# Budget App Backend

FastAPI backend with SQLAlchemy, SimpleFin integration, and scikit-learn ML models.

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

### 3. Run the server
```bash
python main.py
# Or use uvicorn directly:
# uvicorn main:app --reload
```

The API will be available at http://localhost:8000
API documentation at http://localhost:8000/docs

