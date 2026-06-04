# Используем модуль k3s_node для создания VPC, firewall и instance
# Это избегает дублирования кода между vyacheslav, kriolend, u8197250572 проектами
module "k3s_worker_2" {
  source = "../modules/k3s_node"
  
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone
  
  network_name   = "k3s-network"
  subnet_name    = "k3s-subnet"
  firewall_name  = "k3s-firewall"
  instance_name  = "k3s-u8197250572"
  node_role      = "worker"
}
