from sqlalchemy.orm import Session
from typing import List, Optional
from fastapi import HTTPException
from datetime import datetime
import logging

from app.models.budget import Budget, SubcategoryBudget
from app.models.category import Category, Subcategory
from app.models.transaction import Transaction
from app.schemas.budget import BudgetCreate, BudgetUpdate, SubcategoryBudgetCreate

logger = logging.getLogger(__name__)


class BudgetService:
    """Service for managing budgets and subcategory budget allocations (envelope budgeting)."""
    
    def get_all_budgets(self, db: Session) -> List[Budget]:
        """Get all budgets."""
        return db.query(Budget).all()
    
    def get_budget_by_id(self, db: Session, budget_id: int) -> Optional[Budget]:
        """Get a specific budget by ID."""
        return db.query(Budget).filter(Budget.id == budget_id).first()
    
    def get_current_budget(self, db: Session) -> Optional[Budget]:
        """Get the most recent/current budget."""
        now = datetime.utcnow()
        
        # Try to find a budget that's currently active
        # Active = start_date <= now AND (end_date is null OR end_date >= now)
        budget = db.query(Budget).filter(
            Budget.start_date <= now
        ).filter(
            (Budget.end_date == None) | (Budget.end_date >= now)
        ).order_by(Budget.start_date.desc()).first()
        
        # If no active budget, return the most recent one
        if not budget:
            budget = db.query(Budget).order_by(Budget.created_at.desc()).first()
        
        return budget
    
    def create_budget(self, db: Session, budget_data: BudgetCreate) -> Budget:
        """Create a new budget with subcategory allocations."""
        # Validate that end_date is after start_date if provided
        if budget_data.end_date and budget_data.end_date <= budget_data.start_date:
            raise HTTPException(
                status_code=400,
                detail="End date must be after start date"
            )
        
        # Create the budget
        db_budget = Budget(
            name=budget_data.name,
            start_date=budget_data.start_date,
            end_date=budget_data.end_date
        )
        db.add(db_budget)
        db.flush()  # Flush to get the budget ID
        
        # Create subcategory budget allocations
        for subcat_budget_data in budget_data.subcategory_budgets:
            # Verify subcategory exists
            subcategory = db.query(Subcategory).filter(
                Subcategory.id == subcat_budget_data.subcategory_id
            ).first()
            if not subcategory:
                raise HTTPException(
                    status_code=404,
                    detail=f"Subcategory with ID {subcat_budget_data.subcategory_id} not found"
                )
            
            db_subcat_budget = SubcategoryBudget(
                budget_id=db_budget.id,
                subcategory_id=subcat_budget_data.subcategory_id,
                allocated_amount=subcat_budget_data.allocated_amount
            )
            db.add(db_subcat_budget)
        
        db.commit()
        db.refresh(db_budget)
        logger.info(f"Created budget: {db_budget.name} (ID: {db_budget.id})")
        return db_budget
    
    def update_budget(
        self,
        db: Session,
        budget_id: int,
        budget_data: BudgetUpdate
    ) -> Optional[Budget]:
        """Update an existing budget."""
        db_budget = self.get_budget_by_id(db, budget_id)
        if not db_budget:
            return None
        
        # Update only provided fields
        update_data = budget_data.model_dump(exclude_unset=True)
        
        # Validate dates if being updated
        start_date = update_data.get("start_date", db_budget.start_date)
        end_date = update_data.get("end_date", db_budget.end_date)
        if end_date and end_date <= start_date:
            raise HTTPException(
                status_code=400,
                detail="End date must be after start date"
            )
        
        for field, value in update_data.items():
            setattr(db_budget, field, value)
        
        db.commit()
        db.refresh(db_budget)
        logger.info(f"Updated budget: {db_budget.name} (ID: {db_budget.id})")
        return db_budget
    
    def delete_budget(self, db: Session, budget_id: int) -> bool:
        """Delete a budget and all its subcategory allocations."""
        db_budget = self.get_budget_by_id(db, budget_id)
        if not db_budget:
            return False
        
        db.delete(db_budget)
        db.commit()
        logger.info(f"Deleted budget ID: {budget_id}")
        return True
    
    def get_subcategory_budgets(self, db: Session, budget_id: int) -> List[SubcategoryBudget]:
        """Get all subcategory budget allocations for a specific budget."""
        return db.query(SubcategoryBudget).filter(
            SubcategoryBudget.budget_id == budget_id
        ).all()
    
    def update_subcategory_budget(
        self,
        db: Session,
        subcategory_budget_id: int,
        allocated_amount: float
    ) -> Optional[SubcategoryBudget]:
        """Update the allocated amount for a subcategory budget."""
        db_subcat_budget = db.query(SubcategoryBudget).filter(
            SubcategoryBudget.id == subcategory_budget_id
        ).first()
        
        if not db_subcat_budget:
            return None
        
        db_subcat_budget.allocated_amount = allocated_amount
        db.commit()
        db.refresh(db_subcat_budget)
        return db_subcat_budget
    
    def get_spending_by_subcategory(
        self,
        db: Session,
        budget_id: int
    ) -> dict:
        """Get current spending for each subcategory in a budget."""
        budget = self.get_budget_by_id(db, budget_id)
        if not budget:
            return {}
        
        spending = {}
        for subcat_budget in budget.subcategory_budgets:
            # Get all transactions for this subcategory in the budget period
            query = db.query(Transaction).filter(
                Transaction.subcategory_id == subcat_budget.subcategory_id,
                Transaction.date >= budget.start_date,
                Transaction.amount < 0  # Only expenses
            )
            
            # If budget has an end date, filter by it
            if budget.end_date:
                query = query.filter(Transaction.date <= budget.end_date)
            
            transactions = query.all()
            total_spent = abs(sum(t.amount for t in transactions))
            spending[subcat_budget.subcategory_id] = total_spent
        
        return spending
