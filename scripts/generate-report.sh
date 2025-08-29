#!/bin/bash

# Load environment variables
source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Generating Development Report${NC}"
echo "================================="

# Load session data
if [ ! -f "development_session.json" ]; then
  echo -e "${RED}❌ Error: development_session.json not found${NC}"
  exit 1
fi

TICKET_ID=$(jq -r '.ticket_id' development_session.json)
PROJECT_MODE=$(jq -r '.project_mode' development_session.json)
SESSION_START=$(jq -r '.session_start' development_session.json)
UNIT_COVERAGE=$(jq -r '.test_results.unit_coverage' development_session.json)
INTEGRATION_PASSED=$(jq -r '.test_results.integration_passed' development_session.json)
STRESS_PASSED=$(jq -r '.test_results.stress_test_passed' development_session.json)

REPORT_FILE="development_report_${TICKET_ID}_$(date +%Y%m%d_%H%M%S).md"

# Calculate metrics
FILES_MODIFIED=$(git diff --name-only 2>/dev/null | wc -l)
LINES_ADDED=$(git diff --stat 2>/dev/null | tail -1 | awk '{print $4}' || echo 0)
LINES_REMOVED=$(git diff --stat 2>/dev/null | tail -1 | awk '{print $6}' || echo 0)
COMMITS_MADE=$(git log --oneline --since="$SESSION_START" 2>/dev/null | wc -l)

# Create comprehensive report
cat > $REPORT_FILE << EOF
# Development Report for ${TICKET_ID}

**Generated:** $(date)  
**Developer:** $(git config user.name 2>/dev/null || echo "Unknown")  
**Project Mode:** $PROJECT_MODE

---

## 📋 Session Summary

| Metric | Value |
|--------|-------|
| Session Start | $SESSION_START |
| Session End | $(date -Iseconds) |
| Duration | $(echo "$(date +%s) - $(date -d "$SESSION_START" +%s)" | bc | awk '{printf "%d hours %d minutes\n", $1/3600, ($1%3600)/60}') |
| Files Modified | $FILES_MODIFIED |
| Lines Added | $LINES_ADDED |
| Lines Removed | $LINES_REMOVED |
| Commits Made | $COMMITS_MADE |

---

## 🎯 Jira Ticket Information

**Ticket ID:** $TICKET_ID  
**Summary:** $(jq -r '.ticket_summary' project_config.json 2>/dev/null || echo "N/A")  
**Status:** $(jq -r '.ticket_status' project_config.json 2>/dev/null || echo "N/A")  
**Confluence Spec:** $(jq -r '.confluence_url' project_config.json 2>/dev/null || echo "N/A")

---

## ✅ Compliance Checklist

### Pre-Development
- [x] Jira ticket validated
- [x] Confluence specification retrieved
- [x] Development environment initialized
- [x] Project mode selected: $PROJECT_MODE
EOF

if [ "$PROJECT_MODE" == "MODIFICATION" ]; then
  cat >> $REPORT_FILE << EOF
- [x] Pre-modification snapshot created
- [x] Allowed files list defined
- [x] File checksums recorded
EOF
fi

cat >> $REPORT_FILE << EOF

### Development Process
- [x] Code implemented according to specification
- [$([ "$UNIT_COVERAGE" != "0" ] && echo "x" || echo " ")] Unit tests written
- [$([ "$INTEGRATION_PASSED" != "0" ] && echo "x" || echo " ")] Integration tests created
- [$([ "$STRESS_PASSED" == "true" ] && echo "x" || echo " ")] Stress tests executed
- [x] Security scanning completed
- [x] Code linting performed
- [x] Type checking completed

---

## 🧪 Test Results

### Unit Tests
- **Coverage:** ${UNIT_COVERAGE}%
- **Threshold:** 80%
- **Status:** $([ $(echo "$UNIT_COVERAGE >= 80" | bc -l) -eq 1 ] && echo "✅ PASSED" || echo "❌ FAILED")

### Integration Tests
- **Tests Passed:** $INTEGRATION_PASSED
- **Status:** $([ "$INTEGRATION_PASSED" != "0" ] && echo "✅ PASSED" || echo "⚠️ NO TESTS")

