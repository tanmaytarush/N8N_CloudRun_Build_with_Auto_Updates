# n8n Docker Serverless on Google Cloud Run

Simple deployment of n8n to Google Cloud Run with automatic updates.

## Quick Start

1. **Setup GCP project:**
   ```bash
   ./deploy.sh setup
   ```

2. **Deploy n8n:**
   ```bash
   ./deploy.sh deploy
   ```

3. **Update n8n:**
   ```bash
   ./deploy.sh update
   ```

## Commands

- `./deploy.sh setup` - Set up GCP project and APIs
- `./deploy.sh deploy` - Deploy n8n to Cloud Run
- `./deploy.sh update` - Update n8n to latest version
- `./deploy.sh status` - Show service status
- `./deploy.sh logs` - Show service logs
- `./deploy.sh delete` - Delete the service
- `./deploy.sh help` - Show help

## Configuration

Edit `config/environment.env` to customize:
- Project ID (default: betterprep)
- Region (default: us-central1)
- Username/Password
- Encryption key

## Prerequisites

- Google Cloud SDK installed
- Docker installed
- Authenticated with GCP: `gcloud auth login`

That's it! 🚀
