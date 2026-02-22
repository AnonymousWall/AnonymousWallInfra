# Email Delivery Module

# Email Domain
resource "oci_email_email_domain" "email_domain" {
  compartment_id = var.compartment_ocid
  name           = var.email_domain_name
  freeform_tags  = var.tags
}

# DKIM signing key for the email domain
# After apply, add the DNS CNAME record shown in dkim_dns_subdomain_name / dkim_dns_subdomain_value
# to your DNS provider to complete domain verification.
resource "oci_email_dkim" "dkim" {
  email_domain_id = oci_email_email_domain.email_domain.id
  name            = var.dkim_selector
  freeform_tags   = var.tags
}

# Approved Sender
# depends_on ensures the domain exists before the sender is registered
resource "oci_email_sender" "approved_sender" {
  compartment_id = var.compartment_ocid
  email_address  = var.sender_email_address
  freeform_tags  = var.tags

  depends_on = [oci_email_email_domain.email_domain]
}

# SMTP Credential for the specified IAM user
# NOTE: The generated password is only available at creation time.
# Store it securely (e.g. OCI Vault, GitHub Secrets) immediately after apply.
resource "oci_identity_smtp_credential" "smtp_credential" {
  user_id     = var.smtp_user_ocid
  description = "SMTP credential for ${var.app_name}-${var.environment} Email Delivery"
}

# IAM Policy — allows EmailAdmins group to manage email-family resources
resource "oci_identity_policy" "email_policy" {
  compartment_id = var.compartment_ocid
  name           = "${var.app_name}-${var.environment}-email-delivery-policy"
  description    = "Policy to allow managing OCI Email Delivery for ${var.app_name}"
  statements = [
    "Allow group ${var.email_admin_group_name} to manage email-family in compartment id ${var.compartment_ocid}",
  ]
  freeform_tags = var.tags
}
