// ─── Microsoft Foundry (Azure AI Services + GPT-5.2) ───

param name string
param location string = 'eastus2'

resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-12-01' = {
  name: name
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource gpt52Deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-12-01' = {
  parent: aiAccount
  name: 'gpt-5-2-chat'
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5.2-chat'
      version: '2026-02-10'
    }
  }
}

output endpoint string = aiAccount.properties.endpoint
output accountName string = aiAccount.name
output accountId string = aiAccount.id
