# Cirrus

A simple, good-looking finance app with a futuristic **sky-blue, Apple-style
glass** UI. Track income and spending, watch your balance update, and see where
your money goes — behind bright frosted-glass panels floating over a soft sky.

Built to be the first building block of an end-to-end DevOps project: one
self-contained, container-ready app with a database, ready to deploy to AWS.

**No build tooling.** Python backend + a plain HTML/CSS/JS frontend. No Maven,
no npm, no bundler — just `pip install` and run.

![Cirrus](docs/preview.png)

## Stack

- **Backend:** Python 3.12, FastAPI (REST API)
- **Database:** SQLite for local dev (zero setup), PostgreSQL in the cloud — via SQLAlchemy
- **Frontend:** vanilla HTML/CSS/JS served by FastAPI (no build step)
- **Ops-ready:** Docker image + `/metrics` Prometheus endpoint for later monitoring

## Project structure

```
cirrus/
├── requirements.txt          # runtime deps
├── requirements-dev.txt      # + test deps
├── Dockerfile                # slim, non-root image
├── app/
│   ├── main.py               # FastAPI app + routes + static mount
│   ├── database.py           # SQLAlchemy engine/session (DATABASE_URL)
│   ├── models.py             # Transaction ORM model
│   ├── schemas.py            # Pydantic request/response models
│   └── seed.py               # sample data on first run
├── static/                   # the glass UI (index.html, css, js)
└── tests/
    └── test_api.py           # API tests (pytest)
```

## Run it locally

You need **Python 3.11+**.

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

Open <http://localhost:8080>. It starts with a local SQLite database seeded with
sample transactions — nothing else to install. (`--reload` is for development.)

### Or with Docker

```bash
docker build -t cirrus:local .
docker run -p 8080:8080 cirrus:local
```

## Run the tests

```bash
pip install -r requirements-dev.txt
pytest -q
```

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/transactions` | list all transactions |
| GET | `/api/transactions/summary` | income, expense, balance totals |
| POST | `/api/transactions` | add one (JSON body) |
| DELETE | `/api/transactions/{id}` | remove one |
| GET | `/health` | health check |
| GET | `/metrics` | Prometheus metrics (for monitoring later) |
| GET | `/docs` | auto-generated interactive API docs (FastAPI) |

Example:

```bash
curl -X POST http://localhost:8080/api/transactions \
  -H "Content-Type: application/json" \
  -d '{"description":"Lunch","amount":12.50,"type":"EXPENSE","category":"Food","date":"2026-07-04"}'
```

## Running against Postgres (for AWS)

The app reads its database connection from the `DATABASE_URL` environment
variable. Point it at RDS (or any Postgres) and it just works — SQLAlchemy creates
the schema on first start:

```bash
export DATABASE_URL="postgresql+psycopg2://cirrus:<password>@<host>:5432/cirrus"
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

With no `DATABASE_URL` set, it falls back to local SQLite.

## About the design

The look is modelled on Apple's frosted "liquid glass" surfaces (think iOS
Control Center or the Weather app): a bright sky-blue gradient with drifting light,
translucent white panels with heavy background blur, hairline highlights along the
top edge, and SF Pro typography (with Inter as a fallback on non-Apple devices).

## What's next

This repo is just the app. Later steps can add infrastructure (Terraform), a
Kubernetes deployment (Helm), CI/CD (Jenkins), GitOps (ArgoCD), and monitoring
(Prometheus + Grafana) around it. Because it's a plain container exposing `/health`
and `/metrics`, it drops into all of that cleanly.
