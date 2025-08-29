# Claude Code Project Development Lifecycle with MCP Integration

## 🔌 MCP (Model Context Protocol) Configuration

### Available MCP Tools
Claude Code can directly connect to Atlassian services via MCP:
- **mcp__jira_***: Direct Jira operations
- **mcp__confluence_***: Direct Confluence operations
- **mcp__github_***: GitHub integration (if available)

## 🚦 MANDATORY WORKFLOW ENFORCEMENT WITH MCP

### PHASE 1: Pre-Development Validation (MCP-Powered)

#### 1.1 Jira Ticket Verification via MCP
**STOP - DO NOT PROCEED WITHOUT COMPLETING:**
```markdown
1. Use MCP Jira tool to fetch ticket:
   - mcp__jira_get_issue(issue_key="PROJ-XXX")
   
2. Validate ticket attributes:
   - Status must be "In Progress" or "Development"
   - Assignee must match current user
   - Sprint must be active
   
3. Extract linked Confluence pages:
   - Check issue links for Confluence URLs
   - Parse description for specification references
```

#### 1.2 Confluence Specification Validation via MCP
**MANDATORY - NO CODE WITHOUT SPECS:**
```markdown
1. Use MCP Confluence tool to fetch specification:
   - mcp__confluence_get_page(page_id="xxx")
   - mcp__confluence_get_page_content(page_id="xxx")
   
2. Parse and validate specification contains:
   - [ ] Acceptance criteria (mandatory section)
   - [ ] Technical requirements (mandatory section)
   - [ ] API contracts (if applicable)
   - [ ] Database schema (if applicable)
   - [ ] Security requirements (mandatory section)
   - [ ] Performance SLAs (mandatory section)
   
3. Store specification locally:
   - Save as `spec_[TICKET-ID].md`
   - Create checklist from acceptance criteria
```

### PHASE 2: Development Mode with MCP Tracking

#### 2.1 Create MCP-Tracked Development Session
```markdown
1. Initialize session with MCP:
   - Create Jira comment: "Development started by Claude Code"
   - Create Confluence child page: "Dev Session [TICKET-ID] [DATE]"
   
2. For MODIFICATIONS:
   - Use mcp__jira_add_comment to log files being modified
   - Create Confluence table of allowed files
   - Set up file watchers for unauthorized changes
```

#### 2.2 Real-time MCP Synchronization
```markdown
CONTINUOUS MCP OPERATIONS (every 10 minutes):
1. Update Jira ticket:
   - mcp__jira_add_worklog(time_spent="10m")
   - mcp__jira_update_field(field="progress", value=%)
   
2. Update Confluence page:
   - mcp__confluence_update_page with current progress
   - Include code snippets of key changes
   - Update test coverage metrics
```

### PHASE 3: Development Execution with MCP

#### 3.1 Code Generation with Specification Compliance
```markdown
FOR EVERY FUNCTION/CLASS/MODULE:
1. Query Confluence spec via MCP:
   - mcp__confluence_search("acceptance criteria AND [feature_name]")
   
2. Validate implementation matches spec:
   - Cross-reference with Confluence requirements
   - Log compliance in Jira comments
```

#### 3.2 MCP-Powered Progress Tracking
```markdown
CREATE JIRA SUBTASKS AUTOMATICALLY:
- mcp__jira_create_issue(
    type="Sub-task",
    parent="[TICKET-ID]",
    summary="Unit tests for [component]"
  )
  
UPDATE SUBTASKS AS COMPLETED:
- mcp__jira_transition_issue(
    issue_key="[SUBTASK-ID]",
    transition="Done"
  )
```

### PHASE 4: Testing with MCP Reporting

#### 4.1 Test Execution and MCP Logging
```markdown
AFTER EACH TEST RUN:
1. Post to Jira:
   mcp__jira_add_attachment(
     issue_key="[TICKET-ID]",
     file="test_results.json"
   )
   
2. Update Confluence:
   mcp__confluence_create_page(
     title="Test Results [TICKET-ID] [TIMESTAMP]",
     content=test_report_html,
     parent_id=spec_page_id
   )
```

