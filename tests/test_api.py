import os
import tempfile

# Use a throwaway SQLite file so tests never touch dev data.
_tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp.name}"

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "UP"


def test_seed_and_list():
    r = client.get("/api/transactions")
    assert r.status_code == 200
    assert len(r.json()) >= 1


def test_summary_math():
    r = client.get("/api/transactions/summary")
    body = r.json()
    assert r.status_code == 200
    assert round(body["balance"], 2) == round(body["income"] - body["expense"], 2)


def test_create_and_delete():
    payload = {
        "description": "Test lunch",
        "amount": 14.25,
        "type": "EXPENSE",
        "category": "Food",
        "date": "2026-07-03",
    }
    created = client.post("/api/transactions", json=payload)
    assert created.status_code == 201
    tx_id = created.json()["id"]

    deleted = client.delete(f"/api/transactions/{tx_id}")
    assert deleted.status_code == 204

    missing = client.delete(f"/api/transactions/{tx_id}")
    assert missing.status_code == 404


def test_validation_rejects_bad_input():
    r = client.post("/api/transactions", json={
        "description": "", "amount": -5, "type": "EXPENSE", "category": "Food",
    })
    assert r.status_code == 422


def test_metrics_exposed():
    r = client.get("/metrics")
    assert r.status_code == 200
    assert "http_request" in r.text
