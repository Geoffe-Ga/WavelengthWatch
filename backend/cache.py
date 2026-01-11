"""Simple in-memory cache with TTL for analytics endpoints.

This module provides a lightweight caching layer for analytics queries.
Since this is a watch-only app with optional backend, we use a simple
in-memory cache rather than Redis to avoid infrastructure complexity.

Design decisions:
- TTL-based expiration (5 minutes default)
- User-based invalidation on journal entry creation
- Thread-safe with lock protection
- No persistence (cache cleared on restart)
"""

from __future__ import annotations

import threading
import time
from dataclasses import dataclass
from typing import Any

# Default TTL: 5 minutes balances freshness with performance
# Analytics data changes only when journal entries are created
DEFAULT_TTL_SECONDS = 300


@dataclass
class CacheEntry:
    """A cached value with expiration timestamp."""

    value: Any
    expires_at: float


class AnalyticsCache:
    """Thread-safe in-memory cache with TTL support.

    Optimized for analytics endpoints where:
    - Queries involve multiple joins and aggregations
    - Data changes infrequently (only on journal entry creation)
    - Cache invalidation is straightforward (by user_id)

    Example:
        cache = AnalyticsCache(ttl_seconds=300)
        key = make_cache_key(user_id=1, endpoint="overview", ...)

        # Try cache first
        result = cache.get(key)
        if result is None:
            result = expensive_calculation()
            cache.set(key, result)

        # Invalidate on data change
        cache.invalidate_user(user_id=1)
    """

    def __init__(self, ttl_seconds: int = DEFAULT_TTL_SECONDS) -> None:
        """Initialize cache with specified TTL.

        Args:
            ttl_seconds: Time-to-live for cache entries in seconds
        """
        self._cache: dict[str, CacheEntry] = {}
        self._lock = threading.Lock()
        self._ttl = ttl_seconds

    def get(self, key: str) -> Any | None:
        """Get a value from cache if it exists and hasn't expired.

        Args:
            key: Cache key to look up

        Returns:
            Cached value if found and not expired, None otherwise
        """
        with self._lock:
            entry = self._cache.get(key)
            if entry is None:
                return None
            if time.time() > entry.expires_at:
                # Lazy expiration: remove expired entry on access
                del self._cache[key]
                return None
            return entry.value

    def set(self, key: str, value: Any) -> None:
        """Set a value in cache with TTL.

        Args:
            key: Cache key
            value: Value to cache (should be serializable)
        """
        with self._lock:
            self._cache[key] = CacheEntry(
                value=value,
                expires_at=time.time() + self._ttl,
            )

    def invalidate_user(self, user_id: int) -> None:
        """Invalidate all cache entries for a specific user.

        Called when a new journal entry is created to ensure
        analytics reflect the latest data.

        Args:
            user_id: User ID whose cache entries should be invalidated
        """
        with self._lock:
            prefix = f"user:{user_id}:"
            keys_to_delete = [k for k in self._cache if k.startswith(prefix)]
            for key in keys_to_delete:
                del self._cache[key]

    def clear(self) -> None:
        """Clear all cache entries.

        Useful for testing or when a full cache invalidation is needed.
        """
        with self._lock:
            self._cache.clear()

    def stats(self) -> dict[str, int]:
        """Return cache statistics for monitoring.

        Returns:
            Dictionary with entry_count and approximate memory usage
        """
        with self._lock:
            return {
                "entry_count": len(self._cache),
            }


# Global cache instance - used by analytics router
analytics_cache = AnalyticsCache()


def make_cache_key(
    user_id: int,
    endpoint: str,
    start_date: str,
    end_date: str,
    **kwargs: Any,
) -> str:
    """Generate a deterministic cache key for analytics queries.

    The key format is: user:{user_id}:{endpoint}:{start_date}:{end_date}:{extras}

    Args:
        user_id: The user ID (required)
        endpoint: Name of the analytics endpoint (e.g., "overview", "growth")
        start_date: ISO format start date string
        end_date: ISO format end date string
        **kwargs: Additional parameters affecting the result (e.g., limit)

    Returns:
        A unique, deterministic cache key string
    """
    # Sort kwargs for deterministic key generation
    extra = ":".join(f"{k}={v}" for k, v in sorted(kwargs.items()))
    base = f"user:{user_id}:{endpoint}:{start_date}:{end_date}"
    return f"{base}:{extra}" if extra else base


__all__ = [
    "AnalyticsCache",
    "analytics_cache",
    "make_cache_key",
    "DEFAULT_TTL_SECONDS",
]
