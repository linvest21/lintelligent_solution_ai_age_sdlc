#!/bin/bash

# Load environment variables from .env file
# Usage: source load_env.sh

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Environment variables loaded from .env"
    echo "   JIRA_URL: $JIRA_URL"
    echo "   CONFLUENCE_URL: $CONFLUENCE_URL"
    echo "   GitHub configured: $([ -n "$GITHUB_TOKEN" ] && echo "Yes" || echo "No")"
else
    echo "❌ Error: .env file not found"
    echo "   Please create a .env file with your credentials"
    exit 1
fi