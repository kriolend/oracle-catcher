terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file("../../.secrets/kriolend-key.json")
  project     = var.gcp_project_id
  region      = var.gcp_region
  zone        = var.gcp_zone
}
