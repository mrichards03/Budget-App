# Budget App Backend

FastAPI backend with SQLAlchemy, Plaid integration, and scikit-learn ML models.

## Setup

### 1. Create virtual environment
```bash
python -m venv venv
venv\Scripts\activate  # On Windows
# source venv/bin/activate  # On Mac/Linux
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Configure environment
Create a `.env` file (already exists) and update with your Plaid credentials:
```
DATABASE_URL=sqlite:///./budget_app.db
PLAID_CLIENT_ID=your_client_id
PLAID_SECRET=your_secret
PLAID_ENV=sandbox
```

Get Plaid credentials from: https://dashboard.plaid.com/

### 4. Initialize database
```bash
python init_db.py
```

### 5. Run the server
```bash
python main.py
# Or use uvicorn directly:
# uvicorn main:app --reload
```

The API will be available at http://localhost:8000
API documentation at http://localhost:8000/docs

## Project Structure

```
backend/
├── main.py                # FastAPI app entry point
├── init_db.py            # Database initialization script
├── requirements.txt      # Python dependencies
├── .env                  # Environment variables (not in git)
└── app/
    ├── core/
    │   ├── config.py     # Settings and configuration
    │   └── database.py   # Database connection and session
    ├── models/           # SQLAlchemy models
    │   ├── account.py
    │   └── transaction.py
    ├── schemas/          # Pydantic schemas for API
    │   ├── account.py
    │   └── transaction.py
    ├── api/
    │   └── routes/       # API endpoints
    │       ├── plaid.py  # Plaid integration endpoints
    │       ├── transactions.py
    │       └── ml.py     # ML model endpoints
    └── services/         # Business logic
        ├── plaid_service.py
        └── ml_service.py # ML training and prediction
```

## API Endpoints

### Plaid
- `POST /api/plaid/create_link_token` - Create Plaid Link token
- `POST /api/plaid/exchange_public_token` - Exchange public token
- `POST /api/plaid/sync_transactions` - Fetch and store transactions

### Transactions
- `GET /api/transactions/` - List all transactions
- `GET /api/transactions/{id}` - Get specific transaction
- `POST /api/transactions/{id}/categorize` - Manually categorize

### ML
- `POST /api/ml/train` - Train categorization models
- `POST /api/ml/predict` - Predict transaction category
- `GET /api/ml/models/status` - Get model status

## Development Workflow

### 1. Connect to Plaid (Sandbox)
Use the Flutter app to create a link token and connect to a test bank account.

### 2. Sync Transactions
Fetch transactions from Plaid into your local database.

### 3. Label Transactions
Manually categorize some transactions to create training data.

### 4. Train ML Models
Run the training endpoint to train models on your labeled data.

### 5. Auto-Categorize
New transactions will be automatically categorized by the ML model.

## TODO

### Plaid Integration
- [ ] Implement full Plaid sync with cursor-based pagination
- [ ] Add webhook support for automatic updates
- [ ] Store access tokens securely in database
- [ ] Handle Plaid errors and rate limits

### Database
- [ ] Add more models (budgets, categories, etc.)
- [ ] Implement database migrations with Alembic
- [ ] Add indexes for performance
- [ ] Implement soft deletes

### ML
- [ ] Implement feature engineering
- [ ] Train multiple models (RF, SVM, etc.)
- [ ] Add model versioning
- [ ] Implement model evaluation metrics
- [ ] Add cross-validation
- [ ] Create training data pipeline

### API
- [ ] Add pagination for all list endpoints
- [ ] Add filtering and search
- [ ] Implement proper error handling
- [ ] Add request validation
- [ ] Add API rate limiting
