"""Analytics endpoints."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Annotated, cast

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.sql import desc
from sqlalchemy.sql.elements import ColumnElement
from sqlmodel import Session, select
from sqlmodel.sql.expression import SelectOfScalar

from ..database import get_session
from ..models import Curriculum, Dosage, Journal
from ..schemas import AnalyticsOverview

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/analytics", tags=["analytics"])


def _calculate_streak(entries: list[datetime], end_date: datetime) -> int:
    """Calculate current streak of consecutive days with entries.

    Args:
        entries: List of entry timestamps, should be sorted desc
        end_date: The reference end date for streak calculation

    Returns:
        Number of consecutive days with at least one entry
    """
    if not entries:
        return 0

    # Extract unique dates
    dates = sorted({entry.date() for entry in entries}, reverse=True)

    # Start from the most recent date
    end_date_only = end_date.date()

    # If the most recent entry is not today or yesterday, streak is 0
    if dates[0] < end_date_only - timedelta(days=1):
        return 0

    # Count consecutive days
    streak = 0
    current_date = dates[0]

    for date in dates:
        # If this date is the expected date, increment streak
        if date == current_date:
            streak += 1
            current_date -= timedelta(days=1)
        elif date < current_date:
            # There's a gap
            break

    return streak


def _calculate_longest_streak(entries: list[datetime]) -> int:
    """Calculate the longest streak of consecutive days with entries.

    Args:
        entries: List of entry timestamps

    Returns:
        Longest consecutive day count in the history
    """
    if not entries:
        return 0

    # Extract unique dates sorted chronologically
    dates = sorted({entry.date() for entry in entries})

    if not dates:
        return 0

    longest = 1
    current = 1

    for i in range(1, len(dates)):
        if dates[i] - dates[i - 1] == timedelta(days=1):
            current += 1
            longest = max(longest, current)
        else:
            current = 1

    return longest


def _calculate_medicinal_ratio(
    session: Session, user_id: int, start_date: datetime, end_date: datetime
) -> float:
    """Calculate percentage of medicinal entries."""
    statement = (
        select(Curriculum.dosage, func.count())
        .select_from(Journal)
        .join(
            Curriculum,
            cast(ColumnElement[bool], Journal.curriculum_id == Curriculum.id),
        )
        .where(
            cast(ColumnElement[bool], Journal.user_id == user_id),
            cast(ColumnElement[bool], Journal.created_at >= start_date),
            cast(ColumnElement[bool], Journal.created_at <= end_date),
        )
        .group_by(Curriculum.dosage)
    )

    results = session.exec(statement).all()
    if not results:
        return 0.0

    total = sum(count for _, count in results)
    medicinal = sum(count for dosage, count in results if dosage == Dosage.MEDICINAL)

    return (medicinal / total) * 100 if total > 0 else 0.0


def _calculate_medicinal_trend(
    session: Session, user_id: int, start_date: datetime, end_date: datetime
) -> float:
    """Calculate change in medicinal ratio from previous period.

    Args:
        session: Database session
        user_id: User ID
        start_date: Start of current period
        end_date: End of current period

    Returns:
        Percentage point change in medicinal ratio
    """
    # Calculate duration of current period
    duration = end_date - start_date

    # Previous period: same duration before start_date
    prev_end_date = start_date
    prev_start_date = start_date - duration

    # Get ratios for both periods
    current_ratio = _calculate_medicinal_ratio(session, user_id, start_date, end_date)

    prev_ratio = _calculate_medicinal_ratio(
        session, user_id, prev_start_date, prev_end_date
    )

    # Return the difference
    return current_ratio - prev_ratio


def _get_dominant_layer_and_phase(
    session: Session, user_id: int, end_date: datetime
) -> tuple[int | None, int | None]:
    """Get most frequent layer and phase from last 7 days.

    Args:
        session: Database session
        user_id: User ID
        end_date: Reference date for 7-day window

    Returns:
        Tuple of (dominant_layer_id, dominant_phase_id)
    """
    seven_days_ago = end_date - timedelta(days=7)

    # Get dominant layer
    count_col = func.count().label("cnt")
    layer_stmt = (
        select(Curriculum.layer_id, count_col)
        .select_from(Journal)
        .join(
            Curriculum,
            cast(ColumnElement[bool], Journal.curriculum_id == Curriculum.id),
        )
        .where(
            cast(ColumnElement[bool], Journal.user_id == user_id),
            cast(ColumnElement[bool], Journal.created_at >= seven_days_ago),
            cast(ColumnElement[bool], Journal.created_at <= end_date),
        )
        .group_by(cast(ColumnElement[int], Curriculum.layer_id))
        .order_by(desc(count_col))
        .limit(1)
    )

    layer_result = session.exec(layer_stmt).first()
    dominant_layer = layer_result[0] if layer_result else None

    # Get dominant phase
    count_col = func.count().label("cnt")
    phase_stmt = (
        select(Curriculum.phase_id, count_col)
        .select_from(Journal)
        .join(
            Curriculum,
            cast(ColumnElement[bool], Journal.curriculum_id == Curriculum.id),
        )
        .where(
            cast(ColumnElement[bool], Journal.user_id == user_id),
            cast(ColumnElement[bool], Journal.created_at >= seven_days_ago),
            cast(ColumnElement[bool], Journal.created_at <= end_date),
        )
        .group_by(cast(ColumnElement[int], Curriculum.phase_id))
        .order_by(desc(count_col))
        .limit(1)
    )

    phase_result = session.exec(phase_stmt).first()
    dominant_phase = phase_result[0] if phase_result else None

    return dominant_layer, dominant_phase


@router.get("/overview", response_model=AnalyticsOverview)
def get_analytics_overview(
    *,
    session: SessionDep,
    user_id: Annotated[int, Query()],
    start_date: Annotated[datetime | None, Query()] = None,
    end_date: Annotated[datetime | None, Query()] = None,
) -> AnalyticsOverview:
    """Get analytics overview for a user.

    Args:
        session: Database session
        user_id: User ID to fetch analytics for
        start_date: Start date for analytics (defaults to 30 days ago)
        end_date: End date for analytics (defaults to now)

    Returns:
        Analytics overview with all metrics

    Raises:
        HTTPException: 404 if user has no journal entries
    """
    # Set defaults
    if end_date is None:
        end_date = datetime.now(UTC)
    if start_date is None:
        start_date = end_date - timedelta(days=30)

    # Get all journal entries for the user in the date range
    created_at = cast(ColumnElement[datetime], Journal.created_at)
    statement: SelectOfScalar[Journal] = (
        select(Journal)
        .where(
            cast(ColumnElement[bool], Journal.user_id == user_id),
            cast(ColumnElement[bool], Journal.created_at >= start_date),
            cast(ColumnElement[bool], Journal.created_at <= end_date),
        )
        .order_by(desc(created_at))
    )

    result = session.exec(statement)
    entries = result.all()

    if not entries:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No journal entries found for user",
        )

    # Total entries
    total_entries = len(entries)

    # Last check-in
    last_check_in = entries[0].created_at

    # Current streak
    entry_timestamps = [entry.created_at for entry in entries]
    current_streak = _calculate_streak(entry_timestamps, end_date)

    # Calculate longest streak across all history
    longest_streak = _calculate_longest_streak(entry_timestamps)

    # Average frequency (entries per day)
    days_in_period = (end_date - start_date).days + 1
    avg_frequency = total_entries / days_in_period if days_in_period > 0 else 0.0

    # Medicinal ratio
    medicinal_ratio = _calculate_medicinal_ratio(session, user_id, start_date, end_date)

    # Medicinal trend
    medicinal_trend = _calculate_medicinal_trend(session, user_id, start_date, end_date)

    # Dominant layer and phase (last 7 days)
    dominant_layer_id, dominant_phase_id = _get_dominant_layer_and_phase(
        session, user_id, end_date
    )

    # Unique emotions
    unique_emotions_stmt = select(
        func.count(func.distinct(Journal.curriculum_id))
    ).where(
        cast(ColumnElement[bool], Journal.user_id == user_id),
        cast(ColumnElement[bool], Journal.created_at >= start_date),
        cast(ColumnElement[bool], Journal.created_at <= end_date),
    )
    unique_emotions = session.exec(unique_emotions_stmt).one()

    # Strategies used (excluding null)
    strategy_id_col = cast(ColumnElement[int | None], Journal.strategy_id)
    strategies_used_stmt = select(func.count(func.distinct(Journal.strategy_id))).where(
        cast(ColumnElement[bool], Journal.user_id == user_id),
        cast(ColumnElement[bool], Journal.created_at >= start_date),
        cast(ColumnElement[bool], Journal.created_at <= end_date),
        strategy_id_col.is_not(None),
    )
    strategies_used = session.exec(strategies_used_stmt).one()

    # Secondary emotions percentage
    secondary_id_col = cast(ColumnElement[int | None], Journal.secondary_curriculum_id)
    total_entries_with_secondary_stmt = (
        select(func.count())
        .select_from(Journal)
        .where(
            cast(ColumnElement[bool], Journal.user_id == user_id),
            cast(ColumnElement[bool], Journal.created_at >= start_date),
            cast(ColumnElement[bool], Journal.created_at <= end_date),
            secondary_id_col.is_not(None),
        )
    )
    entries_with_secondary = session.exec(total_entries_with_secondary_stmt).one()
    secondary_emotions_pct = (
        (entries_with_secondary / total_entries) * 100 if total_entries > 0 else 0.0
    )

    return AnalyticsOverview(
        total_entries=total_entries,
        current_streak=current_streak,
        longest_streak=longest_streak,
        avg_frequency=avg_frequency,
        last_check_in=last_check_in,
        medicinal_ratio=medicinal_ratio,
        medicinal_trend=medicinal_trend,
        dominant_layer_id=dominant_layer_id,
        dominant_phase_id=dominant_phase_id,
        unique_emotions=unique_emotions,
        strategies_used=strategies_used,
        secondary_emotions_pct=secondary_emotions_pct,
    )
