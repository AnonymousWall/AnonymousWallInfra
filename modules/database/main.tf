# MySQL Database System Module

resource "oci_mysql_mysql_db_system" "main" {
  compartment_id      = var.compartment_ocid
  display_name        = var.mysql_display_name
  admin_password      = var.mysql_admin_password
  admin_username      = var.mysql_admin_username
  availability_domain = var.availability_domain
  shape_name          = var.mysql_shape_name
  subnet_id           = var.subnet_id

  data_storage_size_in_gb = var.mysql_data_storage_size_in_gb
  mysql_version           = var.mysql_version

  freeform_tags = merge(var.tags, {
    Name = var.mysql_display_name
  })
}
