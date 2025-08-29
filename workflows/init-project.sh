#!/bin/bash

# Project initialization script
# Sets up a new development session with full lifecycle compliance

source ./load_env.sh

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   PROJECT LIFECYCLE INITIALIZATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Step 1: Get Jira ticket
echo -e "${YELLOW}Step 1: Jira Ticket Configuration${NC}"
if [ -z "$CURRENT_TICKET" ]; then
    read -p "Enter Jira ticket ID (e.g., PROJ-123): " TICKET_INPUT
    
    # Update .env file
    sed -i "s/^CURRENT_TICKET=.*/CURRENT_TICKET=$TICKET_INPUT/" .env
    export CURRENT_TICKET=$TICKET_INPUT
    echo -e "${GREEN}✅ Ticket set: $CURRENT_TICKET${NC}"
else
    echo -e "${GREEN}✅ Using existing ticket: $CURRENT_TICKET${NC}"
fi

# Step 2: Verify ticket exists
echo ""
echo -e "${YELLOW}Step 2: Verifying Jira Ticket${NC}"
./jira-confluence-helper.sh fetch-ticket $CURRENT_TICKET
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to fetch ticket. Please check your credentials and ticket ID.${NC}"
    exit 1
fi

# Step 3: Get Confluence spec
echo ""
echo -e "${YELLOW}Step 3: Confluence Specification${NC}"
if [ -z "$CONFLUENCE_SPEC_ID" ]; then
    read -p "Enter Confluence page ID for specifications (or press Enter to skip): " SPEC_INPUT
    
    if [ -n "$SPEC_INPUT" ]; then
        sed -i "s/^CONFLUENCE_SPEC_ID=.*/CONFLUENCE_SPEC_ID=$SPEC_INPUT/" .env
        export CONFLUENCE_SPEC_ID=$SPEC_INPUT
        echo -e "${GREEN}✅ Confluence spec set: $CONFLUENCE_SPEC_ID${NC}"
        
        # Fetch the spec
        ./jira-confluence-helper.sh fetch-spec $CONFLUENCE_SPEC_ID
    else
        echo -e "${YELLOW}⚠️  No Confluence spec provided (not recommended)${NC}"
    fi
else
    echo -e "${GREEN}✅ Using existing spec: $CONFLUENCE_SPEC_ID${NC}"
    ./jira-confluence-helper.sh fetch-spec $CONFLUENCE_SPEC_ID
fi

# Step 4: Project type selection
echo ""
echo -e "${YELLOW}Step 4: Project Type Selection${NC}"
echo "1) NEW PROJECT - Creating from scratch"
echo "2) MODIFICATION - Updating existing codebase"
read -p "Select project type (1 or 2): " PROJECT_TYPE

if [ "$PROJECT_TYPE" = "2" ]; then
    # Step 5: Define allowed files for modification
    echo ""
    echo -e "${YELLOW}Step 5: Define Allowed Files for Modification${NC}"
    echo "Enter files you're allowed to modify (one per line, empty line to finish):"
    
    > allowed_files.txt
    while IFS= read -r file; do
        [ -z "$file" ] && break
        echo "$file" >> allowed_files.txt
    done
    
    if [ -s allowed_files.txt ]; then
        echo -e "${GREEN}✅ Allowed files list created:${NC}"
        cat allowed_files.txt
    else
        echo -e "${YELLOW}⚠️  No file restrictions (all files allowed)${NC}"
    fi
    
    # Generate pre-modification snapshot
    echo ""
    echo -e "${YELLOW}Generating pre-modification snapshot...${NC}"
    git status > pre_modification_status.txt
    git diff > pre_modification_diff.txt
    find . -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) -exec md5sum {} \; > file_checksums.txt 2>/dev/null
    echo -e "${GREEN}✅ Snapshot created${NC}"
else
    echo -e "${GREEN}✅ New project mode selected${NC}"
fi

# Step 6: Initialize Git branch
echo ""
echo -e "${YELLOW}Step 6: Git Configuration${NC}"
BRANCH_NAME="feature/${CURRENT_TICKET}-$(echo "$CURRENT_TICKET" | tr '[:upper:]' '[:lower:]')"
if git rev-parse --git-dir > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
        read -p "Create new branch $BRANCH_NAME? (y/n): " CREATE_BRANCH
        if [ "$CREATE_BRANCH" = "y" ]; then
            git checkout -b "$BRANCH_NAME"
            echo -e "${GREEN}✅ Created and switched to branch: $BRANCH_NAME${NC}"
        fi
    else
        echo -e "${GREEN}✅ Already on branch: $BRANCH_NAME${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Not a git repository. Initialize with 'git init' if needed.${NC}"
