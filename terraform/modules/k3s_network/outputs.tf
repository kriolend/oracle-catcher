output "network_name" {
  description = "VPC Network name"
  value       = google_compute_network.k3s_network.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.k3s_subnet.name
}

output "network_self_link" {
  description = "Network self link"
  value       = google_compute_network.k3s_network.self_link
}
