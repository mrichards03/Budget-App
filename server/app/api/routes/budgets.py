from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.services.budget_service import BudgetService
from app.schemas.budget import (
    BudgetResponse, BudgetSimpleResponse, BudgetCreate, BudgetUpdate,
    SubcategoryBudgetResponse
)

router = APIRouter()
budget_service = BudgetService()


@router.get("/current", response_model=BudgetResponse)
async def get_current_budget(db: Session = Depends(get_db)):
    """Get the current active budget with subcategory allocations and spending."""
    budget = budget_service.get_current_budget(db, eager_load=True)
    
    if not budget:
        raise HTTPException(status_code=404, detail="No budget found")
    
    # Build response with current spending
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, budget.id)
    subcategory_budgets = budget_service.build_subcategory_budget_responses(budget, spending_by_subcategory)
    
    return BudgetResponse(
        id=budget.id,
        name=budget.name,
        month=budget.month,
        year=budget.year,
        start_date=budget.start_date,
        created_at=budget.created_at,
        updated_at=budget.updated_at,
        subcategory_budgets=subcategory_budgets,
        total_allocated=sum(sb.total_balance for sb in subcategory_budgets)
    )


@router.get("/", response_model=List[BudgetSimpleResponse])
async def get_all_budgets(db: Session = Depends(get_db)):
    """Get all budgets without category details."""
    return budget_service.get_all_budgets(db)


@router.get("/{year}/{month}", response_model=BudgetResponse)
async def get_budget_by_month(year: int, month: int, db: Session = Depends(get_db)):
    """Get or create a budget for a specific month and year."""
    # Validate month
    if month < 1 or month > 12:
        raise HTTPException(status_code=400, detail="Month must be between 1 and 12")
    
    budget = budget_service.get_budget_by_month(db, year, month, eager_load=True, auto_create=True)
    
    if not budget:
        raise HTTPException(status_code=404, detail=f"Budget not found for {year}/{month}")
    
    # Build response with current spending
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, budget.id)
    subcategory_budgets = budget_service.build_subcategory_budget_responses(budget, spending_by_subcategory)
    
    return BudgetResponse(
        id=budget.id,
        name=budget.name,
        month=budget.month,
        year=budget.year,
        start_date=budget.start_date,
        created_at=budget.created_at,
        updated_at=budget.updated_at,
        subcategory_budgets=subcategory_budgets,
        total_allocated=sum(sb.total_balance for sb in subcategory_budgets)
    )


@router.get("/{budget_id}", response_model=BudgetResponse)
async def get_budget(budget_id: int, db: Session = Depends(get_db)):
    """Get a specific budget by ID with subcategory allocations and spending."""
    budget = budget_service.get_budget_by_id(db, budget_id, eager_load=True)
    
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    # Build response with current spending
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, budget.id)
    subcategory_budgets = budget_service.build_subcategory_budget_responses(budget, spending_by_subcategory)
    
    return BudgetResponse(
        id=budget.id,
        name=budget.name,
        month=budget.month,
        year=budget.year,
        start_date=budget.start_date,
        created_at=budget.created_at,
        updated_at=budget.updated_at,
        subcategory_budgets=subcategory_budgets,
        total_allocated=sum(sb.total_balance for sb in subcategory_budgets)
    )


@router.post("/", response_model=BudgetResponse, status_code=201)
async def create_budget(
    budget: BudgetCreate,
    db: Session = Depends(get_db)
):
    """Create a new budget with subcategory allocations (envelope budgeting)."""
    db_budget = budget_service.create_budget(db, budget)
    
    # Build response (spending is 0 for new budget)
    spending_by_subcategory = {}
    subcategory_budgets = budget_service.build_subcategory_budget_responses(db_budget, spending_by_subcategory)
    
    return BudgetResponse(
        id=db_budget.id,
        name=db_budget.name,
        month=db_budget.month,
        year=db_budget.year,
        start_date=db_budget.start_date,
        created_at=db_budget.created_at,
        updated_at=db_budget.updated_at,
        subcategory_budgets=subcategory_budgets,
        total_allocated=sum(sb.total_balance for sb in subcategory_budgets)
    )


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
    subcategory_budgets = budget_service.build_subcategory_budget_responses(updated_budget, spending_by_subcategory)
    
    return BudgetResponse(
        id=updated_budget.id,
        name=updated_budget.name,
        month=updated_budget.month,
        year=updated_budget.year,
        start_date=updated_budget.start_date,
        created_at=updated_budget.created_at,
        updated_at=updated_budget.updated_at,
        subcategory_budgets=subcategory_budgets,
        total_allocated=sum(sb.total_balance for sb in subcategory_budgets)
    )


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
    budget = budget_service.get_budget_by_id(db, budget_id, eager_load=True)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    spending_by_subcategory = budget_service.get_spending_by_subcategory(db, budget_id)
    return budget_service.build_subcategory_budget_responses(budget, spending_by_subcategory)


@router.put("/{budget_id}/subcategories/{subcategory_budget_id}")
async def update_subcategory_budget(
    budget_id: int,
    subcategory_budget_id: int,
    monthly_assigned: float = None,
    monthly_target: float = None,
    db: Session = Depends(get_db)
):
    """Update the monthly assigned amount or monthly target for a specific subcategory in a budget."""
    budget = budget_service.get_budget_by_id(db, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    if monthly_assigned is not None:
        updated = budget_service.update_subcategory_budget(db, subcategory_budget_id, monthly_assigned)
        if not updated:
            raise HTTPException(status_code=404, detail="Subcategory budget not found")
        return {"success": True, "monthly_assigned": monthly_assigned}
    
    if monthly_target is not None:
        updated = budget_service.update_monthly_target(db, subcategory_budget_id, monthly_target)
        if not updated:
            raise HTTPException(status_code=404, detail="Subcategory budget not found")
        return {"success": True, "monthly_target": monthly_target}
    
    raise HTTPException(status_code=400, detail="Must provide either monthly_assigned or monthly_target")

