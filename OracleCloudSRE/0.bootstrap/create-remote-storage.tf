#
# Core management resources
#

resource "oci_identity_compartment" "tf-compartment" {
    compartment_id = var.tf_var_management_ParentCompartment_OCID
    description = "Compartment for Terraform resources"
    name = var.tf_var_management_Compartment
}

resource "oci_objectstorage_bucket" "tfstate" {
  compartment_id = var.tf_var_management_Compartment_OCID
  name           = var.tf_var_management_BucketName
  namespace      = var.tf_var_management_BucketNS
  access_type    = var.tf_var_management_BucketAccess
}
