"""Tests for analytics endpoints."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta


def test_analytics_overview_basic(client) -> None:
    """Test basic analytics overview with default date range."""
    # Use date range that includes seed data
    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 1,
            "start_date": "2025-09-01T00:00:00Z",
            "end_date": "2025-09-30T23:59:59Z",
        },
    )
    assert response.status_code == 200

    data = response.json()

    # Basic structure validation
    assert "total_entries" in data
    assert "current_streak" in data
    assert "avg_frequency" in data
    assert "last_check_in" in data
    assert "medicinal_ratio" in data
    assert "medicinal_trend" in data
    assert "dominant_layer_id" in data
    assert "dominant_phase_id" in data
    assert "unique_emotions" in data
    assert "strategies_used" in data
    assert "secondary_emotions_pct" in data

    # User 1 has 2 entries in seed data
    assert data["total_entries"] == 2
    assert data["unique_emotions"] >= 1
    assert data["last_check_in"] is not None


def test_analytics_overview_with_date_range(client) -> None:
    """Test analytics with custom date range."""
    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 1,
            "start_date": "2025-09-13T00:00:00Z",
            "end_date": "2025-09-14T23:59:59Z",
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Should only include entry from 2025-09-13
    assert data["total_entries"] == 1


def test_analytics_overview_no_entries(client) -> None:
    """Test analytics for user with no journal entries."""
    response = client.get(
        "/api/v1/analytics/overview",
        params={"user_id": 999},
    )
    assert response.status_code == 404
    assert "No journal entries found" in response.json()["detail"]


def test_analytics_overview_medicinal_ratio(client) -> None:
    """Test medicinal ratio calculation."""
    # Create mix of medicinal and toxic entries
    now = datetime.now(UTC)

    # Medicinal entry (curriculum_id=1 is Medicinal from seed data)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": now.isoformat(),
            "user_id": 100,
            "curriculum_id": 1,  # Medicinal
        },
    )

    # Toxic entry (curriculum_id=10 is Toxic from seed data)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": now.isoformat(),
            "user_id": 100,
            "curriculum_id": 10,  # Toxic
        },
    )

    # Another medicinal
    client.post(
        "/api/v1/journal",
        json={
            "created_at": now.isoformat(),
            "user_id": 100,
            "curriculum_id": 2,  # Medicinal
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={"user_id": 100},
    )
    assert response.status_code == 200
    data = response.json()

    # Should be 66.67% medicinal (2 out of 3)
    assert 66.0 <= data["medicinal_ratio"] <= 67.0


def test_analytics_overview_streak_calculation(client) -> None:
    """Test streak calculation with consecutive days."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries on consecutive days
    for i in range(5):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 101,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 101,
            "end_date": (base_date + timedelta(days=4, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Should have 5-day streak
    assert data["current_streak"] == 5


def test_analytics_overview_streak_with_gap(client) -> None:
    """Test streak resets after a gap."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries with a gap
    client.post(
        "/api/v1/journal",
        json={
            "created_at": base_date.isoformat(),
            "user_id": 102,
            "curriculum_id": 1,
        },
    )

    # Gap of 2 days
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(days=3)).isoformat(),
            "user_id": 102,
            "curriculum_id": 1,
        },
    )

    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(days=4)).isoformat(),
            "user_id": 102,
            "curriculum_id": 1,
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 102,
            "end_date": (base_date + timedelta(days=4, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Should have 2-day streak (only the last two consecutive days)
    assert data["current_streak"] == 2


def test_analytics_overview_avg_frequency(client) -> None:
    """Test average frequency calculation."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 6 entries over 3 days (avg should be 2.0)
    for i in range(3):
        for j in range(2):
            client.post(
                "/api/v1/journal",
                json={
                    "created_at": (
                        base_date + timedelta(days=i, hours=j * 2)
                    ).isoformat(),
                    "user_id": 103,
                    "curriculum_id": 1,
                },
            )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 103,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(days=2, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Should be 2.0 entries per day
    assert 1.9 <= data["avg_frequency"] <= 2.1


def test_analytics_overview_dominant_layer_and_phase(client) -> None:
    """Test dominant layer and phase calculation (last 7 days)."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries with different layers and phases
    # Layer 1, Phase 1 appears 3 times
    for i in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 104,
                "curriculum_id": 1,  # Layer 1, Phase 1, Medicinal
            },
        )

    # Layer 2, Phase 2 appears 2 times
    for i in range(2):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 104,
                "curriculum_id": 19,  # Layer 1, Phase 2, Medicinal
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 104,
            "start_date": (base_date - timedelta(days=7)).isoformat(),
            "end_date": (base_date + timedelta(days=6)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Layer 1 should be dominant (appears 5 times)
    assert data["dominant_layer_id"] == 1
    # Phase 1 should be dominant (appears 3 times vs 2 for phase 2)
    assert data["dominant_phase_id"] == 1


def test_analytics_overview_unique_emotions_and_strategies(client) -> None:
    """Test unique emotions and strategies count."""
    base_date = datetime.now(UTC) - timedelta(days=5)

    # Create entries with same curriculum multiple times
    for i in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 105,
                "curriculum_id": 1,
                "strategy_id": 1,
            },
        )

    # Different curriculum
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=4)).isoformat(),
            "user_id": 105,
            "curriculum_id": 2,
            "strategy_id": 1,
        },
    )

    # Different strategy
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=5)).isoformat(),
            "user_id": 105,
            "curriculum_id": 1,
            "strategy_id": 2,
        },
    )

    # No strategy
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=6)).isoformat(),
            "user_id": 105,
            "curriculum_id": 3,
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={"user_id": 105},
    )
    assert response.status_code == 200
    data = response.json()

    # 3 unique curriculum_ids (1, 2, 3)
    assert data["unique_emotions"] == 3
    # 2 unique strategy_ids (1, 2), excluding null
    assert data["strategies_used"] == 2


def test_analytics_overview_secondary_emotions_percentage(client) -> None:
    """Test secondary emotions percentage calculation."""
    base_date = datetime.now(UTC) - timedelta(days=5)

    # 2 entries with secondary
    for i in range(2):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 106,
                "curriculum_id": 1,
                "secondary_curriculum_id": 2,
            },
        )

    # 1 entry without secondary
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=2)).isoformat(),
            "user_id": 106,
            "curriculum_id": 1,
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={"user_id": 106},
    )
    assert response.status_code == 200
    data = response.json()

    # Should be 66.67% (2 out of 3)
    assert 66.0 <= data["secondary_emotions_pct"] <= 67.0


def test_analytics_overview_medicinal_trend(client) -> None:
    """Test medicinal trend calculation."""
    base_date = datetime(2025, 10, 1, 12, 0, 0, tzinfo=UTC)

    # Previous period (10 days): 1 medicinal, 1 toxic (50%)
    prev_start = base_date - timedelta(days=20)

    client.post(
        "/api/v1/journal",
        json={
            "created_at": (prev_start + timedelta(days=1)).isoformat(),
            "user_id": 107,
            "curriculum_id": 1,  # Medicinal
        },
    )
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (prev_start + timedelta(days=2)).isoformat(),
            "user_id": 107,
            "curriculum_id": 10,  # Toxic
        },
    )

    # Current period (10 days): 3 medicinal, 1 toxic (75%)
    curr_start = base_date - timedelta(days=10)
    curr_end = base_date

    client.post(
        "/api/v1/journal",
        json={
            "created_at": (curr_start + timedelta(days=1)).isoformat(),
            "user_id": 107,
            "curriculum_id": 1,  # Medicinal
        },
    )
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (curr_start + timedelta(days=2)).isoformat(),
            "user_id": 107,
            "curriculum_id": 1,  # Medicinal
        },
    )
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (curr_start + timedelta(days=3)).isoformat(),
            "user_id": 107,
            "curriculum_id": 1,  # Medicinal
        },
    )
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (curr_start + timedelta(days=4)).isoformat(),
            "user_id": 107,
            "curriculum_id": 10,  # Toxic
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 107,
            "start_date": curr_start.isoformat(),
            "end_date": curr_end.isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Current: 75% medicinal, Previous: 50% medicinal
    # Trend should be +25%
    assert data["medicinal_ratio"] == 75.0
    assert 24.0 <= data["medicinal_trend"] <= 26.0


def test_analytics_overview_default_start_date(client) -> None:
    """Test that start_date defaults to 30 days ago."""
    now = datetime.now(UTC)

    # Create entry 31 days ago (should not be included with default)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (now - timedelta(days=31)).isoformat(),
            "user_id": 108,
            "curriculum_id": 1,
        },
    )

    # Create entry 20 days ago (should be included)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (now - timedelta(days=20)).isoformat(),
            "user_id": 108,
            "curriculum_id": 1,
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={"user_id": 108},
    )
    assert response.status_code == 200
    data = response.json()

    # Should only count the entry from 20 days ago
    assert data["total_entries"] == 1


def test_analytics_overview_missing_user_id(client) -> None:
    """Test that user_id is required."""
    response = client.get("/api/v1/analytics/overview")
    assert response.status_code == 422  # Validation error


def test_analytics_overview_last_check_in_format(client) -> None:
    """Test that last_check_in is a valid datetime."""
    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 1,
            "start_date": "2025-09-01T00:00:00Z",
            "end_date": "2025-09-30T23:59:59Z",
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Should be ISO format datetime string
    last_check_in = data["last_check_in"]
    assert last_check_in is not None
    # Validate it can be parsed
    parsed = datetime.fromisoformat(last_check_in.replace("Z", "+00:00"))
    assert parsed.tzinfo is not None


# MARK: - Emotional Landscape Tests


def test_emotional_landscape_basic_structure(client) -> None:
    """Test emotional landscape endpoint returns correct structure."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create sample entries
    for i in range(5):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 200,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 200,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=6)).isoformat(),
        },
    )

    assert response.status_code == 200
    data = response.json()

    # Verify structure
    assert "layer_distribution" in data
    assert "phase_distribution" in data
    assert "top_emotions" in data
    assert isinstance(data["layer_distribution"], list)
    assert isinstance(data["phase_distribution"], list)
    assert isinstance(data["top_emotions"], list)


