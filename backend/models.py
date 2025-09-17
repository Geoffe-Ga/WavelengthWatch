"""SQLModel table definitions for the WavelengthWatch backend."""

from datetime import datetime
from enum import Enum
from typing import List, Optional

from sqlalchemy import Column, DateTime, Enum as SAEnum
from sqlmodel import Field, Relationship, SQLModel


class Dosage(str, Enum):
    """Dosage categories for curriculum entries."""

    MEDICINAL = "Medicinal"
    TOXIC = "Toxic"


class Layer(SQLModel, table=True):
    """Reference table describing each spiral dynamics layer."""

    id: Optional[int] = Field(default=None, primary_key=True)
    color: str
    title: str
    subtitle: str

    curriculum_items: List["Curriculum"] = Relationship(back_populates="layer")
    strategies: List["Strategy"] = Relationship(back_populates="layer")


class Phase(SQLModel, table=True):
    """Reference table of user energy phases."""

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str

    curriculum_items: List["Curriculum"] = Relationship(back_populates="phase")
    strategies: List["Strategy"] = Relationship(back_populates="phase")


class Curriculum(SQLModel, table=True):
    """Curriculum entries that map layers to phases and expressions."""

    id: Optional[int] = Field(default=None, primary_key=True)
    layer_id: int = Field(foreign_key="layer.id", index=True)
    phase_id: int = Field(foreign_key="phase.id", index=True)
    dosage: Dosage = Field(sa_column=Column(SAEnum(Dosage, name="curriculum_dosage", native_enum=False)))
    expression: str

    layer: Optional[Layer] = Relationship(back_populates="curriculum_items")
    phase: Optional[Phase] = Relationship(back_populates="curriculum_items")
    journal_entries: List["Journal"] = Relationship(
        back_populates="curriculum",
        sa_relationship_kwargs={
            "primaryjoin": "Curriculum.id==Journal.curriculum_id",
        },
    )
    secondary_journal_entries: List["Journal"] = Relationship(
        back_populates="secondary_curriculum",
        sa_relationship_kwargs={
            "primaryjoin": "Curriculum.id==Journal.secondary_curriculum_id",
        },
    )


class Strategy(SQLModel, table=True):
    """Self-care strategies associated with specific layers and phases."""

    id: Optional[int] = Field(default=None, primary_key=True)
    strategy: str
    layer_id: int = Field(foreign_key="layer.id", index=True)
    phase_id: int = Field(foreign_key="phase.id", index=True)

    layer: Optional[Layer] = Relationship(back_populates="strategies")
    phase: Optional[Phase] = Relationship(back_populates="strategies")
    journal_entries: List["Journal"] = Relationship(
        back_populates="strategy",
        sa_relationship_kwargs={
            "primaryjoin": "Strategy.id==Journal.strategy_id",
        },
    )


class Journal(SQLModel, table=True):
    """User journal entries representing runtime activity."""

    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(sa_column=Column(DateTime(timezone=True), nullable=False))
    user_id: int = Field(index=True)
    curriculum_id: int = Field(foreign_key="curriculum.id", nullable=False, index=True)
    secondary_curriculum_id: Optional[int] = Field(
        default=None, foreign_key="curriculum.id", nullable=True, index=True
    )
    strategy_id: Optional[int] = Field(default=None, foreign_key="strategy.id", nullable=True, index=True)

    curriculum: Optional[Curriculum] = Relationship(
        back_populates="journal_entries",
        sa_relationship_kwargs={
            "primaryjoin": "Journal.curriculum_id==Curriculum.id",
            "foreign_keys": "Journal.curriculum_id",
        },
    )
    secondary_curriculum: Optional[Curriculum] = Relationship(
        back_populates="secondary_journal_entries",
        sa_relationship_kwargs={
            "primaryjoin": "Journal.secondary_curriculum_id==Curriculum.id",
            "foreign_keys": "Journal.secondary_curriculum_id",
        },
    )
    strategy: Optional[Strategy] = Relationship(
        back_populates="journal_entries",
        sa_relationship_kwargs={
            "primaryjoin": "Journal.strategy_id==Strategy.id",
            "foreign_keys": "Journal.strategy_id",
        },
    )


__all__ = ["Layer", "Phase", "Curriculum", "Strategy", "Journal", "Dosage"]
