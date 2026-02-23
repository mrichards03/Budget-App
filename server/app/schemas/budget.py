from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class SubcategoryBudgetBase(BaseModel):
    subcategory_id: int
    monthly_assigned: float


class SubcategoryBudgetCreate(SubcategoryBudgetBase):
    monthly_target: float = 0.0


class SubcategoryBudgetUpdate(BaseModel):
    monthly_assigned: Optional[float] = None
    monthly_target: Optional[float] = None


class SubcategoryBudgetResponse(SubcategoryBudgetBase):
    id: int
    budget_id: int
    category_name: str
    subcategory_name: str
    monthly_target: float
    total_balance: float
    monthly_activity: float
    monthly_available: float
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class BudgetBase(BaseModel):
    name: str
    month: int
    year: int


class BudgetCreate(BudgetBase):
    subcategory_budgets: List[SubcategoryBudgetCreate] = []


class BudgetUpdate(BaseModel):
    name: Optional[str] = None
    month: Optional[int] = None
    year: Optional[int] = None


class BudgetResponse(BudgetBase):
    id: int
    start_date: datetime
    created_at: datetime
    updated_at: datetime
    subcategory_budgets: List[SubcategoryBudgetResponse] = []
    
    class Config:
        from_attributes = True


class BudgetSimpleResponse(BudgetBase):
    id: int
    start_date: datetime
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
