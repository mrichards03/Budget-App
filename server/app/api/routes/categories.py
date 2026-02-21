from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.services.category_service import CategoryService
from app.schemas.category import (
    CategoryResponse, CategorySimpleResponse, CategoryCreate, CategoryUpdate,
    SubcategoryResponse, SubcategoryCreate, SubcategoryUpdate
)

router = APIRouter()
category_service = CategoryService()


# ==================== Category Endpoints ====================

@router.get("/", response_model=List[CategoryResponse])
async def get_categories(db: Session = Depends(get_db)):
    """
    Get all budget categories with their subcategories.
    """
    categories = category_service.get_all_categories(db)
    return categories


@router.get("/simple", response_model=List[CategorySimpleResponse])
async def get_categories_simple(db: Session = Depends(get_db)):
    """
    Get all budget categories without subcategories (lighter response).
    Use this endpoint for dropdowns or lists where you don't need subcategory details.
    """
    categories = category_service.get_all_categories(db, include_subcategories=False)
    return categories


@router.get("/{category_id}", response_model=CategoryResponse)
async def get_category(category_id: int, db: Session = Depends(get_db)):
    """
    Get a specific category by ID with its subcategories.
    """
    category = category_service.get_category_by_id(db, category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category


@router.post("/", response_model=CategoryResponse, status_code=201)
async def create_category(category: CategoryCreate, db: Session = Depends(get_db)):
    """
    Create a new budget category.
    """
    return category_service.create_category(db, category)


@router.put("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: int,
    category: CategoryUpdate,
    db: Session = Depends(get_db)
):
    """
    Update an existing category.
    System categories can be modified but not deleted.
    """
    updated_category = category_service.update_category(db, category_id, category)
    if not updated_category:
        raise HTTPException(status_code=404, detail="Category not found")
    return updated_category


@router.delete("/{category_id}", status_code=204)
async def delete_category(category_id: int, db: Session = Depends(get_db)):
    """
    Delete a category and all its subcategories.
    System categories cannot be deleted.
    Will fail if any transactions are associated with this category.
    """
    success = category_service.delete_category(db, category_id)
    if not success:
        raise HTTPException(status_code=404, detail="Category not found")
    return None


# ==================== Subcategory Endpoints ====================

@router.get("/{category_id}/subcategories", response_model=List[SubcategoryResponse])
async def get_subcategories_by_category(
    category_id: int,
    db: Session = Depends(get_db)
):
    """
    Get all subcategories for a specific category.
    """
    # Verify category exists
    category = category_service.get_category_by_id(db, category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    return category_service.get_all_subcategories(db, category_id)


@router.get("/subcategories/all", response_model=List[SubcategoryResponse])
async def get_all_subcategories(db: Session = Depends(get_db)):
    """
    Get all subcategories across all categories.
    """
    return category_service.get_all_subcategories(db)


@router.get("/subcategories/{subcategory_id}", response_model=SubcategoryResponse)
async def get_subcategory(subcategory_id: int, db: Session = Depends(get_db)):
    """
    Get a specific subcategory by ID.
    """
    subcategory = category_service.get_subcategory_by_id(db, subcategory_id)
    if not subcategory:
        raise HTTPException(status_code=404, detail="Subcategory not found")
    return subcategory


@router.post("/subcategories", response_model=SubcategoryResponse, status_code=201)
async def create_subcategory(
    subcategory: SubcategoryCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new subcategory under a specific category.
    """
    return category_service.create_subcategory(db, subcategory)


@router.put("/subcategories/{subcategory_id}", response_model=SubcategoryResponse)
async def update_subcategory(
    subcategory_id: int,
    subcategory: SubcategoryUpdate,
    db: Session = Depends(get_db)
):
    """
    Update an existing subcategory.
    System subcategories can be modified but not deleted.
    """
    updated_subcategory = category_service.update_subcategory(db, subcategory_id, subcategory)
    if not updated_subcategory:
        raise HTTPException(status_code=404, detail="Subcategory not found")
    return updated_subcategory


@router.delete("/subcategories/{subcategory_id}", status_code=204)
async def delete_subcategory(subcategory_id: int, db: Session = Depends(get_db)):
    """
    Delete a subcategory.
    System subcategories cannot be deleted.
    Will fail if any transactions are associated with this subcategory.
    """
    success = category_service.delete_subcategory(db, subcategory_id)
    if not success:
        raise HTTPException(status_code=404, detail="Subcategory not found")
    return None


# ==================== Admin/Utility Endpoints ====================

@router.post("/seed", status_code=201)
async def seed_default_categories(db: Session = Depends(get_db)):
    """
    Seed the database with default categories and subcategories.
    This endpoint is typically called once during initial setup.
    """
    category_service.seed_default_categories(db)
    return {"message": "Default categories seeded successfully"}
