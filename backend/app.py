from __future__ import annotations

import json
from collections import defaultdict, deque
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Annotated, Any, cast

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import selectinload
from sqlalchemy.sql import ColumnElement
from sqlmodel import Session, select

from .db import get_session_dep
from .models import (
    EntryDetail,
    JournalEntry,
    JournalEntryCreateWithDetails,
    JournalEntryRead,
    SelfCareLog,
    SelfCareLogCreate,
    SelfCareLogRead,
    SelfCareStrategy,
    SelfCareStrategyCreate,
    SelfCareStrategyRead,
)
from .utils import to_utc_naive

SessionDep = Annotated[Session, Depends(get_session_dep)]

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

# Simple in-memory rate limiting: allow `RATE_LIMIT` requests per `RATE_PERIOD`
RATE_LIMIT = 100
RATE_PERIOD = timedelta(minutes=1)
_request_times: dict[str, deque[datetime]] = defaultdict(deque)


def rate_limit(request: Request) -> None:
    """Naive IP-based rate limiter."""
    now = datetime.now(UTC)
    ip = request.client.host if request.client else "unknown"
    times = _request_times[ip]
    while times and now - times[0] > RATE_PERIOD:
        times.popleft()
    if len(times) >= RATE_LIMIT:
        raise HTTPException(status_code=429, detail="Too many requests")
    times.append(now)


def _load_json(filename: str) -> Any:
    path = DATA_DIR / filename
    if not path.exists():
        return [] if filename.endswith(".json") else None
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


app = FastAPI(title="WavelengthWatch Backend", version="0.1.0")

# CORS: allow local dev + simulator to fetch JSON
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/curriculum")
def curriculum() -> Any:
    # Returns the JSON list describing stages/phases and medicinal/toxic flags.
    return _load_json("curriculum.json")


@app.get(
    "/strategies",
    response_model=list[SelfCareStrategyRead]
    | dict[str, list[dict[str, str]]],
)
def list_strategies(
    session: SessionDep, raw: bool = False
) -> list[SelfCareStrategy] | dict[str, list[dict[str, str]]]:
    """Return all available self-care strategies.

    Setting ``raw`` to ``True`` returns the legacy JSON structure used by the
    original watchOS client. This maintains backward compatibility while the
    frontend transitions to the structured database-backed format.
    """
    if raw:
        return _load_json("strategies.json")
    result = session.exec(select(SelfCareStrategy))
    return list(result)


@app.post("/strategies", response_model=SelfCareStrategyRead, status_code=201)
def create_strategy(
    payload: SelfCareStrategyCreate,
    session: SessionDep,
    _rate_limit: None = Depends(rate_limit),
) -> SelfCareStrategy:
    """Add a new self-care strategy to the catalog."""
    strategy = SelfCareStrategy(
        color=payload.color, strategy=payload.strategy
    )
    session.add(strategy)
    session.commit()
    session.refresh(strategy)
    return strategy


@app.post("/self-care", response_model=SelfCareLogRead, status_code=201)
def create_self_care(
    payload: SelfCareLogCreate,
    session: SessionDep,
    _rate_limit: None = Depends(rate_limit),
) -> SelfCareLog:
    """Create a self-care log linked to a journal entry."""
    journal = session.get(JournalEntry, payload.journal_id)
    if journal is None:
        raise HTTPException(status_code=404, detail="Journal entry not found")
    timestamp = to_utc_naive(payload.timestamp)
    strategy = session.get(SelfCareStrategy, payload.strategy_id)
    if strategy is None:
        raise HTTPException(status_code=404, detail="Strategy not found")

    log = SelfCareLog(
        journal_id=payload.journal_id,
        strategy_id=payload.strategy_id,
        timestamp=timestamp,
    )
    session.add(log)
    session.commit()
    session.refresh(log)
    return log


@app.get("/self-care", response_model=list[SelfCareLogRead])
def list_self_care(
    session: SessionDep,
    journal_id: int | None = None,
    start: datetime | None = None,
    end: datetime | None = None,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    _rate_limit: None = Depends(rate_limit),
) -> list[SelfCareLog]:
    """Return self-care logs filtered by journal or date range."""
    statement = select(SelfCareLog).order_by(
        cast(ColumnElement, SelfCareLog.timestamp).desc()
    )
    if journal_id is not None:
        statement = statement.where(SelfCareLog.journal_id == journal_id)
    if start is not None:
        start = to_utc_naive(start)
        statement = statement.where(SelfCareLog.timestamp >= start)
    if end is not None:
        end = to_utc_naive(end)
        statement = statement.where(SelfCareLog.timestamp <= end)
    result = session.exec(statement.offset(offset).limit(limit))
    return list(result)


@app.post("/journal", response_model=JournalEntryRead, status_code=201)
def create_journal(
    payload: JournalEntryCreateWithDetails,
    session: SessionDep,
    _rate_limit: None = Depends(rate_limit),
) -> JournalEntry:
    """Create a journal entry with nested combo details."""
    timestamp = to_utc_naive(payload.timestamp)
    entry = JournalEntry(
        timestamp=timestamp,
        initiated_by=payload.initiated_by,
    )
    for detail in payload.details:
        entry.details.append(
            EntryDetail(
                stage=detail.stage,
                phase=detail.phase,
                dosage=detail.dosage,
                position=detail.position,
            )
        )
    session.add(entry)
    session.commit()
    session.refresh(entry)
    _: list[EntryDetail] = entry.details  # load details before session closes
    return entry


@app.get("/journal", response_model=list[JournalEntryRead])
def list_journal(
    session: SessionDep,
    start: datetime | None = None,
    end: datetime | None = None,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
) -> list[JournalEntry]:
    """Return journal entries optionally filtered by a date range."""
    statement = (
        select(JournalEntry)
        .options(selectinload(JournalEntry.details))  # type: ignore[arg-type]
        .order_by(cast(ColumnElement, JournalEntry.timestamp).desc())
    )
    if start is not None:
        start = to_utc_naive(start)
        statement = statement.where(JournalEntry.timestamp >= start)
    if end is not None:
        end = to_utc_naive(end)
        statement = statement.where(JournalEntry.timestamp <= end)
    result = session.exec(statement.offset(offset).limit(limit))
    return list(result)
