#!/bin/bash

# Run watchOS test suites with optimized execution strategy
#
# After fixing the @StateObject initialization bug (commit 3945b6a), all test suites
# can run together on a single simulator without SIGSEGV crashes. This is ~12x faster
# than running each suite individually.
#
# Build flags optimized for:
# - Single simulator execution (no Xcode parallelization conflicts)
# - Reduced I/O overhead (quiet mode)
# - Faster builds (code coverage disabled by default)
#
# Usage:
#   ./run-tests-individually.sh                    # Run all test suites together (default)
#   ./run-tests-individually.sh --individual       # Run suites individually (legacy mode)
#   ./run-tests-individually.sh AppConfigurationTests  # Run specific suite(s)

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
  "LayerFilterModeTests"
  "EmotionSummaryCardTests"
  "FilteredLayerNavigationViewTests"
  "ContentViewFilteringTests"
  "JournalFlowViewModelTests"
  "FlowCoordinatorViewTests"
  "MenuViewTests"
  "PrimaryEmotionSelectionViewTests"
  "SecondaryEmotionPromptViewTests"
  "SecondaryEmotionSelectionViewTests"
  "StrategySelectionViewTests"
)

# Parse arguments
INDIVIDUAL_MODE=false
SUITES=()

if [ $# -eq 0 ]; then
  # No arguments: run all suites together (optimized)
  SUITES=("${ALL_SUITES[@]}")
else
  for arg in "$@"; do
    if [ "$arg" = "--individual" ]; then
      INDIVIDUAL_MODE=true
    else
      SUITES+=("$arg")
    fi
  done

  # If no suites specified after --individual, run all
  if [ ${#SUITES[@]} -eq 0 ]; then
    SUITES=("${ALL_SUITES[@]}")
  fi
fi

# Build once for all tests - this is the slowest part (20-25 seconds)
echo "Building for testing..."
if ! xcodebuild build-for-testing \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -quiet \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -enableCodeCoverage NO \
  > /dev/null 2>&1; then
  echo "❌ Build failed. Showing error output:"
  echo ""
  # Error path: omit -quiet for verbose debugging output
  xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    -enableCodeCoverage NO
  exit 1
fi

echo "✅ Build complete."
echo ""

LOG_DIR="/tmp/watchos_tests"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/all_tests.log"

if [ "$INDIVIDUAL_MODE" = true ] || [ ${#SUITES[@]} -eq 1 ]; then
  # Individual mode: run each suite separately (legacy behavior)
  echo "Running ${#SUITES[@]} test suite(s) individually..."
  echo "====================================="
  echo ""

  FAILED_SUITES=()
  PASSED_COUNT=0

  for suite in "${SUITES[@]}"; do
    echo "Testing: $suite"
    SUITE_LOG="$LOG_DIR/${suite}.log"

    # Run tests without building - this is fast (2-5 seconds per suite)
    # Store output in memory first to avoid unnecessary disk I/O
    if ! TEST_OUTPUT=$(xcodebuild test-without-building \
      -xctestrun "$(find "$DERIVED_DATA_PATH" -name "*.xctestrun" | head -1)" \
      -destination "$DESTINATION" \
      -only-testing:"$TEST_TARGET/$suite" \
      2>&1); then
      # Test failed - save output to disk for analysis
      echo "$TEST_OUTPUT" > "$SUITE_LOG"
      echo "❌ $suite FAILED"
      FAILED_SUITES+=("$suite")

      # Show failure details
      echo ""
      echo "Failure details for $suite:"
      echo "---"
      echo "$TEST_OUTPUT" | grep -A 5 "failed\|error\|Error" | head -20 || echo "No error details found"
      echo "---"
      echo "Full log: $SUITE_LOG"
    else
      # Test passed - only save if it contains failures in output (xcodebuild exit code can be misleading)
      if echo "$TEST_OUTPUT" | grep -q "TEST FAILED\|Test case.*failed\|Testing failed"; then
        echo "$TEST_OUTPUT" > "$SUITE_LOG"
        echo "❌ $suite FAILED"
        FAILED_SUITES+=("$suite")

        echo ""
        echo "Failure details for $suite:"
        echo "---"
        echo "$TEST_OUTPUT" | grep -A 5 "failed\|error\|Error" | head -20 || echo "No error details found"
        echo "---"
        echo "Full log: $SUITE_LOG"
      else
        echo "✅ $suite PASSED"
        ((PASSED_COUNT++))
        # Write log file for reference (consistent with optimized mode)
        echo "$TEST_OUTPUT" > "$SUITE_LOG"
      fi
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
else
  # Optimized mode: run all suites together on single simulator
  echo "Running all ${#SUITES[@]} test suites together (optimized)..."
  echo "====================================="
  echo ""

  # Build -only-testing arguments
  ONLY_TESTING_ARGS=()
  for suite in "${SUITES[@]}"; do
    ONLY_TESTING_ARGS+=("-only-testing:$TEST_TARGET/$suite")
  done

  # Run all tests together
  # Store output in memory first to avoid unnecessary disk I/O
  if ! TEST_OUTPUT=$(xcodebuild test-without-building \
    -xctestrun "$(find "$DERIVED_DATA_PATH" -name "*.xctestrun" | head -1)" \
    -destination "$DESTINATION" \
    "${ONLY_TESTING_ARGS[@]}" \
    2>&1); then
    # Tests failed - save output to disk for analysis
    echo "$TEST_OUTPUT" > "$LOG_FILE"

    echo ""
    echo "====================================="
    echo "❌ Tests FAILED"
    echo ""
    echo "Failure details:"
    echo "---"
    echo "$TEST_OUTPUT" | grep -A 5 "failed\|error\|Error" | head -30 || echo "No error details found"
    echo "---"
    echo "Full log: $LOG_FILE"
    echo ""
    echo "💡 Tip: Run with --individual flag to isolate failing suite(s)"
    exit 1
  else
    # Tests passed - check for failures in output (xcodebuild exit code can be misleading)
    if echo "$TEST_OUTPUT" | grep -q "TEST FAILED\|Test case.*failed\|Testing failed"; then
      echo "$TEST_OUTPUT" > "$LOG_FILE"

      echo ""
      echo "====================================="
      echo "❌ Tests FAILED"
      echo ""
      echo "Failure details:"
      echo "---"
      echo "$TEST_OUTPUT" | grep -A 5 "failed\|error\|Error" | head -30 || echo "No error details found"
      echo "---"
      echo "Full log: $LOG_FILE"
      echo ""
      echo "💡 Tip: Run with --individual flag to isolate failing suite(s)"
      exit 1
    else
      # All tests passed - save log for reference
      echo "$TEST_OUTPUT" > "$LOG_FILE"

      echo ""
      echo "====================================="
      echo "✅ All test suites passed!"
      echo ""
      echo "Full log: $LOG_FILE"
      exit 0
    fi
  fi
fi
