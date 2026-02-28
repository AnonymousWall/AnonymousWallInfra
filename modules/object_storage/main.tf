# Object Storage Module for React Admin Frontend Static Hosting

# Get Object Storage Namespace
data "oci_objectstorage_namespace" "main" {
  compartment_id = var.compartment_ocid
}

# Object Storage Bucket for Admin Frontend Static Hosting
resource "oci_objectstorage_bucket" "admin_frontend" {
  compartment_id = var.compartment_ocid
  name           = "${var.app_name}-${var.environment}-admin-frontend"
  namespace      = data.oci_objectstorage_namespace.main.namespace

  # Allow public read access so the React app assets can be served.
  # WARNING: All objects uploaded to this bucket will be publicly accessible.
  # Do NOT upload sensitive files, API keys, or environment config to this bucket.
  access_type = "ObjectRead"

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-admin-frontend"
  })
}

# Object Storage Bucket for Official Website Static Hosting
resource "oci_objectstorage_bucket" "official_web" {
  compartment_id = var.compartment_ocid
  name           = "${var.app_name}-${var.environment}-official-web"
  namespace      = data.oci_objectstorage_namespace.main.namespace

  # Allow public read access so the official website assets can be served.
  # WARNING: All objects uploaded to this bucket will be publicly accessible.
  # Do NOT upload sensitive files, API keys, or environment config to this bucket.
  access_type = "ObjectRead"

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-official-web"
  })
}

# Object Storage Bucket for Media (images, etc.)
resource "oci_objectstorage_bucket" "media" {
  compartment_id = var.compartment_ocid
  name           = "${var.app_name}-${var.environment}-media"
  namespace      = data.oci_objectstorage_namespace.main.namespace

  # Allow public read access so media files (e.g. images) load directly in the app.
  # WARNING: All objects uploaded to this bucket will be publicly accessible.
  # Do NOT upload sensitive files, API keys, or environment config to this bucket.
  access_type = "ObjectRead"

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-media"
  })
}
