# Load Balancer Module

# Load Balancer
resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}-${var.environment}-lb"
  shape          = var.lb_shape

  dynamic "shape_details" {
    for_each = var.lb_shape == "flexible" ? [1] : []
    content {
      minimum_bandwidth_in_mbps = var.lb_min_bandwidth_mbps
      maximum_bandwidth_in_mbps = var.lb_max_bandwidth_mbps
    }
  }

  subnet_ids = var.subnet_ids

  is_private = false

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-lb"
  })
}

# Backend Set
resource "oci_load_balancer_backend_set" "main" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "${var.app_name}-${var.environment}-backend-set"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol            = "HTTP"
    port                = 8080
    url_path            = "/health"
    return_code         = 200
    interval_ms         = 10000
    timeout_in_millis   = 3000
    retries             = 3
  }

  session_persistence_configuration {
    cookie_name = "${var.app_name}_session"
  }
}

# Backends (one for each compute instance)
resource "oci_load_balancer_backend" "main" {
  count            = length(var.backend_instance_ids)
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  ip_address       = data.oci_core_vnic.backend[count.index].private_ip_address
  port             = 8080
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

# Get VNIC details for each backend instance
data "oci_core_vnic_attachments" "backend" {
  count               = length(var.backend_instance_ids)
  compartment_id      = var.compartment_ocid
  instance_id         = var.backend_instance_ids[count.index]
}

data "oci_core_vnic" "backend" {
  count   = length(var.backend_instance_ids)
  vnic_id = data.oci_core_vnic_attachments.backend[count.index].vnic_attachments[0].vnic_id
}

# Listener for HTTP
resource "oci_load_balancer_listener" "http" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "${var.app_name}-${var.environment}-http-listener"
  default_backend_set_name = oci_load_balancer_backend_set.main.name
  port                     = 80
  protocol                 = "HTTP"

  connection_configuration {
    idle_timeout_in_seconds = 300
  }
}

# Listener for HTTPS (optional - requires SSL certificate)
# Uncomment and configure when you have an SSL certificate
# resource "oci_load_balancer_listener" "https" {
#   load_balancer_id         = oci_load_balancer_load_balancer.main.id
#   name                     = "${var.app_name}-${var.environment}-https-listener"
#   default_backend_set_name = oci_load_balancer_backend_set.main.name
#   port                     = 443
#   protocol                 = "HTTP"
#
#   ssl_configuration {
#     certificate_name        = oci_load_balancer_certificate.main.certificate_name
#     verify_peer_certificate = false
#   }
#
#   connection_configuration {
#     idle_timeout_in_seconds = 300
#   }
# }

# SSL Certificate (optional)
# Uncomment when you have an SSL certificate
# resource "oci_load_balancer_certificate" "main" {
#   load_balancer_id   = oci_load_balancer_load_balancer.main.id
#   certificate_name   = "${var.app_name}-${var.environment}-cert"
#   ca_certificate     = file("path/to/ca_certificate.pem")
#   private_key        = file("path/to/private_key.pem")
#   public_certificate = file("path/to/public_certificate.pem")
# }
