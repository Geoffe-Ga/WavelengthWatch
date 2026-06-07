"""Tests for DATABASE_URL normalization (Railway Postgres compatibility)."""

from __future__ import annotations

import pytest

from backend.database import _normalize_database_url


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        # Railway's plugin hands out the bare ``postgres://`` scheme.
        (
            "postgres://host:5432/db",
            "postgresql+psycopg://host:5432/db",
        ),
        # SQLAlchemy's canonical bare scheme also needs the driver pinned.
        (
            "postgresql://host:5432/db",
            "postgresql+psycopg://host:5432/db",
        ),
    ],
)
def test_normalizes_bare_postgres_schemes_to_psycopg(raw: str, expected: str) -> None:
    assert _normalize_database_url(raw) == expected


@pytest.mark.parametrize(
    "url",
    [
        "postgresql+psycopg://host:5432/db",
        "postgresql+psycopg2://host:5432/db",
        "sqlite:///./app.db",
        "sqlite:////tmp/app.db",
    ],
)
def test_leaves_explicit_driver_and_sqlite_urls_untouched(url: str) -> None:
    assert _normalize_database_url(url) == url


def test_preserves_path_and_query_when_swapping_scheme() -> None:
    raw = "postgres://host:5432/db?sslmode=require"
    expected = "postgresql+psycopg://host:5432/db?sslmode=require"
    assert _normalize_database_url(raw) == expected
