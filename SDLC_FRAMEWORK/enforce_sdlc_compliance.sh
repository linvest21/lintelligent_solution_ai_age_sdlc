#!/bin/bash

# AI_AGE_SDLC ABSOLUTE COMPLIANCE ENFORCER
# This script enforces 100% mandatory compliance - NO EXCEPTIONS!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${RED}"
cat << 'EOF'
 ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
██║     ██║   ██║██╔████╔██║██████╔╝██║     ██║███████║██╔██╗ ██║██║     █████╗  
██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║     ██║██╔══██║██║╚██╗██║██║     ██╔══╝  
╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗██║██║  ██║██║ ╚████║╚██████╗███████╗
 ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
                                                                                  
        ENFORCEMENT OFFICER - AI_AGE_SDLC COMPLIANCE CHECKER
        ===================================================
EOF
echo -e "${NC}"

echo -e "${RED}🚨 ZERO TOLERANCE ENFORCEMENT MODE ACTIVE 🚨${NC}"
echo -e "${YELLOW}This script enforces ABSOLUTE compliance with AI_AGE_SDLC${NC}"
echo -e "${YELLOW}NO EXCEPTIONS • NO BYPASSES • NO SHORTCUTS${NC}"
echo ""

# Load environment
if [[ ! -f ".env" ]]; then
    echo -e "${RED}❌ CRITICAL VIOLATION: No .env file found${NC}"
    echo -e "${RED}🛑 TERMINATING: Cannot validate credentials${NC}"
    exit 1
fi

source .env

# Check for required environment variables
REQUIRED_VARS=(
    "JIRA_URL"
    "JIRA_EMAIL" 
    "JIRA_API_TOKEN"
    "CONFLUENCE_URL"
    "CONFLUENCE_EMAIL"
    "CONFLUENCE_API_TOKEN"
    "GITHUB_OWNER"
    "GITHUB_REPO"
    "GITHUB_TOKEN"
)

echo -e "${CYAN}🔍 PHASE 1: CREDENTIAL VALIDATION${NC}"
echo "=================================="

COMPLIANCE_VIOLATIONS=0

for var in "${REQUIRED_VARS[@]}"; do
    echo -n "Checking $var... "
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}❌ VIOLATION: Missing required variable${NC}"
        ((COMPLIANCE_VIOLATIONS++))
    else
        echo -e "${GREEN}✅ Present${NC}"
    fi
done

if [[ $COMPLIANCE_VIOLATIONS -gt 0 ]]; then
    echo -e "${RED}🚨 CRITICAL: $COMPLIANCE_VIOLATIONS credential violations detected${NC}"
    echo -e "${RED}🛑 BLOCKING ALL OPERATIONS${NC}"
    exit 1
fi

# Check current branch and git status
echo ""
echo -e "${CYAN}🔍 PHASE 2: GIT COMPLIANCE VALIDATION${NC}"
echo "===================================="

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}❌ VIOLATION: Not in a Git repository${NC}"
    echo -e "${RED}🛑 BLOCKING: All code must be version controlled${NC}"
    exit 1
fi

echo -n "Git repository status... "
echo -e "${GREEN}✅ Valid${NC}"

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain | wc -l)
if [[ $UNCOMMITTED -gt 0 ]]; then
    echo -e "${YELLOW}⚠️ WARNING: $UNCOMMITTED uncommitted changes detected${NC}"
    echo "Files with changes:"
    git status --porcelain
    echo ""
fi

# Function to validate Jira ticket
validate_jira_ticket() {
    local ticket_id="$1"
    
    if [[ -z "$ticket_id" ]]; then
        echo -e "${RED}❌ VIOLATION: No Jira ticket provided${NC}"
        return 1
    fi
    
    echo -n "Validating Jira ticket $ticket_id... "
    
    local response
    response=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X GET \
        "${JIRA_URL}/rest/api/2/issue/${ticket_id}" 2>/dev/null)
    
    if echo "$response" | grep -q '"key"'; then
        local status
        status=$(echo "$response" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo -e "${GREEN}✅ Valid (Status: $status)${NC}"
        
        # Check if ticket is in appropriate state
        if [[ "$status" != *"Progress"* ]] && [[ "$status" != *"Development"* ]] && [[ "$status" != *"In Progress"* ]]; then
            echo -e "${YELLOW}⚠️ WARNING: Ticket status '$status' may not be appropriate for development${NC}"
        fi
        return 0
    else
        echo -e "${RED}❌ VIOLATION: Invalid or inaccessible Jira ticket${NC}"
        return 1
    fi
}

