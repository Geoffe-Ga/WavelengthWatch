"""Utility helpers for backend services."""

from __future__ import annotations

from datetime import UTC, datetime


def to_utc_naive(dt: datetime) -> datetime:
    """Return a naive UTC datetime from a possibly tz-aware input."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=UTC)
    else:
        dt = dt.astimezone(UTC)
    return dt.replace(tzinfo=None)
