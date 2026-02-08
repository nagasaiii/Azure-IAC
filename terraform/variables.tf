variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "Azure-IAC-RG"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "Demo"
}
