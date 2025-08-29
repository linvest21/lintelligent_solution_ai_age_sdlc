#!/bin/bash
# AI_AGE_SDLC Project Startup Script

echo "🚀 Starting AI_AGE_SDLC for this project..."

# Check if environment is configured
if [[ ! -f ".env" ]]; then
    if [[ -f ".env.template" ]]; then
        echo "⚠️ Environment not configured. Copying template..."
        cp .env.template .env
        echo "📝 Please edit .env with your credentials, then run this script again."
        exit 1
    else
        echo "❌ No .env or .env.template found. Please run setup_ai_age_sdlc.sh first."
        exit 1
    fi
fi

# Validate that required credentials are present
source .env
if [[ -z "$JIRA_URL" ]] || [[ -z "$JIRA_EMAIL" ]] || [[ -z "$JIRA_API_TOKEN" ]]; then
    echo "⚠️ Missing required Jira credentials in .env file"
    echo "Please edit .env and add your Jira credentials"
    exit 1
fi

echo "✅ Environment configured and validated"

# Start the main SDLC orchestrator
exec ./ai_age_sdlc_master.sh
