output "network_name" {
  description = "VPC Network name"
  value       = var.use_existing_network ? var.existing_network_name : google_compute_network.k3s_network[0].name
}

output "subnet_name" {
  description = "Subnet name"
  value       = var.use_existing_network ? var.existing_subnet_name : google_compute_subnetwork.k3s_subnet[0].name
}

output "network_self_link" {
  description = "Network self link"
  value       = var.use_existing_network ? data.google_compute_network.existing[0].self_link : google_compute_network.k3s_network[0].self_link
}

data "google_compute_network" "existing" {
  count      = var.use_existing_network ? 1 : 0
  name       = var.existing_network_name
}
