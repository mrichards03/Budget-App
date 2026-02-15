from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AccountInfo(BaseModel):
    """Minimal account information for nested responses"""
    id: int
    name: str
    account_type: str
    account_subtype: str
    current_balance: float
    
    class Config:
        from_attributes = True


class CategoryInfo(BaseModel):
    """Minimal category information for nested responses"""
    id: int
    name: str
    description: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None
    
    class Config:
        from_attributes = True


class SubcategoryInfo(BaseModel):
    """Minimal subcategory information for nested responses"""
    id: int
    name: str
    category_id: int
    description: Optional[str] = None
    
    class Config:
        from_attributes = True
