# Bastion Module - Jump host for SSH access to private instances

# Get the latest Oracle Linux image
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "7"
  shape                    = var.bastion_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Bastion Host Instance
resource "oci_core_instance" "bastion" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.app_name}-${var.environment}-bastion"
  shape               = var.bastion_shape

  shape_config {
    ocpus         = var.bastion_ocpus
    memory_in_gbs = var.bastion_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "${var.app_name}-${var.environment}-bastion-vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "${var.app_name}-bastion"
    freeform_tags             = var.tags
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-bastion"
    Role = "Bastion"
  })

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}
