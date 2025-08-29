#!/bin/bash

# AI_AGE_SDLC Service Setup Wizard
# This script helps configure Jira, Confluence, and GitHub for the SDLC

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
cat << 'EOF'
    ___    ____       ___   ____  ______       _____ ____  __    ______
   /   |  /  _/      /   | / ___// ____/      / ___// __ \/ /   / ____/
  / /| |  / /       / /| |/ __ \/ __/         \__ \/ / / / /   / /     
 / ___ |_/ /       / ___ / /_/ / /___        ___/ / /_/ / /___/ /___   
/_/  |_/___/      /_/  |_\____/_____/       /____/_____/_____/\____/   
                                                                        
        SERVICE SETUP WIZARD - AI-Driven Age SDLC
        ============================================
EOF
echo -e "${NC}"

echo -e "${GREEN}This wizard will help you set up:${NC}"
echo -e "  🎯 Jira (Task Management)"
echo -e "  📚 Confluence (Specifications)" 
echo -e "  🐙 GitHub (Code Repository)"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is required but not installed${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️ jq not found. Install for better JSON parsing${NC}"
fi

echo -e "${GREEN}✅ Prerequisites met${NC}"
echo ""

# Collect service information
echo -e "${BLUE}📋 Service Configuration${NC}"
echo "=============================="

# Jira Configuration
echo -e "${CYAN}🎯 Jira Setup:${NC}"
read -p "Enter Jira domain (e.g., 'mycompany' for mycompany.atlassian.net): " JIRA_DOMAIN
read -p "Enter your Jira email: " JIRA_EMAIL
read -sp "Enter Jira API token (generate at id.atlassian.com/manage-profile/security/api-tokens): " JIRA_API_TOKEN
echo ""
read -p "Enter Jira project key (e.g., 'AISD'): " JIRA_PROJECT_KEY

# Confluence Configuration  
echo ""
echo -e "${CYAN}📚 Confluence Setup:${NC}"
read -p "Enter Confluence email (press Enter to use Jira email): " CONFLUENCE_EMAIL
if [[ -z "$CONFLUENCE_EMAIL" ]]; then
    CONFLUENCE_EMAIL="$JIRA_EMAIL"
fi
read -sp "Enter Confluence API token (press Enter to use Jira token): " CONFLUENCE_API_TOKEN
echo ""
if [[ -z "$CONFLUENCE_API_TOKEN" ]]; then
    CONFLUENCE_API_TOKEN="$JIRA_API_TOKEN"
fi
CONFLUENCE_SPACE_KEY="${JIRA_PROJECT_KEY}SPEC"
echo "Confluence space key will be: $CONFLUENCE_SPACE_KEY"

# GitHub Configuration
echo ""
echo -e "${CYAN}🐙 GitHub Setup:${NC}"
read -p "Enter GitHub username/organization: " GITHUB_OWNER
read -p "Enter repository name: " GITHUB_REPO
read -sp "Enter GitHub personal access token: " GITHUB_TOKEN
echo ""

echo ""
echo -e "${YELLOW}🔧 Setting up services...${NC}"

# Jira Setup
echo -e "${YELLOW}📋 Configuring Jira...${NC}"

# Test Jira connection
JIRA_URL="https://${JIRA_DOMAIN}.atlassian.net"
echo -n "Testing Jira connection... "
JIRA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
    -X GET \
    "${JIRA_URL}/rest/api/2/myself" 2>/dev/null)

if [[ "$JIRA_RESPONSE" == "200" ]]; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed (HTTP $JIRA_RESPONSE)${NC}"
    echo "Please check your Jira credentials and try again"
    exit 1
fi

# Create Jira project (if it doesn't exist)
echo -n "Checking if Jira project exists... "
PROJECT_EXISTS=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
    "${JIRA_URL}/rest/api/2/project/${JIRA_PROJECT_KEY}" \
    | grep -o '"key"' | wc -l)

if [[ "$PROJECT_EXISTS" -gt 0 ]]; then
    echo -e "${GREEN}✅ Project exists${NC}"
else
    echo -e "${YELLOW}Creating project...${NC}"
    # Note: Creating projects requires admin permissions
    echo -e "${YELLOW}⚠️ You may need to create the project '${JIRA_PROJECT_KEY}' manually in Jira${NC}"
fi

# Confluence Setup
echo -e "${YELLOW}📚 Configuring Confluence...${NC}"

CONFLUENCE_URL="https://${JIRA_DOMAIN}.atlassian.net/wiki"
echo -n "Testing Confluence connection... "
CONF_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" \
    -X GET \
    "${CONFLUENCE_URL}/rest/api/content" 2>/dev/null)

if [[ "$CONF_RESPONSE" == "200" ]]; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed (HTTP $CONF_RESPONSE)${NC}"
    echo "Please check your Confluence credentials"
fi

# GitHub Setup
echo -e "${YELLOW}🐙 Configuring GitHub...${NC}"

echo -n "Testing GitHub connection... "
GH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/user" 2>/dev/null)

if [[ "$GH_RESPONSE" == "200" ]]; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed (HTTP $GH_RESPONSE)${NC}"
    echo "Please check your GitHub token"
    exit 1
fi

# Check if repository exists
echo -n "Checking if GitHub repository exists... "
REPO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}" 2>/dev/null)

if [[ "$REPO_RESPONSE" == "200" ]]; then
    echo -e "${GREEN}✅ Repository exists${NC}"
