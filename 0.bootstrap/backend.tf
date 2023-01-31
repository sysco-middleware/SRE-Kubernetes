terraform {
    backend "azurerm" {
        resource_group_name  = "sre-management-rg"
        storage_account_name = "sretfstatetstorage"
        container_name       = "sretfstatecontainer"
        key                  = "sre.tfstate"
    }

}