"""Shared constants for backend services."""

PHASE_ORDER: list[str] = [
    "Rising",
    "Peaking",
    "Withdrawal",
    "Diminishing",
    "Bottoming Out",
    "Restoration",
]

__all__ = ["PHASE_ORDER"]
