@description('The name of the Application Insights')
param name string

@description('The location for the Application Insights')
param location string = resourceGroup().location

@description('The resource ID of the Log Analytics Workspace')
param workspaceId string

@description('Tags to apply to the resource')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Application Insights')
output id string = appInsights.id

@description('The instrumentation key of the Application Insights')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string of the Application Insights')
output connectionString string = appInsights.properties.ConnectionString

@description('The name of the Application Insights')
output name string = appInsights.name
