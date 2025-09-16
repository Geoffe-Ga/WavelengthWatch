"""Pydantic schemas for request/response DTOs."""

from datetime import datetime

from sqlmodel import SQLModel

from backend.models import DosageEnum


# Layer schemas
class LayerBase(SQLModel):
    """Base Layer schema."""

    color: str
    title: str
    subtitle: str


class LayerCreate(LayerBase):
    """Schema for creating Layer records."""

    pass


class LayerUpdate(SQLModel):
    """Schema for updating Layer records."""

    color: str | None = None
    title: str | None = None
    subtitle: str | None = None


class LayerRead(LayerBase):
    """Schema for reading Layer records."""

    id: int


# Phase schemas
class PhaseBase(SQLModel):
    """Base Phase schema."""

    name: str


class PhaseCreate(PhaseBase):
    """Schema for creating Phase records."""

    pass


class PhaseUpdate(SQLModel):
    """Schema for updating Phase records."""

    name: str | None = None


class PhaseRead(PhaseBase):
    """Schema for reading Phase records."""

    id: int


# Curriculum schemas
class CurriculumBase(SQLModel):
    """Base Curriculum schema."""

    layer_id: int
    phase_id: int
    dosage: DosageEnum
    expression: str


class CurriculumCreate(CurriculumBase):
    """Schema for creating Curriculum records."""

    pass


class CurriculumUpdate(SQLModel):
    """Schema for updating Curriculum records."""

    layer_id: int | None = None
    phase_id: int | None = None
    dosage: DosageEnum | None = None
    expression: str | None = None


class CurriculumRead(CurriculumBase):
    """Schema for reading Curriculum records."""

    id: int


class CurriculumReadWithRelations(CurriculumRead):
    """Schema for reading Curriculum with related data."""

    layer: LayerRead | None = None
    phase: PhaseRead | None = None


# Strategy schemas
class StrategyBase(SQLModel):
    """Base Strategy schema."""

    strategy: str
    layer_id: int
    phase_id: int


class StrategyCreate(StrategyBase):
    """Schema for creating Strategy records."""

    pass


class StrategyUpdate(SQLModel):
    """Schema for updating Strategy records."""

    strategy: str | None = None
    layer_id: int | None = None
    phase_id: int | None = None


class StrategyRead(StrategyBase):
    """Schema for reading Strategy records."""

    id: int


class StrategyReadWithRelations(StrategyRead):
    """Schema for reading Strategy with related data."""

    layer: LayerRead | None = None
    phase: PhaseRead | None = None


# Journal schemas
class JournalBase(SQLModel):
    """Base Journal schema."""

    created_at: datetime
    user_id: int
    curriculum_id: int
    secondary_curriculum_id: int | None = None
    strategy_id: int | None = None


class JournalCreate(JournalBase):
    """Schema for creating Journal records."""

    pass


class JournalUpdate(SQLModel):
    """Schema for updating Journal records."""

    created_at: datetime | None = None
    user_id: int | None = None
    curriculum_id: int | None = None
    secondary_curriculum_id: int | None = None
    strategy_id: int | None = None


class JournalRead(JournalBase):
    """Schema for reading Journal records."""

    id: int


class JournalReadWithRelations(JournalRead):
    """Schema for reading Journal with related data."""

    curriculum: CurriculumRead | None = None
    secondary_curriculum: CurriculumRead | None = None
    strategy: StrategyRead | None = None
