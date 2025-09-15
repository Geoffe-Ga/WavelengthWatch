"""Database models and Pydantic schemas for journaling."""

from datetime import datetime

from sqlalchemy import Index
from sqlmodel import Field, Relationship, SQLModel


class EntryDetail(SQLModel, table=True):
    """Detail row tied to a :class:`JournalEntry`."""

    journal_id: int | None = Field(
        default=None, foreign_key="journalentry.id", primary_key=True
    )
    stage: int
    phase: int
    dosage: float
    position: int = Field(primary_key=True)

    journal: "JournalEntry" = Relationship(back_populates="details")


class EntryDetailCreate(SQLModel):
    """Pydantic schema for creating ``EntryDetail`` records."""

    journal_id: int
    stage: int
    phase: int
    dosage: float
    position: int


class EntryDetailInput(SQLModel):
    """Input schema for nested detail creation via the API."""

    stage: int
    phase: int
    dosage: float
    position: int


class SelfCareStrategy(SQLModel, table=True):
    """Catalog of available self-care strategies."""

    id: int | None = Field(default=None, primary_key=True)
    color: str = Field(max_length=100)
    strategy: str = Field(max_length=100)

    logs: list["SelfCareLog"] = Relationship(back_populates="strategy")


class SelfCareStrategyCreate(SQLModel):
    """Schema for creating ``SelfCareStrategy`` records."""

    color: str = Field(max_length=100)
    strategy: str = Field(max_length=100)


class SelfCareStrategyRead(SelfCareStrategyCreate):
    """Schema for reading ``SelfCareStrategy`` records."""

    id: int


class SelfCareLog(SQLModel, table=True):
    """Record of a self-care strategy linked to a journal entry."""

    id: int | None = Field(default=None, primary_key=True)
    journal_id: int | None = Field(
        default=None, foreign_key="journalentry.id"
    )
    strategy_id: int | None = Field(
        default=None, foreign_key="selfcarestrategy.id"
    )
    timestamp: datetime

    journal: "JournalEntry" = Relationship(back_populates="self_care_logs")
    strategy: SelfCareStrategy | None = Relationship(back_populates="logs")

    __table_args__ = (
        Index("ix_selfcarelog_journal_timestamp", "journal_id", "timestamp"),
    )


class SelfCareLogCreate(SQLModel):
    """Pydantic schema for creating ``SelfCareLog`` records."""

    journal_id: int
    strategy_id: int
    timestamp: datetime


class SelfCareLogRead(SelfCareLogCreate):
    """Schema for reading ``SelfCareLog`` records."""

    id: int


class JournalEntry(SQLModel, table=True):
    """Represents a journaling session."""

    id: int | None = Field(default=None, primary_key=True)
    timestamp: datetime
    initiated_by: str = Field(max_length=100)

    details: list[EntryDetail] = Relationship(
        back_populates="journal",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )
    self_care_logs: list[SelfCareLog] = Relationship(
        back_populates="journal",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


class JournalEntryCreate(SQLModel):
    """Pydantic schema for creating ``JournalEntry`` records."""

    timestamp: datetime
    initiated_by: str = Field(max_length=100)


class JournalEntryCreateWithDetails(JournalEntryCreate):
    """Schema for creating entries with nested detail records."""

    details: list[EntryDetailInput]


class JournalEntryRead(JournalEntryCreate):
    """Schema for reading ``JournalEntry`` records with details."""

    id: int
    details: list[EntryDetail] = []


__all__ = [
    "JournalEntry",
    "EntryDetail",
    "SelfCareLog",
    "SelfCareStrategy",
    "JournalEntryCreate",
    "EntryDetailCreate",
    "SelfCareLogCreate",
    "SelfCareLogRead",
    "SelfCareStrategyCreate",
    "SelfCareStrategyRead",
    "EntryDetailInput",
    "JournalEntryCreateWithDetails",
    "JournalEntryRead",
]


# Resolve forward references for Pydantic/SQLModel.
JournalEntry.model_rebuild()
EntryDetail.model_rebuild()
SelfCareLog.model_rebuild()
SelfCareStrategy.model_rebuild()
