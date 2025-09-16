"""SQLModel table definitions for WavelengthWatch."""

from datetime import datetime
from enum import Enum

from sqlmodel import Field, Relationship, SQLModel


class DosageEnum(str, Enum):
    """Dosage type for curriculum entries."""

    MEDICINAL = "Medicinal"
    TOXIC = "Toxic"


class Layer(SQLModel, table=True):
    """Layer/Stage reference data."""

    id: int = Field(primary_key=True)
    color: str
    title: str
    subtitle: str

    # Relationships
    curriculum_items: list["Curriculum"] = Relationship(
        back_populates="layer"
    )
    strategies: list["Strategy"] = Relationship(back_populates="layer")


class Phase(SQLModel, table=True):
    """Phase reference data."""

    id: int = Field(primary_key=True)
    name: str

    # Relationships
    curriculum_items: list["Curriculum"] = Relationship(
        back_populates="phase"
    )
    strategies: list["Strategy"] = Relationship(back_populates="phase")


class Curriculum(SQLModel, table=True):
    """Curriculum reference data with layer/phase combinations."""

    id: int = Field(primary_key=True)
    layer_id: int = Field(foreign_key="layer.id")
    phase_id: int = Field(foreign_key="phase.id")
    dosage: DosageEnum
    expression: str

    # Relationships
    layer: Layer = Relationship(back_populates="curriculum_items")
    phase: Phase = Relationship(back_populates="curriculum_items")
    journal_entries: list["Journal"] = Relationship(
        back_populates="curriculum",
        sa_relationship_kwargs={"foreign_keys": "Journal.curriculum_id"},
    )
    secondary_journal_entries: list["Journal"] = Relationship(
        back_populates="secondary_curriculum",
        sa_relationship_kwargs={
            "foreign_keys": "Journal.secondary_curriculum_id"
        },
    )


class Strategy(SQLModel, table=True):
    """Self-care strategy reference data."""

    id: int = Field(primary_key=True)
    strategy: str
    layer_id: int = Field(foreign_key="layer.id")
    phase_id: int = Field(foreign_key="phase.id")

    # Relationships
    layer: Layer = Relationship(back_populates="strategies")
    phase: Phase = Relationship(back_populates="strategies")
    journal_entries: list["Journal"] = Relationship(back_populates="strategy")


class Journal(SQLModel, table=True):
    """Journal entry tracking user interactions."""

    id: int = Field(primary_key=True)
    created_at: datetime
    user_id: int  # No users table in current scope
    curriculum_id: int = Field(foreign_key="curriculum.id")
    secondary_curriculum_id: int | None = Field(
        default=None, foreign_key="curriculum.id"
    )
    strategy_id: int | None = Field(default=None, foreign_key="strategy.id")

    # Relationships
    curriculum: Curriculum = Relationship(
        back_populates="journal_entries",
        sa_relationship_kwargs={"foreign_keys": "Journal.curriculum_id"},
    )
    secondary_curriculum: Curriculum | None = Relationship(
        back_populates="secondary_journal_entries",
        sa_relationship_kwargs={
            "foreign_keys": "Journal.secondary_curriculum_id"
        },
    )
    strategy: Strategy | None = Relationship(back_populates="journal_entries")
