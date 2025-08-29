# AINV-707: Formal Prompts Documentation
## Project Development Lifecycle - AMB Hallucination Fix Implementation

### Document Information
- **Created**: 2025-08-29
- **Author**: david.d.lin@linvest21.com
- **Jira Ticket**: AINV-707
- **Purpose**: Formal documentation of prompts used in the development lifecycle

---

## 1. Initial Project Context Prompt

### User Prompt #1:
```
what should I as next step?
```

### Formal Prompt Template:
```
Given the current project state with the mandatory CLAUDE.md workflow enforcement:
1. Identify the current phase of development
2. Check for any incomplete prerequisites
3. Provide the next mandatory step according to the workflow
4. List required actions in priority order
```

### Expected Response Pattern:
- Verification of environment setup
- Check for Jira ticket requirement
- Validate Confluence specification requirement
- Determine development mode (NEW/MODIFICATION)

---

## 2. Jira Ticket Assignment Prompt

### User Prompt #2:
```
jira ticker id: "AINV-532". Development type: Modification.
```

### Formal Prompt Template:
```
For Jira ticket [TICKET-ID] with development type [NEW|MODIFICATION]:
1. Validate ticket exists in Jira system
2. Verify ticket status is "In Progress" or "Development"
3. Confirm ticket is assigned to current user
4. Fetch linked Confluence specification
5. If MODIFICATION: List authorized files for changes
6. Create pre-modification snapshot if applicable
```

### Validation Checklist:
- [ ] Ticket exists in Jira
- [ ] Status is appropriate for development
- [ ] Assignee matches current user
- [ ] Confluence spec is linked
- [ ] Authorized files are defined

---

## 3. Ticket Reassignment Prompt

### User Prompt #3:
```
jira ticker id: "AINV-707". Development type: Modification.
```

### Formal Prompt Template:
```
When ticket validation fails, execute fallback workflow:
1. Identify validation failures
2. Provide corrective actions needed
3. List prerequisites that must be met
4. Suggest alternative tickets if applicable
5. Document the validation failure reason
```

---

## 4. Jira Ticket Management Prompt

### User Prompt #4:
```
Pls assign AINV-707 to me, and change status to "In progress" first, and tell me next step?
```

### Formal Prompt Template:
```
Execute Jira ticket management operations:
1. Assign ticket [TICKET-ID] to user [EMAIL]
   - Get user account ID from email
   - Execute assignment API call
2. Update ticket status to "In Progress"
   - Get available transitions
   - Execute status transition
3. Verify all changes were successful
4. Provide next steps in the workflow
```

### API Operations Required:
```bash
# Get user account ID
curl -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
  -X GET \
  "https://${JIRA_URL}/rest/api/2/user/search?query=${USER_EMAIL}"

# Assign ticket
curl -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{"fields":{"assignee":{"accountId":"[ACCOUNT_ID]"}}}' \
  "https://${JIRA_URL}/rest/api/2/issue/${TICKET_ID}"

# Update status
curl -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"transition":{"id":"[TRANSITION_ID]"}}' \
  "https://${JIRA_URL}/rest/api/2/issue/${TICKET_ID}/transitions"
```

---

## 5. Specification Upload Prompt

### User Prompt #5:
```
pls upload the spec doc named "AMB_FIX_HALLUCINATION_SPEC.MD" in "doc" directory.
```

### Formal Prompt Template:
```
Upload specification document to designated location:
1. Locate source document at [SOURCE_PATH]
2. Determine target location ([LOCAL_DIR|CONFLUENCE])
3. If local: Move/copy to specified directory
4. If Confluence: Create page with proper hierarchy
5. Maintain naming convention as specified
6. Verify upload success
```

### File Operations:
```bash
# Local file movement
mv [SOURCE_PATH] [DEST_DIR]/[FILENAME]

# Confluence upload
./upload_to_confluence.sh [SPEC_FILE]
```

---

## 6. Confluence Directory Structure Prompt

### User Prompt #6:
```
where is the spec in confluence's directory tree structure?
```

### Formal Prompt Template:
```
Query and report Confluence documentation location:
1. List available Confluence spaces
2. Identify relevant space for documentation type
3. Check for existing directory/page structure
4. Create missing directories if authorized
5. Upload documentation to correct location
6. Report full hierarchical path
7. Provide direct access links
```

