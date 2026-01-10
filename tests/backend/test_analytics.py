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
    assert "longest_streak" in data
    assert "avg_frequency" in data
    assert "last_check_in" in data
    assert "medicinal_ratio" in data
    assert "medicinal_trend" in data
    assert "dominant_layer_id" in data
    assert "dominant_phase_id" in data
    assert "unique_emotions" in data
    assert "strategies_used" in data
    assert "secondary_emotions_pct" in data

    # Type validation
    assert isinstance(data["total_entries"], int)
    assert isinstance(data["current_streak"], int)
    assert isinstance(data["longest_streak"], int)
    assert isinstance(data["avg_frequency"], int | float)


def test_analytics_overview_empty_user(client) -> None:
    """Test analytics for user with no entries."""
    response = client.get(
        "/api/v1/analytics/overview",
        params={"user_id": 99999},  # Non-existent user
    )
    assert response.status_code == 404


def test_analytics_overview_current_streak_calculation(client) -> None:
    """Test current streak calculation with consecutive days."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 3 consecutive days of entries
    for i in range(3):
        response = client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 100,
                "curriculum_id": 1,
            },
        )
        assert response.status_code == 201

    # Query analytics
    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 100,
            "end_date": (base_date + timedelta(days=2, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    assert data["current_streak"] == 3


def test_analytics_overview_current_streak_with_gap(client) -> None:
    """Test current streak resets after gap in entries."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries: 2 days, gap, then 2 more days
    for i in range(2):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 101,
                "curriculum_id": 1,
            },
        )

    # Gap of 2 days

    # New streak starting day 4
    for i in range(2):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i + 4)).isoformat(),
                "user_id": 101,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 101,
            "end_date": (base_date + timedelta(days=5, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Current streak should be 2 (only the recent consecutive days)
    assert data["current_streak"] == 2


def test_analytics_overview_avg_frequency(client) -> None:
    """Test average frequency calculation."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 6 entries over 3 days (2 per day average)
    for i in range(6):
        entry_date = base_date + timedelta(days=i // 2, hours=i * 2)
        client.post(
            "/api/v1/journal",
            json={
                "created_at": entry_date.isoformat(),
                "user_id": 102,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 102,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(days=2, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # 6 entries over 3 days = 2.0 avg
    assert data["avg_frequency"] == 2.0


def test_analytics_overview_medicinal_ratio(client) -> None:
    """Test medicinal ratio calculation."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 3 medicinal and 1 toxic entry
    # curriculum_id 1 is medicinal, curriculum_id 10 is toxic
    for i in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 103,
                "curriculum_id": 1,  # Medicinal
            },
        )

    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=4)).isoformat(),
            "user_id": 103,
            "curriculum_id": 10,  # Toxic
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 103,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=5)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # 3 medicinal out of 4 total = 75%
    assert data["medicinal_ratio"] == 75.0


def test_analytics_overview_dominant_layer(client) -> None:
    """Test dominant layer identification."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 4 entries from layer 1, 1 entry from layer 2
    # curriculum_id 1-18 are layer 1, 19-36 are layer 2
    for i in range(4):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 104,
                "curriculum_id": 1,  # Layer 1
            },
        )

    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=5)).isoformat(),
            "user_id": 104,
            "curriculum_id": 19,  # Layer 2
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 104,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=6)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Layer 1 should be dominant
    assert data["dominant_layer_id"] == 1


def test_analytics_overview_dominant_phase(client) -> None:
    """Test dominant phase identification."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 3 entries from phase 1, 1 entry from phase 2
    # curriculum_id 1, 7, 13 are phase 1
    # curriculum_id 2, 8, 14 are phase 2
    for i in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 105,
                "curriculum_id": 1 if i == 0 else 7,  # Phase 1
            },
        )

    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=4)).isoformat(),
            "user_id": 105,
            "curriculum_id": 2,  # Phase 2
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 105,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=5)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Phase 1 should be dominant
    assert data["dominant_phase_id"] == 1


