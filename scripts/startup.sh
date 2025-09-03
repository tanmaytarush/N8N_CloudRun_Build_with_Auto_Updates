#!/bin/bash
set -e

# Check for update at startup
/usr/local/bin/update-script.sh

# Start n8n
exec n8n start
