# AI_AGE_SDLC - Claude Code Configuration

## 🚀 Enhanced Version Available
**For the complete AI_AGE_SDLC framework with full automation, see:**
- **Primary Documentation**: `documentation/CLAUDE_AI_AGE_SDLC.md` (1400+ lines)
- **Master Orchestrator**: `workflows/ai_age_sdlc_master.sh` 
- **Session Documentation**: `doc/SESSION_PROMPTS_AND_RESULTS.md`

This file maintains compatibility with existing workflows while the enhanced version provides:
- Repository management (NEW/MODIFICATION modes)
- Branch stacking automation
- Complete test orchestration
- Auto-commit and push workflows

## Original CLAUDE.md Configuration

## 🔧 FIRST TIME SETUP REQUIRED

**⚠️ IMPORTANT: Before using this SDLC, you MUST set up your services!**

### 📚 Complete Setup Guide
**See `SETUP_GUIDE.md` for step-by-step instructions on:**
- ✅ Creating and configuring Jira projects
- ✅ Setting up Confluence spaces and templates  
- ✅ Creating GitHub repositories with proper branches
- ✅ Generating API tokens for all services
- ✅ Automated setup and validation scripts

### ⚡ Quick Setup Commands
```bash
# 1. Set up all services using the wizard
./setup_sdlc_services.sh

# 2. Validate all connections work
./validate_sdlc_setup.sh

# 3. You're ready to use the SDLC!
```

## 🔐 Credentials Configuration
Configure these environment variables or update the values below:
```yaml
JIRA_URL: https://your-domain.atlassian.net
JIRA_PROJECT_KEY: AISD  # Your project key
JIRA_EMAIL: your-email@company.com
JIRA_API_TOKEN: [Stored in .env]

CONFLUENCE_URL: https://your-domain.atlassian.net/wiki
CONFLUENCE_SPACE_KEY: AISDSPEC  # Your space key
CONFLUENCE_EMAIL: your-email@company.com
CONFLUENCE_API_TOKEN: [Stored in .env]

GITHUB_OWNER: your-org
GITHUB_REPO: your-repo
GITHUB_TOKEN: [Stored in .env]
```

## 🚫 ABSOLUTE ENFORCEMENT - NO EXCEPTIONS

**⚠️ CRITICAL: AI_AGE_SDLC IS 100% MANDATORY - NOT OPTIONAL!**

```
┌─────────────────────────────────────────────────────────────┐
│  🚨 ENFORCEMENT NOTICE 🚨                                   │
│                                                             │
│  MANDATORY SEQUENCE - MUST BE FOLLOWED IN ORDER:           │
│                                                             │
│  1. SETUP: Configure Confluence, Jira, GitHub access       │
│  2. VALIDATE: Test all service connections                  │
│  3. JIRA TICKET: Get assigned ticket from Jira             │
│  4. CONFLUENCE SPEC: Get linked specification               │
│  5. DEVELOPMENT: Follow all SDLC phases                     │
│                                                             │
│  SKIP ANY STEP = IMMEDIATE STOP                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 STEP 0: MANDATORY SERVICE SETUP (MUST BE FIRST!)

**🚫 CLAUDE WILL REFUSE ALL WORK WITHOUT PROPER SETUP 🚫**

Before ANY development work can begin, you MUST:

### 1. Configure All Services
```bash
# Run the service setup wizard
./setup_sdlc_services.sh

# This configures:
# - Jira account and project
# - Confluence space and templates
# - GitHub repository and branches
# - API tokens and credentials
```

### 2. Validate All Connections  
```bash
# Test all service connectivity
./validate_sdlc_setup.sh

# Must show ALL GREEN:
# ✅ Jira: Ready
# ✅ Confluence: Ready  
# ✅ GitHub: Ready
```

### 3. Verify Compliance
```bash
# Run full compliance check
./enforce_sdlc_compliance.sh

