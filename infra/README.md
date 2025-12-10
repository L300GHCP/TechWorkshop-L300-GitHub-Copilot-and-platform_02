# ZavaStorefront Infrastructure

This directory contains the Infrastructure as Code (IaC) for deploying the ZavaStorefront application to Azure using Bicep templates and Azure Developer CLI (azd).

## Architecture Overview

The infrastructure provisions the following Azure resources in the `westus3` region:

### Core Resources
- **Resource Group**: `rg-zavastore-dev-westus3`
  - Central container for all Azure resources

- **Azure Container Registry (ACR)**: `acrzavastoredewvestus3`
  - SKU: Basic
  - Container image storage for the application
  - Admin user disabled (RBAC-based authentication only)
  - 7-day retention policy for images

- **App Service Plan**: `asp-zavastore-dev-westus3`
  - SKU: B1 (Linux)
  - Optimized for dev environments with minimal cost

- **App Service (Web App for Containers)**: `app-zavastore-dev-westus3`
  - Linux container hosting
  - System-assigned managed identity for ACR authentication
  - HTTPS-only with TLS 1.2+ minimum
  - Configured to pull images from ACR using managed identity (no passwords)

### Monitoring & AI Resources
- **Log Analytics Workspace**: `log-zavastore-dev-westus3`
  - Centralized logging and analytics
  - 30-day retention period

- **Application Insights**: `appi-zavastore-dev-westus3`
  - Application performance monitoring
  - Connected to Log Analytics workspace

- **AI Foundry Hub**: `aif-zavastore-dev-westus3`
  - Machine learning workspace for GPT-4 and Phi model access
  - Basic SKU for dev environments

### Security Configuration
- **System-assigned Managed Identity**: Automatically created for App Service
- **Role Assignment**: AcrPull role assigned to App Service identity on ACR
- **No admin credentials**: ACR admin user is disabled
- **HTTPS enforcement**: All traffic to App Service is HTTPS-only
- **TLS 1.2+**: Minimum TLS version enforced

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed (version 2.50.0 or later)
   ```bash
   az version
   ```

2. **Azure Developer CLI (azd)** installed
   ```bash
   azd version
   ```

3. **Azure subscription** with appropriate permissions:
   - Contributor role at subscription level
   - Ability to create role assignments

4. **Bicep CLI** (included with Azure CLI 2.20.0+)
   ```bash
   az bicep version
   ```

## Deployment Instructions

### Option 1: Using Azure Developer CLI (azd) - Recommended

The easiest way to deploy the entire solution:

1. **Initialize azd environment** (first time only):
   ```bash
   azd init
   ```

2. **Login to Azure**:
   ```bash
   azd auth login
   ```

3. **Provision infrastructure**:
   ```bash
   azd provision
   ```
   
   This will:
   - Create all Azure resources
   - Configure security settings
   - Set up managed identity and role assignments

4. **Deploy the application** (after infrastructure is provisioned):
   ```bash
   azd deploy
   ```

5. **Full provision and deploy in one command**:
   ```bash
   azd up
   ```

### Option 2: Using Azure CLI directly

If you prefer to use Azure CLI:

1. **Login to Azure**:
   ```bash
   az login
   ```

2. **Set your subscription**:
   ```bash
   az account set --subscription <subscription-id>
   ```

3. **Deploy the infrastructure**:
   ```bash
   az deployment sub create \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.dev.json
   ```

4. **Build and push container image to ACR**:
   ```bash
   # Get the ACR name from deployment outputs
   ACR_NAME=$(az deployment sub show \
     --name <deployment-name> \
     --query properties.outputs.acrName.value -o tsv)
   
   # Build and push using ACR build (no local Docker required)
   az acr build \
     --registry $ACR_NAME \
     --image zava-storefront:latest \
     --file src/Dockerfile \
     src/
   ```

5. **Verify deployment**:
   ```bash
   # Get the App Service URL
   APP_URL=$(az deployment sub show \
     --name <deployment-name> \
     --query properties.outputs.appServiceHostname.value -o tsv)
   
   echo "Application URL: https://${APP_URL}"
   ```

## GitHub Actions CI/CD

The repository includes a GitHub Actions workflow for automated builds and deployments.

### Setup

