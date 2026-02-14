from fastapi import BackgroundTasks
from sqlalchemy.orm import Session
import logging

from app.services.transaction_service import TransactionService

logger = logging.getLogger(__name__)


class PlaidWebhookHandler:
    """Service for handling Plaid webhook notifications."""
    
    def __init__(self, transaction_service: TransactionService):
        self.transaction_service = transaction_service
    
    def handle_webhook(
        self, 
        webhook_data: dict, 
        background_tasks: BackgroundTasks,
        db: Session
    ) -> dict:
        """
        Process incoming Plaid webhooks.
        Routes to appropriate handler based on webhook type and code.
        """
        webhook_type = webhook_data.get("webhook_type")
        webhook_code = webhook_data.get("webhook_code")
        item_id = webhook_data.get("item_id")
        
        logger.info(f"Received webhook: {webhook_type}.{webhook_code} for item {item_id}")
        
        # Handle TRANSACTIONS webhooks
        if webhook_type == "TRANSACTIONS":
            return self._handle_transactions_webhook(webhook_code, item_id, background_tasks)
        
        # Handle ITEM webhooks (errors, updates needed, etc.)
        elif webhook_type == "ITEM":
            return self._handle_item_webhook(webhook_code, item_id, webhook_data)
        
        return {"status": "received"}
    
    def _handle_transactions_webhook(
        self, 
        webhook_code: str, 
        item_id: str,
        background_tasks: BackgroundTasks
    ) -> dict:
        """Handle TRANSACTIONS webhook events."""
        if webhook_code == "SYNC_UPDATES_AVAILABLE":
            # New transactions are available to sync
            logger.info(f"Syncing transactions for item {item_id}")
            
            # Run sync in background to avoid timeout
            background_tasks.add_task(self._sync_transactions_background, item_id=item_id)
        
        return {"status": "received"}
    
    def _handle_item_webhook(
        self, 
        webhook_code: str, 
        item_id: str,
        webhook_data: dict
    ) -> dict:
        """Handle ITEM webhook events."""
        if webhook_code == "ERROR":
            error = webhook_data.get("error", {})
            logger.error(f"Item error for {item_id}: {error}")
            # TODO: Mark item as needs attention in database
            
        elif webhook_code == "PENDING_EXPIRATION":
            logger.warning(f"Item {item_id} access will expire soon")
            # TODO: Notify user to re-authenticate
        
        return {"status": "received"}
    
    def _sync_transactions_background(self, item_id: str):
        """
        Background task wrapper that creates its own DB session.
        """
        from app.core.database import SessionLocal
        db = SessionLocal()
        try:
            self.transaction_service.sync_transactions(item_id, db)
        finally:
            db.close()
