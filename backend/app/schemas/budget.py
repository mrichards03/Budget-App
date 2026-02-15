from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class SubcategoryBudgetBase(BaseModel):
    subcategory_id: int
    allocated_amount: float


class SubcategoryBudgetCreate(SubcategoryBudgetBase):
    pass


class SubcategoryBudgetUpdate(BaseModel):
    allocated_amount: Optional[float] = None


class SubcategoryBudgetResponse(SubcategoryBudgetBase):
    id: int
    budget_id: int
    category_name: str
    subcategory_name: str
    current_spending: float = 0.0
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class BudgetBase(BaseModel):
    name: str
    start_date: datetime
    end_date: Optional[datetime] = None


class BudgetCreate(BudgetBase):
    subcategory_budgets: List[SubcategoryBudgetCreate] = []


class BudgetUpdate(BaseModel):
    name: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None


class BudgetResponse(BudgetBase):
    id: int
    created_at: datetime
    updated_at: datetime
    subcategory_budgets: List[SubcategoryBudgetResponse] = []
    total_allocated: float = 0.0
    
    class Config:
        from_attributes = True


class BudgetSimpleResponse(BudgetBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
