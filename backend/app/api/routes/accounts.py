from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.models.account import Account

router = APIRouter()


@router.get("")
async def get_accounts(db: Session = Depends(get_db)):
    """Get all accounts"""
    accounts = db.query(Account).all()
    return accounts


@router.get("/total_balance")
async def get_total_balance(db: Session = Depends(get_db)):
    """Get total balance across all accounts (credit balances are subtracted)"""
    accounts = db.query(Account).all()
    total = 0.0
    for account in accounts:
        # Credit accounts have positive balances when you owe money
        # So we need to negate them to subtract debt from net worth
        if account.account_type == 'credit':
            total -= account.current_balance
        else:
            total += account.current_balance
    return {"total_balance": total}
