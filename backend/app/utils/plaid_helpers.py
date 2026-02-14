"""Utility functions for working with Plaid data."""
from datetime import datetime


def parse_plaid_date(date_value, fallback=None):
    """
    Parse a date that could be a string, date object, or None.
    
    Args:
        date_value: Date from Plaid API (string, date object, or None)
        fallback: Default value if date_value is None
        
    Returns:
        datetime object or fallback value
    """
    if not date_value:
        return fallback
    
    if isinstance(date_value, str):
        return datetime.fromisoformat(date_value)
    else:
        # Already a date object, convert to datetime
        return datetime.combine(date_value, datetime.min.time())


def parse_plaid_datetime(datetime_value):
    """
    Parse an ISO datetime string with Z timezone.
    
    Args:
        datetime_value: ISO datetime string from Plaid API (e.g., "2024-01-01T12:00:00Z")
        
    Returns:
        datetime object or None
    """
    if not datetime_value:
        return None
    return datetime.fromisoformat(datetime_value.replace('Z', '+00:00'))
