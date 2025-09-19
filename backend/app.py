"""FastAPI application entrypoint."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session

from . import database
from .routers import curriculum, journal, layer, phase, strategy
from .tools.seed_data import seed_database

DEFAULT_DEV_CORS_ORIGINS: list[str] = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:5173",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5173",
]


def _determine_allowed_origins() -> list[str]:
    """Return CORS origins based on the current environment configuration."""

    environment = os.getenv("APP_ENV", "development").strip().lower()
    configured_origins = os.getenv("CORS_ALLOWED_ORIGINS", "")

    if configured_origins:
        origins = [
            origin.strip()
            for origin in configured_origins.split(",")
            if origin.strip()
        ]
        if origins:
            return origins

    if environment == "production":
        msg = "CORS_ALLOWED_ORIGINS must be set to a comma-separated list when APP_ENV=production"
        raise RuntimeError(msg)

    return DEFAULT_DEV_CORS_ORIGINS.copy()


def create_application() -> FastAPI:
    """Configure and return the FastAPI application."""

    @asynccontextmanager
    async def lifespan(
        app: FastAPI,
    ):  # pragma: no cover - exercised via startup events
        database.create_db_and_tables()
        with Session(database.engine) as session:
            seed_database(session)
        yield

    application = FastAPI(
        title="WavelengthWatch API", version="1.0.0", lifespan=lifespan
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=_determine_allowed_origins(),
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
