@description('The name of the App Service Plan')
param name string

@description('The location for the App Service Plan')
param location string

@description('The environment name')
param environmentName string

@description('The SKU for the App Service Plan')
param sku object = {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  tags: {
    environment: environmentName
  }
  sku: sku
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux plans
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
