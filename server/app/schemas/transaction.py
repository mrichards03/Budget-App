from pydantic import BaseModel, computed_field
from datetime import datetime
from typing import Optional, List


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
    # Splits information when a transaction is split across multiple subcategories
    is_split: bool = False
    splits: Optional[List["TransactionSplitResponse"]] = []
    
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


class TransactionSplitCreate(BaseModel):
    subcategory_id: int
    amount: float
    memo: Optional[str] = None


class TransactionSplitResponse(BaseModel):
    id: int
    subcategory_id: int
    amount: float
    memo: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class CreateSplitsRequest(BaseModel):
    splits: List[TransactionSplitCreate]
    replace_existing: bool = True


# Resolve forward references for Pydantic models
try:
    TransactionResponse.update_forward_refs()
except Exception:
    pass
