// ─── Azure Container Apps ───

param name string
param location string
param containerImage string
param containerCpu string
param containerMemory string
param logAnalyticsWorkspaceId string

@secure()
param logAnalyticsSharedKey string

param storageAccountName string

@secure()
param storageAccountKey string

param fileShareName string
param keyVaultUri string
param aiEndpoint string

@secure()
param gatewayToken string

// Container Apps Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${name}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2023-09-01').customerId
        sharedKey: logAnalyticsSharedKey
      }
    }
  }
}

// Azure Files storage link
resource envStorage 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: containerAppEnv
  name: 'openclawconfig'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: fileShareName
      accessMode: 'ReadWrite'
    }
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 18789
        transport: 'http'
        allowInsecure: false
      }
      secrets: [
        {
          name: 'gateway-token'
          value: gatewayToken
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'openclaw'
          image: containerImage
          resources: {
            cpu: json(containerCpu)
            memory: containerMemory
          }
          env: [
            {
              name: 'OPENCLAW_GATEWAY_TOKEN'
              secretRef: 'gateway-token'
            }
            {
              name: 'OPENCLAW_GATEWAY_BIND'
              value: '0.0.0.0'
            }
            {
              name: 'OPENCLAW_GATEWAY_PORT'
              value: '18789'
            }
            {
              name: 'AZURE_KEYVAULT_URI'
              value: keyVaultUri
            }
            {
              name: 'AZURE_AI_ENDPOINT'
              value: aiEndpoint
            }
            {
              name: 'NODE_ENV'
              value: 'production'
            }
          ]
          volumeMounts: [
            {
              volumeName: 'openclaw-config'
              mountPath: '/home/node/.openclaw'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'openclaw-config'
          storageName: 'openclawconfig'
          storageType: 'AzureFile'
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}

output fqdn string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output identityPrincipalId string = containerApp.identity.principalId
