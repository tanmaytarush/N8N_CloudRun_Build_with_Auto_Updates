#!/bin/sh

# Force n8n to use Cloud Run's PORT environment variable
export N8N_PORT=${PORT:-5678}
export N8N_HOST="0.0.0.0"
export N8N_LISTEN_ADDRESS="0.0.0.0"

# Ensure proper binding
echo "Starting n8n on ${N8N_HOST}:${N8N_PORT}"

# Start n8n with explicit web server configuration
exec n8n web \
  --host="0.0.0.0" \
  --port="${N8N_PORT}"