# Must achieve: 100% COMPLIANCE
```

**⚠️ CRITICAL: Claude will CHECK these steps and REFUSE to proceed if any are missing!**

## 🛡️ ENFORCEMENT MECHANISMS

Claude Code will **AUTOMATICALLY ENFORCE** these rules:

### 🚫 BLOCKING CONDITIONS (Claude will REFUSE to proceed):
- ❌ **NO CODE WITHOUT JIRA TICKET** - Period. No exceptions.
- ❌ **NO JIRA TICKET WITHOUT CONFLUENCE SPEC** - Must exist and be complete
- ❌ **NO COMMIT WITHOUT 80% TEST COVERAGE** - Non-negotiable minimum
- ❌ **NO MODIFICATION OUTSIDE AUTHORIZED FILES** - Strict scope control
- ❌ **NO PUSH WITHOUT VALIDATION** - All checks must pass

### ✅ MANDATORY COMPLIANCE CHECKS:
1. **Jira Ticket Validation** - API verified, status confirmed
2. **Confluence Specification** - Complete technical specs required
3. **Test Coverage Enforcement** - 80% minimum, measured automatically
4. **Code Quality Gates** - Lint, type-check, security scan
5. **Documentation Updates** - All changes documented

## 🚦 MANDATORY WORKFLOW ENFORCEMENT

### STEP 1: SERVICE SETUP VALIDATION (PREREQUISITE)
**🚫 CLAUDE WILL CHECK THIS FIRST - NO EXCEPTIONS 🚫**

Before any development discussion:
1. Verify .env file exists with all credentials
2. Test Jira API connection
3. Test Confluence API connection  
4. Test GitHub API connection
5. Confirm all services are operational

**IF ANY SERVICE FAILS → IMMEDIATE STOP → GO SETUP SERVICES FIRST**

### STEP 2: JIRA TICKET ACQUISITION 

**🚫 NO WORK WITHOUT ASSIGNED JIRA TICKET 🚫**

Process:
1. User provides Jira ticket ID (e.g., AISD-123)
2. Claude validates ticket exists via API
3. Claude confirms ticket is assigned to user
4. Claude verifies ticket status allows development

### STEP 3: CONFLUENCE SPECIFICATION RETRIEVAL

**🚫 NO CODING WITHOUT COMPLETE SPECS 🚫**

Process:
1. Claude extracts Confluence link from Jira ticket
2. Claude fetches specification via API
3. Claude validates spec contains all required sections
4. Claude confirms spec is approved for development

### PHASE 1: Pre-Development Validation (After Setup Complete)

#### 1.1 Jira Ticket Verification (Already Done in Step 2)
**🚫 ABSOLUTE REQUIREMENT - ZERO TOLERANCE FOR NON-COMPLIANCE 🚫**
**STOP - DO NOT PROCEED WITHOUT COMPLETING:**
- [ ] Jira ticket ID provided: `[PROJ-XXXX]`
- [ ] Verify ticket exists via API:
  ```bash
  curl -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
    -X GET \
    -H "Content-Type: application/json" \
    ${JIRA_URL}/rest/api/2/issue/${TICKET_ID}
  ```
- [ ] Ticket status is "In Progress" or "Development"
- [ ]ticket assigned to current user

#### 1.2 Confluence Specification Validation
**🚫 ABSOLUTELY MANDATORY - NO CODE WITHOUT COMPLETE SPECS 🚫**
**MANDATORY - NO CODE WITHOUT SPECS:**
- [ ] Confluence page ID linked in Jira ticket
- [ ] Fetch specification from Confluence:
  ```bash
  curl -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
    -X GET \
    -H "Content-Type: application/json" \
    ${CONFLUENCE_URL}/rest/api/content/${PAGE_ID}?expand=body.storage
  ```
- [ ] Specification contains:
  - [ ] Acceptance criteria
  - [ ] Technical requirements
  - [ ] API contracts (if applicable)
  - [ ] Database schema changes (if applicable)
  - [ ] Security considerations
  - [ ] Performance requirements

### PHASE 2: Development Mode Selection

#### 2.1 Project Type Classification
**SELECT ONE:**
- [ ] **NEW PROJECT**: Creating from scratch
- [ ] **MODIFICATION**: Updating existing codebase

#### 2.2 Modification Rules (IF MODIFYING)
**ENFORCE MINIMAL INTRUSION POLICY:**
1. **Pre-modification Analysis**
   - [ ] Generate current state snapshot:
     ```bash
     git status > pre_modification_status.txt
     git diff > pre_modification_diff.txt
     find . -type f -name "*.{js,ts,py,java,go}" -exec md5sum {} \; > file_checksums.txt
     ```
   
2. **Scope Limitation**
   - [ ] List ONLY files to be modified:
     ```yaml
     allowed_files:
       - path/to/file1.js
       - path/to/file2.ts
     ```
   - [ ] Any file NOT in this list must NOT be touched

3. **Change Tracking**
   - [ ] Before each file modification, create backup:
     ```bash
     cp ${FILE} ${FILE}.backup.$(date +%Y%m%d_%H%M%S)
     ```
   - [ ] After modification, generate diff report:
     ```bash
     diff -u ${FILE}.backup ${FILE} > ${FILE}.changes
     ```

### PHASE 3: Development Execution

#### 3.1 Code Generation Guidelines
**FOLLOW THESE RULES:**
1. **Every function/method must include:**
   - [ ] JSDoc/PyDoc/JavaDoc comments
   - [ ] Input validation
   - [ ] Error handling
   - [ ] Logging statements

2. **Code structure:**
   - [ ] Follow existing project patterns
   - [ ] Maintain consistent naming conventions
   - [ ] Use dependency injection where applicable

#### 3.2 Real-time Validation
**CONTINUOUS CHECKS:**
```bash
# Run every 10 minutes during development
while true; do
  echo "=== Validation Check $(date) ==="
  
  # Check Jira ticket still valid
  curl -s -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
    ${JIRA_URL}/rest/api/2/issue/${TICKET_ID} | jq '.fields.status.name'
  
  # Verify no unauthorized file modifications
  git status --porcelain | grep -v -f allowed_files.txt && \
    echo "WARNING: Unauthorized files modified!"
  
  sleep 600
