output "zone_id" {
  description = "OCID of the DNS zone"
  value       = oci_dns_zone.main.id
}

output "nameservers" {
  description = "Nameservers for the DNS zone"
  value       = oci_dns_zone.main.nameservers
}

output "zone_name" {
  description = "Name of the DNS zone"
  value       = oci_dns_zone.main.name
}

output "a_record_domain" {
  description = "Domain of the A record"
  value       = oci_dns_record.lb_a_record.domain
}
