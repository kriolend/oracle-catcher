output "instance_id" {
  description = "Instance ID"
  value       = google_compute_instance.k3s_nodes[0].id
}

output "instance_name" {
  description = "Instance name"
  value       = google_compute_instance.k3s_nodes[0].name
}

output "public_ip" {
  description = "Public IP address"
  value       = google_compute_instance.k3s_nodes[0].network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.k3s_nodes[0].network_interface[0].network_ip
}

output "network_name" {
  description = "VPC Network name"
  value       = google_compute_network.k3s_network.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.k3s_subnet.name
}