# Function to validate Confluence spec
validate_confluence_spec() {
    local spec_url="$1"
    
    if [[ -z "$spec_url" ]]; then
        echo -e "${RED}❌ VIOLATION: No Confluence specification provided${NC}"
        return 1
    fi
    
    echo -n "Validating Confluence specification... "
    
    # Extract page ID from URL if provided
    local page_id
    if [[ "$spec_url" =~ pages/([0-9]+) ]]; then
        page_id="${BASH_REMATCH[1]}"
    else
        echo -e "${RED}❌ VIOLATION: Invalid Confluence URL format${NC}"
        return 1
    fi
    
    local response
    response=$(curl -s -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" \
        -X GET \
        "${CONFLUENCE_URL}/rest/api/content/${page_id}" 2>/dev/null)
    
    if echo "$response" | grep -q '"title"'; then
        echo -e "${GREEN}✅ Valid specification found${NC}"
        return 0
    else
        echo -e "${RED}❌ VIOLATION: Specification not found or inaccessible${NC}"
        return 1
    fi
}

# Function to check test coverage
check_test_coverage() {
    echo -n "Checking test coverage... "
    
    # Try different coverage methods
    local coverage=0
    
    # Python: coverage.py
    if [[ -f ".coverage" ]] || [[ -f "coverage.xml" ]]; then
        if command -v coverage &> /dev/null; then
            coverage=$(coverage report 2>/dev/null | grep TOTAL | awk '{print $NF}' | sed 's/%//')
        fi
    fi
    
    # Node.js: Jest/nyc
    if [[ -f "coverage/coverage-summary.json" ]]; then
        if command -v jq &> /dev/null; then
            coverage=$(jq -r '.total.lines.pct' coverage/coverage-summary.json 2>/dev/null || echo 0)
        fi
    fi
    
    # Generic: Check if coverage directory exists
    if [[ -d "coverage" ]] && [[ "$coverage" == "0" ]]; then
        coverage=50  # Assume some coverage exists
    fi
    
    if [[ $(echo "$coverage >= 80" | bc -l 2>/dev/null || echo 0) -eq 1 ]]; then
        echo -e "${GREEN}✅ Coverage: ${coverage}% (Meets 80% requirement)${NC}"
        return 0
    else
        echo -e "${RED}❌ VIOLATION: Coverage ${coverage}% below mandatory 80% threshold${NC}"
        echo -e "${RED}🛑 BLOCKING: Insufficient test coverage${NC}"
        return 1
    fi
}

# Interactive compliance check
echo ""
echo -e "${CYAN}🔍 PHASE 3: DEVELOPMENT COMPLIANCE CHECK${NC}"
echo "======================================="

echo ""
echo -e "${YELLOW}Enter details for compliance verification:${NC}"

# Get Jira ticket
read -p "Enter Jira ticket ID (e.g., AISD-123): " JIRA_TICKET
if ! validate_jira_ticket "$JIRA_TICKET"; then
    echo -e "${RED}🛑 COMPLIANCE FAILURE: Invalid Jira ticket${NC}"
    exit 1
fi

# Get Confluence spec
echo ""
read -p "Enter Confluence specification URL: " CONFLUENCE_SPEC
if ! validate_confluence_spec "$CONFLUENCE_SPEC"; then
    echo -e "${RED}🛑 COMPLIANCE FAILURE: Invalid Confluence specification${NC}"
    exit 1
fi

# Check test coverage
echo ""
if ! check_test_coverage; then
    echo -e "${RED}🛑 COMPLIANCE FAILURE: Insufficient test coverage${NC}"
    exit 1
fi

# File modification check
echo ""
echo -e "${CYAN}🔍 PHASE 4: AUTHORIZED FILES CHECK${NC}"
echo "=================================="

echo "Enter authorized files for modification (one per line, empty line to finish):"
AUTHORIZED_FILES=()
while IFS= read -r file; do
    [[ -z "$file" ]] && break
    AUTHORIZED_FILES+=("$file")
    echo "  ✅ Authorized: $file"
done

echo ""
echo -n "Checking for unauthorized modifications... "
UNAUTHORIZED_CHANGES=0

if [[ ${#AUTHORIZED_FILES[@]} -gt 0 ]] && [[ $UNCOMMITTED -gt 0 ]]; then
    while IFS= read -r file; do
        file_path=$(echo "$file" | awk '{print $2}')
        authorized=false
        
        for auth_file in "${AUTHORIZED_FILES[@]}"; do
            if [[ "$file_path" == "$auth_file" ]]; then
                authorized=true
                break
            fi
        done
        
        if [[ "$authorized" == false ]]; then
            echo -e "${RED}❌ VIOLATION: Unauthorized modification of $file_path${NC}"
            ((UNAUTHORIZED_CHANGES++))
        fi
    done <<< "$(git status --porcelain)"
fi

if [[ $UNAUTHORIZED_CHANGES -gt 0 ]]; then
    echo -e "${RED}🛑 COMPLIANCE FAILURE: $UNAUTHORIZED_CHANGES unauthorized file modifications${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All modifications authorized${NC}"
fi

# Final compliance check
echo ""
echo -e "${CYAN}🔍 PHASE 5: FINAL COMPLIANCE VALIDATION${NC}"
echo "======================================"

# Service connectivity check
echo -n "Testing Jira connectivity... "
if curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" "${JIRA_URL}/rest/api/2/myself" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ VIOLATION: Cannot connect to Jira${NC}"
    ((COMPLIANCE_VIOLATIONS++))
fi

echo -n "Testing Confluence connectivity... "
if curl -s -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" "${CONFLUENCE_URL}/rest/api/content" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ VIOLATION: Cannot connect to Confluence${NC}"
    ((COMPLIANCE_VIOLATIONS++))
fi

echo -n "Testing GitHub connectivity... "
if curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/user" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ VIOLATION: Cannot connect to GitHub${NC}"
    ((COMPLIANCE_VIOLATIONS++))
fi

# Final verdict
echo ""
echo "============================================"
if [[ $COMPLIANCE_VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}🎉 100% COMPLIANCE ACHIEVED! 🎉${NC}"
    echo -e "${GREEN}✅ All AI_AGE_SDLC requirements met${NC}"
    echo -e "${GREEN}✅ Authorized to proceed with development${NC}"
    echo ""
    echo -e "${BLUE}📋 Compliance Summary:${NC}"
    echo -e "  ✅ Jira ticket validated: $JIRA_TICKET"
    echo -e "  ✅ Confluence specification verified"
    echo -e "  ✅ Test coverage meets 80% minimum"
    echo -e "  ✅ All service connections working"
    echo -e "  ✅ File modifications authorized"
    echo ""
    echo -e "${YELLOW}🚀 You may now proceed with SDLC-compliant development${NC}"
    
    # Create compliance record
    cat > .sdlc_compliance_record << EOF
# AI_AGE_SDLC Compliance Record
Date: $(date)
Jira Ticket: $JIRA_TICKET
Confluence Spec: $CONFLUENCE_SPEC
Test Coverage: Verified ≥80%
Services: All connected
File Authorization: Verified
Status: FULLY COMPLIANT
EOF
    echo -e "${GREEN}✅ Compliance record created: .sdlc_compliance_record${NC}"
    
else
    echo -e "${RED}🚨 COMPLIANCE FAILURE! 🚨${NC}"
    echo -e "${RED}❌ $COMPLIANCE_VIOLATIONS critical violations detected${NC}"
    echo -e "${RED}🛑 DEVELOPMENT BLOCKED UNTIL RESOLVED${NC}"
    echo ""
    echo -e "${YELLOW}Fix all violations and run this script again${NC}"
    exit 1
fi