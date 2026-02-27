variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet OCIDs for the load balancer"
  type        = list(string)
}

variable "backend_instance_ids" {
  description = "List of backend instance OCIDs"
  type        = list(string)
}

variable "lb_shape" {
  description = "Shape of the load balancer"
  type        = string
}

variable "lb_min_bandwidth_mbps" {
  description = "Minimum bandwidth in Mbps for flexible load balancer"
  type        = number
}

variable "lb_max_bandwidth_mbps" {
  description = "Maximum bandwidth in Mbps for flexible load balancer"
  type        = number
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

variable "backend_private_ips" {
  description = "Primary VNIC private IPs of backend instances"
  type        = list(string)
}
