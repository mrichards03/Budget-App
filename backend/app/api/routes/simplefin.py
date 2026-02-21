from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from sqlalchemy.orm import Session
import logging
import requests
import base64
from app.core.config import settings
from app.core.database import get_db
from app.services.simplefin_service import SimplefinService
from app.services.account_service import AccountService
from app.services.transaction_service import TransactionService
from app.models import Organization

router = APIRouter()
logger = logging.getLogger(__name__)


# Initialize services
transaction_service = TransactionService()
account_service = AccountService()
simplefin_service = SimplefinService(account_service, transaction_service)

@router.get("/institutions")
async def get_institutions(db: Session = Depends(get_db)):
    """
    Get all currently connected institutions.
    Used to check if an institution is already connected.
    """
    return db.query(Organization)


@router.post("/connect")
async def connect(access_code: str, db: Session = Depends(get_db)):
    # Python 3: decode base64 string
    claim_url = base64.b64decode(access_code).decode('utf-8')
    # Enforce HTTPS only
    if not claim_url.lower().startswith('https://'):
        raise HTTPException(status_code=400, detail="Only HTTPS URLs are allowed for security.")

    try:
        response = requests.post(claim_url, verify=True)
    except requests.exceptions.SSLError:
        raise HTTPException(status_code=400, detail="SSL certificate verification failed.")

    if response.status_code == 403:
        # Notify user that token may be compromised
        raise HTTPException(
            status_code=403,
            detail="Access denied when claiming Access URL. Your token may be compromised. Please disable the token and contact support."
        )
    elif response.status_code != 200:
        # Display sanitized error message
        error_msg = response.text[:200].replace('\n', ' ').replace('\r', ' ')
        raise HTTPException(status_code=response.status_code, detail=f"Error claiming Access URL: {error_msg}")

    try:
        access_url = response.text
        success, msg = simplefin_service.add_access_token(access_url, db)
        if success:
            acc_success, acc_msg = simplefin_service.get_accounts(access_url, db)
            if(not acc_success):
                raise HTTPException(status_code=500, detail=f"Failed to fetch/store accounts: {acc_msg}")
            db.commit()
        else:
            raise HTTPException(status_code=500, detail=f"Failed to store access_token: {msg}")
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Failed to get/store accounts and transactions: {ex}")


