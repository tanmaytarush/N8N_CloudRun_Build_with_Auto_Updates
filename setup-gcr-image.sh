#!/bin/bash

# Setup script to pull n8n image from external registry and push to GCR
# This resolves the issue with Cloud Run not supporting external registries

set -e

# Configuration
PROJECT_ID="betterprep-main-account"
REGION="us-central1"

echo "🚀 Setting up n8n image in Google Container Registry..."

# Set project
gcloud config set project $PROJECT_ID

# Enable Container Registry API if not already enabled
echo "🔌 Enabling Container Registry API..."
gcloud services enable containerregistry.googleapis.com

# Configure Docker authentication for GCR
echo "🔐 Configuring Docker authentication for GCR..."
gcloud auth configure-docker

# Pull the n8n image from external registry
echo "📦 Pulling n8n image from docker.n8n.io..."
docker pull docker.n8n.io/n8nio/n8n:latest

# Tag the image for GCR
echo "🏷️  Tagging image for GCR..."
docker tag docker.n8n.io/n8nio/n8n:latest gcr.io/${PROJECT_ID}/n8n:latest

# Push to GCR
echo "📤 Pushing image to GCR..."
docker push gcr.io/${PROJECT_ID}/n8n:latest

echo "✅ n8n image successfully pushed to GCR!"
echo "📍 Image location: gcr.io/${PROJECT_ID}/n8n:latest"
echo ""
echo "🚀 You can now deploy using:"
echo "gcloud run deploy n8n \\"
echo "    --image=gcr.io/${PROJECT_ID}/n8n:latest \\"
echo "    --platform=managed \\"
echo "    --region=${REGION} \\"
echo "    --allow-unauthenticated \\"
echo "    --port=5678 \\"
echo "    --cpu=1 \\"
echo "    --memory=1Gi \\"
echo "    --min-instances=0 \\"
echo "    --max-instances=1 \\"
echo "    --set-env-vars=\"N8N_PATH=/,N8N_PORT=5678,N8N_HOST=0.0.0.0,N8N_PROTOCOL=https,EXECUTIONS_PROCESS=main,EXECUTIONS_MODE=regular,GENERIC_TIMEZONE=UTC\""
