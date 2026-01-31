output "lb_id" {
  description = "OCID of the load balancer"
  value       = oci_load_balancer_load_balancer.main.id
}

output "lb_ip_address" {
  description = "Public IP address of the load balancer"
  value       = oci_load_balancer_load_balancer.main.ip_address_details[0].ip_address
}

output "backend_set_name" {
  description = "Name of the backend set"
  value       = oci_load_balancer_backend_set.main.name
}
