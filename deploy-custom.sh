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

# Deploy via the canonical script that uses 'gcloud run services replace'.
# This preserves the cloudsql-instances annotation. Do not use gcloud run deploy here.
echo "Delegating to infra/deploy-n8n.sh..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/infra/deploy-n8n.sh"
