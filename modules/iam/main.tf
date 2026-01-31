# IAM Policies Module

# Dynamic Group for Compute Instances
resource "oci_identity_dynamic_group" "compute_instances" {
  compartment_id = var.compartment_ocid
  description    = "Dynamic group for ${var.app_name} compute instances"
  matching_rule  = "All {instance.compartment.id = '${var.compartment_ocid}'}"
  name           = "${var.app_name}-${var.environment}-compute-dg"
  freeform_tags  = var.tags
}

# Policy for Compute Instances to access Object Storage
resource "oci_identity_policy" "compute_object_storage" {
  compartment_id = var.compartment_ocid
  description    = "Policy for ${var.app_name} compute instances to access Object Storage"
  name           = "${var.app_name}-${var.environment}-compute-os-policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to read buckets in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to manage objects in compartment id ${var.compartment_ocid}",
  ]
  freeform_tags = var.tags
}

# Policy for Compute Instances to access Autonomous Database
resource "oci_identity_policy" "compute_database" {
  compartment_id = var.compartment_ocid
  description    = "Policy for ${var.app_name} compute instances to access ADB"
  name           = "${var.app_name}-${var.environment}-compute-db-policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to read autonomous-databases in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to use autonomous-databases in compartment id ${var.compartment_ocid}",
  ]
  freeform_tags = var.tags
}

# Policy for Load Balancer
resource "oci_identity_policy" "load_balancer" {
  compartment_id = var.compartment_ocid
  description    = "Policy for ${var.app_name} load balancer"
  name           = "${var.app_name}-${var.environment}-lb-policy"
  statements = [
    "Allow service loadbalancer to manage vnics in compartment id ${var.compartment_ocid}",
    "Allow service loadbalancer to use subnets in compartment id ${var.compartment_ocid}",
    "Allow service loadbalancer to use network-security-groups in compartment id ${var.compartment_ocid}",
  ]
  freeform_tags = var.tags
}

# Policy for Monitoring and Logging
resource "oci_identity_policy" "monitoring" {
  compartment_id = var.compartment_ocid
  description    = "Policy for ${var.app_name} monitoring and logging"
  name           = "${var.app_name}-${var.environment}-monitoring-policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to use metrics in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to use log-content in compartment id ${var.compartment_ocid}",
  ]
  freeform_tags = var.tags
}

# Policy for Secrets Management (for storing database credentials, API keys, etc.)
resource "oci_identity_policy" "secrets" {
  compartment_id = var.compartment_ocid
  description    = "Policy for ${var.app_name} secrets management"
  name           = "${var.app_name}-${var.environment}-secrets-policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to read secret-bundles in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.compute_instances.name} to read secrets in compartment id ${var.compartment_ocid}",
  ]
  freeform_tags = var.tags
}
