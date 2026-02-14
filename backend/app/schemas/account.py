from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class AccountBase(BaseModel):
    name: str
    official_name: Optional[str] = None
    account_type: str
    account_subtype: str

class AccountCreate(AccountBase):
    plaid_account_id: str
    plaid_item_id: str
    current_balance: float
    available_balance: Optional[float] = None

class AccountResponse(AccountBase):
    id: int
    plaid_account_id: str
    plaid_item_id: str
    current_balance: float
    available_balance: Optional[float] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
