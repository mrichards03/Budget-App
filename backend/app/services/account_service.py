from fastapi import Depends
from sqlalchemy.orm import Session
import logging

from app.models import Account, Organization
from app.core.database import get_db
from datetime import datetime

logger = logging.getLogger(__name__)


class AccountService:
    """Service for handling account-related operations."""
    
    def store_account(self, account: dict, db: Session) -> tuple:
        """
        Fetch connected accounts from Plaid and store/update them in the database.
        
        Args:
            access_token: Plaid access token for the item
            db: Database session
            
        Returns:
            list: List of account data from Plaid API
        """
        try:            
            # Check if account already exists
            existing_account = db.query(Account).filter(
                Account.id == account['id']
            ).first()
                        
            if existing_account:
                # Update existing account
                existing_account.current_balance = account['balance']
                existing_account.available_balance = account.get('available-balance')
                existing_account.balance_date = datetime.fromtimestamp(account['balance-date'])
            else:
                # Create new account
                existing_org = db.query(Organization).filter(Organization.domain == account['org']['domain']).first() 
                if(not existing_org):
                    success, msg = self.add_org(account['org'], db)
                    if(not success):
                        return (False, msg)

                account = Account(
                    id=account['id'],
                    name=account['name'],
                    currency_code=account['currency'],
                    current_balance=account['balance'],
                    available_balance = account.get('available-balance'),
                    balance_date = datetime.fromtimestamp(account['balance-date']),
                    organization_domain = account['org']['domain']
                )
                db.add(account)
                db.flush()
            return (True, "")
        except Exception as ex:
            return (False, f"Failed to store accounts: {ex}")

    
    def add_org(self, org: dict, db:Session) -> tuple:
        try: 
            newOrg = Organization(
                domain = org['domain'],
                name = org['name'],
            )
            db.add(newOrg)
            db.flush()
            return (True, "")
        except Exception as ex:
            return (False, f"Failed to add new organization ({org['domain']}): {ex}")


