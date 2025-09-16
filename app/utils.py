"""Utility helpers for the FastAPI application."""
from __future__ import annotations

from datetime import UTC, datetime, timezone


def parse_iso_datetime(value: str) -> datetime:
    """Parse an ISO-8601 string into an aware datetime.

    Args:
        value: The ISO-8601 formatted datetime string. Handles a trailing ``Z``
            by converting it to ``+00:00`` before parsing.

    Returns:
        A timezone-aware datetime normalized to UTC.
    """

    normalized = value.replace("Z", "+00:00")
    dt = datetime.fromisoformat(normalized)
    return ensure_aware(dt)


def ensure_aware(dt: datetime) -> datetime:
    """Ensure the provided datetime is timezone-aware.

    Naive datetimes are assumed to be in UTC to keep storage consistent.
    """

    if dt.tzinfo is None or dt.tzinfo.utcoffset(dt) is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(timezone.utc)
