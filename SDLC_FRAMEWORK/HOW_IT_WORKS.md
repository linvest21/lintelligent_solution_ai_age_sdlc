# 🎯 AI_AGE_SDLC - How It Works

## ⚡ Quick Summary

**CLAUDE.md IS THE SDLC FRAMEWORK** - Not the shell scripts!

The shell scripts (`setup_ai_age_sdlc.sh`) are ONLY for:
- Initial directory structure creation
- Copying template files
- Setting up .env configuration

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│            CLAUDE.md                     │
│   (The Actual SDLC Framework)           │
│                                         │
│  • Enforces Jira ticket requirements   │
│  • Validates Confluence specs          │
│  • Mandates 80% test coverage         │
│  • Controls development workflow       │
│  • Defines commit standards           │
└─────────────────────────────────────────┘
              ↑
              │ READS & ENFORCES
              │
┌─────────────────────────────────────────┐
│         Claude Code (AI)                │
│                                         │
│  When you work with Claude Code,       │
│  it reads CLAUDE.md and enforces       │
│  all the rules automatically           │
└─────────────────────────────────────────┘

## 📋 The Real Workflow (CLAUDE.md-based)

### Step 1: Setup (One-time only)
```bash
# Run setup to create structure and .env
cd SDLC_FRAMEWORK
./setup_ai_age_sdlc.sh
```

### Step 2: Development (CLAUDE.md takes over)
When you start coding with Claude Code:

1. **Claude reads CLAUDE.md** automatically
2. **Enforces all phases**:
   - PHASE 1: Pre-Development (Jira ticket required)
   - PHASE 2: Development Mode Selection
   - PHASE 3: Development Execution
   - PHASE 4: Testing Requirements (80% coverage)
   - PHASE 5: Pre-Commit Validation
   - PHASE 6: Post-Development Validation

### Step 3: Claude Enforces Rules
Claude will:
- ❌ **REFUSE** to write code without a Jira ticket
- ❌ **REFUSE** to commit without 80% test coverage
- ❌ **REFUSE** to modify unauthorized files
- ✅ **ENFORCE** all SDLC policies automatically

## 🚫 Common Misconceptions

### ❌ WRONG: "The shell scripts run the SDLC"
**Reality**: Shell scripts only set up the environment

### ❌ WRONG: "I need to run scripts to enforce SDLC"
**Reality**: CLAUDE.md is automatically enforced by Claude Code

### ❌ WRONG: "The framework is in the scripts"
**Reality**: The framework is the CLAUDE.md configuration file

## ✅ How to Use Correctly

1. **Initial Setup** (once):
   ```bash
   ./setup_ai_age_sdlc.sh  # Creates structure & .env
   ```

2. **Daily Development**:
   - Open your project in Claude Code
   - CLAUDE.md is automatically loaded
   - Start coding - Claude enforces all rules

3. **Example Interaction**:
   ```
   You: "Help me implement a new feature"
   Claude: "Please provide the Jira ticket ID for this task"
   You: "AINV-707"
   Claude: [Validates ticket, fetches Confluence spec, enforces workflow]
   ```

## 📁 File Responsibilities

| File | Purpose | When Used |
|------|---------|-----------|
| **CLAUDE.md** | The actual SDLC framework rules | ALWAYS - Claude reads this automatically |
| setup_ai_age_sdlc.sh | Initial project setup | ONCE - during project initialization |
| .env | Stores credentials | Runtime - for API calls |
| ai_age_sdlc_master.sh | Optional automation helper | Optional - for CI/CD |

## 🔑 Key Points

1. **CLAUDE.md = The Framework**
   - Contains all enforcement rules
   - Defines the complete workflow
   - Claude Code reads and enforces it

2. **Shell Scripts = Setup Tools**
   - Create directories
   - Copy templates
   - Configure environment

3. **Claude Code = The Enforcer**
   - Reads CLAUDE.md
   - Enforces all rules
   - Blocks non-compliant actions

## 📚 Documentation Structure

- **CLAUDE.md** - The framework configuration (THIS IS THE SDLC!)
- **docs/CLAUDE_AI_AGE_SDLC.md** - Extended documentation
- **HOW_IT_WORKS.md** - This file (explains the architecture)
- **README.md** - Project overview

## 🎯 Remember

**CLAUDE.md IS the AI_AGE_SDLC framework!**

The shell scripts are just helpers for initial setup. Once CLAUDE.md is in place, Claude Code handles everything automatically through the configuration.

---

*The power of AI_AGE_SDLC is that it's configuration-driven, not script-driven. Claude Code reads CLAUDE.md and enforces enterprise SDLC practices automatically.*