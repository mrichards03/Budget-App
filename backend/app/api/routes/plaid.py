from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.transactions_get_request_options import TransactionsGetRequestOptions
import plaid
from datetime import datetime, timedelta

from app.core.config import settings
from app.core.database import get_db
from app.services.plaid_service import PlaidService
from app.models.plaid_item import PlaidItem

router = APIRouter()

# Initialize Plaid client
configuration = plaid.Configuration(
    host=plaid.Environment.Sandbox if settings.PLAID_ENV == "sandbox" else plaid.Environment.Production,
    api_key={
        'clientId': settings.PLAID_CLIENT_ID,
        'secret': settings.PLAID_SECRET,
    }
)
api_client = plaid.ApiClient(configuration)
plaid_client = plaid_api.PlaidApi(api_client)

@router.post("/create_link_token")
async def create_link_token():
    """
    Create a Plaid Link token for the user to connect their bank account.
    This token is used by the Flutter app to initialize Plaid Link.
    """
    try:
        request = LinkTokenCreateRequest(
            user=LinkTokenCreateRequestUser(client_user_id="user-id"),
            client_name="Budget App",
            products=[Products("transactions")],
            country_codes=[CountryCode("US"), CountryCode("CA")],
            language="en"
        )
        response = plaid_client.link_token_create(request)
        return {"link_token": response['link_token']}
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/exchange_public_token")
async def exchange_public_token(public_token: str, inst_id: str, inst_name: str, db: Session = Depends(get_db)):
    """
    Exchange the public token from Plaid Link for an access token.
    Store this access token securely to fetch transactions later.
    
    TODO: Store access_token in database associated with user/account
    """
    try:
        exchange_request = ItemPublicTokenExchangeRequest(public_token=public_token)
        exchange_response = plaid_client.item_public_token_exchange(exchange_request)
        access_token = exchange_response['access_token']
        item_id = exchange_response['item_id']
        
        # TODO: Store access_token and item_id in database
        # For now, return it (in production, never return access tokens to client)
        
        plaid_item = PlaidItem(
            item_id = item_id,
            access_token = access_token,
            institution_id = inst_id,
            institution_name = inst_name
        )
        db.add(plaid_item)
        db.commit()

        return {
            "message": "Token exchanged successfully"
        }
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/sync_transactions")
async def sync_transactions(access_token: str, db: Session = Depends(get_db)):
    """
    Fetch transactions from Plaid and store them in the database.
    
    TODO: 
    - Retrieve access_token from database instead of accepting as parameter
    - Implement transaction deduplication
    - Implement incremental sync with cursor
    - Apply ML model to categorize transactions
    """
    try:
        # Fetch last 30 days of transactions
        start_date = (datetime.now() - timedelta(days=30)).date()
        end_date = datetime.now().date()
        
        request = TransactionsGetRequest(
            access_token=access_token,
            start_date=start_date,
            end_date=end_date,
            options=TransactionsGetRequestOptions()
        )
        
        response = plaid_client.transactions_get(request)
        transactions = response['transactions']
        
        # TODO: Save transactions to database
        


        # TODO: Run ML model to predict categories
        
        return {
            "transactions_count": len(transactions),
            "transactions": transactions[:10]  # Return first 10 for preview
        }
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/accounts")
async def get_accounts(access_token: str):
    """
    Fetch connected accounts from Plaid.
    
    TODO: Retrieve access_token from database
    """
    try:
        # TODO: Use appropriate Plaid API to get accounts
        return {"message": "Implement account fetching"}
    except plaid.ApiException as e:
        raise HTTPException(status_code=400, detail=str(e))
