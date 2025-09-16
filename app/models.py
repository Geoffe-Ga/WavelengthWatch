"""Database models defined using SQLModel with relationships."""

from datetime import datetime
from typing import Optional

from sqlalchemy import Column, DateTime
from sqlmodel import Field, Relationship, SQLModel


class Layer(SQLModel, table=True):
    """Represents an archetypal layer of the curriculum."""

    __tablename__ = "layer"

    id: Optional[int] = Field(default=None, primary_key=True)
    color: str
    title: str
    subtitle: str

    curriculum_items: list["Curriculum"] = Relationship(back_populates="layer")
    strategies: list["Strategy"] = Relationship(back_populates="layer")


class Phase(SQLModel, table=True):
    """Represents a progression phase."""

    __tablename__ = "phase"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str

    curriculum_items: list["Curriculum"] = Relationship(back_populates="phase")
    strategies: list["Strategy"] = Relationship(back_populates="phase")


class Curriculum(SQLModel, table=True):
    """Represents a curriculum item tying together layer, phase, and dosage."""

    __tablename__ = "curriculum"

    id: Optional[int] = Field(default=None, primary_key=True)
    stage_id: int = Field(foreign_key="layer.id")
    phase_id: int = Field(foreign_key="phase.id")
    dosage: str
    expression: str

    layer: Layer = Relationship(back_populates="curriculum_items")
    phase: Phase = Relationship(back_populates="curriculum_items")
    journal_entries: list["Journal"] = Relationship(
        back_populates="curriculum",
        sa_relationship_kwargs={
            "primaryjoin": "Curriculum.id == Journal.curriculum_id",
            "foreign_keys": "Journal.curriculum_id",
        },
    )
    secondary_journal_entries: list["Journal"] = Relationship(
        back_populates="secondary_curriculum",
        sa_relationship_kwargs={
            "primaryjoin": "Curriculum.id == Journal.secondary_curriculum_id",
            "foreign_keys": "Journal.secondary_curriculum_id",
        },
    )


class Strategy(SQLModel, table=True):
    """Represents a strategy associated with a specific layer and phase."""

    __tablename__ = "strategy"

    id: Optional[int] = Field(default=None, primary_key=True)
    strategy: str
    layer_id: int = Field(foreign_key="layer.id")
    phase_id: int = Field(foreign_key="phase.id")

    layer: Layer = Relationship(back_populates="strategies")
    phase: Phase = Relationship(back_populates="strategies")
    journal_entries: list["Journal"] = Relationship(back_populates="strategy")


class Journal(SQLModel, table=True):
    """Represents a journal entry submitted by a user."""

    __tablename__ = "journal"

    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(
        sa_column=Column(DateTime(timezone=True), nullable=False)
    )
    user_id: int
    curriculum_id: int = Field(foreign_key="curriculum.id")
    secondary_curriculum_id: Optional[int] = Field(
        default=None, foreign_key="curriculum.id"
    )
    strategy_id: Optional[int] = Field(default=None, foreign_key="strategy.id")

    curriculum: Curriculum = Relationship(
        back_populates="journal_entries",
        sa_relationship_kwargs={"foreign_keys": "Journal.curriculum_id"},
    )
    secondary_curriculum: Optional[Curriculum] = Relationship(
        back_populates="secondary_journal_entries",
        sa_relationship_kwargs={
            "foreign_keys": "Journal.secondary_curriculum_id",
        },
    )
    strategy: Optional[Strategy] = Relationship(back_populates="journal_entries")
