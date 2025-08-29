#!/bin/bash

# Claude Setup Validator - Used by Claude Code to verify setup
# This script is called automatically by Claude before any development work

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if .env exists and has required variables
check_env_file() {
    if [[ ! -f ".env" ]]; then
        echo -e "${RED}❌ SETUP FAILURE: No .env file found${NC}"
        echo -e "${YELLOW}Run: ./setup_sdlc_services.sh${NC}"
        return 1
    fi
    
    source .env
    
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
    
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo -e "${RED}❌ SETUP FAILURE: Missing $var in .env${NC}"
            echo -e "${YELLOW}Run: ./setup_sdlc_services.sh${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}✅ Environment variables configured${NC}"
    return 0
}

# Function to test service connections
test_service_connections() {
    local failures=0
    
    # Test Jira
    echo -n "Testing Jira connection... "
    if curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" "${JIRA_URL}/rest/api/2/myself" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Connected${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
        ((failures++))
    fi
    
    # Test Confluence
    echo -n "Testing Confluence connection... "
    if curl -s -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" "${CONFLUENCE_URL}/rest/api/content" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Connected${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
        ((failures++))
    fi
    
    # Test GitHub
    echo -n "Testing GitHub connection... "
    if curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/user" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Connected${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
        ((failures++))
    fi
    
    if [[ $failures -gt 0 ]]; then
        echo -e "${RED}❌ SETUP FAILURE: $failures service(s) not accessible${NC}"
        echo -e "${YELLOW}Run: ./setup_sdlc_services.sh${NC}"
        return 1
    fi
    
    return 0
}

# Function to validate Jira ticket
validate_jira_ticket() {
    local ticket_id="$1"
    
    if [[ -z "$ticket_id" ]]; then
        echo -e "${RED}❌ No Jira ticket provided${NC}"
        echo -e "${YELLOW}Please provide a Jira ticket ID (e.g., AISD-123)${NC}"
        return 1
    fi
    
    echo -n "Validating Jira ticket $ticket_id... "
    
    local response
    response=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X GET \
        "${JIRA_URL}/rest/api/2/issue/${ticket_id}" 2>/dev/null)
    
    if echo "$response" | grep -q '"key"'; then
        local status assignee
        status=$(echo "$response" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        assignee=$(echo "$response" | grep -o '"displayName":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        echo -e "${GREEN}✅ Valid${NC}"
        echo -e "  Status: $status"
        echo -e "  Assignee: $assignee"
        
        # Check if in appropriate state for development
        if [[ "$status" != *"Progress"* ]] && [[ "$status" != *"Development"* ]] && [[ "$status" != *"In Progress"* ]]; then
            echo -e "${YELLOW}⚠️ Warning: Ticket may not be ready for development${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Invalid or inaccessible ticket${NC}"
        return 1
    fi
}

# Function to get and validate Confluence spec from Jira ticket
get_confluence_spec() {
    local ticket_id="$1"
    
    echo -n "Fetching Confluence link from Jira ticket... "
    
    local response
    response=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X GET \
        "${JIRA_URL}/rest/api/2/issue/${ticket_id}?expand=description" 2>/dev/null)
    
    # Look for Confluence links in the description
    local confluence_links
    confluence_links=$(echo "$response" | grep -o 'https://[^"]*confluence[^"]*pages/[0-9]*' || echo "")
    
    if [[ -z "$confluence_links" ]]; then
        echo -e "${RED}❌ No Confluence link found in ticket${NC}"
        echo -e "${YELLOW}Please add Confluence specification link to Jira ticket${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Found specification link${NC}"
    
    # Validate the Confluence page
    local page_url="$confluence_links"
    local page_id
    if [[ "$page_url" =~ pages/([0-9]+) ]]; then
        page_id="${BASH_REMATCH[1]}"
    else
        echo -e "${RED}❌ Invalid Confluence URL format${NC}"
        return 1
    fi
    
    echo -n "Validating Confluence specification... "
    local spec_response
    spec_response=$(curl -s -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" \
        -X GET \
        "${CONFLUENCE_URL}/rest/api/content/${page_id}" 2>/dev/null)
    
    if echo "$spec_response" | grep -q '"title"'; then
        local title
        title=$(echo "$spec_response" | grep -o '"title":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}✅ Valid specification: $title${NC}"
        echo -e "  URL: $page_url"
        return 0
    else
        echo -e "${RED}❌ Cannot access Confluence specification${NC}"
        return 1
    fi
}

# Main function for Claude to call
claude_validate_setup() {
    local ticket_id="$1"
    
    echo "🔍 AI_AGE_SDLC Setup Validation for Claude"
    echo "========================================"
    
    # Step 1: Check environment setup
    if ! check_env_file; then
        echo -e "${RED}🛑 BLOCKING: Setup incomplete${NC}"
        exit 1
    fi
    
    # Step 2: Test service connections
    if ! test_service_connections; then
        echo -e "${RED}🛑 BLOCKING: Services not accessible${NC}"
        exit 1
    fi
    
    # Step 3: Validate Jira ticket if provided
    if [[ -n "$ticket_id" ]]; then
        if ! validate_jira_ticket "$ticket_id"; then
            echo -e "${RED}🛑 BLOCKING: Invalid Jira ticket${NC}"
            exit 1
        fi
        
        # Step 4: Get and validate Confluence spec
        if ! get_confluence_spec "$ticket_id"; then
            echo -e "${RED}🛑 BLOCKING: Missing or invalid Confluence specification${NC}"
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}🎉 ALL VALIDATION PASSED${NC}"
    echo -e "${GREEN}✅ Claude is authorized to proceed with development${NC}"
    
    return 0
}

# If script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    claude_validate_setup "$1"
fi