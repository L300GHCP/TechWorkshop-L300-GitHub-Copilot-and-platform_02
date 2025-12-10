@description('The name of the Log Analytics Workspace')
param name string

@description('The location for the Log Analytics Workspace')
param location string = resourceGroup().location

@description('The SKU of the Log Analytics Workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param sku string = 'PerGB2018'

@description('The retention period in days')
param retentionInDays int = 30

@description('Tags to apply to the resource')
param tags object = {}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Log Analytics Workspace')
output id string = logAnalytics.id

@description('The customer ID of the Log Analytics Workspace')
output customerId string = logAnalytics.properties.customerId

@description('The name of the Log Analytics Workspace')
output name string = logAnalytics.name
