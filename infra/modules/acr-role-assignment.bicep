@description('The principal ID to assign the role to')
param principalId string

@description('The resource ID of the Azure Container Registry')
param acrId string

@description('The principal type (ServicePrincipal, User, or Group)')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

// AcrPull role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, acrPullRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

@description('The ID of the role assignment')
output id string = acrRoleAssignment.id
