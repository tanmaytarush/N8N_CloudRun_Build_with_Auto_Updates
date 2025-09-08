#!/bin/bash

# N8N Access Script - Works around organization policy restrictions
# This script provides multiple ways to access your N8N service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
SERVICE_NAME="n8n-v1"
REGION="us-central1"
PROJECT_ID=$(gcloud config get-value project)
SERVICE_URL="https://n8n-v1-cn7loxmeea-uc.a.run.app"
LOCAL_PORT=8080

# N8N Credentials
N8N_USER="tanmay@betterprep.ai"
N8N_PASSWORD="M#x46\$\$LZ&fUtc2u"

echo "=========================================="
echo "N8N Access Solutions"
echo "=========================================="
echo ""

# Method 1: gcloud proxy (Recommended)
start_proxy() {
    print_status "Starting gcloud proxy (Method 1 - Recommended)"
    
    # Kill any existing proxy
    pkill -f "gcloud run services proxy" 2>/dev/null || true
    
    # Start proxy
    gcloud run services proxy $SERVICE_NAME --region=$REGION --port=$LOCAL_PORT &
    PROXY_PID=$!
    
    # Wait for proxy to start
    sleep 5
    
    # Test the proxy
    if curl -s -u "$N8N_USER:$N8N_PASSWORD" http://localhost:$LOCAL_PORT/ >/dev/null 2>&1; then
        print_success "Proxy started successfully!"
        echo ""
        echo "🌐 Access N8N at: http://localhost:$LOCAL_PORT"
        echo "👤 Username: $N8N_USER"
        echo "🔑 Password: $N8N_PASSWORD"
        echo ""
        echo "Press Ctrl+C to stop the proxy"
        
        # Keep proxy running
        wait $PROXY_PID
    else
        print_error "Failed to start proxy"
        kill $PROXY_PID 2>/dev/null || true
        return 1
    fi
}

# Method 2: Direct access with authentication
direct_access() {
    print_status "Testing direct access with authentication (Method 2)"
    
    # Get access token
    ACCESS_TOKEN=$(gcloud auth print-access-token)
    
    # Test with authentication
    RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "$SERVICE_URL/")
    
    if echo "$RESPONSE" | grep -q "n8n is starting up\|Cannot GET /"; then
        print_success "Service is accessible with authentication!"
        echo ""
        echo "🌐 Service URL: $SERVICE_URL"
        echo "🔑 Use gcloud authentication to access"
        echo ""
        echo "To access in browser, run:"
        echo "gcloud auth login"
        echo "gcloud run services proxy $SERVICE_NAME --region=$REGION --port=$LOCAL_PORT"
    else
        print_warning "Direct access may be restricted by organization policy"
        echo "Response: $RESPONSE"
    fi
}

# Method 3: Open in browser with proxy
open_browser() {
    print_status "Opening N8N in browser (Method 3)"
    
    # Start proxy in background
    gcloud run services proxy $SERVICE_NAME --region=$REGION --port=$LOCAL_PORT &
    PROXY_PID=$!
    
    # Wait for proxy
    sleep 5
    
    # Open browser
    if command -v open >/dev/null 2>&1; then
        open "http://localhost:$LOCAL_PORT"
        print_success "Browser opened! Use credentials: $N8N_USER / $N8N_PASSWORD"
    else
        print_warning "Could not open browser automatically"
        echo "Please open: http://localhost:$LOCAL_PORT"
    fi
    
    # Keep proxy running
    wait $PROXY_PID
}

# Method 4: Test service health
test_health() {
    print_status "Testing service health (Method 4)"
    
    # Check service status
    SERVICE_STATUS=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.conditions[0].status)" 2>/dev/null || echo "Unknown")
    
    if [ "$SERVICE_STATUS" = "True" ]; then
        print_success "Service is healthy and running"
    else
        print_warning "Service status: $SERVICE_STATUS"
    fi
    
    # Check recent logs
    print_status "Recent service logs:"
    gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit=5 --format="value(textPayload)" --freshness=5m | head -3
}

# Method 5: Deploy with different configuration
redeploy_with_auth() {
    print_status "Redeploying with authentication configuration (Method 5)"
    
    # Update service to require authentication
    gcloud run services update $SERVICE_NAME \
        --region=$REGION \
        --set-env-vars="N8N_BASIC_AUTH_ACTIVE=true,N8N_BASIC_AUTH_USER=$N8N_USER,N8N_BASIC_AUTH_PASSWORD=$N8N_PASSWORD" \
        --no-allow-unauthenticated
    
    print_success "Service updated to require authentication"
    echo "Now use Method 1 (proxy) to access the service"
}

# Main menu
show_menu() {
    echo "Choose an access method:"
    echo ""
    echo "1) Start gcloud proxy (Recommended)"
    echo "2) Test direct access with authentication"
    echo "3) Open in browser with proxy"
    echo "4) Test service health"
    echo "5) Redeploy with authentication"
    echo "6) Show all methods"
    echo "0) Exit"
    echo ""
    read -p "Enter your choice (0-6): " choice
    
    case $choice in
        1) start_proxy ;;
        2) direct_access ;;
        3) open_browser ;;
        4) test_health ;;
        5) redeploy_with_auth ;;
        6) show_all_methods ;;
        0) exit 0 ;;
        *) print_error "Invalid choice. Please try again." && show_menu ;;
    esac
}

# Show all methods
show_all_methods() {
    echo ""
    echo "=========================================="
    echo "All Access Methods"
    echo "=========================================="
    echo ""
    echo "Method 1: gcloud proxy (Recommended)"
    echo "  gcloud run services proxy $SERVICE_NAME --region=$REGION --port=$LOCAL_PORT"
    echo "  Then access: http://localhost:$LOCAL_PORT"
    echo ""
    echo "Method 2: Direct with authentication"
    echo "  curl -H \"Authorization: Bearer \$(gcloud auth print-access-token)\" $SERVICE_URL"
    echo ""
    echo "Method 3: Browser with proxy"
    echo "  Run this script and choose option 3"
    echo ""
    echo "Method 4: Check service health"
    echo "  gcloud run services describe $SERVICE_NAME --region=$REGION"
    echo ""
    echo "Method 5: Redeploy with auth"
    echo "  gcloud run services update $SERVICE_NAME --no-allow-unauthenticated"
    echo ""
    echo "Credentials:"
    echo "  Username: $N8N_USER"
    echo "  Password: $N8N_PASSWORD"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    --proxy|-p)
        start_proxy
        ;;
    --direct|-d)
        direct_access
        ;;
    --browser|-b)
        open_browser
        ;;
    --health|-h)
        test_health
        ;;
    --redeploy|-r)
        redeploy_with_auth
        ;;
    --help)
        show_all_methods
        ;;
    *)
        show_menu
        ;;
esac
