module "k3s_network" {
  source   = "../modules/k3s_network"

  use_existing_network    = true
  existing_network_name   = "k3s-network"
  existing_subnet_name    = "k3s-subnet"
}

module "k3s_node" {
  source = "../modules/k3s_node"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  use_existing_network  = true
  existing_network_name = module.k3s_network.network_name
  existing_subnet_name  = module.k3s_network.subnet_name

  instance_name = "k3s-vyacheslav"
  node_role     = "oracle-catcher"
}
