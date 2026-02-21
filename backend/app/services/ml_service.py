from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report
import numpy as np
from scipy.sparse import hstack
import pandas as pd
import joblib
import os
from typing import Dict, List, Optional
from sqlalchemy.orm import Session
import logging

from app.core.config import settings
from app.models.transaction import Transaction
from app.models.category import Subcategory

logger = logging.getLogger(__name__)

class MLService:
    """
    ML service for transaction categorization using RandomForest.
    
    Feature priority:
    1. Transaction name text (TF-IDF) - PRIMARY SIGNAL
    2. Transaction amount patterns - STRONG SIGNAL
    3. Temporal patterns (day of week/month) - MODERATE SIGNAL
    """
    
    def __init__(self):
        # Use only RandomForest - simplest and most effective for mixed features
        self.model = RandomForestClassifier(
            n_estimators=200,
            max_depth=20,
            min_samples_split=5,
            class_weight='balanced',  # Handle imbalanced categories
            random_state=42,
            n_jobs=-1  # Use all CPU cores
        )
        
        # Text vectorizer - most important feature
        self.vectorizer = TfidfVectorizer(
            max_features=200,  # Increased from 100
            ngram_range=(1, 2),  # Capture "SHELL GAS" as single feature
            min_df=2,  # Ignore very rare words
            stop_words='english'
        )
        
        self.scaler = StandardScaler()
        self.categorical_columns = None
        self.model_path = settings.MODEL_PATH
        self.best_model_name = 'transaction_categorizer'
        # Category name mappings for portability
        self.name_to_id_map = {}  # Maps subcategory name to current DB ID
        self.id_to_name_map = {}  # Maps current DB ID to subcategory name
        os.makedirs(self.model_path, exist_ok=True)
    
    def prepare_features(
        self, 
        transactions: List[Transaction], 
        fit: bool = True
    ) -> np.ndarray:
        """
        Extract features prioritizing transaction name text.
        
        Feature hierarchy:
        1. TF-IDF on transaction name (200 dimensions) - learns merchant patterns
        2. Amount (scaled) - different categories have different price ranges
        3. Day of week (0-6) - helps detect recurring subscriptions
        4. Day of month (1-31) - helps detect bill cycles
        
        Args:
            transactions: List of Transaction objects
            fit: If True, fit vectorizer/scaler. If False, transform only.
        
        Returns:
            Sparse feature matrix of shape (n_transactions, ~250 features)
        """
        if not transactions:
            raise ValueError("Cannot prepare features from empty transaction list")
        
        # 1. PRIMARY FEATURE: Transaction name text via TF-IDF
        texts = [t.name.lower() for t in transactions]  # Lowercase for consistency
        
        if fit:
            text_features = self.vectorizer.fit_transform(texts)
            logger.info(f"Fitted TF-IDF with {len(self.vectorizer.vocabulary_)} vocabulary terms")
        else:
            text_features = self.vectorizer.transform(texts)
        
        # 2. NUMERICAL FEATURES: Amount and temporal patterns
        numerical_data = []
        for t in transactions:
            
            numerical_data.append([
                abs(float(t.amount)),  # Use absolute value (expenses are negative)
                t.date.weekday(),  # 0=Monday, 6=Sunday
                t.date.day,  # Day of month
            ])
        
        numerical_features = np.array(numerical_data)
        
        if fit:
            numerical_features = self.scaler.fit_transform(numerical_features)
        else:
            numerical_features = self.scaler.transform(numerical_features)
                      
                
        # 4. COMBINE ALL FEATURES
        combined_features = hstack([
            text_features,  # ~200 features (most important)
            numerical_features,  # 4 features
        ])
        
        return combined_features
    
    def _load_category_mappings(self, db: Session):
        """
        Load mappings between subcategory names and IDs from database.
        This allows the model to train on names (stable) and map back to IDs (variable).
        """
        subcategories = db.query(Subcategory).all()
        
        self.name_to_id_map = {sub.name: sub.id for sub in subcategories}
        self.id_to_name_map = {sub.id: sub.name for sub in subcategories}
        
        logger.info(f"Loaded {len(self.name_to_id_map)} subcategory mappings")
    
    def train_models(self, db: Session) -> Dict:
        """
        Train RandomForest on transactions with manual subcategory assignments.
        
        Process:
        1. Query labeled transactions (where subcategory_id IS NOT NULL)
        2. Filter out transfers (we don't want to predict those)
        3. Require minimum samples per category (10+)
        4. Split 80/20 train/test
        5. Train model and evaluate
        6. Save if accuracy > 70%
        
        Returns:
            Training metrics and status
        """
        try:
            # 1. Query labeled transactions
            labeled_txns = db.query(Transaction).filter(
                Transaction.subcategory_id.isnot(None)
            ).all()
            
            if len(labeled_txns) < 50:
                return {
                    "status": "insufficient_data",
                    "message": f"Need at least 50 labeled transactions, found {len(labeled_txns)}",
                    "labeled_count": len(labeled_txns)
                }
            
            logger.info(f"Found {len(labeled_txns)} labeled transactions for training")
            
            # 2. Load category name mappings (allows model to survive DB resets)
            self._load_category_mappings(db)
            
            # 3. Check category distribution (using names now)
            category_counts = {}
            for t in labeled_txns:
                category_name = self.id_to_name_map.get(t.subcategory_id, 'Unknown')
                category_counts[category_name] = category_counts.get(category_name, 0) + 1
            
            # Filter out categories with < 5 samples (too sparse to learn)
            valid_txns = [
                t for t in labeled_txns 
                if category_counts[self.id_to_name_map.get(t.subcategory_id, 'Unknown')] >= 5
            ]
            
            if len(valid_txns) < 50:
                return {
                    "status": "insufficient_data",
                    "message": "Not enough samples per category (need 5+ per category)",
                    "category_distribution": category_counts
                }
            
            # 4. Prepare features and labels (using NAMES instead of IDs)
            X = self.prepare_features(valid_txns, fit=True)
            y = np.array([
                self.id_to_name_map.get(t.subcategory_id, 'Unknown') 
                for t in valid_txns
            ])
            
            # 5. Train/test split with stratification
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42, stratify=y
            )
            
            logger.info(f"Training on {X_train.shape[0]} samples, testing on {X_test.shape[0]}")
            logger.info(f"Training on category names: {set(y)}")
            
            # 6. Train model on NAMES
            self.model.fit(X_train, y_train)
            
            # 7. Evaluate
            train_pred = self.model.predict(X_train)
            test_pred = self.model.predict(X_test)
            
            train_accuracy = accuracy_score(y_train, train_pred)
            test_accuracy = accuracy_score(y_test, test_pred)
            
            logger.info(f"Training accuracy: {train_accuracy:.2%}")
            logger.info(f"Test accuracy: {test_accuracy:.2%}")
            
            # 8. Save model if performance is acceptable
            if test_accuracy >= 0.70:
                self.save_model(self.best_model_name, self.model)
                self.save_model(f"{self.best_model_name}_vectorizer", self.vectorizer)
                self.save_model(f"{self.best_model_name}_scaler", self.scaler)
                
                # Save categorical columns for prediction alignment
                joblib.dump(
                    self.categorical_columns, 
                    os.path.join(self.model_path, f"{self.best_model_name}_columns.joblib")
                )
                
                status = "success"
                message = f"Model trained successfully with {test_accuracy:.2%} accuracy"
            else:
                status = "low_accuracy"
                message = f"Model accuracy too low ({test_accuracy:.2%}). Need more labeled data."
            
            return {
                "status": status,
                "message": message,
                "train_accuracy": float(train_accuracy),
                "test_accuracy": float(test_accuracy),
                "training_samples": X_train.shape[0],
                "test_samples": X_test.shape[0],
                "categories_trained": len(set(y)),
                "category_distribution": category_counts,
                "feature_count": X.shape[1]
            }
            
        except Exception as e:
            logger.error(f"Training failed: {str(e)}")
            raise
    
    def predict_category(
        self, 
        transaction_text: str, 
        amount: float,
        date,
        db: Session = None  # Need for name-to-ID mapping
    ) -> Dict:
        """
        Predict subcategory for a single transaction.
        Model predicts NAME, then maps back to current database ID.
        
        Returns:
            {
                "subcategory_id": int,
                "confidence": float (0-1),
                "top_3_predictions": [(subcategory_id, confidence), ...]
            }
        """
        try:
            # Load model if not in memory
            if not hasattr(self.model, 'n_estimators') or self.model.n_estimators is None:
                self.model = self.load_model(self.best_model_name)
                self.vectorizer = self.load_model(f"{self.best_model_name}_vectorizer")
                self.scaler = self.load_model(f"{self.best_model_name}_scaler")
                self.categorical_columns = joblib.load(
                    os.path.join(self.model_path, f"{self.best_model_name}_columns.joblib")
                )
            
            # Load current category mappings (may differ from training time)
            if db and not self.name_to_id_map:
                self._load_category_mappings(db)
            
            if self.model is None:
                return {
                    "subcategory_id": None,
                    "confidence": 0.0,
                    "message": "No trained model available"
                }
            
            if not self.name_to_id_map:
                logger.warning("Category mappings not loaded - predictions may fail")
            
            # Create temporary transaction object for feature extraction
            class TempTransaction:
                def __init__(self, name, amount, date):
                    self.name = name
                    self.amount = amount
                    self.date = date
            
            temp_txn = TempTransaction(
                transaction_text, 
                amount, 
                date
            )
            
            # Extract features
            X = self.prepare_features([temp_txn], fit=False)
            
            # Get prediction probabilities (model outputs NAMES)
            probabilities = self.model.predict_proba(X)[0]
            classes = self.model.classes_  # These are category NAMES
            
            # Get top 3 predictions and map names back to current IDs
            top_3_indices = np.argsort(probabilities)[-3:][::-1]
            top_3 = []
            for i in top_3_indices:
                category_name = classes[i]
                category_id = self.name_to_id_map.get(category_name)
                if category_id:  # Only include if category still exists in DB
                    top_3.append((int(category_id), float(probabilities[i])))
            
            if not top_3:
                return {
                    "subcategory_id": None,
                    "confidence": 0.0,
                    "message": "Predicted categories no longer exist in database"
                }
            
            return {
                "subcategory_id": int(top_3[0][0]),
                "confidence": float(top_3[0][1]),
                "top_3_predictions": top_3
            }
            
        except Exception as e:
            logger.error(f"Prediction failed: {str(e)}")
            return {
                "subcategory_id": None,
                "confidence": 0.0,
                "error": str(e)
            }
    
    def batch_predict(self, transaction_ids: List[str], db: Session) -> List[Dict]:
        """
        Efficiently predict categories for multiple transactions.
        """
        try:
            # Load model once
            if not hasattr(self.model, 'n_estimators') or self.model.n_estimators is None:
                self.model = self.load_model(self.best_model_name)
                self.vectorizer = self.load_model(f"{self.best_model_name}_vectorizer")
                self.scaler = self.load_model(f"{self.best_model_name}_scaler")
                self.categorical_columns = joblib.load(
                    os.path.join(self.model_path, f"{self.best_model_name}_columns.joblib")
                )
            
            # Load current category mappings
            if not self.name_to_id_map:
                self._load_category_mappings(db)
            
            if self.model is None:
                return []
            
            # Fetch transactions
            transactions = db.query(Transaction).filter(
                Transaction.transaction_id.in_(transaction_ids)
            ).all()
            
            if not transactions:
                return []
            
            # Batch feature extraction
            X = self.prepare_features(transactions, fit=False)
            
            # Batch prediction (model outputs NAMES)
            probabilities = self.model.predict_proba(X)
            classes = self.model.classes_  # These are category NAMES
            
            results = []
            for i, txn in enumerate(transactions):
                probs = probabilities[i]
                top_idx = np.argmax(probs)
                
                # Map predicted name back to current DB ID
                category_name = classes[top_idx]
                category_id = self.name_to_id_map.get(category_name)
                
                # Only add result if category still exists
                if category_id:
                    results.append({
                        "transaction_id": txn.transaction_id,
                        "subcategory_id": int(category_id),
                        "confidence": float(probs[top_idx])
                    })
            
            return results
            
        except Exception as e:
            logger.error(f"Batch prediction failed: {str(e)}")
            return []
    
    def save_model(self, model_name: str, model):
        """Save trained model/vectorizer/scaler to disk."""
        filepath = os.path.join(self.model_path, f"{model_name}.joblib")
        joblib.dump(model, filepath)
        logger.info(f"Saved model to {filepath}")
    
    def load_model(self, model_name: str):
        """Load trained model/vectorizer/scaler from disk."""
        filepath = os.path.join(self.model_path, f"{model_name}.joblib")
        if os.path.exists(filepath):
            logger.info(f"Loaded model from {filepath}")
            return joblib.load(filepath)
        return None
