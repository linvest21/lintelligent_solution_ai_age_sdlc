#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}    🔌 TESTING ALL PHYSICAL CONNECTIONS    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
  echo -e "${RED}❌ ERROR: .env file not found!${NC}"
  echo ""
  echo "Please create .env file:"
  echo "  cp .env.template .env"
  echo "  nano .env"
  echo ""
  exit 1
fi

# Load environment variables
source .env

# Function to mask tokens for display
mask_token() {
  local token=$1
  if [ -z "$token" ]; then
    echo "(not set)"
  else
    echo "${token:0:10}...${token: -4}"
  fi
}

# Display configuration
echo -e "${YELLOW}📋 Current Configuration:${NC}"
echo "├─ Jira URL: ${JIRA_URL:-❌ NOT SET}"
echo "├─ Jira Email: ${JIRA_EMAIL:-❌ NOT SET}"
echo "├─ Jira Token: $(mask_token "$JIRA_API_TOKEN")"
echo "├─ Confluence URL: ${CONFLUENCE_URL:-❌ NOT SET}"
echo "├─ GitHub Owner: ${GITHUB_OWNER:-❌ NOT SET}"
echo "├─ GitHub Repo: ${GITHUB_REPO:-❌ NOT SET}"
echo "└─ GitHub Token: $(mask_token "$GITHUB_TOKEN")"
echo ""

# Test results
JIRA_OK=false
CONFLUENCE_OK=false
GITHUB_OK=false

# Test Jira Connection
echo -e "${YELLOW}1. Testing Jira Connection...${NC}"
if [ -z "$JIRA_URL" ] || [ -z "$JIRA_EMAIL" ] || [ -z "$JIRA_API_TOKEN" ]; then
  echo -e "   ${RED}❌ Missing Jira credentials${NC}"
