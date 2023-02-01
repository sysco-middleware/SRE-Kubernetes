#
# Core management resources
#
resource "azurerm_resource_group" "tfstate" {
  name     = var.tf_var_management_ResourceGroup
  location = var.tf_var_management_Region
}

resource "oci_objectstorage_bucket" "tfstate" {
  compartment_id = var.tf_var_management_Compartment_OCID
  name           = var.tf_var_management_BucketName
  access_type    = var.tf_var_management_BucketAccess
}


