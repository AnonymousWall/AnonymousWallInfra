variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "email_domain_name" {
  description = "The email domain name for OCI Email Delivery (e.g., mail.example.com)"
  type        = string
}

variable "sender_email_address" {
  description = "The approved sender email address (must belong to the email domain)"
  type        = string
}

variable "smtp_user_ocid" {
  description = "The OCID of the OCI user for whom the SMTP credential will be created"
  type        = string
}

variable "email_admins_group" {
  description = "Name of the OCI IAM group that will manage email delivery resources"
  type        = string
  default     = "EmailAdmins"
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
  default     = {}
}
