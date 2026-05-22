output "node_ips" {
  description = "Публичные (белые) IP-адреса наших серверов"
  value = {
    # Проходимся циклом по всем созданным серверам и вытаскиваем их внешний IP
    for instance in google_compute_instance.k3s_nodes :
    instance.name => instance.network_interface[0].access_config[0].nat_ip
  }
}

output "node_internal_ips" {
  description = "Внутренние (серые) IP-адреса серверов"
  value = {
    for instance in google_compute_instance.k3s_nodes :
    instance.name => instance.network_interface[0].network_ip
  }
}
