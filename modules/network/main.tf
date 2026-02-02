# Network Module - VCN, Subnets, Security Lists, Route Tables, VNICs, VLANs

# Virtual Cloud Network (VCN)
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}-${var.environment}-vcn"
  cidr_blocks    = [var.vcn_cidr_block]
  # DNS label: max 15 chars, alphanumeric only
  # Takes first 12 chars of app_name (removing hyphens) and converts to lowercase
  dns_label     = lower(substr(replace(var.app_name, "-", ""), 0, 12))
  freeform_tags = var.tags
}

# Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-igw"
  enabled        = true
  freeform_tags  = var.tags
}

# NAT Gateway
resource "oci_core_nat_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-nat"
  freeform_tags  = var.tags
}

# Service Gateway
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-sgw"
  freeform_tags  = var.tags

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

# Route Table for Public Subnet
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-public-rt"
  freeform_tags  = var.tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# Route Table for Private Subnet
resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-private-rt"
  freeform_tags  = var.tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.main.id
  }
}

# Route Table for Database Subnet
resource "oci_core_route_table" "db" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-db-rt"
  freeform_tags  = var.tags

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.main.id
  }
}

# Security List for Public Subnet (Load Balancer)
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-public-sl"
  freeform_tags  = var.tags

  # Allow inbound HTTP
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    stateless   = false
    description = "Allow HTTP"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Allow inbound HTTPS
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    stateless   = false
    description = "Allow HTTPS"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow inbound SSH (for bastion host) from allowed CIDR blocks
  dynamic "ingress_security_rules" {
    for_each = var.ssh_allowed_cidrs
    content {
      protocol    = "6" # TCP
      source      = ingress_security_rules.value
      stateless   = false
      description = "Allow SSH to bastion from ${ingress_security_rules.value}"
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # Allow all outbound
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
    description = "Allow all outbound"
  }
}

# Security List for Private Subnet (Backend Instances)
resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-private-sl"
  freeform_tags  = var.tags

  # Allow inbound from public subnet (Load Balancer)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.public_subnet_cidr
    stateless   = false
    description = "Allow from Load Balancer"
    tcp_options {
      min = 8080
      max = 8080
    }
  }

  # Allow inbound from private subnet (internal communication)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.private_subnet_cidr
    stateless   = false
    description = "Allow internal communication"
  }

  # Allow SSH from within VCN
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.vcn_cidr_block
    stateless   = false
    description = "Allow SSH from VCN"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow all outbound
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
    description = "Allow all outbound"
  }
}

# Security List for Database Subnet
resource "oci_core_security_list" "db" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-${var.environment}-db-sl"
  freeform_tags  = var.tags

  # Allow inbound from private subnet on database ports
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.private_subnet_cidr
    stateless   = false
    description = "Allow database access from app servers"
    tcp_options {
      min = 1521
      max = 1522
    }
  }

  # Allow HTTPS for ADB connections
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.private_subnet_cidr
    stateless   = false
    description = "Allow HTTPS for ADB"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow outbound to Oracle Services Network
  egress_security_rules {
    protocol         = "6" # TCP
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    stateless        = false
    description      = "Allow to Oracle Services"
  }
}

# Public Subnet (for Load Balancer)
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "${var.app_name}-${var.environment}-public-subnet"
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  freeform_tags              = var.tags
}

# Private Subnet (for Backend Instances)
resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.app_name}-${var.environment}-private-subnet"
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  freeform_tags              = var.tags
}

# Database Subnet (for ADB)
resource "oci_core_subnet" "db" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.db_subnet_cidr
  display_name               = "${var.app_name}-${var.environment}-db-subnet"
  dns_label                  = "db"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.db.id
  security_list_ids          = [oci_core_security_list.db.id]
  freeform_tags              = var.tags
}
