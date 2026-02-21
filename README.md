# Budget App

A personal budget tracking application with bank integration (SimpleFin), FastAPI backend, Flutter frontend, and ML-powered transaction categorization.

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
- **SimpleFin**: Bank account and transaction data
- **scikit-learn**: Machine learning for transaction categorization

### Frontend
- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **HTTP**: API communication

## Quick Start

### Prerequisites
- Python 3.10+
- Flutter SDK
- SimpleFin account

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

1. Sign up at https://beta-bridge.simplefin.org/
2. Link Institutions
3. Create one time access-token for this app

## API Documentation

Once the backend is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [SimpleFin Documentation](https://www.simplefin.org/protocol.html)
- [scikit-learn Documentation](https://scikit-learn.org/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
