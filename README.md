# ZavaStorefront - Azure Cloud Migration Workshop

This lab guides you through a series of practical exercises focused on modernising Zava's business applications and databases by migrating everything to Azure, leveraging GitHub Enterprise, Copilot, and Azure services. Each exercise is designed to deliver hands-on experience in governance, automation, security, AI integration, and observability, ensuring Zava's transition to Azure is robust, secure, and future-ready.

## Project Overview

ZavaStorefront is a modern e-commerce web application built with .NET 8 ASP.NET MVC, designed to run as a containerized application on Azure App Service with integrated monitoring and AI capabilities.

### Key Features

- **Containerized Deployment**: Docker-based deployment to Azure App Service
- **Infrastructure as Code**: Complete Bicep templates for Azure resources
- **Secure by Default**: Managed identities, RBAC, HTTPS-only, TLS 1.2+
- **Cloud-Native**: No local Docker required - build and deploy from the cloud
- **Monitoring**: Application Insights integration for observability
- **AI-Ready**: Microsoft Foundry (AI Hub) provisioned for GPT-4 and Phi model access

## Architecture

### Azure Resources (westus3)

- **Resource Group**: Single resource group containing all resources
- **Azure Container Registry (ACR)**: Container image storage with RBAC authentication
- **App Service Plan**: Linux-based B1 tier for dev environments
- **App Service**: Web App for Containers with managed identity
- **Log Analytics Workspace**: Centralized logging
- **Application Insights**: Application performance monitoring
- **AI Foundry Hub**: Machine learning workspace for AI model access

All resources use managed identities and RBAC for authentication - no passwords or secrets required.

## Quick Start

### Prerequisites

- Azure subscription with Contributor access
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (v2.50.0+)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (recommended)
- [.NET 8 SDK](https://dotnet.microsoft.com/download) (for local development)

### Deploy to Azure

#### Option 1: Using Azure Developer CLI (Recommended)

```bash
# Login to Azure
azd auth login

# Provision infrastructure and deploy application
azd up
```

That's it! The `azd up` command will:
1. Create all Azure resources in westus3
2. Build the container image in the cloud
3. Deploy the application to App Service
4. Output the application URL

#### Option 2: Using Azure CLI

```bash
# Login to Azure
az login

# Deploy infrastructure
az deployment sub create \
  --location westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.dev.json

# Build and push container image
ACR_NAME=$(az deployment sub show --name <deployment-name> --query properties.outputs.acrName.value -o tsv)
az acr build --registry $ACR_NAME --image zava-storefront:latest --file src/Dockerfile src/

# Get application URL
az deployment sub show --name <deployment-name> --query properties.outputs.appServiceHostname.value -o tsv
```

### Local Development

Run the application locally without Docker:

```bash
cd src
dotnet run
```

Navigate to `https://localhost:5001` to view the application.

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── build-deploy-acr.yml    # CI/CD pipeline for Azure
├── infra/                          # Infrastructure as Code
│   ├── modules/                    # Bicep modules
│   │   ├── acr.bicep              # Azure Container Registry
│   │   ├── acr-role-assignment.bicep
│   │   ├── app-service.bicep      # Web App for Containers
│   │   ├── app-service-plan.bicep
│   │   ├── app-insights.bicep     # Application Insights
│   │   ├── log-analytics.bicep    # Log Analytics
│   │   └── ai-foundry.bicep       # AI Foundry Hub
│   ├── main.bicep                 # Main orchestration template
│   ├── main.resources.bicep       # Resource deployment
│   ├── main.parameters.dev.json   # Dev environment parameters
│   └── README.md                  # Infrastructure documentation
├── src/                           # Application source code
│   ├── Controllers/
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   ├── wwwroot/
│   ├── Dockerfile                 # Multi-stage Docker build
│   ├── .dockerignore
│   └── README.md                  # Application documentation
├── azd.yaml                       # Azure Developer CLI configuration
└── README.md                      # This file
```

## Documentation

- **[Infrastructure Documentation](infra/README.md)**: Detailed guide on Azure resources, deployment, costs, and troubleshooting
- **[Application Documentation](src/README.md)**: Application features, architecture, and development guide
- **[CI/CD Pipeline](.github/workflows/build-deploy-acr.yml)**: Automated build and deployment workflow

## Cost Estimation

The dev environment is optimized for minimal cost:

| Resource | SKU | Estimated Cost/Month |
|----------|-----|---------------------|
| App Service Plan | B1 | ~$13.00 |
| Container Registry | Basic | ~$5.00 |
| Log Analytics | Pay-as-you-go | ~$2-5 |
| Application Insights | Pay-as-you-go | ~$0-2 (first 5GB free) |
| AI Foundry Hub | Basic | ~$0 (minimal usage) |
| **Total** | | **~$20-25/month** |

## Security Features

- **No admin credentials**: All authentication uses Azure RBAC
- **Managed identities**: System-assigned identities for all services
- **HTTPS enforcement**: All traffic encrypted with TLS 1.2+
- **Private registry access**: ACR accessible only via managed identity
- **Secure secrets**: No passwords in code or configuration

## CI/CD Pipeline

The included GitHub Actions workflow provides:
- Cloud-based container builds (no local Docker required)
- Automated deployment to App Service
- Support for multiple environments (dev/staging/prod)
- OIDC authentication to Azure (no secrets needed)

See the [workflow file](.github/workflows/build-deploy-acr.yml) for details.

## Monitoring

Application Insights is automatically configured to collect:
- Request telemetry
- Dependency calls
- Exceptions
- Custom events and metrics
- Performance counters

Access monitoring data in the Azure Portal under the Application Insights resource.

## AI Integration

The AI Foundry Hub is provisioned in westus3 to provide access to:
- GPT-4 models
- Phi models
- Other Azure AI services

See the [AI Foundry documentation](https://learn.microsoft.com/azure/machine-learning/) for details on using AI capabilities.

## Cleanup

To delete all Azure resources:

```bash
# Using azd
azd down

# Or using Azure CLI
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
