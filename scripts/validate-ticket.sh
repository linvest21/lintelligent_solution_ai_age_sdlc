#!/bin/bash

# Load environment variables
source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating Jira Ticket and Confluence Specification..."

# Check if ticket ID is provided
if [ -z "$1" ]; then
  echo -e "${RED}❌ Error: No Jira ticket ID provided${NC}"
  echo "Usage: ./validate-ticket.sh PROJ-123"
  exit 1
fi

TICKET_ID=$1

# Validate Jira ticket exists and get details
echo "📋 Checking Jira ticket: $TICKET_ID"
TICKET_RESPONSE=$(curl -s -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
  -X GET \
  -H "Content-Type: application/json" \
  ${JIRA_URL}/rest/api/2/issue/${TICKET_ID})

if echo "$TICKET_RESPONSE" | grep -q "errorMessages"; then
  echo -e "${RED}❌ Jira ticket $TICKET_ID not found or access denied${NC}"
  exit 1
fi

# Extract ticket details
TICKET_STATUS=$(echo "$TICKET_RESPONSE" | jq -r '.fields.status.name')
TICKET_ASSIGNEE=$(echo "$TICKET_RESPONSE" | jq -r '.fields.assignee.emailAddress')
TICKET_SUMMARY=$(echo "$TICKET_RESPONSE" | jq -r '.fields.summary')

echo -e "${GREEN}✅ Ticket found: $TICKET_SUMMARY${NC}"
echo "   Status: $TICKET_STATUS"
echo "   Assignee: $TICKET_ASSIGNEE"

# Check if ticket is in correct status
if [[ "$TICKET_STATUS" != "In Progress" && "$TICKET_STATUS" != "Development" ]]; then
  echo -e "${YELLOW}⚠️  Warning: Ticket status is '$TICKET_STATUS', expected 'In Progress' or 'Development'${NC}"
fi

# Look for Confluence link in ticket
echo ""
echo "📄 Looking for Confluence specification..."

# Try to find Confluence URL in description or comments
CONFLUENCE_LINKS=$(echo "$TICKET_RESPONSE" | jq -r '.. | select(type=="string") | select(contains("confluence"))' | grep -o 'https://[^"]*confluence[^"]*' | head -1)

if [ -z "$CONFLUENCE_LINKS" ]; then
  echo -e "${RED}❌ No Confluence specification found in ticket${NC}"
  echo "Please ensure a Confluence spec is linked to the ticket"
  exit 1
fi

echo -e "${GREEN}✅ Confluence specification found: $CONFLUENCE_LINKS${NC}"

# Extract page ID from Confluence URL
PAGE_ID=$(echo "$CONFLUENCE_LINKS" | grep -o 'pageId=[0-9]*' | cut -d'=' -f2)
if [ -z "$PAGE_ID" ]; then
  PAGE_ID=$(echo "$CONFLUENCE_LINKS" | grep -o '/pages/[0-9]*' | grep -o '[0-9]*')
fi

if [ ! -z "$PAGE_ID" ]; then
  echo "   Fetching Confluence page ID: $PAGE_ID"
  
  # Get Confluence page content
  CONF_RESPONSE=$(curl -s -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
    -X GET \
    -H "Content-Type: application/json" \
    ${CONFLUENCE_URL}/rest/api/content/${PAGE_ID}?expand=body.storage)
  
  if echo "$CONF_RESPONSE" | grep -q "title"; then
    CONF_TITLE=$(echo "$CONF_RESPONSE" | jq -r '.title')
    echo -e "${GREEN}✅ Specification retrieved: $CONF_TITLE${NC}"
    
    # Save specification locally
    echo "$CONF_RESPONSE" | jq -r '.body.storage.value' > "spec_${TICKET_ID}.html"
    echo "   Specification saved to: spec_${TICKET_ID}.html"
  else
    echo -e "${YELLOW}⚠️  Could not fetch Confluence content${NC}"
  fi
fi

# Create project config file
cat > project_config.json << EOF
{
  "ticket_id": "$TICKET_ID",
  "ticket_summary": "$TICKET_SUMMARY",
  "ticket_status": "$TICKET_STATUS",
  "ticket_assignee": "$TICKET_ASSIGNEE",
  "confluence_url": "$CONFLUENCE_LINKS",
  "confluence_page_id": "$PAGE_ID",
  "timestamp": "$(date -Iseconds)",
  "validation_passed": true
}
EOF

echo ""
echo -e "${GREEN}✅ Validation complete! Project configuration saved to project_config.json${NC}"
echo ""
echo "Next steps:"
echo "1. Review the specification in spec_${TICKET_ID}.html"
echo "2. Run ./scripts/init-development.sh to start development"