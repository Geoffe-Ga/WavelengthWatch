#!/bin/bash

# Run watchOS test suites individually to avoid simulator crashes
# This is necessary because watchOS Simulator cannot handle running all tests simultaneously
#
# Usage:
#   ./run-tests-individually.sh                    # Run all test suites
#   ./run-tests-individually.sh AppConfigurationTests  # Run specific suite
#   ./run-tests-individually.sh PhaseNavigatorTests NotificationDelegateTests  # Run multiple suites

set -e  # Exit on first failure

SCHEME="WavelengthWatch Watch App"
# Use a commonly available simulator across different Xcode/CI versions
DESTINATION="platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
TEST_TARGET="WavelengthWatch Watch AppTests"
DERIVED_DATA_PATH="$(pwd)/.test-cache"

# All available test suites
ALL_SUITES=(
  "AppConfigurationTests"
  "CatalogRepositoryTests"
  "PhaseNavigatorTests"
  "NotificationDelegateTests"
  "NotificationSchedulerTests"
  "ContentViewModelTests"
  "ContentViewModelInitiationContextTests"
  "ScheduleViewModelTests"
  "JournalUIInteractionTests"
  "JournalScheduleTests"
  "JournalClientTests"
  "MysticalJournalIconTests"
)

# Use command-line arguments if provided, otherwise run all suites
if [ $# -eq 0 ]; then
  SUITES=("${ALL_SUITES[@]}")
else
  SUITES=("$@")
fi

echo "Running watchOS tests individually..."
echo "====================================="
echo "Test suites: ${SUITES[*]}"
echo ""

# Build once for all tests - this is the slowest part (20-25 seconds)
echo "Building for testing (this happens once)..."
xcodebuild build-for-testing \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  > /dev/null 2>&1

echo "✅ Build complete. Running tests..."
echo ""

FAILED_SUITES=()
PASSED_COUNT=0
LOG_DIR="/tmp/watchos_tests"
mkdir -p "$LOG_DIR"

for suite in "${SUITES[@]}"; do
  echo "Testing: $suite"
  LOG_FILE="$LOG_DIR/${suite}.log"

  # Run tests without building - this is fast (2-5 seconds per suite)
  xcodebuild test-without-building \
    -xctestrun "$(find "$DERIVED_DATA_PATH" -name "*.xctestrun" | head -1)" \
    -destination "$DESTINATION" \
    -only-testing:"$TEST_TARGET/$suite" \
    2>&1 | tee "$LOG_FILE" > /dev/null

  # Check for test failures - if no failures found, tests passed
  if grep -q "TEST FAILED\|Test case.*failed\|Testing failed" "$LOG_FILE"; then
    echo "❌ $suite FAILED"
    FAILED_SUITES+=("$suite")

    # Show failure details
    echo ""
    echo "Failure details for $suite:"
    echo "---"
    grep -A 5 "failed\|error\|Error" "$LOG_FILE" | head -20 || echo "No error details found"
    echo "---"
    echo "Full log: $LOG_FILE"
  else
    echo "✅ $suite PASSED"
    ((PASSED_COUNT++))
  fi

  echo ""
done

echo "====================================="
echo "Test Results Summary:"
echo "  Passed: $PASSED_COUNT/${#SUITES[@]}"
echo "  Failed: ${#FAILED_SUITES[@]}"

if [ ${#FAILED_SUITES[@]} -gt 0 ]; then
  echo ""
  echo "Failed suites:"
  for suite in "${FAILED_SUITES[@]}"; do
    echo "  - $suite"
  done
  exit 1
else
  echo ""
  echo "✅ All test suites passed!"
  exit 0
fi
