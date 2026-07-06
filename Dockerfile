# Use n8n image with specific version tag for stability
# Using a recent stable version instead of latest to avoid pull issues
FROM n8nio/n8n:1.111.0

# Expose port 5678 (internal container port)
EXPOSE 5678

# Note: All environment variables are set at runtime via Cloud Run
# This minimal Dockerfile avoids layer registration issues
