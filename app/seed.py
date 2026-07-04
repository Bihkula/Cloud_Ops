import datetime

from sqlalchemy import func, select

from .database import SessionLocal
from .models import Transaction, TransactionType


def seed_if_empty() -> None:
    """Populate sample data on first run so the app looks alive."""
    db = SessionLocal()
    try:
        count = db.scalar(select(func.count(Transaction.id)))
        if count and count > 0:
            return
        today = datetime.date.today()
        rows = [
            Transaction(description="Monthly salary", amount=4200.00,
                        type=TransactionType.INCOME, category="Salary", date=today),
            Transaction(description="Freelance project", amount=850.00,
                        type=TransactionType.INCOME, category="Freelance",
                        date=today - datetime.timedelta(days=3)),
            Transaction(description="Rent", amount=1450.00,
                        type=TransactionType.EXPENSE, category="Housing",
                        date=today - datetime.timedelta(days=1)),
            Transaction(description="Groceries", amount=92.40,
                        type=TransactionType.EXPENSE, category="Food",
                        date=today - datetime.timedelta(days=1)),
            Transaction(description="Electric bill", amount=68.00,
                        type=TransactionType.EXPENSE, category="Utilities",
                        date=today - datetime.timedelta(days=2)),
            Transaction(description="Coffee", amount=4.80,
                        type=TransactionType.EXPENSE, category="Food", date=today),
            Transaction(description="Streaming", amount=15.99,
                        type=TransactionType.EXPENSE, category="Entertainment",
                        date=today - datetime.timedelta(days=4)),
        ]
        db.add_all(rows)
        db.commit()
    finally:
        db.close()
