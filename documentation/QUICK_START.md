# 🚀 QUICK START - 5 MINUTE SETUP

## 1️⃣ Setup (30 seconds)
```bash
# Clone or copy these files to your project:
cp CLAUDE.md /your/project/
cp -r scripts/ /your/project/
cp .env.template /your/project/.env

# Edit credentials:
nano /your/project/.env
```

## 2️⃣ Create Jira Ticket (1 minute)
```
Go to Jira → Create Issue
- Type: Story/Task
- Summary: "Your feature"
- Status: Set to "In Progress"
- Assign: To yourself
Remember the ID: PROJ-XXX
```

## 3️⃣ Create Confluence Spec (2 minutes)
```
Go to Confluence → Create Page
Title: "PROJ-XXX Specification"

Paste this template:
---
## Acceptance Criteria
- [ ] Feature does X
- [ ] Feature handles Y

## Technical Requirements
- Language: [Python/JS/etc]
- Framework: [React/Django/etc]

## Security Requirements
- Authentication required
- Input validation

## Performance Requirements
- Response time < 200ms
- Handle 100 concurrent users
---

Link to Jira ticket!
```

## 4️⃣ Start Coding with Claude (30 seconds)
```bash
cd /your/project/

# Tell Claude:
"I need to work on Jira ticket PROJ-XXX"

# Claude takes over from here!
```

## 5️⃣ What Happens Automatically

### Claude Will:
✅ Validate your ticket exists  
✅ Fetch your Confluence spec  
✅ Create a dev session  
✅ Track all changes  
✅ Generate tests  
✅ Check coverage  
✅ Validate before commit  
✅ Update Jira/Confluence  

### You Cannot:
❌ Skip any validation  
❌ Commit without 80% coverage  
❌ Modify unauthorized files  
❌ Proceed without a ticket  
❌ Ignore test failures  

---

# 🎮 REAL EXAMPLE SESSION

```bash
You: "I need to implement user login for PROJ-123"

Claude: "Validating PROJ-123... ✓
        Fetching Confluence spec... ✓
        Creating session... ✓
        
        I'll implement the login feature according to the spec.
        Starting with authentication endpoint..."

[Claude writes code]

Claude: "Running tests... 
        Coverage: 85% ✓
        All tests passing ✓
        
        Ready to commit. Shall I proceed?"

You: "Yes"

Claude: "[PROJ-123] Implemented user login
        
        Tests: Unit (85%), Integration (100%)
        Jira and Confluence updated ✓"
```

---

# 🔥 THAT'S IT!

**No configuration beyond credentials needed.**  
**Claude enforces everything automatically.**  
**You just code.**

---

# 🆘 Troubleshooting

## "Claude isn't enforcing rules"
→ Make sure CLAUDE.md is in project root
→ Restart Claude Code session

## "Can't connect to Jira"
→ Check .env credentials
→ Verify API token is valid

## "Coverage check fails"
→ Claude will auto-generate more tests
→ Or run: ./scripts/run-tests.sh

## "Want to modify more files"
→ Update allowed_files.txt
→ Or tell Claude which files to add

---

**Remember: The system enforces itself. You don't need to remember the rules - Claude won't let you break them.**