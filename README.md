# Azure-IAC

## Azure Infrastructure Provisioning with Terraform & GitHub Actions

[![Terraform](https://img.shields.io/badge/Terraform-v1.7+-623CE4?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=flat&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A production-grade Infrastructure as Code (IaC) project demonstrating automated Azure resource provisioning using Terraform with GitHub Actions CI/CD pipeline. Built with cost optimization and DevOps best practices in mind.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technologies](#technologies)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Cost Analysis](#cost-analysis)
- [Workflows](#workflows)
- [Security](#security)
- [Screenshots](#screenshots)
- [Lessons Learned](#lessons-learned)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)
- [Acknowledgments](#acknowledgments)

---

## 🎯 Overview

This project demonstrates a complete Infrastructure as Code workflow for Azure, featuring:

- **Automated provisioning** of Azure Cache for Redis and Azure Service Bus
- **GitHub Actions CI/CD** pipeline for infrastructure deployment
- **Remote state management** using Azure Blob Storage
- **Service Principal authentication** for secure Azure access
- **Cost-optimized** resource configuration for minimal spending

**Project Goal**: Validate Terraform IaC capabilities in Azure while maintaining sub-$1 deployment costs through ephemeral infrastructure testing.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                        │
│   ┌────────────────────────────────────────────────────┐    │
│   │          Terraform Configuration Files             │    │
│   │ (main.tf, provider.tf, backend.tf, variables.tf)   │    │
│   └────────────────────────────────────────────────────┘    │
│                            ↓                                │
│   ┌────────────────────────────────────────────────────┐    │
│   │            GitHub Actions Workflow                 │    │
│   │       (terraform-deploy.yml / destroy.yml)         │    │
│   └────────────────────────────────────────────────────┘    │
└──────────────────────────┬──────────────────────────────────┘
                           ↓ (Service Principal Auth)
          ┌─────────────────────────────────────┐
          │       Azure Cloud Platform          │
          │                                     │
          │    ┌────────────────────────────┐   │
          │    │ Azure Storage Account      │   │
          │    │ (Terraform State Backend)  │   │
          │    └────────────────────────────┘   │
          │                                     │
          │    ┌────────────────────────────┐   │
          │    │ Azure Cache for Redis      │   │
          │    │ (Basic C0 - 250MB)         │   │
          │    └────────────────────────────┘   │
          │                                     │
          │    ┌────────────────────────────┐   │
          │    │ Azure Service Bus          │   │
          │    │ (Basic Tier - Queue)       │   │
          │    └────────────────────────────┘   │
          └─────────────────────────────────────┘
```

---

## 🛠️ Technologies

| Category | Technology | Purpose |
| ---------- | ----------- | --------- |
| **IaC** | Terraform 1.7+ | Infrastructure provisioning and management |
| **Cloud** | Microsoft Azure | Cloud platform provider |
| **CI/CD** | GitHub Actions | Automated deployment pipeline |
| **State Management** | Azure Blob Storage | Remote Terraform state with locking |
| **Authentication** | Azure Service Principal | Automated identity and access management |
| **Version Control** | Git / GitHub | Source code management |

---

## ✨ Features

- ✅ **Automated Infrastructure Provisioning** - One-click deployment via GitHub Actions
- ✅ **Remote State Management** - Terraform state stored in Azure Blob Storage with versioning
- ✅ **Cost Optimized** - Basic tier resources with immediate teardown capability
- ✅ **Secure Authentication** - Service Principal with GitHub Secrets integration
- ✅ **Idempotent Deployments** - Reliable, repeatable infrastructure creation
- ✅ **Manual Triggers** - Workflow dispatch for controlled deployments
- ✅ **Comprehensive Documentation** - Detailed setup guides and cost analysis

---

## 📦 Prerequisites

### Required Tools

- **Azure Account** with Pay-As-You-Go subscription (Free Trail Subscription with initial Free Credits will also work)
- **GitHub Account** with repository access
  - public repo is preferred for using shared runners provided by Github or create your own dedicated runners
- **Azure CLI** (`v2.50+`) - [Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Terraform** (`v1.7+`) - [Install Guide](https://developer.hashicorp.com/terraform/downloads) (for local testing)

### Required Knowledge

- Basic understanding of Terraform syntax
- Familiarity with Azure services
- YAML configuration experience
- Git command line basics

---

## 📁 Project Structure

```
Azure_IAC/
├── .github/
│ └── workflows/
│ ├── terraform-deploy.yml # Main deployment pipeline
│ └── terraform-destroy.yml # Cleanup/teardown pipeline
├── terraform/
│ ├── main.tf # Core resource definitions
│ ├── provider.tf # Azure provider configuration
│ ├── backend.tf # Remote state configuration
│ ├── variables.tf # Input variable definitions
│ ├── outputs.tf # Output value definitions
│ └── terraform.tfvars.example # Example variable values
├── screenshots/ # Deployment validation screenshots
├── docs/
│ ├── setup-guide.md # Detailed setup instructions
│ └── cost-analysis.md # Cost breakdown and optimization
├── .gitignore # Git ignore rules (Terraform files)
├── LICENSE # MIT License
└── README.md # This file
```

---

## 🚀 Quick Start

### 1. Fork and Clone Repository

```bash
git clone https://github.com/nagasaiii/Azure-IAC.git 
cd Azure-IAC
```

### 2. Create Azure Service Principal

```bash
# Login to Azure
az login
or
az login --tenant "YOUR_TENANT_ID"

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create Service Principal
az ad sp create-for-rbac \
  --name "github-terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Save the output: appId, password, tenant
```

### 3. Create Terraform State Storage

```bash
# Create resource group
az group create --name terraform-state-rg --location eastus

# Create storage account (name must be globally unique)
az storage account create \
  --name tfstateXXXXX \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS

# Create blob container
az storage container create \
  --name tfstate \
  --account-name tfstateXXXXX

# Assign permissions to Service Principal
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee APP_ID \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/terraform-state-rg"
```

### 4. Configure GitHub Secrets

Go to repository Settings → Secrets and variables → Actions and add:

`ARM_SUBSCRIPTION_ID` - Your Azure Subscription ID

`ARM_TENANT_ID` - Your Azure Tenant ID

`ARM_CLIENT_ID` - Service Principal App ID

`ARM_CLIENT_SECRET` - Service Principal Password

### 5. Update Backend Configuration

Edit terraform/backend.tf with your storage account name:

```bash
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"  # Your unique name
    container_name       = "tfstate"
    key                  = "azure-demo.tfstate"
  }
}
```

### 6. Deploy Infrastructure

Go to `Actions` tab in GitHub

Select `Terraform Deploy` workflow

Click `Run workflow` → Run workflow

Monitor the execution logs

Verify resources in Azure Portal

### 7. Destroy Infrastructure

Go to `Actions` tab

Select `Terraform Destroy` workflow

Click `Run workflow` → Run workflow

Confirm resources are deleted in Azure Portal

## 💰 Cost Analysis

| Resource | Tier | Hourly Cost | Test Duration | Total Cost |
| ---------- | ----------- | --------- | ----------- | ---------- |
| **Azure Cache for Redis** | Basic C0 (250MB) | $0.020/hour | ~15 minutes | $0.005 |
| **Azure Service Bus** | Basic | $0.05/million ops | ~10 operations | $0.001 |
| **Storage Account** | Standard LRS | $0.02/GB/month | 1GB state file | $0.001 |

**Total Estimated** - - Single Run < $0.01
Monthly Budget Recommendation: $10 (allows 1000+ test runs)

For detailed cost optimization strategies, see `docs/cost-analysis.md`

## 🔄 Workflows

### Terraform Deploy Workflow

**Trigger**: Manual (workflow_dispatch)

**Steps**:

1. Checkout repository code
2. Setup Terraform CLI
3. Initialize Terraform (download providers, configure backend)
4. Validate Terraform syntax
5. Generate execution plan
6. Apply infrastructure changes
7. Output resource details
8. Upload artifacts

**Duration**: ~8-10 minutes (Redis cache takes 5-7 minutes to provision)

### Terraform Destroy Workflow

**Trigger**: Manual (workflow_dispatch)

**Steps**:

1. Checkout repository code
2. Setup Terraform CLI
3. Initialize Terraform
4. Destroy all managed resources

**Duration**: ~3-5 minutes

## 🔒 Security

**Authentication**

Service Principal authentication with least-privilege access (Contributor role scoped to subscription)

GitHub Secrets for credential storage (encrypted at rest)

No hardcoded credentials in source code

**Best Practices Implemented**

✅ TLS 1.2+ enforcement on Redis cache

✅ Non-SSL ports disabled

✅ Resource tagging for governance

✅ State file versioning enabled

✅ .gitignore configured for sensitive files

**Future Security Enhancements**

 Implement OpenID Connect (OIDC) for passwordless authentication

 Add Terraform state encryption with customer-managed keys

 Implement network security groups and private endpoints

 Add Azure Policy compliance scanning

## 📸 Screenshots

Successful Deployment

GitHub Actions Success
Terraform Deploy workflow execution

Azure Resources

Azure Portal Resources
Provisioned resources in Azure Portal

Cost Analysis

Azure Cost Management
Actual deployment costs

## 📚 Lessons Learned

### Technical Insights

**Redis Provisioning Time** - Azure Cache for Redis takes 15-20 minutes to fully provision; plan workflow timeouts accordingly

**Service Principal Propagation** - Allow 5-10 minutes after SP creation for role assignments to propagate across Azure regions

**State Locking** - Azure Blob Storage provides automatic state locking via lease mechanism

**GitHub Actions Secrets** - Secrets are masked in logs but must be explicitly passed as environment variables

### DevOps Best Practices

**Cost Management** - Always use smallest resource tiers for testing/demo purposes

**Workflow Design** - Separate deploy and destroy workflows provide better control

**Documentation** - Screenshots and cost analysis significantly improve portfolio presentation

**Iterative Testing** - Test locally with terraform plan before committing to workflows

## 🚧 Future Enhancements

 Multi-Environment Support - Add dev/staging/prod workspace management

 Terraform Modules - Refactor resources into reusable modules

 PR Automation - Auto-comment terraform plan output on pull requests

 Security Scanning - Integrate tfsec/Checkov for IaC security analysis

 Monitoring - Add Azure Monitor alerts and dashboards

 Additional Resources - Expand to include VNet, App Service, SQL Database

 OIDC Authentication - Migrate from Service Principal secrets to OIDC

 Terraform Cloud - Compare Azure backend vs. Terraform Cloud for state management

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 Author

Naga Sai Dandamudi

GitHub: [nagasaiii](https://github.com/nagasaiii/nagasaiii/)

## 🙏 Acknowledgments

[HashiCorp Terraform Documentation](https://developer.hashicorp.com/terraform/docs)

[Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

[GitHub Actions Documentation](https://docs.github.com/en/actions)

⭐ If you found this project helpful, please consider giving it a star!
