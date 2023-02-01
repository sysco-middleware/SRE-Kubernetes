variable "tf_var_management_ResourceGroup" {
  type        = string
  description = "Shared management resource group"
}

variable "tf_var_management_Region" {
  type        = string
  description = "Region used for all resources"
  default = "norwayeast"
}

variable "tf_var_management_Compartment_OCID" {
  type        = string
  description = "Region used for all resources"
  default = "norwayeast"
}

variable "tf_var_management_BucketName" {
  type        = string
  description = "Storage account created by bootstrap to hold all Terraform state"
}

variable "tf_var_management_BucketAccess" {
  type    = string
  default = "NoPublicAccess"
}
