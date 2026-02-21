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

from app.models.simplefin_item import SimplefinItem
from app.schemas.api_result import ApiResult

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

@router.get("/access-exists")
async def does_access_exist(db: Session = Depends(get_db)):
    try:
        exists = db.query(SimplefinItem).count() > 0
        return ApiResult.success(exists).__dict__
    except Exception as e:
        return ApiResult.error(str(e)).__dict__

@router.post("/connect")
async def connect(access_code: str, db: Session = Depends(get_db)):
    try:
        claim_url = base64.b64decode(access_code).decode('utf-8')
        if not claim_url.lower().startswith('https://'):
            return ApiResult.error("Only HTTPS URLs are allowed for security.").__dict__
        try:
            response = requests.post(claim_url, verify=True)
        except requests.exceptions.SSLError:
            return ApiResult.error("SSL certificate verification failed.").__dict__
        if response.status_code == 403:
            return ApiResult.error("Access denied when claiming Access URL. Your token may be compromised. Please disable the token and contact support.").__dict__
        elif response.status_code != 200:
            error_msg = response.text[:200].replace('\n', ' ').replace('\r', ' ')
            return ApiResult.error(f"Error claiming Access URL: {error_msg}").__dict__
        access_url = response.text
        success, msg = simplefin_service.add_access_token(access_url, db)
        if success:
            acc_success, acc_msg = simplefin_service.get_accounts(access_url, db)
            if not acc_success:
                return ApiResult.error(f"Failed to fetch/store accounts: {acc_msg}").__dict__
            db.commit()
            return ApiResult.success("Account connected and accounts fetched.").__dict__
        else:
            return ApiResult.error(f"Failed to store access_token: {msg}").__dict__
    except Exception as ex:
        return ApiResult.error(f"Failed to get/store accounts and transactions: {ex}").__dict__

@router.post("/sync")
async def sync(db: Session = Depends(get_db)):
    try:
        success, msg = simplefin_service.get_accounts(db)
        db.commit()
        if not success:
            return ApiResult.error(f"Failed to fetch/store accounts: {msg}").__dict__
        return ApiResult.success("Accounts synced successfully.").__dict__
    except Exception as ex:
        return ApiResult.error(f"Failed to get/store accounts and transactions: {ex}").__dict__
