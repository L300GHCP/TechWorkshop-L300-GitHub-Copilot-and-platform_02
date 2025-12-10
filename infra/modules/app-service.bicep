@description('The name of the App Service')
param name string

@description('The location for the App Service')
param location string = resourceGroup().location

@description('The resource ID of the App Service Plan')
param appServicePlanId string

@description('The login server of the Azure Container Registry')
param acrLoginServer string

@description('The name of the container image')
param containerImageName string = 'zava-storefront'

@description('The tag of the container image')
param containerImageTag string = 'latest'

@description('The Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Tags to apply to the resource')
param tags object = {}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${containerImageName}:${containerImageTag}'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

@description('The principal ID of the system-assigned managed identity')
output principalId string = appService.identity.principalId

@description('The resource ID of the App Service')
output id string = appService.id

@description('The name of the App Service')
output name string = appService.name

@description('The default hostname of the App Service')
output defaultHostname string = appService.properties.defaultHostName
