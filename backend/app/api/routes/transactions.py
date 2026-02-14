from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.core.database import get_db
from app.models.transaction import Transaction
from app.schemas.transaction import TransactionResponse

router = APIRouter()

@router.get("/", response_model=List[TransactionResponse])
async def get_transactions(
    skip: int = 0, 
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get all transactions from the database.
    
    TODO: Add filtering by date range, category, account, etc.
    """
    transactions = db.query(Transaction).offset(skip).limit(limit).all()
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
    category: str,
    db: Session = Depends(get_db)
):
    """
    Manually set category for a transaction.
    Use this for training data for your ML model.
    
    TODO: Add this labeled data to training dataset
    """
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    transaction.predicted_category = category
    db.commit()
    
    return {"message": "Category updated", "transaction_id": transaction_id}
