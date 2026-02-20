// ─── Key Vault ───

param name string
param location string

@secure()
param gatewayToken string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: take(name, 24)
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
  }
}

resource gatewayTokenSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openclaw-gateway-token'
  properties: {
    value: gatewayToken
  }
}

output vaultUri string = keyVault.properties.vaultUri
output vaultName string = keyVault.name