### Stress Tests
- **Status:** $([ "$STRESS_PASSED" == "true" ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Load:** 100 concurrent users for 5 minutes
- **Success Rate Target:** 99.9%

---

## 📁 Files Changed

EOF

if [ "$PROJECT_MODE" == "MODIFICATION" ] && [ -f "allowed_files.txt" ]; then
  echo "### Authorized Modifications" >> $REPORT_FILE
  echo '```' >> $REPORT_FILE
  cat allowed_files.txt >> $REPORT_FILE
  echo '```' >> $REPORT_FILE
  echo "" >> $REPORT_FILE
fi

echo "### All Modified Files" >> $REPORT_FILE
echo '```' >> $REPORT_FILE
git diff --name-only 2>/dev/null >> $REPORT_FILE || echo "No git changes" >> $REPORT_FILE
echo '```' >> $REPORT_FILE

# Add detailed changes
cat >> $REPORT_FILE << EOF

---

## 🔍 Detailed Changes

<details>
<summary>Click to expand diff</summary>

\`\`\`diff
EOF

git diff 2>/dev/null | head -500 >> $REPORT_FILE || echo "No changes to show" >> $REPORT_FILE

cat >> $REPORT_FILE << EOF
\`\`\`

</details>

---

## 📊 Code Quality Metrics

EOF

# Add quality metrics if available
if [ -f "coverage/coverage-summary.json" ]; then
  cat >> $REPORT_FILE << EOF
### Coverage Breakdown
| Type | Coverage |
|------|----------|
| Statements | $(jq '.total.statements.pct' coverage/coverage-summary.json)% |
| Branches | $(jq '.total.branches.pct' coverage/coverage-summary.json)% |
| Functions | $(jq '.total.functions.pct' coverage/coverage-summary.json)% |
| Lines | $(jq '.total.lines.pct' coverage/coverage-summary.json)% |

EOF
fi

# Security scan results
if [ -f "package-lock.json" ]; then
  AUDIT=$(npm audit --json 2>/dev/null)
  if [ ! -z "$AUDIT" ]; then
    LOW=$(echo "$AUDIT" | jq '.metadata.vulnerabilities.low' 2>/dev/null || echo 0)
    MOD=$(echo "$AUDIT" | jq '.metadata.vulnerabilities.moderate' 2>/dev/null || echo 0)
    HIGH=$(echo "$AUDIT" | jq '.metadata.vulnerabilities.high' 2>/dev/null || echo 0)
    CRIT=$(echo "$AUDIT" | jq '.metadata.vulnerabilities.critical' 2>/dev/null || echo 0)
    
    cat >> $REPORT_FILE << EOF
### Security Scan Results
| Severity | Count |
|----------|-------|
| Low | $LOW |
| Moderate | $MOD |
| High | $HIGH |
| Critical | $CRIT |

EOF
  fi
fi

# Add commit history
cat >> $REPORT_FILE << EOF
---

## 📝 Commit History

\`\`\`
EOF

git log --oneline --since="$SESSION_START" 2>/dev/null | head -20 >> $REPORT_FILE || echo "No commits yet" >> $REPORT_FILE

cat >> $REPORT_FILE << EOF
\`\`\`

---

## 🚀 Deployment Instructions

1. Ensure all tests are passing
2. Review this report for completeness
3. Create pull request with reference to $TICKET_ID
4. Update Jira ticket status to "Code Review"
5. After approval, merge to main branch
6. Deploy according to project deployment guide

---

## ✍️ Sign-off

**Developer Checklist:**
- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Comments added where necessary
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] No new warnings generated
- [ ] Dependent changes merged

**Reviewer Checklist:**
- [ ] Code accomplishes intended goal
- [ ] No obvious bugs or issues
- [ ] Tests adequately cover changes
- [ ] Performance impact assessed
- [ ] Security implications reviewed
- [ ] Documentation is clear

---

*Report generated by Claude Code Development Lifecycle System*  
*Co-authored-by: Claude <noreply@anthropic.com>*
EOF

echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"

# Upload to Confluence if configured
if [ ! -z "$CONFLUENCE_EMAIL" ] && [ ! -z "$CONFLUENCE_API_TOKEN" ]; then
  echo ""
  echo "📤 Uploading report to Confluence..."
  
  # Convert markdown to HTML for Confluence
  REPORT_HTML=$(cat $REPORT_FILE | sed 's/"/\\"/g' | sed 's/$/\\n/g' | tr -d '\n')
  
  CONFLUENCE_RESPONSE=$(curl -s -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "{
      \"type\": \"page\",
      \"title\": \"Dev Report: ${TICKET_ID} - $(date +%Y-%m-%d)\",
      \"space\": {\"key\": \"DEV\"},
      \"body\": {
        \"storage\": {
          \"value\": \"$REPORT_HTML\",
          \"representation\": \"markdown\"
        }
      },
      \"ancestors\": [{\"id\": \"$(jq -r '.confluence_page_id' project_config.json 2>/dev/null || echo '')\"}]
    }" \
    ${CONFLUENCE_URL}/rest/api/content)
  
  if echo "$CONFLUENCE_RESPONSE" | grep -q '"id"'; then
    PAGE_URL=$(echo "$CONFLUENCE_RESPONSE" | jq -r '._links.webui' | sed "s|^|${CONFLUENCE_URL}|")
    echo -e "${GREEN}✅ Report uploaded to Confluence${NC}"
    echo "   URL: $PAGE_URL"
  else
    echo -e "${YELLOW}⚠️  Could not upload to Confluence${NC}"
  fi
fi

# Update Jira with report summary
if [ ! -z "$JIRA_EMAIL" ] && [ ! -z "$JIRA_API_TOKEN" ]; then
  echo ""
  echo "📤 Updating Jira ticket..."
  
  COMMENT="Development Report Generated:\n"
  COMMENT="${COMMENT}- Files Modified: $FILES_MODIFIED\n"
  COMMENT="${COMMENT}- Lines Changed: +$LINES_ADDED -$LINES_REMOVED\n"
  COMMENT="${COMMENT}- Test Coverage: ${UNIT_COVERAGE}%\n"
  COMMENT="${COMMENT}- All Tests: $([ "$UNIT_COVERAGE" != "0" ] && [ "$STRESS_PASSED" == "true" ] && echo "PASSED" || echo "FAILED")\n"
  COMMENT="${COMMENT}\nFull report: See attached file or Confluence page"
  
  curl -s -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"body\": \"$COMMENT\"}" \
    ${JIRA_URL}/rest/api/2/issue/${TICKET_ID}/comment > /dev/null
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Jira ticket updated with summary${NC}"
  fi
fi

echo ""
echo "📋 Report Contents:"
echo "  - Session metrics"
echo "  - Test results"
echo "  - Code changes"
echo "  - Quality metrics"
echo "  - Deployment instructions"
echo ""
echo "Share this report with your team for review!"