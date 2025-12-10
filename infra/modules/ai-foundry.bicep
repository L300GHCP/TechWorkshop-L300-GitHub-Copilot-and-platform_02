@description('The name of the AI Foundry Hub')
param name string

@description('The location for the AI Foundry Hub')
param location string = resourceGroup().location

@description('The friendly name for the AI Foundry Hub')
param friendlyName string = ''

@description('The description of the AI Foundry Hub')
param hubDescription string = 'AI Foundry Hub for ZavaStorefront application'

@description('Tags to apply to the resource')
param tags object = {}

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: empty(friendlyName) ? name : friendlyName
    description: hubDescription
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

@description('The resource ID of the AI Foundry Hub')
output id string = aiHub.id

@description('The name of the AI Foundry Hub')
output name string = aiHub.name

@description('The principal ID of the system-assigned managed identity')
output principalId string = aiHub.identity.principalId
