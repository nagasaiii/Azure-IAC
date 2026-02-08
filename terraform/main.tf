# Resource Group
resource "azurerm_resource_group" "Azure-IAC" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Azure-IaC-Github"
    CostCenter  = "Azure-IAC"
  }
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Azure Cache for Redis - Basic Tier (C0)
resource "azurerm_redis_cache" "Azure-IAC" {
  name                 = "redis-azure-iac-${random_string.suffix.result}"
  location             = azurerm_resource_group.Azure-IAC.location
  resource_group_name  = azurerm_resource_group.Azure-IAC.name
  capacity             = 0
  family               = "C"
  sku_name             = "Basic"
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  redis_configuration {
  }

  tags = azurerm_resource_group.Azure-IAC.tags
}

# Azure Service Bus - Basic Tier
resource "azurerm_servicebus_namespace" "Azure-IAC" {
  name                = "sb-azure-iac-${random_string.suffix.result}"
  location            = azurerm_resource_group.Azure-IAC.location
  resource_group_name = azurerm_resource_group.Azure-IAC.name
  sku                 = "Basic"

  tags = azurerm_resource_group.Azure-IAC.tags
}

# Service Bus Queue
resource "azurerm_servicebus_queue" "Azure-IAC" {
  name         = "azure-iac-queue"
  namespace_id = azurerm_servicebus_namespace.Azure-IAC.id

  partitioning_enabled = false
}
