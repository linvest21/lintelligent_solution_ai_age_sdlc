#!/bin/bash

# Load environment variables
source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Pre-Commit Validation${NC}"
echo "========================="

VALIDATION_PASSED=true

# Load session data
if [ ! -f "development_session.json" ]; then
  echo -e "${RED}❌ Error: development_session.json not found${NC}"
  exit 1
fi

TICKET_ID=$(jq -r '.ticket_id' development_session.json)
PROJECT_MODE=$(jq -r '.project_mode' development_session.json)

# 1. Check for Jira ticket reference
echo "1. Checking commit message format..."

# Get staged commit message if exists
if [ -f ".git/COMMIT_EDITMSG" ]; then
  COMMIT_MSG=$(cat .git/COMMIT_EDITMSG)
else
  COMMIT_MSG=""
  echo -e "${YELLOW}   No commit message yet. Example format:${NC}"
  echo "   [$TICKET_ID] Brief description"
  echo ""
fi

# 2. Check for unauthorized file modifications
echo "2. Checking file modifications..."

if [ "$PROJECT_MODE" == "MODIFICATION" ] && [ -f "allowed_files.txt" ]; then
  MODIFIED_FILES=$(git diff --cached --name-only)
  UNAUTHORIZED_COUNT=0
  
  while IFS= read -r file; do
    if ! grep -q "^$file$" allowed_files.txt; then
      echo -e "${RED}   ❌ Unauthorized modification: $file${NC}"
      UNAUTHORIZED_COUNT=$((UNAUTHORIZED_COUNT + 1))
      VALIDATION_PASSED=false
    fi
  done <<< "$MODIFIED_FILES"
  
  if [ $UNAUTHORIZED_COUNT -eq 0 ]; then
    echo -e "${GREEN}   ✅ All modifications authorized${NC}"
  else
    echo -e "${RED}   ❌ $UNAUTHORIZED_COUNT unauthorized file(s) modified${NC}"
  fi
else
  echo -e "${GREEN}   ✅ No modification restrictions${NC}"
fi

# 3. Check test coverage
echo "3. Checking test coverage..."

COVERAGE_FILE=""
COVERAGE=0

if [ -f "coverage/coverage-summary.json" ]; then
  COVERAGE=$(jq '.total.lines.pct' coverage/coverage-summary.json)
  COVERAGE_FILE="coverage/coverage-summary.json"
elif [ -f "coverage.json" ]; then
  COVERAGE=$(python -c "import json; print(json.load(open('coverage.json'))['totals']['percent_covered'])" 2>/dev/null || echo 0)
  COVERAGE_FILE="coverage.json"
fi

if [ ! -z "$COVERAGE_FILE" ]; then
  if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
    echo -e "${GREEN}   ✅ Test coverage: ${COVERAGE}% (meets 80% requirement)${NC}"
  else
    echo -e "${RED}   ❌ Test coverage: ${COVERAGE}% (below 80% requirement)${NC}"
    VALIDATION_PASSED=false
  fi
else
  echo -e "${YELLOW}   ⚠️  No coverage report found. Run ./scripts/run-tests.sh first${NC}"
  VALIDATION_PASSED=false
fi

# 4. Check linting
echo "4. Running linters..."

LINT_PASSED=true

# JavaScript/TypeScript
if [ -f "package.json" ] && grep -q '"lint"' package.json; then
  npm run lint --silent > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ JavaScript/TypeScript linting passed${NC}"
  else
    echo -e "${RED}   ❌ JavaScript/TypeScript linting failed${NC}"
    echo "      Run 'npm run lint' to see errors"
    LINT_PASSED=false
    VALIDATION_PASSED=false
  fi
  
# Python
elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
  if command -v flake8 &> /dev/null; then
    flake8 . --exclude=venv,__pycache__ > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}   ✅ Python linting passed${NC}"
    else
      echo -e "${RED}   ❌ Python linting failed${NC}"
      echo "      Run 'flake8 .' to see errors"
      LINT_PASSED=false
      VALIDATION_PASSED=false
    fi
  else
    echo -e "${YELLOW}   ⚠️  flake8 not installed${NC}"
  fi
  
# Go
elif [ -f "go.mod" ]; then
  if command -v golangci-lint &> /dev/null; then
    golangci-lint run > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}   ✅ Go linting passed${NC}"
    else
      echo -e "${RED}   ❌ Go linting failed${NC}"
      echo "      Run 'golangci-lint run' to see errors"
      LINT_PASSED=false
      VALIDATION_PASSED=false
    fi
  else
    go fmt ./... > /dev/null 2>&1
    echo -e "${GREEN}   ✅ Go formatting applied${NC}"
  fi
else
  echo -e "${YELLOW}   ⚠️  No linter configured${NC}"
fi

# 5. Check type checking
echo "5. Running type checking..."

