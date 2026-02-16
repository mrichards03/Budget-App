from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import logging

from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.category import Category, Subcategory
from app.schemas.transaction import TransactionResponse, CategorizeTransactionRequest
from app.services.ml_service import MLService

logger = logging.getLogger(__name__)
router = APIRouter()
ml_service = MLService()

@router.get("/", response_model=List[TransactionResponse])
async def get_transactions(
    skip: int = 0, 
    limit: int = 100,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get all transactions from the database.
    
    Supports filtering by date range using start_date and end_date parameters (ISO format: YYYY-MM-DD).
    """
    query = db.query(Transaction)
    
    # Apply date filters if provided
    if start_date:
        try:
            start_dt = datetime.fromisoformat(start_date)
            query = query.filter(Transaction.date >= start_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid start_date format. Use YYYY-MM-DD")
    
    if end_date:
        try:
            end_dt = datetime.fromisoformat(end_date)
            query = query.filter(Transaction.date <= end_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid end_date format. Use YYYY-MM-DD")
    
    transactions = query.offset(skip).limit(limit).all()
    return transactions

@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(transaction_id: int, db: Session = Depends(get_db)):
    """Get a specific transaction by ID."""
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return transaction

@router.get("/category/{category}")
async def get_transactions_by_category(
    category: str,
    db: Session = Depends(get_db)
):
    """
    Get transactions by category.
    
    TODO: Implement filtering logic
    """
    transactions = db.query(Transaction).filter(
        Transaction.predicted_category == category
    ).all()
    return transactions

@router.post("/{transaction_id}/categorize")
async def manually_categorize_transaction(
    transaction_id: int,
    categorize_request: CategorizeTransactionRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Manually assign a budget subcategory to a transaction.
    The parent category is derived from the subcategory relationship.
    Triggers ML retraining in background if sufficient labeled data exists.
    """
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    # Verify subcategory exists
    subcategory = db.query(Subcategory).filter(
        Subcategory.id == categorize_request.subcategory_id
    ).first()
    if not subcategory:
        raise HTTPException(status_code=404, detail="Subcategory not found")
    
    # Track if category changed for retraining
    category_changed = transaction.subcategory_id != categorize_request.subcategory_id
    
    # Update transaction
    transaction.subcategory_id = categorize_request.subcategory_id
    db.commit()
    
    # Trigger retraining in background if enough labeled data exists
    retrain_triggered = False
    if category_changed:
        labeled_count = db.query(Transaction).filter(
            Transaction.subcategory_id.isnot(None)
        ).count()
        
        if labeled_count >= 50:
            logger.info(f"Category change detected, scheduling background retraining ({labeled_count} labeled txns)")
            background_tasks.add_task(_background_retrain, db)
            retrain_triggered = True
    
    return {
        "message": "Transaction categorized successfully",
        "transaction_id": transaction_id,
        "subcategory_id": categorize_request.subcategory_id,
        "category_id": subcategory.category_id,
        "retrain_triggered": retrain_triggered
    }

def _background_retrain(db: Session):
    """Background task for retraining ML model."""
    try:
        result = ml_service.train_models(db)
        logger.info(f"Background retraining completed: {result.get('message')}")
    except Exception as e:
        logger.error(f"Background retraining failed: {str(e)}")


@router.get("/by-category/{category_id}", response_model=List[TransactionResponse])
async def get_transactions_by_budget_category(
    category_id: int,
    subcategory_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """
    Get transactions filtered by budget category and optionally subcategory.
    """
    query = db.query(Transaction).join(Subcategory).filter(Subcategory.category_id == category_id)
    
    if subcategory_id:
        query = query.filter(Transaction.subcategory_id == subcategory_id)
    
    transactions = query.all()
    return transactions
