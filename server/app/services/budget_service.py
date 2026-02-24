from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from typing import List, Optional, Dict
from fastapi import HTTPException
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import calendar
import logging

from app.models.budget import Budget, SubcategoryBudget
from app.models.category import Category, Subcategory
from app.models.transaction import Transaction
from app.models.transaction_split import TransactionSplit
from app.schemas.budget import BudgetCreate, BudgetUpdate, SubcategoryBudgetCreate, SubcategoryBudgetResponse

logger = logging.getLogger(__name__)


class BudgetService:
    """Service for managing budgets and subcategory budget allocations (envelope budgeting)."""
    
    def get_all_budgets(self, db: Session) -> List[Budget]:
        """Get all budgets."""
        return db.query(Budget).all()
    
    def get_budget_by_id(self, db: Session, budget_id: int, eager_load: bool = True) -> Optional[Budget]:
        """Get a specific budget by ID with optional eager loading."""
        query = db.query(Budget)
        if eager_load:
            query = query.options(
                joinedload(Budget.subcategory_budgets)
                .joinedload(SubcategoryBudget.subcategory)
                .joinedload(Subcategory.category)
            )
        return query.filter(Budget.id == budget_id).first()
    
    def get_current_budget(self, db: Session, eager_load: bool = True) -> Optional[Budget]:
        """Get or create the current month's budget with optional eager loading."""
        now = datetime.utcnow()
        return self.get_budget_by_month(db, now.year, now.month, eager_load=eager_load)
    
    def get_budget_by_month(self, db: Session, year: int, month: int, eager_load: bool = True, auto_create: bool = True) -> Optional[Budget]:
        """Get or optionally create a budget for a specific month/year."""
        query = db.query(Budget)
        if eager_load:
            query = query.options(
                joinedload(Budget.subcategory_budgets)
                .joinedload(SubcategoryBudget.subcategory)
                .joinedload(Subcategory.category)
            )
        
        budget = query.filter(
            Budget.month == month,
            Budget.year == year
        ).first()
        
        if not budget and auto_create:
            budget = self._create_monthly_budget(db, month, year)
            if eager_load:
                budget = self.get_budget_by_id(db, budget.id, eager_load=True)
        else:
            now = datetime.now()
            if year > now.year or (year == now.year and month > now.month):
                self._update_future_budget(db, budget)
        
        return budget
    
    def create_budget(self, db: Session, budget_data: BudgetCreate) -> Budget:
        """Create a new budget with subcategory allocations."""
        db_budget = Budget(
            name=budget_data.name,
            month=budget_data.month,
            year=budget_data.year
        )
        db.add(db_budget)
        db.flush()
        
        for subcat_budget_data in budget_data.subcategory_budgets:
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
                monthly_assigned=subcat_budget_data.monthly_assigned,
                monthly_target=subcat_budget_data.monthly_target,
                total_balance=0.0
            )
            db.add(db_subcat_budget)
        
        db.commit()
        db_budget = self.get_budget_by_id(db, db_budget.id, eager_load=True)
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
        
        update_data = budget_data.model_dump(exclude_unset=True)
        
        for field, value in update_data.items():
            setattr(db_budget, field, value)
        
        db.commit()
        db_budget = self.get_budget_by_id(db, db_budget.id, eager_load=True)
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
        monthly_assigned: float
    ) -> Optional[SubcategoryBudget]:
        """Update the monthly assigned amount for a subcategory budget."""
        db_subcat_budget = db.query(SubcategoryBudget).filter(
            SubcategoryBudget.id == subcategory_budget_id
        ).first()
        
        if not db_subcat_budget:
            return None
        
        db_subcat_budget.monthly_assigned = monthly_assigned
        db.commit()
        db.refresh(db_subcat_budget)
        return db_subcat_budget
    
    def get_spending_by_subcategory(
        self,
        db: Session,
        budget_id: int
    ) -> Dict[int, float]:
        """Get current spending for each subcategory in a budget."""
        budget = self.get_budget_by_id(db, budget_id, eager_load=False)
        if not budget:
            return {}
        
        spending = {}
        for subcat_budget in budget.subcategory_budgets:
            subcat_id = subcat_budget.subcategory_id

            # Sum amounts for transactions directly categorized to the subcategory
            query = db.query(func.sum(Transaction.amount)).filter(
                Transaction.subcategory_id == subcat_id,
                Transaction.posted >= budget.start_date,
                Transaction.is_transfer == False
            )
            if budget.end_date:
                query = query.filter(Transaction.posted <= budget.end_date)

            direct_total = query.scalar() or 0.0

            # Sum amounts for splits that allocate to this subcategory
            split_query = db.query(func.sum(TransactionSplit.amount)).join(
                Transaction, Transaction.id == TransactionSplit.transaction_id
            ).filter(
                TransactionSplit.subcategory_id == subcat_id,
                Transaction.posted >= budget.start_date,
                Transaction.is_transfer == False
            )
            if budget.end_date:
                split_query = split_query.filter(Transaction.posted <= budget.end_date)

            splits_total = split_query.scalar() or 0.0

            # We're dealing with spending (outflows) so take absolute of negative sums
            combined = float(direct_total or 0.0) + float(splits_total or 0.0)
            total_spent = abs(combined)
            spending[subcat_id] = total_spent
        
        return spending
    
    def build_subcategory_budget_responses(
        self,
        budget: Budget,
        spending_by_subcategory: Dict[int, float]
    ) -> List[SubcategoryBudgetResponse]:
        """Build subcategory budget response list from budget with eager-loaded relationships."""
        subcategory_budgets = []
        
        for subcat_budget in budget.subcategory_budgets:
            subcategory = subcat_budget.subcategory
            if subcategory:
                category = subcategory.category
                monthly_activity = spending_by_subcategory.get(subcat_budget.subcategory_id, 0.0)
                monthly_available = subcat_budget.monthly_target - monthly_activity
                
                subcategory_budgets.append(
                    SubcategoryBudgetResponse(
                        id=subcat_budget.id,
                        budget_id=subcat_budget.budget_id,
                        subcategory_id=subcat_budget.subcategory_id,
                        category_name=category.name if category else "Unknown",
                        subcategory_name=subcategory.name,
                        monthly_assigned=subcat_budget.monthly_assigned,
                        monthly_target=subcat_budget.monthly_target,
                        total_balance=subcat_budget.total_balance,
                        monthly_activity=monthly_activity,
                        monthly_available=monthly_available,
                        created_at=subcat_budget.created_at,
                        updated_at=subcat_budget.updated_at
                    )
                )
        
        return subcategory_budgets
    
    def _update_future_budget(self, db: Session, future_budget: Budget):
        all_subcategories = db.query(Subcategory).all()
        
        # Calculate previous month/year
        if future_budget.month == 1:
            prev_month = 12
            prev_year = future_budget.year - 1
        else:
            prev_month = future_budget.month - 1
            prev_year = future_budget.year
        
        previous_budget = db.query(Budget).filter(
            Budget.month == prev_month,
            Budget.year == prev_year
        ).first()
        
        previous_balances = {}
        if previous_budget:
            spending = self.get_spending_by_subcategory(db, previous_budget.id)
            for prev_subcat in previous_budget.subcategory_budgets:
                monthly_activity = spending.get(prev_subcat.subcategory_id, 0.0)
                total_balance = prev_subcat.total_balance + prev_subcat.monthly_assigned - monthly_activity
                previous_balances[prev_subcat.subcategory_id] = total_balance
        
        for subcategory in all_subcategories:
            prev_balance = previous_balances.get(subcategory.id, 0.0)
            db_subcat_budget = db.query(SubcategoryBudget).filter(SubcategoryBudget.budget_id == future_budget.id, SubcategoryBudget.subcategory_id == subcategory.id).first()
            db_subcat_budget.total_balance=prev_balance
        
        db.commit()
        logger.info(f"Auto-updated monthly budget: {future_budget.name} ({future_budget.month}/{future_budget.year})")

    def _create_monthly_budget(self, db: Session, month: int, year: int) -> Budget:
        """Create a new monthly budget with rollover from previous month."""
        month_start = datetime(year, month, 1)
        budget_name = month_start.strftime("%b %Y")
        
        db_budget = Budget(
            name=budget_name,
            month=month,
            year=year
        )
        db.add(db_budget)
        db.flush()
        
        all_subcategories = db.query(Subcategory).all()
        
        # Calculate previous month/year
        if month == 1:
            prev_month = 12
            prev_year = year - 1
        else:
            prev_month = month - 1
            prev_year = year
        
        previous_budget = db.query(Budget).filter(
            Budget.month == prev_month,
            Budget.year == prev_year
        ).first()
        
        previous_balances = {}
        if previous_budget:
            spending = self.get_spending_by_subcategory(db, previous_budget.id)
            for prev_subcat in previous_budget.subcategory_budgets:
                monthly_activity = spending.get(prev_subcat.subcategory_id, 0.0)
                monthly_available = prev_subcat.total_balance + prev_subcat.monthly_assigned - monthly_activity
                previous_balances[prev_subcat.subcategory_id] = monthly_available
        
        for subcategory in all_subcategories:
            prev_balance = previous_balances.get(subcategory.id, 0.0)
            
            db_subcat_budget = SubcategoryBudget(
                budget_id=db_budget.id,
                subcategory_id=subcategory.id,
                monthly_assigned=0.0,
                monthly_target=0.0,
                total_balance=prev_balance
            )
            db.add(db_subcat_budget)
        
        db.commit()
        logger.info(f"Auto-created monthly budget: {budget_name} ({month}/{year})")
        return db_budget
    
    def update_monthly_target(
        self,
        db: Session,
        subcategory_budget_id: int,
        monthly_target: float
    ) -> Optional[SubcategoryBudget]:
        """Update the monthly target for a subcategory budget."""
        db_subcat_budget = db.query(SubcategoryBudget).filter(
            SubcategoryBudget.id == subcategory_budget_id
        ).first()
        
        if not db_subcat_budget:
            return None
        
        db_subcat_budget.monthly_target = monthly_target
        db.commit()
        db.refresh(db_subcat_budget)
        return db_subcat_budget
