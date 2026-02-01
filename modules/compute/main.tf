# Compute Module - Backend Instances with VNICs

# Get the latest Oracle Linux image
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Compute Instances
resource "oci_core_instance" "backend" {
  count               = var.instance_count
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.app_name}-${var.environment}-backend-${count.index + 1}"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "${var.app_name}-${var.environment}-backend-vnic-${count.index + 1}"
    assign_public_ip          = false
    assign_private_dns_record = true
    hostname_label            = "${var.app_name}-backend-${count.index + 1}"
    freeform_tags             = var.tags
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid != "" ? var.instance_image_ocid : data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      app_name = var.app_name
    }))
  }

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-backend-${count.index + 1}"
  })

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

# Data source to get VNIC attachments for each instance
data "oci_core_vnic_attachments" "backend" {
  count          = var.instance_count
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.backend[count.index].id

  depends_on = [oci_core_instance.backend]
}

# Secondary VNICs (optional - for high-performance networking)
resource "oci_core_vnic_attachment" "secondary" {
  count        = var.instance_count
  instance_id  = oci_core_instance.backend[count.index].id
  display_name = "${var.app_name}-${var.environment}-backend-secondary-vnic-${count.index + 1}"

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "${var.app_name}-${var.environment}-backend-secondary-vnic-${count.index + 1}"
    assign_public_ip          = false
    assign_private_dns_record = true
    skip_source_dest_check    = false
    freeform_tags             = var.tags
  }
}
