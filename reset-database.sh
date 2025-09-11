#!/bin/bash

# Script to reset n8n database and allow fresh owner setup
# This will clear the existing database and allow you to create a new owner

echo "🔄 Resetting n8n database to allow fresh owner setup..."

# Configuration
PROJECT_ID="betterprep-main-account"
REGION="us-central1"
SERVICE_NAME="n8n-serverless"

# Set project
gcloud config set project $PROJECT_ID

# Update the service to clear the database and allow fresh setup
echo "📝 Updating service configuration..."
gcloud run services update $SERVICE_NAME \
    --region=$REGION \
    --set-env-vars="N8N_SKIP_OWNER_SETUP=false,N8N_DISABLE_UI=false,DB_TYPE=sqlite,DB_SQLITE_DATABASE=/tmp/n8n-new.db" \
    --min-instances=1

echo "✅ Database reset complete!"
echo ""
echo "🌐 Now you can access n8n at: https://n8n-serverless-1069021792204.us-central1.run.app"
echo "👤 You should now be able to create a new owner account"
echo ""
echo "📋 Steps to create owner:"
echo "1. Visit the URL above"
echo "2. Fill in the owner setup form"
echo "3. Create your admin account"
echo "4. Start using n8n!"
