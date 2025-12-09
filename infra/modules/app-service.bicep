@description('The name of the App Service')
param name string

@description('The location for the App Service')
param location string

@description('The App Service Plan resource ID')
param appServicePlanId string

@description('The ACR login server')
param acrLoginServer string

@description('Application Insights connection string')
@secure()
param applicationInsightsConnectionString string

@description('The environment name')
param environmentName string

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: {
    environment: environmentName
    'azd-service-name': 'web'
  }
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest' // Placeholder image
      acrUseManagedIdentityCreds: true
      alwaysOn: false // Set to false for Basic tier
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
      ]
    }
  }
}

output id string = appService.id
output name string = appService.name
output hostName string = appService.properties.defaultHostName
output managedIdentityPrincipalId string = appService.identity.principalId
