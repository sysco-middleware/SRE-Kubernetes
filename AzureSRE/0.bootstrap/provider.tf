terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  
  subscription_id  = "__CHANGE_ME__"
  client_id  = "__CHANGE_ME__"
  client_secret  = "__CHANGE_ME__"
  tenant_id  = "__CHANGE_ME__"
}