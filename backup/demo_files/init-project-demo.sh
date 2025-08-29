#!/bin/bash

# Demo initialization script - works without existing Jira ticket
# For testing the lifecycle workflow setup

source ./load_env.sh

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   PROJECT LIFECYCLE INITIALIZATION (DEMO MODE)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Step 1: Create demo ticket ID
echo -e "${YELLOW}Step 1: Demo Ticket Configuration${NC}"
DEMO_TICKET="DEMO-$(date +%Y%m%d)"
sed -i "s/^CURRENT_TICKET=.*/CURRENT_TICKET=$DEMO_TICKET/" .env
export CURRENT_TICKET=$DEMO_TICKET
echo -e "${GREEN}✅ Demo ticket set: $CURRENT_TICKET${NC}"
echo "   (In production, this would be a real Jira ticket)"

# Step 2: Skip Jira verification in demo mode
echo ""
echo -e "${YELLOW}Step 2: Jira Verification (DEMO - Skipped)${NC}"
echo -e "${YELLOW}⚠️  Demo mode: Skipping Jira verification${NC}"
echo "   In production, this would verify the ticket exists and is 'In Progress'"

# Step 3: Demo Confluence spec
echo ""
echo -e "${YELLOW}Step 3: Confluence Specification (DEMO)${NC}"
DEMO_SPEC="SPEC-$(date +%Y%m%d)"
sed -i "s/^CONFLUENCE_SPEC_ID=.*/CONFLUENCE_SPEC_ID=$DEMO_SPEC/" .env
export CONFLUENCE_SPEC_ID=$DEMO_SPEC
echo -e "${GREEN}✅ Demo spec ID set: $CONFLUENCE_SPEC_ID${NC}"

# Create a demo specification file
cat > "confluence_${DEMO_SPEC}.md" << EOF
# Demo Specification for $CURRENT_TICKET

## Acceptance Criteria
- [ ] Implement core functionality
- [ ] Add unit tests with 80% coverage
- [ ] Add integration tests
- [ ] Pass stress testing
- [ ] Update documentation

## Technical Requirements
- Language: JavaScript/TypeScript
- Testing: Jest
- Coverage: Minimum 80%
- Performance: < 200ms response time

## Security Considerations
- No hardcoded credentials
- Input validation required
- Error handling implemented
EOF
echo -e "${BLUE}Demo specification created: confluence_${DEMO_SPEC}.md${NC}"

# Step 4: Project type selection
echo ""
echo -e "${YELLOW}Step 4: Project Type Selection${NC}"
echo "1) NEW PROJECT - Creating from scratch"
echo "2) MODIFICATION - Updating existing codebase"
read -p "Select project type (1 or 2): " PROJECT_TYPE

if [ "$PROJECT_TYPE" = "2" ]; then
    echo ""
    echo -e "${YELLOW}Step 5: Define Allowed Files for Modification${NC}"
    echo "Enter files you're allowed to modify (one per line, empty line to finish):"
    
    > allowed_files.txt
    while IFS= read -r file; do
        [ -z "$file" ] && break
        echo "$file" >> allowed_files.txt
    done
    
    if [ -s allowed_files.txt ]; then
        echo -e "${GREEN}✅ Allowed files list created${NC}"
    fi
    
    # Generate snapshot
    echo -e "${YELLOW}Generating pre-modification snapshot...${NC}"
    git status > pre_modification_status.txt 2>/dev/null || echo "Not a git repo" > pre_modification_status.txt
    echo -e "${GREEN}✅ Snapshot created${NC}"
else
    echo -e "${GREEN}✅ New project mode selected${NC}"
fi

# Step 5: Create demo project structure
echo ""
echo -e "${YELLOW}Step 5: Demo Project Setup${NC}"
if [ ! -f package.json ]; then
    echo "Creating demo Node.js project..."
    cat > package.json << EOF
{
  "name": "lifecycle-demo-project",
  "version": "1.0.0",
  "description": "Demo project for lifecycle workflow",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "eslint": "^8.0.0",
    "typescript": "^5.0.0"
  }
}
EOF
    echo -e "${GREEN}✅ Demo package.json created${NC}"
