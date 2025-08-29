#!/bin/bash

# Pre-commit validation script (DEMO MODE)
# This version works with demo tickets

source ./load_env.sh

echo "🔍 Running pre-commit validation (DEMO MODE)..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VALIDATION_PASSED=true

# 1. Check for Jira ticket in current branch name
echo -n "Checking for ticket reference in branch... "
BRANCH_NAME=$(git branch --show-current 2>/dev/null || echo "")
if [[ "$BRANCH_NAME" =~ (DEMO|PROJ)-[0-9]+ ]]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  No ticket in branch name (non-blocking in demo)${NC}"
fi

# 2. Check if CURRENT_TICKET is set
echo -n "Checking CURRENT_TICKET in .env... "
if [ -z "$CURRENT_TICKET" ]; then
    echo -e "${RED}❌ CURRENT_TICKET not set${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}✅ $CURRENT_TICKET${NC}"
fi

# 3. Demo mode - skip Jira API verification
echo -n "Verifying ticket (DEMO)... "
if [[ "$CURRENT_TICKET" =~ ^DEMO- ]]; then
    echo -e "${GREEN}✅ Demo ticket accepted${NC}"
else
    echo -e "${YELLOW}⚠️  Not a demo ticket, skipping API check${NC}"
fi

# 4. Check for unauthorized file modifications
echo -n "Checking for unauthorized modifications... "
if [ -d .git ] && [ -f allowed_files.txt ]; then
    UNAUTHORIZED=$(git diff --name-only 2>/dev/null | grep -v -f allowed_files.txt | wc -l)
    if [ "$UNAUTHORIZED" -gt 0 ]; then
        echo -e "${RED}❌ Unauthorized files modified:${NC}"
        git diff --name-only 2>/dev/null | grep -v -f allowed_files.txt
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}✅${NC}"
    fi
else
    echo -e "${GREEN}✅ (No restrictions)${NC}"
fi

# 5. Run linting
if [ -f package.json ]; then
    echo -n "Running lint checks... "
    if npm run lint --silent 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  Lint warnings (non-blocking)${NC}"
    fi
fi

# 6. Run type checking
if [ -f tsconfig.json ]; then
    echo -n "Running type checks... "
    if npx tsc --noEmit 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  Type warnings (non-blocking)${NC}"
    fi
fi

# 7. Check test coverage (if tests exist)
echo -n "Checking test coverage... "
if [ -d tests ] && [ -f package.json ]; then
    COVERAGE_RESULT=$(npm run test:coverage --silent 2>&1 | grep "All files" || echo "")
    if [ -n "$COVERAGE_RESULT" ]; then
        echo -e "${GREEN}✅ Coverage data available${NC}"
    else
        echo -e "${YELLOW}⚠️  No coverage data yet${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No tests configured${NC}"
fi

# 8. Security scan
echo -n "Running security scan... "
if [ -f package.json ]; then
    AUDIT_RESULT=$(npm audit --audit-level=high 2>&1)
    if echo "$AUDIT_RESULT" | grep -q "found 0 vulnerabilities"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  Check npm audit (non-blocking)${NC}"
    fi
fi

# 9. Check for Confluence spec
echo -n "Checking Confluence spec... "
if [ -n "$CONFLUENCE_SPEC_ID" ]; then
    echo -e "${GREEN}✅ $CONFLUENCE_SPEC_ID${NC}"
else
    echo -e "${YELLOW}⚠️  No spec linked (not recommended)${NC}"
fi

# Final result
echo ""
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✅ Pre-commit validation passed (DEMO MODE)!${NC}"
    echo ""
    echo "Ready to commit with message format:"
    echo "  [${CURRENT_TICKET}] Your commit message here"
    exit 0
else
    echo -e "${RED}❌ Pre-commit validation failed!${NC}"
    echo "Critical issues must be fixed before committing."
    exit 1
fi