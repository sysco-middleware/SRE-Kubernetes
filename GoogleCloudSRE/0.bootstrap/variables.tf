variable "tf_var_management_ProjectID" {
  type        = string
  description = "ProjectID for shared resources"
}

variable "tf_var_management_Location" {
  type        = string
  description = "Location used for all resources"
  default = "europe-north1"
}

variable "tf_var_management_BucketName" {
  type        = string
  description = "Bucket to store Terraform state"
}

variable "tf_var_resource_prefix" {
  type        = string
  description = "Prefix for resources created"
}

