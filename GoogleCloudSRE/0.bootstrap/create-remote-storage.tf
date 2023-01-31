#
# Core management resources
#

resource "google_storage_bucket" "tfstate" {
  name          = "${tf_var_management_BucketName}"
  force_destroy = false
  location      = "${tf_var_management_Location}"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}