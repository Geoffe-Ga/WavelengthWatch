#!/usr/bin/env bash
#
# Backend code quality checks script
# Runs linting, formatting, type checking, and tests for the Python backend
#
# Usage:
#   ./scripts/check-backend.sh           # Run all checks
#   ./scripts/check-backend.sh --fix     # Auto-fix formatting issues
#   ./scripts/check-backend.sh --test    # Run only tests
#   ./scripts/check-backend.sh --lint    # Run only lint checks
#   ./scripts/check-backend.sh --type    # Run only type checks

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Activate virtual environment
if [ -f "$PROJECT_ROOT/.venv/bin/activate" ]; then
    source "$PROJECT_ROOT/.venv/bin/activate"
else
    echo -e "${RED}❌ Virtual environment not found. Run dev-setup.sh first.${NC}"
    exit 1
fi

# Parse arguments
FIX_MODE=false
TEST_ONLY=false
LINT_ONLY=false
TYPE_ONLY=false

for arg in "$@"; do
    case $arg in
        --fix)
            FIX_MODE=true
            ;;
        --test)
            TEST_ONLY=true
            ;;
        --lint)
            LINT_ONLY=true
            ;;
        --type)
            TYPE_ONLY=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--fix] [--test] [--lint] [--type]"
            exit 1
            ;;
    esac
done

cd "$PROJECT_ROOT"

# Run linting
if [ "$TEST_ONLY" = false ] && [ "$TYPE_ONLY" = false ]; then
    echo -e "${YELLOW}Running ruff linting...${NC}"
    if ruff check backend tests/backend; then
        echo -e "${GREEN}✅ Linting passed${NC}"
    else
        echo -e "${RED}❌ Linting failed${NC}"
        exit 1
    fi
    echo ""
fi

# Run formatting
if [ "$TEST_ONLY" = false ] && [ "$TYPE_ONLY" = false ]; then
    echo -e "${YELLOW}Running ruff formatting...${NC}"
    if [ "$FIX_MODE" = true ]; then
        ruff format backend tests/backend
        echo -e "${GREEN}✅ Formatting applied${NC}"
    else
        if ruff format --check backend tests/backend; then
            echo -e "${GREEN}✅ Formatting check passed${NC}"
        else
            echo -e "${RED}❌ Formatting check failed. Run with --fix to auto-format.${NC}"
            exit 1
        fi
    fi
    echo ""
fi

# Run type checking
if [ "$TEST_ONLY" = false ] && [ "$LINT_ONLY" = false ]; then
    echo -e "${YELLOW}Running mypy type checking...${NC}"
    if mypy --config-file mypy.ini backend; then
        echo -e "${GREEN}✅ Type checking passed${NC}"
    else
        echo -e "${RED}❌ Type checking failed${NC}"
        exit 1
    fi
    echo ""
fi

# Run tests
if [ "$LINT_ONLY" = false ] && [ "$TYPE_ONLY" = false ]; then
    echo -e "${YELLOW}Running pytest...${NC}"
    if pytest tests/backend/ -q; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        echo -e "${RED}❌ Tests failed${NC}"
        exit 1
    fi
    echo ""
fi

echo -e "${GREEN}✅ All backend checks passed!${NC}"
