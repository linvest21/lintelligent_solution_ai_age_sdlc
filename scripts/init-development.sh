#!/bin/bash

# Load environment variables
source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Initializing Development Environment${NC}"
echo "================================================"

# Check if project config exists
if [ ! -f "project_config.json" ]; then
  echo -e "${RED}❌ Error: project_config.json not found${NC}"
  echo "Please run ./scripts/validate-ticket.sh TICKET-ID first"
  exit 1
fi

# Load project config
TICKET_ID=$(jq -r '.ticket_id' project_config.json)
TICKET_SUMMARY=$(jq -r '.ticket_summary' project_config.json)

echo -e "${GREEN}Working on: $TICKET_ID - $TICKET_SUMMARY${NC}"
echo ""

# Determine project type
echo "Please select project type:"
echo "1) New Project (creating from scratch)"
echo "2) Modification (updating existing code)"
read -p "Enter choice [1-2]: " PROJECT_TYPE

if [ "$PROJECT_TYPE" == "1" ]; then
  echo -e "${GREEN}✅ Initializing NEW PROJECT${NC}"
  PROJECT_MODE="NEW"
  
  # Create project structure
  mkdir -p src tests docs
  touch allowed_files.txt
  echo "# New Project for $TICKET_ID" > README.md
  
elif [ "$PROJECT_TYPE" == "2" ]; then
  echo -e "${YELLOW}✅ Initializing MODIFICATION mode${NC}"
  PROJECT_MODE="MODIFICATION"
  
  # Create pre-modification snapshot
  echo "Creating pre-modification snapshot..."
  mkdir -p .modifications
  
  # Save current state
  git status > .modifications/pre_modification_status.txt 2>/dev/null || touch .modifications/pre_modification_status.txt
  git diff > .modifications/pre_modification_diff.txt 2>/dev/null || touch .modifications/pre_modification_diff.txt
  
  # Create file checksums
  find . -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) \
    -not -path "./node_modules/*" -not -path "./.git/*" \
    -exec md5sum {} \; > .modifications/file_checksums.txt
  
  echo -e "${GREEN}✅ Snapshot created in .modifications/${NC}"
  
  # Request allowed files list
  echo ""
  echo "Please specify files allowed for modification:"
  echo "(Enter file paths one per line, press Ctrl+D when done)"
  cat > allowed_files.txt
  
  echo -e "${GREEN}✅ Allowed files list saved${NC}"
else
  echo -e "${RED}Invalid choice${NC}"
  exit 1
fi

# Create development session file
cat > development_session.json << EOF
{
  "ticket_id": "$TICKET_ID",
  "project_mode": "$PROJECT_MODE",
  "session_start": "$(date -Iseconds)",
  "allowed_files": $(jq -Rs 'split("\n") | map(select(. != ""))' allowed_files.txt),
  "pre_commit_checks": {
    "lint": false,
    "test": false,
    "coverage": false,
    "security": false
  },
  "test_results": {
    "unit_coverage": 0,
    "integration_passed": 0,
    "stress_test_passed": false
  }
}
EOF

# Create git hooks
mkdir -p .git/hooks 2>/dev/null

cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

source .env

echo "🔍 Running pre-commit validation..."

# Check for Jira ticket in commit message
COMMIT_MSG=$(git log -1 --pretty=%B 2>/dev/null)
if ! echo "$COMMIT_MSG" | grep -qE '\[[A-Z]+-[0-9]+\]'; then
  echo "❌ ERROR: No Jira ticket found in commit message"
  echo "Format: [TICKET-123] Your commit message"
  exit 1
fi

# Run tests if they exist
if [ -f "package.json" ] && grep -q "test" package.json; then
  npm test || { echo "❌ Tests failed"; exit 1; }
fi

if [ -f "requirements.txt" ]; then
  python -m pytest || { echo "❌ Tests failed"; exit 1; }
fi

echo "✅ Pre-commit validation passed!"
EOF

chmod +x .git/hooks/pre-commit 2>/dev/null

# Start compliance monitor in background
cat > compliance_monitor.sh << 'EOF'
#!/bin/bash

source .env

TICKET_ID=$(jq -r '.ticket_id' development_session.json)
PROJECT_MODE=$(jq -r '.project_mode' development_session.json)

while true; do
  clear
  echo "📊 Compliance Monitor - $(date)"
  echo "================================"
  echo "Ticket: $TICKET_ID"
  echo "Mode: $PROJECT_MODE"
  echo ""
  
  # Check for unauthorized modifications
  if [ "$PROJECT_MODE" == "MODIFICATION" ] && [ -f "allowed_files.txt" ]; then
    UNAUTHORIZED=$(git status --porcelain 2>/dev/null | grep -v -f allowed_files.txt | wc -l)
    if [ "$UNAUTHORIZED" -gt 0 ]; then
      echo "⚠️  WARNING: $UNAUTHORIZED unauthorized file(s) modified!"
      git status --porcelain | grep -v -f allowed_files.txt
    else
      echo "✅ No unauthorized modifications"
    fi
  fi
  
  # Show test coverage if available
  if [ -f "coverage/coverage-summary.json" ]; then
    COVERAGE=$(jq '.total.lines.pct' coverage/coverage-summary.json)
    echo "📈 Test Coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "   ⚠️  Below 80% threshold!"
    fi
  fi
  
  echo ""
  echo "Press Ctrl+C to stop monitoring"
  sleep 30
done
EOF

chmod +x compliance_monitor.sh

echo ""
echo -e "${GREEN}✅ Development environment initialized!${NC}"
echo ""
echo "📋 Development Checklist:"
echo "   □ Jira ticket validated: $TICKET_ID"
echo "   □ Confluence spec available: spec_${TICKET_ID}.html"
echo "   □ Project mode set: $PROJECT_MODE"
if [ "$PROJECT_MODE" == "MODIFICATION" ]; then
  echo "   □ Pre-modification snapshot created"
  echo "   □ Allowed files defined: $(wc -l < allowed_files.txt) files"
fi
echo "   □ Git hooks configured"
echo "   □ Compliance monitoring ready"
echo ""
echo "🎯 Next Steps:"
echo "1. Review the specification: spec_${TICKET_ID}.html"
echo "2. Start compliance monitor: ./compliance_monitor.sh (in new terminal)"
echo "3. Begin development following CLAUDE.md guidelines"
echo "4. Run tests: ./scripts/run-tests.sh"
echo "5. Validate before commit: ./scripts/pre-commit-check.sh"
echo ""
echo -e "${BLUE}Happy coding! Remember: No code without spec, no commit without tests!${NC}"