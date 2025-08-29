#!/bin/bash

# Pre-commit validation script
# This script MUST pass before any commit is allowed

source ./load_env.sh

echo "🔍 Running pre-commit validation..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VALIDATION_PASSED=true

# 1. Check for Jira ticket in current branch name or staged commit message
echo -n "Checking for Jira ticket reference... "
BRANCH_NAME=$(git branch --show-current 2>/dev/null || echo "")
if [[ ! "$BRANCH_NAME" =~ [A-Z]+-[0-9]+ ]] && [[ ! -f .git/COMMIT_EDITMSG || ! $(cat .git/COMMIT_EDITMSG 2>/dev/null) =~ \[[A-Z]+-[0-9]+\] ]]; then
    echo -e "${RED}❌ ERROR: No Jira ticket found in branch name or commit message${NC}"
    echo "  Branch name should be like: feature/PROJ-123-description"
    echo "  Or commit message should start with: [PROJ-123]"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}✅${NC}"
fi

# 2. Check if CURRENT_TICKET is set in .env
echo -n "Checking CURRENT_TICKET in .env... "
if [ -z "$CURRENT_TICKET" ]; then
    echo -e "${YELLOW}⚠️  WARNING: CURRENT_TICKET not set in .env${NC}"
    echo "  Please set CURRENT_TICKET=PROJ-XXX in .env file"
else
    echo -e "${GREEN}✅ $CURRENT_TICKET${NC}"
fi

# 3. Verify Jira ticket status (if CURRENT_TICKET is set)
if [ -n "$CURRENT_TICKET" ] && [ -n "$JIRA_API_TOKEN" ]; then
    echo -n "Verifying Jira ticket status... "
    TICKET_STATUS=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X GET \
        "${JIRA_URL}/rest/api/2/issue/${CURRENT_TICKET}" 2>/dev/null | \
        grep -o '"status"[^}]*' | grep -o '"name":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$TICKET_STATUS" ]; then
        echo -e "${RED}❌ Failed to fetch ticket status${NC}"
        VALIDATION_PASSED=false
    elif [[ "$TICKET_STATUS" == "In Progress" ]] || [[ "$TICKET_STATUS" == "Development" ]]; then
        echo -e "${GREEN}✅ Status: $TICKET_STATUS${NC}"
    else
        echo -e "${YELLOW}⚠️  WARNING: Ticket status is '$TICKET_STATUS'${NC}"
    fi
fi

# 4. Check for unauthorized file modifications
echo -n "Checking for unauthorized modifications... "
if [ -d .git ] && [ -f allowed_files.txt ]; then
    UNAUTHORIZED=$(git diff --cached --name-only 2>/dev/null | grep -v -f allowed_files.txt | wc -l)
    if [ "$UNAUTHORIZED" -gt 0 ]; then
        echo -e "${RED}❌ Unauthorized files modified:${NC}"
        git diff --cached --name-only 2>/dev/null | grep -v -f allowed_files.txt
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}✅${NC}"
    fi
elif [ -f allowed_files.txt ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  No allowed_files.txt found (all files allowed)${NC}"
fi

# 5. Run linting (if package.json exists)
if [ -f package.json ]; then
    echo -n "Running lint checks... "
    if npm run lint --silent 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌ Lint errors found${NC}"
        VALIDATION_PASSED=false
    fi
fi

# 6. Run type checking (if tsconfig.json exists)
if [ -f tsconfig.json ]; then
    echo -n "Running type checks... "
    if npm run typecheck --silent 2>/dev/null || npx tsc --noEmit 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌ Type errors found${NC}"
        VALIDATION_PASSED=false
    fi
fi

# 7. Check Python code (if Python files exist)
if git diff --cached --name-only | grep -q '\.py$'; then
    echo -n "Running Python checks... "
    if command -v flake8 &> /dev/null; then
        if flake8 $(git diff --cached --name-only | grep '\.py$') 2>/dev/null; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌ Python linting errors${NC}"
            VALIDATION_PASSED=false
        fi
    else
        echo -e "${YELLOW}⚠️  flake8 not installed${NC}"
    fi
fi

# 8. Security scan
echo -n "Running security scan... "
if [ -f package.json ]; then
    AUDIT_RESULT=$(npm audit --audit-level=high 2>&1)
    if echo "$AUDIT_RESULT" | grep -q "found 0 vulnerabilities"; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  Security vulnerabilities found (non-blocking)${NC}"
    fi
else
    echo -e "skipped (no package.json)"
fi

# Final result
echo ""
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✅ All pre-commit checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Pre-commit validation failed!${NC}"
    echo "Please fix the issues above before committing."
    exit 1
fi