from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.core.database import Base

class SimplefinItem(Base):
    __tablename__ = "simplefin_items"
    
    id = Column(Integer, primary_key=True, index=True)
    access_token = Column(String, nullable=False)  
    created_at = Column(DateTime, default=datetime.utcnow)