#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROJECT_PATH=${WW_XCODE_PROJECT:-"${PROJECT_ROOT}/frontend/WavelengthWatch/WavelengthWatch.xcodeproj"}
SCHEME=${WW_XCODE_SCHEME:-"WavelengthWatch Watch App"}
CONFIGURATION=${WW_XCODE_CONFIGURATION:-"Debug"}
DESTINATION=${WW_XCODE_DESTINATION:-"generic/platform=watchOS Simulator"}
ACTION=${WW_XCODE_ACTION:-"build"}
ALLOW_MISSING_XCODEBUILD=${WW_ALLOW_MISSING_XCODEBUILD:-0}

platform=$(uname -s)
if [[ "${platform}" != "Darwin" ]]; then
  echo "watchOS build skipped: requires macOS (detected ${platform})." >&2
  exit "${ALLOW_MISSING_XCODEBUILD}"
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild command not found. Install Xcode 16.4 or newer plus the command-line tools." >&2
  exit 1
fi

if ! command -v plutil >/dev/null 2>&1; then
  echo "plutil command not found. Install the Xcode command-line tools." >&2
  exit 1
fi

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Xcode project not found at ${PROJECT_PATH}." >&2
  exit 1
fi

declare -a EXTRA_ARGS
for arg in "$@"; do
  EXTRA_ARGS+=("${arg}")
  if [[ "${arg}" == "-project" ]]; then
    echo "Use WW_XCODE_PROJECT to override the project path instead of passing -project." >&2
    exit 1
  fi
  if [[ "${arg}" == "-scheme" ]]; then
    echo "Use WW_XCODE_SCHEME to override the scheme instead of passing -scheme." >&2
    exit 1
  fi
  if [[ "${arg}" == "-configuration" ]]; then
    echo "Use WW_XCODE_CONFIGURATION to override the configuration instead of passing -configuration." >&2
    exit 1
  fi
  if [[ "${arg}" == "-destination" ]]; then
    echo "Use WW_XCODE_DESTINATION to override the destination instead of passing -destination." >&2
    exit 1
  fi
  if [[ "${arg}" == "-showBuildSettings" ]]; then
    echo "-showBuildSettings is managed internally." >&2
    exit 1
  fi
  if [[ "${arg}" == "build" ]]; then
    echo "Action arguments are managed internally via WW_XCODE_ACTION." >&2
    exit 1
  fi
  if [[ "${arg}" == "clean" ]]; then
    echo "Action arguments are managed internally via WW_XCODE_ACTION." >&2
    exit 1
  fi
  if [[ "${arg}" == "archive" ]]; then
    echo "Action arguments are managed internally via WW_XCODE_ACTION." >&2
    exit 1
  fi
  if [[ "${arg}" == -* ]]; then
    continue
  fi
done

if [[ -z "${EXTRA_ARGS[*]-}" || " ${EXTRA_ARGS[*]} " != *" CODE_SIGNING_ALLOWED="* ]]; then
  EXTRA_ARGS+=("CODE_SIGNING_ALLOWED=NO")
fi

echo "Building ${SCHEME} (${CONFIGURATION}) for ${DESTINATION}..."
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "${DESTINATION}" \
  "${EXTRA_ARGS[@]}" \
  "${ACTION}"

echo "Resolving build settings to locate generated Info.plist..."
SETTINGS_OUTPUT=$(mktemp)
trap 'rm -f "${SETTINGS_OUTPUT}"' EXIT
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "${DESTINATION}" \
  -showBuildSettings >"${SETTINGS_OUTPUT}"

TARGET_BUILD_DIR=$(grep -E "^\s*TARGET_BUILD_DIR = " "${SETTINGS_OUTPUT}" | head -n1 | awk -F ' = ' '{print $2}')
INFOPLIST_PATH=$(grep -E "^\s*INFOPLIST_PATH = " "${SETTINGS_OUTPUT}" | head -n1 | awk -F ' = ' '{print $2}')

if [[ -z "${TARGET_BUILD_DIR}" || -z "${INFOPLIST_PATH}" ]]; then
  echo "Unable to parse build settings for TARGET_BUILD_DIR or INFOPLIST_PATH." >&2
  exit 1
fi

FULL_PLIST_PATH="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [[ ! -f "${FULL_PLIST_PATH}" ]]; then
  echo "Info.plist not found at ${FULL_PLIST_PATH}." >&2
  exit 1
fi

echo "Validating API_BASE_URL in ${FULL_PLIST_PATH}..."
API_BASE_URL=$(plutil -extract API_BASE_URL raw -o - "${FULL_PLIST_PATH}" 2>/dev/null || true)
if [[ -z "${API_BASE_URL}" ]]; then
  echo "API_BASE_URL is missing from ${FULL_PLIST_PATH}." >&2
  exit 1
fi
if echo "${API_BASE_URL}" | grep -qi "placeholder"; then
  echo "API_BASE_URL contains a placeholder value: ${API_BASE_URL}" >&2
  exit 1
fi

echo "API_BASE_URL verified: ${API_BASE_URL}"
