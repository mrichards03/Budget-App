from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class TransactionBase(BaseModel):
    amount: float
    date: datetime
    name: str
    merchant_name: Optional[str] = None
    category: Optional[str] = None
    category_detailed: Optional[str] = None

class TransactionCreate(TransactionBase):
    plaid_transaction_id: str
    account_id: int

class TransactionResponse(TransactionBase):
    id: int
    plaid_transaction_id: str
    account_id: int
    predicted_category: Optional[str] = None
    predicted_confidence: Optional[float] = None
    pending: bool
    created_at: datetime
    
    class Config:
        from_attributes = True
