
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import IntEnum


# Enum for account type (schema-only)
class AccountType(IntEnum):
    CHECKING = 0
    SAVINGS = 1
    CREDIT = 2
    INVESTMENT = 3
    LOAN = 4
    OTHER = 5

class AccountBase(BaseModel):
    name: str

class AccountResponse(AccountBase):
    id: str
    currency_code: str
    current_balance: float
    available_balance: Optional[float] = None
    balance_date: datetime
    organization_domain: str
    account_type: AccountType
    created_at: datetime

    class Config:
        from_attributes = True

        
class ChangeTypeRequest(BaseModel):
    new_type: int
