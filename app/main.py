"""FastAPI application entry point."""
from __future__ import annotations

from fastapi import FastAPI
from sqlmodel import Session

from app import routers
from app.database import create_db_and_tables, engine
from app.seed_data import seed_data

app = FastAPI(title="WavelengthWatch API", version="0.1.0")


@app.on_event("startup")
def on_startup() -> None:
    """Initialize database schema and seed data on startup."""
    create_db_and_tables()
    with Session(engine) as session:
        seed_data(session)


# Include routers
app.include_router(routers.layer.router)
app.include_router(routers.phase.router)
app.include_router(routers.curriculum.router)
app.include_router(routers.strategy.router)
app.include_router(routers.journal.router)


@app.get("/health", tags=["health"])
def healthcheck() -> dict[str, str]:
    """Simple healthcheck endpoint."""
    return {"status": "ok"}
