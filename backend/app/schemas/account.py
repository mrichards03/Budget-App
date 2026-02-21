from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class AccountBase(BaseModel):
    name: str

class AccountResponse(AccountBase):
    id: str
    currency_code: str
    current_balance: float
    available_balance: Optional[float] = None
    balance_date: datetime
    organization_domain: str
    account_type: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
