# Budget App - AI Coding Agent Instructions

## Architecture Overview
This is a **local-first personal budgeting app** with Plaid bank integration, ML-powered transaction categorization, and no authentication (single-user design).

**Tech Stack:**
- **Backend:** FastAPI + SQLAlchemy (SQLite) + scikit-learn ML models + Plaid API
- **Frontend:** Flutter web app with Provider state management
- **Communication:** REST API at `http://localhost:8000`

## Critical Setup Commands

### Backend (from `/backend`)
```bash
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
python main.py  # Starts on port 8000
```

### Frontend (from `/frontend`)
```bash
flutter pub get
flutter run -d chrome  # Web development
```

### Environment Requirements
- `.env` file in `/backend` with Plaid credentials: `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV=sandbox`
- Backend must be running before frontend (hard-coded base URL in `main.dart`)

## Project-Specific Patterns

### Backend Architecture
1. **Layered Service Pattern:** All business logic lives in `/backend/app/services/`, NOT in route handlers
   - Routes (`/backend/app/api/routes/`) handle HTTP concerns only
   - Example: `PlaidService` handles Plaid API, `BudgetService` handles budget logic
   - Services accept `Session` (SQLAlchemy) as first parameter

2. **Model Relationships:**
   - `Transaction` → `Account` → `PlaidItem` (bank connection hierarchy)
   - `Transaction.subcategory_id` → `Subcategory` → `Category` (budget categorization)
   - `Budget` → `SubcategoryBudget` → `Subcategory` (monthly budget allocations)
   - **Key:** `Transaction.is_transfer` and `transfer_account_id` detect internal transfers (crucial for credit card payments)

3. **Database Initialization:**
   - `init_db()` creates tables from SQLAlchemy models
   - `CategoryService.seed_default_categories()` runs on startup (see `main.py` lifespan)
   - Tables auto-created via `Base.metadata.create_all()`

4. **Plaid Integration Workflow:**
   - Create link token → User connects bank → Exchange public token → Store access token
   - `/api/plaid/sync_transactions` fetches from Plaid and deduplicates by `plaid_transaction_id`
   - Webhooks at `/api/plaid/webhooks` handle background updates

### Frontend Architecture
1. **Service Facade Pattern:** `ApiService` provides organized access to domain-specific API services
   ```dart
   apiService.budgets.getCurrentBudget()
   apiService.plaid.createLinkToken()
   apiService.transactions.getTransactions()
   ```
   - All API services extend `BaseApiService` for common HTTP logic
   - Located in `/frontend/lib/services/api/`

2. **State Management:** 
   - Uses Provider (injected in `main.dart`)
   - Screens fetch data via `Provider.of<ApiService>(context)` and manage local state with `setState()`
   - No global state management (Riverpod/Bloc) - each screen refetches data on `initState()`

3. **Navigation:** 
   - `MainLayoutScreen` is the root with bottom nav bar
   - Screens: Budget, Reflect (analytics), Accounts
   - Plaid link modal launched from accounts screen

4. **Models:**
   - Simple `fromJson`/`toJson` classes in `/frontend/lib/models/`
   - Match backend Pydantic schemas (in `/backend/app/schemas/`)

## Critical Implementation Details

### Transaction Categorization System
- **Three-tier categorization:** Plaid categories (auto) → ML predictions (auto) → User subcategories (manual)
- `Transaction.predicted_category` = ML model output (not implemented yet)
- `Transaction.subcategory_id` = user's budget category assignment
- `Transaction.merchants` = many-to-many via `transaction_merchants` table with confidence levels

### Budget System
- One active budget at a time (query by `start_date <= now < end_date`)
- Each budget has `SubcategoryBudget` entries (allocated amounts per subcategory)
- Frontend calculates spent amounts by querying transactions with matching `subcategory_id`

### ML Service (Incomplete)
- `/backend/app/services/ml_service.py` is a **stub** - training/prediction not implemented
- Placeholder for multi-model (RandomForest, SVM, LogisticRegression) comparison
- Intended to use TF-IDF on transaction names/merchants for text features

## Common Workflows

### Adding New API Endpoint
1. Create route in `/backend/app/api/routes/[domain].py`
2. Implement logic in `/backend/app/services/[domain]_service.py`
3. Add Pydantic schema in `/backend/app/schemas/[domain].py` if needed
4. Create corresponding method in `/frontend/lib/services/api/[domain]_api_service.dart`
5. Add method to ApiService facade if new service

### Adding New Model
1. Define SQLAlchemy model in `/backend/app/models/[name].py`
2. Import in `/backend/app/models/__init__.py`
3. Run backend to auto-create table (or use Alembic for migrations)
4. Create matching Dart model in `/frontend/lib/models/[name].dart`

### Debugging
- Backend logs are verbose (level=DEBUG in `main.py`)
- FastAPI auto-docs at `http://localhost:8000/docs` (Swagger UI)
- Flutter DevTools for frontend debugging
- Check terminal history: Both backend and frontend have exit code 1 (need to diagnose startup failures)

## Integration Points
- **Plaid SDK:** Backend uses `plaid-python==28.0.0` (adjust for API version changes)
- **CORS:** Fully open in development (`allow_origins=["*"]` in `main.py`)
- **Database:** SQLite file at `/backend/budget_app.db` (created on first run)
- **ML Models:** Saved to `/backend/ml_models/saved_models/` (via joblib)

## Known Gotchas
- Backend uses `asynccontextmanager` lifespan - database initialization happens before first request
- `Transaction.merchant_name` is a @property that filters merchants by confidence level (not a DB column)
- Frontend hardcodes `baseUrl: 'http://localhost:8000'` in `main.dart` - must change for production
- No authentication = no user isolation (single-user assumption throughout)
- Plaid webhooks require ngrok or public URL (see example in `plaid_service.py`)
