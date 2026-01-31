output "adb_id" {
  description = "OCID of the Autonomous Database"
  value       = oci_database_autonomous_database.main.id
}

output "adb_connection_strings" {
  description = "Connection strings for the Autonomous Database"
  value       = oci_database_autonomous_database.main.connection_strings
  sensitive   = true
}

output "adb_service_console_url" {
  description = "Service console URL for the Autonomous Database"
  value       = oci_database_autonomous_database.main.service_console_url
}

output "adb_wallet_content" {
  description = "Wallet content for the Autonomous Database"
  value       = oci_database_autonomous_database_wallet.main.content
  sensitive   = true
}
