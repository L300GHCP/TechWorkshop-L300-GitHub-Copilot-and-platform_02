# Azure Infrastructure Summary

## Deployment Overview

This document provides a comprehensive overview of the Azure infrastructure provisioned for the ZavaStorefront application.

## Resources Deployed

### Resource Group
- **Name**: `rg-zavastore-dev-westus3`
- **Location**: West US 3
- **Purpose**: Container for all Azure resources

### Azure Container Registry (ACR)
- **Name**: `acrzavastoredewvestus3`
- **SKU**: Basic
- **Features**:
  - Admin user disabled (RBAC only)
  - 7-day image retention policy
  - Managed identity authentication
- **Purpose**: Store Docker container images

### App Service Plan
- **Name**: `asp-zavastore-dev-westus3`
- **SKU**: B1 (Linux)
- **Features**:
  - Linux containers support
  - Reserved capacity
- **Purpose**: Hosting platform for the web application

### App Service (Web App)
- **Name**: `app-zavastore-dev-westus3`
- **Type**: Web App for Containers
- **Features**:
  - System-assigned managed identity
  - HTTPS-only enforcement
  - TLS 1.2+ minimum
  - ACR managed identity authentication
  - Application Insights integration
- **Purpose**: Host the containerized .NET application

### Log Analytics Workspace
- **Name**: `log-zavastore-dev-westus3`
- **SKU**: PerGB2018
- **Retention**: 30 days
- **Purpose**: Centralized logging and analytics

### Application Insights
- **Name**: `appi-zavastore-dev-westus3`
- **Type**: Web application monitoring
- **Features**:
  - Connected to Log Analytics workspace
  - Request telemetry
  - Dependency tracking
  - Exception monitoring
- **Purpose**: Application performance monitoring and diagnostics

### AI Foundry Hub
- **Name**: `aif-zavastore-dev-westus3`
- **SKU**: Basic
- **Type**: Machine Learning Workspace (Hub)
- **Features**:
  - System-assigned managed identity
  - Public network access enabled
  - GPT-4 and Phi model access
- **Purpose**: AI/ML capabilities for the application

## Security Configuration

### Authentication & Authorization
- **No passwords**: All services use managed identities
- **RBAC**: AcrPull role assigned to App Service on ACR
- **Identity type**: System-assigned managed identities

### Network Security
- **HTTPS enforcement**: All App Service traffic is HTTPS-only
- **TLS version**: Minimum TLS 1.2
- **FTPS**: Disabled
- **ACR access**: Managed identity credentials only

### Compliance
- **Password-less authentication**: ✅
- **Encrypted traffic**: ✅
- **Managed identities**: ✅
- **RBAC authorization**: ✅

## Deployment Methods

### Azure Developer CLI (azd)
```bash
azd auth login
azd up
```

### Azure CLI
```bash
az login
az deployment sub create --location westus3 --template-file infra/main.bicep --parameters infra/main.parameters.dev.json
```

### GitHub Actions
Automated CI/CD pipeline that:
1. Builds container images in the cloud (no local Docker)
2. Pushes to ACR
3. Updates App Service with new image
4. Restarts the application

## Resource Dependencies

```
Resource Group (rg-zavastore-dev-westus3)
├── Log Analytics Workspace (log-zavastore-dev-westus3)
│   ├── Application Insights (appi-zavastore-dev-westus3)
│   └── AI Foundry Hub (aif-zavastore-dev-westus3)
├── Azure Container Registry (acrzavastoredewvestus3)
├── App Service Plan (asp-zavastore-dev-westus3)
│   └── App Service (app-zavastore-dev-westus3)
│       ├── Managed Identity → ACR (AcrPull role)
│       └── Application Insights connection
```

## Cost Breakdown (Monthly Estimates)

| Resource | SKU/Tier | Estimated Cost |
|----------|----------|----------------|
| App Service Plan | B1 | $13.00 |
| Azure Container Registry | Basic | $5.00 |
| Log Analytics | Pay-as-you-go | $2-5 |
| Application Insights | Pay-as-you-go | $0-2 (5GB free) |
| AI Foundry Hub | Basic | $0 (minimal usage) |
| **Total** | | **$20-25/month** |

## Monitoring & Observability

### Application Insights Telemetry
- HTTP requests and responses
- Dependencies (database, external APIs)
- Exceptions and stack traces
- Custom events and metrics
- Performance counters

### Log Analytics Queries
Access via Azure Portal → Log Analytics Workspace → Logs

Example queries:
```kusto
// Application requests
AppRequests
| where TimeGenerated > ago(1h)
| summarize count() by ResultCode

// Application exceptions
AppExceptions
| where TimeGenerated > ago(1h)
| project TimeGenerated, Message, ExceptionType
```

## Scaling Considerations

### Current Configuration (Dev)
- **App Service Plan**: B1 (1 core, 1.75 GB RAM)
- **Instances**: 1
- **Suitable for**: Development and testing

### Production Recommendations
- Upgrade to **P1v2 or P2v2** for better performance
- Enable **auto-scaling** based on CPU/memory
- Consider **Application Gateway** for advanced routing
- Implement **Azure Front Door** for global distribution

## Backup & Disaster Recovery

### Current State
- No automated backups configured (dev environment)
- Infrastructure can be redeployed from Bicep templates
- Application is stateless (no data loss risk)

### Production Recommendations
- Enable App Service backup
- Implement geo-redundant ACR
- Set up Azure Site Recovery for DR
- Configure backup for Log Analytics

## Next Steps

1. **Deploy the infrastructure**: Use `azd up` or Azure CLI
2. **Verify deployment**: Check all resources in Azure Portal
3. **Test the application**: Access the App Service URL
4. **Configure monitoring**: Set up alerts in Application Insights
5. **Set up CI/CD**: Configure GitHub Actions with Azure credentials
6. **Deploy the application**: Push code to trigger automated deployment

## Support & Troubleshooting

See [infra/README.md](README.md) for detailed troubleshooting guide.

## References

- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [App Service on Linux](https://docs.microsoft.com/azure/app-service/overview)
- [Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure Developer CLI](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [Managed Identities](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
