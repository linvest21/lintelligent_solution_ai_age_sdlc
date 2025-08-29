#!/bin/bash

# Compliance monitoring script
# Runs continuously to ensure workflow compliance

source ./load_env.sh

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Starting Compliance Monitor...${NC}"
echo "Monitoring interval: 5 minutes"
echo "Press Ctrl+C to stop"
echo ""

LOG_FILE="compliance_monitor_$(date +%Y%m%d).log"

log_violation() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] VIOLATION: $message" >> "$LOG_FILE"
    echo -e "${RED}🚨 VIOLATION: $message${NC}"
}

log_warning() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $message" >> "$LOG_FILE"
    echo -e "${YELLOW}⚠️  WARNING: $message${NC}"
}

log_info() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $message" >> "$LOG_FILE"
    echo -e "${GREEN}✅ $message${NC}"
}

check_compliance() {
    echo -e "${BLUE}=== Compliance Check $(date '+%H:%M:%S') ===${NC}"
    
    # 1. Check active Jira ticket
    if [ -n "$CURRENT_TICKET" ] && [ -n "$JIRA_API_TOKEN" ]; then
        echo -n "Checking Jira ticket $CURRENT_TICKET... "
        TICKET_STATUS=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
            "${JIRA_URL}/rest/api/2/issue/${CURRENT_TICKET}" 2>/dev/null | \
            grep -o '"status"[^}]*' | grep -o '"name":"[^"]*' | cut -d'"' -f4)
        
        if [ -z "$TICKET_STATUS" ]; then
            log_warning "Failed to fetch ticket status"
        elif [[ "$TICKET_STATUS" != "In Progress" ]] && [[ "$TICKET_STATUS" != "Development" ]]; then
            log_violation "Ticket $CURRENT_TICKET is not in active development (Status: $TICKET_STATUS)"
        else
            echo -e "${GREEN}Active${NC}"
        fi
    else
        log_warning "No CURRENT_TICKET configured"
    fi
    
    # 2. Check for unauthorized modifications
    if [ -f allowed_files.txt ]; then
        echo -n "Checking for unauthorized modifications... "
        UNAUTHORIZED=$(git status --porcelain 2>/dev/null | awk '{print $2}' | grep -v -f allowed_files.txt | wc -l)
        if [ "$UNAUTHORIZED" -gt 0 ]; then
            log_violation "Unauthorized files modified (count: $UNAUTHORIZED)"
            git status --porcelain | awk '{print $2}' | grep -v -f allowed_files.txt | while read file; do
                echo "  - $file"
            done
        else
            echo -e "${GREEN}Clean${NC}"
        fi
    fi
    
    # 3. Check test coverage trend
    if [ -f coverage/coverage-summary.json ]; then
        echo -n "Checking test coverage... "
        CURRENT_COV=$(cat coverage/coverage-summary.json | grep -o '"pct":[0-9.]*' | head -1 | cut -d':' -f2)
        if (( $(echo "$CURRENT_COV < $MIN_TEST_COVERAGE" | bc -l 2>/dev/null || echo 0) )); then
            log_violation "Test coverage ${CURRENT_COV}% is below minimum ${MIN_TEST_COVERAGE}%"
        else
            echo -e "${GREEN}${CURRENT_COV}%${NC}"
        fi
    fi
    
    # 4. Check for long-running branches
    if command -v git &> /dev/null; then
        echo -n "Checking branch age... "
        BRANCH_AGE_DAYS=$(git log --format="%cr" -1 | grep -o '[0-9]*' | head -1)
        if [ -n "$BRANCH_AGE_DAYS" ] && [ "$BRANCH_AGE_DAYS" -gt 7 ]; then
            log_warning "Branch is $BRANCH_AGE_DAYS days old (consider merging soon)"
        else
            echo -e "${GREEN}Fresh${NC}"
        fi
    fi
    
    # 5. Check for uncommitted changes
    echo -n "Checking for uncommitted changes... "
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l)
    if [ "$UNCOMMITTED" -gt 10 ]; then
        log_warning "Large number of uncommitted changes ($UNCOMMITTED files)"
    elif [ "$UNCOMMITTED" -gt 0 ]; then
        echo -e "${YELLOW}$UNCOMMITTED files${NC}"
    else
        echo -e "${GREEN}Clean${NC}"
    fi
    
    # 6. Memory/Resource check for stress testing readiness
    echo -n "Checking system resources... "
    MEM_AVAILABLE=$(free -m | awk 'NR==2{printf "%.1f", $7/$2*100}')
    if (( $(echo "$MEM_AVAILABLE < 20" | bc -l 2>/dev/null || echo 0) )); then
        log_warning "Low memory available (${MEM_AVAILABLE}%) - may affect stress tests"
    else
        echo -e "${GREEN}${MEM_AVAILABLE}% free${NC}"
    fi
    
    echo ""
}

# Main monitoring loop
while true; do
    check_compliance
    
    # Summary
    VIOLATIONS=$(grep -c "VIOLATION" "$LOG_FILE" 2>/dev/null || echo 0)
    WARNINGS=$(grep -c "WARNING" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo -e "${BLUE}Summary - Violations: $VIOLATIONS, Warnings: $WARNINGS${NC}"
    echo "Next check in 5 minutes... (Press Ctrl+C to stop)"
    echo "─────────────────────────────────────────────"
    echo ""
    
    # Desktop notification for violations (if available)
    if [ "$VIOLATIONS" -gt 0 ] && command -v notify-send &> /dev/null; then
        notify-send "⚠️ Compliance Monitor" "$VIOLATIONS violations detected! Check $LOG_FILE"
    fi
    
    sleep 300
done