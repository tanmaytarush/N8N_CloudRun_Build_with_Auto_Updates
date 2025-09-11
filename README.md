# n8n Docker Serverless - Cloud Run Deployment

A serverless deployment of n8n on Google Cloud Run, based on the [n8n Docker Compose setup](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/).

## Features

- 🚀 **Serverless**: Deploy n8n on Google Cloud Run
- 🐳 **Docker**: Containerized deployment following n8n best practices
- 🔒 **Secure**: Basic authentication and HTTPS enabled
- 📊 **Scalable**: Auto-scaling based on demand (0-3 instances)
- 💾 **Persistent**: SQLite database for data persistence
- 🌐 **HTTPS**: Automatic SSL/TLS termination by Cloud Run
- ⚡ **Production Ready**: Based on n8n Docker Compose configuration

## Quick Start

1. **Clone and setup**:
   ```bash
   git clone <your-repo>
   cd n8n-docker-serverless
   chmod +x deploy.sh setup-gcr-image.sh
   ```

2. **Configure**:
   Edit `config/environment.env` with your settings:
   ```bash
   PROJECT_ID=your-gcp-project
   REGION=us-central1
   SERVICE_NAME=n8n-serverless
   ```

3. **Setup GCR Image** (Required for Cloud Run):
   ```bash
   ./setup-gcr-image.sh  # Pull n8n image and push to GCR
   ```

4. **Deploy**:
   ```bash
   ./deploy.sh setup    # First time only
   ./deploy.sh deploy   # Deploy n8n
   ```

5. **Access**:
   - URL: `https://n8n-serverless-your-project.region.run.app`
   - Username: `admin`
   - Password: Check `config/environment.env`

## GCR Setup (Important!)

**Google Cloud Run doesn't support external registries** like `docker.n8n.io`. You must first pull the n8n image and push it to Google Container Registry (GCR).

### Option 1: Use the setup script (Recommended)
```bash
./setup-gcr-image.sh
```

### Option 2: Manual setup
```bash
# Pull n8n image
docker pull docker.n8n.io/n8nio/n8n:latest

# Tag for GCR
docker tag docker.n8n.io/n8nio/n8n:latest gcr.io/your-project/n8n:latest

# Configure Docker auth
gcloud auth configure-docker

# Push to GCR
docker push gcr.io/your-project/n8n:latest
```

## Configuration

### Environment Variables (Based on n8n Docker Compose)

| Variable | Description | Default | Source |
|----------|-------------|---------|---------|
| `N8N_HOST` | n8n host address | `0.0.0.0` | Docker Compose |
| `N8N_PORT` | n8n port | `5678` | Docker Compose |
| `N8N_PROTOCOL` | Protocol (https/http) | `https` | Docker Compose |
| `N8N_RUNNERS_ENABLED` | Enable n8n runners | `true` | Docker Compose |
| `NODE_ENV` | Node environment | `production` | Docker Compose |
| `DB_TYPE` | Database type | `sqlite` | Docker Compose |
| `DB_SQLITE_DATABASE` | SQLite database path | `/tmp/n8n.db` | Docker Compose |
| `DB_SQLITE_POOL_SIZE` | Connection pool size | `3` | Docker Compose |
| `N8N_BASIC_AUTH_ACTIVE` | Enable basic auth | `true` | Docker Compose |
| `N8N_BASIC_AUTH_USER` | Username | `admin` | Docker Compose |
| `N8N_BASIC_AUTH_PASSWORD` | Password | Generated | Docker Compose |
| `N8N_ENCRYPTION_KEY` | Data encryption key | Generated | Docker Compose |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | File permissions | `true` | Docker Compose |
| `GENERIC_TIMEZONE` | Timezone | `UTC` | Docker Compose |
| `TZ` | Timezone | `UTC` | Docker Compose |
| `WEBHOOK_URL` | Webhook base URL | Auto-generated | Cloud Run |
| `N8N_EDITOR_BASE_URL` | Editor base URL | Auto-generated | Cloud Run |

### GCP Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PROJECT_ID` | GCP Project ID | `betterprep-main-account` |
| `REGION` | GCP Region | `us-central1` |
| `SERVICE_NAME` | Cloud Run Service Name | `n8n-serverless` |

## Architecture

This deployment follows the n8n Docker Compose architecture but adapted for Cloud Run:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cloud Build   │───▶│   Container      │───▶│   Cloud Run     │
│                 │    │   Registry       │    │   (n8n)         │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                              │
         ▼                                              ▼
┌─────────────────┐                            ┌─────────────────┐
│   Source Code   │                            │   n8n Instance  │
│   + Dockerfile  │                            │   (HTTPS)       │
│   + startup.sh  │                            │   + SQLite DB   │
└─────────────────┘                            └─────────────────┘
```

### Key Differences from Docker Compose

1. **No Traefik**: Cloud Run handles SSL/TLS termination
2. **No Volume Mounts**: SQLite database stored in `/tmp` (ephemeral)
3. **No Reverse Proxy**: Direct access to n8n on port 5678
4. **Auto-scaling**: 0-3 instances based on demand

## Commands

```bash
./deploy.sh setup     # Set up GCP project and APIs
./deploy.sh deploy    # Deploy n8n to Cloud Run
./deploy.sh update    # Update n8n to latest version
./deploy.sh status    # Show service status
./deploy.sh logs      # Show service logs
./deploy.sh delete    # Delete the service
./deploy.sh help      # Show help
```

## Security

- **Basic Authentication**: Enabled by default (change password!)
- **HTTPS Only**: All traffic encrypted with Cloud Run's SSL
- **Data Encryption**: n8n data encrypted with custom key
- **File Permissions**: Enforced for security
- **Production Mode**: `NODE_ENV=production`

## Cost Optimization

- **Min instances**: 0 (cold start, pay per use)
- **Max instances**: 3 (auto-scale limit)
- **Memory**: 2GB per instance
- **CPU**: 1 vCPU per instance
- **Concurrency**: 80 requests per instance
- **Timeout**: 15 minutes per request

## Troubleshooting

### Common Issues

1. **Permission denied**: Make sure `deploy.sh` is executable
2. **Docker not found**: Install Docker Desktop
3. **GCP authentication**: Run `gcloud auth login`
4. **Service not accessible**: Check Cloud Run service status
5. **Database issues**: SQLite database is ephemeral (resets on restart)

### Logs

```bash
./deploy.sh logs
```

### Service Status

```bash
./deploy.sh status
```

## Data Persistence

⚠️ **Important**: This deployment uses SQLite in `/tmp` which is ephemeral. Data will be lost when the container restarts. For production use, consider:

1. Using Cloud SQL (PostgreSQL/MySQL)
2. Using Cloud Storage for file uploads
3. Implementing proper backup strategies

## Migration from Docker Compose

If migrating from Docker Compose:

1. Export your workflows from the Docker Compose instance
2. Deploy this Cloud Run version
3. Import your workflows
4. Update webhook URLs to the new Cloud Run URL

## Security Best Practices

1. **Change default passwords** immediately
2. **Use strong encryption keys** (32+ characters)
3. **Enable audit logging** in n8n settings
4. **Regular security updates** via redeployment
5. **Monitor access logs** in Cloud Run
6. **Use IAM** for fine-grained access control

## Prerequisites

- Google Cloud SDK installed
- Docker installed
- Authenticated with GCP: `gcloud auth login`

## Support

For issues and questions:
- Check the logs: `./deploy.sh logs`
- Review [n8n Docker Compose documentation](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/)
- Review GCP Cloud Run documentation
- n8n documentation: https://docs.n8n.io

That's it! 🚀
