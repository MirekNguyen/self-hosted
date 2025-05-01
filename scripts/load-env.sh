#!/bin/bash

set -e

# Hardcoded Infisical secret keys
CLOUDFLARE_API_KEY_SECRET="cloudflare-api-key-secret"
INFISICAL_CLIENT_ID_SECRET="infisical-clientId-secret"
INFISICAL_CLIENT_SECRET_SECRET="infisical-clientSecret-secret"

echo "🔍 Checking for Infisical CLI..."
if ! command -v infisical &>/dev/null; then
  echo "❌ Infisical CLI is not installed."
  echo "➡️  Install it with: brew install infisical/get-cli/infisical"
  exit 1
fi
echo "✅ Infisical CLI is installed."

echo ""
echo "🔐 Checking Infisical login status..."
if ! infisical user get token &>/dev/null; then
  echo "❌ You are not logged into Infisical."
  echo "➡️  Run 'infisical login' and try again."
  exit 1
fi
echo "✅ Logged in to Infisical."
echo ""

echo "🌐 Retrieving secrets from Infisical..."
echo ""
echo "📋 Paste the following into your .env file:"
echo "--------------------------------------------------"

function print_env_entry() {
  local env_var="$1"
  local secret_key="$2"

  value=$(infisical secrets get --plain "$secret_key" 2>/dev/null || echo "[❌ Not Found]")
  echo "$env_var=$value"
}

print_env_entry "CLOUDFLARE_API_KEY" "$CLOUDFLARE_API_KEY_SECRET"
print_env_entry "INFISICAL_CLIENT_ID" "$INFISICAL_CLIENT_ID_SECRET"
print_env_entry "INFISICAL_CLIENT_SECRET" "$INFISICAL_CLIENT_SECRET_SECRET"

echo "--------------------------------------------------"
echo ""
echo "✅ Copy and paste the lines above into your .env file."
