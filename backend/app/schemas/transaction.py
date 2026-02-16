from pydantic import BaseModel, computed_field
from datetime import datetime
from typing import Optional


class TransactionBase(BaseModel):
    """Base fields for transaction creation"""
    amount: float
    name: str
    memo: Optional[str] = None


class TransactionCreate(TransactionBase):
    """Schema for creating a new transaction (internal use)"""
    plaid_transaction_id: str
    account_id: int
    date: datetime
    authorized_datetime: Optional[datetime] = None
    pending: bool = False


class TransactionUpdate(BaseModel):
    """Schema for updating a transaction"""
    memo: Optional[str] = None
    subcategory_id: Optional[int] = None


class TransactionResponse(BaseModel):
    """Clean transaction response for frontend - no plaid internals"""
    id: int
    account_id: int
    amount: float
    date: datetime
    authorized_datetime: Optional[datetime] = None
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
    
    # Merchant name (filtered by confidence at ORM level via @property)
    merchant_name: Optional[str] = None
    
    @computed_field
    @property
    def effective_date(self) -> datetime:
        """Return authorized_datetime if available, otherwise date"""
        return self.authorized_datetime or self.date
    
    @computed_field
    @property
    def display_name(self) -> str:
        """Return merchant_name if available (and high confidence), otherwise raw name"""
        return self.merchant_name or self.name
    
    class Config:
        from_attributes = True


class CategorizeTransactionRequest(BaseModel):
    """Request to categorize a transaction"""
    subcategory_id: int
