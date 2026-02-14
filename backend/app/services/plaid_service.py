from sqlalchemy.orm import Session
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
import plaid
import logging

from app.core.config import settings
from app.models import PlaidItem

logger = logging.getLogger(__name__)


class PlaidService:
    """Service for handling Plaid-related operations."""
    
    def __init__(self, plaid_client: plaid_api.PlaidApi, account_service=None):
        self.plaid_client = plaid_client
        self.account_service = account_service
    
    def get_existing_institutions(self, db: Session) -> list:
        """
        Get all currently connected institutions.
        
        Args:
            db: Database session
            
        Returns:
            list: List of dicts with institution info
        """
        items = db.query(PlaidItem).all()
        return [
            {
                "item_id": item.item_id,
                "institution_id": item.institution_id,
                "institution_name": item.institution_name
            }
            for item in items
        ]
    
    def create_link_token(self, access_token: str = None) -> str:
        """
        Create a Plaid Link token for the user to connect their bank account.
        If access_token is provided, creates an update mode token for re-authentication.
        
        Args:
            access_token: Optional access token for update mode
        
        Returns:
            str: The link token to be used by the client application
        """
        request_params = {
            "user": LinkTokenCreateRequestUser(client_user_id="user-id"),
            "client_name": "Budget App",
            "country_codes": [CountryCode("US"), CountryCode("CA")],
            "language": "en",
            "webhook": "https://unanatomized-charleigh-overdelicately.ngrok-free.dev/api/plaid/webhooks"
        }
        
        # If access_token provided, use update mode
        if access_token:
            request_params["access_token"] = access_token
        else:
            # Only specify products for new connections
            request_params["products"] = [Products("transactions")]
        
        request = LinkTokenCreateRequest(**request_params)
        response = self.plaid_client.link_token_create(request)
        return response['link_token']
    
    def exchange_public_token(
        self, 
        public_token: str, 
        inst_id: str, 
        inst_name: str, 
        db: Session
    ) -> dict:
        """
        Exchange a public token for an access token and store the item.
        
        Args:
            public_token: The public token from Plaid Link
            inst_id: Institution ID
            inst_name: Institution name
            db: Database session
            
        Returns:
            dict: Contains item_id, accounts list, and success message
        """
        exchange_request = ItemPublicTokenExchangeRequest(public_token=public_token)
        exchange_response = self.plaid_client.item_public_token_exchange(exchange_request)
        access_token = exchange_response['access_token']
        item_id = exchange_response['item_id']
        
        # Store Plaid item
        plaid_item = PlaidItem(
            item_id=item_id,
            access_token=access_token,
            institution_id=inst_id,
            institution_name=inst_name
        )
        db.add(plaid_item)
        db.commit()

        # Fetch and store accounts
        accounts = self.account_service.fetch_and_store_accounts(access_token, db)
        
        return {
            "item_id": item_id,
            "accounts": [
                {
                    "account_id": acc['account_id'],
                    "name": acc['name'],
                    "mask": acc.get('mask'),
                    "type": str(acc['type']),
                    "subtype": str(acc['subtype']),
                    "balance": acc['balances']['current']
                }
                for acc in accounts
            ],
            "message": "Token exchanged successfully"
        }
