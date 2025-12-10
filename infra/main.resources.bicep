targetScope = 'resourceGroup'

@description('The location for all resources')
param location string

@description('The name of the Azure Container Registry')
param acrName string

@description('The name of the App Service Plan')
param appServicePlanName string

@description('The name of the App Service')
param appServiceName string

@description('The name of the Log Analytics Workspace')
param logAnalyticsName string

@description('The name of the Application Insights')
param appInsightsName string

@description('The name of the AI Foundry Hub')
param aiFoundryName string

@description('The container image tag to deploy')
param containerImageTag string

@description('Tags to apply to all resources')
param tags object

// Deploy Log Analytics Workspace
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'log-analytics-deployment'
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
  }
}

// Deploy Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'app-insights-deployment'
  params: {
    name: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// Deploy Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    name: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// Deploy App Service Plan
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'app-service-plan-deployment'
  params: {
    name: appServicePlanName
    location: location
    sku: 'B1'
    tags: tags
  }
}

// Deploy App Service
module appService 'modules/app-service.bicep' = {
  name: 'app-service-deployment'
  params: {
    name: appServiceName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    acrLoginServer: acr.outputs.loginServer
    containerImageName: 'zava-storefront'
    containerImageTag: containerImageTag
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Assign AcrPull role to App Service managed identity
module acrRoleAssignment 'modules/acr-role-assignment.bicep' = {
  name: 'acr-role-assignment-deployment'
  params: {
    principalId: appService.outputs.principalId
    acrName: acr.outputs.name
  }
}

// Deploy AI Foundry Hub
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry-deployment'
  params: {
    name: aiFoundryName
    location: location
    tags: tags
  }
}

// Outputs
@description('The name of the ACR')
output acrName string = acr.outputs.name

@description('The login server of the ACR')
output acrLoginServer string = acr.outputs.loginServer

@description('The name of the App Service')
output appServiceName string = appService.outputs.name

@description('The default hostname of the App Service')
output appServiceHostname string = appService.outputs.defaultHostname

@description('The name of the Application Insights')
output appInsightsName string = appInsights.outputs.name

@description('The name of the AI Foundry Hub')
output aiFoundryName string = aiFoundry.outputs.name
