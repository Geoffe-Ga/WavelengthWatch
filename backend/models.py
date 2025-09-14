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


class JournalEntry(SQLModel, table=True):
    """Represents a journaling session."""

    id: int | None = Field(default=None, primary_key=True)
    timestamp: datetime
    initiated_by: str

    details: list[EntryDetail] = Relationship(
        back_populates="journal",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


class JournalEntryCreate(SQLModel):
    """Pydantic schema for creating ``JournalEntry`` records."""

    timestamp: datetime
    initiated_by: str


__all__ = [
    "JournalEntry",
    "EntryDetail",
    "JournalEntryCreate",
    "EntryDetailCreate",
]


# Resolve forward references for Pydantic/SQLModel.
JournalEntry.model_rebuild()
EntryDetail.model_rebuild()
