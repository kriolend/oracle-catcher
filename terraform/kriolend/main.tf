# Using existing network
# Avoiding code duplication between projects
module "k3s_worker" {
  source = "../modules/k3s_node"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  use_existing_network  = true
  existing_network_name = "k3s-network"
  existing_subnet_name  = "k3s-subnet"
  instance_name         = "k3s-kriolend"
  node_role             = "worker"
}
