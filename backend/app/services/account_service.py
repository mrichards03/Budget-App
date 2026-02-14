from sqlalchemy.orm import Session
from plaid.api import plaid_api
from plaid.model.accounts_get_request import AccountsGetRequest
import logging

from app.models import Account

logger = logging.getLogger(__name__)


class AccountService:
    """Service for handling account-related operations."""
    
    def __init__(self, plaid_client: plaid_api.PlaidApi):
        self.plaid_client = plaid_client
    
    def fetch_and_store_accounts(self, access_token: str, db: Session) -> list:
        """
        Fetch connected accounts from Plaid and store/update them in the database.
        
        Args:
            access_token: Plaid access token for the item
            db: Database session
            
        Returns:
            list: List of account data from Plaid API
        """
        request = AccountsGetRequest(access_token=access_token)
        response = self.plaid_client.accounts_get(request)
        item_id = response['item']['item_id']
        
        for acc in response['accounts']:
            # Check if account already exists
            existing_account = db.query(Account).filter(
                Account.plaid_account_id == acc['account_id']
            ).first()
            
            holder_cat = acc.get('holder_category')
            
            if existing_account:
                # Update existing account
                existing_account.plaid_item_id = item_id
                existing_account.name = acc['name']
                existing_account.official_name = acc.get('official_name')
                existing_account.account_type = str(acc['type'])
                existing_account.account_subtype = str(acc['subtype'])
                existing_account.holder_category = str(holder_cat) if holder_cat else None
                existing_account.mask = acc.get('mask')
                existing_account.current_balance = acc['balances']['current']
                existing_account.available_balance = acc['balances'].get('available')
                existing_account.limit = acc['balances'].get('limit')
                existing_account.currency_code = acc['balances']['iso_currency_code']
            else:
                # Create new account
                account = Account(
                    plaid_account_id=acc['account_id'],
                    plaid_item_id=item_id,
                    name=acc['name'],
                    official_name=acc.get('official_name'),
                    account_type=str(acc['type']),
                    account_subtype=str(acc['subtype']),
                    holder_category=str(holder_cat) if holder_cat else None,
                    mask=acc.get('mask'),
                    current_balance=acc['balances']['current'],
                    available_balance=acc['balances'].get('available'),
                    limit=acc['balances'].get('limit'),
                    currency_code=acc['balances']['iso_currency_code']
                )
                db.add(account)

        db.commit()
        return response['accounts']
