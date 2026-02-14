from sqlalchemy import Column, Integer, String, ForeignKey, Table
from app.core.database import Base

# Many-to-many association table
transaction_merchants = Table(
    'transaction_merchants',
    Base.metadata,
    Column('transaction_id', Integer, ForeignKey('transactions.id'), primary_key=True),
    Column('merchant_id', Integer, ForeignKey('merchants.id'), primary_key=True)
)