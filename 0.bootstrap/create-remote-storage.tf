#
# Core management resources
#
resource "azurerm_resource_group" "tfstate" {
  name     = var.tf_var_management_ResourceGroup
  location = var.tf_var_management_Region
  
  tags = {
    environment = "poc"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.tf_var_management_storageaccountName
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false

  tags = {
    environment = "poc"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.tf_var_management_container
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}