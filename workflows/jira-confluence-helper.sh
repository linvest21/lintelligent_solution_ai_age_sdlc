#!/bin/bash

# Jira and Confluence helper utilities
# Provides easy-to-use functions for API interactions

source ./load_env.sh

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to fetch Jira ticket details
fetch_jira_ticket() {
    local TICKET_ID="${1:-$CURRENT_TICKET}"
    
    if [ -z "$TICKET_ID" ]; then
        echo -e "${RED}Error: No ticket ID provided${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Fetching Jira ticket $TICKET_ID...${NC}"
    
    RESPONSE=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X GET \
        -H "Content-Type: application/json" \
        "${JIRA_URL}/rest/api/2/issue/${TICKET_ID}")
    
    if echo "$RESPONSE" | grep -q '"errorMessages"'; then
        echo -e "${RED}Error fetching ticket:${NC}"
        echo "$RESPONSE" | grep -o '"errorMessages":\[[^]]*' | sed 's/.*\["\(.*\)".*/\1/'
        return 1
    fi
    
    # Parse and display ticket info
    STATUS=$(echo "$RESPONSE" | grep -o '"status"[^}]*' | grep -o '"name":"[^"]*' | cut -d'"' -f4)
    SUMMARY=$(echo "$RESPONSE" | grep -o '"summary":"[^"]*' | cut -d'"' -f4)
    ASSIGNEE=$(echo "$RESPONSE" | grep -o '"assignee"[^}]*' | grep -o '"displayName":"[^"]*' | cut -d'"' -f4)
    
    echo -e "${GREEN}Ticket Details:${NC}"
    echo "  ID: $TICKET_ID"
    echo "  Summary: $SUMMARY"
    echo "  Status: $STATUS"
    echo "  Assignee: ${ASSIGNEE:-Unassigned}"
    
    # Save to file for reference
    echo "$RESPONSE" > "jira_${TICKET_ID}.json"
    echo -e "${BLUE}Full response saved to jira_${TICKET_ID}.json${NC}"
}

# Function to update Jira ticket status
update_jira_status() {
    local TICKET_ID="${1:-$CURRENT_TICKET}"
    local NEW_STATUS="$2"
    
    if [ -z "$TICKET_ID" ] || [ -z "$NEW_STATUS" ]; then
        echo -e "${RED}Usage: update_jira_status TICKET_ID STATUS${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Updating $TICKET_ID to status: $NEW_STATUS${NC}"
    
    # Get transition ID for the status
    TRANSITIONS=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X GET \
        "${JIRA_URL}/rest/api/2/issue/${TICKET_ID}/transitions")
    
    TRANSITION_ID=$(echo "$TRANSITIONS" | grep -B2 "\"name\":\"$NEW_STATUS\"" | grep '"id"' | head -1 | grep -o '[0-9]*')
    
    if [ -z "$TRANSITION_ID" ]; then
        echo -e "${RED}Error: Cannot transition to status '$NEW_STATUS'${NC}"
        echo "Available transitions:"
        echo "$TRANSITIONS" | grep -o '"name":"[^"]*' | cut -d'"' -f4
        return 1
    fi
    
    # Perform the transition
    RESPONSE=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"transition\":{\"id\":\"$TRANSITION_ID\"}}" \
        "${JIRA_URL}/rest/api/2/issue/${TICKET_ID}/transitions")
    
    if [ -z "$RESPONSE" ]; then
        echo -e "${GREEN}✅ Status updated successfully${NC}"
    else
        echo -e "${RED}Error updating status${NC}"
    fi
}

