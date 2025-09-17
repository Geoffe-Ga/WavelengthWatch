"""FastAPI application entrypoint."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session

from . import database
from .routers import curriculum, journal, layer, phase, strategy
from .tools.seed_data import seed_database


def create_application() -> FastAPI:
    """Configure and return the FastAPI application."""

    @asynccontextmanager
    async def lifespan(app: FastAPI):  # pragma: no cover - exercised via startup events
        database.create_db_and_tables()
        with Session(database.engine) as session:
            seed_database(session)
        yield

    application = FastAPI(title="WavelengthWatch API", version="1.0.0", lifespan=lifespan)

    application.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    application.include_router(layer.router)
    application.include_router(phase.router)
    application.include_router(curriculum.router)
    application.include_router(strategy.router)
    application.include_router(journal.router)

    @application.get("/health", tags=["health"])
    def healthcheck() -> dict[str, str]:
        return {"status": "ok"}

    return application


app = create_application()

__all__ = ["app", "create_application"]
