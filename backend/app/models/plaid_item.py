from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.core.database import Base

class PlaidItem(Base):
    __tablename__ = "plaid_items"
    
    id = Column(Integer, primary_key=True, index=True)
    item_id = Column(String, unique=True, index=True)
    access_token = Column(String, nullable=False)  # Encrypt this in production
    institution_id = Column(String)
    institution_name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_synced = Column(DateTime)