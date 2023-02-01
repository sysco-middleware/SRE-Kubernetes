# Outputs
output "bucket_name" {
  value = oci_objectstorage_bucket.tfstate.name
}

output "bucket_id" {
  value = oci_objectstorage_bucket.tfstate.bucket_id
}