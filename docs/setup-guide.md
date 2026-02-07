# Detailed Setup Guide

This comprehensive guide walks through every step needed to set up and deploy this Azure infrastructure project from scratch.

---

## Table of Contents

1. [Azure Prerequisites](#azure-prerequisites)
2. [Service Principal Creation](#service-principal-creation)
3. [Storage Account Setup](#storage-account-setup)
4. [GitHub Configuration](#github-configuration)
5. [Terraform Configuration](#terraform-configuration)
6. [Local Testing](#local-testing)
7. [Deployment Workflow](#deployment-workflow)
8. [Troubleshooting](#troubleshooting)

---

## 1. Azure Prerequisites

### 1.1 Create or Upgrade Azure Subscription

**If you have a Free Trial**:

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Search for "Subscriptions" in the top search bar
3. Select your Free Trial subscription
4. Click the **"Upgrade"** button at the top
5. Follow the prompts to add payment method
6. Confirm upgrade to Pay-As-You-Go
7. **Note**: You keep any remaining credits and 12 months of free services

**If creating new account**:

1. Go to <https://azure.microsoft.com/free/>
2. Click "Start free" or "Pay as you go"
3. Sign in with Microsoft account
4. Complete registration with payment method

### 1.2 Locate Your Subscription ID and Tenant ID

**Method 1: Azure Portal**

1. In Azure Portal, search for **"Subscriptions"**
2. Click on your subscription name (e.g., "Pay-As-You-Go")
3. In the "Overview" page, copy:
   - **Subscription ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - **Tenant ID**: Found by clicking "Change directory" or searching "Microsoft Entra ID"

**Method 2: Azure CLI**

```bash
# Install Azure CLI (macOS)
brew install azure-cli

# Login
az login

# List subscriptions
az account list --output table

# Show current subscription details
az account show --query "{SubscriptionId:id, Name:name, TenantId:tenantId}" --output json
```

### 1.3 Set Budget Alerts (Critical!)

**Why**: Prevent unexpected charges from accidental resource creation

**Steps**:

1. Navigate to **"Cost Management + Billing"** in Azure Portal
2. Select your subscription from the scope picker (top-left dropdown)
3. In left menu, click **"Budgets"** under Cost Management section
4. Click **"+ Add"** button

**Budget Configuration**:

- **Name**: `Monthly-Dev-Budget`
- **Reset period**: Monthly
- **Creation date**: First day of current month
- **Expiration date**: One year from today
- **Budget amount**: `$10.00` (USD)

**Alert Conditions** (create 4 alerts):

| Alert Name | Type | Threshold | Email Notification |
| ------------ | ------ | ----------- | ------------------- |
| Budget 50% | Forecasted | 50% ($5.00) | ✅ Your email |
| Budget 75% | Actual | 75% ($7.50) | ✅ Your email |
| Budget 90% | Actual | 90% ($9.00) | ✅ Your email |
| Budget 100% | Actual | 100% ($10.00) | ✅ Your email |

1. Click **"Create"** to save budget
2. Verify you receive confirmation email

### 1.4 Save Your Credentials Securely

Create a secure note (1Password, LastPass, or encrypted file):

```bash
AZURE PROJECT CREDENTIALS
==========================
Subscription Name: [Your subscription name]
Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Tenant ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Account Email: [Your Azure login email]
Budget: $10/month with alerts at 50%, 75%, 90%, 100%
```

---

## 2. Service Principal Creation

### 2.1 What is a Service Principal?

A Service Principal is an **identity for applications/automation** (similar to AWS IAM Role). It allows GitHub Actions to authenticate to Azure and create resources without using your personal credentials.

### 2.2 Create Service Principal via Azure CLI

**Step 1: Login and Set Subscription**

```bash
# Login to Azure
az login

# Verify you're on the correct subscription
az account show --output table

# If not, set the correct subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

**Step 2: Create Service Principal with Contributor Role**

```bash
az ad sp create-for-rbac \
  --name "github-terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

Replace `YOUR_SUBSCRIPTION_ID` with your actual subscription ID from Step 1.2.

**Step 3: Save the Output**

The command will output JSON like this:

```json
{
  "appId": "12345678-1234-1234-1234-123456789abc",
  "displayName": "github-terraform-sp",
  "password": "",
  "tenant": "87654321-4321-4321-4321-abcdefghijkl"
}
```

**CRITICAL**: Save these values immediately (they won't be shown again):

- `appId` → This is your **ARM_CLIENT_ID**
- `password` → This is your **ARM_CLIENT_SECRET** (only shown once!)
- `tenant` → This is your **ARM_TENANT_ID**

**Step 4: Verify Service Principal**

```bash
# List service principals
az ad sp list --display-name "github-terraform-sp" --output table
```

### 2.3 Alternative: Create via Azure Portal

If you prefer GUI:

1. Navigate to **"Microsoft Entra ID"** (formerly Azure Active Directory)
2. Click **"App registrations"** in left menu
3. Click **"+ New registration"**
4. **Name**: `github-terraform-sp`
5. **Supported account types**: Single tenant
6. Click **"Register"**
7. Copy the **Application (client) ID** and **Directory (tenant) ID**
8. Go to **"Certificates & secrets"** → **"+ New client secret"**
9. **Description**: `GitHub Actions Secret`
10. **Expires**: 24 months
11. Click **"Add"** and **immediately copy the Value** (shown only once!)

**Assign Contributor Role**:

1. Navigate to your **Subscription** (search "Subscriptions")
2. Click **"Access control (IAM)"** in left menu
3. Click **"+ Add"** → **"Add role assignment"**
4. Select **"Contributor"** role → Click **"Next"**
5. Click **"+ Select members"**
6. Search for `github-terraform-sp` and select it
7. Click **"Review + assign"**

---

## 3. Storage Account Setup

### 3.1 Why Do We Need This?

Terraform stores infrastructure state in a file (`terraform.tfstate`). For automation and team collaboration, this must be stored remotely with locking capabilities. Azure Blob Storage provides this with built-in state locking.

### 3.2 Create Storage Account via Azure CLI

**Step 1: Create Resource Group**

```bash
az group create \
  --name terraform-state-rg \
  --location eastus
```

**Step 2: Create Storage Account**

**IMPORTANT**: Storage account names must be:

- Globally unique across all Azure
- 3-24 characters
- Lowercase letters and numbers only

```bash
# Replace XXXXX with random characters (e.g., your initials + random numbers)
export STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"
echo "Your storage account name: $STORAGE_ACCOUNT_NAME"

az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob \
  --allow-blob-public-access false
```

**Step 3: Create Blob Container**

```bash
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT_NAME
```

**Step 4: Enable Versioning (Recommended)**

```bash
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group terraform-state-rg \
  --enable-versioning true
```

**Step 5: Grant Service Principal Access**

```bash
# Get the Service Principal Object ID
SP_OBJECT_ID=$(az ad sp list --display-name "github-terraform-sp" --query "[0].id" -o tsv)

# Assign Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $SP_OBJECT_ID \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/terraform-state-rg/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
```

Replace `YOUR_SUBSCRIPTION_ID` with your actual subscription ID.

### 3.3 Verify Storage Account

**Azure Portal**:

1. Search for "Storage accounts"
2. Find your `tfstateXXXXX` account
3. Click on it → **"Containers"** → Verify `tfstate` container exists
4. Go to **"Access Control (IAM)"** → **"Role assignments"**
5. Verify `github-terraform-sp` has "Storage Blob Data Contributor" role

**Azure CLI**:

```bash
# Verify storage account exists
az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group terraform-state-rg

# Verify container exists
az storage container list --account-name $STORAGE_ACCOUNT_NAME --output table
```

### 3.4 Save Storage Account Name

**Add to your secure notes**:

```bash
TERRAFORM STATE STORAGE
=======================
Resource Group: terraform-state-rg
Storage Account: tfstateXXXXX
Container: tfstate
Location: eastus
SKU: Standard_LRS
```

---

## 4. GitHub Configuration

### 4.1 Create GitHub Repository

1. Go to <https://github.com/new>
2. **Repository name**: `azure-terraform-iac-demo`
3. **Description**: `Production-grade Azure infrastructure provisioning using Terraform and GitHub Actions CI/CD`
4. **Visibility**: Public (for portfolio + free GitHub Actions minutes)
5. **Initialize**:
   - ✅ Add a README file
   - ✅ Add .gitignore: Terraform
   - ✅ Choose a license: MIT
6. Click **"Create repository"**

### 4.2 Clone Repository Locally

```bash
cd ~/projects  # or your preferred directory
git clone https://github.com/YOUR_USERNAME/azure-terraform-iac-demo.git
cd azure-terraform-iac-demo
```

### 4.3 Configure GitHub Secrets

**Navigate to Repository Settings**:

1. Go to your repository on GitHub
2. Click **"Settings"** tab
3. In left sidebar, click **"Secrets and variables"** → **"Actions"**
4. Click **"New repository secret"** for each of the following:

**Secrets to Add**:

| Secret Name | Value | Source |
| ------------- | ------- | -------- |
| `ARM_SUBSCRIPTION_ID` | Your subscription ID | Step 1.2 output |
| `ARM_TENANT_ID` | Your tenant ID | Step 1.2 or SP creation output |
| `ARM_CLIENT_ID` | Service Principal appId | Step 2.2 output |
| `ARM_CLIENT_SECRET` | Service Principal password | Step 2.2 output |

**For each secret**:

1. Click **"New repository secret"**
2. **Name**: (exact name from table above)
3. **Secret**: (paste the corresponding value)
4. Click **"Add secret"**

### 4.4 Set Up Branch Protection

1. In repository Settings, click **"Branches"** (under "Code and automation")
2. Click **"Add branch protection rule"**

**Configuration**:

- **Branch name pattern**: `main`
- ✅ **Require a pull request before merging**
  - Required approvals: **0** (for solo developer)
  - ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Search and add: `YAML Lint`, `Terraform Format & Validate`, `Markdown Lint`
- ✅ **Require conversation resolution before merging**
- ❌ **Do NOT check "Lock branch"** (this prevents merging)
- ❌ **Do NOT allow bypassing the above settings**

1. Click **"Create"** or **"Save changes"**

---

## 5. Terraform Configuration

### 5.1 Create Directory Structure

```bash
cd azure-terraform-iac-demo

mkdir -p .github/workflows
mkdir -p terraform
mkdir -p screenshots
mkdir -p docs
```

### 5.2 Create Terraform Backend Configuration

Create `terraform/backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"  # Replace with YOUR storage account name
    container_name       = "tfstate"
    key                  = "azure-demo.tfstate"
  }
}
```

**Replace `tfstateXXXXX`** with your actual storage account name from Step 3.2.

### 5.3 Create Provider Configuration

Create `terraform/provider.tf`:

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  # Authentication via environment variables
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}
```

### 5.4 Create Variables Configuration

Create `terraform/variables.tf`:

```hcl
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-terraform-demo"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "Demo"
}
```

### 5.5 Create Outputs Configuration

Create `terraform/outputs.tf`:

```hcl
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.demo.name
}

output "redis_cache_hostname" {
  description = "Redis Cache hostname"
  value       = azurerm_redis_cache.demo.hostname
  sensitive   = true
}

output "redis_cache_ssl_port" {
  description = "Redis Cache SSL port"
  value       = azurerm_redis_cache.demo.ssl_port
}

output "service_bus_namespace" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.demo.name
}

output "service_bus_connection_string" {
  description = "Service Bus primary connection string"
  value       = azurerm_servicebus_namespace.demo.default_primary_connection_string
  sensitive   = true
}
```

### 5.6 Create Main Resource Configuration

Create `terraform/main.tf`:

```hcl
# Resource Group
resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Azure-IaC-Portfolio"
    CostCenter  = "Demo"
  }
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Azure Cache for Redis - Basic Tier (C0)
resource "azurerm_redis_cache" "demo" {
  name                = "redis-demo-${random_string.suffix.result}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  tags = azurerm_resource_group.demo.tags
}

# Azure Service Bus - Basic Tier
resource "azurerm_servicebus_namespace" "demo" {
  name                = "sb-demo-${random_string.suffix.result}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  sku                 = "Basic"

  tags = azurerm_resource_group.demo.tags
}

# Service Bus Queue
resource "azurerm_servicebus_queue" "demo" {
  name         = "demo-queue"
  namespace_id = azurerm_servicebus_namespace.demo.id

  enable_partitioning = false
}
```

### 5.7 Create Example Variables File

Create `terraform/terraform.tfvars.example`:

```hcl
# Azure Credentials (DO NOT commit actual values!)
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
client_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
client_secret   = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Resource Configuration
location            = "eastus"
resource_group_name = "rg-terraform-demo"
environment         = "Demo"
```

---

## 6. Local Testing (Optional but Recommended)

### 6.1 Install Terraform Locally

**macOS**:

```bash
brew install terraform
terraform version
```

**Linux**:

```bash
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

**Windows**:

```powershell
# Using Chocolatey
choco install terraform

# Or download from https://www.terraform.io/downloads
```

### 6.2 Test Terraform Configuration Syntax

```bash
cd terraform

# Format check (will show which files need formatting)
terraform fmt -check -recursive

# Apply formatting
terraform fmt -recursive

# Initialize (without backend to avoid needing Azure auth)
terraform init -backend=false

# Validate syntax
terraform validate
```

### 6.3 Test with Azure Authentication (Optional)

**Only if you want to test full deployment locally**:

```bash
cd terraform

# Set environment variables
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"

# Initialize with backend
terraform init

# Generate execution plan
terraform plan

# DO NOT RUN: terraform apply (save this for GitHub Actions)
```

---

## 7. Deployment Workflow

### 7.1 Feature Branch Workflow

**Step 1: Create Feature Branch**

```bash
git checkout main
git pull origin main
git checkout -b feature/add-terraform-resources
```

**Step 2: Make Changes**

- Edit Terraform files
- Update documentation
- Add any new configurations

**Step 3: Commit Changes**

```bash
git add .
git commit -m "Add Azure Cache for Redis and Service Bus resources"
git push origin feature/add-terraform-resources
```

**Step 4: Create Pull Request**

1. Go to GitHub repository
2. Click **"Pull requests"** → **"New pull request"**
3. Base: `main` ← Compare: `feature/add-terraform-resources`
4. Click **"Create pull request"**
5. Fill in description
6. Wait for status checks to pass
7. Review changes
8. Click **"Merge pull request"** or **"Squash and merge"**

### 7.2 Deploy Infrastructure via GitHub Actions

**Step 1: Navigate to Actions**

1. Go to your GitHub repository
2. Click **"Actions"** tab in the top menu
3. You should see "Terraform Deploy" workflow in the left sidebar

**Step 2: Trigger Deployment**

1. Click on **"Terraform Deploy"** workflow
2. Click **"Run workflow"** dropdown button (top-right)
3. Select branch: `main`
4. Click green **"Run workflow"** button
5. Workflow will start executing

**Step 3: Monitor Execution**

1. Click on the running workflow to see live logs
2. Expand each job to see detailed output
3. **Expected duration**: 8-12 minutes (Redis takes 5-7 minutes)

**Step 4: Verify in Azure Portal**

1. Login to [Azure Portal](https://portal.azure.com)
2. Search for "Resource groups"
3. Click on `rg-terraform-demo`
4. Verify resources:
   - Azure Cache for Redis (status: Running)
   - Service Bus Namespace (status: Active)
   - Service Bus Queue

### 7.3 Capture Screenshots for Documentation

While resources are running:

**Screenshot 1: GitHub Actions Success**

- Actions tab → Completed workflow with green checkmark
- Save as `screenshots/github-actions-deploy-success.png`

**Screenshot 2: Resource Group Overview**

- Azure Portal → Resource Groups → `rg-terraform-demo`
- Overview showing all 3 resources
- Save as `screenshots/azure-resource-group.png`

**Screenshot 3: Redis Cache Details**

- Click Redis Cache resource
- Overview page showing status, tier, hostname
- Save as `screenshots/azure-redis-cache.png`

**Screenshot 4: Service Bus Details**

- Click Service Bus Namespace
- Overview page showing status, tier, queues
- Save as `screenshots/azure-service-bus.png`

**Screenshot 5: Cost Analysis**

- Go to "Cost Management + Billing"
- Cost analysis showing actual spend
- Save as `screenshots/azure-cost-analysis.png`

### 7.4 Destroy Infrastructure

**IMPORTANT**: Destroy resources immediately to minimize costs!

**Step 1: Trigger Destroy Workflow**

1. Go to **"Actions"** tab
2. Click **"Terraform Destroy"** workflow
3. Click **"Run workflow"** dropdown
4. Select branch: `main`
5. Click **"Run workflow"** button

**Step 2: Monitor Execution**

- Watch the workflow logs
- **Expected duration**: 3-5 minutes

**Step 3: Verify Deletion**

1. Go to Azure Portal
2. Navigate to Resource Groups
3. Verify `rg-terraform-demo` is either:
   - Deleted (preferred), or
   - Empty (if only resources were destroyed)

**Step 4: Manual Cleanup (if needed)**

```bash
# If resource group still exists, delete manually
az group delete --name rg-terraform-demo --yes --no-wait
```

### 7.5 Commit Screenshots to Repository

```bash
git checkout main
git pull origin main
git checkout -b docs/add-deployment-screenshots

# Add screenshots
git add screenshots/
git commit -m "Add deployment validation screenshots"
git push origin docs/add-deployment-screenshots

# Create PR and merge
```

---

## 8. Troubleshooting

### 8.1 Service Principal Authentication Fails

**Error Message**:

```bash
Error building AzureRM Client: obtain subscription() from Azure CLI...
```

**Possible Causes & Solutions**:

1. **Incorrect GitHub Secrets**
   - Verify all 4 secrets are set correctly
   - Check for extra spaces or newlines
   - Re-create secrets if needed

2. **Service Principal Not Propagated**
   - Wait 5-10 minutes after SP creation
   - Azure AD replication can take time

3. **Missing Contributor Role**

   ```bash
   # Verify role assignment
   az role assignment list --assignee YOUR_CLIENT_ID --output table
   ```

4. **Expired Client Secret**
   - Check secret expiration date
   - Create new secret if expired

### 8.2 Terraform Backend Initialization Fails

**Error Message**:

```bash
Error: Failed to get existing workspaces: containers.Client#ListBlobs
```

**Solutions**:

1. **Verify Storage Account Name**
   - Check `backend.tf` has correct storage account name
   - Name must match exactly (case-sensitive)

2. **Missing Storage Permissions**

   ```bash
   # Grant Storage Blob Data Contributor role
   az role assignment create \
     --role "Storage Blob Data Contributor" \
     --assignee YOUR_CLIENT_ID \
     --scope "/subscriptions/SUB_ID/resourceGroups/terraform-state-rg"
   ```

3. **Storage Account Firewall**
   - Go to Storage Account → Networking
   - Ensure "Allow Azure services" is enabled

4. **Container Doesn't Exist**

   ```bash
   # Verify container exists
   az storage container show \
     --name tfstate \
     --account-name YOUR_STORAGE_ACCOUNT
   ```

### 8.3 Redis Cache Provisioning Timeout

**Symptom**: Workflow times out waiting for Redis

**Solutions**:

1. **Increase Workflow Timeout**
   - Edit `.github/workflows/terraform-deploy.yml`
   - Add `timeout-minutes: 30` to the terraform job

2. **Check Azure Service Health**
   - Azure Portal → Service Health
   - Check for outages in your region

3. **Try Different Region**
   - Change `location = "eastus"` to `"westus2"` or `"centralus"`

4. **Be Patient**
   - Redis Basic C0 typically takes 15-20 minutes
   - This is normal Azure behavior

### 8.4 Terraform State Lock Issues

**Error Message**:

```bash
Error: Error acquiring the state lock
```

**Causes & Solutions**:

1. **Previous Workflow Still Running**
   - Check Actions tab for running workflows
   - Cancel conflicting workflow

2. **Stale Lock from Failed Run**

   ```bash
   # Force unlock (use with caution!)
   cd terraform
   terraform init
   terraform force-unlock LOCK_ID
   ```

3. **Multiple Simultaneous Runs**
   - Never run deploy and destroy simultaneously
   - Wait for one workflow to complete

### 8.5 GitHub Actions Workflow Not Triggering

**Possible Issues**:

1. **Workflow File Location**
   - Must be in `.github/workflows/` directory
   - File must have `.yml` or `.yaml` extension

2. **YAML Syntax Error**
   - Use online YAML validator
   - Check indentation (use 2 spaces, not tabs)

3. **Branch Protection Blocking**
   - Verify workflows have permission to run
   - Check Actions settings in repository

4. **Workflow Disabled**
   - Go to Actions tab
   - Check if workflow shows as disabled
   - Click "Enable workflow" if needed

### 8.6 Cost Charges Higher Than Expected

**Investigation Steps**:

1. **Check Cost Analysis**
   - Azure Portal → Cost Management + Billing → Cost analysis
   - Group by: Resource
   - View detailed breakdown

2. **Look for Zombie Resources**

   ```bash
   # List all resource groups
   az group list --output table

   # Check for unexpected resources
   az resource list --output table
   ```

3. **Verify Resource Deletion**
   - Ensure destroy workflow completed successfully
   - Manually check resource groups in portal

4. **Check for Hidden Costs**
   - Data transfer charges
   - Storage transactions
   - IP address reservations

5. **Contact Azure Support**
   - If charges seem incorrect
   - Request detailed billing breakdown

### 8.7 Terraform Apply Fails with Resource Already Exists

**Error Message**:

```bash
Error: A resource with the ID "..." already exists
```

**Solutions**:

1. **Import Existing Resource**

   ```bash
   terraform import azurerm_resource_group.demo /subscriptions/SUB_ID/resourceGroups/rg-terraform-demo
   ```

2. **Delete Existing Resource Manually**
   - Azure Portal → Delete the conflicting resource
   - Re-run terraform apply

3. **Use Different Resource Names**
   - Change `resource_group_name` variable
   - Ensure `random_string.suffix` is generating unique names

### 8.8 Secret Detection False Positives

**Issue**: detect-secrets flags non-sensitive data

**Solutions**:

1. **Create Baseline File**

   ```bash
   detect-secrets scan > .secrets.baseline
   git add .secrets.baseline
   ```

2. **Update Pre-Check Workflow**
   - Add `--baseline .secrets.baseline` to scan command

3. **Ignore Specific Files**
   - Add to `.github/workflows/pre-checks.yml`:

   ```yaml
   --exclude-files 'docs/.*'
   ```

---

## 9. Best Practices Summary

### Security

- ✅ Never commit credentials to Git
- ✅ Use GitHub Secrets for sensitive values
- ✅ Rotate Service Principal secrets regularly (every 90 days)
- ✅ Use minimum required permissions (Contributor role)
- ✅ Enable TLS 1.2+ on all resources

### Cost Management

- ✅ Always destroy resources after testing
- ✅ Set up budget alerts before deploying
- ✅ Use smallest resource tiers for demos
- ✅ Monitor costs daily during active development
- ✅ Tag all resources for cost tracking

### Development Workflow

- ✅ Always work in feature branches
- ✅ Create PRs for all changes
- ✅ Wait for status checks before merging
- ✅ Test locally with `terraform validate` before pushing
- ✅ Review workflow logs for warnings

### Documentation

- ✅ Keep README and docs updated
- ✅ Capture screenshots at each milestone
- ✅ Document all manual steps
- ✅ Include troubleshooting tips as you encounter issues
- ✅ Version control everything (except secrets!)

---

## 10. Next Steps

### Phase Completion Checklist

**Phase 1-2: Foundation** ✅

- [x] Azure account created
- [x] Subscription upgraded to Pay-As-You-Go
- [x] Budget alerts configured
- [x] Subscription ID and Tenant ID recorded

**Phase 3: Service Principal** ✅

- [x] Service Principal created
- [x] Credentials saved securely
- [x] Contributor role assigned

**Phase 4: State Storage** ✅

- [x] Storage account created
- [x] Blob container configured
- [x] Service Principal granted access

**Phase 5: GitHub Configuration** ✅

- [x] Repository created
- [x] GitHub Secrets configured
- [x] Branch protection enabled
- [x] Pre-check workflows added

**Phase 6: Terraform Resources** ✅

- [x] Terraform configurations created
- [x] Resources defined (Redis, Service Bus)
- [x] Workflows implemented

**Phase 7: Deployment & Validation**

- [ ] Deploy infrastructure via GitHub Actions
- [ ] Capture screenshots
- [ ] Verify functionality
- [ ] Document costs
- [ ] Destroy resources
- [ ] Update portfolio

### Future Enhancements

**Technical Improvements**:

- [ ] Add Terraform modules for reusability
- [ ] Implement multi-environment support (dev/staging/prod)
- [ ] Add tfsec/Checkov security scanning
- [ ] Migrate to OIDC authentication (passwordless)
- [ ] Add Terraform Cloud integration

**Additional Resources**:

- [ ] Azure Virtual Network with subnets
- [ ] Azure Key Vault for secrets management
- [ ] Azure Monitor dashboards
- [ ] Azure Application Gateway
- [ ] Azure SQL Database

**DevOps Practices**:

- [ ] Add PR comment with `terraform plan` output
- [ ] Implement drift detection workflow
- [ ] Add cost estimation in PRs
- [ ] Create automated documentation generation
- [ ] Add integration tests

---

## 11. Additional Resources

### Official Documentation

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Service Principal Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)

### Learning Resources

- [Terraform Tutorial - HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [Azure Fundamentals Learning Path](https://docs.microsoft.com/en-us/learn/paths/azure-fundamentals/)
- [GitHub Actions Tutorial](https://docs.github.com/en/actions/learn-github-actions)

### Community & Support

- [Terraform Azure Provider Issues](https://github.com/hashicorp/terraform-provider-azurerm/issues)
- [Azure Community Support](https://docs.microsoft.com/en-us/answers/products/azure)
- [r/Terraform Reddit](https://www.reddit.com/r/Terraform/)
- [r/Azure Reddit](https://www.reddit.com/r/AZURE/)

### Tools & Utilities

- [Terraform Visual Studio Code Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/)
- [Terraform Graph Visualizer](https://github.com/blast-radius/blast-radius)

---

## Appendix A: Quick Reference Commands

### Azure CLI

```bash
# Login
az login

# List subscriptions
az account list --output table

# Set subscription
az account set --subscription "SUBSCRIPTION_ID"

# List resource groups
az group list --output table

# List all resources
az resource list --output table

# Delete resource group
az group delete --name RESOURCE_GROUP_NAME --yes
```

### Terraform

```bash
# Initialize
terraform init

# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Show state
terraform show

# List resources in state
terraform state list
```

### Git

```bash
# Create feature branch
git checkout -b feature/branch-name

# Stage changes
git add .

# Commit
git commit -m "Commit message"

# Push
git push origin feature/branch-name

# Update main branch
git checkout main
git pull origin main
```

---

## Appendix B: Troubleshooting Decision Tree

```bash
Issue: Terraform command fails
├─ Authentication error?
│  ├─ Check GitHub Secrets
│  ├─ Verify Service Principal exists
│  └─ Confirm role assignments
├─ Backend error?
│  ├─ Verify storage account name
│  ├─ Check container exists
│  └─ Confirm SP has storage permissions
├─ Resource error?
│  ├─ Check resource name conflicts
│  ├─ Verify quota limits
│  └─ Check region availability
└─ Syntax error?
   ├─ Run terraform validate
   ├─ Check HCL syntax
   └─ Review provider version
```

---

**End of Setup Guide**

For questions or issues, please open an issue in the GitHub repository.
