from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class Account(Base):
    __tablename__ = "accounts"
    
    id = Column(String, primary_key=True)
    organization_domain = Column(String, ForeignKey('organizations.domain'), primary_key=True)

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
    
    balance_date = Column(DateTime)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    organization = relationship("Organization", back_populates="accounts")
    transactions = relationship("Transaction", back_populates="account", foreign_keys="[Transaction.account_id]")
