from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from sqlalchemy.orm import Session
import plaid
import logging

from app.core.config import settings
from app.core.database import get_db
from app.services.plaid_service import PlaidService
from app.services.account_service import AccountService
from app.services.transaction_service import TransactionService
from app.services.plaid_webhook_handler import PlaidWebhookHandler

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
plaid_client = plaid.api.plaid_api.PlaidApi(api_client)

# Initialize services
account_service = AccountService(plaid_client)
plaid_service = PlaidService(plaid_client, account_service)
transaction_service = TransactionService(plaid_client)
webhook_handler = PlaidWebhookHandler(transaction_service)

@router.get("/institutions")
async def get_institutions(db: Session = Depends(get_db)):
    """
    Get all currently connected institutions.
    Used to check if an institution is already connected.
    """
    return plaid_service.get_existing_institutions(db)

@router.post("/create_link_token")
async def create_link_token(item_id: str = None, db: Session = Depends(get_db)):
    """
    Create a Plaid Link token for the user to connect their bank account.
    If item_id is provided, creates an update mode token for re-authentication.
    
    Query params:
        item_id: Optional. If provided, Link opens in update mode for this item.
    """
    try:
        access_token = None
        
        # If item_id provided, fetch access_token for update mode
        if item_id:
            from app.models import PlaidItem
            plaid_item = db.query(PlaidItem).filter(PlaidItem.item_id == item_id).first()
            if not plaid_item:
                raise HTTPException(status_code=404, detail="Institution not found")
            access_token = plaid_item.access_token
        
        link_token = plaid_service.create_link_token(access_token)
        return {"link_token": link_token}
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/exchange_public_token")
async def exchange_public_token(public_token: str, inst_id: str, inst_name: str, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """
    Exchange the public token from Plaid Link for an access token.
    Store this access token securely to fetch transactions later.
    """
    try:
        result = plaid_service.exchange_public_token(
            public_token=public_token,
            inst_id=inst_id,
            inst_name=inst_name,
            db=db
        )
        
        # Trigger initial transaction sync in background
        logger.info(f"Triggering initial transaction sync for item {result['item_id']}")
        background_tasks.add_task(
            transaction_service_background_wrapper,
            item_id=result['item_id']
        )

        return result
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/sync_transactions")
async def sync_transactions(item_id: str, db: Session = Depends(get_db)):
    """
    HTTP endpoint to manually trigger transaction sync.
    """
    try:
        result = transaction_service.sync_transactions(item_id, db)
        if result is None:
            raise HTTPException(status_code=404, detail="Plaid item not found")
        return result
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def transaction_service_background_wrapper(item_id: str):
    """
    Background task wrapper that creates its own DB session.
    """
    from app.core.database import SessionLocal
    db = SessionLocal()
    try:
        transaction_service.sync_transactions(item_id, db)
    finally:
        db.close()


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
        
        result = webhook_handler.handle_webhook(webhook_data, background_tasks, db)
        return result
        
    except Exception as e:
        logger.error(f"Error processing webhook: {str(e)}")
        # Return 200 even on error so Plaid doesn't retry
        return {"status": "error", "message": str(e)}