"""Logging configuration utilities that scrub PII before emission."""

from __future__ import annotations

import logging
from collections.abc import Mapping, Sequence
from typing import Any, Callable

REDACTED_TEXT = "[REDACTED]"

# Lower-case keys for easier comparisons regardless of caller casing.
_SENSITIVE_FIELDS = {
    "user_id",
    "created_at",
    "updated_at",
    "secondary_curriculum_id",
    "notes",
    "entry_text",
    "journal_text",
    "payload",
    "device_id",
}


def _is_sensitive_field(name: str) -> bool:
    return name.lower() in _SENSITIVE_FIELDS


def scrub_sensitive_data(value: Any) -> Any:
    """Return a copy of *value* with known PII fields redacted."""

    if isinstance(value, Mapping):
        return {
            key: (
                REDACTED_TEXT
                if _is_sensitive_field(str(key))
                else scrub_sensitive_data(val)
            )
            for key, val in value.items()
        }

    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        constructor = tuple if isinstance(value, tuple) else type(value)
        redacted_values = [scrub_sensitive_data(item) for item in value]
        return constructor(redacted_values)

    return value


class _SensitiveDataFilter(logging.Filter):
    """Logging filter that redacts sensitive fields on the fly."""

    def filter(self, record: logging.LogRecord) -> bool:  # noqa: D401 - logging protocol
        for attr_name, attr_value in list(record.__dict__.items()):
            if _is_sensitive_field(attr_name):
                setattr(record, attr_name, REDACTED_TEXT)
                continue
            if isinstance(attr_value, Mapping):
                setattr(record, attr_name, scrub_sensitive_data(attr_value))
            elif isinstance(attr_value, Sequence) and not isinstance(
                attr_value, (str, bytes, bytearray)
            ):
                sanitized = [scrub_sensitive_data(item) for item in attr_value]
                setattr(
                    record,
                    attr_name,
                    tuple(sanitized) if isinstance(attr_value, tuple) else type(attr_value)(sanitized),
                )

        if isinstance(record.msg, Mapping):
            record.msg = scrub_sensitive_data(record.msg)

        if isinstance(record.args, Mapping):
            record.args = scrub_sensitive_data(record.args)
        elif isinstance(record.args, tuple):
            record.args = tuple(
                scrub_sensitive_data(arg) if isinstance(arg, Mapping) else arg
                for arg in record.args
            )
        elif isinstance(record.args, list):
            record.args = [
                scrub_sensitive_data(arg) if isinstance(arg, Mapping) else arg
                for arg in record.args
            ]

        return True


_filter_instance = _SensitiveDataFilter()
_configured = False
_original_factory: Callable[..., logging.LogRecord] | None = None


def configure_logging() -> None:
    """Install the sensitive-data filter on known loggers."""

    global _configured
    if _configured:
        return

    root_logger = logging.getLogger()
    root_logger.addFilter(_filter_instance)
    for handler in root_logger.handlers:
        handler.addFilter(_filter_instance)

    for logger_name in ("uvicorn", "uvicorn.access", "uvicorn.error", "uvicorn.asgi"):
        logging.getLogger(logger_name).addFilter(_filter_instance)

    global _original_factory
    if _original_factory is None:
        _original_factory = logging.getLogRecordFactory()

        def _factory(*args: Any, **kwargs: Any) -> logging.LogRecord:
            record = _original_factory(*args, **kwargs)
            _filter_instance.filter(record)
            return record

        logging.setLogRecordFactory(_factory)

    _configured = True


__all__ = ["REDACTED_TEXT", "configure_logging", "scrub_sensitive_data"]
