output "dynamic_group_id" {
  description = "OCID of the dynamic group for compute instances"
  value       = oci_identity_dynamic_group.compute_instances.id
}

output "policy_ids" {
  description = "OCIDs of the IAM policies"
  value = {
    object_storage = oci_identity_policy.compute_object_storage.id
    database       = oci_identity_policy.compute_database.id
    load_balancer  = oci_identity_policy.load_balancer.id
    monitoring     = oci_identity_policy.monitoring.id
    secrets        = oci_identity_policy.secrets.id
  }
}
