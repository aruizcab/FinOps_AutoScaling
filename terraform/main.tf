terraform {
  backend "azurerm" {
    resource_group_name  = "<Resource-group>"
    storage_account_name = "<Storage-account-name>"
    container_name       = "<container-name>"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# A resource group is like a folder for related resources. You can delete the resource group to delete all resources in it.
resource "azurerm_resource_group" "rg" {
  name     = "terraform-tutorial"
  location = "westus3"
}
