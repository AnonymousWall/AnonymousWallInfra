# Autonomous Database Module

resource "oci_database_autonomous_database" "main" {
  compartment_id              = var.compartment_ocid
  db_name                     = var.adb_db_name
  display_name                = var.adb_display_name
  admin_password              = var.adb_admin_password
  cpu_core_count              = var.adb_cpu_core_count
  data_storage_size_in_tbs    = var.adb_data_storage_size_in_tbs
  db_version                  = var.adb_db_version
  db_workload                 = var.adb_db_workload
  license_model               = var.adb_license_model
  is_auto_scaling_enabled     = true
  is_free_tier                = false
  subnet_id                   = var.subnet_id
  nsg_ids                     = []
  is_mtls_connection_required = false
  
  freeform_tags = merge(var.tags, {
    Name = var.adb_display_name
  })
}

# Autonomous Database Wallet (optional - for secure connections)
resource "oci_database_autonomous_database_wallet" "main" {
  autonomous_database_id = oci_database_autonomous_database.main.id
  password               = var.adb_admin_password
  base64_encode_content  = true
}
