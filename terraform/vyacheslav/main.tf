# Используем модуль k3s_node для создания VPC, firewall и instance
# Это избегает дублирования кода между vyacheslav, kriolend, u8197250572 проектами
module "k3s_master" {
  source = "../modules/k3s_node"
  
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone
  
  network_name   = "k3s-network"
  subnet_name    = "k3s-subnet"
  firewall_name  = "k3s-firewall"
  instance_name  = "k3s-vyacheslav"
  node_role      = "master"
}
