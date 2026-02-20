#!/usr/bin/env bash
# quickstart.sh — Deploy OpenClaw on Azure in one command (Azure Cloud Shell compatible)
set -euo pipefail

echo "🦞 OpenClaw on Azure — Quick Deploy"
echo "===================================="

# Check if azd is available (preferred)
if command -v azd &> /dev/null; then
  echo "Found Azure Developer CLI. Using azd..."
  echo ""

  if [ ! -d ".git" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/skowalik/openclaw-on-azure.git
    cd openclaw-on-azure
  fi

  azd auth login
  azd up
  exit 0
fi

# Fallback to Azure CLI
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI not found."
  echo "Install: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
  echo "Or use Azure Cloud Shell: https://shell.azure.com"
  exit 1
fi

RESOURCE_GROUP="${OPENCLAW_RG:-openclaw-rg}"
LOCATION="${OPENCLAW_LOCATION:-eastus}"

echo "📍 Resource Group: $RESOURCE_GROUP"
echo "📍 Location:       $LOCATION"
echo ""

# Clone if needed
if [ ! -f "infra/main.bicep" ]; then
  echo "📥 Cloning repository..."
  git clone https://github.com/skowalik/openclaw-on-azure.git
  cd openclaw-on-azure
fi

# Deploy
echo "📦 Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

echo "🚀 Deploying (this takes ~5 minutes)..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --query "properties.outputs" \
  --output table

echo ""
echo "✅ Done! Check the Azure Portal for your gateway URL."
echo "📖 Next steps: https://github.com/skowalik/openclaw-on-azure#-post-deployment-setup"