done
```

### PHASE 4: Testing Requirements

#### 4.1 Unit Testing
**MANDATORY - 80% MINIMUM COVERAGE:**
```yaml
unit_test_requirements:
  coverage_threshold: 80
  required_test_types:
    - positive_cases
    - negative_cases
    - edge_cases
    - null_checks
    - boundary_conditions
```

**Generate unit tests:**
```bash
# For JavaScript/TypeScript
npm run test:unit -- --coverage

# For Python
pytest --cov=. --cov-report=html --cov-report=term

# For Java
mvn test jacoco:report
```

#### 4.2 Integration Testing
**MANDATORY - ALL ENDPOINTS/INTEGRATIONS:**
```yaml
integration_test_requirements:
  api_tests:
    - all_endpoints_tested
    - authentication_verified
    - error_responses_validated
  database_tests:
    - CRUD_operations
    - transaction_rollback
    - connection_pooling
  external_services:
    - mock_all_third_party_apis
    - timeout_handling
    - retry_logic
```

#### 4.3 Stress Testing
**MANDATORY - PERFORMANCE VALIDATION:**
```yaml
stress_test_requirements:
  load_test:
    concurrent_users: 100
    duration: 300_seconds
    success_rate: 99.9%
  performance_metrics:
    response_time_p95: 200ms
    response_time_p99: 500ms
    error_rate: < 0.1%
```

**Execute stress tests:**
```bash
# Using k6
k6 run --vus 100 --duration 5m stress_test.js

# Using JMeter
jmeter -n -t stress_test.jmx -l results.jtl
```

### PHASE 5: Pre-Commit Validation

#### 5.1 Automated Checks
**ALL MUST PASS:**
```bash
#!/bin/bash
# pre-commit-validate.sh

echo "🔍 Running pre-commit validation..."

# 1. Verify Jira ticket in commit message
if ! git log -1 --pretty=%B | grep -E '\[PROJ-[0-9]+\]'; then
  echo "❌ ERROR: No Jira ticket in commit message"
  exit 1