def test_analytics_overview_unique_emotions(client) -> None:
    """Test unique emotions count."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries with 3 different curriculum IDs
    for curriculum_id in [1, 2, 3]:
        for i in range(2):  # 2 entries per emotion
            entry_date = base_date + timedelta(hours=i + curriculum_id * 2)
            client.post(
                "/api/v1/journal",
                json={
                    "created_at": entry_date.isoformat(),
                    "user_id": 106,
                    "curriculum_id": curriculum_id,
                },
            )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 106,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=10)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Should count 3 unique curriculum IDs
    assert data["unique_emotions"] == 3


def test_analytics_overview_strategies_used(client) -> None:
    """Test strategies used count."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create entries with 2 different strategies
    for strategy_id in [1, 2]:
        for i in range(2):
            entry_date = base_date + timedelta(hours=i + strategy_id * 2)
            client.post(
                "/api/v1/journal",
                json={
                    "created_at": entry_date.isoformat(),
                    "user_id": 107,
                    "curriculum_id": 1,
                    "strategy_id": strategy_id,
                },
            )

    # One entry without strategy
    client.post(
        "/api/v1/journal",
        json={
            "created_at": (base_date + timedelta(hours=6)).isoformat(),
            "user_id": 107,
            "curriculum_id": 1,
        },
    )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 107,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=7)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Should count 2 unique strategies
    assert data["strategies_used"] == 2


def test_analytics_overview_secondary_emotions_pct(client) -> None:
    """Test secondary emotions percentage calculation."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 3 entries with secondary curriculum, 2 without
    for i in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i)).isoformat(),
                "user_id": 108,
                "curriculum_id": 1,
                "secondary_curriculum_id": 2,
            },
        )

    for i in range(2):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(hours=i + 4)).isoformat(),
                "user_id": 108,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 108,
            "start_date": base_date.isoformat(),
            "end_date": (base_date + timedelta(hours=6)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # 3 out of 5 = 60%
    assert data["secondary_emotions_pct"] == 60.0


def test_analytics_overview_last_check_in(client) -> None:
    """Test last check-in timestamp."""
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


# MARK: - Longest Streak Tests


def test_analytics_overview_longest_streak_basic(client) -> None:
    """Test longest streak is included in response."""
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
    assert "longest_streak" in data
    assert isinstance(data["longest_streak"], int)
    assert data["longest_streak"] >= 0


def test_analytics_overview_longest_streak_calculation(client) -> None:
    """Test longest streak tracks historical best."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 5-day streak
    for i in range(5):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 200,
                "curriculum_id": 1,
            },
        )

    # Gap of 2 days

    # Create 3-day streak
    for i in range(3):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=7 + i)).isoformat(),
                "user_id": 200,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 200,
            "end_date": (base_date + timedelta(days=9, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Current streak is 3 (last streak)
    assert data["current_streak"] == 3
    # Longest streak is 5 (historical best)
    assert data["longest_streak"] == 5


def test_analytics_overview_longest_streak_equals_current(client) -> None:
    """Test longest_streak equals current when at personal best."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create ongoing 7-day streak (no gaps)
    for i in range(7):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 201,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 201,
            "end_date": (base_date + timedelta(days=6, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Both should be 7
    assert data["current_streak"] == 7
    assert data["longest_streak"] == 7


def test_analytics_overview_longest_streak_ge_current(client) -> None:
    """Test longest_streak is always >= current_streak."""
    base_date = datetime(2025, 9, 20, 12, 0, 0, tzinfo=UTC)

    # Create 10-day streak
    for i in range(10):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "user_id": 202,
                "curriculum_id": 1,
            },
        )

    # Gap of 3 days

    # Create 4-day streak
    for i in range(4):
        client.post(
            "/api/v1/journal",
            json={
                "created_at": (base_date + timedelta(days=13 + i)).isoformat(),
                "user_id": 202,
                "curriculum_id": 1,
            },
        )

    response = client.get(
        "/api/v1/analytics/overview",
        params={
            "user_id": 202,
            "end_date": (base_date + timedelta(days=16, hours=23)).isoformat(),
        },
    )
    assert response.status_code == 200
    data = response.json()

    # Longest must be >= current
    assert data["longest_streak"] >= data["current_streak"]
    assert data["longest_streak"] == 10
    assert data["current_streak"] == 4


def test_analytics_overview_longest_streak_zero_for_no_entries(client) -> None:
    """Test longest streak is 0 when user has no entries."""
    response = client.get(
        "/api/v1/analytics/overview",
        params={"user_id": 99999},
    )
    assert response.status_code == 404


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
