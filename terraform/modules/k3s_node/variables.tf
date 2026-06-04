variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name of the VPC network (only used when use_existing_network=false)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Name of the subnet (only used when use_existing_network=false)"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR range for subnet (only used when use_existing_network=false)"
  type        = string
  default     = "10.128.0.0/20"
}

variable "firewall_name" {
  description = "Name of firewall rule (only used when use_existing_network=false)"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Name of the compute instance"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-micro"
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "static_ip" {
  description = "Static internal IP address (optional)"
  type        = string
  default     = ""
}

variable "node_role" {
  description = "Role of the node (master or worker)"
  type        = string
  validation {
    condition     = contains(["master", "worker", "oracle-catcher"], var.node_role)
    error_message = "node_role must be either 'master' or 'worker'."
  }
}

variable "use_existing_network" {
  description = "Use existing VPC network instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_network_name" {
  description = "Name of existing VPC network (required when use_existing_network = true)"
  type        = string
  default     = ""
}

variable "existing_subnet_name" {
  description = "Name of existing subnet (required when use_existing_network = true)"
  type        = string
  default     = ""
}
