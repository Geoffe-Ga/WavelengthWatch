"""Logging configuration utilities that scrub PII before emission."""

from __future__ import annotations

import logging
import re
from collections.abc import Callable, Mapping, Sequence
from typing import Any

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


# Heuristic replacements for common f-string/percent-formatting
# mistakes. This is best-effort protection—the preferred guidance is
# to send identifiers via structured payloads.
_STRING_PATTERNS: tuple[tuple[re.Pattern[str], Callable[[re.Match[str]], str]], ...] = (
    (
        re.compile(r"(?i)(\buser(?:[_\s]?id)?)(\s*(?:=|:)?\s*)([0-9a-zA-Z-]+)"),
        lambda match: f"{match.group(1)}{match.group(2)}{REDACTED_TEXT}",
    ),
    (
        re.compile(r"(?i)(\bdevice(?:[_\s]?id)?)(\s*(?:=|:)?\s*)([0-9a-zA-Z-]+)"),
        lambda match: f"{match.group(1)}{match.group(2)}{REDACTED_TEXT}",
    ),
    (
        re.compile(r"(?i)(\bcreated[_\s]?at\b)(\s*(?:=|:)?\s*)([^\s,;]+)"),
        lambda match: f"{match.group(1)}{match.group(2)}{REDACTED_TEXT}",
    ),
    (
        re.compile(r"(?i)(\bupdated[_\s]?at\b)(\s*(?:=|:)?\s*)([^\s,;]+)"),
        lambda match: f"{match.group(1)}{match.group(2)}{REDACTED_TEXT}",
    ),
    (
        re.compile(r"\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\b"),
        lambda match: REDACTED_TEXT,
    ),
)


def _is_sensitive_field(name: str) -> bool:
    return name.lower() in _SENSITIVE_FIELDS


def _scrub_string_message(message: str) -> str:
    """Apply lightweight regex scrubbing to formatted string messages."""

    sanitized = message
    for pattern, replacement in _STRING_PATTERNS:
        sanitized = pattern.sub(replacement, sanitized)
    return sanitized


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

    if isinstance(value, Sequence) and not isinstance(value, str | bytes | bytearray):
        redacted_values = [scrub_sensitive_data(item) for item in value]
        constructor = tuple if isinstance(value, tuple) else list
        try:
            return constructor(redacted_values)
        except TypeError:
            return list(redacted_values)

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
                attr_value, str | bytes | bytearray
            ):
                sanitized = [scrub_sensitive_data(item) for item in attr_value]
                constructor = tuple if isinstance(attr_value, tuple) else list
                try:
                    reconstructed = constructor(sanitized)
                except TypeError:
                    reconstructed = list(sanitized)
                setattr(record, attr_name, reconstructed)

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

        message = record.getMessage()
        record.msg = _scrub_string_message(message)
        record.args = ()

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
