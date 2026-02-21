#!/usr/bin/env bash
# deploy.sh — Deploy OpenClaw to Azure Container Apps
set -euo pipefail

RESOURCE_GROUP="${1:-openclaw-rg}"
LOCATION="${2:-eastus}"
BASE_NAME="${3:-openclaw}"

echo "🦞 OpenClaw on Azure — Deployment"
echo "================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location:       $LOCATION"
echo "Base Name:      $BASE_NAME"
echo ""

# Check Azure CLI
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI not found. Install: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

# Check login
echo "🔑 Checking Azure login..."
az account show --query "name" -o tsv 2>/dev/null || {
  echo "Not logged in. Running 'az login'..."
  az login
}

# Get deployer's object ID for Key Vault access
DEPLOYER_OID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")

# Create resource group
echo "📦 Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# Deploy
echo "🚀 Deploying infrastructure (this takes ~5 minutes)..."
RESULT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters baseName="$BASE_NAME" deployerPrincipalId="$DEPLOYER_OID" \
  --query "properties.outputs" \
  --output json)

GATEWAY_URL=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['gatewayUrl']['value'])" 2>/dev/null || echo "See Azure Portal")
KEYVAULT_URI=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['keyVaultUri']['value'])" 2>/dev/null || echo "See Azure Portal")

echo ""
echo "✅ Deployment complete!"
echo "================================="
echo "🌐 Gateway URL:  $GATEWAY_URL"
echo "🔐 Key Vault:    $KEYVAULT_URI"
echo ""
echo "Next steps:"
echo "  1. Open $GATEWAY_URL in your browser"
echo "  2. Get your gateway token from Key Vault:"
echo "     az keyvault secret show --vault-name <vault> --name openclaw-gateway-token --query value -o tsv"
echo "  3. Paste the token in the Control UI"
echo "  4. Configure your messaging channels"
echo ""
echo "📖 Full guide: https://github.com/skowalik/openclaw-on-azure#post-deployment-setup"
