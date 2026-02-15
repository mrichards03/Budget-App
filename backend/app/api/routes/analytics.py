from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.category import Category, Subcategory

router = APIRouter()


@router.get("/spending_breakdown")
async def get_spending_breakdown(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db)
):
    """Get spending breakdown by category"""
    query = db.query(
        Subcategory.category_id,
        func.sum(Transaction.amount).label('total')
    ).join(
        Transaction, Transaction.subcategory_id == Subcategory.id
    ).filter(Transaction.amount < 0)
    
    if start_date:
        query = query.filter(Transaction.date >= start_date)
    if end_date:
        query = query.filter(Transaction.date <= end_date)
    
    results = query.group_by(Subcategory.category_id).all()
    
    categories = {}
    total_spending = 0
    
    # Handle transactions with subcategories
    for category_id, total in results:
        category = db.query(Category).filter(Category.id == category_id).first()
        category_name = category.name if category else f"Category {category_id}"
        categories[category_name] = float(total)
        total_spending += float(total)
    
    # Handle uncategorized transactions
    uncategorized_total = db.query(
        func.sum(Transaction.amount)
    ).filter(
        Transaction.amount < 0,
        Transaction.subcategory_id.is_(None)
    )
    if start_date:
        uncategorized_total = uncategorized_total.filter(Transaction.date >= start_date)
    if end_date:
        uncategorized_total = uncategorized_total.filter(Transaction.date <= end_date)
    
    uncategorized = uncategorized_total.scalar()
    if uncategorized:
        categories["Uncategorized"] = float(uncategorized)
        total_spending += float(uncategorized)
    
    return {
        "categories": categories,
        "total_spending": total_spending
    }


@router.get("/income_vs_spending")
async def get_income_vs_spending(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db)
):
    """Get income vs spending analysis"""
    query = db.query(Transaction)
    
    if start_date:
        query = query.filter(Transaction.date >= start_date)
    if end_date:
        query = query.filter(Transaction.date <= end_date)
    
    transactions = query.all()
    
    total_income = sum(t.amount for t in transactions if t.amount > 0)
    total_spending = sum(t.amount for t in transactions if t.amount < 0)
    
    return {
        "total_income": float(total_income),
        "total_spending": float(total_spending),
        "net": float(total_income + total_spending)
    }
