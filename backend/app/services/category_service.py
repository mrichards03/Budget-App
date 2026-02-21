from sqlalchemy.orm import Session
from typing import List, Optional
from fastapi import HTTPException
import logging

from app.models.category import Category, Subcategory
from app.schemas.category import (
    CategoryCreate, CategoryUpdate, 
    SubcategoryCreate, SubcategoryUpdate
)
from app.models.transaction import Transaction

logger = logging.getLogger(__name__)


class CategoryService:
    """Service for managing budget categories and subcategories."""
    
    # ==================== Category CRUD ====================
    
    def get_all_categories(self, db: Session, include_subcategories: bool = True) -> List[Category]:
        """Get all categories, optionally with subcategories."""
        from sqlalchemy.orm import joinedload, noload
        
        query = db.query(Category)
        if include_subcategories:
            # Eagerly load subcategories to avoid N+1 queries
            query = query.options(joinedload(Category.subcategories))
        else:
            # Explicitly don't load subcategories
            query = query.options(noload(Category.subcategories))
        
        return query.all()
    
    def get_category_by_id(self, db: Session, category_id: int) -> Optional[Category]:
        """Get a specific category by ID."""
        return db.query(Category).filter(Category.id == category_id).first()
    
    def get_category_by_name(self, db: Session, name: str) -> Optional[Category]:
        """Get a specific category by name."""
        return db.query(Category).filter(Category.name == name).first()
    
    def create_category(self, db: Session, category_data: CategoryCreate) -> Category:
        """Create a new category."""
        # Check if category with same name already exists
        existing = self.get_category_by_name(db, category_data.name)
        if existing:
            raise HTTPException(
                status_code=400, 
                detail=f"Category with name '{category_data.name}' already exists"
            )
        
        db_category = Category(
            name=category_data.name,
            color=category_data.color,
            icon=category_data.icon
        )
        db.add(db_category)
        db.commit()
        db.refresh(db_category)
        logger.info(f"Created category: {db_category.name}")
        return db_category
    
    def update_category(
        self, 
        db: Session, 
        category_id: int, 
        category_data: CategoryUpdate
    ) -> Optional[Category]:
        """Update an existing category."""
        db_category = self.get_category_by_id(db, category_id)
        if not db_category:
            return None
        
        # Update only provided fields
        update_data = category_data.model_dump(exclude_unset=True)
        
        # Check for name conflicts if name is being updated
        if "name" in update_data and update_data["name"] != db_category.name:
            existing = self.get_category_by_name(db, update_data["name"])
            if existing:
                raise HTTPException(
                    status_code=400, 
                    detail=f"Category with name '{update_data['name']}' already exists"
                )
        
        for field, value in update_data.items():
            setattr(db_category, field, value)
        
        db.commit()
        db.refresh(db_category)
        logger.info(f"Updated category: {db_category.name}")
        return db_category
    
    def delete_category(self, db: Session, category_id: int) -> bool:
        """
        Delete a category and all its subcategories.
        System categories cannot be deleted.
        """
        db_category = self.get_category_by_id(db, category_id)
        if not db_category:
            return False
        
        # Check if any transactions are using this category
        has_transactions = any(
            db.query(Transaction).filter(Transaction.subcategory_id == subcat.id).first()
            for subcat in db_category.subcategories
        )
        if has_transactions:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot delete category '{db_category.name}' because it has associated transactions. "
                       f"Please reassign or delete those transactions first."
            )
        
        db.delete(db_category)
        db.commit()
        logger.info(f"Deleted category: {db_category.name}")
        return True
    
    # ==================== Subcategory CRUD ====================
    
    def get_all_subcategories(self, db: Session, category_id: Optional[int] = None) -> List[Subcategory]:
        """Get all subcategories, optionally filtered by category."""
        query = db.query(Subcategory)
        if category_id:
            query = query.filter(Subcategory.category_id == category_id)
        return query.all()
    
    def get_subcategory_by_id(self, db: Session, subcategory_id: int) -> Optional[Subcategory]:
        """Get a specific subcategory by ID."""
        return db.query(Subcategory).filter(Subcategory.id == subcategory_id).first()
    
    def create_subcategory(
        self, 
        db: Session, 
        subcategory_data: SubcategoryCreate
    ) -> Subcategory:
        """Create a new subcategory."""
        # Verify parent category exists
        category = self.get_category_by_id(db, subcategory_data.category_id)
        if not category:
            raise HTTPException(
                status_code=404, 
                detail=f"Category with id {subcategory_data.category_id} not found"
            )
        
        # Check for duplicate subcategory name within the same category
        existing = db.query(Subcategory).filter(
            Subcategory.category_id == subcategory_data.category_id,
            Subcategory.name == subcategory_data.name
        ).first()
        
        if existing:
            raise HTTPException(
                status_code=400,
                detail=f"Subcategory '{subcategory_data.name}' already exists in category '{category.name}'"
            )
        
        db_subcategory = Subcategory(
            category_id=subcategory_data.category_id,
            name=subcategory_data.name
        )
        db.add(db_subcategory)
        db.commit()
        db.refresh(db_subcategory)
        logger.info(f"Created subcategory: {db_subcategory.name} under {category.name}")
        return db_subcategory
    
    def update_subcategory(
        self, 
        db: Session, 
        subcategory_id: int, 
        subcategory_data: SubcategoryUpdate
    ) -> Optional[Subcategory]:
        """Update an existing subcategory."""
        db_subcategory = self.get_subcategory_by_id(db, subcategory_id)
        if not db_subcategory:
            return None
        
        update_data = subcategory_data.model_dump(exclude_unset=True)
        
        # Check for name conflicts if name is being updated
        if "name" in update_data and update_data["name"] != db_subcategory.name:
            existing = db.query(Subcategory).filter(
                Subcategory.category_id == db_subcategory.category_id,
                Subcategory.name == update_data["name"]
            ).first()
            if existing:
                raise HTTPException(
                    status_code=400,
                    detail=f"Subcategory '{update_data['name']}' already exists in this category"
                )
        
        for field, value in update_data.items():
            setattr(db_subcategory, field, value)
        
        db.commit()
        db.refresh(db_subcategory)
        logger.info(f"Updated subcategory: {db_subcategory.name}")
        return db_subcategory
    
    def delete_subcategory(self, db: Session, subcategory_id: int) -> bool:
        """
        Delete a subcategory.
        System subcategories cannot be deleted.
        """
        db_subcategory = self.get_subcategory_by_id(db, subcategory_id)
        if not db_subcategory:
            return False
        
        # Check if any transactions are using this subcategory
        if db_subcategory.transactions:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot delete subcategory '{db_subcategory.name}' because it has associated transactions. "
                       f"Please reassign or delete those transactions first."
            )
        
        db.delete(db_subcategory)
        db.commit()
        logger.info(f"Deleted subcategory: {db_subcategory.name}")
        return True
    
    # ==================== Seed Data ====================
    
    def seed_default_categories(self, db: Session) -> None:
        """
        Seed the database with default categories and subcategories.
        This is a one-time operation - if ANY categories exist, seeding is skipped
        to preserve user modifications. This means user changes are never overwritten.
        """
        logger.info("Checking if default budget categories need to be seeded...")
        
        # Check if ANY categories exist (including user-created ones)
        existing_count = db.query(Category).count()
        if existing_count > 0:
            logger.info(f"Found {existing_count} existing categories. Skipping seed to preserve user data.")
            return
        
        logger.info("No categories found. Seeding default categories...")
        
        default_categories = [
        {
            "name": "Bills",
            "color": "#FF5252",
            "icon": "receipt",
            "subcategories": [
                {"name": "Rent"},
                {"name": "Utilities"},
                {"name": "Insurance"},
                {"name": "Phone"},
                {"name": "Internet"},
                {"name": "Subscriptions"},
                {"name": "Gym Membership"}
            ]
        },
        {
            "name": "Needs",
            "color": "#4CAF50",
            "icon": "shopping_cart",
            "subcategories": [
                {"name": "Groceries"},
                {"name": "Gas"},
                {"name": "Public Transit"},
                {"name": "Healthcare"},
                {"name": "Car Maintenance"},
                {"name": "Household Supplies"}
            ]
        },
        {
            "name": "Wants",
            "color": "#2196F3",
            "icon": "favorite",
            "subcategories": [
                {"name": "Dining Out"},
                {"name": "Entertainment"},
                {"name": "Shopping"},
                {"name": "Gifts"},
                {"name": "Hobbies"},
                {"name": "Cigarettes & Alcohol"},
            ]
        },
        {
            "name": "Savings & Investments",
            "color": "#FFC107",
            "icon": "savings",
            "subcategories": [
                {"name": "Emergency Fund"},
                {"name": "General Savings"},
                {"name": "Travel"},
            ]
        },
        {
            "name": "Debt",
            "color": "#9C27B0",
            "icon": "credit_card",
            "subcategories": [
                {"name": "Student Loans"}
            ]
        },
        {
            "name": "Income",
            "color": "#00BCD4",
            "icon": "attach_money",
            "subcategories": [
                {"name": "Salary"},
                {"name": "Refunds"},
                {"name": "Other Income"},
            ]
        },
        {
            "name": "Transfers",
            "color": "#607D8B",
            "icon": "swap_horiz",
            "subcategories": [
                {"name": "Account Transfer"},
                {"name": "Credit Card Payment"},
            ]
        },
        {
            "name": "Other",
            "color": "#607D8B",
            "icon": "swap_horiz",
            "subcategories": [
                {"name": "Miscellaneous"},
            ]
        },
    ]
        
        for cat_data in default_categories:
            subcats = cat_data.pop("subcategories", [])
            
            # Create category
            category = Category(
                name=cat_data["name"],
                color=cat_data.get("color"),
                icon=cat_data.get("icon")
            )
            db.add(category)
            db.flush()  # Flush to get the ID
            
            # Create subcategories
            for subcat_data in subcats:
                subcategory = Subcategory(
                    category_id=category.id,
                    name=subcat_data["name"],
                )
                db.add(subcategory)
            
            logger.info(f"Created category '{category.name}' with {len(subcats)} subcategories")
        
        db.commit()
        logger.info("Default categories seeded successfully!")
