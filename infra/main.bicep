targetScope = 'subscription'

@description('The environment name (dev, test, prod)')
param environmentName string = 'dev'

@description('The primary location for all resources')
param location string = 'westus3'

@description('The resource group name')
param resourceGroupName string = 'rg-zavastore-${environmentName}-${location}'

@description('The base name for all resources')
param baseName string = 'zavastore'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: environmentName
    project: 'ZavaStorefront'
    managedBy: 'bicep'
  }
}

// Deploy main resources
module resources 'main.resources.bicep' = {
  scope: rg
  name: 'resources-deployment'
  params: {
    environmentName: environmentName
    location: location
    baseName: baseName
  }
}

// Outputs
output resourceGroupName string = rg.name
output acrLoginServer string = resources.outputs.acrLoginServer
output acrName string = resources.outputs.acrName
output appServiceName string = resources.outputs.appServiceName
output appServiceHostName string = resources.outputs.appServiceHostName
output applicationInsightsName string = resources.outputs.applicationInsightsName
output applicationInsightsConnectionString string = resources.outputs.applicationInsightsConnectionString
output aiFoundryEndpoint string = resources.outputs.aiFoundryEndpoint