# Function to fetch Confluence page
fetch_confluence_spec() {
    local PAGE_ID="${1:-$CONFLUENCE_SPEC_ID}"
    
    if [ -z "$PAGE_ID" ]; then
        echo -e "${RED}Error: No Confluence page ID provided${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Fetching Confluence page $PAGE_ID...${NC}"
    
    RESPONSE=$(curl -s -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" \
        -X GET \
        -H "Content-Type: application/json" \
        "${CONFLUENCE_URL}/rest/api/content/${PAGE_ID}?expand=body.storage")
    
    if echo "$RESPONSE" | grep -q '"statusCode":404'; then
        echo -e "${RED}Error: Page not found${NC}"
        return 1
    fi
    
    # Extract and save content
    TITLE=$(echo "$RESPONSE" | grep -o '"title":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}Page Title: $TITLE${NC}"
    
    # Extract HTML content and convert to markdown (basic conversion)
    echo "$RESPONSE" | grep -o '"value":".*"' | sed 's/"value":"//;s/",$//' | sed 's/\\"/"/g' > "confluence_${PAGE_ID}.html"
    
    # Basic HTML to Markdown conversion
    cat "confluence_${PAGE_ID}.html" | \
        sed 's/<h1[^>]*>/# /g' | \
        sed 's/<h2[^>]*>/## /g' | \
        sed 's/<h3[^>]*>/### /g' | \
        sed 's/<\/h[1-3]>//g' | \
        sed 's/<p[^>]*>//g' | \
        sed 's/<\/p>/\n/g' | \
        sed 's/<ul[^>]*>//g' | \
        sed 's/<\/ul>//g' | \
        sed 's/<li[^>]*>/- /g' | \
        sed 's/<\/li>//g' | \
        sed 's/<[^>]*>//g' > "confluence_${PAGE_ID}.md"
    
    echo -e "${BLUE}Content saved to:${NC}"
    echo "  - confluence_${PAGE_ID}.html (original)"
    echo "  - confluence_${PAGE_ID}.md (markdown)"
}

# Function to create Confluence page
create_confluence_page() {
    local TITLE="$1"
    local CONTENT="$2"
    local SPACE_KEY="${3:-DEV}"
    
    if [ -z "$TITLE" ] || [ -z "$CONTENT" ]; then
        echo -e "${RED}Usage: create_confluence_page \"Title\" \"Content\" [SPACE_KEY]${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Creating Confluence page: $TITLE${NC}"
    
    # Escape content for JSON
    ESCAPED_CONTENT=$(echo "$CONTENT" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    RESPONSE=$(curl -s -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"page\",
            \"title\": \"$TITLE\",
            \"space\": {\"key\": \"$SPACE_KEY\"},
            \"body\": {
                \"storage\": {
                    \"value\": \"$ESCAPED_CONTENT\",
                    \"representation\": \"storage\"
                }
            }
        }" \
        "${CONFLUENCE_URL}/rest/api/content")
    
    PAGE_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    
    if [ -n "$PAGE_ID" ]; then
        echo -e "${GREEN}✅ Page created successfully${NC}"
        echo "  Page ID: $PAGE_ID"
        echo "  URL: ${CONFLUENCE_URL}/spaces/${SPACE_KEY}/pages/${PAGE_ID}"
    else
        echo -e "${RED}Error creating page${NC}"
        echo "$RESPONSE"
    fi
}

# Function to add comment to Jira ticket
add_jira_comment() {
    local TICKET_ID="${1:-$CURRENT_TICKET}"
    local COMMENT="$2"
    
    if [ -z "$TICKET_ID" ] || [ -z "$COMMENT" ]; then
        echo -e "${RED}Usage: add_jira_comment TICKET_ID \"Comment\"${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Adding comment to $TICKET_ID...${NC}"
    
    RESPONSE=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"body\": \"$COMMENT\"}" \
        "${JIRA_URL}/rest/api/2/issue/${TICKET_ID}/comment")
    
    if echo "$RESPONSE" | grep -q '"id"'; then
        echo -e "${GREEN}✅ Comment added successfully${NC}"
    else
        echo -e "${RED}Error adding comment${NC}"
    fi
}

# Main menu
if [ "$1" = "" ]; then
    echo -e "${BLUE}Jira/Confluence Helper Utilities${NC}"
    echo ""
    echo "Usage:"
    echo "  ./jira-confluence-helper.sh fetch-ticket [TICKET_ID]"
    echo "  ./jira-confluence-helper.sh update-status [TICKET_ID] STATUS"
    echo "  ./jira-confluence-helper.sh fetch-spec [PAGE_ID]"
    echo "  ./jira-confluence-helper.sh create-page \"Title\" \"Content\" [SPACE]"
    echo "  ./jira-confluence-helper.sh add-comment [TICKET_ID] \"Comment\""
    echo ""
    echo "Environment variables used:"
    echo "  CURRENT_TICKET: $CURRENT_TICKET"
    echo "  CONFLUENCE_SPEC_ID: $CONFLUENCE_SPEC_ID"
else
    case "$1" in
        fetch-ticket)
            fetch_jira_ticket "$2"
            ;;
        update-status)
            update_jira_status "$2" "$3"
            ;;
        fetch-spec)
            fetch_confluence_spec "$2"
            ;;
        create-page)
            create_confluence_page "$2" "$3" "$4"
            ;;
        add-comment)
            add_jira_comment "$2" "$3"
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            ;;
    esac
fi