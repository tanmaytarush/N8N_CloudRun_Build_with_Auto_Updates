# N8N V1 Serverless Deployment

This directory contains the V1 implementation of N8N serverless deployment on Google Cloud Platform using Cloud Run and Artifact Registry.

## Quick Start

### Prerequisites

1. **Google Cloud SDK**: Install and configure gcloud CLI
   ```bash
   # Install gcloud (if not already installed)
   curl https://sdk.cloud.google.com | bash
   
   # Authenticate
   gcloud auth login
   
   # Set your project
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Enable Required APIs**:
   ```bash
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   ```

### Deployment

1. **Navigate to V1 directory**:
   ```bash
   cd V1
   ```

2. **Run the deployment script**:
   ```bash
   ./deploy.sh
   ```

   Or with custom options:
   ```bash
   ./deploy.sh --region us-west1 --service my-n8n
   ```

## Files Overview

- `Dockerfile` - Container configuration for N8N
- `startup.sh` - Entrypoint script that handles Cloud Run port mapping
- `cloudbuild.yaml` - Cloud Build configuration with variable substitution
- `deploy.sh` - Automated deployment script with error handling
- `environment.env` - Environment variables template
- `README.md` - This documentation

## Deployment Methods

### Method 1: Automated Script (Recommended)

The `deploy.sh` script implements all the recommended solutions:

```bash
./deploy.sh
```

**Features:**
- ✅ Environment variable validation
- ✅ Artifact Registry repository creation
- ✅ Multiple deployment fallback methods
- ✅ Error handling and colored output
- ✅ Service URL retrieval

### Method 2: Manual Cloud Build

If you prefer manual control:

```bash
# Set variables explicitly
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1

# Create Artifact Registry repository (if needed)
gcloud artifacts repositories create n8n-repo \
    --repository-format=docker \
    --location=$REGION

# Deploy using cloudbuild.yaml
gcloud builds submit \
    --config=cloudbuild.yaml \
    --substitutions=_REGION=$REGION,_PROJECT_ID=$PROJECT_ID,_SERVICE_NAME=n8n-v1 \
    .
```

### Method 3: Direct Tag Approach

For simple deployments:

```bash
# Set variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1

# Build and push
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/n8n-repo/n8n-v1:latest" .

# Deploy to Cloud Run
gcloud run deploy n8n-v1 \
    --image "$REGION-docker.pkg.dev/$PROJECT_ID/n8n-repo/n8n-v1:latest" \
    --region $REGION \
    --platform managed \
    --allow-unauthenticated \
    --port 5678
```

## Troubleshooting

### Common Issues

#### 1. Environment Variables Not Expanding

**Error**: `unrecognized arguments: $REGION-docker.pkg.dev/$PROJECT_ID/n8n-repo/n8n:latest`

**Solution**: Use double quotes and ensure variables are set:
```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/n8n-repo/n8n-v1:latest" .
```

#### 2. Artifact Registry Repository Not Found

**Error**: `Repository 'n8n-repo' not found`

**Solution**: Create the repository:
```bash
gcloud artifacts repositories create n8n-repo \
    --repository-format=docker \
    --location=$REGION
```

#### 3. Permission Denied

**Error**: `Permission denied` or `Access denied`

**Solution**: Ensure proper authentication and permissions:
```bash
gcloud auth login
gcloud auth configure-docker $REGION-docker.pkg.dev
```

#### 4. Build Timeout

**Error**: Build process times out

**Solution**: Increase timeout in `cloudbuild.yaml`:
```yaml
options:
  timeout: '1200s'  # 20 minutes
```

### Debug Steps

1. **Verify current project**:
   ```bash
   gcloud config get-value project
   ```

2. **Check Artifact Registry repositories**:
   ```bash
   gcloud artifacts repositories list --location=$REGION
   ```

3. **Test with simple build**:
   ```bash
   gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/n8n-repo/test:latest \
       https://github.com/GoogleCloudPlatform/cloud-build-samples.git#main/quickstart-build
   ```

4. **Check Cloud Run services**:
   ```bash
   gcloud run services list --region=$REGION
   ```

## Configuration

### Environment Variables

Edit `environment.env` to customize your N8N configuration:

```bash
# Load environment variables
source environment.env

# Or set them manually
export N8N_BASIC_AUTH_USER=your-username
export N8N_BASIC_AUTH_PASSWORD=your-password
export N8N_EDITOR_BASE_URL=https://your-service-url.run.app
```

### Service Configuration

The service is configured with:
- **Memory**: 2Gi
- **CPU**: 1
- **Min Instances**: 0 (true serverless)
- **Max Instances**: 3
- **Concurrency**: 80
- **Timeout**: 1800s (30 minutes)
- **Port**: 5678

## Security

- Basic authentication is enabled by default
- Update credentials in `environment.env`
- The service allows unauthenticated access (configure as needed)
- Encryption key is set for data security

## Monitoring

After deployment, monitor your service:

1. **Cloud Run Console**: View logs and metrics
2. **Cloud Build Console**: Check build history
3. **Artifact Registry**: Manage container images

## Support

For issues specific to this deployment:

1. Check the troubleshooting section above
2. Review Cloud Build logs in the GCP Console
3. Verify all prerequisites are met
4. Ensure proper IAM permissions

## Version History

- **V1**: Initial serverless implementation with Cloud Run and Artifact Registry
