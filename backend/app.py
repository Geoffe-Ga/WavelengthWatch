from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"


def _load_json(filename: str) -> Any:
    path = DATA_DIR / filename
    if not path.exists():
        return [] if filename.endswith(".json") else None
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


app = FastAPI(title="WavelengthWatch Backend", version="0.1.0")

# CORS: allow local dev + simulator to fetch JSON
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/curriculum")
def curriculum() -> Any:
    # Returns the JSON list describing stages/phases and medicinal/toxic flags.
    return _load_json("curriculum.json")


@app.get("/strategies")
def strategies() -> Any:
    # Returns the JSON list of self-care strategies.
    return _load_json("strategies.json")
