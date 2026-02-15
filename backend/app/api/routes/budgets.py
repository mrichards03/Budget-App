from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.services.budget_service import BudgetService
from app.schemas.budget import (
    BudgetResponse, BudgetSimpleResponse, BudgetCreate, BudgetUpdate,
    SubcategoryBudgetResponse
)
from app.models.category import Category, Subcategory

router = APIRouter()
budget_service = BudgetService()


@router.get("/current", response_model=BudgetResponse)
async def get_current_budget(db: Session = Depends(get_db)):
    """Get the current active budget with subcategory allocations and spending."""
    budget = budget_service.get_current_budget(db)
    
    if not budget:
        raise HTTPException(status_code=404, detail="No budget found")
    
    # Build response with current spending
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, budget.id)
    
    subcategory_budgets = []
    total_allocated = 0.0
    
    for subcat_budget in budget.subcategory_budgets:
        subcategory = db.query(Subcategory).filter(Subcategory.id == subcat_budget.subcategory_id).first()
        if subcategory:
            category = db.query(Category).filter(Category.id == subcategory.category_id).first()
            subcategory_budgets.append({
                "id": subcat_budget.id,
                "budget_id": subcat_budget.budget_id,
                "subcategory_id": subcat_budget.subcategory_id,
                "category_name": category.name if category else "Unknown",
                "subcategory_name": subcategory.name,
                "allocated_amount": subcat_budget.allocated_amount,
                "current_spending": spending_by_subcategory.get(subcat_budget.subcategory_id, 0.0),
                "created_at": subcat_budget.created_at,
                "updated_at": subcat_budget.updated_at
            })
            total_allocated += subcat_budget.allocated_amount
    
    return {
        "id": budget.id,
        "name": budget.name,
        "start_date": budget.start_date,
        "end_date": budget.end_date,
        "created_at": budget.created_at,
        "updated_at": budget.updated_at,
        "subcategory_budgets": subcategory_budgets,
        "total_allocated": total_allocated
    }


@router.get("/", response_model=List[BudgetSimpleResponse])
async def get_all_budgets(db: Session = Depends(get_db)):
    """Get all budgets without category details."""
    return budget_service.get_all_budgets(db)


@router.get("/{budget_id}", response_model=BudgetResponse)
async def get_budget(budget_id: int, db: Session = Depends(get_db)):
    """Get a specific budget by ID with subcategory allocations and spending."""
    budget = budget_service.get_budget_by_id(db, budget_id)
    
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    # Build response with current spending
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, budget.id)
    
    subcategory_budgets = []
    total_allocated = 0.0
    
    for subcat_budget in budget.subcategory_budgets:
        subcategory = db.query(Subcategory).filter(Subcategory.id == subcat_budget.subcategory_id).first()
        if subcategory:
            category = db.query(Category).filter(Category.id == subcategory.category_id).first()
            subcategory_budgets.append({
                "id": subcat_budget.id,
                "budget_id": subcat_budget.budget_id,
                "subcategory_id": subcat_budget.subcategory_id,
                "category_name": category.name if category else "Unknown",
                "subcategory_name": subcategory.name,
                "allocated_amount": subcat_budget.allocated_amount,
                "current_spending": spending_by_subcategory.get(subcat_budget.subcategory_id, 0.0),
                "created_at": subcat_budget.created_at,
                "updated_at": subcat_budget.updated_at
            })
            total_allocated += subcat_budget.allocated_amount
    
    return {
        "id": budget.id,
        "name": budget.name,
        "start_date": budget.start_date,
        "end_date": budget.end_date,
        "created_at": budget.created_at,
        "updated_at": budget.updated_at,
        "subcategory_budgets": subcategory_budgets,
        "total_allocated": total_allocated
    }


