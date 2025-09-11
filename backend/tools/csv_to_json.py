#!/usr/bin/env python3
"""Utility to convert A-W CSV files into JSON.

The script accepts a single CSV file. It inspects the header to determine
whether the input represents curriculum data or self-care strategies and
writes the corresponding JSON structure.

Usage
-----
python backend/tools/csv_to_json.py path/to/file.csv [--out output.json]
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Iterable

PHASE_ORDER = [
    "Rising",
    "Peaking",
    "Withdrawal",
    "Diminishing",
    "Bottoming Out",
    "Restoration",
]


def _detect(headers: Iterable[str]) -> str:
    lowered = {h.lower() for h in headers if h}
    if "dosage" in lowered:
        return "curriculum"
    if {"strategy", "phase"}.issubset(lowered):
        return "strategies"
    raise ValueError(f"Unrecognised CSV format with headers: {headers}")


def _convert_curriculum(rows: list[dict[str, str]], headers: Iterable[str]) -> dict[str, dict[str, dict[str, str]]]:
    phases = [h for h in headers if h and h.lower() not in {"dosage", "stage"}]
    result: dict[str, dict[str, dict[str, str]]] = {}
    for row in rows:
        dosage = row.get("dosage", "").strip().lower()
        stage = row.get("stage", "").strip().title()
        stage_map = result.setdefault(stage, {})
        key = "Prescription" if dosage.startswith("med") else "Overdose"
        for ph in phases:
            value = row.get(ph, "").strip()
            if not value:
                continue
            phase = ph.strip().title()
            payload = stage_map.setdefault(phase, {"Prescription": "", "Overdose": ""})
            payload[key] = value
    ordered: dict[str, dict[str, dict[str, str]]] = {}
    for stage, phase_map in result.items():
        ordered_phases: dict[str, dict[str, str]] = {
            ph: phase_map[ph] for ph in PHASE_ORDER if ph in phase_map
        }
        for ph, val in phase_map.items():
            if ph not in ordered_phases:
                ordered_phases[ph] = val
        ordered[stage] = ordered_phases
    return ordered


def _convert_strategies(rows: list[dict[str, str]]) -> dict[str, list[dict[str, str]]]:
    result: dict[str, list[dict[str, str]]] = {ph: [] for ph in PHASE_ORDER}
    for row in rows:
        strategy = row.get("strategy", "").strip()
        stage = row.get("stage", "").strip().title()
        phase = row.get("phase", "").strip().title()
        if not strategy or not stage or not phase:
            continue
        result.setdefault(phase, []).append({"color": stage, "strategy": strategy})
    # remove phases without strategies while preserving order
    return {ph: result[ph] for ph in PHASE_ORDER if result.get(ph)}


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert A-W CSV to JSON")
    parser.add_argument("csv_file", type=Path, help="Input CSV file")
    parser.add_argument("--out", type=Path, help="Output JSON path")
    args = parser.parse_args()

    with args.csv_file.open(encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames or []
        rows = list(reader)
    kind = _detect(headers)
    if kind == "curriculum":
        data = _convert_curriculum(rows, headers)
        default_out = args.csv_file.with_name("curriculum.json")
    else:
        data = _convert_strategies(rows)
        default_out = args.csv_file.with_name("strategies.json")
    out_path = args.out or default_out
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


if __name__ == "__main__":  # pragma: no cover
    main()
