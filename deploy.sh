#!/bin/bash

# n8n Docker Serverless Deployment Script
# Single script to handle everything

# Load environment variables
if [ -f "config/environment.env" ]; then
    source config/environment.env
    echo "✅ Loaded configuration from config/environment.env"
else
    echo "❌ Error: config/environment.env not found!"
    echo "Creating default configuration..."
    
    # Create default environment file
    mkdir -p config
    cat > config/environment.env << 'EOF'
# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD="M#x46\$LZ&fUtc2u"
DB_TYPE=sqlite
N8N_ENCRYPTION_KEY=2d51aedbfbffe89d9ad53182bd966398
PROJECT_ID=betterprep
N8N_HOME=/home/node

# GCP Configuration
REGION=us-central1
SERVICE_NAME=n8n-serverless
EOF
    
    source config/environment.env
    echo "✅ Created default configuration. Edit config/environment.env if needed."
fi

# Override HOME for local execution
export HOME=$HOME

# Function to show help
show_help() {
    echo "🚀 n8n Docker Serverless Deployment"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Set up GCP project and APIs"
    echo "  deploy    - Deploy n8n to Cloud Run"
    echo "  update    - Update n8n to latest version"
    echo "  status    - Show service status"
    echo "  logs      - Show service logs"
    echo "  delete    - Delete the service"
    echo "  help      - Show this help"
    echo ""
    echo "Configuration:"
    echo "  Project: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Service: $SERVICE_NAME"
    echo ""
}

# Function to setup GCP
setup_gcp() {
    echo "🏗️  Setting up GCP project: $PROJECT_ID"
    
    # Set project
    gcloud config set project $PROJECT_ID
    
    # Enable APIs
    echo "🔌 Enabling required APIs..."
    gcloud services enable run.googleapis.com
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable storage.googleapis.com
    gcloud services enable containerregistry.googleapis.com
    
    # Create storage bucket
    echo "📦 Creating storage bucket..."
    gsutil mb gs://$PROJECT_ID-n8n-data || echo "Bucket already exists"
    
    # Authenticate Docker
    echo "🐳 Configuring Docker authentication..."
    gcloud auth configure-docker
    
    echo "✅ GCP setup complete!"
}

# Function to deploy
deploy() {
    echo "🚀 Deploying n8n to Cloud Run (Docker Compose style)..."
    
    # Set project
    gcloud config set project $PROJECT_ID
    
    # Ensure Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # First, ensure n8n image is available in GCR
    echo "📦 Ensuring n8n image is available in GCR..."
    if ! gcloud container images describe gcr.io/$PROJECT_ID/n8n:latest >/dev/null 2>&1; then
        echo "🔄 n8n image not found in GCR. Setting up..."
        ./setup-gcr-image.sh
    else
        echo "✅ n8n image already available in GCR"
    fi
    
    # Use Cloud Build for deployment
    echo "🏗️  Deploying with Cloud Build..."
    gcloud builds submit \
      --config cloud-build.yaml \
      --substitutions=_PROJECT_ID=$PROJECT_ID,_REGION=$REGION,_SERVICE_NAME=$SERVICE_NAME \
      --project $PROJECT_ID
    
    if [ $? -eq 0 ]; then
        # Get service URL
        SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')
        
        echo ""
        echo "✅ Deployment complete!"
        echo "🌐 n8n URL: $SERVICE_URL"
        echo "👤 Username: $N8N_BASIC_AUTH_USER"
        echo "🔑 Password: [hidden]"
        echo "🔐 Encryption Key: $N8N_ENCRYPTION_KEY"
        echo ""
        echo "📋 Next steps:"
        echo "1. Access your n8n instance using the URL above"
        echo "2. Change the default password in n8n settings"
        echo "3. Configure your workflows and integrations"
        echo "4. Set up webhooks using the service URL"
    else
        echo "❌ Deployment failed! Check the build logs."
        exit 1
    fi
}

# Function to update
update() {
    echo "🔄 Updating n8n to latest version..."
    deploy
}

# Function to show status
show_status() {
    echo "📊 Service Status:"
    echo ""
    
    # Set proper environment and project
    export HOME=$HOME
    gcloud config set project $PROJECT_ID
    
    if gcloud run services describe $SERVICE_NAME --region $REGION >/dev/null 2>&1; then
        SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')
        STATUS=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.conditions[0].status)')
        
        echo "✅ Service: $SERVICE_NAME"
        echo "🌐 URL: $SERVICE_URL"
        echo "📊 Status: $STATUS"
        echo "📍 Region: $REGION"
    else
        echo "❌ Service not found. Run: $0 deploy"
    fi
}

# Function to show logs
show_logs() {
    echo "📋 Recent logs:"
    gcloud run services logs read $SERVICE_NAME --region $REGION --limit=50
}

# Function to delete service
delete_service() {
    echo "🗑️  Deleting service: $SERVICE_NAME"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        gcloud run services delete $SERVICE_NAME --region $REGION --quiet
        echo "✅ Service deleted"
    else
        echo "❌ Deletion cancelled"
    fi
}

# Main script logic
case "${1:-help}" in
    setup)
        setup_gcp
        ;;
    deploy)
        deploy
        ;;
    update)
        update
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    delete)
        delete_service
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac