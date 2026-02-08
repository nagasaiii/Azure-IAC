output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.Azure-IAC.name
}

output "redis_cache_hostname" {
  description = "Redis Cache hostname"
  value       = azurerm_redis_cache.Azure-IAC.hostname
  sensitive   = true
}

output "redis_cache_ssl_port" {
  description = "Redis Cache SSL port"
  value       = azurerm_redis_cache.Azure-IAC.ssl_port
}

output "service_bus_namespace" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.Azure-IAC.name
}

output "service_bus_primary_connection_string" {
  description = "Service Bus primary connection string"
  value       = azurerm_servicebus_namespace.Azure-IAC.default_primary_connection_string
  sensitive   = true
}
