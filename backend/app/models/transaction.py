from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime
from typing import Optional

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    plaid_transaction_id = Column(String, unique=True, index=True)
    account_id = Column(Integer, ForeignKey("accounts.id"))
    
    # Basic transaction info
    amount = Column(Float)
    date = Column(DateTime)
    authorized_datetime = Column(DateTime, nullable=True)
    name = Column(String)  # Raw transaction name
    
    # Plaid categories
    category_primary = Column(String, nullable=True)
    category_detailed = Column(String, nullable=True)
    category_confidence = Column(String, nullable=True)
    
    # Transaction metadata
    pending = Column(Boolean, default=False)
    pending_transaction_id = Column(String, nullable=True)
    payment_channel = Column(String, nullable=True)

    # Transfer detection - important for credit card payments, account transfers
    is_transfer = Column(Boolean, default=False)
    transfer_account_id = Column(Integer, ForeignKey("accounts.id"), nullable=True)  # Link to other account
    transfer_transaction_id = Column(String, nullable=True)  # Plaid's transfer matching ID
    
    # Payment metadata (for transfers, bill payments)
    payment_meta = Column(JSON, nullable=True)  # Store full payment_meta object
    
    # Location (store as JSON)
    location = Column(JSON, nullable=True)
    
    # ML predicted category (for your custom categorization)
    predicted_category = Column(String, nullable=True)
    predicted_confidence = Column(Float, nullable=True)
    
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
    subcategory = relationship("Subcategory", back_populates="transactions")
    
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