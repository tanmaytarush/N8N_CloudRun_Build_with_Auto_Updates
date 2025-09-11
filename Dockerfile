# Use n8n image from Docker Hub (better architecture support)
FROM n8nio/n8n:latest

# Set working directory
WORKDIR /home/node

# Switch to node user
USER node

# Expose port 5678
EXPOSE 5678

# Set environment variables for Cloud Run
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=https
ENV N8N_LISTEN_ADDRESS=0.0.0.0
ENV N8N_WEBHOOK_URL=https://n8n-serverless-1069021792204.us-central1.run.app
ENV N8N_EDITOR_BASE_URL=https://n8n-serverless-1069021792204.us-central1.run.app
ENV N8N_DISABLE_UI=false
ENV N8N_SKIP_OWNER_SETUP=false

# Create a startup script to ensure n8n starts properly
RUN echo '#!/bin/sh' > /home/node/startup.sh && \
    echo 'echo "Starting n8n..."' >> /home/node/startup.sh && \
    echo 'n8n start' >> /home/node/startup.sh && \
    chmod +x /home/node/startup.sh

# Use the startup script
ENTRYPOINT ["/home/node/startup.sh"]
