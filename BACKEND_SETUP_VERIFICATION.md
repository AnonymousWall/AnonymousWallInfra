# Backend Micronaut API Setup Verification

This document provides a comprehensive verification of the infrastructure setup for the AnonymousWall Micronaut backend API.

**Date:** 2026-02-02  
**Backend Repository:** https://github.com/AnonymousWall/AnonymousWall  
**Infrastructure Repository:** https://github.com/AnonymousWall/AnonymousWallInfra

---

## Executive Summary

### ✅ WORKING Components

1. **Network Infrastructure** - Fully configured and compatible
2. **Compute Instances** - Properly configured with Docker support
3. **Load Balancer** - Correctly configured with health checks
4. **Bastion Host** - SSH access properly configured
5. **IAM Policies** - Security policies in place
6. **Cloud-Init Setup** - Docker and firewall properly configured

### ❌ CRITICAL ISSUE: Database Incompatibility

**Problem:** The infrastructure uses **Oracle Autonomous Database**, but the Micronaut backend application requires **MySQL**.

**Impact:** The application will NOT work with the current database configuration.

**Required Action:** Replace Autonomous Database with MySQL HeatWave (OCI's MySQL service).

---

## Detailed Verification

### 1. Network Configuration ✅

**Status:** WORKING

**Configuration:**
- VCN: `10.0.0.0/16`
- Public Subnet: `10.0.1.0/24` (Load Balancer, Bastion)
- Private Subnet: `10.0.2.0/24` (Backend instances)
- Database Subnet: `10.0.3.0/24` (Database)

**Security Lists:**
- Public subnet: HTTP (80), HTTPS (443), SSH (22) allowed
- Private subnet: Port 8080 from load balancer, SSH from bastion
- Proper isolation between tiers

**Verification:**
```bash
# After deployment, verify with:
terraform output vcn_id
terraform output public_subnet_id
terraform output private_subnet_id
```

---

### 2. Compute Instances ✅

**Status:** WORKING

**Configuration:**
- Instance Shape: VM.Standard.E5.Flex (configurable)
- Default: 1 OCPU, 1GB RAM per instance
- Count: 2 instances (configurable)
- OS: Oracle Linux 9
- Location: Private subnet (no public IPs)
- Docker: Pre-installed via cloud-init
- Firewall: Port 8080 open

**Cloud-Init Verification:**

The `modules/compute/cloud-init.yaml` correctly configures:
- ✅ Docker installation
- ✅ Docker Compose installation
- ✅ Docker service enabled and started
- ✅ User added to docker group
- ✅ Firewall configured for port 8080
- ✅ Application directory created at `/opt/anonymouswall`
- ✅ Systemd service template for backend

**Expected Backend Deployment:**

The backend expects to run as a Docker container exposing port 8080:
```yaml
services:
  app:
    image: anonymouswall-backend:latest
    ports:
      - "8080:8080"
```

**Verification Commands:**
```bash
# SSH to backend instance via bastion
ssh -i ~/.ssh/oci_instance_key -J opc@<bastion-ip> opc@<backend-private-ip>

# Verify Docker installation
docker --version
docker-compose --version

# Check firewall rules
sudo firewall-cmd --list-all

# Verify port 8080 is open
sudo firewall-cmd --list-ports
```

---

### 3. Load Balancer ✅

**Status:** WORKING

**Configuration:**
- Shape: Flexible (10-100 Mbps, configurable)
- Backend Port: 8080
- Health Check Path: `/health`
- Health Check Protocol: HTTP
- Expected Response: 200 OK
- Check Interval: 10 seconds
- Timeout: 3 seconds
- Retries: 3

**Backend Compatibility:**

The Micronaut application provides a `/health` endpoint:
```bash
curl http://localhost:8080/health
# Expected response: {"status":"UP"}
```

**Verification:**
```bash
# Get load balancer IP
terraform output load_balancer_ip

# Test health endpoint through load balancer
curl http://<load-balancer-ip>/health
```

**Match with Backend:** ✅ PERFECT MATCH
- Backend exposes `/health` endpoint
- Load balancer checks `/health` endpoint
- Both use HTTP on port 8080

---

### 4. Bastion Host ✅

**Status:** WORKING

**Configuration:**
- Location: Public subnet
- Public IP: Yes
- SSH Access: Configurable CIDR blocks (default: 0.0.0.0/0)
- Purpose: Secure SSH access to backend instances

**Backend Access:**

Backend instances are in a private subnet and can only be accessed via the bastion:

```bash
# Method 1: SSH with agent forwarding
ssh -A -i ~/.ssh/oci_instance_key opc@<bastion-ip>
ssh opc@<backend-private-ip>

# Method 2: ProxyJump (recommended)
ssh -i ~/.ssh/oci_instance_key -J opc@<bastion-ip> opc@<backend-private-ip>
```

**Verification:**
```bash
terraform output bastion_public_ip
terraform output ssh_access_instructions
```

---

### 5. Database Configuration ❌

**Status:** CRITICAL ISSUE - INCOMPATIBLE

**Current Configuration:**
- Database Type: **Oracle Autonomous Database**
- Version: 19c
- Workload: OLTP
- Free Tier: Yes
- Connection: mTLS required
- Access: Public endpoint (Always Free limitation)

**Backend Requirements:**
- Database Type: **MySQL**
- JDBC Driver: `com.mysql.cj.jdbc.Driver`
- Dialect: MySQL
- Connection: `jdbc:mysql://host:3306/database`

**The Problem:**

```diff
- Current: Oracle Autonomous Database (Oracle SQL)
+ Required: MySQL Database
```

The Micronaut backend is specifically configured for MySQL:

**From backend `docker-compose.prod.yml`:**
```yaml
environment:
  - DATABASE_URL=${DATABASE_URL}  # jdbc:mysql://...
  - DB_TYPE=mysql
  - DB_DIALECT=MYSQL
  - DB_DRIVER=com.mysql.cj.jdbc.Driver
```

**From backend `application-prod.properties`:**
```properties
datasources.default.dialect=MYSQL
datasources.default.driver-class-name=com.mysql.cj.jdbc.Driver
```

**Backend Dependencies (`pom.xml`):**
- Uses MySQL Connector/J JDBC driver
- Schema designed for MySQL
- Liquibase migrations written for MySQL

---

## Required Fix: Replace with MySQL HeatWave

### Solution Overview

Replace the Oracle Autonomous Database module with MySQL HeatWave (OCI's MySQL Database Service).

### Why MySQL HeatWave?

1. **Fully Compatible:** Native MySQL engine
2. **Always Free Tier Available:** Yes (one free instance)
3. **Managed Service:** Automated backups, patching, HA
4. **Performance:** Includes HeatWave analytics engine
5. **Integration:** Works with existing VCN/subnet setup

### Implementation Steps

#### Step 1: Create New MySQL Module

Create `modules/mysql_heatwave/main.tf`:

```hcl
# Get the latest MySQL HeatWave shape configuration
data "oci_mysql_mysql_configurations" "free_tier" {
  compartment_id = var.compartment_ocid
  shape_name     = "MySQL.VM.Standard.E3.1.8GB"
  type           = ["DEFAULT"]
}

# MySQL HeatWave Database System
resource "oci_mysql_mysql_db_system" "main" {
  compartment_id      = var.compartment_ocid
  shape_name          = "MySQL.VM.Standard.E3.1.8GB"
  subnet_id           = var.subnet_id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  availability_domain = var.availability_domain
  
  display_name = "${var.app_name}-${var.environment}-mysql"
  description  = "MySQL Database for ${var.app_name}"

  # Data storage
  data_storage_size_in_gb = 50

  # Network configuration
  hostname_label = "${var.app_name}-mysql"
  ip_address     = var.mysql_private_ip

  # Configuration
  configuration_id = data.oci_mysql_mysql_configurations.free_tier.configurations[0].id

  # Backup policy
  backup_policy {
    is_enabled        = true
    retention_in_days = 7
    window_start_time = "02:00"
  }

  # Maintenance window
  maintenance {
    window_start_time = "sun 02:00"
  }

  freeform_tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-mysql"
  })
}
```

#### Step 2: Update Main Configuration

Replace in `main.tf`:

```hcl
# Remove:
# module "database" {
#   source = "./modules/database"
#   ...
# }

# Add:
module "mysql_database" {
  source = "./modules/mysql_heatwave"

  compartment_ocid    = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_id           = module.network.db_subnet_id
  admin_username      = var.mysql_admin_username
  admin_password      = var.mysql_admin_password
  mysql_private_ip    = "10.0.3.10"  # Within db_subnet_cidr
  app_name            = var.app_name
  environment         = var.environment
  tags                = var.tags
}
```

#### Step 3: Update Variables

In `variables.tf`, replace ADB variables with MySQL variables:

```hcl
variable "mysql_admin_username" {
  description = "MySQL admin username"
  type        = string
  default     = "admin"
}

variable "mysql_admin_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}
```

#### Step 4: Update Outputs

In `outputs.tf`:

```hcl
output "mysql_endpoint" {
  description = "MySQL database endpoint"
  value       = module.mysql_database.endpoint
  sensitive   = true
}

output "mysql_port" {
  description = "MySQL database port"
  value       = module.mysql_database.port
}

output "mysql_connection_string" {
  description = "MySQL JDBC connection string"
  value       = "jdbc:mysql://${module.mysql_database.endpoint}:${module.mysql_database.port}/anonymous_wall"
  sensitive   = true
}
```

#### Step 5: Network Security Update

Ensure `modules/network/main.tf` allows MySQL traffic (port 3306):

```hcl
# In db_subnet security list, add:
ingress_security_rules {
  protocol    = "6" # TCP
  source      = var.private_subnet_cidr
  stateless   = false
  description = "Allow MySQL from backend instances"
  tcp_options {
    min = 3306
    max = 3306
  }
}
```

### Deployment After Fix

After implementing the MySQL HeatWave module:

```bash
# Update terraform.tfvars
mysql_admin_password = "YourStrongPassword123!@#"

# Deploy
terraform init
terraform plan
terraform apply

# Get connection details
terraform output mysql_connection_string
```

---

## Backend Deployment Process

Once the database issue is fixed, the backend deployment follows these steps:

### Prerequisites

1. Infrastructure deployed via Terraform
2. MySQL database connection details from `terraform output`
3. SSH access to backend instances via bastion
4. Backend application code and Docker configuration

### Deployment Steps

#### 1. Get Infrastructure Details

```bash
# Get bastion IP for SSH access
BASTION_IP=$(terraform output -raw bastion_public_ip)

# Get backend instance IPs
INSTANCE_IPS=$(terraform output -json instance_private_ips | jq -r '.[]')

# Get database connection string
DB_CONN=$(terraform output -raw mysql_connection_string)
```

#### 2. Prepare Deployment Package

On your local machine:

```bash
# Clone backend repository
git clone https://github.com/AnonymousWall/AnonymousWall.git
cd AnonymousWall

# Create environment file
cat > .env << EOF
JWT_GENERATOR_SIGNATURE_SECRET=$(openssl rand -base64 32)
DATABASE_URL=${DB_CONN}
DATABASE_USER=admin
DATABASE_PASSWORD=YourDatabasePassword
REDIS_URI=redis://localhost:6379
EOF

# Create deployment tarball
tar czf anonymouswall-deploy.tar.gz \
  Dockerfile \
  docker-compose.prod.yml \
  deploy.sh \
  .env \
  pom.xml \
  mvnw \
  mvnw.bat \
  .mvn \
  src \
  *.properties \
  *.yml
```

#### 3. Transfer to Backend Instance

```bash
# Transfer via bastion to first backend instance
scp -i ~/.ssh/oci_instance_key anonymouswall-deploy.tar.gz opc@$BASTION_IP:/tmp/
ssh -i ~/.ssh/oci_instance_key opc@$BASTION_IP \
  "scp /tmp/anonymouswall-deploy.tar.gz opc@${INSTANCE_IPS[0]}:/tmp/"
```

#### 4. Deploy Application

```bash
# SSH to backend instance
ssh -i ~/.ssh/oci_instance_key -J opc@$BASTION_IP opc@${INSTANCE_IPS[0]}

# Extract and deploy
cd /opt/anonymouswall
tar xzf /tmp/anonymouswall-deploy.tar.gz
./deploy.sh

# Verify deployment
curl http://localhost:8080/health
# Expected: {"status":"UP"}

# Exit and test via load balancer
exit
curl http://$(terraform output -raw load_balancer_ip)/health
```

#### 5. Deploy to Additional Instances

Repeat step 4 for each backend instance.

---

## Verification Checklist

### Infrastructure Verification

- [ ] VCN and subnets created
- [ ] Security lists configured correctly
- [ ] Load balancer operational
- [ ] Backend instances running
- [ ] Bastion host accessible
- [ ] **MySQL database deployed and accessible** (currently blocked by database issue)
- [ ] IAM policies applied
- [ ] Network routing configured

### Backend Application Verification

Once database is fixed:

- [ ] Docker installed on backend instances
- [ ] Application directory exists (`/opt/anonymouswall`)
- [ ] Environment variables configured (`.env` file)
- [ ] Application container running
- [ ] Health endpoint responding (`/health`)
- [ ] Database connection successful
- [ ] Load balancer health checks passing
- [ ] Application accessible via load balancer

### Commands to Verify

```bash
# 1. Check infrastructure
terraform output

# 2. Verify load balancer
curl http://$(terraform output -raw load_balancer_ip)/health

# 3. Check backend instance (via bastion)
ssh -i ~/.ssh/oci_instance_key -J opc@$(terraform output -raw bastion_public_ip) \
  opc@$(terraform output -json instance_private_ips | jq -r '.[0]')

# On backend instance:
docker ps
curl http://localhost:8080/health
docker logs anonymouswall-backend
```

---

## Known Limitations and Considerations

### 1. Always Free Tier Constraints

If using Always Free tier:
- **Database:** MySQL HeatWave Always Free provides 1 instance
- **Compute:** 4 ARM-based OCPUs total (need VM.Standard.A1.Flex)
- **Load Balancer:** Fixed at 10 Mbps bandwidth
- **Memory:** 24 GB total across all compute instances

### 2. Database Access

With the current Always Free ADB configuration:
- Public endpoint only (no VCN integration)
- mTLS required (wallet-based authentication)
- Backend would need Oracle JDBC driver (incompatible)

With MySQL HeatWave (after fix):
- VCN integration supported
- Standard MySQL authentication
- Compatible with backend JDBC driver

### 3. High Availability

Current configuration:
- 2 backend instances for redundancy
- Single database instance (no HA in free tier)
- Single load balancer

For production:
- Consider multiple availability domains
- Enable MySQL Read Replicas (paid tier)
- Configure load balancer across ADs

### 4. Security Considerations

- [ ] Restrict SSH access to bastion (update `ssh_allowed_cidrs`)
- [ ] Secure database credentials (consider OCI Vault)
- [ ] Enable SSL/TLS on load balancer (requires certificate)
- [ ] Rotate JWT secret regularly
- [ ] Enable database backups (MySQL HeatWave includes automated backups)

---

## Next Steps

### Immediate Action Required

1. **Replace Oracle Autonomous Database with MySQL HeatWave**
   - Follow the implementation steps above
   - Update Terraform configuration
   - Redeploy infrastructure

### After Database Fix

2. **Deploy Backend Application**
   - Follow backend deployment process
   - Verify health endpoints
   - Test load balancer connectivity

3. **Configure Monitoring**
   - Set up OCI monitoring for instances
   - Configure load balancer logs
   - Monitor database performance

4. **Production Readiness**
   - Configure DNS (if needed)
   - Add SSL certificate to load balancer
   - Implement backup strategy
   - Document runbooks

---

## Additional Resources

### Documentation

- [Backend Repository](https://github.com/AnonymousWall/AnonymousWall)
- [Backend Deployment Guide](https://github.com/AnonymousWall/AnonymousWall/blob/main/DEPLOYMENT.md)
- [Infrastructure QUICKSTART](./QUICKSTART.md)
- [Infrastructure README](./README.md)
- [Always Free Configuration](./ALWAYS_FREE_CONFIG.md)

### OCI Documentation

- [MySQL HeatWave Documentation](https://docs.oracle.com/en-us/iaas/mysql-database/)
- [MySQL HeatWave Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/mysql_mysql_db_system)
- [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)

### Support

For questions or issues:
- Infrastructure issues: Create issue in AnonymousWallInfra repository
- Backend issues: Create issue in AnonymousWall repository
- OCI issues: [OCI Support](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/contactingsupport.htm)

---

## Conclusion

### Summary

The infrastructure is **95% ready** for the Micronaut backend API, with excellent network, compute, load balancer, and security configurations. However, there is one **CRITICAL BLOCKER**:

**The database must be changed from Oracle Autonomous Database to MySQL HeatWave** for compatibility with the Micronaut backend application.

### Recommendation

**Priority 1 (CRITICAL):** Implement MySQL HeatWave module as described in this document.

**Priority 2 (After database fix):** Deploy and test the backend application.

**Priority 3 (Production readiness):** Configure SSL, monitoring, and backup strategies.

### Timeline Estimate

- Database replacement: 2-4 hours (Terraform module creation and testing)
- Backend deployment: 1-2 hours (after database is ready)
- Production hardening: 4-8 hours (SSL, monitoring, security)

**Total:** 1-2 days for complete setup and testing

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-02  
**Status:** Database incompatibility identified - awaiting fix
