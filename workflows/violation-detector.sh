#!/bin/bash

# Violation detector - STOPS all operations if critical violations detected
# This script enforces ABSOLUTE RULES

source ./load_env.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "🛡️ Running Violation Detector..."

CRITICAL_VIOLATION=false

# RULE 1: NO CODE WITHOUT JIRA TICKET
if [ -z "$CURRENT_TICKET" ]; then
    echo -e "${RED}🚨 CRITICAL: Attempting to code without Jira ticket${NC}"
    echo "🛑 STOPPING ALL OPERATIONS"
    CRITICAL_VIOLATION=true
fi

# RULE 2: NO JIRA TICKET WITHOUT CONFLUENCE SPEC
if [ -n "$CURRENT_TICKET" ] && [ -z "$CONFLUENCE_SPEC_ID" ]; then
    echo -e "${RED}🚨 CRITICAL: Jira ticket exists but no Confluence spec linked${NC}"
    echo "🛑 STOPPING ALL OPERATIONS"
    CRITICAL_VIOLATION=true
fi

# RULE 3: NO COMMIT WITHOUT 80% TEST COVERAGE
if [ -f coverage/coverage-summary.json ]; then
    COVERAGE=$(cat coverage/coverage-summary.json | grep -o '"pct":[0-9.]*' | head -1 | cut -d':' -f2)
    if (( $(echo "$COVERAGE < 80" | bc -l 2>/dev/null || echo 1) )); then
        echo -e "${RED}🚨 CRITICAL: Test coverage ${COVERAGE}% is below mandatory 80%${NC}"
        echo "🛑 BLOCKING COMMIT"
        CRITICAL_VIOLATION=true
    fi
fi

# RULE 4: NO MODIFICATION OUTSIDE AUTHORIZED FILES
if [ -f allowed_files.txt ]; then
    UNAUTHORIZED=$(git diff --name-only | grep -v -f allowed_files.txt | wc -l)
    if [ "$UNAUTHORIZED" -gt 0 ]; then
        echo -e "${RED}🚨 CRITICAL: Modifications detected outside authorized files${NC}"
        echo "Modified files not in allowed list:"
        git diff --name-only | grep -v -f allowed_files.txt
        echo "🛑 BLOCKING ALL CHANGES"
        CRITICAL_VIOLATION=true
    fi
fi

# RULE 5: NO PUSH WITHOUT STRESS TEST VALIDATION
if [ -f .git/PUSH_INTENT ]; then
    if [ ! -f stress_test_results.json ] || [ ! -f stress_test.passed ]; then
        echo -e "${RED}🚨 CRITICAL: Attempting to push without stress test validation${NC}"
        echo "🛑 BLOCKING PUSH"
        CRITICAL_VIOLATION=true
    fi
fi

if [ "$CRITICAL_VIOLATION" = true ]; then
    echo ""
    echo -e "${RED}════════════════════════════════════════════${NC}"
    echo -e "${RED}     CRITICAL VIOLATIONS DETECTED${NC}"
    echo -e "${RED}     ALL OPERATIONS BLOCKED${NC}"
    echo -e "${RED}════════════════════════════════════════════${NC}"
    
    # Create violation report
    VIOLATION_REPORT="violation_$(date +%Y%m%d_%H%M%S).log"
    {
        echo "VIOLATION REPORT - $(date)"
        echo "================================"
        echo "Current Ticket: ${CURRENT_TICKET:-NOT SET}"
        echo "Confluence Spec: ${CONFLUENCE_SPEC_ID:-NOT SET}"
        echo "Test Coverage: ${COVERAGE:-UNKNOWN}%"
        echo "Unauthorized Files: $UNAUTHORIZED"
        echo "================================"
        git status
    } > "$VIOLATION_REPORT"
    
    echo "Violation report saved to: $VIOLATION_REPORT"
    exit 1
else
    echo -e "${GREEN}✅ No critical violations detected${NC}"
    echo "All mandatory rules are being followed."
    exit 0
fi