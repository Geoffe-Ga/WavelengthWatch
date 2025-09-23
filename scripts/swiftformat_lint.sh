#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "SwiftFormat lint skipped: non-macOS platform" >&2
  exit 0
fi

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "SwiftFormat not installed. Install via 'brew install swiftformat'." >&2
  exit 1
fi

swiftformat --lint frontend
