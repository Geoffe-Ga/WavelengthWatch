"""Pydantic/SQLModel schemas for request and response bodies."""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import ConfigDict, Field as PydanticField
from sqlmodel import SQLModel


class LayerBase(SQLModel):
    color: str = PydanticField(description="Display color of the layer")
    title: str = PydanticField(description="Primary layer title")
    subtitle: str = PydanticField(description="Supporting subtitle text")


class LayerCreate(LayerBase):
    """Payload for creating a new layer reference item."""


class LayerUpdate(SQLModel):
    color: Optional[str] = None
    title: Optional[str] = None
    subtitle: Optional[str] = None


class LayerRead(LayerBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class PhaseBase(SQLModel):
    name: str = PydanticField(description="Name of the phase")


class PhaseCreate(PhaseBase):
    pass


class PhaseUpdate(SQLModel):
    name: Optional[str] = None


class PhaseRead(PhaseBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class CurriculumBase(SQLModel):
    stage_id: int = PydanticField(description="Foreign key to Layer.id")
    phase_id: int = PydanticField(description="Foreign key to Phase.id")
    dosage: str = PydanticField(
        description="Dosage descriptor. Known values include 'Medicinal' and 'Toxic'."
    )
    expression: str = PydanticField(description="Curriculum expression label")


class CurriculumCreate(CurriculumBase):
    pass


class CurriculumUpdate(SQLModel):
    stage_id: Optional[int] = None
    phase_id: Optional[int] = None
    dosage: Optional[str] = None
    expression: Optional[str] = None


class CurriculumRead(CurriculumBase):
    id: int
    layer: Optional[LayerRead] = None
    phase: Optional[PhaseRead] = None

    model_config = ConfigDict(from_attributes=True)


class StrategyBase(SQLModel):
    strategy: str = PydanticField(description="Strategy description")
    layer_id: int = PydanticField(description="Foreign key to Layer.id")
    phase_id: int = PydanticField(description="Foreign key to Phase.id")


class StrategyCreate(StrategyBase):
    pass


class StrategyUpdate(SQLModel):
    strategy: Optional[str] = None
    layer_id: Optional[int] = None
    phase_id: Optional[int] = None


class StrategyRead(StrategyBase):
    id: int
    layer: Optional[LayerRead] = None
    phase: Optional[PhaseRead] = None

    model_config = ConfigDict(from_attributes=True)


class JournalBase(SQLModel):
    created_at: datetime = PydanticField(description="Timestamp when the entry was recorded")
    user_id: int = PydanticField(description="Identifier for the user submitting the entry")
    curriculum_id: int = PydanticField(description="Primary curriculum reference")
    secondary_curriculum_id: Optional[int] = PydanticField(
        default=None, description="Optional secondary curriculum reference"
    )
    strategy_id: Optional[int] = PydanticField(
        default=None, description="Optional strategy reference"
    )


class JournalCreate(JournalBase):
    pass


class JournalUpdate(SQLModel):
    created_at: Optional[datetime] = None
    user_id: Optional[int] = None
    curriculum_id: Optional[int] = None
    secondary_curriculum_id: Optional[int] = None
    strategy_id: Optional[int] = None


class JournalRead(JournalBase):
    id: int
    curriculum: Optional[CurriculumRead] = None
    secondary_curriculum: Optional[CurriculumRead] = None
    strategy: Optional[StrategyRead] = None

    model_config = ConfigDict(from_attributes=True)
