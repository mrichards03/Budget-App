from pydantic import BaseModel
from typing import Dict, List
from app.schemas.transaction import TransactionResponse
from app.schemas.common import AccountInfo, CategoryInfo, SubcategoryInfo


class AnalyticsSummary(BaseModel):
    """Aggregated analytics metrics"""
    total_spending: float
    total_income: float
    net: float
    transaction_count: int
    date_range_days: int
    monthly_average_spending: float
    monthly_average_income: float
    daily_average_spending: float
    daily_average_income: float
    
    # Spending by category
    category_breakdown: Dict[int, float]  # category_id -> amount
    subcategory_breakdown: Dict[int, float]  # subcategory_id -> amount


class AnalyticsResponse(BaseModel):
    """Normalized analytics data structure"""
    transactions: List[TransactionResponse]
    categories: Dict[int, CategoryInfo]  # category_id -> category
    subcategories: Dict[int, SubcategoryInfo]  # subcategory_id -> subcategory
    accounts: Dict[str, AccountInfo]  # account_id -> account
    summary: AnalyticsSummary
