output "resource_project_id" {
  value       = google_storage_bucket.tfstate.name
  description = "Boostrap Bucket"
}
