"""Database models and Pydantic schemas for journaling."""

from datetime import datetime

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


class SelfCareLog(SQLModel, table=True):
    """Record of a self-care strategy linked to a journal entry."""

    id: int | None = Field(default=None, primary_key=True)
    journal_id: int | None = Field(
        default=None, foreign_key="journalentry.id"
    )
    strategy: str
    timestamp: datetime

    journal: "JournalEntry" = Relationship(back_populates="self_care_logs")


class SelfCareLogCreate(SQLModel):
    """Pydantic schema for creating ``SelfCareLog`` records."""

    journal_id: int
    strategy: str
    timestamp: datetime


class JournalEntry(SQLModel, table=True):
    """Represents a journaling session."""

    id: int | None = Field(default=None, primary_key=True)
    timestamp: datetime
    initiated_by: str

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
    initiated_by: str


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
    "JournalEntryCreate",
    "EntryDetailCreate",
    "SelfCareLogCreate",
    "EntryDetailInput",
    "JournalEntryCreateWithDetails",
    "JournalEntryRead",
]


# Resolve forward references for Pydantic/SQLModel.
JournalEntry.model_rebuild()
EntryDetail.model_rebuild()
SelfCareLog.model_rebuild()
