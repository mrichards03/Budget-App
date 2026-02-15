from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from plaid.api import plaid_api
from plaid.model.transactions_sync_request import TransactionsSyncRequest
import plaid
import logging

from app.models import PlaidItem, Account, Transaction, Merchant
from app.models.category import Category, Subcategory
from app.utils.plaid_helpers import parse_plaid_date, parse_plaid_datetime

logger = logging.getLogger(__name__)


class TransactionService:
    """Service for handling transaction syncing and management."""
    
    def __init__(self, plaid_client: plaid_api.PlaidApi):
        self.plaid_client = plaid_client
    
    def sync_transactions(self, item_id: str, db: Session) -> dict:
        """
        Sync transactions from Plaid for a given item.
        Returns dict with counts of added, modified, and removed transactions.
        """
        plaid_item = db.query(PlaidItem).filter(PlaidItem.item_id == item_id).first()
        if not plaid_item:
            logger.error(f"Plaid item not found: {item_id}")
            return None

        try:
            access_token = plaid_item.access_token

            # New transaction updates since "cursor"
            added = []
            modified = []
            removed = []  # Removed transaction ids
            account_lookup = {}
            has_more = True

            # Iterate through each page of new transaction updates for item
            while has_more:
                if plaid_item.cursor:
                    request = TransactionsSyncRequest(
                        access_token=access_token,
                        cursor=plaid_item.cursor,
                    )
                else:
                    request = TransactionsSyncRequest(access_token=access_token)
                
                response = self.plaid_client.transactions_sync(request)
                logger.info(f"Sync iteration - Added: {len(response['added'])}, Modified: {len(response['modified'])}, Removed: {len(response['removed'])}, Has more: {response['has_more']}")

                # Add this page of results
                added.extend(response['added'])
                modified.extend(response['modified'])
                removed.extend(response['removed'])

                has_more = response['has_more']

                # Update account balances
                for acc in response['accounts']:
                    account = db.query(Account).filter(Account.plaid_account_id == acc['account_id']).first()
                    if account:
                        account.current_balance = acc['balances']['current']
                        account.available_balance = acc['balances'].get('available')
                        account.limit = acc['balances'].get('limit')
                        account_lookup[acc['account_id']] = account.id

                # Update cursor to the next cursor
                plaid_item.cursor = response['next_cursor']

            # Process added transactions
            for txn in added:
                account_id = account_lookup.get(txn['account_id'])            
                if not account_id:
                    logger.warning(f"Skipping transaction {txn['transaction_id']} - account not found")
                    continue
                
                try:
                    self._map_transaction(txn, account_id, db)
                    logger.debug(f"Successfully mapped transaction {txn['transaction_id']}")
                except Exception as e:
                    logger.error(f"Error mapping transaction {txn['transaction_id']}: {str(e)}")
                    raise  # Re-raise to trigger rollback

            # Process modified transactions
            for txn in modified:
                existing = db.query(Transaction).filter(
                    Transaction.plaid_transaction_id == txn['transaction_id']
                ).first()
                
                if existing:
                    self._update_transaction(existing, txn, db)

            # Process removed transactions
            for removed_txn in removed:
                existing = db.query(Transaction).filter(
                    Transaction.plaid_transaction_id == removed_txn['transaction_id']
                ).first()
                if existing:
                    db.delete(existing)

            logger.info(f"About to commit. Added: {len(added)}, Modified: {len(modified)}, Removed: {len(removed)}")
            db.commit()
            logger.info("Commit successful!")

            # TODO: Run ML model to predict categories
            
            return {
                "success": True,
                "added": len(added),
                "modified": len(modified),
                "removed": len(removed)
            }
        except plaid.ApiException as e:
            logger.error(f"Plaid API error syncing transactions: {str(e)}")
            db.rollback()
            raise
        except Exception as e:
            logger.error(f"Error syncing transactions: {str(e)}")
            db.rollback()
            raise
    
    def _map_transaction(self, txn: dict, account_id: int, db: Session):
        """Map Plaid transaction to database Transaction model."""
        
        # Check if transaction already exists
        existing = db.query(Transaction).filter(
            Transaction.plaid_transaction_id == txn['transaction_id']
        ).first()
        
        if existing:
            logger.debug(f"Transaction {txn['transaction_id']} already exists, skipping")
            return  # Skip duplicates
        
        logger.debug(f"Creating new transaction {txn['transaction_id']}")

        # Check if it's a transfer
        personal_finance_cat = txn.get('personal_finance_category', {})
        is_transfer = personal_finance_cat.get('primary') in ['TRANSFER_IN', 'TRANSFER_OUT']

        transfer_account_id = None
        transfer_transaction_id = None

        if is_transfer:
            # Look for a matching transaction in opposite direction with similar amount and date
            txn_date_for_matching = parse_plaid_date(txn.get('date'))
            date_range_start = txn_date_for_matching - timedelta(days=2)
            date_range_end = txn_date_for_matching + timedelta(days=2)
            
            # Look for opposite transaction (if this is negative, look for positive with same amount)
            opposite_amount = -txn['amount']
            
            matching_transfer = db.query(Transaction).join(
                Account, Transaction.account_id == Account.id
            ).filter(
                Transaction.account_id != account_id,  # Different account
                Transaction.date.between(date_range_start, date_range_end),
                Transaction.amount.between(opposite_amount - 0.01, opposite_amount + 0.01),  # Allow small variance
                Transaction.is_transfer == True
            ).first()
            
            if matching_transfer:
                transfer_account_id = matching_transfer.account_id
                transfer_transaction_id = matching_transfer.plaid_transaction_id
        
        # Auto-categorize transfers to the "Account Transfer" subcategory
        subcategory_id = None
        if is_transfer:
            # Try to find the "Account Transfer" subcategory
            transfer_subcategory = db.query(Subcategory).join(
                Category, Subcategory.category_id == Category.id
            ).filter(
                Category.name == "Transfers",
                Subcategory.name == "Account Transfer"
            ).first()
            if transfer_subcategory:
                subcategory_id = transfer_subcategory.id
        
        transaction = Transaction(
            plaid_transaction_id=txn['transaction_id'],
            account_id=account_id,
            amount=txn['amount'],
            date=parse_plaid_date(txn.get('date')),
            authorized_datetime=parse_plaid_datetime(txn.get('authorized_datetime')),
            name=txn['name'],
            category_primary=personal_finance_cat.get('primary'),
            category_detailed=personal_finance_cat.get('detailed'),
            category_confidence=personal_finance_cat.get('confidence_level'),
            pending=txn.get('pending', False),
            pending_transaction_id=txn.get('pending_transaction_id'),
            payment_channel=txn.get('payment_channel'),
            is_transfer=is_transfer,
            transfer_account_id=transfer_account_id,
            transfer_transaction_id=transfer_transaction_id,
            subcategory_id=subcategory_id,  # Auto-assign transfer category
            payment_meta=txn.get('payment_meta').to_dict() if txn.get('payment_meta') else None,
            location=txn.get('location').to_dict() if txn.get('location') else None
        )
        db.add(transaction)
        db.flush()  # Get transaction.id
        
        # Process merchants
        if not is_transfer:
            self._process_merchants(txn, transaction, db)
    
    def _process_merchants(self, txn: dict, transaction: Transaction, db: Session):
        """Process and link merchants to a transaction."""
        for counterparty in txn.get('counterparties', []):
            merchant = db.query(Merchant).filter(
                Merchant.plaid_entity_id == counterparty.get('entity_id')
            ).first()
            
            if not merchant:
                counterparty_type = counterparty.get('type')
                merchant = Merchant(
                    plaid_entity_id=counterparty.get('entity_id'),
                    name=counterparty.get('name'),
                    type=str(counterparty_type) if counterparty_type else None,
                    logo_url=counterparty.get('logo_url'),
                    website=counterparty.get('website')
                )
                db.add(merchant)
                db.flush()
            
            transaction.merchants.append(merchant)
    
    def _update_transaction(self, existing: Transaction, txn: dict, db: Session):
        """Update an existing transaction with modified data."""
        personal_finance_cat = txn.get('personal_finance_category', {})
        
        existing.amount = txn['amount']
        existing.date = parse_plaid_date(txn.get('date'), existing.date)
        existing.authorized_datetime = parse_plaid_datetime(txn.get('authorized_datetime'))
        existing.name = txn['name']
        existing.category_primary = personal_finance_cat.get('primary')
        existing.category_detailed = personal_finance_cat.get('detailed')
        existing.category_confidence = personal_finance_cat.get('confidence_level')
        existing.pending = txn.get('pending', False)
        existing.pending_transaction_id = txn.get('pending_transaction_id')
        existing.payment_channel = txn.get('payment_channel')
        existing.payment_meta = txn.get('payment_meta').to_dict() if txn.get('payment_meta') else None
        existing.location = txn.get('location').to_dict() if txn.get('location') else None
        existing.updated_at = datetime.utcnow()
