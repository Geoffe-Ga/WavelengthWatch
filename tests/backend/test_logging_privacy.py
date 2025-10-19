"""Privacy-focused logging tests."""

from __future__ import annotations

import importlib
import logging
from collections.abc import Sequence

import pytest


@pytest.fixture(autouse=True)
def reset_logging_filters():
    """Ensure each test starts with a clean root logger."""

    import backend.logging_config as logging_config

    original_factory = logging.getLogRecordFactory()
    logging.setLogRecordFactory(logging.LogRecord)
    importlib.reload(logging_config)
    root = logging.getLogger()
    for existing_filter in list(root.filters):
        root.removeFilter(existing_filter)
    yield
    for existing_filter in list(root.filters):
        root.removeFilter(existing_filter)
    logging.setLogRecordFactory(original_factory)


def test_scrub_sensitive_data_recurses_through_nested_structures():
    from backend import logging_config

    payload = {
        "user_id": 99,
        "created_at": "2024-07-01T10:00:00Z",
        "context": {
            "notes": "Jogged in the park",
            "measurements": [
                {"user_id": 100},
                {"secondary_curriculum_id": 7},
            ],
            "strategy_id": 3,
        },
    }

    sanitized = logging_config.scrub_sensitive_data(payload)

    assert sanitized["user_id"] == logging_config.REDACTED_TEXT
    assert sanitized["created_at"] == logging_config.REDACTED_TEXT
    assert sanitized["context"]["notes"] == logging_config.REDACTED_TEXT
    assert (
        sanitized["context"]["measurements"][0]["user_id"]
        == logging_config.REDACTED_TEXT
    )
    assert (
        sanitized["context"]["measurements"][1]["secondary_curriculum_id"]
        == logging_config.REDACTED_TEXT
    )
    assert sanitized["context"]["strategy_id"] == 3


def test_logging_filter_redacts_payload_before_emission(
    caplog: pytest.LogCaptureFixture,
):
    from backend import logging_config

    logging_config.configure_logging()

    logger = logging.getLogger("backend.audit")

    with caplog.at_level(logging.INFO):
        logger.info(
            "persisted journal payload %s",
            {
                "user_id": 7,
                "created_at": "2024-07-02T08:00:00Z",
                "curriculum_id": 2,
            },
        )

    log_output = caplog.text
    assert "'user_id'" in log_output
    assert "'user_id': 7" not in log_output
    assert "2024-07-02T08:00:00Z" not in log_output
    assert logging_config.REDACTED_TEXT in log_output
    assert "'curriculum_id': 2" in log_output


def test_logging_filter_sanitizes_f_strings(caplog: pytest.LogCaptureFixture):
    from backend import logging_config

    logging_config.configure_logging()

    logger = logging.getLogger("backend.audit")

    with caplog.at_level(logging.INFO):
        user_id = 7
        created_at = "2024-07-02T08:00:00Z"
        logger.info(f"User {user_id} created entry at {created_at}")

    log_output = caplog.text
    assert "User" in log_output
    assert logging_config.REDACTED_TEXT in log_output
    assert "User 7" not in log_output
    assert "2024-07-02T08:00:00Z" not in log_output


def test_logging_filter_sanitizes_percent_format_strings(
    caplog: pytest.LogCaptureFixture,
):
    from backend import logging_config

    logging_config.configure_logging()

    logger = logging.getLogger("backend.audit")

    with caplog.at_level(logging.INFO):
        logger.info("User %s created entry at %s", 7, "2024-07-02T08:00:00Z")

    log_output = caplog.text
    assert logging_config.REDACTED_TEXT in log_output
    assert "User 7" not in log_output
    assert "2024-07-02T08:00:00Z" not in log_output


class _SequenceRequiringMarker(Sequence):
    def __init__(self, data: list[object], marker: str):
        self._data = list(data)
        self.marker = marker

    def __getitem__(self, index: int):  # type: ignore[override]
        return self._data[index]

    def __len__(self) -> int:  # type: ignore[override]
        return len(self._data)


def test_logging_filter_handles_sequence_constructor_fallback(
    caplog: pytest.LogCaptureFixture,
):
    from backend import logging_config

    logging_config.configure_logging()

    logger = logging.getLogger("backend.audit")

    with caplog.at_level(logging.INFO):
        logger.info(
            "custom sequence payload",
            extra={
                "items": _SequenceRequiringMarker([{"user_id": 5}], marker="journal")
            },
        )

    record = caplog.records[0]
    assert isinstance(record.items, list)
    assert record.items[0]["user_id"] == logging_config.REDACTED_TEXT


def test_log_record_factory_invokes_filter(caplog: pytest.LogCaptureFixture):
    from backend import logging_config

    logging_config.configure_logging()

    root = logging.getLogger()
    for existing_filter in list(root.filters):
        root.removeFilter(existing_filter)

    with caplog.at_level(logging.INFO):
        logging.info("User %s updated", {"user_id": 1})

    log_output = caplog.text
    assert logging_config.REDACTED_TEXT in log_output
    assert "'user_id': 1" not in log_output
