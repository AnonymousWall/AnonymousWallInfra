output "instance_ids" {
  description = "OCIDs of the compute instances"
  value       = oci_core_instance.backend[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of the compute instances"
  value       = oci_core_instance.backend[*].private_ip
}

output "instance_public_ips" {
  description = "Public IP addresses of the compute instances"
  value       = oci_core_instance.backend[*].public_ip
}

output "primary_vnic_ids" {
  description = "OCIDs of the primary VNICs"
  value       = data.oci_core_vnic_attachments.backend[*].vnic_attachments[0].vnic_id
}

output "secondary_vnic_ids" {
  description = "OCIDs of the secondary VNICs"
  value       = oci_core_vnic_attachment.secondary[*].vnic_id
}