1. **Configure Azure credentials** in GitHub repository secrets:
   - `AZURE_CLIENT_ID`: Service principal client ID
   - `AZURE_TENANT_ID`: Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

2. **Create service principal with federated credentials**:
   ```bash
   az ad sp create-for-rbac \
     --name "github-zavastore-deploy" \
     --role contributor \
     --scopes /subscriptions/<subscription-id> \
     --sdk-auth
   ```

3. **Configure OIDC for GitHub Actions** (recommended over secrets):
   ```bash
   az ad app federated-credential create \
     --id <app-id> \
     --parameters '{
       "name": "github-federation",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:<org>/<repo>:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

### Workflow Triggers

The workflow automatically runs on:
- Push to `main` branch (when `src/` files change)
- Manual trigger via workflow_dispatch

The workflow uses `az acr build` to build containers in the cloud - no local Docker required.

## Resource Naming Conventions

All resources follow Azure naming best practices:

| Resource Type | Prefix | Example |
|--------------|--------|---------|
| Resource Group | `rg-` | `rg-zavastore-dev-westus3` |
| Container Registry | `acr` | `acrzavastoredewvestus3` |
| App Service Plan | `asp-` | `asp-zavastore-dev-westus3` |
| App Service | `app-` | `app-zavastore-dev-westus3` |
| Log Analytics | `log-` | `log-zavastore-dev-westus3` |
| Application Insights | `appi-` | `appi-zavastore-dev-westus3` |
| AI Foundry Hub | `aif-` | `aif-zavastore-dev-westus3` |

## Cost Estimation (Dev Environment)

Approximate monthly costs for the dev environment:

| Resource | SKU | Estimated Cost/Month |
|----------|-----|---------------------|
| App Service Plan | B1 | ~$13.00 |
| Container Registry | Basic | ~$5.00 |
| Log Analytics | Pay-as-you-go | ~$2-5 (based on usage) |
| Application Insights | Pay-as-you-go | ~$0-2 (first 5GB free) |
| AI Foundry Hub | Basic | ~$0 (minimal usage) |
| **Total** | | **~$20-25/month** |

> **Note**: Costs may vary based on actual usage, data ingestion, and retention settings.

## Modular Bicep Structure

The infrastructure uses a modular approach for maintainability:

```
infra/
├── main.bicep                    # Subscription-level orchestration
├── main.resources.bicep          # Resource group-level deployment
├── main.parameters.dev.json      # Dev environment parameters
└── modules/
    ├── acr.bicep                 # Azure Container Registry
    ├── acr-role-assignment.bicep # ACR RBAC configuration
    ├── app-service-plan.bicep    # App Service Plan
    ├── app-service.bicep         # App Service (Web App)
    ├── log-analytics.bicep       # Log Analytics Workspace
    ├── app-insights.bicep        # Application Insights
    └── ai-foundry.bicep          # AI Foundry Hub
```

## Troubleshooting

### Issue: ACR authentication fails

**Solution**: Ensure the App Service managed identity has the AcrPull role:
```bash
az role assignment list \
  --assignee <app-service-principal-id> \
  --scope <acr-resource-id>
```

### Issue: App Service not pulling latest image

**Solution**: Restart the App Service:
```bash
az webapp restart \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

### Issue: Deployment fails with quota errors

**Solution**: Check regional quotas for your subscription:
```bash
az vm list-usage --location westus3 -o table
```

### Issue: AI Foundry Hub deployment fails

**Solution**: Verify that westus3 supports AI Foundry and you have sufficient quota:
```bash
az provider show -n Microsoft.MachineLearningServices \
  --query "resourceTypes[?resourceType=='workspaces'].locations"
```

## Cleanup

To delete all resources:

### Using azd:
```bash
azd down
```

### Using Azure CLI:
```bash
az group delete \
  --name rg-zavastore-dev-westus3 \
  --yes --no-wait
```

## Additional Resources

- [Azure Container Registry documentation](https://docs.microsoft.com/azure/container-registry/)
- [App Service on Linux documentation](https://docs.microsoft.com/azure/app-service/overview)
- [Azure Developer CLI documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Application Insights documentation](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AI Foundry documentation](https://docs.microsoft.com/azure/machine-learning/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure service health status
3. Open an issue in the repository