#### 4.2 Coverage Enforcement via MCP
```markdown
IF COVERAGE < 80%:
1. Create Jira blocker:
   mcp__jira_create_issue(
     type="Bug",
     priority="Blocker",
     summary="Coverage below 80% for [TICKET-ID]",
     blocks="[TICKET-ID]"
   )
   
2. Flag in Confluence:
   mcp__confluence_add_label(
     page_id=spec_page_id,
     label="coverage-failed"
   )
```

### PHASE 5: MCP-Integrated Pre-Commit

#### 5.1 Automated MCP Validation Chain
```markdown
PRE-COMMIT MCP SEQUENCE:
1. Verify Jira ticket is still valid:
   result = mcp__jira_get_issue(issue_key="[TICKET-ID]")
   assert result.status in ["In Progress", "Development"]
   
2. Check Confluence spec hasn't changed:
   spec = mcp__confluence_get_page_version(page_id, version)
   assert spec.version == original_version
   
3. Log commit intent:
   mcp__jira_add_comment(
     issue_key="[TICKET-ID]",
     body="Preparing commit: [description]"
   )
```

#### 5.2 MCP Commit Metadata
```markdown
ENRICH COMMIT WITH MCP DATA:
1. Fetch from Jira:
   - Epic link
   - Sprint name
   - Fix Version
   
2. Fetch from Confluence:
   - Spec URL
   - Spec version
   - Related documentation
   
3. Include in commit message:
   [TICKET-ID] Description
   
   Jira Epic: [EPIC-ID]
   Sprint: [Sprint Name]
   Spec: [Confluence URL]@v[version]
   Coverage: [X]%
   
   Co-authored-by: Claude <noreply@anthropic.com>
```

### PHASE 6: Post-Development MCP Workflows

#### 6.1 Comprehensive MCP Reporting
```markdown
GENERATE AND DISTRIBUTE REPORTS:
1. Create Confluence report page:
   mcp__confluence_create_page(
     title="Development Complete: [TICKET-ID]",
     content=comprehensive_report,
     parent_id=project_space_id
   )
   
2. Update Jira with summary:
   mcp__jira_add_comment(
     issue_key="[TICKET-ID]",
     body=summary_with_links
   )
   
3. Create PR with MCP metadata:
   - Link Jira ticket
   - Link Confluence spec
   - Add reviewers from Jira watchers
```

#### 6.2 MCP Transition Automation
```markdown
AUTOMATIC STATUS UPDATES:
1. When all tests pass:
   mcp__jira_transition_issue(
     issue_key="[TICKET-ID]",
     transition="Ready for Review"
   )
   
2. Create review checklist in Confluence:
   mcp__confluence_create_page(
     title="Review Checklist: [TICKET-ID]",
     content=review_template
   )
   
3. Notify reviewers via Jira:
   mcp__jira_assign_issue(
     issue_key="[TICKET-ID]",
     assignee=lead_reviewer
   )
```

## 📋 MCP-Powered Prompt Sequences

### Sequence 1: MCP Project Initialization
```markdown
1. "I'll use MCP to fetch Jira ticket [TICKET-ID]"
2. "Retrieving linked Confluence specification via MCP"
3. "Creating development session in both Jira and Confluence"
4. "MCP validation complete. Ready to begin development"
```

### Sequence 2: MCP Progress Updates
```markdown
Every 10 minutes:
1. "Updating Jira ticket with current progress via MCP"
2. "Syncing code changes to Confluence page"
3. "Creating subtasks for remaining work"
4. "MCP sync complete"
```

### Sequence 3: MCP Test Orchestration
```markdown
1. "Running tests and streaming results to Jira via MCP"
2. "Creating Confluence test report page"
3. "Updating ticket status based on test results"
4. "MCP test reporting complete"
```

## 🔄 MCP Continuous Compliance Monitor