def test_emotional_landscape_layer_distribution(client) -> None:
    """Test layer distribution calculation."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries across different layers
    # curriculum_id 1 is in layer 1 (Beige)
    # curriculum_id 2 is in layer 2 (Purple)
    # curriculum_id 3 is in layer 3 (Red)

    # 2 Beige entries (both curriculum 1)
    for i in range(2):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 201,
                "curriculum_id": 1,
            },
        )

    # 1 Purple entry (curriculum 2)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=2)).isoformat(),
            "user_id": 201,
            "curriculum_id": 2,
        },
    )

    # 1 Red entry (curriculum 3)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=3)).isoformat(),
            "user_id": 201,
            "curriculum_id": 3,
        },
    )

    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 201,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=6)).isoformat(),
        },
    )

    assert response.status_code == 200
    data = response.json()

    layer_dist = data["layer_distribution"]
    assert len(layer_dist) > 0

    # Find Beige layer (layer_id 1)
    beige_layer = next((item for item in layer_dist if item["layer_id"] == 1), None)
    assert beige_layer is not None
    assert beige_layer["count"] == 2
    assert beige_layer["percentage"] == 50.0  # 2 out of 4 total


def test_emotional_landscape_phase_distribution(client) -> None:
    """Test phase distribution calculation."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries with different phases
    # curriculum_id 1 is in phase 1 (Rising)
    # curriculum_id 2 is in phase 1 (Rising)
    # curriculum_id 3 is in phase 1 (Rising)
    # Need to find curriculum items in different phases

    # For now, create 3 entries with same curriculum
    # (will update once we understand phase mapping)
    for i in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 202,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 202,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=6)).isoformat(),
        },
    )

    assert response.status_code == 200
    data = response.json()

    phase_dist = data["phase_distribution"]
    assert len(phase_dist) > 0

    # At least one phase should have count=3 and percentage=100
    phase_with_all = next((p for p in phase_dist if p["count"] == 3), None)
    assert phase_with_all is not None
    assert phase_with_all["percentage"] == 100.0


