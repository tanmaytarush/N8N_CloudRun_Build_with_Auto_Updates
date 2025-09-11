#!/bin/bash

# Deploy custom n8n container to Cloud Run
# This script uses the custom Dockerfile and startup.sh that forces proper port binding

set -e

# Configuration
PROJECT_ID="betterprep-main-account"
REGION="us-central1"
SERVICE_NAME="n8n-serverless"

echo "🚀 Building and deploying custom n8n container to Cloud Run..."

# Set project
gcloud config set project $PROJECT_ID

# Enable Container Registry API if not already enabled
echo "🔌 Enabling Container Registry API..."
gcloud services enable containerregistry.googleapis.com

# Configure Docker authentication for GCR
echo "🔐 Configuring Docker authentication for GCR..."
gcloud auth configure-docker

# Build custom n8n image and push to GCR
echo "📦 Building custom n8n image..."
docker build -t gcr.io/${PROJECT_ID}/n8n:latest .

echo "📤 Pushing image to GCR..."
docker push gcr.io/${PROJECT_ID}/n8n:latest

# Deploy to Cloud Run with GCR image
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
    --image=gcr.io/${PROJECT_ID}/n8n:latest \
    --port=5678 \
    --cpu=2 \
    --memory=4Gi \
    --timeout=900 \
    --region=${REGION} \
    --allow-unauthenticated \
    --set-env-vars="N8N_HOST=0.0.0.0,N8N_PORT=\$PORT,N8N_PROTOCOL=https,DB_TYPE=sqlite,DB_SQLITE_DATABASE=/tmp/n8n.db,DB_SQLITE_POOL_SIZE=3,N8N_USER_FOLDER=/tmp/.n8n,N8N_RUNNERS_ENABLED=true,N8N_BASIC_AUTH_ACTIVE=true,N8N_BASIC_AUTH_USER=tanmay@betterprep.ai,N8N_BASIC_AUTH_PASSWORD=M#x46\$\$LZ&fUtc2u,N8N_ENCRYPTION_KEY=2d51aedbfbffe89d9ad53182bd966398,N8N_EDITOR_BASE_URL=https://n8n-serverless-1069021792204.us-central1.run.app,N8N_WEBHOOK_URL=https://n8n-serverless-1069021792204.us-central1.run.app"

echo "✅ Deployment complete!"
echo "🔗 Service URL: https://n8n-serverless-1069021792204.us-central1.run.app"
echo ""
echo "📊 To check logs:"
echo "gcloud run logs tail ${SERVICE_NAME} --region=${REGION}"
echo ""
echo "🔍 To check service status:"
echo "gcloud run services describe ${SERVICE_NAME} --region=${REGION}"