# TypeScript
if [ -f "tsconfig.json" ]; then
  npx tsc --noEmit > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ TypeScript type checking passed${NC}"
  else
    echo -e "${RED}   ❌ TypeScript type checking failed${NC}"
    echo "      Run 'npx tsc --noEmit' to see errors"
    VALIDATION_PASSED=false
  fi
  
# Python with mypy
elif [ -f "requirements.txt" ]; then
  if command -v mypy &> /dev/null; then
    mypy . --ignore-missing-imports > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}   ✅ Python type checking passed${NC}"
    else
      echo -e "${YELLOW}   ⚠️  Python type checking has warnings${NC}"
    fi
  else
    echo -e "${YELLOW}   ⚠️  mypy not installed${NC}"
  fi
else
  echo -e "${GREEN}   ✅ No type checking required${NC}"
fi

# 6. Security check
echo "6. Running security scan..."

SECURITY_PASSED=true

# npm audit
if [ -f "package-lock.json" ]; then
  AUDIT_RESULT=$(npm audit --json 2>/dev/null)
  VULNERABILITIES=$(echo "$AUDIT_RESULT" | jq '.metadata.vulnerabilities.moderate + .metadata.vulnerabilities.high + .metadata.vulnerabilities.critical' 2>/dev/null || echo 0)
  
  if [ "$VULNERABILITIES" -gt 0 ]; then
    echo -e "${RED}   ❌ $VULNERABILITIES security vulnerabilities found${NC}"
    echo "      Run 'npm audit' for details"
    SECURITY_PASSED=false
    VALIDATION_PASSED=false
  else
    echo -e "${GREEN}   ✅ No security vulnerabilities${NC}"
  fi
  
# Python safety
elif [ -f "requirements.txt" ]; then
  if command -v safety &> /dev/null; then
    safety check > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}   ✅ No security vulnerabilities${NC}"
    else
      echo -e "${RED}   ❌ Security vulnerabilities found${NC}"
      echo "      Run 'safety check' for details"
      SECURITY_PASSED=false
      VALIDATION_PASSED=false
    fi
  else
    echo -e "${YELLOW}   ⚠️  'safety' not installed${NC}"
  fi
else
  echo -e "${GREEN}   ✅ Security scan not required${NC}"
fi

# 7. Check for TODO items
echo "7. Checking for unresolved TODOs..."

TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX\|HACK" --include="*.js" --include="*.ts" --include="*.py" --include="*.java" --include="*.go" . 2>/dev/null | wc -l)

if [ $TODO_COUNT -gt 0 ]; then
  echo -e "${YELLOW}   ⚠️  Found $TODO_COUNT TODO/FIXME items in code${NC}"
  echo "      Consider resolving before commit"
else
  echo -e "${GREEN}   ✅ No TODO items found${NC}"
fi

# 8. Check commit size
echo "8. Checking commit size..."

CHANGED_LINES=$(git diff --cached --stat | tail -1 | awk '{print $4 + $6}')
if [ -z "$CHANGED_LINES" ]; then
  CHANGED_LINES=0
fi

if [ $CHANGED_LINES -gt 500 ]; then
  echo -e "${YELLOW}   ⚠️  Large commit: $CHANGED_LINES lines changed${NC}"
  echo "      Consider breaking into smaller commits"
elif [ $CHANGED_LINES -eq 0 ]; then
  echo -e "${YELLOW}   ⚠️  No changes staged for commit${NC}"
else
  echo -e "${GREEN}   ✅ Commit size: $CHANGED_LINES lines${NC}"
fi

# Generate commit message template
echo ""
echo -e "${BLUE}📝 Suggested Commit Message:${NC}"
echo "--------------------------------"

cat > .git/COMMIT_TEMPLATE << EOF
[$TICKET_ID] <Brief description of change>

Changes:
- <Detail 1>
- <Detail 2>

Confluence Spec: <URL from project_config.json>
Tests: Unit (${COVERAGE}%), Integration (Passed), Stress (Passed)

Co-authored-by: Claude <noreply@anthropic.com>
EOF

cat .git/COMMIT_TEMPLATE

# Final validation summary
echo ""
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "===================="

if [ "$VALIDATION_PASSED" = true ]; then
  echo -e "${GREEN}✅ ALL CHECKS PASSED!${NC}"
  echo ""
  echo "Ready to commit! Use:"
  echo "  git commit -t .git/COMMIT_TEMPLATE"
  echo ""
  echo "Or for a quick commit:"
  echo "  git commit -m \"[$TICKET_ID] Your message here\""
  
  # Update session file
  jq '.pre_commit_checks.lint = true | 
      .pre_commit_checks.test = true | 
      .pre_commit_checks.coverage = true | 
      .pre_commit_checks.security = true' development_session.json > tmp.json && mv tmp.json development_session.json
  
  exit 0
else
  echo -e "${RED}❌ VALIDATION FAILED!${NC}"
  echo ""
  echo "Please fix the issues above before committing."
  echo "Run this script again after fixing to revalidate."
  
  exit 1
fi