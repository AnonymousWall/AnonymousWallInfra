# Network Outputs
output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.network.vcn_id
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = module.network.private_subnet_id
}

output "db_subnet_id" {
  description = "OCID of the database subnet"
  value       = module.network.db_subnet_id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway (whitelisted for database access)"
  value       = module.network.nat_gateway_public_ip
}

# Compute Outputs
output "instance_ids" {
  description = "OCIDs of the compute instances"
  value       = module.compute.instance_ids
}

output "instance_private_ips" {
  description = "Private IP addresses of the compute instances"
  value       = module.compute.instance_private_ips
}

output "instance_public_ips" {
  description = "Public IP addresses of the compute instances"
  value       = module.compute.instance_public_ips
}

# Bastion Outputs
output "bastion_id" {
  description = "OCID of the bastion host"
  value       = module.bastion.bastion_id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.bastion_public_ip
}

# Database Outputs
output "adb_id" {
  description = "OCID of the Autonomous Database"
  value       = module.database.adb_id
}

output "adb_connection_strings" {
  description = "Connection strings for the Autonomous Database"
  value       = module.database.adb_connection_strings
  sensitive   = true
}

output "adb_service_console_url" {
  description = "Service console URL for the Autonomous Database"
  value       = module.database.adb_service_console_url
}

output "adb_wallet_content" {
  description = "Wallet content for the Autonomous Database"
  value       = module.database.adb_wallet_content
  sensitive   = true
}

# Load Balancer Outputs
output "load_balancer_id" {
  description = "OCID of the load balancer"
  value       = module.load_balancer.lb_id
}

output "load_balancer_ip" {
  description = "Public IP address of the load balancer"
  value       = module.load_balancer.lb_ip_address
}

# DNS Outputs
output "dns_zone_id" {
  description = "OCID of the DNS zone"
  value       = var.dns_zone_name != "" ? module.dns[0].zone_id : null
}

output "dns_nameservers" {
  description = "Nameservers for the DNS zone"
  value       = var.dns_zone_name != "" ? module.dns[0].nameservers : null
}

# Application URL
output "application_url" {
  description = "Application URL"
  value       = var.dns_zone_name != "" ? "https://${var.dns_record_domain != "" ? var.dns_record_domain : var.dns_zone_name}" : "http://${module.load_balancer.lb_ip_address}"
}

# Email Delivery Outputs
output "email_domain_id" {
  description = "OCID of the email domain"
  value       = var.email_domain_name != "" ? module.email[0].email_domain_id : null
}

output "approved_sender_email" {
  description = "Email address of the approved sender"
  value       = var.email_domain_name != "" ? module.email[0].approved_sender_email : null
}

output "smtp_username" {
  description = "SMTP username for the generated SMTP credential"
  value       = var.email_domain_name != "" ? module.email[0].smtp_username : null
}

output "smtp_password" {
  description = "SMTP password for the generated SMTP credential"
  value       = var.email_domain_name != "" ? module.email[0].smtp_password : null
  sensitive   = true
}

# SSH Access Instructions
output "ssh_access_instructions" {
  description = "Instructions for SSH access to backend instances"
  value       = <<-EOT
    To SSH into backend instances via the bastion host:
    
    Method 1: SSH with agent forwarding (recommended for manual use)
       ssh -A -i <your-private-key> opc@${module.bastion.bastion_public_ip}
       # Then from bastion: ssh opc@<backend-private-ip>
    
    Method 2: SSH ProxyJump (one command, best for automation)
       ssh -i <your-private-key> -J opc@${module.bastion.bastion_public_ip} opc@<backend-private-ip>
    
    Backend instance private IPs:
    ${join("\n    ", module.compute.instance_private_ips)}
  EOT
}