else
  JIRA_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
    -X GET \
    "${JIRA_URL}/rest/api/2/myself" \
    -H "Accept: application/json" 2>/dev/null)
  
  HTTP_CODE=$(echo "$JIRA_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
  BODY=$(echo "$JIRA_RESPONSE" | grep -v "HTTP_CODE:")
  
  if [ "$HTTP_CODE" = "200" ]; then
    USER_NAME=$(echo "$BODY" | grep -o '"displayName":"[^"]*' | cut -d'"' -f4)
    echo -e "   ${GREEN}✅ Connected as: $USER_NAME${NC}"
    echo -e "   ${GREEN}   Endpoint: ${JIRA_URL}${NC}"
    JIRA_OK=true
  elif [ "$HTTP_CODE" = "401" ]; then
    echo -e "   ${RED}❌ Authentication failed (401)${NC}"
    echo "      Check your API token and email"
  elif [ "$HTTP_CODE" = "404" ]; then
    echo -e "   ${RED}❌ URL not found (404)${NC}"
    echo "      Check JIRA_URL: ${JIRA_URL}"
  else
    echo -e "   ${RED}❌ Connection failed (HTTP $HTTP_CODE)${NC}"
    echo "      Response: $(echo "$BODY" | head -1)"
  fi
fi
echo ""

# Test Confluence Connection
echo -e "${YELLOW}2. Testing Confluence Connection...${NC}"
if [ -z "$CONFLUENCE_URL" ] || [ -z "$CONFLUENCE_EMAIL" ] || [ -z "$CONFLUENCE_API_TOKEN" ]; then
  echo -e "   ${RED}❌ Missing Confluence credentials${NC}"
else
  CONF_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
    -X GET \
    "${CONFLUENCE_URL}/rest/api/space?limit=1" \
    -H "Accept: application/json" 2>/dev/null)
  
  HTTP_CODE=$(echo "$CONF_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
  BODY=$(echo "$CONF_RESPONSE" | grep -v "HTTP_CODE:")
  
  if [ "$HTTP_CODE" = "200" ]; then
    SPACE_COUNT=$(echo "$BODY" | grep -o '"key":"[^"]*' | wc -l)
    echo -e "   ${GREEN}✅ Connected - Found $SPACE_COUNT space(s)${NC}"
    echo -e "   ${GREEN}   Endpoint: ${CONFLUENCE_URL}${NC}"
    CONFLUENCE_OK=true
  elif [ "$HTTP_CODE" = "401" ]; then
    echo -e "   ${RED}❌ Authentication failed (401)${NC}"
    echo "      Check your API token (same as Jira)"
  elif [ "$HTTP_CODE" = "404" ]; then
    echo -e "   ${RED}❌ URL not found (404)${NC}"
    echo "      Check CONFLUENCE_URL: ${CONFLUENCE_URL}"
  else
    echo -e "   ${RED}❌ Connection failed (HTTP $HTTP_CODE)${NC}"
  fi
fi
echo ""

# Test GitHub Connection
echo -e "${YELLOW}3. Testing GitHub Connection...${NC}"
if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "   ${RED}❌ Missing GitHub token${NC}"
else
  GH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    https://api.github.com/user 2>/dev/null)
  
  HTTP_CODE=$(echo "$GH_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
  BODY=$(echo "$GH_RESPONSE" | grep -v "HTTP_CODE:")
  
  if [ "$HTTP_CODE" = "200" ]; then
    GH_USER=$(echo "$BODY" | grep -o '"login":"[^"]*' | cut -d'"' -f4)
    echo -e "   ${GREEN}✅ Connected as: $GH_USER${NC}"
    
    # Test repository access
    if [ ! -z "$GITHUB_OWNER" ] && [ ! -z "$GITHUB_REPO" ]; then
      REPO_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}" 2>/dev/null)
      
      REPO_CODE=$(echo "$REPO_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
      if [ "$REPO_CODE" = "200" ]; then
        echo -e "   ${GREEN}   Repository: ${GITHUB_OWNER}/${GITHUB_REPO} ✓${NC}"
      else
        echo -e "   ${YELLOW}   Repository: ${GITHUB_OWNER}/${GITHUB_REPO} (not accessible)${NC}"
      fi
    fi
    GITHUB_OK=true
  elif [ "$HTTP_CODE" = "401" ]; then
    echo -e "   ${RED}❌ Invalid token (401)${NC}"
    echo "      Create new token at: https://github.com/settings/tokens"
  else
    echo -e "   ${RED}❌ Connection failed (HTTP $HTTP_CODE)${NC}"
  fi
fi
echo ""

# Test Git Configuration
echo -e "${YELLOW}4. Checking Git Configuration...${NC}"
GIT_USER=$(git config user.name 2>/dev/null)
GIT_EMAIL=$(git config user.email 2>/dev/null)

if [ ! -z "$GIT_USER" ] && [ ! -z "$GIT_EMAIL" ]; then
  echo -e "   ${GREEN}✅ Git configured${NC}"
  echo -e "      User: $GIT_USER"
  echo -e "      Email: $GIT_EMAIL"
else
  echo -e "   ${YELLOW}⚠️  Git not fully configured${NC}"
  if [ -z "$GIT_USER" ]; then
    echo "      Run: git config user.name \"Your Name\""
  fi
  if [ -z "$GIT_EMAIL" ]; then
    echo "      Run: git config user.email \"you@example.com\""
  fi
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}                 SUMMARY                    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"

ALL_OK=true

if [ "$JIRA_OK" = true ]; then
  echo -e "  Jira:       ${GREEN}✅ CONNECTED${NC}"
else
  echo -e "  Jira:       ${RED}❌ NOT CONNECTED${NC}"
  ALL_OK=false
fi

if [ "$CONFLUENCE_OK" = true ]; then
  echo -e "  Confluence: ${GREEN}✅ CONNECTED${NC}"
else
  echo -e "  Confluence: ${RED}❌ NOT CONNECTED${NC}"
  ALL_OK=false
fi

if [ "$GITHUB_OK" = true ]; then
  echo -e "  GitHub:     ${GREEN}✅ CONNECTED${NC}"
else
  echo -e "  GitHub:     ${RED}❌ NOT CONNECTED${NC}"
  ALL_OK=false
fi

echo ""

if [ "$ALL_OK" = true ]; then
  echo -e "${GREEN}🎉 ALL CONNECTIONS SUCCESSFUL!${NC}"
  echo -e "${GREEN}You're ready to use the development lifecycle system.${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Create a Jira ticket in status 'In Progress'"
  echo "2. Create a Confluence spec page and link it"
  echo "3. Tell Claude: 'Work on [TICKET-ID]'"
else
  echo -e "${RED}⚠️  Some connections failed.${NC}"
  echo ""
  echo "To fix:"
  echo "1. Edit .env file with correct credentials"
  echo "2. For Jira/Confluence: Get API token from"
  echo "   https://id.atlassian.com/manage-profile/security/api-tokens"
  echo "3. For GitHub: Get token from"
  echo "   https://github.com/settings/tokens"
  echo "4. Run this script again to verify"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"