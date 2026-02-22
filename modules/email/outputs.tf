output "email_domain_id" {
  description = "OCID of the email domain"
  value       = oci_email_email_domain.email_domain.id
}

output "approved_sender_email" {
  description = "Email address of the approved sender"
  value       = oci_email_sender.approved_sender.email_address
}

output "smtp_username" {
  description = "SMTP username for Email Delivery authentication"
  value       = oci_identity_smtp_credential.smtp_credential.username
}

output "smtp_password" {
  description = "SMTP password for Email Delivery authentication (sensitive)"
  value       = oci_identity_smtp_credential.smtp_credential.password
  sensitive   = true
}

output "email_policy_id" {
  description = "OCID of the email delivery IAM policy"
  value       = oci_identity_policy.email_policy.id
}
