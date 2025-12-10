targetScope = 'subscription'

@description('The environment name (e.g., dev, staging, prod)')
@minLength(1)
@maxLength(10)
param environmentName string = 'dev'

@description('The primary location for all resources')
param location string = 'westus3'

@description('The name of the application')
param appName string = 'zavastore'

@description('The container image tag to deploy')
param containerImageTag string = 'latest'

@description('Tags to apply to all resources')
param tags object = {
  environment: environmentName
  application: appName
  'managed-by': 'bicep'
}

// Generate resource names following Azure naming conventions
var resourceGroupName = 'rg-${appName}-${environmentName}-${location}'
var acrName = replace('acr${appName}${environmentName}${location}', '-', '')
var appServicePlanName = 'asp-${appName}-${environmentName}-${location}'
var appServiceName = 'app-${appName}-${environmentName}-${location}'
var logAnalyticsName = 'log-${appName}-${environmentName}-${location}'
var appInsightsName = 'appi-${appName}-${environmentName}-${location}'
var aiFoundryName = 'aif-${appName}-${environmentName}-${location}'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy all resources using modules
module resources 'main.resources.bicep' = {
  name: 'resources-deployment'
  scope: rg
  params: {
    location: location
    acrName: acrName
    appServicePlanName: appServicePlanName
    appServiceName: appServiceName
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    aiFoundryName: aiFoundryName
    containerImageTag: containerImageTag
    tags: tags
  }
}

// Outputs
@description('The name of the resource group')
output resourceGroupName string = rg.name

@description('The name of the ACR')
output acrName string = resources.outputs.acrName

@description('The login server of the ACR')
output acrLoginServer string = resources.outputs.acrLoginServer

@description('The name of the App Service')
output appServiceName string = resources.outputs.appServiceName

@description('The default hostname of the App Service')
output appServiceHostname string = resources.outputs.appServiceHostname

@description('The name of the Application Insights')
output appInsightsName string = resources.outputs.appInsightsName

@description('The name of the AI Foundry Hub')
output aiFoundryName string = resources.outputs.aiFoundryName
