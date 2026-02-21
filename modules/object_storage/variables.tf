variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "region" {
  description = "The OCI region"
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
