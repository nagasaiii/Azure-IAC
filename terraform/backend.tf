terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "nagasaitfstate"
    container_name       = "tfstate"
    key                  = "azure-demo.tfstate"
  }
}
