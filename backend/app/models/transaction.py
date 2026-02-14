from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    plaid_transaction_id = Column(String, unique=True, index=True)
    account_id = Column(Integer, ForeignKey("accounts.id"))
    
    amount = Column(Float)
    date = Column(DateTime)
    name = Column(String)
    merchant_name = Column(String, nullable=True)
    
    category = Column(String, nullable=True)  # Primary category
    category_detailed = Column(String, nullable=True)  # Detailed category
    
    pending = Column(Boolean, default=False)
    
    # ML predicted category (for your custom categorization)
    predicted_category = Column(String, nullable=True)
    predicted_confidence = Column(Float, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    account = relationship("Account", back_populates="transactions")
