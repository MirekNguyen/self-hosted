#!/bin/bash

set -e

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APPS_DIR="$PROJECT_ROOT/apps"
APP_OF_APPS_FILE="$PROJECT_ROOT/app-of-apps.yaml"

echo "🚀 Deploying ArgoCD App of Apps and individual apps"
echo ""

# Apply app-of-apps.yaml
if [ -f "$APP_OF_APPS_FILE" ]; then
  echo "📄 Applying: $(basename "$APP_OF_APPS_FILE")"
  kubectl apply -f "$APP_OF_APPS_FILE"
  echo ""
else
  echo "⚠️  File not found: $APP_OF_APPS_FILE"
fi

# Apply all .yml files in ./apps
if [ ! -d "$APPS_DIR" ]; then
  echo "❌ Apps directory not found: $APPS_DIR"
  exit 1
fi

shopt -s nullglob
APP_FILES=("$APPS_DIR"/*.yml)

if [ ${#APP_FILES[@]} -eq 0 ]; then
  echo "⚠️  No .yml files found in $APPS_DIR"
else
  for file in "${APP_FILES[@]}"; do
    echo "🔧 Applying: $(basename "$file")"
    kubectl apply -f "$file"
    echo ""
  done
fi

echo "✅ All app manifests applied successfully."
