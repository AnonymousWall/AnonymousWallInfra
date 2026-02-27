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
    protocol          = "HTTP"
    port              = 8080
    url_path          = "/health"
    return_code       = 200
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
}

# Backends (one for each compute instance)
resource "oci_load_balancer_backend" "main" {
  count            = length(var.backend_private_ips)
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  ip_address       = var.backend_private_ips[count.index]
  port             = 8080
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
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
