from fastapi import Depends
from sqlalchemy.orm import Session

import requests
import logging

from app.core.config import settings
from app.models import SimplefinItem
from app.core.database import get_db

logger = logging.getLogger(__name__)


class SimplefinService:
    """Service for handling simplefin-related operations."""
    
    def __init__(self, account_service=None, transaction_service=None):
        self.account_service = account_service
        self.transaction_service = transaction_service

    def add_access_token(self, access_token, db: Session) -> tuple:
        try:
            existing_token = db.query(SimplefinItem).first()
            if existing_token:
                existing_token.access_token = access_token
            else:
                item = SimplefinItem(access_token = access_token)
                db.add(item)
            return (True, "")
        except Exception as ex:
            return (False, f"Failed to save access_token: {ex}")
    
    def get_access_token(self, db:Session):
        return db.query(SimplefinItem).first().access_token

    def get_accounts(self, db: Session, access_token: str = None) -> tuple:
        """
        Get all accounts, transactions, and organizations
        
        Args:
            access_token: access token for simplefin
        """
        if not access_token:
            access_token = self.get_access_token(db)
        scheme, rest = access_token.split('//', 1)
        auth, rest = rest.split('@', 1)
        url = scheme + '//' + rest + '/accounts'
        username, password = auth.split(':', 1)

        # Enforce HTTPS only
        if not url.lower().startswith('https://'):
            raise Exception("Only HTTPS URLs are allowed for security.")

        try:
            response = requests.get(url, auth=(username, password), verify=True)
        except requests.exceptions.SSLError:
            raise Exception("SSL certificate verification failed.")

        if response.status_code == 403:
            raise Exception("Access denied from /accounts. Your token may be compromised. Please disable the token and contact support.")
        elif response.status_code != 200:
            # Display sanitized error message
            error_msg = response.text[:200].replace('\n', ' ').replace('\r', ' ')
            raise Exception(f"Error from /accounts: {error_msg}")

        data = response.json()

        from datetime import datetime

        def ts_to_datetime(ts):
            """Convert a timestamp (seconds since epoch) to a datetime string."""
            return datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
        
        try:
            for account in data['accounts']:
                account['balance-date-formatted'] = ts_to_datetime(account['balance-date'])
                print('\n{balance-date-formatted} {balance:>8} {name} {id}'.format(**account))
                print('-'*60)   
                if 'extra' in account:
                    print("Account extra:")
                    for k, v in account['extra'].items():
                        print(f"  {k}: {v}")         
                acc_succ, acc_msg = self.account_service.store_account(account, db)
                if not acc_succ:
                    return (False, acc_msg)
                for transaction in account['transactions']:
                    transaction['posted-formatted'] = ts_to_datetime(transaction['posted'])
                    print('{id} {posted-formatted} {amount:>8} {description}'.format(**transaction))
                    if 'extra' in transaction:
                        print("Transaction extra:")
                        for k, v in transaction['extra'].items():
                            print(f"  {k}: {v}")
                    txn_succ, txn_msg = self.transaction_service.add_transaction(transaction, account['id'], db)
                    if not txn_succ:
                        return (False, txn_msg)
            return (True, "") 
        except Exception as ex:
            return (False, f"Failed to save accounts and transactions: {ex}")
        