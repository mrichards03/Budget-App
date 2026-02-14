from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class Merchant(Base):
    __tablename__ = "merchants"
    
    id = Column(Integer, primary_key=True, index=True)
    plaid_entity_id = Column(String, unique=True, index=True, nullable=True)
    
    name = Column(String)
    type = Column(String, nullable=True)  # "merchant", "marketplace", etc.
    logo_url = Column(String, nullable=True)
    website = Column(String, nullable=True)
    confidence_level = Column(String, nullable=True)
    
    # Relationships
    transactions = relationship("Transaction", secondary="transaction_merchants", back_populates="merchants")