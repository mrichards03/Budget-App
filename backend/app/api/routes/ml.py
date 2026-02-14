from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict

from app.core.database import get_db
from app.services.ml_service import MLService

router = APIRouter()
ml_service = MLService()

@router.post("/train")
async def train_models(db: Session = Depends(get_db)):
    """
    Train ML models on existing labeled transaction data.
    
    TODO: 
    - Fetch labeled transactions from database
    - Train multiple models (Random Forest, SVM, etc.)
    - Compare and save best performing model
    - Return training metrics
    """
    try:
        # TODO: Implement training logic
        result = ml_service.train_models(db)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/predict")
async def predict_category(
    transaction_text: str,
    amount: float,
    merchant_name: str = None
):
    """
    Predict transaction category using trained model.
    
    TODO: Load saved model and make prediction
    """
    try:
        prediction = ml_service.predict_category(
            transaction_text=transaction_text,
            amount=amount,
            merchant_name=merchant_name
        )
        return prediction
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/models/status")
async def get_models_status():
    """
    Get status of all trained models.
    
    TODO: Return model versions, accuracy metrics, last trained date
    """
    return {
        "models": [
            {"name": "random_forest", "status": "not_trained"},
            {"name": "svm", "status": "not_trained"},
            {"name": "logistic_regression", "status": "not_trained"}
        ]
    }

@router.post("/batch_predict")
async def batch_predict(transaction_ids: List[int], db: Session = Depends(get_db)):
    """
    Predict categories for multiple transactions at once.
    
    TODO: Implement batch prediction for efficiency
    """
    try:
        results = ml_service.batch_predict(transaction_ids, db)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
