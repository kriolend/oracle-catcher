output "node_ips" {
  description = "Публичные (белые) IP-адреса наших серверов"
  value = {
    "k3s-vyacheslav" = module.k3s_node.public_ip
  }
}

output "node_internal_ips" {
  description = "Внутренние (серые) IP-адреса серверов"
  value = {
    "k3s-vyacheslav" = module.k3s_node.internal_ip
  }
}
