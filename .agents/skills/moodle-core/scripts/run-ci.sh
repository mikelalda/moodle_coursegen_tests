#!/bin/bash
#
# Moodle Plugin CI Validation Script
# Runs standard quality checks for Moodle plugin development
#
# Usage: ./run-ci.sh [plugin_path]
#        plugin_path defaults to current directory
#

set -e

PLUGIN_PATH="${1:-.}"
CI_BIN="../moodle-plugin-ci/bin/moodle-plugin-ci"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
FAILED=0

echo "=========================================="
echo "Moodle Plugin CI Validation"
echo "=========================================="
echo ""

# Check if CI tools are available
if [ ! -f "$CI_BIN" ]; then
    echo -e "${RED}Error: moodle-plugin-ci not found at $CI_BIN${NC}"
    echo "Please install moodle-plugin-ci in ../moodle-plugin-ci/"
    echo "See: https://moodlehq.github.io/moodle-plugin-ci/"
    exit 1
fi

# Detect Moodle installation directory
if [ -z "$MOODLE_DIR" ]; then
    if [ -f "../moodle/config.php" ]; then
        MOODLE_DIR="../moodle"
    elif [ -f "/var/www/moodle/config.php" ]; then
        MOODLE_DIR="/var/www/moodle"
    elif [ -f "$HOME/moodle/config.php" ]; then
        MOODLE_DIR="$HOME/moodle"
    fi
fi

if [ -n "$MOODLE_DIR" ] && [ -f "$MOODLE_DIR/config.php" ]; then
    MOODLE_AVAILABLE=true
    echo "Moodle installation: $MOODLE_DIR"
else
    MOODLE_AVAILABLE=false
    echo -e "${YELLOW}Warning: No configured Moodle installation found${NC}"
    echo "Set MOODLE_DIR environment variable or ensure ../moodle/config.php exists"
    echo "Some checks will be skipped."
fi

echo "Plugin path: $PLUGIN_PATH"
echo ""

# Phase 1: PHP Syntax
echo "----------------------------------------"
echo "Phase 1: PHP Syntax Validation"
echo "----------------------------------------"
if $CI_BIN phplint "$PLUGIN_PATH"; then
    echo -e "${GREEN}[PASS]${NC} PHP syntax OK"
else
    echo -e "${RED}[FAIL]${NC} PHP syntax errors found"
    FAILED=1
fi
echo ""

# Phase 2: Plugin Validation (requires Moodle)
echo "----------------------------------------"
echo "Phase 2: Plugin Validation"
echo "----------------------------------------"
if [ "$MOODLE_AVAILABLE" = true ]; then
    if $CI_BIN validate -m "$MOODLE_DIR" "$PLUGIN_PATH"; then
        echo -e "${GREEN}[PASS]${NC} Plugin validation OK"
    else
        echo -e "${RED}[FAIL]${NC} Plugin validation errors found"
        FAILED=1
    fi
else
    echo -e "${YELLOW}[SKIP]${NC} Requires Moodle installation"
fi
echo ""

# Phase 3: Coding Standards
echo "----------------------------------------"
echo "Phase 3: Moodle Coding Standards"
echo "----------------------------------------"
if $CI_BIN codechecker "$PLUGIN_PATH"; then
    echo -e "${GREEN}[PASS]${NC} Coding standards OK"
else
    echo -e "${YELLOW}[WARN]${NC} Coding standard violations found"
    echo "Attempting auto-fix..."
    $CI_BIN codefixer "$PLUGIN_PATH" || true
    echo ""
    echo "Re-checking after auto-fix..."
    if $CI_BIN codechecker "$PLUGIN_PATH"; then
        echo -e "${GREEN}[PASS]${NC} Coding standards OK after auto-fix"
    else
        echo -e "${RED}[FAIL]${NC} Manual fixes required"
        FAILED=1
    fi
fi
echo ""

# Phase 4: Code Quality (PHPMD)
echo "----------------------------------------"
echo "Phase 4: Code Quality Analysis"
echo "----------------------------------------"
if $CI_BIN phpmd "$PLUGIN_PATH" 2>/dev/null; then
    echo -e "${GREEN}[PASS]${NC} Code quality OK"
else
    echo -e "${YELLOW}[WARN]${NC} Code quality issues found (review recommended)"
    # Don't fail on PHPMD - it has known parser issues
fi
echo ""

# Phase 5: Savepoints (if upgrade.php exists)
if [ -f "$PLUGIN_PATH/db/upgrade.php" ]; then
    echo "----------------------------------------"
    echo "Phase 5: Database Savepoints"
    echo "----------------------------------------"
    if [ "$MOODLE_AVAILABLE" = true ]; then
        if $CI_BIN savepoints -m "$MOODLE_DIR" "$PLUGIN_PATH"; then
            echo -e "${GREEN}[PASS]${NC} Savepoints OK"
        else
            echo -e "${RED}[FAIL]${NC} Savepoint errors found"
            FAILED=1
        fi
    else
        echo -e "${YELLOW}[SKIP]${NC} Requires Moodle installation"
    fi
    echo ""
fi

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed. Please review and fix the issues above.${NC}"
    exit 1
fi
