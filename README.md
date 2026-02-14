# Budget App

A personal budget tracking application with bank integration (Plaid), FastAPI backend, Flutter frontend, and ML-powered transaction categorization.

## Features

- 🏦 **Bank Integration**: Connect to your bank accounts using Plaid
- 💳 **Transaction Tracking**: Automatically fetch and categorize transactions
- 🤖 **ML Categorization**: Multi-model machine learning for intelligent transaction categorization
- 📊 **Local First**: Runs entirely on your machine - no cloud deployment needed
- 🔒 **No Authentication**: Simplified for local personal use

## Tech Stack

### Backend
- **FastAPI**: Modern Python web framework
- **SQLAlchemy**: SQL toolkit and ORM
- **SQLite**: Lightweight database
- **Plaid**: Bank account and transaction data
- **scikit-learn**: Machine learning for transaction categorization

### Frontend
- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **HTTP**: API communication

## Quick Start

### Prerequisites
- Python 3.10+
- Flutter SDK
- Plaid account (free sandbox access)

### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Mac/Linux

# Install dependencies
pip install -r requirements.txt

# Initialize database
python init_db.py

# Run server
python main.py
```

Backend will run at http://localhost:8000

### Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Run app (web)
flutter run -d chrome

# Or run on mobile emulator
flutter run
```

### Get Plaid Credentials

1. Sign up at https://dashboard.plaid.com/
2. Get your `client_id` and `secret` (sandbox)
3. Update `backend/.env` with your credentials

## Project Structure

```
Budget-App/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── api/         # API routes
│   │   ├── core/        # Config & database
│   │   ├── models/      # SQLAlchemy models
│   │   ├── schemas/     # Pydantic schemas
│   │   └── services/    # Business logic
│   ├── main.py          # Entry point
│   └── requirements.txt
├── frontend/            # Flutter frontend
│   ├── lib/
│   │   ├── models/      # Data models
│   │   ├── screens/     # UI screens
│   │   └── services/    # API service
│   └── pubspec.yaml
└── README.md
```

## Usage

1. **Connect Bank Account**
   - Open the Flutter app
   - Click "Connect Bank Account"
   - Follow Plaid Link flow (use sandbox credentials)

2. **Sync Transactions**
   - After connecting, sync your transactions
   - Transactions are stored in local SQLite database

3. **Categorize Transactions**
   - Manually categorize some transactions
   - This creates training data for ML models

4. **Train ML Models**
   - Go to ML Models tab
   - Click "Train Models"
   - Models learn from your manual categorizations

5. **Auto-Categorization**
   - New transactions are automatically categorized
   - Review and correct predictions to improve models

## Development Notes

This is a **starter template** - not a complete application. It provides:

✅ Project structure and architecture
✅ Basic API endpoints with TODOs
✅ Database models and migrations setup
✅ Plaid integration skeleton
✅ ML service structure
✅ Flutter UI components

❌ NOT included (you'll implement):
- Complete Plaid webhook handling
- Full ML feature engineering and training
- Advanced UI/UX features
- Data visualization and charts
- Budget tracking logic
- Reporting and insights

## Next Steps

### Backend
1. Implement Plaid webhook handling
2. Build out ML training pipeline with proper feature engineering
3. Add more database models (budgets, recurring transactions, etc.)
4. Implement transaction deduplication
5. Add proper error handling and logging

### Frontend
1. Configure plaid_flutter package properly
2. Implement state management (Provider/Riverpod/Bloc)
3. Build dashboard with charts
4. Add transaction filtering and search
5. Create budget tracking UI
6. Add spending insights and analytics

### ML
1. Engineer features (text embeddings, time patterns, amounts)
2. Train and compare multiple models
3. Implement cross-validation
4. Add model versioning and A/B testing
5. Build feedback loop for continuous learning

## API Documentation

Once the backend is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Plaid Documentation](https://plaid.com/docs/)
- [scikit-learn Documentation](https://scikit-learn.org/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)

## License

MIT

