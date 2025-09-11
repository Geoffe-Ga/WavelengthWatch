#!/usr/bin/env python3
"""
csv_to_json.py

Convert Google Sheets–exported CSVs into JSON for the WavelengthWatch app.

Input (default locations under backend/data/):
  - curriculum.csv   # columns: stage, phase, medicinal, toxic
  - strategies.csv   # columns: stage, phase, strategy   (one strategy per row)

Output (in backend/data/):
  - curriculum.json  # combined: {stage: {phase: {medicinal, toxic, strategies[]}}}
  - strategies.json  # {stage: {phase: [strategy, ...]}}

Usage:
  cd backend
  python tools/csv_to_json.py
  # or specify custom paths:
  python tools/csv_to_json.py --data-dir data --curriculum curriculum.csv --strategies strategies.csv

Notes:
  - Reads with UTF-8 (BOM-tolerant) to handle Google Sheets CSVs.
  - Ignores extra columns; trims whitespace; case-insensitive headers.
  - Normalizes keys (stage, phase) to snake_case (e.g., "Clear Light" -> "clear_light", "Bottoming Out" -> "bottoming_out").
  - Warns on duplicates; last one wins for medicinal/toxic; strategies de-duplicate.
  - If a strategy refers to a (stage, phase) not present in curriculum.csv, it will create the node with empty medicinal/toxic and warn.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import OrderedDict, defaultdict
from collections.abc import Sequence
from pathlib import Path
from typing import TypedDict

# Canonical keys (lowercase snake_case)
CANONICAL_STAGES = {
    "beige",
    "purple",
    "red",
    "blue",
    "orange",
    "green",
    "yellow",
    "teal",
    "ultraviolet",
    "clear_light",
}

CANONICAL_PHASES = {
    "restoration",
    "rising",
    "peaking",
    "withdrawal",
    "diminishing",
    "bottoming_out",
}


def snake(s: str) -> str:
    s = (s or "").strip().lower()
    # normalize common punctuation/spaces/hyphens
    for ch in ["/", "\\", "-", "—", "–"]:
        s = s.replace(ch, " ")
    s = "_".join([tok for tok in s.split() if tok])
    return s


def normalize_stage(raw: str) -> str:
    s = snake(raw)
    # canonicalize known variations
    if s in {"clearlight", "clear-light"}:
        s = "clear_light"
    return s


def normalize_phase(raw: str) -> str:
    p = snake(raw)
    # canonicalize known variations
    if p in {"bottomingout", "bottoming-out"}:
        p = "bottoming_out"
    if p == "withdraw":  # occasional shorthand
        p = "withdrawal"
    return p


def warn(msg: str) -> None:
    print(f"[WARN] {msg}", file=sys.stderr)


def info(msg: str) -> None:
    print(f"[INFO] {msg}", file=sys.stderr)


class PhasePayload(TypedDict):
    """Structure stored for each (stage, phase) pair."""

    medicinal: str
    toxic: str
    strategies: list[str]


def find_col(row_keys: Sequence[str], target: str) -> str:
    """
    Find the actual CSV column name matching 'target' (case/space-insensitive).
    Returns the exact key present in the CSV header or raises KeyError.
    """
    canonical = {k.strip().lower(): k for k in row_keys}
    key = target.strip().lower()
    if key not in canonical:
        # try some fallbacks
        aliases = {
            "medicinal": ["rx", "prescription", "light"],
            "toxic": ["od", "shadow", "overdose"],
            "strategy": ["strategies", "self_care", "self-care", "tip"],
            "stage": ["aptitude_stage", "aptitude", "level"],
            "phase": ["wavelength_phase", "wavelength", "state"],
        }
        for alias in aliases.get(target, []):
            if alias in canonical:
                return canonical[alias]
        raise KeyError(
            f"Missing required column '{target}' in CSV header. "
            f"Found columns: {', '.join(row_keys)}"
        )
    return canonical[key]


def read_curriculum_csv(path: Path) -> dict[tuple[str, str], dict[str, str]]:
    """
    Returns mapping: (stage, phase) -> {"medicinal": str, "toxic": str}
    """
    out: dict[tuple[str, str], dict[str, str]] = {}
    if not path.exists():
        raise FileNotFoundError(f"curriculum.csv not found at {path}")

    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            raise ValueError("curriculum.csv has no header row.")

        # Map target columns to actual header keys
        stage_col = find_col(reader.fieldnames, "stage")
        phase_col = find_col(reader.fieldnames, "phase")
        med_col = find_col(reader.fieldnames, "medicinal")
        tox_col = find_col(reader.fieldnames, "toxic")

        for i, row in enumerate(
            reader, start=2
        ):  # 2 = account for header row at 1
            stage = normalize_stage(row.get(stage_col, ""))
            phase = normalize_phase(row.get(phase_col, ""))
            medicinal = (row.get(med_col, "") or "").strip()
            toxic = (row.get(tox_col, "") or "").strip()

            if not stage or not phase:
                # skip empty rows
                continue

            key = (stage, phase)
            if key in out:
                warn(
                    f"Duplicate curriculum row at line {i} for {stage}/{phase}. "
                    f"Overwriting previous medicinal/toxic."
                )
            out[key] = {"medicinal": medicinal, "toxic": toxic}

            if stage not in CANONICAL_STAGES:
                warn(
                    f"Non-canonical stage '{stage}' (line {i}). It will be kept as-is."
                )
            if phase not in CANONICAL_PHASES:
                warn(
                    f"Non-canonical phase '{phase}' (line {i}). It will be kept as-is."
                )

    info(f"Loaded {len(out)} curriculum entries from {path.name}")
    return out


def read_strategies_csv(path: Path) -> dict[tuple[str, str], list[str]]:
    """
    Returns mapping: (stage, phase) -> [strategy, ...]
    """
    out: dict[tuple[str, str], list[str]] = defaultdict(list)
    if not path.exists():
        warn(f"strategies.csv not found at {path}; continuing without it.")
        return out

    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            raise ValueError("strategies.csv has no header row.")

        stage_col = find_col(reader.fieldnames, "stage")
        phase_col = find_col(reader.fieldnames, "phase")
        strat_col = find_col(reader.fieldnames, "strategy")

        for i, row in enumerate(reader, start=2):
            stage = normalize_stage(row.get(stage_col, ""))
            phase = normalize_phase(row.get(phase_col, ""))
            raw = (row.get(strat_col, "") or "").strip()
            if not stage or not phase or not raw:
                continue

            # One strategy per row is expected. If someone put delimited strategies,
            # be generous and split on '|' or ';;'.
            parts = [p.strip() for p in split_maybe(raw) if p.strip()]
            for p in parts:
                if p not in out[(stage, phase)]:
                    out[(stage, phase)].append(p)

            if stage not in CANONICAL_STAGES:
                warn(
                    f"Non-canonical stage '{stage}' in strategies (line {i})."
                )
            if phase not in CANONICAL_PHASES:
                warn(
                    f"Non-canonical phase '{phase}' in strategies (line {i})."
                )

    total = sum(len(v) for v in out.values())
    info(
        f"Loaded {total} strategies across {len(out)} stage/phase groups from {path.name}"
    )
    return out


def split_maybe(s: str) -> list[str]:
    """Split strategy strings if someone pasted multiple in one cell."""
    if "||" in s:
        return s.split("||")
    if " | " in s:
        return s.split(" | ")
    if ";;" in s:
        return s.split(";;")
    return [s]


def merge_to_nested(
    curriculum_map: dict[tuple[str, str], dict[str, str]],
    strategies_map: dict[tuple[str, str], list[str]],
) -> dict[str, dict[str, PhasePayload]]:
    """
    Returns nested dict:
      {
        stage: {
          phase: {
            "medicinal": str,
            "toxic": str,
            "strategies": [str, ...]
          }
        }
      }
    Stages and phases are sorted for stable output.
    """
    nested: dict[str, dict[str, PhasePayload]] = {}

    # Prime with curriculum entries
    for (stage, phase), vals in curriculum_map.items():
        if stage not in nested:
            nested[stage] = {}
        nested[stage][phase] = PhasePayload(
            medicinal=vals.get("medicinal", ""),
            toxic=vals.get("toxic", ""),
            strategies=[],
        )

    # Merge strategies; create nodes if missing (warn)
    for (stage, phase), strategies in strategies_map.items():
        if stage not in nested:
            warn(
                f"Strategy references unknown stage '{stage}'. Creating placeholder."
            )
            nested[stage] = {}
        if phase not in nested[stage]:
            warn(
                f"Strategy references unknown phase '{stage}/{phase}'. "
                "Creating placeholder with empty medicinal/toxic."
            )
            nested[stage][phase] = PhasePayload(
                medicinal="",
                toxic="",
                strategies=[],
            )
        # De-duplicate while preserving order
        seen = set(nested[stage][phase]["strategies"])
        for s in strategies:
            if s not in seen:
                nested[stage][phase]["strategies"].append(s)
                seen.add(s)

    # Sort phases inside each stage, and sort stages overall, for deterministic JSON
    def phase_sort_key(p: str) -> tuple[int, str]:
        order = [
            "restoration",
            "rising",
            "peaking",
            "withdrawal",
            "diminishing",
            "bottoming_out",
        ]
        return (order.index(p) if p in order else len(order), p)

    ordered: dict[str, dict[str, PhasePayload]] = OrderedDict()
    for stage in sorted(
        nested.keys(),
        key=lambda s: (
            list(CANONICAL_STAGES).index(s)
            if s in CANONICAL_STAGES
            else (len(CANONICAL_STAGES) + hash(s) % 1000)
        ),
    ):
        phases = nested[stage]
        ordered_phases = OrderedDict()
        for phase in sorted(phases.keys(), key=phase_sort_key):
            ordered_phases[phase] = phases[phase]
        ordered[stage] = ordered_phases

    return ordered


def write_json(path: Path, obj: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")
    info(f"Wrote {path}")


def extract_strategies_view(
    nested: dict[str, dict[str, PhasePayload]],
) -> dict[str, dict[str, list[str]]]:
    """
    Produce {stage: {phase: [strategy...]}} from the combined nested view.
    """
    out: dict[str, dict[str, list[str]]] = {}
    for stage, phases in nested.items():
        out[stage] = {}
        for phase, payload in phases.items():
            out[stage][phase] = list(payload["strategies"])
    return out


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert CSVs to JSON for WavelengthWatch."
    )
    parser.add_argument(
        "--data-dir",
        type=str,
        default="data",
        help="Directory containing CSVs and where JSON will be written.",
    )
    parser.add_argument(
        "--curriculum",
        type=str,
        default="curriculum.csv",
        help="Curriculum CSV filename.",
    )
    parser.add_argument(
        "--strategies",
        type=str,
        default="strategies.csv",
        help="Strategies CSV filename.",
    )
    parser.add_argument(
        "--out-curriculum",
        type=str,
        default="curriculum.json",
        help="Output JSON filename (combined).",
    )
    parser.add_argument(
        "--out-strategies",
        type=str,
        default="strategies.json",
        help="Output JSON filename (strategies-only).",
    )
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    curriculum_csv = data_dir / args.curriculum
    strategies_csv = data_dir / args.strategies

    info(f"Reading curriculum from {curriculum_csv}")
    curriculum_map = read_curriculum_csv(curriculum_csv)

    info(f"Reading strategies from {strategies_csv}")
    strategies_map = read_strategies_csv(strategies_csv)

    combined = merge_to_nested(curriculum_map, strategies_map)

    # Write outputs
    write_json(data_dir / args.out_curriculum, combined)
    write_json(
        data_dir / args.out_strategies, extract_strategies_view(combined)
    )

    # Simple summary
    num_pairs = sum(len(phases) for phases in combined.values())
    num_strats = sum(
        len(phases[p]["strategies"])
        for phases in combined.values()
        for p in phases
    )
    info(
        f"Done. Stages: {len(combined)}; Stage/Phase pairs: {num_pairs}; Total strategies: {num_strats}"
    )


if __name__ == "__main__":
    main()
