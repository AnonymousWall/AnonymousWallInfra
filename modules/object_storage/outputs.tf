output "bucket_id" {
  description = "OCID of the Object Storage bucket for admin frontend"
  value       = oci_objectstorage_bucket.admin_frontend.id
}

output "bucket_name" {
  description = "Name of the Object Storage bucket for admin frontend"
  value       = oci_objectstorage_bucket.admin_frontend.name
}

output "namespace" {
  description = "Object Storage namespace"
  value       = data.oci_objectstorage_namespace.main.namespace
}

output "static_website_url" {
  description = "Base URL for the React admin frontend static website (entry point: index.html). Note: OCI Object Storage does not natively support SPA fallback routing; direct-link navigation to sub-routes will 404 unless an edge service (e.g. OCI CDN or API Gateway) rewrites the paths."
  value       = "https://objectstorage.${var.region}.oraclecloud.com/n/${data.oci_objectstorage_namespace.main.namespace}/b/${oci_objectstorage_bucket.admin_frontend.name}/o/index.html"
}

output "media_bucket_name" {
  description = "Name of the Object Storage bucket for media files"
  value       = oci_objectstorage_bucket.media.name
}

output "media_bucket_url" {
  description = "Base URL for the media bucket (publicly readable)"
  value       = "https://objectstorage.${var.region}.oraclecloud.com/n/${data.oci_objectstorage_namespace.main.namespace}/b/${oci_objectstorage_bucket.media.name}/o"
}
