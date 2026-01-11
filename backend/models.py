"""SQLModel table definitions for the WavelengthWatch backend."""

from datetime import datetime
from enum import Enum

from sqlalchemy import Column, DateTime
from sqlalchemy import Enum as SAEnum
from sqlalchemy import Index
from sqlalchemy.orm import Mapped
from sqlmodel import Field, Relationship, SQLModel


class Dosage(str, Enum):
    """Dosage categories for curriculum entries."""

    MEDICINAL = "Medicinal"
    TOXIC = "Toxic"


class InitiatedBy(str, Enum):
    """Source of journal entry creation."""

    SELF = "self"
    SCHEDULED = "scheduled"


class Layer(SQLModel, table=True):
    """Reference table describing each spiral dynamics layer."""

    id: int | None = Field(default=None, primary_key=True)
    color: str
    title: str
    subtitle: str

    curriculum_items: Mapped[list["Curriculum"]] = Relationship(back_populates="layer")
    strategies: Mapped[list["Strategy"]] = Relationship(
        back_populates="layer",
        sa_relationship_kwargs={
            "primaryjoin": "Layer.id==Strategy.layer_id",
            "foreign_keys": "Strategy.layer_id",
        },
    )
    color_strategies: Mapped[list["Strategy"]] = Relationship(
        back_populates="color_layer",
        sa_relationship_kwargs={
            "primaryjoin": "Layer.id==Strategy.color_layer_id",
            "foreign_keys": "Strategy.color_layer_id",
        },
    )


class Phase(SQLModel, table=True):
    """Reference table of user energy phases."""

    id: int | None = Field(default=None, primary_key=True)
    name: str

    curriculum_items: Mapped[list["Curriculum"]] = Relationship(back_populates="phase")
    strategies: Mapped[list["Strategy"]] = Relationship(back_populates="phase")


class Curriculum(SQLModel, table=True):
    """Curriculum entries that map layers to phases and expressions."""

    id: int | None = Field(default=None, primary_key=True)
    layer_id: int = Field(foreign_key="layer.id", index=True)
    phase_id: int = Field(foreign_key="phase.id", index=True)
    dosage: Dosage = Field(
        sa_column=Column(SAEnum(Dosage, name="curriculum_dosage", native_enum=False))
    )
    expression: str

    layer: Mapped[Layer | None] = Relationship(back_populates="curriculum_items")
    phase: Mapped[Phase | None] = Relationship(back_populates="curriculum_items")
    journal_entries: Mapped[list["Journal"]] = Relationship(
        back_populates="curriculum",
        sa_relationship_kwargs={
            "primaryjoin": "Curriculum.id==Journal.curriculum_id",
        },
    )
    secondary_journal_entries: Mapped[list["Journal"]] = Relationship(
        back_populates="secondary_curriculum",
        sa_relationship_kwargs={
            "primaryjoin": "Curriculum.id==Journal.secondary_curriculum_id",
        },
    )


class Strategy(SQLModel, table=True):
    """Self-care strategies associated with specific layers and phases."""

    id: int | None = Field(default=None, primary_key=True)
    strategy: str
    layer_id: int = Field(foreign_key="layer.id", index=True)
    color_layer_id: int = Field(foreign_key="layer.id", index=True)
    phase_id: int = Field(foreign_key="phase.id", index=True)

    layer: Mapped[Layer | None] = Relationship(
        back_populates="strategies",
        sa_relationship_kwargs={
            "primaryjoin": "Strategy.layer_id==Layer.id",
            "foreign_keys": "Strategy.layer_id",
        },
    )
    color_layer: Mapped[Layer | None] = Relationship(
        back_populates="color_strategies",
        sa_relationship_kwargs={
            "primaryjoin": "Strategy.color_layer_id==Layer.id",
            "foreign_keys": "Strategy.color_layer_id",
        },
    )
    phase: Mapped[Phase | None] = Relationship(back_populates="strategies")
    journal_entries: Mapped[list["Journal"]] = Relationship(
        back_populates="strategy",
        sa_relationship_kwargs={
            "primaryjoin": "Strategy.id==Journal.strategy_id",
        },
    )


class Journal(SQLModel, table=True):
    """User journal entries representing runtime activity.

    Performance note: The composite index on (user_id, created_at) optimizes
    analytics queries that filter by user and date range.
    """

    id: int | None = Field(default=None, primary_key=True)
    # Index on created_at for efficient date range queries in analytics
    created_at: datetime = Field(
        sa_column=Column(DateTime(timezone=True), nullable=False, index=True)
    )
    user_id: int = Field(index=True)
    curriculum_id: int = Field(foreign_key="curriculum.id", nullable=False, index=True)
    secondary_curriculum_id: int | None = Field(
        default=None, foreign_key="curriculum.id", nullable=True, index=True
    )
    strategy_id: int | None = Field(
        default=None, foreign_key="strategy.id", nullable=True, index=True
    )
    initiated_by: InitiatedBy = Field(
        default=InitiatedBy.SELF,
        sa_column=Column(
            SAEnum(InitiatedBy, name="journal_initiated_by", native_enum=False)
        ),
    )

    curriculum: Mapped[Curriculum | None] = Relationship(
        back_populates="journal_entries",
        sa_relationship_kwargs={
            "primaryjoin": "Journal.curriculum_id==Curriculum.id",
            "foreign_keys": "Journal.curriculum_id",
        },
    )
    secondary_curriculum: Mapped[Curriculum | None] = Relationship(
        back_populates="secondary_journal_entries",
        sa_relationship_kwargs={
            "primaryjoin": "Journal.secondary_curriculum_id==Curriculum.id",
            "foreign_keys": "Journal.secondary_curriculum_id",
        },
    )
    strategy: Mapped[Strategy | None] = Relationship(
        back_populates="journal_entries",
        sa_relationship_kwargs={
            "primaryjoin": "Journal.strategy_id==Strategy.id",
            "foreign_keys": "Journal.strategy_id",
        },
    )

    # Composite index for analytics queries: user_id + created_at (DESC)
    # This covers the common query pattern: WHERE user_id = ? AND created_at >= ?
    __table_args__ = (Index("ix_journal_user_created", "user_id", "created_at"),)


__all__ = [
    "Layer",
    "Phase",
    "Curriculum",
    "Strategy",
    "Journal",
    "Dosage",
    "InitiatedBy",
]
