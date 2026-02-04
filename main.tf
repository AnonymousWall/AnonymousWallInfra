# Main Terraform configuration for AnonymousWall OCI Infrastructure

# Networking Module
module "network" {
  source = "./modules/network"

  compartment_ocid    = var.compartment_ocid
  vcn_cidr_block      = var.vcn_cidr_block
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  db_subnet_cidr      = var.db_subnet_cidr
  ssh_allowed_cidrs   = var.ssh_allowed_cidrs
  app_name            = var.app_name
  environment         = var.environment
  tags                = var.tags
}

# IAM Policies Module
module "iam" {
  source = "./modules/iam"

  compartment_ocid = var.compartment_ocid
  app_name         = var.app_name
  environment      = var.environment
  tags             = var.tags
}

# Compute Instances Module
module "compute" {
  source = "./modules/compute"

  compartment_ocid       = var.compartment_ocid
  availability_domain    = var.availability_domain
  subnet_id              = module.network.private_subnet_id
  instance_shape         = var.instance_shape
  instance_ocpus         = var.instance_ocpus
  instance_memory_in_gbs = var.instance_memory_in_gbs
  instance_count         = var.instance_count
  ssh_public_key         = var.ssh_public_key
  instance_image_ocid    = var.instance_image_ocid
  app_name               = var.app_name
  environment            = var.environment
  tags                   = var.tags
}

# MySQL Database Module
module "database" {
  source = "./modules/database"

  compartment_ocid              = var.compartment_ocid
  availability_domain           = var.availability_domain
  subnet_id                     = module.network.db_subnet_id
  mysql_display_name            = var.mysql_display_name
  mysql_admin_username          = var.mysql_admin_username
  mysql_admin_password          = var.mysql_admin_password
  mysql_version                 = var.mysql_version
  mysql_shape_name              = var.mysql_shape_name
  mysql_data_storage_size_in_gb = var.mysql_data_storage_size_in_gb
  app_name                      = var.app_name
  environment                   = var.environment
  tags                          = var.tags
}

# Bastion Module
module "bastion" {
  source = "./modules/bastion"

  compartment_ocid      = var.compartment_ocid
  availability_domain   = var.availability_domain
  subnet_id             = module.network.public_subnet_id
  bastion_shape         = var.bastion_shape
  bastion_ocpus         = var.bastion_ocpus
  bastion_memory_in_gbs = var.bastion_memory_in_gbs
  ssh_public_key        = var.ssh_public_key
  app_name              = var.app_name
  environment           = var.environment
  tags                  = var.tags
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load_balancer"

  compartment_ocid      = var.compartment_ocid
  subnet_ids            = [module.network.public_subnet_id]
  backend_instance_ids  = module.compute.instance_ids
  lb_shape              = var.lb_shape
  lb_min_bandwidth_mbps = var.lb_min_bandwidth_mbps
  lb_max_bandwidth_mbps = var.lb_max_bandwidth_mbps
  app_name              = var.app_name
  environment           = var.environment
  tags                  = var.tags
}

# DNS Module (optional, only if dns_zone_name is provided)
module "dns" {
  source = "./modules/dns"
  count  = var.dns_zone_name != "" ? 1 : 0

  compartment_ocid = var.compartment_ocid
  zone_name        = var.dns_zone_name
  record_domain    = var.dns_record_domain != "" ? var.dns_record_domain : var.dns_zone_name
  lb_ip_address    = module.load_balancer.lb_ip_address
  app_name         = var.app_name
  environment      = var.environment
  tags             = var.tags
}
