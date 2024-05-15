terraform {
  backend "azurerm" {
    resource_group_name  = "tfmtfstates"
    storage_account_name = "tfmtf"
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

    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
}

data "azurerm_client_config" "current" {}

# ["northeurope", "westeurope", "eastus", "uksouth", "westus3"]
# A resource group is like a folder for related resources. You can delete the resource group to delete all resources in it.
resource "azurerm_resource_group" "rg" {
  name     = "terraform-tfm"
  location = "westus3"
}
