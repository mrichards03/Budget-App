from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from plaid.api import plaid_api
from plaid.model.transactions_sync_request import TransactionsSyncRequest
import plaid
import logging

from app.models import SimplefinItem, Account, Transaction, Merchant
from app.models.category import Category, Subcategory
from app.utils.plaid_helpers import parse_plaid_date, parse_plaid_datetime
from app.services.ml_service import MLService

logger = logging.getLogger(__name__)


class TransactionService:
    """Service for handling transaction syncing and management."""
    
    def __init__(self):
        self.ml_service = MLService()
 
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
                Transaction.posted.between(date_range_start, date_range_end),
                Transaction.amount.between(opposite_amount - 0.01, opposite_amount + 0.01),  # Allow small variance
                Transaction.is_transfer == True
            ).first()
            
            if matching_transfer:
                transfer_account_id = matching_transfer.account_id
                transfer_transaction_id = matching_transfer.plaid_transaction_id
        
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
            subcategory_id=None,  # Let ML handle categorization
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

        existing.posted = datetime.fromtimestamp(txn['posted'])        
        existing.amount = txn['amount']
        existing.name = txn['description']
        existing.transacted_at = datetime.fromtimestamp(float(txn.get('transacted_at'))) if txn.get('transacted_at') is not None else None
        existing.pending = txn.get('pending', False)
        existing.updated_at = datetime.utcnow()

    def add_transaction(self, transaction: dict, account_id: str, db: Session) -> tuple:
        try:
            existing_trans = db.query(Transaction).filter(Transaction.id == int(transaction['id']) and Transaction.account_id == account_id).first()
            if existing_trans:
                self._update_transaction(existing_trans, transaction, db)
            else:
                new_trans = Transaction(
                    id = int(transaction['id']),
                    account_id = account_id,
                    posted = datetime.fromtimestamp(transaction['posted']),
                    amount = transaction['amount'],
                    name  = transaction['description'],
                    transacted_at = datetime.fromtimestamp(float(transaction.get('transacted_at'))) if transaction.get('transacted_at') is not None else None,
                    pending = transaction.get('pending', False)
                )
                db.add(new_trans)
                db.flush()
            return (True, "")
        except Exception as ex:
            return (False, f"Failed to add transaction id {transaction['id']}: {ex}")