### Background MCP Monitor
```python
# mcp_monitor.py
import asyncio
from datetime import datetime

async def mcp_compliance_check():
    while True:
        # Check Jira ticket status
        ticket = await mcp__jira_get_issue(CURRENT_TICKET)
        if ticket.status not in ["In Progress", "Development"]:
            await mcp__jira_add_comment(
                issue_key=CURRENT_TICKET,
                body=f"⚠️ Ticket not in active development status at {datetime.now()}"
            )
        
        # Check Confluence spec version
        spec = await mcp__confluence_get_page(SPEC_PAGE_ID)
        if spec.version != ORIGINAL_VERSION:
            await mcp__jira_create_issue(
                type="Bug",
                summary=f"Spec changed during development of {CURRENT_TICKET}",
                priority="High"
            )
        
        # Update progress in Jira
        await mcp__jira_update_field(
            issue_key=CURRENT_TICKET,
            field="customfield_progress",
            value=calculate_progress()
        )
        
        # Log to Confluence
        await mcp__confluence_append_page(
            page_id=SESSION_PAGE_ID,
            content=f"Progress check: {datetime.now()}"
        )
        
        await asyncio.sleep(600)  # Check every 10 minutes
```

## 🛡️ MCP Enforcement Rules

### ABSOLUTE MCP-ENFORCED RULES:
1. **Every code file must trace to Jira ticket via MCP**
2. **Every ticket must have Confluence spec verified by MCP**
3. **Every commit must update both Jira and Confluence via MCP**
4. **Every test result must be logged via MCP**
5. **Every PR must link to Jira/Confluence via MCP**

### MCP Violation Handling:
```python
async def handle_mcp_violation(violation_type, details):
    # Create blocker in Jira
    blocker = await mcp__jira_create_issue(
        type="Bug",
        priority="Blocker",
        summary=f"MCP Violation: {violation_type}",
        description=details,
        blocks=CURRENT_TICKET
    )
    
    # Flag in Confluence
    await mcp__confluence_add_label(
        page_id=SPEC_PAGE_ID,
        label=f"violation-{violation_type}"
    )
    
    # Stop all operations
    raise MCPViolationError(f"Critical violation: {violation_type}")
```

## 🎯 MCP Success Metrics Dashboard

### Real-time MCP Metrics:
```markdown
Query via MCP every 30 minutes:
1. Jira Metrics:
   - mcp__jira_search("project = PROJ AND creator = claude")
   - Calculate compliance rate
   - Track velocity
   
2. Confluence Metrics:
   - mcp__confluence_search("label = claude-generated")
   - Count documentation pages
   - Measure spec coverage
   
3. Combined Dashboard:
   - Create Confluence dashboard page
   - Update with real-time metrics
   - Link from Jira project page
```

## 🔌 MCP Tool Priority

### ALWAYS PREFER MCP TOOLS:
```markdown
Instead of:              Use:
- curl to Jira API  →   mcp__jira_* tools
- curl to Confluence →  mcp__confluence_* tools  
- manual updates    →   MCP automated updates
- file-based specs  →   MCP live spec fetching
```

## 🚀 MCP Quick Commands

### Check Everything via MCP:
```markdown
1. mcp__jira_get_issue("[TICKET-ID]")
2. mcp__confluence_get_page("[SPEC-PAGE-ID]")
3. mcp__jira_get_comments("[TICKET-ID]")
4. mcp__confluence_get_attachments("[PAGE-ID]")
```

### Update Everything via MCP:
```markdown
1. mcp__jira_add_worklog("[TICKET-ID]", "1h", "Coding")
2. mcp__confluence_update_page("[PAGE-ID]", new_content)
3. mcp__jira_transition_issue("[TICKET-ID]", "In Review")
4. mcp__confluence_add_attachment("[PAGE-ID]", file)
```

---

**⚠️ CRITICAL: With MCP integration, there are NO EXCUSES for non-compliance.**
**Every action is tracked, validated, and enforced through direct Atlassian integration.**

**✅ MCP ensures:**
- Real-time validation
- Automatic documentation
- Instant compliance checking
- Zero manual overhead
- Complete traceability