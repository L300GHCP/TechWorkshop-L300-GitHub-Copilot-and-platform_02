targetScope = 'resourceGroup'

@description('The environment name')
param environmentName string

@description('The primary location for all resources')
param location string

@description('The base name for all resources')
param baseName string

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var acrName = 'acr${baseName}${environmentName}${uniqueSuffix}'
var appServicePlanName = 'asp-${baseName}-${environmentName}'
var appServiceName = 'app-${baseName}-${environmentName}-${uniqueSuffix}'
var logAnalyticsName = 'log-${baseName}-${environmentName}'
var appInsightsName = 'appi-${baseName}-${environmentName}'
var aiFoundryName = 'aif-${baseName}-${environmentName}-${uniqueSuffix}'

// Deploy Log Analytics Workspace
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'log-analytics-deployment'
  params: {
    name: logAnalyticsName
    location: location
    environmentName: environmentName
  }
}

// Deploy Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'app-insights-deployment'
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.id
    environmentName: environmentName
  }
}

// Deploy Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    name: acrName
    location: location
    environmentName: environmentName
  }
}

// Deploy App Service Plan
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'app-service-plan-deployment'
  params: {
    name: appServicePlanName
    location: location
    environmentName: environmentName
  }
}

// Deploy App Service (Web App for Containers)
module appService 'modules/app-service.bicep' = {
  name: 'app-service-deployment'
  params: {
    name: appServiceName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    acrLoginServer: acr.outputs.loginServer
    applicationInsightsConnectionString: appInsights.outputs.connectionString
    environmentName: environmentName
  }
}

// Assign AcrPull role to App Service managed identity
module acrRoleAssignment 'modules/acr-role-assignment.bicep' = {
  name: 'acr-role-assignment-deployment'
  params: {
    acrName: acrName
    principalId: appService.outputs.managedIdentityPrincipalId
  }
}

// Deploy AI Foundry
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry-deployment'
  params: {
    name: aiFoundryName
    location: location
    environmentName: environmentName
  }
}

// Outputs
output acrLoginServer string = acr.outputs.loginServer
output acrName string = acr.outputs.name
output appServiceName string = appService.outputs.name
output appServiceHostName string = appService.outputs.hostName
output appServiceManagedIdentityPrincipalId string = appService.outputs.managedIdentityPrincipalId
output applicationInsightsName string = appInsights.outputs.name
output applicationInsightsConnectionString string = appInsights.outputs.connectionString
output aiFoundryEndpoint string = aiFoundry.outputs.endpoint
