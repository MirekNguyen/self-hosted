#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$BASE_DIR/.env"
SECRETS_DIR="$BASE_DIR/secrets"

echo "📄 Loading environment variables from: $ENV_FILE"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env file not found. Please create it first."
  exit 1
fi

# Load .env variables
set -a
source "$ENV_FILE"
set +a

# Validate required variables
function check_var() {
  local name="$1"
  local value="${!name}"
  if [ -z "$value" ]; then
    echo "❌ Missing required environment variable: $name"
    exit 1
  fi
}

check_var "CLOUDFLARE_API_KEY"
check_var "INFISICAL_CLIENT_ID"
check_var "INFISICAL_CLIENT_SECRET"

echo "✅ All required environment variables are set."
echo ""

echo "🔄 Syncing dynamic Kubernetes secrets..."

kubectl create secret generic cloudflare-api-key-secret \
  --namespace cert-manager \
  --from-literal=api-key="$CLOUDFLARE_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic universal-auth-credentials \
  --namespace external-secrets \
  --from-literal=clientId="$INFISICAL_CLIENT_ID" \
  --from-literal=clientSecret="$INFISICAL_CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "📁 Applying static Kubernetes secrets from: $SECRETS_DIR"
echo ""

echo "🔧 Applying: certificate.yml"
kubectl apply -f "$SECRETS_DIR/certificate.yml"
echo ""

echo "⏳ Waiting for External Secrets CRDs to be available..."
TIMEOUT=120
INTERVAL=5
ELAPSED=0
while ! kubectl get crd clustersecretstores.external-secrets.io &>/dev/null; do
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "❌ Timed out waiting for External Secrets CRDs after ${TIMEOUT}s."
    exit 1
  fi
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done
echo "✅ External Secrets CRDs are available."
echo ""

echo "🔧 Applying: infisical-store.yml"
kubectl apply -f "$SECRETS_DIR/infisical-store.yml"
echo ""

echo "✅ All Kubernetes secrets created and applied successfully."
