// ─── Azure Container Apps ───

param name string
param location string
param containerImage string
param containerCpu string
param containerMemory string
param logAnalyticsWorkspaceId string

@secure()
param logAnalyticsSharedKey string

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
        {
          name: 'openclaw-config-json'
          keyVaultUrl: '${keyVaultUri}secrets/openclaw-config'
          identity: 'system'
        }
        {
          name: 'openclaw-wa-auth'
          keyVaultUrl: '${keyVaultUri}secrets/openclaw-wa-auth'
          identity: 'system'
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
              name: 'OPENCLAW_CONFIG'
              secretRef: 'openclaw-config-json'
            }
            {
              name: 'OPENCLAW_WA_AUTH'
              secretRef: 'openclaw-wa-auth'
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
          command: [
            'sh'
          ]
          args: [
            '-c'
            'mkdir -p /home/node/.openclaw/credentials/whatsapp/default && printf \'%s\' "$OPENCLAW_CONFIG" > /home/node/.openclaw/openclaw.json && printf \'%s\' "$OPENCLAW_WA_AUTH" | base64 -d | tar xzf - -C /home/node/.openclaw/credentials/whatsapp/default && export AZURE_OPENAI_ENDPOINT="$AZURE_AI_ENDPOINT" && export AZURE_OPENAI_API_KEY=$(curl -sf "http://localhost:12356/msi/token?resource=https%3A%2F%2Fcognitiveservices.azure.com&api-version=2019-08-01" -H "X-IDENTITY-HEADER: $IDENTITY_HEADER" | node -e "let d=\'\';process.stdin.on(\'data\',c=>d+=c);process.stdin.on(\'end\',()=>console.log(JSON.parse(d).access_token))") && node openclaw.mjs models set azure-openai-responses/gpt-5-2-chat 2>/dev/null; node openclaw.mjs gateway --allow-unconfigured --bind lan --port 18789 & GW=$! && (sleep 8; while kill -0 $GW 2>/dev/null; do node openclaw.mjs devices approve --latest --url ws://localhost:18789 --token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true; sleep 30; done) & wait $GW'
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
          storageType: 'EmptyDir'
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