fi

# 2. Check test coverage
COVERAGE=$(npm run test:coverage --silent | grep "All files" | awk '{print $10}' | sed 's/%//')
if [ "$COVERAGE" -lt 80 ]; then
  echo "❌ ERROR: Test coverage ${COVERAGE}% is below 80%"
  exit 1
fi

# 3. Lint check
npm run lint || { echo "❌ Lint errors found"; exit 1; }

# 4. Type check
npm run typecheck || { echo "❌ Type errors found"; exit 1; }

# 5. Security scan
npm audit --audit-level=moderate || { echo "❌ Security vulnerabilities found"; exit 1; }

echo "✅ All pre-commit checks passed!"
```

#### 5.2 Commit Message Format
**ENFORCED FORMAT:**
```
[JIRA-TICKET] Brief description

- Detailed change 1
- Detailed change 2

Confluence Spec: https://confluence.url/page/id
Tests: Unit (85%), Integration (100%), Stress (Passed)

Co-authored-by: Claude <noreply@anthropic.com>
```

### PHASE 6: Post-Development Validation

#### 6.1 Final Checklist
**MUST COMPLETE ALL:**
- [ ] All tests passing (unit, integration, stress)
- [ ] Code review comments addressed
- [ ] Documentation updated
- [ ] Jira ticket updated with:
  - [ ] Development notes
  - [ ] Test results
  - [ ] Deployment instructions
- [ ] Confluence page updated with:
  - [ ] Implementation details
  - [ ] API documentation
  - [ ] Known limitations

#### 6.2 Automated Reporting
```bash
# generate-report.sh
#!/bin/bash

REPORT_FILE="development_report_${TICKET_ID}_$(date +%Y%m%d).md"

cat > $REPORT_FILE << EOF
# Development Report for ${TICKET_ID}

## Summary
- Start Time: ${START_TIME}
- End Time: $(date)
- Files Modified: $(git diff --name-only | wc -l)
- Lines Added: $(git diff --stat | tail -1 | awk '{print $4}')
- Lines Removed: $(git diff --stat | tail -1 | awk '{print $6}')

## Test Results
- Unit Test Coverage: ${UNIT_COVERAGE}%
- Integration Tests: ${INTEGRATION_PASS}/${INTEGRATION_TOTAL}
- Stress Test Result: ${STRESS_RESULT}

## Compliance Checklist
✅ Jira ticket validated
✅ Confluence spec followed
✅ Minimal intrusion policy enforced
✅ All tests passing
✅ Security scan completed

## Files Changed
$(git diff --name-only)

## Detailed Changes
$(git diff)
EOF

# Upload report to Confluence
curl -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
  -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"type\":\"page\",\"title\":\"Report ${TICKET_ID}\",\"space\":{\"key\":\"DEV\"},\"body\":{\"storage\":{\"value\":\"$(cat $REPORT_FILE | sed 's/"/\\"/g')\",\"representation\":\"markdown\"}}}" \
  ${CONFLUENCE_URL}/rest/api/content
