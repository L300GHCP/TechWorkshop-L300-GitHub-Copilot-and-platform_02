@description('The name of the Azure Container Registry')
@minLength(5)
@maxLength(50)
param name string

@description('The location for the ACR')
param location string

@description('The environment name')
param environmentName string

@description('The ACR SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  tags: {
    environment: environmentName
  }
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Use RBAC instead of admin credentials
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
      retentionPolicy: {
        status: 'disabled'
        days: 7
      }
    }
  }
}

output id string = acr.id
output name string = acr.name
output loginServer string = acr.properties.loginServer
