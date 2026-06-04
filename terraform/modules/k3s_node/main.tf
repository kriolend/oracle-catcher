# Shared module for K3s nodes (reduces duplication across vyacheslav, kriolend, u8197250572)

resource "google_compute_network" "k3s_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k3s_subnet" {
  name          = var.subnet_name
  network       = google_compute_network.k3s_network.id
  ip_cidr_range = var.subnet_cidr
}

resource "google_compute_firewall" "k3s_firewall" {
  name    = var.firewall_name
  network = google_compute_network.k3s_network.name

  allow {
    protocol = "tcp"
    # K3s API, kubelet, NodePorts
    ports    = ["22", "6443", "10250", "30080", "30443"]
  }

  allow {
    protocol = "udp"
    # Flannel Wireguard (для связи нод из разных проектов/сетей GCP)
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
    }
  }

  network_interface {
    network            = google_compute_network.k3s_network.name
    subnetwork         = google_compute_subnetwork.k3s_subnet.name
    network_ip         = var.static_ip
    
    access_config {
      # Автоматически назначить внешний IP
    }
  }

  labels = {
    cluster = "k3s"
    role    = var.node_role
  }

  tags = ["k3s-cluster"]
}
