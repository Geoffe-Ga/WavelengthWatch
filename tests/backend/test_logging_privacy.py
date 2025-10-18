"""Privacy-focused logging tests."""

from __future__ import annotations

import logging

import pytest


@pytest.fixture(autouse=True)
def reset_logging_filters():
    """Ensure each test starts with a clean root logger."""

    root = logging.getLogger()
    for existing_filter in list(root.filters):
        root.removeFilter(existing_filter)
    yield
    for existing_filter in list(root.filters):
        root.removeFilter(existing_filter)


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
    assert sanitized["context"]["measurements"][0]["user_id"] == logging_config.REDACTED_TEXT
    assert (
        sanitized["context"]["measurements"][1]["secondary_curriculum_id"]
        == logging_config.REDACTED_TEXT
    )
    assert sanitized["context"]["strategy_id"] == 3


def test_logging_filter_redacts_payload_before_emission(caplog: pytest.LogCaptureFixture):
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
    assert "'user_id': 7" not in log_output
    assert "2024-07-02T08:00:00Z" not in log_output
    assert logging_config.REDACTED_TEXT in log_output
    assert "'curriculum_id': 2" in log_output
