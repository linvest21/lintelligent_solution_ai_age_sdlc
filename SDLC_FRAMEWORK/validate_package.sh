#!/bin/bash
# SDLC_FRAMEWORK Package Validation Script
# Ensures package integrity before shipping

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 AI_AGE_SDLC Package Validation${NC}"
echo "=================================="

ERRORS=0
WARNINGS=0

check_file() {
    local file=$1
    local description=$2
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅ $description${NC}"
    else
        echo -e "${RED}❌ Missing: $file ($description)${NC}"
        ((ERRORS++))
    fi
}

check_executable() {
    local file=$1
    local description=$2
    
    if [[ -f "$file" && -x "$file" ]]; then
        echo -e "${GREEN}✅ $description (executable)${NC}"
    elif [[ -f "$file" ]]; then
        echo -e "${YELLOW}⚠️ $file exists but not executable${NC}"
        ((WARNINGS++))
    else
        echo -e "${RED}❌ Missing: $file ($description)${NC}"
        ((ERRORS++))
    fi
}

check_directory() {
    local dir=$1
    local description=$2
    
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✅ $description${NC}"
    else
        echo -e "${RED}❌ Missing directory: $dir ($description)${NC}"
        ((ERRORS++))
    fi
}

echo ""
echo "📦 Checking Package Structure..."

# Check main files
check_executable "setup_ai_age_sdlc.sh" "Linux/MacOS setup script"
check_file "setup_ai_age_sdlc.bat" "Windows setup script"
check_file "README.md" "Package documentation"

# Check directories
check_directory "core" "Core SDLC files"
check_directory "scripts" "Automation scripts"  
check_directory "docs" "Documentation"
check_directory "config" "Configuration files"

echo ""
echo "🔧 Checking Core Files..."

# Core files
check_file "core/CLAUDE.md" "Claude Code configuration"
check_file "core/CLAUDE_AI_AGE_SDLC.md" "Complete SDLC framework"

# Scripts
check_executable "scripts/ai_age_sdlc_master.sh" "Master orchestrator"

# Documentation
check_file "docs/SESSION_PROMPTS_AND_RESULTS.md" "Session documentation"
check_file "docs/AINV-707_FORMAL_PROMPTS.md" "Formal prompts"

# Configuration
check_file "config/mcp_config.json" "MCP configuration"
check_file "config/CLAUDE_MCP.md" "MCP documentation"

echo ""
echo "📄 Checking File Sizes..."

# Check for reasonable file sizes
check_size() {
    local file=$1
    local min_size=$2
    local description=$3
    
    if [[ -f "$file" ]]; then
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        if [[ $size -gt $min_size ]]; then
            echo -e "${GREEN}✅ $description (${size} bytes)${NC}"
        else
            echo -e "${YELLOW}⚠️ $description seems small (${size} bytes)${NC}"
            ((WARNINGS++))
        fi
    fi
}

check_size "setup_ai_age_sdlc.sh" 10000 "Setup script"
check_size "core/CLAUDE_AI_AGE_SDLC.md" 50000 "SDLC framework"
check_size "docs/SESSION_PROMPTS_AND_RESULTS.md" 20000 "Session documentation"

echo ""
echo "🔧 Testing Script Syntax..."

# Test bash script syntax
if bash -n setup_ai_age_sdlc.sh; then
    echo -e "${GREEN}✅ Linux setup script syntax valid${NC}"
else
    echo -e "${RED}❌ Linux setup script has syntax errors${NC}"
    ((ERRORS++))
fi

if bash -n scripts/ai_age_sdlc_master.sh; then
    echo -e "${GREEN}✅ Master orchestrator syntax valid${NC}"
else
    echo -e "${RED}❌ Master orchestrator has syntax errors${NC}"
    ((ERRORS++))
fi

echo ""
echo "📋 Validation Summary"
echo "===================="

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}🎉 Package validation PASSED!${NC}"
    echo -e "${GREEN}✅ Ready for shipping${NC}"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}⚠️ Package validation PASSED with warnings${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${GREEN}✅ Ready for shipping (minor issues)${NC}"
    exit 0
else
    echo -e "${RED}❌ Package validation FAILED${NC}"
    echo -e "${RED}Errors: $ERRORS${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}🛑 NOT ready for shipping${NC}"
    exit 1
fi