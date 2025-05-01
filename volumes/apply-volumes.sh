#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Applying all volume YAML files in: $SCRIPT_DIR"

# Loop over *.volume.yml files in current directory
for file in "$SCRIPT_DIR"/*.volume.yml; do
  if [[ -f "$file" ]]; then
    echo ""
    echo "🔧 Applying $file..."
    kubectl apply -f "$file"
  fi
done

echo ""
echo "✅ All volume definitions applied successfully."
