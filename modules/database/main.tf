# Autonomous Database Module

resource "oci_database_autonomous_database" "main" {
  compartment_id              = var.compartment_ocid
  db_name                     = var.adb_db_name
  display_name                = var.adb_display_name
  admin_password              = var.adb_admin_password
  db_version                  = var.adb_db_version
  db_workload                 = var.adb_db_workload
  is_free_tier                = true
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
