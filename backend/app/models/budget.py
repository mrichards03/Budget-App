from sqlalchemy import Column, Integer, String, DateTime, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime
import calendar


class Budget(Base):
    __tablename__ = "budgets"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    month = Column(Integer, nullable=False)
    year = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    subcategory_budgets = relationship("SubcategoryBudget", back_populates="budget", cascade="all, delete-orphan")
    
    @property
    def start_date(self):
        """Calculate start date from month and year."""
        return datetime(self.year, self.month, 1)
    
    @property
    def end_date(self):
        """Calculate end date from month and year."""
        last_day = calendar.monthrange(self.year, self.month)[1]
        return datetime(self.year, self.month, last_day, 23, 59, 59)


class SubcategoryBudget(Base):
    __tablename__ = "subcategory_budgets"
    
    id = Column(Integer, primary_key=True, index=True)
    budget_id = Column(Integer, ForeignKey("budgets.id"), nullable=False)
    subcategory_id = Column(Integer, ForeignKey("subcategories.id"), nullable=False)
    monthly_assigned = Column(Float, nullable=False, default=0.0)
    monthly_target = Column(Float, nullable=False, default=0.0)
    total_balance = Column(Float, nullable=False, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    budget = relationship("Budget", back_populates="subcategory_budgets")
    subcategory = relationship("Subcategory")