### Confluence Hierarchy Query:
```bash
# List spaces
curl -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
  -X GET \
  "${CONFLUENCE_URL}/rest/api/space"

# Get page hierarchy
curl -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
  -X GET \
  "${CONFLUENCE_URL}/rest/api/content?spaceKey=[SPACE_KEY]&type=page"
```

---

## 7. Documentation Generation Prompt

### User Prompt #7:
```
pls write down formal prompts for prompts I have written, to "doc" directory.
```

### Formal Prompt Template:
```
Generate formal documentation from session history:
1. Extract all user prompts from current session
2. Analyze prompt intent and context
3. Create formal prompt templates for each
4. Include expected responses and patterns
5. Document API calls and operations
6. Add validation checklists
7. Save to specified documentation directory
```

---

## Workflow Automation Prompts

### A. Pre-Development Validation Prompt
```
Validate all prerequisites for ticket [TICKET-ID]:
1. Verify Jira ticket status and assignment
2. Check Confluence specification exists
3. Validate specification completeness:
   - Acceptance criteria
   - Technical requirements
   - Authorized files list
   - Test requirements
4. Return validation status with specific failures
```

### B. Implementation Execution Prompt
```
Implement solution for [TICKET-ID] according to specification:
1. Create pre-modification snapshot
2. Generate required directory structure
3. Implement each authorized file:
   - Follow specification requirements
   - Include comprehensive error handling
   - Add logging and monitoring
   - Implement with test-driven approach
4. Validate implementation against spec
```

### C. Testing and Validation Prompt
```
Execute comprehensive testing for [TICKET-ID]:
1. Run unit tests with coverage report
2. Verify minimum 80% coverage threshold
3. Execute integration tests if applicable
4. Run performance/stress tests
5. Generate test report with metrics
6. Fail fast on any threshold violation
```

### D. Compliance Reporting Prompt
```
Generate compliance report for [TICKET-ID]:
1. Verify all workflow steps completed
2. Check test coverage meets requirements
3. Validate no unauthorized file modifications
4. Generate development report
5. Upload report to Confluence
6. Update Jira ticket with status
7. Link all artifacts for traceability
```

---

## Prompt Engineering Best Practices

### 1. Clarity and Specificity
- Always include ticket ID in prompts
- Specify development type explicitly
- Define target locations clearly
- Use exact filenames and paths

### 2. Validation Requirements
- Request confirmation of prerequisites
- Ask for validation before proceeding
- Require explicit success/failure reporting
- Include rollback instructions

### 3. Traceability
- Reference Jira tickets in all operations
- Link Confluence pages to tickets
- Maintain audit trail of changes
- Document decision rationale

### 4. Error Handling
- Anticipate common failure modes
- Provide clear error messages
- Include recovery procedures
- Document workarounds

---

## Example Composite Prompt

### Complete Development Cycle Prompt:
```
For Jira ticket AINV-XXX:
1. Validate ticket and assign to me if needed
2. Update status to "In Progress"
3. Create/verify Confluence specification at path: /Technology/AI/[TICKET-ID]
4. List authorized files for modification
5. Create pre-modification snapshot
6. Implement solution per specification
7. Generate tests with 80% minimum coverage
8. Run all validation checks
9. Generate and upload development report
10. Update Jira with completion status

Report each step's status and stop on any failure.
```

---

## Command Shortcuts Reference

### Quick Commands:
```bash
# Validate ticket
./jira-confluence-helper.sh validate [TICKET-ID]

# Assign and start ticket
./jira-confluence-helper.sh assign [TICKET-ID] [EMAIL]
./jira-confluence-helper.sh start [TICKET-ID]

# Upload specification
./upload_to_confluence.sh [SPEC_FILE]

# Run tests
npm test -- --coverage

# Generate report
./generate-report.sh [TICKET-ID]
```

---

## Notes

1. All prompts assume CLAUDE.md workflow is mandatory
2. No code without Jira ticket and Confluence spec
3. Minimum 80% test coverage is non-negotiable
4. All modifications must be in authorized files only
5. Stress testing required before commit
6. Development reports must be uploaded to Confluence

---

*This document serves as a reference for formal prompt patterns used in the AINV-707 implementation and can be reused for similar development tasks following the mandatory workflow.*