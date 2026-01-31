# OCI Provider Variables
variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

# Network Variables
variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR block for the database subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# Compute Variables
variable "instance_shape" {
  description = "Shape of the compute instance"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the instance"
  type        = number
  default     = 1
}

variable "instance_memory_in_gbs" {
  description = "Amount of memory in GBs for the instance"
  type        = number
  default     = 8
}

variable "instance_count" {
  description = "Number of compute instances to create"
  type        = number
  default     = 2
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "instance_image_ocid" {
  description = "OCID of the instance image (OS)"
  type        = string
  # Oracle Linux 8
  default = ""
}

# Database Variables
variable "adb_display_name" {
  description = "Display name for the Autonomous Database"
  type        = string
  default     = "anonymouswall-adb"
}

variable "adb_db_name" {
  description = "Database name for the Autonomous Database"
  type        = string
  default     = "ANONWALLDB"
}

variable "adb_cpu_core_count" {
  description = "Number of CPU cores for the ADB"
  type        = number
  default     = 1
}

variable "adb_data_storage_size_in_tbs" {
  description = "Data storage size in TBs for the ADB"
  type        = number
  default     = 1
}

variable "adb_admin_password" {
  description = "Admin password for the Autonomous Database"
  type        = string
  sensitive   = true
}

variable "adb_db_version" {
  description = "Database version for the ADB"
  type        = string
  default     = "19c"
}

variable "adb_db_workload" {
  description = "Workload type for the ADB (OLTP or DW)"
  type        = string
  default     = "OLTP"
}

variable "adb_license_model" {
  description = "License model for the ADB"
  type        = string
  default     = "LICENSE_INCLUDED"
}

# Load Balancer Variables
variable "lb_shape" {
  description = "Shape of the load balancer"
  type        = string
  default     = "flexible"
}

variable "lb_min_bandwidth_mbps" {
  description = "Minimum bandwidth in Mbps for flexible load balancer"
  type        = number
  default     = 10
}

variable "lb_max_bandwidth_mbps" {
  description = "Maximum bandwidth in Mbps for flexible load balancer"
  type        = number
  default     = 100
}

# DNS Variables
variable "dns_zone_name" {
  description = "DNS zone name"
  type        = string
  default     = ""
}

variable "dns_record_domain" {
  description = "DNS record domain"
  type        = string
  default     = ""
}

# General Variables
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "anonymouswall"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "availability_domain" {
  description = "Availability domain for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Application = "AnonymousWall"
    ManagedBy   = "Terraform"
  }
}
