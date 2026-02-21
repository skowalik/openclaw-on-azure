# deploy.ps1 — Deploy OpenClaw to Azure Container Apps (Windows)
param(
    [string]$ResourceGroup = "openclaw-rg",
    [string]$Location = "eastus",
    [string]$BaseName = "openclaw"
)

Write-Host "🦞 OpenClaw on Azure — Deployment" -ForegroundColor Cyan
Write-Host "================================="
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Location:       $Location"
Write-Host "Base Name:      $BaseName"
Write-Host ""

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found. Install: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}

# Check login
Write-Host "🔑 Checking Azure login..." -ForegroundColor Yellow
try {
    az account show --query "name" -o tsv 2>$null | Out-Null
} catch {
    Write-Host "Not logged in. Running 'az login'..."
    az login
}

# Get deployer's object ID for Key Vault access
$deployerOid = az ad signed-in-user show --query id -o tsv 2>$null

# Create resource group
Write-Host "📦 Creating resource group '$ResourceGroup' in '$Location'..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output none

# Deploy
Write-Host "🚀 Deploying infrastructure (this takes ~5 minutes)..." -ForegroundColor Green
$result = az deployment group create `
    --resource-group $ResourceGroup `
    --template-file infra/main.bicep `
    --parameters baseName=$BaseName deployerPrincipalId=$deployerOid `
    --query "properties.outputs" `
    --output json | ConvertFrom-Json

$gatewayUrl = $result.gatewayUrl.value
$keyVaultUri = $result.keyVaultUri.value

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "================================="
Write-Host "🌐 Gateway URL:  $gatewayUrl"
Write-Host "🔐 Key Vault:    $keyVaultUri"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open $gatewayUrl in your browser"
Write-Host "  2. Get your gateway token from Key Vault:"
Write-Host "     az keyvault secret show --vault-name <vault> --name openclaw-gateway-token --query value -o tsv"
Write-Host "  3. Paste the token in the Control UI"
Write-Host "  4. Configure your messaging channels"
Write-Host ""
Write-Host "📖 Full guide: https://github.com/skowalik/openclaw-on-azure#post-deployment-setup"
