# DNS Module

# DNS Zone
resource "oci_dns_zone" "main" {
  compartment_id = var.compartment_ocid
  name           = var.zone_name
  zone_type      = "PRIMARY"
  scope          = "GLOBAL"
  freeform_tags  = var.tags
}

# A Record for Load Balancer
resource "oci_dns_record" "lb_a_record" {
  zone_name_or_id = oci_dns_zone.main.id
  domain          = var.record_domain
  rtype           = "A"
  rdata           = var.lb_ip_address
  ttl             = 300
}

# CNAME Record for www subdomain
resource "oci_dns_record" "www_cname" {
  zone_name_or_id = oci_dns_zone.main.id
  domain          = "www.${var.record_domain}"
  rtype           = "CNAME"
  rdata           = var.record_domain
  ttl             = 300
}

# TXT Record for domain verification (optional)
resource "oci_dns_record" "verification" {
  count           = var.verification_txt != "" ? 1 : 0
  zone_name_or_id = oci_dns_zone.main.id
  domain          = var.record_domain
  rtype           = "TXT"
  rdata           = var.verification_txt
  ttl             = 300
}
