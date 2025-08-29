# AI_AGE_SDLC - Complete Development Lifecycle System

A comprehensive, AI-driven software development lifecycle with full automation from ticket to production.

## 🌟 Version 2.0 - AI_AGE_SDLC Framework

This system implements the complete **AI-Driven Age Software Development Lifecycle**, providing:
- **Full Repository Management** (NEW/MODIFICATION projects)
- **Intelligent Branch Stacking** on develop baseline
- **Automated Testing Orchestration** (unit, integration, stress, security)
- **Self-Healing Workflows** with error recovery
- **Complete Traceability** from Jira to production

## 🎯 Core Principles

1. **No code without Jira ticket**
2. **No Jira ticket without Confluence specification**  
3. **No commit without 80% test coverage**
4. **No modification outside authorized files**
5. **No push without stress test validation**

## 🚀 Quick Start

### 1. Quick Setup

```bash
# Use the master orchestrator
./workflows/ai_age_sdlc_master.sh

# Or configure manually
cp .env.template .env
# Edit .env with your credentials
```

### 2. Choose Your Mode

**Option A: Complete Automation**
```bash
./workflows/ai_age_sdlc_master.sh
# Select option 6: Full Automated Workflow
```

**Option B: Step-by-Step**
```bash
# For NEW projects
./workflows/ai_age_sdlc_master.sh
# Select option 1: Setup NEW Project

# For MODIFICATION projects  
./workflows/ai_age_sdlc_master.sh
# Select option 2: Setup MODIFICATION Project
```

### 4. Start Compliance Monitor

```bash
# In a separate terminal
./compliance_monitor.sh
```

### 5. Develop with Claude Code

Claude Code will automatically:
- Validate Jira ticket exists
- Fetch Confluence specification
- Enforce modification boundaries
- Track all changes
- Require comprehensive testing

### 6. Run Tests

```bash
./scripts/run-tests.sh
```

### 7. Pre-commit Validation

```bash
./scripts/pre-commit-check.sh
```

### 8. Generate Report

```bash
./scripts/generate-report.sh
```

## 📁 Project Structure

```
project_dev_lifecycle/
├── CLAUDE.md                      # Main Claude Code configuration
├── README.md                      # This file
├── package.json                   # Node.js configuration
├── tsconfig.json                  # TypeScript configuration
├── .env.template                  # Environment template
├── .env                          # Your credentials (gitignored)
│
├── src/                          # Source code
│   ├── amb/                      # AMB implementation example
│   └── *.{js,ts}                # Other source files
│
├── tests/                        # Test suites
│   ├── amb/                      # AMB tests
│   └── *.test.js                # Other tests
│
├── documentation/                # Primary documentation
│   ├── CLAUDE_AI_AGE_SDLC.md    # Complete SDLC framework (1400+ lines)
│   └── QUICK_START.md           # Quick start guide
│
├── doc/                         # Session documentation
│   ├── SESSION_PROMPTS_AND_RESULTS.md  # Complete session log
│   ├── AINV-707_FORMAL_PROMPTS.md      # Reusable prompt templates
│   └── AMB_FIX_HALLUCINATION_SPEC.MD   # Technical specifications
│
├── workflows/                   # Automation workflows
│   ├── ai_age_sdlc_master.sh   # Master orchestrator (MAIN ENTRY POINT)
│   ├── compliance-monitor.sh    # Real-time monitoring
│   ├── generate-report.sh       # Report generation
│   └── *.sh                    # Other workflow scripts
│
├── tools/                      # Development tools
│   ├── mcp_integration.py      # MCP integration
│   └── *.py                   # Other tools
│
├── config/                     # Configuration files
│   ├── mcp_config.json        # MCP settings
│   └── CLAUDE_MCP.md          # MCP documentation
│
└── backup/                     # Archived files
    ├── logs/                   # Old log files
    ├── reports/                # Old reports
    ├── demo_files/             # Demo/temp files
    └── duplicate_docs/         # Old documentation
```

## 🔒 Enforcement Features

### Jira Integration
- Validates ticket exists and is assigned
- Checks ticket status (In Progress/Development)
- Updates ticket with progress and results

### Confluence Integration  
- Fetches linked specification
- Validates acceptance criteria
- Uploads development reports

### Testing Requirements
- Unit tests: 80% minimum coverage
- Integration tests: All endpoints/integrations
- Stress tests: 100 users, 5 minutes, 99.9% success
- Security scanning: No moderate+ vulnerabilities

### Modification Control
- Pre-modification snapshots
- Authorized file whitelist
- Continuous change tracking
- Diff reports for all changes

## 🛠️ Workflow Commands

### Start New Project
```bash
./scripts/validate-ticket.sh PROJ-123
./scripts/init-development.sh
# Select option 1 (New Project)
```

### Modify Existing Code
```bash
./scripts/validate-ticket.sh PROJ-123
./scripts/init-development.sh
# Select option 2 (Modification)
# List allowed files when prompted
```

### Run Full Test Suite
```bash
./scripts/run-tests.sh
# Runs unit, integration, stress, and security tests
```

### Validate Before Commit
```bash
./scripts/pre-commit-check.sh
# Checks all requirements before allowing commit
```

### Generate Comprehensive Report
```bash
./scripts/generate-report.sh
# Creates markdown report and uploads to Confluence
```

## 📊 Monitoring

The compliance monitor runs continuously and checks:
- Jira ticket status
- Unauthorized file modifications  
- Test coverage levels
- Security vulnerabilities

Run in separate terminal:
```bash
./compliance_monitor.sh
```

## 🔧 Configuration

Edit `.env` file:
```bash
JIRA_URL=https://your-domain.atlassian.net
JIRA_EMAIL=your-email@company.com
JIRA_API_TOKEN=your-token

CONFLUENCE_URL=https://your-domain.atlassian.net/wiki
CONFLUENCE_EMAIL=your-email@company.com
CONFLUENCE_API_TOKEN=your-token

GITHUB_OWNER=your-org
GITHUB_REPO=your-repo
GITHUB_TOKEN=your-token

MIN_TEST_COVERAGE=80
STRESS_TEST_USERS=100
```

## 📝 Commit Message Format

```
[PROJ-123] Brief description

- Detailed change 1
- Detailed change 2

Confluence Spec: https://confluence.url/page/id
Tests: Unit (85%), Integration (100%), Stress (Passed)

Co-authored-by: Claude <noreply@anthropic.com>
```

## ⚠️ Important Notes

1. **CLAUDE.md is the source of truth** - Claude Code will follow these rules strictly
2. **No bypassing allowed** - All checks are mandatory
3. **Tests must pass** - 80% coverage minimum
4. **Security first** - No vulnerabilities allowed
5. **Track everything** - All changes logged and reported

## 🆘 Troubleshooting

### Jira Connection Issues
```bash
# Test Jira connection
curl -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
  ${JIRA_URL}/rest/api/2/myself
```

### Confluence Connection Issues
```bash
# Test Confluence connection
curl -u ${CONFLUENCE_EMAIL}:${CONFLUENCE_API_TOKEN} \
  ${CONFLUENCE_URL}/rest/api/content?limit=1
```

### Coverage Not Met
```bash
# Generate coverage report
npm test -- --coverage
# or
pytest --cov=. --cov-report=html
```

## 📚 Additional Resources

- [Jira API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v2/)
- [Confluence API Documentation](https://developer.atlassian.com/cloud/confluence/rest/)
- [GitHub API Documentation](https://docs.github.com/en/rest)

---

**Remember:** This system enforces discipline. No exceptions. No bypasses. Every line of code is tracked, tested, and validated.