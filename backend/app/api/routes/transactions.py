from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.category import Category, Subcategory
from app.schemas.transaction import TransactionResponse


class CategorizeTransactionRequest(BaseModel):
    category_id: int
    subcategory_id: Optional[int] = None


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
    Manually assign a budget category and optionally subcategory to a transaction.
    This replaces the old category field with the new budget category system.
    """
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    # Verify category exists
    category = db.query(Category).filter(Category.id == categorize_request.category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Verify subcategory exists and belongs to the category (if provided)
    if categorize_request.subcategory_id:
        subcategory = db.query(Subcategory).filter(
            Subcategory.id == categorize_request.subcategory_id
        ).first()
        if not subcategory:
            raise HTTPException(status_code=404, detail="Subcategory not found")
        if subcategory.category_id != categorize_request.category_id:
            raise HTTPException(
                status_code=400, 
                detail="Subcategory does not belong to the specified category"
            )
    
    # Update transaction
    transaction.category_id = categorize_request.category_id
    transaction.subcategory_id = categorize_request.subcategory_id
    db.commit()
    
    return {
        "message": "Transaction categorized successfully",
        "transaction_id": transaction_id,
        "category_id": categorize_request.category_id,
        "subcategory_id": categorize_request.subcategory_id
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
    query = db.query(Transaction).filter(Transaction.category_id == category_id)
    
    if subcategory_id:
        query = query.filter(Transaction.subcategory_id == subcategory_id)
    
    transactions = query.all()
    return transactions
