from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import logging

from app.models import SimplefinItem, Account, Transaction, Merchant
from app.models.category import Category, Subcategory
from app.services.ml_service import MLService

logger = logging.getLogger(__name__)


class TransactionService:
    """Service for handling transaction syncing and management."""
    
    def __init__(self):
        self.ml_service = MLService()
  
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
            existing_trans = db.query(Transaction).filter(
                Transaction.transaction_id == int(transaction['id']),
                Transaction.account_id == account_id
            ).first()
            if existing_trans:
                self._update_transaction(existing_trans, transaction, db)
            else:
                new_trans = Transaction(
                    transaction_id = int(transaction['id']),
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
