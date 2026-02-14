from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.transactions_get_request_options import TransactionsGetRequestOptions
from plaid.model.transactions_sync_request import TransactionsSyncRequest
from plaid.model.accounts_get_request import AccountsGetRequest
import plaid
from datetime import datetime, timedelta

from app.core.config import settings
from app.core.database import get_db
from app.services.plaid_service import PlaidService
from app.models import PlaidItem, Account, Transaction, Merchant
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

# Initialize Plaid client
configuration = plaid.Configuration(
    host=plaid.Environment.Sandbox if settings.PLAID_ENV == "sandbox" else plaid.Environment.Production,
    api_key={
        'clientId': settings.PLAID_CLIENT_ID,
        'secret': settings.PLAID_SECRET,
    }
)
api_client = plaid.ApiClient(configuration)
plaid_client = plaid_api.PlaidApi(api_client)

@router.post("/create_link_token")
async def create_link_token():
    """
    Create a Plaid Link token for the user to connect their bank account.
    This token is used by the Flutter app to initialize Plaid Link.
    """
    try:
        request = LinkTokenCreateRequest(
            user=LinkTokenCreateRequestUser(client_user_id="user-id"),
            client_name="Budget App",
            products=[Products("transactions")],
            country_codes=[CountryCode("US"), CountryCode("CA")],
            language="en",
            webhook="https://unanatomized-charleigh-overdelicately.ngrok-free.dev/api/plaid/webhooks"
        )
        response = plaid_client.link_token_create(request)
        return {"link_token": response['link_token']}
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/exchange_public_token")
async def exchange_public_token(public_token: str, inst_id: str, inst_name: str, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """
    Exchange the public token from Plaid Link for an access token.
    Store this access token securely to fetch transactions later.
    """
    try:
        exchange_request = ItemPublicTokenExchangeRequest(public_token=public_token)
        exchange_response = plaid_client.item_public_token_exchange(exchange_request)
        access_token = exchange_response['access_token']
        item_id = exchange_response['item_id']
        
        plaid_item = PlaidItem(
            item_id = item_id,
            access_token = access_token,
            institution_id = inst_id,
            institution_name = inst_name
        )
        db.add(plaid_item)
        db.commit()

        accounts = await set_accounts(access_token, db)
        logger.info(f"Triggering initial transaction sync for item {item_id}")
        background_tasks.add_task(sync_transactions_background, item_id=item_id)

        return {
            "item_id": item_id,
            "accounts": [
                {
                    "account_id": acc['account_id'],
                    "name": acc['name'],
                    "mask": acc.get('mask'),
                    "type": str(acc['type']),
                    "subtype": str(acc['subtype']),
                    "balance": acc['balances']['current']
                }
                for acc in accounts
            ],
            "message": "Token exchanged successfully"
        }
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

def sync_transactions_logic(item_id: str, db: Session):
    """
    Core business logic for syncing transactions from Plaid.
    Can be called from endpoint or background task.
    """
    plaid_item = db.query(PlaidItem).filter(PlaidItem.item_id == item_id).first()
    if not plaid_item:
        logger.error(f"Plaid item not found: {item_id}")
        return None

    try:
        access_token = plaid_item.access_token

        # Provide a cursor from your database if you've previously
        # received one for the Item. Leave null if this is your
        # first sync call for this Item. The first request will
        # return a cursor.

        # New transaction updates since "cursor"
        added = []
        modified = []
        removed = [] # Removed transaction ids
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
            
            response = plaid_client.transactions_sync(request)
            logger.info(f"Sync iteration - Added: {len(response['added'])}, Modified: {len(response['modified'])}, Removed: {len(response['removed'])}, Has more: {response['has_more']}")

            # Add this page of results
            added.extend(response['added'])
            modified.extend(response['modified'])
            removed.extend(response['removed'])

            has_more = response['has_more']

            for acc in response['accounts']:
                account = db.query(Account).filter(Account.plaid_account_id == acc['account_id']).first()
                if account:
                    account.current_balance=acc['balances']['current']
                    account.available_balance=acc['balances'].get('available')
                    account.limit=acc['balances'].get('limit')
                    account_lookup[acc['account_id']] = account.id

            # Update cursor to the next cursor
            plaid_item.cursor = response['next_cursor']

        for txn in added:
            account_id = account_lookup.get(txn['account_id'])            
            if not account_id:
                logger.warning(f"Skipping transaction {txn['transaction_id']} - account not found")
                continue
            
            try:
                map_transaction(txn, account_id, db)
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
                update_transaction(existing, txn, db)

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

@router.post("/sync_transactions")
async def sync_transactions(item_id: str, db: Session = Depends(get_db)):
    """
    HTTP endpoint to manually trigger transaction sync.
    """
    try:
        result = sync_transactions_logic(item_id, db)
        if result is None:
            raise HTTPException(status_code=404, detail="Plaid item not found")
        return result
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def sync_transactions_background(item_id: str):
    """
    Background task wrapper that creates its own DB session.
    """
    from app.core.database import SessionLocal
    db = SessionLocal()
    try:
        sync_transactions_logic(item_id, db)
    finally:
        db.close()

def parse_plaid_date(date_value, fallback=None):
    """Parse a date that could be a string, date object, or None."""
    if not date_value:
        return fallback
    
    if isinstance(date_value, str):
        return datetime.fromisoformat(date_value)
    else:
        # Already a date object, convert to datetime
        return datetime.combine(date_value, datetime.min.time())

def parse_plaid_datetime(datetime_value):
    """Parse an ISO datetime string with Z timezone."""
    if not datetime_value:
        return None
    return datetime.fromisoformat(datetime_value.replace('Z', '+00:00'))
    
def map_transaction(txn, account_id: int, db: Session):
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
        from datetime import timedelta
        
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
        payment_meta=txn.get('payment_meta').to_dict() if txn.get('payment_meta') else None,
        location=txn.get('location').to_dict() if txn.get('location') else None
    )
    db.add(transaction)
    db.flush()  # Get transaction.id
    # Process merchants
    if not is_transfer:
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

