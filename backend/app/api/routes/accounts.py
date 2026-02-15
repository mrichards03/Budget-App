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
    """Get total balance across all accounts"""
    accounts = db.query(Account).all()
    total = sum(account.current_balance for account in accounts)
    return {"total_balance": total}
