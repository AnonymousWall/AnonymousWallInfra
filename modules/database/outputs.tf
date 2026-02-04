output "mysql_id" {
  description = "OCID of the MySQL Database System"
  value       = oci_mysql_mysql_db_system.main.id
}

output "mysql_hostname" {
  description = "Hostname for the MySQL Database System"
  value       = oci_mysql_mysql_db_system.main.endpoints[0].hostname
}

output "mysql_port" {
  description = "Port for the MySQL Database System"
  value       = oci_mysql_mysql_db_system.main.endpoints[0].port
}

output "mysql_ip_address" {
  description = "IP address for the MySQL Database System"
  value       = oci_mysql_mysql_db_system.main.endpoints[0].ip_address
}
