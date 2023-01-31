terraform {
    backend "azurerm" {
        resource_group_name  = "__CHANGE_ME__"
        storage_account_name = "__CHANGE_ME__"
        container_name       = "__CHANGE_ME__"
        key                  = "__CHANGE_ME__"
    }

}