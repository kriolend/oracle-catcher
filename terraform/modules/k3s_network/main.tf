resource "google_compute_network" "k3s_network" {
  count                   = var.use_existing_network ? 0 : 1
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k3s_subnet" {
  count         = var.use_existing_network ? 0 : 1
  name          = var.subnet_name
  network       = var.use_existing_network ? var.existing_network_name : google_compute_network.k3s_network[0].id
  ip_cidr_range = var.subnet_cidr
}
