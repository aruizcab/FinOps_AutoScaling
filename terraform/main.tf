terraform {
  backend "azurerm" {
    resource_group_name  = "aruizcabtfstates"
    storage_account_name = "aruizcabtf"
    container_name       = "tfstatetfm"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# A resource group is like a folder for related resources. You can delete the resource group to delete all resources in it.
resource "azurerm_resource_group" "rg" {
  name     = "terraform-tfm"
  location = "northeurope"
}
