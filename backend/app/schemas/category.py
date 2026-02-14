from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


# Subcategory Schemas
class SubcategoryBase(BaseModel):
    name: str
    description: Optional[str] = None


class SubcategoryCreate(SubcategoryBase):
    category_id: int


class SubcategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None


class SubcategoryResponse(SubcategoryBase):
    id: int
    category_id: int
    is_system: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Category Schemas
class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None


class CategoryResponse(CategoryBase):
    id: int
    is_system: bool
    created_at: datetime
    updated_at: datetime
    subcategories: List[SubcategoryResponse] = []
    
    class Config:
        from_attributes = True


# Simplified response without subcategories
class CategorySimpleResponse(CategoryBase):
    id: int
    is_system: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
