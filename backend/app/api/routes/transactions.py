from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.category import Category, Subcategory
from app.schemas.transaction import TransactionResponse, CategorizeTransactionRequest


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
    categorize_request: CategorizeTransactionRequest,
    db: Session = Depends(get_db)
):
    """
    Manually assign a budget subcategory to a transaction.
    The parent category is derived from the subcategory relationship.
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
    
    # Update transaction
    transaction.subcategory_id = categorize_request.subcategory_id
    db.commit()
    
    return {
        "message": "Transaction categorized successfully",
        "transaction_id": transaction_id,
        "subcategory_id": categorize_request.subcategory_id,
        "category_id": subcategory.category_id
    }


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