```

## 📋 Prompt Sequences for Project Success

### Sequence 1: Project Initialization
```markdown
1. "Please provide the Jira ticket ID for this task"
2. "I will now fetch the Confluence specification linked to ticket [TICKET-ID]"
3. "Based on the specification, I understand the requirements are: [SUMMARY]. Is this correct?"
4. "Is this a new project or modification to existing code?"
5. "Which files are authorized for modification? Please list them explicitly."
```

### Sequence 2: Development Verification
```markdown
1. "I will now implement the feature according to the Confluence specification"
2. "Before proceeding, let me verify the current state of authorized files"
3. "I've made changes to [FILES]. Let me show you the diff for review"
4. "Would you like me to proceed with generating tests for these changes?"
```

### Sequence 3: Testing Validation
```markdown
1. "I will now generate comprehensive unit tests targeting 80% coverage"
2. "Unit tests complete with [X]% coverage. Proceeding to integration tests"
3. "Integration tests created. Ready to execute stress testing scenarios"
4. "All tests passing. Shall I prepare the commit with proper Jira reference?"
```

### Sequence 4: Final Validation
```markdown
1. "Running final pre-commit validation checks"
2. "All checks passed. Generating development report"
3. "Updating Jira ticket with development notes and test results"
4. "Creating Confluence page with implementation documentation"
5. "Ready to commit. The changes are fully compliant with all policies"
```

## 🛡️ ZERO-TOLERANCE ENFORCEMENT RULES

### 🚫 ABSOLUTE RULES - 100% ENFORCED - NO EXCEPTIONS EVER:
1. **NO CODE WITHOUT JIRA TICKET** - BLOCKED IMMEDIATELY
2. **NO JIRA TICKET WITHOUT CONFLUENCE SPEC** - REFUSED AUTOMATICALLY  
3. **NO COMMIT WITHOUT 80% TEST COVERAGE** - HARD STOP
4. **NO MODIFICATION OUTSIDE AUTHORIZED FILES** - INSTANT REJECTION
5. **NO PUSH WITHOUT VALIDATION** - COMPLETE BLOCK

**⚠️ VIOLATION = IMMEDIATE TERMINATION OF ALL ACTIVITIES ⚠️**

### 🤖 CLAUDE CODE ENFORCEMENT:
Claude will **REFUSE** to perform ANY action that violates these rules:
- Will not write a single line of code without valid Jira ticket
- Will not proceed without complete Confluence specifications
- Will not commit code below 80% test coverage
- Will not modify unauthorized files under any circumstances
- Will stop all work immediately upon detecting violations

### Violation Handling:
```bash
# violation-detector.sh
if [ -z "$JIRA_TICKET" ]; then
  echo "🚨 CRITICAL: Attempting to code without Jira ticket"
  echo "🛑 STOPPING ALL OPERATIONS"
  exit 1
fi

if [ "$TEST_COVERAGE" -lt 80 ]; then
  echo "🚨 CRITICAL: Test coverage below mandatory threshold"
  echo "🛑 BLOCKING COMMIT"
  exit 1
fi
```

## 🔄 Continuous Compliance Monitoring

### Background Monitor Script:
```bash
#!/bin/bash
# compliance-monitor.sh

while true; do
  # Check active Jira ticket
  TICKET_STATUS=$(curl -s -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
    ${JIRA_URL}/rest/api/2/issue/${CURRENT_TICKET} | jq -r '.fields.status.name')
  
  if [ "$TICKET_STATUS" != "In Progress" ]; then
    notify-send "⚠️ Jira ticket ${CURRENT_TICKET} is not in progress!"
  fi
  
  # Check for unauthorized modifications
  UNAUTHORIZED=$(git status --porcelain | grep -v -f allowed_files.txt | wc -l)
  if [ "$UNAUTHORIZED" -gt 0 ]; then
    notify-send "🚨 Unauthorized file modifications detected!"
    git status --porcelain | grep -v -f allowed_files.txt
  fi
  
  # Check test coverage trend
  if [ -f coverage/coverage-summary.json ]; then
    CURRENT_COV=$(jq '.total.lines.pct' coverage/coverage-summary.json)
    if (( $(echo "$CURRENT_COV < 80" | bc -l) )); then
      notify-send "📉 Test coverage dropped below 80%!"
    fi
  fi
  
  sleep 300  # Check every 5 minutes
done
```

## 🎯 Success Metrics

Track and report these metrics for every development session:
1. Jira ticket compliance: 100%
2. Confluence spec adherence: 100%
3. Test coverage achieved: ≥80%
4. Unauthorized file modifications: 0
5. Pre-commit validations passed: 100%
6. Stress test success rate: ≥99.9%

---

**⚠️ REMEMBER: This workflow is MANDATORY. No exceptions. No bypasses.**

**✅ By following this CLAUDE.md configuration, every line of code will be:**
- Tracked to a Jira ticket
- Specified in Confluence
- Thoroughly tested
- Minimally intrusive
- Fully documented
- Performance validated