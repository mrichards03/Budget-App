
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime
from app.schemas.account import AccountType

class Account(Base):
    __tablename__ = "accounts"
    
    id = Column(String, primary_key=True)
    organization_domain = Column(String, ForeignKey('organizations.domain'), primary_key=True)

    name = Column(String)

    current_balance = Column(Float, default=0.0)
    available_balance = Column(Float, nullable=True)
    currency_code = Column(String, default="CAD")

    type = Column(Integer, default=AccountType.CHECKING)

    @property
    def account_type(self):
        return AccountType(self.type)

    @account_type.setter
    def account_type(self, value):
        if isinstance(value, AccountType):
            self.type = value.value
        elif isinstance(value, int):
            self.type = value
        else:
            raise ValueError("Invalid account type")
    
    balance_date = Column(DateTime)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    organization = relationship("Organization", back_populates="accounts")
    transactions = relationship("Transaction", back_populates="account", foreign_keys="[Transaction.account_id]")
