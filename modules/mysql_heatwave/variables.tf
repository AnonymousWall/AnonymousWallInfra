variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the MySQL database"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet for MySQL database"
  type        = string
}

variable "admin_username" {
  description = "Admin username for MySQL database"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Admin password for MySQL database"
  type        = string
  sensitive   = true
}

variable "mysql_shape" {
  description = "Shape of the MySQL database system"
  type        = string
  default     = "MySQL.VM.Standard.E3.1.8GB"
}

variable "data_storage_size_in_gb" {
  description = "Data storage size in GB for MySQL database"
  type        = number
  default     = 50
}

variable "mysql_private_ip" {
  description = "Private IP address for MySQL database (within subnet CIDR)"
  type        = string
  default     = ""
}

variable "mysql_port" {
  description = "MySQL database port"
  type        = number
  default     = 3306
}

variable "mysql_port_x" {
  description = "MySQL X Protocol port"
  type        = number
  default     = 33060
}

variable "backup_enabled" {
  description = "Enable automatic backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window_start_time" {
  description = "Backup window start time (HH:MM)"
  type        = string
  default     = "02:00"
}

variable "maintenance_window_start_time" {
  description = "Maintenance window start time (day HH:MM)"
  type        = string
  default     = "sun 02:00"
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
