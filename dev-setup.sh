#!/usr/bin/env bash
set -euo pipefail

echo "🔧 WavelengthWatch dev setup"

# Ensure we are at repo root (contains .git and backend directory)
if [ ! -d ".git" ] || [ ! -d "backend" ]; then
  echo "Please run this from the repository root."
  exit 1
fi

# Xcode check
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode command line tools not found. Please install Xcode and run 'xcode-select --install'."
  exit 1
fi

# Homebrew (optional) install SwiftFormat
if command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing SwiftFormat via Homebrew (if needed)"
  brew list swiftformat >/dev/null 2>&1 || brew install swiftformat
else
  echo "Homebrew not found; skipping SwiftFormat install. Install from https://github.com/nicklockwood/SwiftFormat if needed."
fi

# Python venv + deps
PYTHON_BIN="${PYTHON_BIN:-python3}"
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "python3 not found. Please install Python 3.12+."
  exit 1
fi

echo "🐍 Creating virtualenv .venv (if missing)"
if [ ! -d ".venv" ]; then
  "$PYTHON_BIN" -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r backend/requirements.txt
if [ -f backend/requirements-dev.txt ]; then pip install -r backend/requirements-dev.txt; fi

# pre-commit
echo "🪝 Installing pre-commit hooks"
pip install pre-commit
pre-commit install --install-hooks

echo "✅ Dev environment ready.
- Format Swift: swiftformat frontend
- Run backend:   uvicorn backend.app:app --reload
- Test backend:  pytest -q
