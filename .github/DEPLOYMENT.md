# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that builds and deploys the Zava Storefront application to Azure App Service.

## Prerequisites

- Azure subscription with the infrastructure already provisioned
- GitHub repository with Actions enabled

## Required GitHub Secrets

Configure these secrets in your repository settings (Settings → Secrets and variables → Actions → Secrets):

### `AZURE_CREDENTIALS`
Azure service principal credentials for authentication. Create using:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --sdk-auth
```

Copy the entire JSON output and paste it as the secret value.

### `ACR_USERNAME`
Azure Container Registry username (admin username). Get it from:

```bash
az acr credential show --name {acr-name} --query username -o tsv
```

### `ACR_PASSWORD`
Azure Container Registry password (admin password). Get it from:

```bash
az acr credential show --name {acr-name} --query "passwords[0].value" -o tsv
```

**Note**: You must enable admin user on ACR first:
```bash
az acr update --name {acr-name} --admin-enabled true
```

## Required GitHub Variables

Configure these variables in your repository settings (Settings → Secrets and variables → Actions → Variables):

### `ACR_LOGIN_SERVER`
Value: `acrzavastoredevmychuurfyokni.azurecr.io`

### `APP_SERVICE_NAME`
Value: `app-zavastore-dev-mychuurfyokni`

### `RESOURCE_GROUP_NAME`
Value: `rg-zavastore-dev-uksouth`

## Quick Setup Commands

For your current environment, use these values:

```bash
# Enable ACR admin user
az acr update --name acrzavastoredevmychuurfyokni --admin-enabled true

# Get ACR credentials
az acr credential show --name acrzavastoredevmychuurfyokni

# Create service principal (replace {subscription-id})
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-zavastore-dev-uksouth \
  --sdk-auth
```

## Triggering Deployment

The workflow runs automatically on:
- Push to `main` branch
- Manual trigger via GitHub Actions UI (workflow_dispatch)

## Workflow Steps

1. **Checkout code** - Clones the repository
2. **Login to ACR** - Authenticates with Azure Container Registry
3. **Build and push** - Builds Docker image and pushes to ACR
4. **Azure login** - Authenticates with Azure using service principal
5. **Deploy** - Updates App Service container configuration
6. **Restart** - Restarts App Service to pull the new image

## Troubleshooting

- **ACR login fails**: Verify admin user is enabled and credentials are correct
- **Azure login fails**: Check service principal has proper permissions
- **Deployment fails**: Ensure App Service has AcrPull role on the Container Registry
