variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the bastion host"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet (public subnet)"
  type        = string
}

variable "bastion_shape" {
  description = "Shape of the bastion instance"
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "bastion_ocpus" {
  description = "Number of OCPUs for the bastion instance"
  type        = number
  default     = 1
}

variable "bastion_memory_in_gbs" {
  description = "Amount of memory in GBs for the bastion instance"
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "SSH public key for bastion access"
  type        = string
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

variable "private_subnet_cidr" {
  description = "CIDR of the private subnet where backend instances live"
  type        = string
}
