output "private_ip" {
  description = "Private IP of the Redis instance"
  value       = oci_core_instance.redis.private_ip
}

output "instance_id" {
  description = "OCID of the Redis instance"
  value       = oci_core_instance.redis.id
}
