# Shared module for K3s nodes (reduces duplication across vyacheslav, kriolend, u8197250572)

locals {
  effective_network_name = var.use_existing_network ? var.existing_network_name : google_compute_network.k3s_network[0].name
  effective_subnet_name  = var.use_existing_network ? var.existing_subnet_name : google_compute_subnetwork.k3s_subnet[0].name
}

resource "google_compute_network" "k3s_network" {
  count                   = var.use_existing_network ? 0 : 1
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k3s_subnet" {
  count      = var.use_existing_network ? 0 : 1
  name       = var.subnet_name
  network    = google_compute_network.k3s_network[0].id
  ip_cidr_range = var.subnet_cidr
}

resource "google_compute_firewall" "k3s_firewall" {
  count   = var.use_existing_network ? 0 : 1
  name    = var.firewall_name
  network = google_compute_network.k3s_network[0].name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "10250", "30080", "30443"]
  }

  allow {
    protocol = "udp"
    ports    = ["51820", "51821"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "k3s_nodes" {
  count        = 1
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network            = local.effective_network_name
    subnetwork         = local.effective_subnet_name
    network_ip         = var.static_ip
    
    access_config {
      network_tier = "STANDARD"  # Явно STANDARD — иначе GCP берёт Premium (платный) по умолчанию
    }
  }

  labels = {
    cluster = "k3s"
    role    = var.node_role
  }

  tags = ["k3s-cluster"]
}
