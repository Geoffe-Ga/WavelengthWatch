#!/usr/bin/env bash
set -euo pipefail

platform=$(uname -s)
if [[ "$platform" != "Darwin" ]]; then
  echo "SwiftFormat check skipped: requires macOS (detected $platform)." >&2
  exit 0
fi

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "SwiftFormat is not installed. Install it via \`brew install swiftformat\`." >&2
  exit 1
fi

swiftformat --lint "$@"
