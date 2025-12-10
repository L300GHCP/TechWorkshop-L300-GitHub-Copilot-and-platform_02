# ZavaStorefront Azure Infrastructure

This repository contains the Azure infrastructure as code (IaC) for deploying the ZavaStorefront ASP.NET Core web application to Azure using Bicep and Azure Developer CLI (azd).

## Architecture Overview

The infrastructure deploys the following Azure resources in the `westus3` region:

- **Azure Container Registry (ACR)**: Stores Docker container images for the application
- **Azure App Service Plan**: Linux-based hosting plan for containers
- **Azure App Service**: Web App for Containers hosting the ZavaStorefront application
- **Application Insights**: Application monitoring and telemetry
- **Log Analytics Workspace**: Centralized logging for all resources
- **Microsoft Foundry (Azure AI Services)**: AI capabilities including GPT-4 and Phi models
- **Managed Identity & RBAC**: Secure, password-less authentication between App Service and ACR

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed ([Install Guide](https://learn.microsoft.com/cli/azure/install-azure-cli))
2. **Azure Developer CLI (azd)** installed ([Install Guide](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd))
3. **Azure subscription** with appropriate permissions
4. **.NET 6.0 SDK** (for local development)

## Project Structure

```
.
├── azure.yaml                 # AZD configuration file
├── infra/                     # Infrastructure as Code
│   ├── main.bicep            # Main entry point (subscription scope)
│   ├── main.resources.bicep  # Resource deployments (resource group scope)
│   ├── main.bicepparam       # Parameters file
│   └── modules/              # Bicep modules
│       ├── acr.bicep
│       ├── acr-role-assignment.bicep
│       ├── app-insights.bicep
│       ├── app-service.bicep
│       ├── app-service-plan.bicep
│       ├── ai-foundry.bicep
│       └── log-analytics.bicep
└── src/                       # Application source code
    ├── Dockerfile
    ├── .dockerignore
    └── ... (ASP.NET Core application files)
```

## Deployment Instructions

### Option 1: Deploy with Azure Developer CLI (Recommended)

1. **Initialize the environment**:
   ```bash
   azd init
   ```

2. **Login to Azure**:
   ```bash
   azd auth login
   ```

3. **Set environment variables** (optional):
   ```bash
   azd env set AZURE_ENV_NAME dev
   azd env set AZURE_LOCATION westus3
   ```

4. **Provision infrastructure**:
   ```bash
   azd provision
   ```

5. **Build and deploy the application**:
   ```bash
   azd deploy
   ```

   Or do both in one step:
   ```bash
   azd up
   ```

### Option 2: Deploy with Azure CLI

1. **Login to Azure**:
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

2. **Deploy infrastructure**:
   ```bash
   az deployment sub create \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

3. **Get the ACR and App Service names** from the deployment outputs:
   ```bash
   az deployment sub show \
     --name <deployment-name> \
     --query properties.outputs
   ```

4. **Build and push the Docker image to ACR**:
   ```bash
   # Get ACR login server
   ACR_NAME=<acr-name-from-output>
   
   # Build and push using ACR Tasks (no local Docker required)
   az acr build \
     --registry $ACR_NAME \
     --image zavastore:latest \
     --file src/Dockerfile \
     ./src
   ```

5. **Update App Service to use the new image**:
   ```bash
   APP_NAME=<app-service-name-from-output>
   ACR_LOGIN_SERVER=<acr-login-server-from-output>
   
   az webapp config container set \
     --name $APP_NAME \
     --resource-group <resource-group-name> \
     --docker-custom-image-name $ACR_LOGIN_SERVER/zavastore:latest
   ```

## Key Features

### Security Best Practices

- **No Admin Credentials**: ACR admin user is disabled; access is via RBAC
- **Managed Identity**: App Service uses system-assigned managed identity
- **AcrPull Role**: Managed identity has minimal required permissions
- **HTTPS Only**: App Service enforces HTTPS traffic
- **TLS 1.2+**: Modern TLS version required

### Development Settings

Current configuration is optimized for development:
- **App Service Plan**: Basic (B1) tier
- **ACR**: Basic tier
- **Always On**: Disabled (reduces costs for dev)
- **Public Network Access**: Enabled for all resources

### Monitoring & Observability

- **Application Insights**: Connected to Log Analytics workspace
- **Real-time monitoring**: Application performance and availability
- **Distributed tracing**: End-to-end transaction monitoring
- **Custom telemetry**: Available through Application Insights SDK

## Environment Variables

The App Service is configured with:

| Variable | Description |
|----------|-------------|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection string |
| `ApplicationInsightsAgent_EXTENSION_VERSION` | App Insights agent version |
| `DOCKER_REGISTRY_SERVER_URL` | ACR login server URL |
| `ASPNETCORE_ENVIRONMENT` | ASP.NET Core environment (Development) |
| `WEBSITES_ENABLE_APP_SERVICE_STORAGE` | Disabled for containers |

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and push to ACR
        run: |
          az acr build \
            --registry ${{ secrets.ACR_NAME }} \
            --image zavastore:${{ github.sha }} \
            --file src/Dockerfile \
            ./src
      
      - name: Deploy to App Service
        run: |
          az webapp config container set \
            --name ${{ secrets.APP_SERVICE_NAME }} \
            --resource-group ${{ secrets.RESOURCE_GROUP }} \
            --docker-custom-image-name ${{ secrets.ACR_LOGIN_SERVER }}/zavastore:${{ github.sha }}
```

## Cost Optimization

Current monthly cost estimates for dev environment (westus3):

- App Service Plan (B1): ~$13/month
- Azure Container Registry (Basic): ~$5/month
- Application Insights: Pay-as-you-go (minimal for dev)
- Log Analytics Workspace: Pay-as-you-go (minimal for dev)
- AI Foundry (S0): Usage-based pricing

**Total estimated**: ~$20-30/month for development

## Troubleshooting

### Container Pull Failures

If the App Service cannot pull images from ACR:
1. Verify the managed identity has AcrPull role
2. Check ACR network settings allow App Service access
3. Verify the image exists in ACR: `az acr repository show-tags --name <acr-name> --repository zavastore`

### Application Not Starting

1. Check App Service logs:
   ```bash
   az webapp log tail --name <app-name> --resource-group <rg-name>
   ```
2. Verify the Docker image runs locally
3. Check Application Insights for exceptions

### RBAC Role Assignment Issues

If role assignment fails, wait a few minutes for Azure AD propagation, then re-run:
```bash
az deployment group create \
  --resource-group <rg-name> \
  --template-file infra/modules/acr-role-assignment.bicep \
  --parameters acrName=<acr-name> principalId=<managed-identity-principal-id>
```

## Cleanup

To delete all resources:

```bash
# Using azd
azd down

# Or using Azure CLI
az group delete --name <resource-group-name> --yes
```

## Next Steps

1. **Production Deployment**: 
   - Upgrade to Standard/Premium tiers
   - Add custom domain and SSL certificate
   - Enable private endpoints for ACR
   - Configure auto-scaling
   - Set up staging slots

2. **Security Enhancements**:
   - Implement Azure Key Vault for secrets
   - Add Azure Front Door or Application Gateway
   - Enable Azure AD authentication
   - Configure network isolation with VNet integration

3. **CI/CD Pipeline**:
   - Set up GitHub Actions or Azure DevOps
   - Implement blue-green or canary deployments
   - Add automated testing stages

4. **AI Integration**:
   - Connect application to Microsoft Foundry
   - Implement GPT-4 features
   - Add model observability

## References

- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Microsoft Foundry Documentation](https://learn.microsoft.com/azure/ai-services/)

## Support

For issues or questions:
- Create an issue in this repository
- Review the [troubleshooting guide](#troubleshooting)
- Check Azure service health status
