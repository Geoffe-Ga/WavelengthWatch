from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Annotated, Any

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
) -> JournalEntry:
    """Create a journal entry with nested combo details."""
    entry = JournalEntry(
        timestamp=payload.timestamp,
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
    _ = entry.details  # load details before session closes
    return entry


@app.get("/journal", response_model=list[JournalEntryRead])
def list_journal(
    session: SessionDep,
    start: datetime | None = None,
    end: datetime | None = None,
) -> list[JournalEntry]:
    """Return journal entries optionally filtered by a date range."""
    statement = select(JournalEntry)
    if start is not None:
        statement = statement.where(JournalEntry.timestamp >= start)
    if end is not None:
        statement = statement.where(JournalEntry.timestamp <= end)
    result = session.exec(statement)
    entries = list(result)
    # Ensure details are loaded before the session closes
    for entry in entries:
        _ = entry.details  # trigger lazy load
    return entries
