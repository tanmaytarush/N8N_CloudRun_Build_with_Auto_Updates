#!/bin/bash

# N8N V1 Deployment Script
# This script implements the recommended solutions for Cloud Build deployment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate environment variables
validate_environment() {
    print_status "Validating environment variables..."
    
    # Get current project ID
    if ! PROJECT_ID=$(gcloud config get-value project 2>/dev/null); then
        print_error "Failed to get current project ID. Please run 'gcloud auth login' and 'gcloud config set project YOUR_PROJECT_ID'"
        exit 1
    fi
    
    # Set default region if not provided
    REGION=${REGION:-us-central1}
    SERVICE_NAME=${SERVICE_NAME:-n8n-v1}
    
    print_success "Environment variables validated:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Service Name: $SERVICE_NAME"
}

# Function to check if Artifact Registry repository exists
check_artifact_registry() {
    print_status "Checking Artifact Registry repository..."
    
    if ! gcloud artifacts repositories describe n8n-repo --location=$REGION >/dev/null 2>&1; then
        print_warning "Artifact Registry repository 'n8n-repo' does not exist in region $REGION"
        print_status "Creating Artifact Registry repository..."
        
        if gcloud artifacts repositories create n8n-repo \
            --repository-format=docker \
            --location=$REGION \
            --description="N8N Docker repository"; then
            print_success "Artifact Registry repository created successfully"
        else
            print_error "Failed to create Artifact Registry repository"
            exit 1
        fi
    else
        print_success "Artifact Registry repository exists"
    fi
}

# Function to verify current directory
verify_directory() {
    print_status "Verifying deployment directory..."
    
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found in current directory"
        print_error "Please run this script from the V1 directory"
        exit 1
    fi
    
    if [ ! -f "startup.sh" ]; then
        print_error "startup.sh not found in current directory"
        exit 1
    fi
    
    print_success "All required files found"
}

# Function to run Cloud Build with proper variable handling
run_cloud_build() {
    print_status "Starting Cloud Build deployment..."
    
    # Method 1: Using cloudbuild.yaml with substitutions (Recommended)
    print_status "Using Cloud Build config with variable substitutions..."
    
    if gcloud builds submit \
        --config=cloudbuild.yaml \
        --substitutions=_REGION=$REGION,_PROJECT_ID=$PROJECT_ID,_SERVICE_NAME=$SERVICE_NAME \
        .; then
        print_success "Cloud Build completed successfully"
    else
        print_error "Cloud Build failed"
        print_status "Trying alternative method with direct tag..."
        
        # Method 2: Direct tag approach (Fallback)
        TAG="$REGION-docker.pkg.dev/$PROJECT_ID/n8n-repo/n8n-v1:latest"
        print_status "Using direct tag: $TAG"
        
        if gcloud builds submit --tag "$TAG" .; then
            print_success "Cloud Build with direct tag completed successfully"
            
            # Deploy to Cloud Run
            print_status "Deploying to Cloud Run..."
            if gcloud run deploy $SERVICE_NAME \
                --image "$TAG" \
                --region $REGION \
                --platform managed \
                --allow-unauthenticated \
                --port 5678 \
                --memory 2Gi \
                --cpu 1 \
                --min-instances 0 \
                --max-instances 3 \
                --concurrency 80 \
                --timeout 1800 \
                --ingress all; then
                print_success "Cloud Run deployment completed successfully"
            else
                print_error "Cloud Run deployment failed"
                exit 1
            fi
        else
            print_error "All deployment methods failed"
            exit 1
        fi
    fi
}

# Function to check if service is publicly accessible
check_public_access() {
    print_status "Checking if service is publicly accessible..."
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)" 2>/dev/null)
    
    if [ -z "$SERVICE_URL" ]; then
        print_error "Could not get service URL"
        return 1
    fi
    
    # Test public access
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        print_success "Service is accessible at: $SERVICE_URL"
        return 0
    else
        print_warning "Service may not be publicly accessible (HTTP $HTTP_CODE)"
        return 1
    fi
}

# Function to display service URL and access instructions
display_service_url() {
    print_status "Getting service URL..."
    
    if SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)" 2>/dev/null); then
        print_success "Deployment completed successfully!"
        echo ""
        echo "Service URL: $SERVICE_URL"
        echo ""
        
        # Check if public access is available
        if check_public_access; then
            print_success "Service is publicly accessible!"
            echo "🌐 Access directly at: $SERVICE_URL"
            echo "👤 Username: tanmay@betterprep.ai"
            echo "🔑 Password: M#x46\$\$LZ&fUtc2u"
            echo ""
            echo "✅ You can now access N8N directly in your browser!"
        else
            print_warning "Service may require authentication or have access restrictions"
            echo ""
            echo "🔐 Alternative Access Methods:"
            echo "1. Use gcloud proxy: ./access-n8n.sh --proxy"
            echo "2. Use access script: ./access-n8n.sh"
            echo "3. Manual proxy: gcloud run services proxy $SERVICE_NAME --region=$REGION --port=8080"
            echo ""
            echo "📋 Credentials:"
            echo "   Username: tanmay@betterprep.ai"
            echo "   Password: M#x46\$\$LZ&fUtc2u"
        fi
    else
        print_warning "Could not retrieve service URL. Please check the Cloud Run console."
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "N8N V1 Deployment Script"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Validate environment
    validate_environment
    
    # Check Artifact Registry
    check_artifact_registry
    
    # Verify directory
    verify_directory
    
    # Run deployment
    run_cloud_build
    
    # Display results
    display_service_url
    
    echo ""
    print_success "Deployment process completed!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --region       Set the region (default: us-central1)"
        echo "  --service      Set the service name (default: n8n-v1)"
        echo ""
        echo "Environment Variables:"
        echo "  REGION         GCP region for deployment"
        echo "  SERVICE_NAME   Cloud Run service name"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Use defaults"
        echo "  $0 --region us-west1                 # Deploy to us-west1"
        echo "  $0 --service my-n8n --region us-west1 # Custom service name and region"
        echo "  REGION=us-west1 $0                   # Set region via environment variable"
        exit 0
        ;;
    --region)
        REGION="$2"
        shift 2
        ;;
    --service)
        SERVICE_NAME="$2"
        shift 2
        ;;
esac

# Run main function
main
