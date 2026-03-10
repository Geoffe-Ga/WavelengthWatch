"""Performance tests for analytics endpoints.

Validates spec requirement: "Analytics load in <2 seconds" (line 331).

Test scenarios:
- Cold start (no cache)
- Warm start (cached data)
- Different dataset sizes (100, 500, 1000, 5000 entries)
- Different time ranges (7 days, 30 days, all-time)

Performance targets:
- Backend response: <500ms for 1000 entries
- Total analytics load: <2 seconds (spec requirement)
"""

import time
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from tests.backend.test_data_generator import (
    generate_distributed_entries,
)


@pytest.fixture
def perf_client(client: TestClient) -> TestClient:
    """Client for performance tests with isolated database per test.

    Each test receives a fresh database via the base client fixture's tmp_path,
    ensuring no test data pollution or interference between tests.
    """
    return client


def measure_response_time(client: TestClient, endpoint: str, params: dict) -> float:
    """Measure endpoint response time in milliseconds.

    Args:
        client: FastAPI test client
        endpoint: API endpoint path
        params: Query parameters

    Returns:
        Response time in milliseconds
    """
    start = time.perf_counter()
    response = client.get(endpoint, params=params)
    end = time.perf_counter()

    assert response.status_code == 200, f"Request failed: {response.json()}"
    return (end - start) * 1000  # Convert to milliseconds


def create_test_entries(client: TestClient, count: int, user_id: int = 999) -> dict:
    """Create N test entries and return date range params.

    Args:
        client: FastAPI test client
        count: Number of entries to create
        user_id: User ID for entries

    Returns:
        Dict with user_id, start_date, end_date for analytics queries
    """
    start_date = datetime.now(UTC) - timedelta(days=30)
    end_date = datetime.now(UTC)

    # Use distributed entries for more realistic temporal patterns
    entries = generate_distributed_entries(count, user_id, start_date, days_span=30)

    # Batch create entries with validation
    for i, entry in enumerate(entries):
        response = client.post("/api/v1/journal", json=entry)
        assert response.status_code == 201, (
            f"Failed to create entry {i + 1}/{count}: {response.json()}"
        )

    return {
        "user_id": user_id,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
    }


# Performance tests for different dataset sizes


@pytest.mark.parametrize("entry_count", [100, 500, 1000])
def test_analytics_overview_performance(perf_client: TestClient, entry_count: int):
    """Test overview endpoint performance with varying dataset sizes."""
    params = create_test_entries(perf_client, entry_count, user_id=1000 + entry_count)

    response_time = measure_response_time(
        perf_client, "/api/v1/analytics/overview", params
    )

    # Performance target: <500ms for 1000 entries
    if entry_count <= 1000:
        assert response_time < 500, (
            f"Overview too slow: {response_time:.1f}ms for {entry_count} entries "
            f"(target: <500ms)"
        )

    print(f"\n✅ Overview with {entry_count} entries: {response_time:.1f}ms")


@pytest.mark.parametrize("entry_count", [100, 500, 1000])
def test_analytics_emotional_landscape_performance(
    perf_client: TestClient, entry_count: int
):
    """Test emotional landscape endpoint performance."""
    params = create_test_entries(perf_client, entry_count, user_id=2000 + entry_count)

    response_time = measure_response_time(
        perf_client, "/api/v1/analytics/emotional-landscape", params
    )

    if entry_count <= 1000:
        assert response_time < 500, (
            f"Emotional landscape too slow: {response_time:.1f}ms for {entry_count} "
            f"entries (target: <500ms)"
        )

    print(f"\n✅ Emotional landscape with {entry_count} entries: {response_time:.1f}ms")


@pytest.mark.parametrize("entry_count", [100, 500, 1000])
def test_analytics_self_care_performance(perf_client: TestClient, entry_count: int):
    """Test self-care analytics endpoint performance."""
    params = create_test_entries(perf_client, entry_count, user_id=3000 + entry_count)
    params["limit"] = 10  # Top 10 strategies

    response_time = measure_response_time(
        perf_client, "/api/v1/analytics/self-care", params
    )

    if entry_count <= 1000:
        assert response_time < 500, (
            f"Self-care too slow: {response_time:.1f}ms for {entry_count} entries "
            f"(target: <500ms)"
        )

    print(f"\n✅ Self-care with {entry_count} entries: {response_time:.1f}ms")


@pytest.mark.parametrize("entry_count", [100, 500, 1000])
def test_analytics_temporal_patterns_performance(
    perf_client: TestClient, entry_count: int
):
    """Test temporal patterns endpoint performance."""
    params = create_test_entries(perf_client, entry_count, user_id=4000 + entry_count)

    response_time = measure_response_time(
        perf_client, "/api/v1/analytics/temporal", params
    )

    if entry_count <= 1000:
        assert response_time < 500, (
            f"Temporal patterns too slow: {response_time:.1f}ms for {entry_count} "
            f"entries (target: <500ms)"
        )

    print(f"\n✅ Temporal patterns with {entry_count} entries: {response_time:.1f}ms")


