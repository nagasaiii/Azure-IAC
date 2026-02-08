terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateb7a2bdec"
    container_name       = "tfstate"
    key                  = "azure-demo.tfstate"
  }
}
