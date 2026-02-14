from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class Account(Base):
    __tablename__ = "accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    plaid_account_id = Column(String, unique=True, index=True)
    plaid_item_id = Column(String, ForeignKey('plaid_items.item_id'), index=True)
    
    name = Column(String)
    official_name = Column(String, nullable=True)
    mask = Column(String, nullable=True)

    account_type = Column(String)  # depository, credit, etc.
    account_subtype = Column(String)  # checking, savings, credit card, etc.
    holder_category = Column(String, nullable=True)

    current_balance = Column(Float, default=0.0)
    available_balance = Column(Float, nullable=True)
    limit = Column(Float, nullable=True)
    currency_code = Column(String, default="CAD")
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    plaid_item = relationship("PlaidItem", back_populates="accounts")
    transactions = relationship("Transaction", back_populates="account", foreign_keys="[Transaction.account_id]")