fi

# Step 7: Set up testing framework
echo ""
echo -e "${YELLOW}Step 7: Testing Framework Setup${NC}"
if [ ! -f package.json ] && [ ! -f requirements.txt ] && [ ! -f pom.xml ]; then
    echo "No existing project detected. Select framework:"
    echo "1) Node.js/JavaScript"
    echo "2) Python"
    echo "3) Java"
    echo "4) Skip"
    read -p "Select option (1-4): " FRAMEWORK
    
    case $FRAMEWORK in
        1)
            npm init -y > /dev/null 2>&1
            npm install --save-dev jest eslint @types/node typescript > /dev/null 2>&1
            echo -e "${GREEN}✅ Node.js testing framework initialized${NC}"
            ;;
        2)
            echo "pytest==7.4.0" > requirements.txt
            echo "flake8==6.0.0" >> requirements.txt
            echo "coverage==7.2.0" >> requirements.txt
            echo -e "${GREEN}✅ Python testing framework initialized${NC}"
            ;;
        3)
            echo -e "${YELLOW}Maven/Gradle setup required (manual configuration needed)${NC}"
            ;;
        *)
            echo -e "${YELLOW}Testing framework setup skipped${NC}"
            ;;
    esac
else
    echo -e "${GREEN}✅ Existing project structure detected${NC}"
fi

# Step 8: Set up Git hooks
echo ""
echo -e "${YELLOW}Step 8: Git Hooks Configuration${NC}"
if [ -d .git ]; then
    # Create pre-commit hook
    cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
./pre-commit-validate.sh
HOOK
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}✅ Pre-commit hook installed${NC}"
    
    # Create pre-push hook
    cat > .git/hooks/pre-push << 'HOOK'
#!/bin/bash
touch .git/PUSH_INTENT
./violation-detector.sh
rm -f .git/PUSH_INTENT
HOOK
    chmod +x .git/hooks/pre-push
    echo -e "${GREEN}✅ Pre-push hook installed${NC}"
else
    echo -e "${YELLOW}⚠️  Git hooks not installed (not a git repository)${NC}"
fi

# Step 9: Start compliance monitoring
echo ""
echo -e "${YELLOW}Step 9: Compliance Monitoring${NC}"
read -p "Start compliance monitor in background? (y/n): " START_MONITOR
if [ "$START_MONITOR" = "y" ]; then
    nohup ./compliance-monitor.sh > compliance_monitor.log 2>&1 &
    MONITOR_PID=$!
    echo $MONITOR_PID > .compliance_monitor.pid
    echo -e "${GREEN}✅ Compliance monitor started (PID: $MONITOR_PID)${NC}"
    echo "   To stop: kill \$(cat .compliance_monitor.pid)"
else
    echo "To start monitoring later: ./compliance-monitor.sh &"
fi

# Step 10: Final validation
echo ""
echo -e "${YELLOW}Step 10: Final Validation${NC}"
./violation-detector.sh
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All systems ready!${NC}"
else
    echo -e "${RED}⚠️  Some violations detected. Please resolve before starting development.${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   INITIALIZATION COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo "Configuration Summary:"
echo "  • Jira Ticket: ${CURRENT_TICKET}"
echo "  • Confluence Spec: ${CONFLUENCE_SPEC_ID:-Not set}"
echo "  • Project Type: $([ "$PROJECT_TYPE" = "2" ] && echo "Modification" || echo "New Project")"
echo "  • Branch: $(git branch --show-current 2>/dev/null || echo "N/A")"
echo "  • Compliance Monitor: $([ -f .compliance_monitor.pid ] && echo "Running" || echo "Not running")"
echo ""
echo "Next Steps:"
echo "  1. Start development following the Confluence specification"
echo "  2. Run './pre-commit-validate.sh' before each commit"
echo "  3. Run './generate-report.sh' to create progress reports"
echo "  4. Use './jira-confluence-helper.sh' for API interactions"
echo ""
echo -e "${GREEN}Happy coding! Remember: Every line must be compliant.${NC}"