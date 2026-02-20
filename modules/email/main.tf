# Email Delivery Module

# Email Domain
resource "oci_email_email_domain" "email_domain" {
  compartment_id = var.compartment_ocid
  name           = var.email_domain_name
  freeform_tags  = var.tags
}

# Approved Sender
resource "oci_email_sender" "approved_sender" {
  compartment_id  = var.compartment_ocid
  email_address   = var.sender_email_address
  email_domain_id = oci_email_email_domain.email_domain.id
  freeform_tags   = var.tags
}

# SMTP Credential for the specified OCI user
resource "oci_identity_smtp_credential" "smtp_credential" {
  user_id     = var.smtp_user_ocid
  description = "SMTP credential for ${var.app_name} Email Delivery"
}

# IAM Policy for Email Delivery
resource "oci_identity_policy" "email_policy" {
  compartment_id = var.compartment_ocid
  name           = "${var.app_name}-${var.environment}-email-delivery-policy"
  description    = "Policy to allow managing email delivery for ${var.app_name}"
  statements = [
    "Allow group ${var.email_admins_group} to manage email-family in compartment id ${var.compartment_ocid}",
  ]
  freeform_tags = var.tags
}
