import json
import subprocess
import sys
from pathlib import Path

DATA_DIR = Path("backend/data")
SCRIPT = Path("backend/tools/csv_to_json.py")


def run_script(input_name: str, output_path: Path) -> None:
    subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            str(DATA_DIR / input_name),
            "--out",
            str(output_path),
        ],
        check=True,
    )


def test_curriculum_conversion(tmp_path: Path) -> None:
    output = tmp_path / "curriculum.json"
    run_script("a-w-curriculum.csv", output)
    data = json.loads(output.read_text())
    assert data["Beige"]["Rising"]["Prescription"] == "Commitment"
    assert data["Beige"]["Rising"]["Overdose"] == "Overcommitment"
    assert data["Purple"]["Restoration"]["Prescription"] == "Recuperation"


def test_strategies_conversion(tmp_path: Path) -> None:
    output = tmp_path / "strategies.json"
    run_script("a-w-strategies.csv", output)
    data = json.loads(output.read_text())
    assert any(
        s["strategy"] == "Readjusting posture" and s["color"] == "Beige"
        for s in data["Bottoming Out"]
    )
    assert any(
        s["strategy"] == "Kirtan" and s["color"] == "Purple"
        for s in data["Restoration"]
    )
