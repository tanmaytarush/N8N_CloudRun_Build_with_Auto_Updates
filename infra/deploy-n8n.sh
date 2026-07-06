#!/usr/bin/env bash
# Canonical deploy script for n8n-serverless.
#
# Uses 'gcloud run services replace' so the cloudsql-instances annotation in
# infra/n8n-service.yaml is ALWAYS preserved. Never use
# 'gcloud run services update --set-env-vars' directly — that replaces only
# the env block and silently drops template-level annotations.
#
# First-time setup
# ────────────────
# 1. Run this script once to seed secrets and deploy.
# 2. To rotate a secret later:
#      echo -n "new-value" | gcloud secrets versions add <name> --data-file=-
# 3. Ensure the Cloud Run service account has roles/secretmanager.secretAccessor
#    (this script grants it automatically).
set -euo pipefail

PROJECT_ID="betterprep-main-account"
REGION="us-central1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML="$SCRIPT_DIR/n8n-service.yaml"

gcloud config set project "$PROJECT_ID" --quiet

# ── Secret Manager helpers ────────────────────────────────────────────────────

upsert_secret() {
  local name=$1
  local value=$2
  if gcloud secrets describe "$name" --project="$PROJECT_ID" &>/dev/null; then
    echo "  [secret] $name exists – skipping (rotate with: gcloud secrets versions add $name --data-file=-)"
  else
    echo "  [secret] creating $name"
    printf '%s' "$value" | gcloud secrets create "$name" \
      --data-file=- \
      --project="$PROJECT_ID" \
      --replication-policy=automatic
  fi
}

echo "==> Ensuring secrets exist in Secret Manager..."
# These initial values are used only on first creation.
# After creation, update values via 'gcloud secrets versions add', not here.
upsert_secret "n8n-db-password"         "N8N@betterprep"
upsert_secret "n8n-encryption-key"      "2d51aedbfbffe89d9ad53182bd966398"
upsert_secret "n8n-basic-auth-password" "Welcome@123"

# ── Grant Secret Accessor role to the Cloud Run service account ───────────────

echo "==> Resolving Cloud Run service account..."
# Try to read from an existing revision first; fall back to default compute SA.
SA_EMAIL="$(gcloud run services describe n8n-serverless \
  --region="$REGION" --project="$PROJECT_ID" \
  --format='value(spec.template.spec.serviceAccountName)' 2>/dev/null || true)"

if [ -z "$SA_EMAIL" ]; then
  PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
  SA_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
  echo "  (service not deployed yet; using default SA: $SA_EMAIL)"
fi

echo "  Service account: $SA_EMAIL"
for secret in n8n-db-password n8n-encryption-key n8n-basic-auth-password; do
  gcloud secrets add-iam-policy-binding "$secret" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/secretmanager.secretAccessor" \
    --project="$PROJECT_ID" \
    --quiet 2>/dev/null || true
done

# ── Deploy ────────────────────────────────────────────────────────────────────

echo "==> Deploying via gcloud run services replace..."
gcloud run services replace "$YAML" \
  --region="$REGION" \
  --project="$PROJECT_ID"

echo ""
echo "==> Done."
SERVICE_URL="$(gcloud run services describe n8n-serverless \
  --region="$REGION" --project="$PROJECT_ID" \
  --format='value(status.url)')"
echo "    Cloud Run URL : $SERVICE_URL"
echo "    Custom domain : https://automations.betterprep.ai"
