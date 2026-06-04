variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR range for subnet"
  type        = string
  default     = "10.128.0.0/20"
}

variable "use_existing_network" {
  description = "Whether to use an existing network instead of creating one"
  type        = bool
  default     = false
}

variable "existing_network_name" {
  description = "Name of the existing network to use"
  type        = string
  default     = ""
}

variable "existing_subnet_name" {
  description = "Name of the existing subnet to use"
  type        = string
  default     = ""
}