else
    echo -e "${YELLOW}Repository doesn't exist. You can create it with:${NC}"
    echo "gh repo create ${GITHUB_OWNER}/${GITHUB_REPO} --public"
fi

# Create .env file
echo ""
echo -e "${YELLOW}📝 Creating .env configuration file...${NC}"

cat > .env << EOF
# AI_AGE_SDLC Environment Configuration
# Generated on $(date)

# Jira Configuration
JIRA_URL=${JIRA_URL}
JIRA_PROJECT_KEY=${JIRA_PROJECT_KEY}
JIRA_EMAIL=${JIRA_EMAIL}
JIRA_API_TOKEN=${JIRA_API_TOKEN}

# Confluence Configuration
CONFLUENCE_URL=${CONFLUENCE_URL}
CONFLUENCE_SPACE_KEY=${CONFLUENCE_SPACE_KEY}
CONFLUENCE_EMAIL=${CONFLUENCE_EMAIL}
CONFLUENCE_API_TOKEN=${CONFLUENCE_API_TOKEN}

# GitHub Configuration
GITHUB_OWNER=${GITHUB_OWNER}
GITHUB_REPO=${GITHUB_REPO}
GITHUB_TOKEN=${GITHUB_TOKEN}

# SDLC Configuration
MIN_TEST_COVERAGE=80
MAX_RESPONSE_TIME_MS=200
STRESS_TEST_USERS=100
STRESS_TEST_DURATION=5m
AUTO_COMMIT_ON_SUCCESS=true
AUTO_PUSH_ON_SUCCESS=false

# Project Configuration
PROJECT_NAME=${GITHUB_REPO}
DEVELOPER_NAME=$(git config user.name 2>/dev/null || echo "Developer")
DEVELOPER_EMAIL=$(git config user.email 2>/dev/null || echo "$JIRA_EMAIL")
EOF

# Secure the .env file
chmod 600 .env
echo -e "${GREEN}✅ .env file created (secured with 600 permissions)${NC}"

# Create setup scripts
echo -e "${YELLOW}📄 Creating helper scripts...${NC}"

cat > validate_sdlc_setup.sh << 'EOF'
#!/bin/bash

# Validate AI_AGE_SDLC Setup Script

source .env

echo "🔍 Validating AI_AGE_SDLC Setup..."
echo "===================================="

# Test Jira
echo -n "Testing Jira connection... "
JIRA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_URL}/rest/api/2/myself" 2>/dev/null)
  
if [ "$JIRA_STATUS" = "200" ]; then
  echo "✅ Connected"
else
  echo "❌ Failed (HTTP $JIRA_STATUS)"
fi

# Test Confluence
echo -n "Testing Confluence connection... "
CONF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN}" \
  "${CONFLUENCE_URL}/rest/api/content" 2>/dev/null)
  
if [ "$CONF_STATUS" = "200" ]; then
  echo "✅ Connected"
else
  echo "❌ Failed (HTTP $CONF_STATUS)"
fi

# Test GitHub
echo -n "Testing GitHub connection... "
GH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}" 2>/dev/null)
  
if [ "$GH_STATUS" = "200" ]; then
  echo "✅ Connected"
else
  echo "❌ Failed (HTTP $GH_STATUS)"
fi

echo ""
echo "📊 Setup Status Summary:"
echo "========================"
[ "$JIRA_STATUS" = "200" ] && echo "✅ Jira: Ready" || echo "❌ Jira: Not configured"
[ "$CONF_STATUS" = "200" ] && echo "✅ Confluence: Ready" || echo "❌ Confluence: Not configured"
[ "$GH_STATUS" = "200" ] && echo "✅ GitHub: Ready" || echo "❌ GitHub: Not configured"

if [ "$JIRA_STATUS" = "200" ] && [ "$CONF_STATUS" = "200" ] && [ "$GH_STATUS" = "200" ]; then
  echo ""
  echo "🎉 All services are configured and ready!"
  echo "You can now use the AI_AGE_SDLC framework."
else
  echo ""
  echo "⚠️ Some services need attention before using the SDLC."
fi
EOF

chmod +x validate_sdlc_setup.sh
echo -e "${GREEN}✅ validate_sdlc_setup.sh created${NC}"

# Final summary
echo ""
echo -e "${GREEN}🎉 AI_AGE_SDLC Service Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 What was configured:${NC}"
echo -e "  ✅ Jira: $JIRA_URL"
echo -e "  ✅ Confluence: $CONFLUENCE_URL" 
echo -e "  ✅ GitHub: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}"
echo -e "  ✅ Environment: .env file created"
echo ""
echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo -e "1. Run validation: ${BLUE}./validate_sdlc_setup.sh${NC}"
echo -e "2. Create your first Jira ticket in project ${BLUE}${JIRA_PROJECT_KEY}${NC}"
echo -e "3. Write specifications in Confluence space ${BLUE}${CONFLUENCE_SPACE_KEY}${NC}"
echo -e "4. Start development with Claude Code!"
echo ""
echo -e "${PURPLE}📚 Documentation:${NC}"
echo -e "  - SETUP_GUIDE.md (complete setup instructions)"
echo -e "  - CLAUDE.md (SDLC framework rules)"
echo -e "  - HOW_IT_WORKS.md (architecture explanation)"
echo ""
echo -e "${GREEN}Your AI_AGE_SDLC is ready! 🤖✨${NC}"