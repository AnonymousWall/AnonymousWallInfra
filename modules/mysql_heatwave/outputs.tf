output "mysql_id" {
  description = "OCID of the MySQL database system"
  value       = oci_mysql_mysql_db_system.main.id
}

output "mysql_endpoint" {
  description = "MySQL database endpoint (hostname)"
  value       = oci_mysql_mysql_db_system.main.endpoints[0].hostname
}

output "mysql_ip_address" {
  description = "MySQL database IP address"
  value       = oci_mysql_mysql_db_system.main.endpoints[0].ip_address
}

output "mysql_port" {
  description = "MySQL database port"
  value       = oci_mysql_mysql_db_system.main.endpoints[0].port
}

output "mysql_connection_string" {
  description = "MySQL JDBC connection string"
  value       = "jdbc:mysql://${oci_mysql_mysql_db_system.main.endpoints[0].hostname}:${oci_mysql_mysql_db_system.main.endpoints[0].port}/anonymous_wall"
  sensitive   = true
}

output "mysql_admin_username" {
  description = "MySQL admin username"
  value       = var.admin_username
  sensitive   = true
}
