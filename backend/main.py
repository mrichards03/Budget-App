from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.routes import transactions, plaid, ml
from app.core.database import init_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
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
app.include_router(ml.router, prefix="/api/ml", tags=["ml"])

@app.get("/")
async def root():
    return {"message": "Budget App API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
