variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "email_domain_name" {
  description = "The email domain name for OCI Email Delivery (e.g. mail.example.com)"
  type        = string
}

variable "sender_email_address" {
  description = "The approved sender email address"
  type        = string
}

variable "smtp_user_ocid" {
  description = "The OCID of the IAM user for whom the SMTP credential is created"
  type        = string
}

variable "email_admin_group_name" {
  description = "Name of the IAM group that will be granted manage access to email-family resources"
  type        = string
  default     = "EmailAdmins"
}

variable "dkim_selector" {
  description = "DKIM selector name (used as the DNS CNAME subdomain prefix, e.g. 'mail' produces 'mail._domainkey.<domain>')"
  type        = string
  default     = "mail"
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
