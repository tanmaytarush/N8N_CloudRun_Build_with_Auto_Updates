FROM docker.n8n.io/n8nio/n8n:latest

# Set environment variables for proper Cloud Run operation
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=https
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=admin
ENV N8N_BASIC_AUTH_PASSWORD="M#x46\$LZ&fUtc2u"
ENV DB_TYPE=sqlite
ENV DB_SQLITE_POOL_SIZE=1
ENV N8N_ENCRYPTION_KEY=2d51aedbfbffe89d9ad53182bd966398
ENV N8N_RUNNERS_ENABLED=true
ENV N8N_BLOCK_ENV_ACCESS_IN_NODE=false
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false
ENV GENERIC_TIMEZONE=UTC
ENV TZ=UTC
ENV HOME=/home/node
ENV N8N_DISABLE_UI=false
ENV N8N_LISTEN_ADDRESS=0.0.0.0

EXPOSE 5678

# Ensure the .n8n directory exists and has proper permissions
USER root
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n
USER node
