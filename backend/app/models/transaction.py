from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime
from typing import Optional

class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, index=True, primary_key=True)
    
    account_id = Column(String, ForeignKey("accounts.id"))
    transaction_id = Column(String)
    
    # Basic transaction info
    amount = Column(Float)
    posted = Column(DateTime)
    transacted_at = Column(DateTime, nullable=True)
    name = Column(String)  # Raw transaction name
        
    # Transaction metadata
    pending = Column(Boolean, default=False)

    # Transfer detection - important for credit card payments, account transfers
    is_transfer = Column(Boolean, default=False)
    transfer_account_id = Column(Integer, ForeignKey("accounts.id"), nullable=True)  # Link to other account
    transfer_transaction_id = Column(Integer, nullable=True)  # Plaid's transfer matching ID
    
    # Location (store as JSON)
    location = Column(JSON, nullable=True)
    
    # ML predicted category (for your custom categorization)
    predicted_category = Column(String, nullable=True)  # Legacy field - not used
    predicted_confidence = Column(Float, nullable=True)  # Confidence score 0.0-1.0
    predicted_subcategory_id = Column(Integer, ForeignKey("subcategories.id"), nullable=True)  # ML prediction
    
    # User-defined budget category (subcategory contains the parent category)
    subcategory_id = Column(Integer, ForeignKey("subcategories.id"), nullable=True)
    
    # User-defined memo/note
    memo = Column(String, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    account = relationship("Account", back_populates="transactions", foreign_keys=[account_id])
    transfer_account = relationship("Account", foreign_keys=[transfer_account_id])
    merchants = relationship("Merchant", secondary="transaction_merchants", back_populates="transactions")
    subcategory = relationship("Subcategory", back_populates="transactions", foreign_keys=[subcategory_id], overlaps="predicted_subcategory")
    predicted_subcategory = relationship("Subcategory", foreign_keys=[predicted_subcategory_id], overlaps="subcategory,transactions")
    
    @property
    def merchant_name(self) -> Optional[str]:
        """Get merchant name(s) filtered by confidence level. Concatenates multiple merchants."""
        if self.merchants:
            # Filter merchants by confidence level and collect names
            merchant_names = [
                merchant.name
                for merchant in self.merchants
                if merchant.confidence_level and merchant.confidence_level.upper() != 'LOW'
            ]
            if merchant_names:
                return ', '.join(merchant_names)
        return None