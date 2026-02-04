variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "mysql_display_name" {
  description = "Display name for the MySQL Database System"
  type        = string
}

variable "mysql_admin_username" {
  description = "Admin username for the MySQL Database System"
  type        = string
  default     = "admin"
}

variable "mysql_admin_password" {
  description = "Admin password for the MySQL Database System"
  type        = string
  sensitive   = true
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
}

variable "mysql_shape_name" {
  description = "Shape name for the MySQL Database System"
  type        = string
}

variable "mysql_data_storage_size_in_gb" {
  description = "Data storage size in GB for the MySQL Database System"
  type        = number
}

variable "subnet_id" {
  description = "OCID of the subnet for the MySQL database"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the MySQL Database System"
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
