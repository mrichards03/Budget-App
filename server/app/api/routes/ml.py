from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict
import logging

from app.core.database import get_db
from app.services.ml_service import MLService
from app.models.transaction import Transaction

logger = logging.getLogger(__name__)
router = APIRouter()
ml_service = MLService()

@router.post("/train")
async def train_models(db: Session = Depends(get_db)):
    """
    Train ML model on all manually categorized transactions.
    
    Fetches transactions where subcategory_id IS NOT NULL (manually labeled),
    trains RandomForest classifier, and saves model if accuracy >= 70%.
    """
    try:
        result = ml_service.train_models(db)
        return result
    except Exception as e:
        logger.error(f"Training failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/retrain")
async def retrain_model(db: Session = Depends(get_db)):
    """
    Retrain ML model on all manually categorized transactions.
    
    Alias for /train endpoint. Triggered when user manually corrects categories.
    """
    try:
        result = ml_service.train_models(db)
        return result
    except Exception as e:
        logger.error(f"Retraining failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/predict")
async def predict_category(
    transaction_text: str,
    amount: float,
    merchant_name: str = None,
    db: Session = Depends(get_db)
):
    """
    Predict transaction category using trained model.
    Model predicts subcategory name and maps to current database ID.
    """
    try:
        # Note: predict_category needs date, so we'll use current date as default
        from datetime import datetime
        prediction = ml_service.predict_category(
            transaction_text=transaction_text,
            amount=amount,
            date=datetime.now(),
            db=db
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
async def batch_predict(transaction_ids: List[str], db: Session = Depends(get_db)):
    """
    Predict categories for multiple transactions at once.
    """
    try:
        results = ml_service.batch_predict(transaction_ids, db)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/auto_categorize")
async def auto_categorize_all(db: Session = Depends(get_db)):
    """
    Run ML predictions on all uncategorized transactions.
    
    Useful after initial training or to re-categorize transactions.
    Updates predicted_subcategory_id and auto-assigns if confidence >= 80%.
    """
    try:
        # Find all uncategorized transactions
        uncategorized = db.query(Transaction).filter(
            Transaction.subcategory_id.is_(None)
        ).all()
        
        if not uncategorized:
            return {"message": "No uncategorized transactions found", "categorized": 0}
        
        transaction_ids = [t.transaction_id for t in uncategorized]
        predictions = ml_service.batch_predict(transaction_ids, db)
        
        # Apply predictions
        applied_count = 0
        auto_assigned_count = 0
        for pred in predictions:
            txn = db.query(Transaction).get(pred['transaction_id'])
            if txn and pred.get('subcategory_id'):
                confidence = pred['confidence']
                txn.predicted_subcategory_id = pred['subcategory_id']
                txn.predicted_confidence = confidence
                applied_count += 1
                
                # Auto-assign if very confident
                if confidence >= 0.8:
                    txn.subcategory_id = pred['subcategory_id']
                    auto_assigned_count += 1
        
        db.commit()
        
        return {
            "message": "Auto-categorization complete",
            "total_predictions": len(predictions),
            "auto_assigned": auto_assigned_count,
            "needs_review": applied_count - auto_assigned_count
        }
        
    except Exception as e:
        logger.error(f"Auto-categorization failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
