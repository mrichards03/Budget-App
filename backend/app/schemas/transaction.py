from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class CategoryInfo(BaseModel):
    """Nested category information for transaction response"""
    id: int
    name: str
    
    class Config:
        from_attributes = True


class SubcategoryInfo(BaseModel):
    """Nested subcategory information for transaction response"""
    id: int
    name: str
    category_id: int
    
    class Config:
        from_attributes = True


class TransactionBase(BaseModel):
    amount: float
    date: datetime
    name: str
    merchant_name: Optional[str] = None
    category: Optional[str] = None
    category_detailed: Optional[str] = None

class TransactionCreate(TransactionBase):
    plaid_transaction_id: str
    account_id: int

class TransactionResponse(TransactionBase):
    id: int
    plaid_transaction_id: str
    account_id: int
    predicted_category: Optional[str] = None
    predicted_confidence: Optional[float] = None
    pending: bool
    created_at: datetime
    
    # Budget category fields
    category_id: Optional[int] = None
    subcategory_id: Optional[int] = None
    budget_category: Optional[CategoryInfo] = None
    budget_subcategory: Optional[SubcategoryInfo] = None
    
    class Config:
        from_attributes = True
