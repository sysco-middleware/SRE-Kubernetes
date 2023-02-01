terraform {
  backend "s3" {
    bucket   = "var.tf_var_management_BucketName"
    key      = "var.tf_var_management_TFStateFileName"
    region   = "var.tf_var_management_Region"
    endpoint = "https://acme.compat.objectstorage.us-phoenix-1.oraclecloud.com"
  }
}