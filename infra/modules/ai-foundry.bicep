@description('The name of the AI Foundry resource')
param name string

@description('The location for AI Foundry')
param location string

@description('The environment name')
param environmentName string

@description('The SKU for AI Foundry')
param sku string = 'S0'

// AI Foundry (Azure AI Services) resource
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: {
    environment: environmentName
  }
  kind: 'AIServices'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    disableLocalAuth: false
  }
}

output id string = aiFoundry.id
output name string = aiFoundry.name
output endpoint string = aiFoundry.properties.endpoint