def test_emotional_landscape_top_emotions(client) -> None:
    """Test top emotions ranking."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries with different emotions
    # curriculum_id 1 appears 3 times (most frequent)
    # curriculum_id 2 appears 2 times
    # curriculum_id 3 appears 1 time

    for _ in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=_)).isoformat(),
                "user_id": 203,
                "curriculum_id": 1,
            },
        )

    for _ in range(2):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=_ + 3)).isoformat(),
                "user_id": 203,
                "curriculum_id": 2,
            },
        )

    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=5)).isoformat(),
            "user_id": 203,
            "curriculum_id": 3,
        },
    )

    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 203,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=6)).isoformat(),
        },
    )

    assert response.status_code == 200
    data = response.json()

    top_emotions = data["top_emotions"]
    assert len(top_emotions) >= 3

    # Top emotion should be curriculum_id 1 with count 3
    assert top_emotions[0]["curriculum_id"] == 1
    assert top_emotions[0]["count"] == 3

    # Second should be curriculum_id 2 with count 2
    assert top_emotions[1]["curriculum_id"] == 2
    assert top_emotions[1]["count"] == 2


def test_emotional_landscape_top_emotions_includes_secondary(client) -> None:
    """Test that top emotions includes secondary emotions."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entry with secondary emotion
    client.post(
        "/api/v1/journal",
        json={
            "created_at": base_date.isoformat(),
            "user_id": 204,
            "curriculum_id": 1,
            "secondary_curriculum_id": 2,
        },
    )

    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 204,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=1)).isoformat(),
        },
    )

    assert response.status_code == 200
    data = response.json()

    top_emotions = data["top_emotions"]
    curriculum_ids = [e["curriculum_id"] for e in top_emotions]

    # Both primary (1) and secondary (2) should appear in top emotions
    assert 1 in curriculum_ids
    assert 2 in curriculum_ids


