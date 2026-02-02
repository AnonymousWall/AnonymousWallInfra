output "bastion_id" {
  description = "OCID of the bastion instance"
  value       = oci_core_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = oci_core_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = oci_core_instance.bastion.private_ip
}
