# ZavaStorefront - Quick Start Guide

## Prerequisites Checklist

- [ ] Azure subscription
- [ ] Azure CLI installed
- [ ] Azure Developer CLI (azd) installed  
- [ ] .NET 6.0 SDK installed (optional, for local dev)

## Quick Deploy (5 minutes)

### Using Azure Developer CLI (Easiest)

```powershell
# 1. Login
azd auth login

# 2. Initialize (first time only)
azd init

# 3. Deploy everything
azd up
```

That's it! AZD will:
- Create all Azure resources
- Build your Docker image
- Deploy to Azure App Service
- Configure monitoring

### Using Azure CLI

```powershell
# 1. Login
az login
az account set --subscription "YOUR_SUBSCRIPTION_NAME"

# 2. Deploy infrastructure
az deployment sub create `
  --location westus3 `
  --template-file infra/main.bicep `
  --parameters infra/main.bicepparam `
  --name zavastore-deployment

# 3. Get deployment outputs
$outputs = az deployment sub show `
  --name zavastore-deployment `
  --query 'properties.outputs' -o json | ConvertFrom-Json

$acrName = $outputs.acrName.value
$appServiceName = $outputs.appServiceName.value
$resourceGroup = $outputs.resourceGroupName.value

# 4. Build and push container
az acr build `
  --registry $acrName `
  --image zavastore:latest `
  --file src/Dockerfile `
  ./src

# 5. Configure app service
az webapp config container set `
  --name $appServiceName `
  --resource-group $resourceGroup `
  --docker-custom-image-name "$($outputs.acrLoginServer.value)/zavastore:latest"

# 6. Open the app
az webapp browse --name $appServiceName --resource-group $resourceGroup
```

## What Gets Created

| Resource | Purpose | SKU/Tier |
|----------|---------|----------|
| Resource Group | Container for all resources | N/A |
| Container Registry | Docker image storage | Basic |
| App Service Plan | Compute for web app | B1 (Linux) |
| App Service | Hosts the application | Web App for Containers |
| Application Insights | Monitoring & telemetry | Pay-as-you-go |
| Log Analytics | Centralized logging | Pay-as-you-go |
| AI Foundry | AI/ML capabilities | S0 |

## Important URLs

After deployment, you'll get:

- **Application URL**: `https://app-zavastore-dev-{uniqueid}.azurewebsites.net`
- **ACR**: `acrzavastoredev{uniqueid}.azurecr.io`
- **Application Insights**: Available in Azure Portal

## Common Commands

### View application logs
```powershell
az webapp log tail --name $appServiceName --resource-group $resourceGroup
```

### Restart the app
```powershell
az webapp restart --name $appServiceName --resource-group $resourceGroup
```

### Update the container image
```powershell
# Build new image
az acr build --registry $acrName --image zavastore:v2 --file src/Dockerfile ./src

# Update app service
az webapp config container set `
  --name $appServiceName `
  --resource-group $resourceGroup `
  --docker-custom-image-name "$acrLoginServer/zavastore:v2"
```

### Check deployment status
```powershell
az webapp deployment list --name $appServiceName --resource-group $resourceGroup
```

## Environment Configuration

To change environments (dev, test, prod):

```powershell
# Set environment
azd env set AZURE_ENV_NAME prod
azd env set AZURE_LOCATION eastus

# Deploy
azd up
```

## Cost Estimates

**Development Environment** (~$20-30/month):
- App Service B1: $13.14/month
- ACR Basic: $5/month  
- Application Insights: ~$2-5/month
- Log Analytics: ~$1-3/month
- AI Foundry: Pay per use

## Troubleshooting

### App won't start
1. Check logs: `az webapp log tail --name $appServiceName --resource-group $resourceGroup`
2. Verify image exists: `az acr repository show-tags --name $acrName --repository zavastore`
3. Check Application Insights for errors

### Can't pull from ACR
1. Verify managed identity: `az webapp identity show --name $appServiceName --resource-group $resourceGroup`
2. Check role assignment: `az role assignment list --assignee {principalId} --scope {acrResourceId}`

### Deployment fails
1. Check deployment errors: `az deployment sub show --name zavastore-deployment`
2. Verify quotas: `az vm list-usage --location westus3`
3. Check service availability: https://status.azure.com

## Cleanup

**Delete everything:**
```powershell
# Using azd
azd down --purge

# Or using Azure CLI
az group delete --name $resourceGroup --yes --no-wait
```

## Next Steps

1. ✅ Deploy infrastructure
2. ✅ Verify application works
3. ⬜ Set up CI/CD pipeline (see `.github/workflows/azure-deploy.yml`)
4. ⬜ Configure custom domain
5. ⬜ Add staging slot for blue-green deployments
6. ⬜ Integrate AI Foundry capabilities
7. ⬜ Set up production environment

## Getting Help

- Review [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) for detailed documentation
- Check [Azure App Service docs](https://learn.microsoft.com/azure/app-service/)
- Open an issue in this repository

## Key Files

- `azure.yaml` - AZD configuration
- `infra/main.bicep` - Infrastructure definition
- `src/Dockerfile` - Container configuration
- `.github/workflows/azure-deploy.yml` - CI/CD pipeline
- `INFRASTRUCTURE.md` - Detailed documentation