def test_emotional_landscape_empty_user(client) -> None:
    """Test emotional landscape for user with no entries."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 999,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=1)).isoformat(),
        },
    )

    # Should return 404 for user with no entries
    assert response.status_code == 404


def test_emotional_landscape_date_filtering(client) -> None:
    """Test emotional landscape respects date range filter."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries across different time periods
    # Inside range
    client.post(
        "/api/v1/journal",
        json={
            "created_at": base_date.isoformat(),
            "user_id": 205,
            "curriculum_id": 1,
        },
    )

    # Outside range (before)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date - timedelta(days=2)).isoformat(),
            "user_id": 205,
            "curriculum_id": 2,
        },
    )

    # Outside range (after)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(days=2)).isoformat(),
            "user_id": 205,
            "curriculum_id": 3,
        },
    )

    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 205,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=1)).isoformat(),
        },
    )

    assert response.status_code == 200
    data = response.json()

    # Should only count the entry within range (curriculum_id 1)
    top_emotions = data["top_emotions"]
    assert len(top_emotions) == 1
    assert top_emotions[0]["curriculum_id"] == 1


def test_emotional_landscape_default_dates(client) -> None:
    """Test emotional landscape uses 30-day default when dates not provided."""
    base_date = datetime.now(UTC)

    # Create entry today
    client.post(
        "/api/v1/journal",
        json={
            "created_at": base_date.isoformat(),
            "user_id": 206,
            "curriculum_id": 1,
        },
    )

    # Create entry 31 days ago (outside default 30-day window)
    old_date = base_date - timedelta(days=31)
    client.post(
        "/api/v1/journal",
        json={
            "created_at": old_date.isoformat(),
            "user_id": 206,
            "curriculum_id": 2,
        },
    )

    # Call without date parameters (should default to 30 days)
    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={"user_id": 206},
    )

    assert response.status_code == 200
    data = response.json()

    # Should only include today's entry (curriculum_id 1)
    # not the 31-day-old entry (curriculum_id 2)
    top_emotions = data["top_emotions"]
    assert len(top_emotions) == 1
    assert top_emotions[0]["curriculum_id"] == 1
