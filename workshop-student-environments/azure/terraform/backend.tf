terraform {
  backend "azurerm" {
    resource_group_name  = "External-Training-Utility"
    storage_account_name = "terraform4training"
    container_name       = "terraformstate"

  }
}