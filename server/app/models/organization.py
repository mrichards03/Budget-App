from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class Organization(Base):
    __tablename__ = "organizations"
    
    domain = Column(String, primary_key=True) 
    name = Column(String, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    accounts = relationship("Account", back_populates="organization")