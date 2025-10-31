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
DESTINATION="platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
TEST_TARGET="WavelengthWatch Watch AppTests"

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

FAILED_SUITES=()
PASSED_COUNT=0
LOG_DIR="/tmp/watchos_tests"
mkdir -p "$LOG_DIR"

for suite in "${SUITES[@]}"; do
  echo "Testing: $suite"
  LOG_FILE="$LOG_DIR/${suite}.log"

  xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:"$TEST_TARGET/$suite" \
    2>&1 | tee "$LOG_FILE" > /dev/null

  if grep -q "TEST SUCCEEDED" "$LOG_FILE"; then
    echo "✅ $suite PASSED"
    ((PASSED_COUNT++))
  else
    echo "❌ $suite FAILED"
    FAILED_SUITES+=("$suite")

    # Show failure details
    echo ""
    echo "Failure details for $suite:"
    echo "---"
    grep -A 5 "failed\|error\|Error" "$LOG_FILE" | head -20 || echo "No error details found"
    echo "---"
    echo "Full log: $LOG_FILE"
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
