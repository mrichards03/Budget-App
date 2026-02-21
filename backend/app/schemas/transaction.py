from pydantic import BaseModel, computed_field
from datetime import datetime
from typing import Optional


class TransactionBase(BaseModel):
    """Base fields for transaction creation"""
    amount: float
    name: str
    memo: Optional[str] = None


class TransactionUpdate(BaseModel):
    """Schema for updating a transaction"""
    memo: Optional[str] = None
    subcategory_id: Optional[int] = None


class TransactionResponse(BaseModel):
    """Clean transaction response for frontend"""
    id: int
    account_id: str
    amount: float
    posted: datetime
    transacted_at: Optional[datetime] = None
    name: str
    memo: Optional[str] = None
    subcategory_id: Optional[int] = None
    pending: bool
    created_at: datetime
    
    # Transfer information
    is_transfer: bool = False
    transfer_account_id: Optional[int] = None
    
    # ML prediction fields
    predicted_subcategory_id: Optional[int] = None
    predicted_confidence: Optional[float] = None
    
    @computed_field
    @property
    def effective_date(self) -> datetime:
        """Return transacted_at if available, otherwise posted date"""
        return self.transacted_at or self.posted
        
    class Config:
        from_attributes = True


class CategorizeTransactionRequest(BaseModel):
    """Request to categorize a transaction"""
    subcategory_id: int
