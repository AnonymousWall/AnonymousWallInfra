variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for instances"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet for instances"
  type        = string
}

variable "instance_shape" {
  description = "Shape of the compute instance"
  type        = string
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the instance"
  type        = number
}

variable "instance_memory_in_gbs" {
  description = "Amount of memory in GBs for the instance"
  type        = number
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "instance_image_ocid" {
  description = "OCID of the instance image"
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
