variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "adb_display_name" {
  description = "Display name for the Autonomous Database"
  type        = string
}

variable "adb_db_name" {
  description = "Database name for the Autonomous Database"
  type        = string
}

variable "adb_admin_password" {
  description = "Admin password for the Autonomous Database"
  type        = string
  sensitive   = true
}

variable "adb_db_version" {
  description = "Database version for the ADB"
  type        = string
}

variable "adb_db_workload" {
  description = "Workload type for the ADB (OLTP or DW)"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

# Optional variables - not used in Always Free tier but kept for backward compatibility
variable "subnet_id" {
  description = "OCID of the subnet for the database (not used in Always Free tier)"
  type        = string
  default     = ""
}

variable "adb_cpu_core_count" {
  description = "Number of CPU cores for the ADB (not used in Always Free tier)"
  type        = number
  default     = 1
}

variable "adb_data_storage_size_in_tbs" {
  description = "Data storage size in TBs for the ADB (not used in Always Free tier)"
  type        = number
  default     = 1
}

variable "adb_license_model" {
  description = "License model for the ADB (not used in Always Free tier)"
  type        = string
  default     = "LICENSE_INCLUDED"
}

variable "whitelisted_ips" {
  description = "List of whitelisted IPs/CIDR blocks for ADB access (required for Always Free tier)"
  type        = list(string)
  default     = []
}