@router.post("/", response_model=BudgetResponse, status_code=201)
async def create_budget(
    budget: BudgetCreate,
    db: Session = Depends(get_db)
):
    """Create a new budget with subcategory allocations (envelope budgeting)."""
    db_budget = budget_service.create_budget(db, budget)
    
    # Build response
    subcategory_budgets = []
    total_allocated = 0.0
    
    for subcat_budget in db_budget.subcategory_budgets:
        subcategory = db.query(Subcategory).filter(Subcategory.id == subcat_budget.subcategory_id).first()
        if subcategory:
            category = db.query(Category).filter(Category.id == subcategory.category_id).first()
            subcategory_budgets.append({
                "id": subcat_budget.id,
                "budget_id": subcat_budget.budget_id,
                "subcategory_id": subcat_budget.subcategory_id,
                "category_name": category.name if category else "Unknown",
                "subcategory_name": subcategory.name,
                "allocated_amount": subcat_budget.allocated_amount,
                "current_spending": 0.0,
                "created_at": subcat_budget.created_at,
                "updated_at": subcat_budget.updated_at
            })
            total_allocated += subcat_budget.allocated_amount
    
    return {
        "id": db_budget.id,
        "name": db_budget.name,
        "start_date": db_budget.start_date,
        "end_date": db_budget.end_date,
        "created_at": db_budget.created_at,
        "updated_at": db_budget.updated_at,
        "subcategory_budgets": subcategory_budgets,
        "total_allocated": total_allocated
    }


@router.put("/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    budget_id: int,
    budget: BudgetUpdate,
    db: Session = Depends(get_db)
):
    """Update an existing budget."""
    updated_budget = budget_service.update_budget(db, budget_id, budget)
    if not updated_budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, updated_budget.id)
    
    subcategory_budgets = []
    total_allocated = 0.0
    
    for subcat_budget in updated_budget.subcategory_budgets:
        subcategory = db.query(Subcategory).filter(Subcategory.id == subcat_budget.subcategory_id).first()
        if subcategory:
            category = db.query(Category).filter(Category.id == subcategory.category_id).first()
            subcategory_budgets.append({
                "id": subcat_budget.id,
                "budget_id": subcat_budget.budget_id,
                "subcategory_id": subcat_budget.subcategory_id,
                "category_name": category.name if category else "Unknown",
                "subcategory_name": subcategory.name,
                "allocated_amount": subcat_budget.allocated_amount,
                "current_spending": spending_by_subcategory.get(subcat_budget.subcategory_id, 0.0),
                "created_at": subcat_budget.created_at,
                "updated_at": subcat_budget.updated_at
            })
            total_allocated += subcat_budget.allocated_amount
    
    return {
        "id": updated_budget.id,
        "name": updated_budget.name,
        "start_date": updated_budget.start_date,
        "end_date": updated_budget.end_date,
        "created_at": updated_budget.created_at,
        "updated_at": updated_budget.updated_at,
        "subcategory_budgets": subcategory_budgets,
        "total_allocated": total_allocated
    }


@router.delete("/{budget_id}", status_code=204)
async def delete_budget(budget_id: int, db: Session = Depends(get_db)):
    """Delete a budget and all its subcategory allocations."""
    success = budget_service.delete_budget(db, budget_id)
    if not success:
        raise HTTPException(status_code=404, detail="Budget not found")
    return None


@router.get("/{budget_id}/subcategories", response_model=List[SubcategoryBudgetResponse])
async def get_budget_subcategories(budget_id: int, db: Session = Depends(get_db)):
    """Get all subcategory allocations for a specific budget with current spending."""
    budget = budget_service.get_budget_by_id(db, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, budget_id)
    
    subcategory_budgets = []
    for subcat_budget in budget.subcategory_budgets:
        subcategory = db.query(Subcategory).filter(Subcategory.id == subcat_budget.subcategory_id).first()
        if subcategory:
            category = db.query(Category).filter(Category.id == subcategory.category_id).first()
            subcategory_budgets.append({
                "id": subcat_budget.id,
                "budget_id": subcat_budget.budget_id,
                "subcategory_id": subcat_budget.subcategory_id,
                "category_name": category.name if category else "Unknown",
                "subcategory_name": subcategory.name,
                "allocated_amount": subcat_budget.allocated_amount,
                "current_spending": spending_by_subcategory.get(subcat_budget.subcategory_id, 0.0),
                "created_at": subcat_budget.created_at,
                "updated_at": subcat_budget.updated_at
            })
    
    return subcategory_budgets


@router.put("/{budget_id}/subcategories/{subcategory_budget_id}")
async def update_subcategory_budget(
    budget_id: int,
    subcategory_budget_id: int,
    allocated_amount: float,
    db: Session = Depends(get_db)
):
    """Update the allocated amount for a specific subcategory in a budget."""
    # Verify budget exists
    budget = budget_service.get_budget_by_id(db, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    # Update subcategory budget
    updated = budget_service.update_subcategory_budget(db, subcategory_budget_id, allocated_amount)
    if not updated:
        raise HTTPException(status_code=404, detail="Subcategory budget not found")
    
    return {"success": True, "allocated_amount": allocated_amount}

