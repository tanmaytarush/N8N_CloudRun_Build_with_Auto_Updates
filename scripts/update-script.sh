#!/bin/bash
CURRENT_VERSION=$(n8n --version)
LATEST_VERSION=$(curl -s https://api.github.com/repos/n8n-io/n8n/releases/latest | jq -r '.tag_name')

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "Update available: $CURRENT_VERSION -> $LATEST_VERSION"
    echo "$(date): Update from $CURRENT_VERSION to $LATEST_VERSION" >> /home/node/.n8n/update.log
    exit 0
else
    echo "n8n is up to date: $CURRENT_VERSION"
fi
