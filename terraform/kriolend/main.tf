# 1. Виртуальная сеть для нашего кластера
resource "google_compute_network" "k3s_network" {
  name                    = "k3s-network"
  auto_create_subnetworks = true
}

# 2. Правила Firewall (Огненная стена)
resource "google_compute_firewall" "k3s_firewall" {
  name = "k3s-firewall"
  network = google_compute_network.k3s_network.name

  # Разрешаем входящий трафик
  allow {
    protocol = "tcp"
    # 22    — SSH
    # 6443  — K3s API (kubectl, ArgoCD агент)
    # 10250 — kubelet API (нужен для kubectl logs/exec; без него 502 Bad Gateway)
    # 30080 — ArgoCD UI HTTP (NodePort)
    # 30443 — ArgoCD UI HTTPS (NodePort)
    ports    = ["22", "6443", "10250", "30080", "30443"]
  }

  allow {
    protocol = "udp"
    # 51820, 51821 — Flannel Wireguard (для связи нод из разных проектов/сетей GCP)
    ports    = ["51820", "51821"]
  }

  # Разрешаем подключаться с любых IP адресов интернета
  source_ranges = ["0.0.0.0/0"]
}

# 3. Виртуальные машины (Ноды кластера)
resource "google_compute_instance" "k3s_nodes" {
  count        = 1 # Создаем сразу 2 сервера (один будет мастером, второй - воркером)
  name         = "k3s-kriolend" # Имя сервера
  machine_type = "e2-micro" # Тот самый бесплатный тип сервера
  
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  boot_disk {
    initialize_params {
      # Используем стабильную Ubuntu 22.04 LTS
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      # Бесплатный лимит в GCP — 30 ГБ диска на весь аккаунт. 
      # Мы создаем 2 сервера, поэтому даем каждому по 15 ГБ, чтобы не выйти за рамки бесплатного тарифа.
      size  = 30
    }
  }

  network_interface {
    # Подключаем серверы к сети, которую мы создали в блоке 1
    network = google_compute_network.k3s_network.name
    
    # Этот пустой блок означает: "Google, выдай этим серверам внешние белые IP-адреса"
    access_config {
    }
  }
}
