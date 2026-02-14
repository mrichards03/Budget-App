from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class Account(Base):
    __tablename__ = "accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    plaid_account_id = Column(String, unique=True, index=True)
    plaid_item_id = Column(String, index=True)
    
    name = Column(String)
    official_name = Column(String, nullable=True)
    account_type = Column(String)  # depository, credit, etc.
    account_subtype = Column(String)  # checking, savings, credit card, etc.
    
    current_balance = Column(Float, default=0.0)
    available_balance = Column(Float, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    transactions = relationship("Transaction", back_populates="account")
