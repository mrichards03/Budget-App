from sqlalchemy import Column, Integer, String, DateTime, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime


class Budget(Base):
    __tablename__ = "budgets"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=True)  # Optional - null means ongoing
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    subcategory_budgets = relationship("SubcategoryBudget", back_populates="budget", cascade="all, delete-orphan")


class SubcategoryBudget(Base):
    __tablename__ = "subcategory_budgets"
    
    id = Column(Integer, primary_key=True, index=True)
    budget_id = Column(Integer, ForeignKey("budgets.id"), nullable=False)
    subcategory_id = Column(Integer, ForeignKey("subcategories.id"), nullable=False)
    allocated_amount = Column(Float, nullable=False, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    budget = relationship("Budget", back_populates="subcategory_budgets")
    subcategory = relationship("Subcategory")
