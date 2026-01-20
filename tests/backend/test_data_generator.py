"""Test data generator for performance testing.

Generates realistic journal entries with distribution across layers, phases,
dosages, and strategies for load testing analytics endpoints.
"""

from datetime import UTC, datetime, timedelta
from random import choice, randint, random
from typing import Any

# Curriculum IDs by dosage (from database seeding)
MEDICINAL_IDS = list(range(1, 6))  # IDs 1-5 are medicinal
TOXIC_IDS = list(range(6, 11))  # IDs 6-10 are toxic

# Strategy IDs (from database seeding)
STRATEGY_IDS = list(range(1, 21))  # 20 strategies total

# Distribution weights for realistic data
MEDICINAL_WEIGHT = 0.65  # 65% medicinal entries (realistic growth trajectory)
SECONDARY_EMOTION_WEIGHT = 0.40  # 40% have secondary emotions
STRATEGY_USAGE_WEIGHT = 0.60  # 60% of entries use strategies


def generate_journal_entries(
    count: int,
    user_id: int = 1,
    start_date: datetime | None = None,
    days_span: int = 30,
) -> list[dict[str, Any]]:
    """Generate N journal entries with realistic distributions.

    Args:
        count: Number of entries to generate
        user_id: User ID for all entries (default: 1)
        start_date: Start date for entry range (default: 30 days ago)
        days_span: Number of days to distribute entries across (default: 30)

    Returns:
        List of journal entry dicts ready for POST to /api/v1/journal

    Example:
        >>> entries = generate_journal_entries(1000, user_id=123, days_span=90)
        >>> len(entries)
        1000
        >>> all(e["user_id"] == 123 for e in entries)
        True
    """
    if start_date is None:
        start_date = datetime.now(UTC) - timedelta(days=days_span)

    entries = []
    for i in range(count):
        # Distribute entries across time period
        offset_minutes = (i * days_span * 24 * 60) // count
        created_at = start_date + timedelta(minutes=offset_minutes)

        # Choose curriculum ID based on weighted distribution
        is_medicinal = random() < MEDICINAL_WEIGHT
        curriculum_id = choice(MEDICINAL_IDS if is_medicinal else TOXIC_IDS)

        # Add secondary emotion ~40% of the time
        secondary_curriculum_id = (
            choice(MEDICINAL_IDS + TOXIC_IDS)
            if random() < SECONDARY_EMOTION_WEIGHT
            else None
        )

        # Add strategy based on usage weight
        strategy_id = choice(STRATEGY_IDS) if random() < STRATEGY_USAGE_WEIGHT else None

        entry = {
            "created_at": created_at.isoformat(),
            "user_id": user_id,
            "curriculum_id": curriculum_id,
        }

        if secondary_curriculum_id:
            entry["secondary_curriculum_id"] = secondary_curriculum_id
        if strategy_id:
            entry["strategy_id"] = strategy_id

        entries.append(entry)

    return entries


def generate_distributed_entries(
    count: int,
    user_id: int = 1,
    start_date: datetime | None = None,
    days_span: int = 30,
) -> list[dict[str, Any]]:
    """Generate entries with time-of-day distribution (for temporal analytics).

    Creates entries clustered around common check-in times:
    - Morning: 7-9am (20%)
    - Midday: 12-2pm (30%)
    - Evening: 6-8pm (40%)
    - Night: 10pm-12am (10%)

    Args:
        count: Number of entries to generate
        user_id: User ID for all entries
        start_date: Start date for entry range (default: 30 days ago)
        days_span: Number of days to distribute entries across

    Returns:
        List of journal entry dicts with realistic time-of-day patterns
    """
    if start_date is None:
        start_date = datetime.now(UTC) - timedelta(days=days_span)

    # Define time-of-day clusters (hour ranges and weights)
    time_clusters = [
        (7, 9, 0.20),  # Morning: 20%
        (12, 14, 0.30),  # Midday: 30%
        (18, 20, 0.40),  # Evening: 40%
        (22, 24, 0.10),  # Night: 10%
    ]

    entries = []
    day_index = 0
    entries_today = 0
    target_entries_per_day = max(1, count // days_span)

    for _i in range(count):
        # Determine which day this entry belongs to
        if entries_today >= target_entries_per_day and day_index < days_span - 1:
            day_index += 1
            entries_today = 0

        base_date = start_date + timedelta(days=day_index)

        # Choose time cluster based on weights
        rand_val = random()
        cumulative = 0.0
        chosen_hour = 12  # Default to midday

        for start_hour, end_hour, weight in time_clusters:
            cumulative += weight
            if rand_val <= cumulative:
                chosen_hour = randint(start_hour, end_hour - 1)
                break

        # Add random minutes within the hour
        chosen_minute = randint(0, 59)

        created_at = base_date.replace(
            hour=chosen_hour % 24, minute=chosen_minute, second=0, microsecond=0
        )

        # Choose curriculum and strategy (same logic as generate_journal_entries)
        is_medicinal = random() < MEDICINAL_WEIGHT
        curriculum_id = choice(MEDICINAL_IDS if is_medicinal else TOXIC_IDS)

        secondary_curriculum_id = (
            choice(MEDICINAL_IDS + TOXIC_IDS)
            if random() < SECONDARY_EMOTION_WEIGHT
            else None
        )

        strategy_id = choice(STRATEGY_IDS) if random() < 0.60 else None

        entry = {
            "created_at": created_at.isoformat(),
            "user_id": user_id,
            "curriculum_id": curriculum_id,
        }

        if secondary_curriculum_id:
            entry["secondary_curriculum_id"] = secondary_curriculum_id
        if strategy_id:
            entry["strategy_id"] = strategy_id

        entries.append(entry)
        entries_today += 1

    return entries