def update_transaction(existing: Transaction, txn: dict, db: Session):
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

async def set_accounts(access_token: str, db: Session):
    """
    Fetch connected accounts from Plaid.
    
    TODO: Retrieve access_token from database
    """
    try:
        request = AccountsGetRequest(access_token=access_token)
        response = plaid_client.accounts_get(request)
        item_id = response['item']['item_id']
        
        for acc in response['accounts']:
            # Check if account already exists
            existing_account = db.query(Account).filter(
                Account.plaid_account_id == acc['account_id']
            ).first()
            
            holder_cat = acc.get('holder_category')
            
            if existing_account:
                # Update existing account
                existing_account.plaid_item_id = item_id
                existing_account.name = acc['name']
                existing_account.official_name = acc.get('official_name')
                existing_account.account_type = str(acc['type'])
                existing_account.account_subtype = str(acc['subtype'])
                existing_account.holder_category = str(holder_cat) if holder_cat else None
                existing_account.mask = acc.get('mask')
                existing_account.current_balance = acc['balances']['current']
                existing_account.available_balance = acc['balances'].get('available')
                existing_account.limit = acc['balances'].get('limit')
                existing_account.currency_code = acc['balances']['iso_currency_code']
            else:
                # Create new account
                account = Account(
                    plaid_account_id=acc['account_id'],
                    plaid_item_id=item_id,
                    name=acc['name'],
                    official_name=acc.get('official_name'),
                    account_type=str(acc['type']),
                    account_subtype=str(acc['subtype']),
                    holder_category=str(holder_cat) if holder_cat else None,
                    mask=acc.get('mask'),
                    current_balance=acc['balances']['current'],
                    available_balance=acc['balances'].get('available'),
                    limit=acc['balances'].get('limit'),
                    currency_code=acc['balances']['iso_currency_code']
                )
                db.add(account)

        db.commit()
        return response['accounts']
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/webhooks")
async def plaid_webhook(request: Request, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """
    Receive webhook notifications from Plaid.
    Handles SYNC_UPDATES_AVAILABLE and other transaction webhooks.
    """
    logger.info("Webhook endpoint hit!")
    try:
        webhook_data = await request.json()
        logger.info(f"Webhook data: {webhook_data}")
        webhook_type = webhook_data.get("webhook_type")
        webhook_code = webhook_data.get("webhook_code")
        item_id = webhook_data.get("item_id")
        
        logger.info(f"Received webhook: {webhook_type}.{webhook_code} for item {item_id}")
        
        # Handle TRANSACTIONS webhooks
        if webhook_type == "TRANSACTIONS":
            if webhook_code == "SYNC_UPDATES_AVAILABLE":
                # New transactions are available to sync
                logger.info(f"Syncing transactions for item {item_id}")
                
                # Run sync in background to avoid timeout
                # Note: Background task creates its own DB session
                background_tasks.add_task(sync_transactions_background, item_id=item_id)
                
        # Handle ITEM webhooks (errors, updates needed, etc.)
        elif webhook_type == "ITEM":
            if webhook_code == "ERROR":
                error = webhook_data.get("error", {})
                logger.error(f"Item error for {item_id}: {error}")
                # TODO: Mark item as needs attention in database
                
            elif webhook_code == "PENDING_EXPIRATION":
                logger.warning(f"Item {item_id} access will expire soon")
                # TODO: Notify user to re-authenticate
        
        return {"status": "received"}
        
    except Exception as e:
        logger.error(f"Error processing webhook: {str(e)}")
        # Return 200 even on error so Plaid doesn't retry
        return {"status": "error", "message": str(e)}