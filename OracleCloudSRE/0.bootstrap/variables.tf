variable "tf_var_management_Region" {
  type        = string
  description = "Region used for all resources"
  default = "norwayeast"
}

variable "tf_var_management_Compartment" {
  type        = string
  description = "Storage account created by bootstrap to hold all Terraform state"
}


variable "tf_var_management_Compartment_OCID" {
  type        = string
  description = "Bootstrap Compartment used for all resources"
  default = "norwayeast"
}

variable "tf_var_management_ParentCompartment_OCID" {
  type        = string
  description = "Parent COmpartment of Bootstrap Compartment"
  default = "norwayeast"
}

variable "tf_var_management_BucketName" {
  type        = string
  description = "Bucket created by bootstrap to hold all Terraform state"
}

variable "tf_var_management_BucketAccess" {
  type    = string
  default = "NoPublicAccess"
}

variable "tf_var_management_BucketNS" {
  type    = string
  description = "Bucket Namespace"
}

variable "tf_var_management_BucketAuth" {
  type        = string
  description = "Bucket Auth"
}

variable "tf_var_management_TFStateFile" {
  type        = string
  description = "Terraform state file name"
}
