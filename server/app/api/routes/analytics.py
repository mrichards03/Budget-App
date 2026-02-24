from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, timedelta
from collections import defaultdict

from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.category import Category, Subcategory
from app.models.account import Account
from app.schemas.analytics import AnalyticsResponse, AnalyticsSummary
from app.schemas.transaction import TransactionResponse
from app.schemas.common import CategoryInfo, SubcategoryInfo, AccountInfo

router = APIRouter()


@router.get("/data", response_model=AnalyticsResponse)
async def get_analytics_data(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db)
):
    """
    Get comprehensive analytics data with normalized structure.
    Returns all transactions with lookup maps for categories, subcategories, and accounts.
    """
    # Query transactions (exclude transfers as they are net-zero)
    # Eager-load splits to properly account for split transactions
    query = db.query(Transaction).options(joinedload(Transaction.splits)).filter(Transaction.is_transfer == False)
    if start_date:
        query = query.filter(Transaction.posted >= start_date)
    if end_date:
        query = query.filter(Transaction.posted <= end_date)
    
    transactions = query.all()
    
    # Build transaction responses (uses computed properties)
    transaction_responses = [TransactionResponse.model_validate(t) for t in transactions]
    
    # Collect IDs for lookups
    account_ids = {t.account_id for t in transactions}
    # Include subcategory ids from both parent transactions and splits
    subcategory_ids = set()
    for t in transactions:
        if t.subcategory_id:
            subcategory_ids.add(t.subcategory_id)
        if getattr(t, 'splits', None):
            for s in t.splits:
                if s.subcategory_id:
                    subcategory_ids.add(s.subcategory_id)
    
    # Fetch all needed subcategories
    subcategories_dict = {}
    category_ids = set()
    
    if subcategory_ids:
        subcategories = db.query(Subcategory).filter(Subcategory.id.in_(subcategory_ids)).all()
        for sub in subcategories:
            subcategories_dict[sub.id] = SubcategoryInfo.model_validate(sub)
            category_ids.add(sub.category_id)
    
    # Fetch all needed categories
    categories_dict = {}
    if category_ids:
        categories = db.query(Category).filter(Category.id.in_(category_ids)).all()
        for cat in categories:
            categories_dict[cat.id] = CategoryInfo.model_validate(cat)
    
    # Fetch all needed accounts
    accounts_dict = {}
    if account_ids:
        accounts = db.query(Account).filter(Account.id.in_(account_ids)).all()
        for acc in accounts:
            accounts_dict[acc.id] = AccountInfo.model_validate(acc)
    
    # Calculate summary statistics, accounting for split transactions
    total_spending = 0.0
    total_income = 0.0
    for t in transactions:
        if getattr(t, 'splits', None) and len(t.splits) > 0:
            for s in t.splits:
                if s.amount < 0:
                    total_spending += s.amount
                else:
                    total_income += s.amount
        else:
            if t.amount < 0:
                total_spending += t.amount
            else:
                total_income += t.amount

    net = total_income + total_spending
    
    # Calculate date range
    if transactions:
        dates = [t.transacted_at or t.posted for t in transactions]
        min_date = min(dates)
        max_date = max(dates)
        date_range_days = max((max_date - min_date).days, 1)
    else:
        date_range_days = 1
    
    # Calculate averages
    months = date_range_days / 30.44  # Average days per month
    monthly_avg_spending = total_spending / months if months > 0 else 0
    monthly_avg_income = total_income / months if months > 0 else 0
    daily_avg_spending = total_spending / date_range_days if date_range_days > 0 else 0
    daily_avg_income = total_income / date_range_days if date_range_days > 0 else 0
    
    # Category breakdown
    category_breakdown = defaultdict(float)
    subcategory_breakdown = defaultdict(float)
    
    for t in transactions:
        if getattr(t, 'splits', None) and len(t.splits) > 0:
            for s in t.splits:
                if s.subcategory_id:
                    subcategory_breakdown[s.subcategory_id] += s.amount
                    if s.subcategory_id in subcategories_dict:
                        category_id = subcategories_dict[s.subcategory_id].category_id
                        category_breakdown[category_id] += s.amount
        else:
            if t.subcategory_id:
                subcategory_breakdown[t.subcategory_id] += t.amount
                # Get category_id from subcategory
                if t.subcategory_id in subcategories_dict:
                    category_id = subcategories_dict[t.subcategory_id].category_id
                    category_breakdown[category_id] += t.amount
    
    summary = AnalyticsSummary(
        total_spending=total_spending,
        total_income=total_income,
        net=net,
        transaction_count=len(transactions),
        date_range_days=date_range_days,
        monthly_average_spending=monthly_avg_spending,
        monthly_average_income=monthly_avg_income,
        daily_average_spending=daily_avg_spending,
        daily_average_income=daily_avg_income,
        category_breakdown=dict(category_breakdown),
        subcategory_breakdown=dict(subcategory_breakdown)
    )
    
    return AnalyticsResponse(
        transactions=transaction_responses,
        categories=categories_dict,
        subcategories=subcategories_dict,
        accounts=accounts_dict,
        summary=summary
    )


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
    ).filter(
        Transaction.amount < 0, #TODO check sign correct for credit cards too
        Transaction.is_transfer == False  # Exclude transfers
    )
    
    if start_date:
        query = query.filter(Transaction.posted >= start_date)
    if end_date:
        query = query.filter(Transaction.posted <= end_date)
    
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
        uncategorized_total = uncategorized_total.filter(Transaction.posted >= start_date)
    if end_date:
        uncategorized_total = uncategorized_total.filter(Transaction.posted <= end_date)
    
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
    query = db.query(Transaction).filter(Transaction.is_transfer == False)
    
    if start_date:
        query = query.filter(Transaction.posted >= start_date)
    if end_date:
        query = query.filter(Transaction.posted <= end_date)
    
    transactions = query.all()
    
    # TODO check if correct for cc
    total_spending = sum(t.amount for t in transactions if t.amount < 0)
    total_income = sum(t.amount for t in transactions if t.amount > 0)
    
    return {
        "total_income": float(total_income),
        "total_spending": float(total_spending),
        "net": float(total_income + total_spending)
    }
