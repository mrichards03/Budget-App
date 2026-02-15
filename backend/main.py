from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.routes import transactions, plaid, ml, categories, budgets, accounts, analytics
from app.core.database import init_db, get_db
from app.services.category_service import CategoryService
import logging

logging.basicConfig(
    level=logging.DEBUG,  # Show all logs including DEBUG
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Reduce noise from libraries
logging.getLogger("urllib3").setLevel(logging.WARNING)
logging.getLogger("plaid").setLevel(logging.INFO)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database and seed default categories
    init_db()
    
    # Seed default categories if needed
    db = next(get_db())
    try:
        category_service = CategoryService()
        category_service.seed_default_categories(db)
    finally:
        db.close()
    
    yield

app = FastAPI(title="Budget App API", version="1.0.0", lifespan=lifespan)

# CORS configuration for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Update this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(plaid.router, prefix="/api/plaid", tags=["plaid"])
app.include_router(transactions.router, prefix="/api/transactions", tags=["transactions"])
app.include_router(categories.router, prefix="/api/categories", tags=["categories"])
app.include_router(ml.router, prefix="/api/ml", tags=["ml"])
app.include_router(budgets.router, prefix="/api/budgets", tags=["budgets"])
app.include_router(accounts.router, prefix="/api/accounts", tags=["accounts"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["analytics"])

@app.get("/")
async def root():
    return {"message": "Budget App API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