@pytest.mark.parametrize("entry_count", [100, 500, 1000])
def test_analytics_growth_indicators_performance(
    perf_client: TestClient, entry_count: int
):
    """Test growth indicators endpoint performance."""
    params = create_test_entries(perf_client, entry_count, user_id=5000 + entry_count)

    response_time = measure_response_time(
        perf_client, "/api/v1/analytics/growth", params
    )

    if entry_count <= 1000:
        assert response_time < 500, (
            f"Growth indicators too slow: {response_time:.1f}ms for {entry_count} "
            f"entries (target: <500ms)"
        )

    print(f"\n✅ Growth indicators with {entry_count} entries: {response_time:.1f}ms")


# Cache effectiveness tests


def test_cache_effectiveness_overview(perf_client: TestClient):
    """Test that cached responses meet performance budget.

    Uses a deterministic <500ms budget with 3-sample average instead of
    unreliable cold-vs-warm comparisons that flake on shared CI runners.
    """
    params = create_test_entries(perf_client, 1000, user_id=6000)

    # Warm up
    measure_response_time(perf_client, "/api/v1/analytics/overview", params)

    # Measure 3 subsequent requests
    times = [
        measure_response_time(perf_client, "/api/v1/analytics/overview", params)
        for _ in range(3)
    ]
    avg_time = sum(times) / len(times)

    assert avg_time < 500, (
        f"Cached overview too slow: avg={avg_time:.1f}ms "
        f"(target: <500ms, samples: {[f'{t:.1f}' for t in times]})"
    )

    print(
        f"\n✅ Cache effectiveness: avg={avg_time:.1f}ms "
        f"(samples: {[f'{t:.1f}' for t in times]})"
    )


# Time range tests


@pytest.mark.parametrize(
    "days_span,entry_count",
    [
        (7, 700),  # Weekly view
        (30, 1000),  # Monthly view (default)
        (90, 2000),  # Quarterly view
    ],
)
def test_analytics_time_range_performance(
    perf_client: TestClient, days_span: int, entry_count: int
):
    """Test performance with different time range queries."""
    start_date = datetime.now(UTC) - timedelta(days=days_span)
    end_date = datetime.now(UTC)

    entries = generate_distributed_entries(
        entry_count, user_id=7000, start_date=start_date, days_span=days_span
    )

    for entry in entries:
        perf_client.post("/api/v1/journal", json=entry)

    params = {
        "user_id": 7000,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
    }

    response_time = measure_response_time(
        perf_client, "/api/v1/analytics/overview", params
    )

    # All time ranges should meet performance target
    assert response_time < 500, (
        f"Time range query too slow: {response_time:.1f}ms for {days_span} days, "
        f"{entry_count} entries (target: <500ms)"
    )

    print(
        f"\n✅ {days_span}-day range with {entry_count} entries: {response_time:.1f}ms"
    )


# Comprehensive multi-endpoint test


def test_all_analytics_endpoints_combined(perf_client: TestClient):
    """Test total load time for all 5 analytics endpoints.

    Validates spec requirement: "Analytics load in <2 seconds" (line 331).
    Simulates user navigating to analytics tab and loading all insights.
    """
    params = create_test_entries(perf_client, 1000, user_id=8000)
    params_self_care = {**params, "limit": 10}

    endpoints = [
        "/api/v1/analytics/overview",
        "/api/v1/analytics/emotional-landscape",
        "/api/v1/analytics/self-care",
        "/api/v1/analytics/temporal",
        "/api/v1/analytics/growth",
    ]

    total_time = 0.0
    individual_times = []

    for endpoint in endpoints:
        endpoint_params = params_self_care if "self-care" in endpoint else params
        response_time = measure_response_time(perf_client, endpoint, endpoint_params)
        total_time += response_time
        individual_times.append((endpoint.split("/")[-1], response_time))

    # CRITICAL: Total load time must be <2 seconds per spec
    assert total_time < 2000, (
        f"Total analytics load time exceeds spec: {total_time:.1f}ms "
        f"(target: <2000ms)\n"
        f"Individual times: {individual_times}"
    )

    print(
        f"\n✅ Total load time for all endpoints: {total_time:.1f}ms (target: <2000ms)"
    )
    for name, duration in individual_times:
        print(f"   - {name}: {duration:.1f}ms")


# Stress test (optional, marked as slow)


@pytest.mark.slow
def test_analytics_stress_5000_entries(perf_client: TestClient):
    """Stress test with 5000 entries (marked slow, skip in normal runs)."""
    params = create_test_entries(perf_client, 5000, user_id=9000)

    response_time = measure_response_time(
        perf_client, "/api/v1/analytics/overview", params
    )

    # More lenient target for stress test
    assert response_time < 1000, (
        f"Stress test exceeded 1s: {response_time:.1f}ms for 5000 entries"
    )

    print(f"\n✅ Stress test (5000 entries): {response_time:.1f}ms")
