#!/bin/bash

set -e

# Resolve absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VOLUMES_DIR="$PROJECT_ROOT/volumes"

echo "📁 Applying Kubernetes volume manifests from: $VOLUMES_DIR"
echo ""

if [ ! -d "$VOLUMES_DIR" ]; then
  echo "❌ Volume directory not found: $VOLUMES_DIR"
  exit 1
fi

shopt -s nullglob
VOLUME_FILES=("$VOLUMES_DIR"/*.yml)

if [ ${#VOLUME_FILES[@]} -eq 0 ]; then
  echo "⚠️  No .yml files found in $VOLUMES_DIR"
  exit 0
fi

for file in "${VOLUME_FILES[@]}"; do
  echo "🔧 Applying: $(basename "$file")"
  kubectl apply -f "$file"
  echo ""
done

echo "✅ All volume manifests applied successfully."
