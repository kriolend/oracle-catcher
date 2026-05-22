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
    ports    = ["22", "6443"] # 22 для SSH (чтобы зайти на сервер), 6443 для K3s API (управление кубернетесом)
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
