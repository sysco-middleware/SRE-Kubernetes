terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

# provider "google" {
#   credentials = file("<NAME>.json")

#   project = "${tf_var_management_ProjectID}"
#   region  = "${tf_var_management_Location}"
# }
