variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet for the database"
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

variable "adb_cpu_core_count" {
  description = "Number of CPU cores for the ADB"
  type        = number
}

variable "adb_data_storage_size_in_tbs" {
  description = "Data storage size in TBs for the ADB"
  type        = number
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

variable "adb_license_model" {
  description = "License model for the ADB"
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
