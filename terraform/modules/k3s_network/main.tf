resource "google_compute_network" "k3s_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k3s_subnet" {
  name          = var.subnet_name
  network       = google_compute_network.k3s_network.id
  ip_cidr_range = var.subnet_cidr
}
