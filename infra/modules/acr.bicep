@description('The name of the Azure Container Registry')
param name string

@description('The location for the Azure Container Registry')
param location string = resourceGroup().location

@description('The SKU of the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
    }
  }
}

@description('The login server for the ACR')
output loginServer string = acr.properties.loginServer

@description('The resource ID of the ACR')
output id string = acr.id

@description('The name of the ACR')
output name string = acr.name
