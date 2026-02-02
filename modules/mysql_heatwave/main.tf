# MySQL HeatWave Database Module

# Get the latest MySQL HeatWave configuration for the specified shape
data "oci_mysql_mysql_configurations" "free_tier" {
  compartment_id = var.compartment_ocid
  shape_name     = var.mysql_shape
  type           = ["DEFAULT"]
}

# MySQL HeatWave Database System
resource "oci_mysql_mysql_db_system" "main" {
  compartment_id      = var.compartment_ocid
  shape_name          = var.mysql_shape
  subnet_id           = var.subnet_id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  availability_domain = var.availability_domain

  display_name = "${var.app_name}-${var.environment}-mysql"
  description  = "MySQL Database for ${var.app_name}"

  # Data storage
  data_storage_size_in_gb = var.data_storage_size_in_gb

  # Network configuration
  hostname_label = "${var.app_name}-mysql"
  ip_address     = var.mysql_private_ip

  # Configuration
  configuration_id = data.oci_mysql_mysql_configurations.free_tier.configurations[0].id

  # Port configuration (default 3306)
  port   = var.mysql_port
  port_x = var.mysql_port_x

  # Backup policy
  backup_policy {
    is_enabled        = var.backup_enabled
    retention_in_days = var.backup_retention_days
    window_start_time = var.backup_window_start_time
  }

  # Maintenance window
  maintenance {
    window_start_time = var.maintenance_window_start_time
  }

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-mysql"
  })

  lifecycle {
    ignore_changes = [
      # Ignore changes to these to prevent recreation
      mysql_version,
      configuration_id
    ]
  }
}
