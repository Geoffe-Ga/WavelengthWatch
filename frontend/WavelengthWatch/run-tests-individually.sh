#!/bin/bash

# Run watchOS test suites individually to avoid simulator crashes
# This is necessary because watchOS Simulator cannot handle running all tests simultaneously

set -e  # Exit on first failure

SCHEME="WavelengthWatch Watch App"
DESTINATION="platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
TEST_TARGET="WavelengthWatch Watch AppTests"

# List of all test suites
SUITES=(
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

echo "Running watchOS tests individually..."
echo "====================================="
echo ""

FAILED_SUITES=()
PASSED_COUNT=0

for suite in "${SUITES[@]}"; do
  echo "Testing: $suite"

  if xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:"$TEST_TARGET/$suite" \
    2>&1 | grep -q "TEST SUCCEEDED"; then
    echo "✅ $suite PASSED"
    ((PASSED_COUNT++))
  else
    echo "❌ $suite FAILED"
    FAILED_SUITES+=("$suite")
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
