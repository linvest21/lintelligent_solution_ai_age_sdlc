# 🎯 AI_AGE_SDLC - How It Works

## ⚡ Quick Summary

**🚫 AI_AGE_SDLC IS 100% ENFORCED - ZERO TOLERANCE! 🚫**

**CLAUDE.md IS THE SDLC FRAMEWORK** - Not the shell scripts!

**⚠️ ABSOLUTE ENFORCEMENT: Every single line of code MUST follow this process ⚠️**

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

## 📋 The CORRECT Workflow Sequence (MANDATORY ORDER!)

### ⚠️ STEP 0: SETUP SERVICES FIRST (MANDATORY!)
```bash
# 1. Run service setup wizard - MUST BE FIRST!
./setup_sdlc_services.sh

# 2. Validate all connections work
./validate_sdlc_setup.sh

# 3. Must show ALL GREEN before proceeding
```

**🚫 Claude will REFUSE to work without this setup complete! 🚫**

### STEP 1: Start Development Session with Claude
When you open Claude Code, the sequence is:

1. **Claude validates setup** using `claude_setup_validator.sh`
2. **Claude demands Jira ticket ID** - no exceptions
3. **Claude fetches Confluence spec** from the Jira ticket link
4. **Claude enforces all development phases**:
   - PHASE 1: Pre-Development Validation
   - PHASE 2: Development Mode Selection  
   - PHASE 3: Development Execution
   - PHASE 4: Testing Requirements (80% coverage)
   - PHASE 5: Pre-Commit Validation
   - PHASE 6: Post-Development Validation

### Step 3: Claude Enforces Rules with ZERO TOLERANCE
Claude will **ABSOLUTELY REFUSE** to proceed with:
- ❌ **WRITING ANY CODE** without a validated Jira ticket
- ❌ **COMMITTING ANYTHING** without 80% test coverage
- ❌ **MODIFYING FILES** outside authorized scope
- ❌ **BYPASSING ANY RULE** under any circumstances
- 🛑 **IMMEDIATE STOP** if any violation is detected
- ✅ **100% ENFORCEMENT** of all SDLC policies with no exceptions

## 🚫 Common Misconceptions

### ❌ WRONG: "The shell scripts run the SDLC"
**Reality**: Shell scripts only set up the environment

### ❌ WRONG: "I need to run scripts to enforce SDLC"
**Reality**: CLAUDE.md is automatically enforced by Claude Code

### ❌ WRONG: "The framework is in the scripts"
**Reality**: The framework is the CLAUDE.md configuration file

## ✅ How to Use Correctly

1. **MANDATORY SETUP FIRST** (before ANY development):
   ```bash
   # Step 1: Configure all services
   ./setup_sdlc_services.sh
   
   # Step 2: Validate connections
   ./validate_sdlc_setup.sh
   
   # Step 3: Must show ALL services ready
   ```

2. **Development Session** (every time):
   ```
   You: "Help me implement a new feature"
   Claude: [Runs setup validation first]
   Claude: "Setup validated. Please provide Jira ticket ID"
   You: "AISD-123"  
   Claude: [Validates ticket, fetches Confluence spec]
   Claude: "Specification found. Ready to proceed with development."
   ```

3. **The Correct Interaction Flow**:
   ```
   ✅ Services Setup Complete
   ✅ Jira Ticket: AISD-123 validated
   ✅ Confluence Spec: Found and validated  
   ✅ Ready for SDLC-compliant development
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