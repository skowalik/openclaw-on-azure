// ─── Azure AI Services (Foundry) ───

param name string
param location string

resource aiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
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
    disableLocalAuth: false
  }
}

// Deploy Claude Sonnet model via serverless (Model as a Service)
resource sonnetDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiAccount
  name: 'claude-sonnet'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'claude-sonnet-4-20250514'
      version: '1'
    }
  }
}

output endpoint string = aiAccount.properties.endpoint
output accountName string = aiAccount.name
output accountId string = aiAccount.id
