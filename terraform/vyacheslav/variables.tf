variable "gcp_project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy to"
  type        = string
  default     = "us-central1" # Важно: бесплатный e2-micro доступен в us-central1
}

variable "gcp_zone" {
  description = "The GCP zone to deploy to"
  type        = string
  default     = "us-central1-a"
}
