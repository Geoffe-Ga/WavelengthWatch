from __future__ import annotations

import json
from collections import defaultdict, deque
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Annotated, Any

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from .db import get_session_dep
from .models import (
    EntryDetail,
    JournalEntry,
    JournalEntryCreateWithDetails,
    JournalEntryRead,
)

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


@app.get("/strategies")
def strategies() -> Any:
    # Returns the JSON list of self-care strategies.
    return _load_json("strategies.json")


@app.post("/journal", response_model=JournalEntryRead, status_code=201)
def create_journal(
    payload: JournalEntryCreateWithDetails,
    session: SessionDep,
    _rate_limit: None = Depends(rate_limit),
) -> JournalEntry:
    """Create a journal entry with nested combo details."""
    timestamp = payload.timestamp
    if timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=UTC)
    else:
        timestamp = timestamp.astimezone(UTC)
    timestamp = timestamp.replace(tzinfo=None)
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
        .order_by(JournalEntry.timestamp.desc())  # type: ignore[attr-defined]
    )
    if start is not None:
        if start.tzinfo is None:
            start = start.replace(tzinfo=UTC)
        else:
            start = start.astimezone(UTC)
        start = start.replace(tzinfo=None)
        statement = statement.where(JournalEntry.timestamp >= start)
    if end is not None:
        if end.tzinfo is None:
            end = end.replace(tzinfo=UTC)
        else:
            end = end.astimezone(UTC)
        end = end.replace(tzinfo=None)
        statement = statement.where(JournalEntry.timestamp <= end)
    result = session.exec(statement.offset(offset).limit(limit))
    return list(result)