fi

# Step 6: Create sample test file
echo ""
echo -e "${YELLOW}Step 6: Creating Sample Test Structure${NC}"
mkdir -p tests
cat > tests/demo.test.js << EOF
// Demo test file for lifecycle workflow
describe('Demo Test Suite', () => {
  test('should pass basic test', () => {
    expect(true).toBe(true);
  });
  
  test('should demonstrate coverage', () => {
    const result = 2 + 2;
    expect(result).toBe(4);
  });
});
EOF
echo -e "${GREEN}✅ Sample test created: tests/demo.test.js${NC}"

# Step 7: Set up Git (if not already)
echo ""
echo -e "${YELLOW}Step 7: Git Configuration${NC}"
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    read -p "Initialize git repository? (y/n): " INIT_GIT
    if [ "$INIT_GIT" = "y" ]; then
        git init
        echo -e "${GREEN}✅ Git repository initialized${NC}"
    fi
fi

if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH_NAME="feature/${CURRENT_TICKET}-demo"
    git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME" 2>/dev/null
    echo -e "${GREEN}✅ On branch: $BRANCH_NAME${NC}"
    
    # Install hooks
    mkdir -p .git/hooks
    cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
./pre-commit-validate.sh
HOOK
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}✅ Pre-commit hook installed${NC}"
fi

# Step 8: Create allowed files for demo
echo ""
echo -e "${YELLOW}Step 8: Setting Up Demo Allowed Files${NC}"
cat > allowed_files.txt << EOF
package.json
tests/demo.test.js
src/index.js
README.md
.gitignore
EOF
echo -e "${GREEN}✅ Allowed files list created for demo${NC}"

# Step 9: Run initial validation
echo ""
echo -e "${YELLOW}Step 9: Initial Validation${NC}"
echo -e "${BLUE}Running violation detector in demo mode...${NC}"

# Create a demo-friendly violation check
CRITICAL_VIOLATION=false

if [ -z "$CURRENT_TICKET" ]; then
    echo -e "${RED}❌ No ticket configured${NC}"
    CRITICAL_VIOLATION=true
else
    echo -e "${GREEN}✅ Ticket configured: $CURRENT_TICKET${NC}"
fi

if [ -z "$CONFLUENCE_SPEC_ID" ]; then
    echo -e "${RED}❌ No specification linked${NC}"
    CRITICAL_VIOLATION=true
else
    echo -e "${GREEN}✅ Specification linked: $CONFLUENCE_SPEC_ID${NC}"
fi

if [ -f allowed_files.txt ]; then
    echo -e "${GREEN}✅ File restrictions configured${NC}"
else
    echo -e "${YELLOW}⚠️  No file restrictions${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   DEMO INITIALIZATION COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo "Demo Configuration Summary:"
echo "  • Demo Ticket: ${CURRENT_TICKET}"
echo "  • Demo Spec: ${CONFLUENCE_SPEC_ID}"
echo "  • Project Type: $([ "$PROJECT_TYPE" = "2" ] && echo "Modification" || echo "New Project")"
echo "  • Allowed Files: $(wc -l < allowed_files.txt) files configured"
echo ""
echo -e "${YELLOW}⚠️  DEMO MODE ACTIVE${NC}"
echo "In production, you would:"
echo "  1. Use a real Jira ticket (e.g., PROJ-123)"
echo "  2. Link to actual Confluence specifications"
echo "  3. Connect to live Jira/Confluence APIs"
echo ""
echo "Next Steps:"
echo "  1. Create/modify files listed in allowed_files.txt"
echo "  2. Run './pre-commit-validate.sh' before commits"
echo "  3. Run './compliance-monitor.sh &' for monitoring"
echo "  4. Run './generate-report.sh' for progress reports"
echo ""
echo -e "${GREEN}Demo environment ready for testing the lifecycle workflow!${NC}"