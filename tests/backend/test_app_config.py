"""Tests covering high-level FastAPI application configuration."""

from __future__ import annotations

import pytest
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.app import DEFAULT_DEV_CORS_ORIGINS, create_application


def _cors_origins(app: FastAPI) -> list[str]:
    for middleware in app.user_middleware:
        if middleware.cls is CORSMiddleware:
            return middleware.kwargs["allow_origins"]
    raise AssertionError("CORS middleware not configured on application")


def test_create_application_uses_dev_defaults(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Development builds should fall back to the local default allowlist."""

    monkeypatch.delenv("APP_ENV", raising=False)
    monkeypatch.delenv("CORS_ALLOWED_ORIGINS", raising=False)

    app = create_application()

    assert _cors_origins(app) == DEFAULT_DEV_CORS_ORIGINS


def test_create_application_reads_configured_origins(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Production configuration should respect the provided allowlist."""

    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv(
        "CORS_ALLOWED_ORIGINS",
        "https://example.com, https://api.example.com",
    )

    app = create_application()

    assert _cors_origins(app) == [
        "https://example.com",
        "https://api.example.com",
    ]


def test_create_application_requires_origins_in_production(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Fail fast when production deployments are missing explicit origins."""

    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.delenv("CORS_ALLOWED_ORIGINS", raising=False)

    with pytest.raises(RuntimeError):
        create_application()
