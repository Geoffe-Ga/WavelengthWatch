"""Shared test fixtures for backend tests."""

import os
import tempfile
from datetime import datetime

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine

from backend.database import get_session_dep
from backend.main import app
from backend.models import (
    Curriculum,
    DosageEnum,
    Journal,
    Layer,
    Phase,
    Strategy,
)


@pytest.fixture(scope="function")
def test_engine():
    """Create a test database engine using SQLite in-memory."""
    # Use in-memory SQLite for tests
    test_db = tempfile.NamedTemporaryFile(delete=False)
    test_db.close()

    database_url = f"sqlite:///{test_db.name}"
    engine = create_engine(database_url, echo=False)

    # Create all tables
    SQLModel.metadata.create_all(engine)

    yield engine

    # Cleanup
    os.unlink(test_db.name)


@pytest.fixture(scope="function")
def test_session(test_engine):
    """Create a test database session."""
    with Session(test_engine) as session:
        yield session


@pytest.fixture(scope="function")
def client(test_session):
    """Create a test client with dependency override."""

    def get_test_session():
        yield test_session

    app.dependency_overrides[get_session_dep] = get_test_session

    with TestClient(app) as test_client:
        yield test_client

    # Clean up dependency override
    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def sample_layer(test_session):
    """Create a sample layer for testing."""
    layer = Layer(id=1, color="Beige", title="INHABIT", subtitle="(Do)")
    test_session.add(layer)
    test_session.commit()
    test_session.refresh(layer)
    return layer


@pytest.fixture(scope="function")
def sample_phase(test_session):
    """Create a sample phase for testing."""
    phase = Phase(id=1, name="Rising")
    test_session.add(phase)
    test_session.commit()
    test_session.refresh(phase)
    return phase


@pytest.fixture(scope="function")
def sample_curriculum(test_session, sample_layer, sample_phase):
    """Create a sample curriculum for testing."""
    curriculum = Curriculum(
        id=1,
        layer_id=sample_layer.id,
        phase_id=sample_phase.id,
        dosage=DosageEnum.MEDICINAL,
        expression="Commitment",
    )
    test_session.add(curriculum)
    test_session.commit()
    test_session.refresh(curriculum)
    return curriculum


@pytest.fixture(scope="function")
def sample_strategy(test_session, sample_layer, sample_phase):
    """Create a sample strategy for testing."""
    strategy = Strategy(
        id=1,
        strategy="Cold Shower",
        layer_id=sample_layer.id,
        phase_id=sample_phase.id,
    )
    test_session.add(strategy)
    test_session.commit()
    test_session.refresh(strategy)
    return strategy


@pytest.fixture(scope="function")
def sample_journal(test_session, sample_curriculum, sample_strategy):
    """Create a sample journal entry for testing."""
    journal = Journal(
        id=1,
        created_at=datetime(2025, 9, 16, 10, 30, 0),
        user_id=1,
        curriculum_id=sample_curriculum.id,
        strategy_id=sample_strategy.id,
    )
    test_session.add(journal)
    test_session.commit()
    test_session.refresh(journal)
    return journal
