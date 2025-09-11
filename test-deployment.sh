#!/bin/bash

# Test script to verify n8n deployment
SERVICE_URL="https://n8n-serverless-1069021792204.us-central1.run.app"

echo "🧪 Testing n8n deployment..."

# Test 1: Check if service is responding
echo "1️⃣ Testing basic connectivity..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${SERVICE_URL})
echo "HTTP Status: ${HTTP_STATUS}"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Service is responding with HTTP 200"
elif [ "$HTTP_STATUS" = "401" ]; then
    echo "✅ Service is responding with HTTP 401 (authentication required - this is expected)"
else
    echo "❌ Service is not responding correctly. Status: ${HTTP_STATUS}"
fi

# Test 2: Check if we can reach the health endpoint
echo ""
echo "2️⃣ Testing health endpoint..."
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${SERVICE_URL}/healthz 2>/dev/null || echo "000")
echo "Health endpoint status: ${HEALTH_STATUS}"

# Test 3: Check if we can reach the editor
echo ""
echo "3️⃣ Testing editor endpoint..."
EDITOR_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${SERVICE_URL}/ 2>/dev/null || echo "000")
echo "Editor endpoint status: ${EDITOR_STATUS}"

# Test 4: Check logs for proper binding
echo ""
echo "4️⃣ Checking recent logs for proper port binding..."
gcloud run services logs read n8n-serverless --region=us-central1 --limit=20 | grep -E "(Starting n8n|ready on|Editor is now accessible|0\.0\.0\.0|5678)" || echo "No binding logs found"

echo ""
echo "🎯 Expected results:"
echo "   - HTTP 200 or 401 for main endpoint"
echo "   - Logs should show 'Starting n8n on 0.0.0.0:5678'"
echo "   - Logs should show 'Editor is now accessible'"
echo "   - No 404 errors in logs"
