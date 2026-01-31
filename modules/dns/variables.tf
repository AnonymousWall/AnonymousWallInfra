variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "zone_name" {
  description = "DNS zone name"
  type        = string
}

variable "record_domain" {
  description = "Domain for DNS records"
  type        = string
}

variable "lb_ip_address" {
  description = "IP address of the load balancer"
  type        = string
}

variable "verification_txt" {
  description = "TXT record value for domain verification"
  type        = string
  default     = ""
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
