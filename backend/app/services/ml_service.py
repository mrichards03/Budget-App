from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, classification_report
import joblib
import os
from typing import Dict, List
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.transaction import Transaction

class MLService:
    """
    Service for ML operations - training and prediction.
    
    This class provides a starting point for multi-model learning.
    You'll need to:
    1. Create feature engineering from transaction data
    2. Train multiple models and compare performance
    3. Save/load models using joblib
    4. Make predictions on new transactions
    """
    
    def __init__(self):
        self.models = {
            'random_forest': RandomForestClassifier(n_estimators=100),
            'svm': SVC(kernel='rbf', probability=True),
            'logistic_regression': LogisticRegression(max_iter=1000)
        }
        self.vectorizer = TfidfVectorizer(max_features=100)
        self.model_path = settings.MODEL_PATH
        os.makedirs(self.model_path, exist_ok=True)
    
    def prepare_features(self, transactions: List[Transaction]):
        """
        Extract features from transactions for ML models.
        
        TODO: Implement feature engineering:
        - Text features from transaction name and merchant
        - Numerical features like amount, day of week, time of day
        - Categorical encoding
        """
        # Example: Extract text and create TF-IDF features
        texts = [f"{t.name} {t.merchant_name or ''}" for t in transactions]
        # TODO: Add more sophisticated feature engineering
        return texts
    
    def train_models(self, db: Session) -> Dict:
        """
        Train all models on labeled transaction data.
        
        TODO:
        1. Query transactions with manual categories (labels)
        2. Prepare features and labels
        3. Split data into train/test sets
        4. Train each model
        5. Evaluate and compare performance
        6. Save best model
        """
        # Example structure (you'll need to implement):
        # labeled_transactions = db.query(Transaction).filter(
        #     Transaction.predicted_category.isnot(None)
        # ).all()
        
        # features = self.prepare_features(labeled_transactions)
        # labels = [t.predicted_category for t in labeled_transactions]
        
        # X_train, X_test, y_train, y_test = train_test_split(
        #     features, labels, test_size=0.2
        # )
        
        # results = {}
        # for name, model in self.models.items():
        #     model.fit(X_train, y_train)
        #     predictions = model.predict(X_test)
        #     accuracy = accuracy_score(y_test, predictions)
        #     results[name] = accuracy
        
        return {
            "message": "Training not yet implemented",
            "todo": "Implement training logic in ml_service.py"
        }
    
    def predict_category(self, transaction_text: str, amount: float, 
                        merchant_name: str = None) -> Dict:
        """
        Predict category for a single transaction.
        
        TODO:
        1. Load trained model
        2. Prepare features from input
        3. Make prediction
        4. Return category and confidence score
        """
        return {
            "predicted_category": "unknown",
            "confidence": 0.0,
            "message": "Prediction not yet implemented"
        }
    
    def batch_predict(self, transaction_ids: List[int], db: Session) -> List[Dict]:
        """
        Predict categories for multiple transactions efficiently.
        
        TODO: Implement batch prediction
        """
        return []
    
    def save_model(self, model_name: str, model):
        """Save trained model to disk."""
        filepath = os.path.join(self.model_path, f"{model_name}.joblib")
        joblib.dump(model, filepath)
    
    def load_model(self, model_name: str):
        """Load trained model from disk."""
        filepath = os.path.join(self.model_path, f"{model_name}.joblib")
        if os.path.exists(filepath):
            return joblib.load(filepath)
        return None
