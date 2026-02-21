// ─── OpenClaw on Azure — Main Bicep Template ───
// One-click deployment of OpenClaw personal AI assistant on Azure Container Apps

targetScope = 'resourceGroup'

@description('Base name for all resources (lowercase, no spaces)')
@minLength(3)
@maxLength(20)
param baseName string = 'openclaw'

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('OpenClaw container image (from Docker Hub or ACR)')
param containerImage string = 'ghcr.io/openclaw/openclaw:latest'

@description('Container CPU cores')
param containerCpu string = '1.0'

@description('Container memory (e.g. 2Gi)')
param containerMemory string = '2Gi'

@description('OpenClaw gateway token (auto-generated if empty)')
@secure()
param gatewayToken string = newGuid()

// Unique suffix for globally unique resource names
var uniqueSuffix = uniqueString(resourceGroup().id, baseName)
var resourcePrefix = '${baseName}${uniqueSuffix}'

// ─── Monitoring ───
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    name: '${resourcePrefix}-logs'
    location: location
  }
}

// ─── Storage (Azure Files for persistent config) ───
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: 'st${replace(resourcePrefix, '-', '')}'
    location: location
    shareName: 'openclaw-config'
  }
}

// ─── Key Vault ───
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: 'kv-${resourcePrefix}'
    location: location
    gatewayToken: gatewayToken
  }
}

// ─── AI Foundry (Azure AI Services) ───
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'aiFoundry'
  params: {
    name: '${resourcePrefix}-ai'
    location: location
  }
}

// ─── Container Apps ───
module containerApps 'modules/container-apps.bicep' = {
  name: 'containerApps'
  params: {
    name: '${resourcePrefix}-app'
    location: location
    containerImage: containerImage
    containerCpu: containerCpu
    containerMemory: containerMemory
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    logAnalyticsSharedKey: monitoring.outputs.sharedKey
    keyVaultUri: keyVault.outputs.vaultUri
    aiEndpoint: aiFoundry.outputs.endpoint
    gatewayToken: gatewayToken
  }
}

// Grant Container App's managed identity access to Key Vault and AI Foundry
module keyVaultAccess 'modules/keyvault-access.bicep' = {
  name: 'keyVaultAccess'
  params: {
    keyVaultName: keyVault.outputs.vaultName
    principalId: containerApps.outputs.identityPrincipalId
  }
}

module aiAccess 'modules/ai-access.bicep' = {
  name: 'aiAccess'
  params: {
    aiAccountName: aiFoundry.outputs.accountName
    principalId: containerApps.outputs.identityPrincipalId
  }
}

// ─── Outputs ───
output gatewayUrl string = containerApps.outputs.fqdn
output keyVaultUri string = keyVault.outputs.vaultUri
output aiEndpoint string = aiFoundry.outputs.endpoint
output storageAccountName string = storage.outputs.storageAccountName
