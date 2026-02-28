variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the Redis instance"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet for the Redis instance"
  type        = string
}

variable "instance_shape" {
  description = "Shape of the Redis compute instance"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the Redis instance"
  type        = number
  default     = 1
}

variable "instance_memory_in_gbs" {
  description = "Amount of memory in GBs for the Redis instance"
  type        = number
  default     = 6
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
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

variable "private_subnet_cidr" {
  description = "CIDR of private subnet — used in firewall rule to restrict Redis access"
  type        = string
}

variable "redis_password" {
  description = "Password for Redis AUTH"
  type        = string
  sensitive   = true
}
