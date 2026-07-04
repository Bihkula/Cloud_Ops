import datetime

from fastapi import Depends, FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import Base, engine, get_db
from .models import Transaction, TransactionType
from .schemas import TransactionCreate, TransactionOut
from .seed import seed_if_empty

# Create tables + seed on startup (simple; swap for Alembic migrations later).
Base.metadata.create_all(bind=engine)
seed_if_empty()

app = FastAPI(title="Cirrus", version="1.0.0")


@app.get("/health")
def health():
    return {"status": "UP"}


@app.get("/api/transactions", response_model=list[TransactionOut])
def list_transactions(db: Session = Depends(get_db)):
    stmt = select(Transaction).order_by(Transaction.date.desc(), Transaction.id.desc())
    return db.scalars(stmt).all()


@app.get("/api/transactions/summary")
def summary(db: Session = Depends(get_db)):
    txns = db.scalars(select(Transaction)).all()
    income = sum(float(t.amount) for t in txns if t.type == TransactionType.INCOME)
    expense = sum(float(t.amount) for t in txns if t.type == TransactionType.EXPENSE)
    return {"income": income, "expense": expense, "balance": income - expense}


@app.post("/api/transactions", response_model=TransactionOut, status_code=201)
def create_transaction(payload: TransactionCreate, db: Session = Depends(get_db)):
    tx = Transaction(
        description=payload.description,
        amount=payload.amount,
        type=payload.type,
        category=payload.category,
        date=payload.date or datetime.date.today(),
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx


@app.delete("/api/transactions/{tx_id}", status_code=204)
def delete_transaction(tx_id: int, db: Session = Depends(get_db)):
    tx = db.get(Transaction, tx_id)
    if tx is None:
        raise HTTPException(status_code=404, detail="Transaction not found")
    db.delete(tx)
    db.commit()


# Prometheus metrics at /metrics (for the monitoring step later).
Instrumentator().instrument(app).expose(app, endpoint="/metrics")

# Serve the glass frontend. Mounted last so /api/*, /health, /metrics win.
app.mount("/", StaticFiles(directory="static", html=True), name="static")
