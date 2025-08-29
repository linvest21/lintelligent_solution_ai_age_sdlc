#!/bin/bash
# AI_AGE_SDLC Project Startup Script

echo "🚀 Starting AI_AGE_SDLC for this project..."

# Check if environment is configured
if [[ ! -f ".env" ]]; then
    echo "⚠️ Environment not configured. Copying template..."
    cp .env.template .env
    echo "📝 Please edit .env with your credentials, then run this script again."
    exit 1
fi

# Start the main SDLC orchestrator
exec ./scripts/ai_age_sdlc_master.sh
