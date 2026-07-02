# Each GCP project has its own isolated VPC — cross-project networks are impossible
module "k3s_worker" {
  source = "../modules/k3s_node"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  use_existing_network = false       # Создаём СВОЮ VPC (другой аккаунт = другой проект)
  network_name         = "k3s-network"
  subnet_name          = "k3s-subnet"
  subnet_cidr          = "10.128.0.0/20"
  firewall_name        = "k3s-firewall"

  instance_name = "k3s-kriolend"
  node_role     = "worker"
}
