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

output "dkim_id" {
  description = "OCID of the DKIM signing key"
  value       = oci_email_dkim.dkim.id
}

output "dkim_dns_subdomain_name" {
  description = "DNS CNAME name to add to your DNS provider to verify DKIM (e.g. mail._domainkey.example.com)"
  value       = oci_email_dkim.dkim.dns_subdomain_name
}

output "dkim_dns_subdomain_value" {
  description = "DNS CNAME value to add to your DNS provider to verify DKIM"
  value       = oci_email_dkim.dkim.cname_record_value
}
