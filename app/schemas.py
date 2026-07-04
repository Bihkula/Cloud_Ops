import datetime

from pydantic import BaseModel, Field, ConfigDict

from .models import TransactionType


class TransactionCreate(BaseModel):
    description: str = Field(min_length=1, max_length=255)
    amount: float = Field(gt=0)
    type: TransactionType
    category: str = Field(min_length=1, max_length=50)
    date: datetime.date | None = None


class TransactionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    description: str
    amount: float
    type: TransactionType
    category: str
    date: datetime.date
