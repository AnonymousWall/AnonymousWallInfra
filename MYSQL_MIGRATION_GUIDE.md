# Migration Guide: Oracle Autonomous Database to MySQL HeatWave

This guide explains how to migrate from Oracle Autonomous Database to MySQL HeatWave to support the AnonymousWall Micronaut backend API.

## Why This Migration is Needed

The AnonymousWall Micronaut backend application is designed to work with **MySQL**, using:
- MySQL JDBC driver (`com.mysql.cj.jdbc.Driver`)
- MySQL SQL dialect
- MySQL-specific connection strings (`jdbc:mysql://...`)
- Liquibase migrations written for MySQL

The current infrastructure uses **Oracle Autonomous Database**, which is incompatible with the backend application's database requirements.

## Migration Overview

### What's Changing
- **FROM:** Oracle Autonomous Database (Oracle SQL)
- **TO:** MySQL HeatWave (MySQL compatible)

### What Stays the Same
- VCN and subnet configuration
- Compute instances and load balancer
- Network security architecture
- Bastion host access
- All other infrastructure components

### Migration Steps Summary
1. Update Terraform configuration (switch database module)
2. Update variables and outputs
3. Apply Terraform changes (will destroy ADB and create MySQL)
4. Update backend application configuration
5. Initialize MySQL database schema
6. Deploy and test backend application

## Prerequisites

- [ ] Backup any data in Oracle Autonomous Database (if exists)
- [ ] Ensure no applications are currently connected to ADB
- [ ] Have MySQL admin password ready (strong password required)
- [ ] Review Always Free tier limitations if applicable

## Step-by-Step Migration

### Step 1: Update Main Terraform Configuration

**File:** `main.tf`

**Change 1: Comment out the Autonomous Database module**

```hcl
# Comment out or remove the Autonomous Database module
# module "database" {
#   source = "./modules/database"
#
#   compartment_ocid   = var.compartment_ocid
#   adb_display_name   = var.adb_display_name
#   adb_db_name        = var.adb_db_name
#   adb_admin_password = var.adb_admin_password
#   adb_db_version     = var.adb_db_version
#   adb_db_workload    = var.adb_db_workload
#   app_name           = var.app_name
#   environment        = var.environment
#   tags               = var.tags
# }
```

**Change 2: Add MySQL HeatWave module**

```hcl
# MySQL HeatWave Database Module
module "mysql_database" {
  source = "./modules/mysql_heatwave"

  compartment_ocid    = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_id           = module.network.db_subnet_id
  admin_username      = var.mysql_admin_username
  admin_password      = var.mysql_admin_password
  mysql_private_ip    = var.mysql_private_ip
  mysql_shape         = var.mysql_shape
  data_storage_size_in_gb = var.mysql_data_storage_size_in_gb
  app_name            = var.app_name
  environment         = var.environment
  tags                = var.tags
}
```

### Step 2: Update Variables

**File:** `variables.tf`

**Add MySQL variables:**

```hcl
# MySQL HeatWave Variables
variable "mysql_admin_username" {
  description = "MySQL admin username"
  type        = string
  default     = "admin"
}

variable "mysql_admin_password" {
  description = "MySQL admin password (min 12 characters, include uppercase, lowercase, numbers, and special characters)"
  type        = string
  sensitive   = true
}

variable "mysql_shape" {
  description = "Shape of the MySQL database system"
  type        = string
  default     = "MySQL.VM.Standard.E3.1.8GB" # Always Free compatible
}

variable "mysql_data_storage_size_in_gb" {
  description = "Data storage size in GB for MySQL database"
  type        = number
  default     = 50 # Always Free: 50 GB included
}

variable "mysql_private_ip" {
  description = "Private IP address for MySQL database (within db_subnet_cidr)"
  type        = string
  default     = "10.0.3.10"
}
```

**Optional: Comment out or remove old ADB variables:**

```hcl
# These ADB variables are no longer needed
# variable "adb_display_name" { ... }
# variable "adb_db_name" { ... }
# variable "adb_admin_password" { ... }
# variable "adb_db_version" { ... }
# variable "adb_db_workload" { ... }
# variable "adb_cpu_core_count" { ... }
# variable "adb_data_storage_size_in_tbs" { ... }
# variable "adb_license_model" { ... }
```

### Step 3: Update Outputs

**File:** `outputs.tf`

**Replace ADB outputs with MySQL outputs:**

```hcl
# MySQL Database Outputs
output "mysql_id" {
  description = "OCID of the MySQL database system"
  value       = module.mysql_database.mysql_id
}

output "mysql_endpoint" {
  description = "MySQL database endpoint (hostname)"
  value       = module.mysql_database.mysql_endpoint
  sensitive   = true
}

output "mysql_port" {
  description = "MySQL database port"
  value       = module.mysql_database.mysql_port
}

output "mysql_connection_string" {
  description = "MySQL JDBC connection string for backend application"
  value       = module.mysql_database.mysql_connection_string
  sensitive   = true
}

output "mysql_connection_info" {
  description = "Complete MySQL connection information"
  value = {
    endpoint          = module.mysql_database.mysql_endpoint
    port              = module.mysql_database.mysql_port
    connection_string = module.mysql_database.mysql_connection_string
    username          = module.mysql_database.mysql_admin_username
  }
  sensitive = true
}
```

**Comment out or remove old ADB outputs:**

```hcl
# These ADB outputs are no longer needed
# output "adb_id" { ... }
# output "adb_connection_strings" { ... }
```

### Step 4: Update terraform.tfvars

**File:** `terraform.tfvars`

**Add MySQL configuration:**

```hcl
# MySQL HeatWave Configuration
mysql_admin_username        = "admin"
mysql_admin_password        = "YourStrongPassword123!@#"  # Change this!
mysql_shape                 = "MySQL.VM.Standard.E3.1.8GB"
mysql_data_storage_size_in_gb = 50
mysql_private_ip            = "10.0.3.10"
```

**Comment out or remove old ADB configuration:**

```hcl
# adb_admin_password = "..."  # No longer needed
# adb_display_name   = "..."  # No longer needed
# adb_db_name        = "..."  # No longer needed
```

### Step 5: Apply Terraform Changes

**Important:** This will destroy the Oracle Autonomous Database and create a new MySQL HeatWave database.

```bash
# Initialize Terraform (for new module)
terraform init

# Validate configuration
terraform validate

# Review the plan (check what will be destroyed and created)
terraform plan

# Expected output:
# - module.database will be destroyed
# - module.mysql_database will be created
# - Network security list will be updated

# Apply changes (type 'yes' when prompted)
terraform apply
```

**Wait for Deployment:**
- MySQL database creation takes approximately 10-15 minutes
- Monitor progress in OCI Console or via Terraform output

### Step 6: Verify MySQL Deployment

```bash
# Get MySQL connection information
terraform output mysql_connection_info

# Should output something like:
# {
#   "connection_string" = "jdbc:mysql://mysql-hostname.subnet.vcn.oraclevcn.com:3306/anonymous_wall"
#   "endpoint" = "mysql-hostname.subnet.vcn.oraclevcn.com"
#   "port" = 3306
#   "username" = "admin"
# }
```

### Step 7: Create Database Schema

**Option A: Let Backend Application Create Schema (Recommended)**

The Micronaut backend uses Liquibase for automatic schema migrations. The schema will be created automatically when the backend starts.

**Option B: Manually Create Database**

If you want to create the database manually first:

```bash
# SSH to a backend instance via bastion
ssh -i ~/.ssh/oci_instance_key -J opc@$(terraform output -raw bastion_public_ip) \
  opc@$(terraform output -json instance_private_ips | jq -r '.[0]')

# Install MySQL client
sudo yum install -y mysql

# Connect to MySQL (use password from terraform.tfvars)
mysql -h $(terraform output -raw mysql_endpoint) -u admin -p

# Create database
CREATE DATABASE IF NOT EXISTS anonymous_wall;
USE anonymous_wall;

# Exit MySQL
exit;
```

### Step 8: Update Backend Application Configuration

Update the backend's `.env` file with the new MySQL connection details:

```bash
# Get connection string from Terraform
MYSQL_CONN=$(terraform output -raw mysql_connection_string)

# Create .env file for backend
cat > .env << EOF
# JWT Secret
JWT_GENERATOR_SIGNATURE_SECRET=$(openssl rand -base64 32)

# MySQL Database Configuration
DATABASE_URL=${MYSQL_CONN}
DATABASE_USER=admin
DATABASE_PASSWORD=YourStrongPassword123!@#

# Redis Configuration (optional)
REDIS_URI=redis://localhost:6379

# Email Configuration (optional)
# SMTP_HOST=
# SMTP_PORT=587
# SMTP_USERNAME=
# SMTP_PASSWORD=
EOF
```

### Step 9: Deploy Backend Application

Follow the normal backend deployment process:

```bash
# Transfer backend files to instance
# (See BACKEND_SETUP_VERIFICATION.md for complete deployment steps)

# On backend instance:
cd /opt/anonymouswall
./deploy.sh

# Verify deployment
curl http://localhost:8080/health
# Expected: {"status":"UP"}
```

### Step 10: Verify End-to-End Connectivity

```bash
# Test via load balancer
curl http://$(terraform output -raw load_balancer_ip)/health

# Check backend logs
docker logs anonymouswall-backend

# Should see successful database connection:
# "Liquibase: Successfully acquired change log lock"
# "Liquibase: Database is at the most recent version"
```

## Rollback Plan

If you need to rollback to Oracle Autonomous Database:

```bash
# 1. Uncomment the database module in main.tf
# 2. Comment out the mysql_database module
# 3. Restore old variables and outputs
# 4. Run terraform apply

# Note: This will destroy MySQL and recreate ADB
# Any data in MySQL will be lost
```

## Always Free Tier Considerations

### MySQL HeatWave Always Free Limits
- 1 MySQL instance per tenancy
- MySQL.VM.Standard.E3.1.8GB shape (1 OCPU, 8GB RAM)
- 50 GB storage
- In-VCN deployment (private network)
- Automated backups included

### Costs
If you're using Always Free tier:
- MySQL HeatWave: FREE (1 instance)
- Additional MySQL instances: Paid

If you're using paid tier:
- MySQL HeatWave pricing based on shape, storage, and bandwidth
- See [OCI Pricing](https://www.oracle.com/cloud/price-list.html)

## Troubleshooting

### Issue: Terraform Plan Shows Errors

**Problem:** Module not found or configuration errors

**Solution:**
```bash
terraform init -upgrade
terraform validate
```

### Issue: MySQL Creation Fails

**Problem:** Capacity issues or invalid configuration

**Solution:**
- Check availability domain has capacity
- Verify subnet CIDR has available IPs
- Ensure mysql_private_ip is within db_subnet_cidr
- Try different availability domain

### Issue: Backend Can't Connect to MySQL

**Problem:** Network connectivity or authentication

**Solution:**
```bash
# 1. Verify security list allows port 3306
terraform state show module.network.oci_core_security_list.db

# 2. Test connectivity from backend instance
ssh -J opc@<bastion-ip> opc@<backend-ip>
telnet $(terraform output -raw mysql_endpoint) 3306

# 3. Verify MySQL is running
# In OCI Console: Databases → MySQL → DB Systems
```

### Issue: Schema Migration Fails

**Problem:** Liquibase can't create schema

**Solution:**
```bash
# Check backend logs
docker logs anonymouswall-backend | grep -i "liquibase\|database"

# Verify database credentials in .env
docker exec anonymouswall-backend env | grep DATABASE

# Manually test connection
docker exec -it anonymouswall-backend sh
mysql -h <mysql-endpoint> -u admin -p
```

## Post-Migration Checklist

- [ ] MySQL database is running
- [ ] Security list allows MySQL traffic (port 3306)
- [ ] Backend can connect to MySQL
- [ ] Database schema is created (via Liquibase)
- [ ] Backend health check passes
- [ ] Load balancer health checks pass
- [ ] Application endpoints responding correctly
- [ ] Remove old ADB references from documentation
- [ ] Update runbooks with new connection details

## References

- [MySQL HeatWave Documentation](https://docs.oracle.com/en-us/iaas/mysql-database/)
- [Backend Deployment Guide](https://github.com/AnonymousWall/AnonymousWall/blob/main/DEPLOYMENT.md)
- [Backend Setup Verification](./BACKEND_SETUP_VERIFICATION.md)
- [MySQL Module README](./modules/mysql_heatwave/README.md)

## Support

For issues during migration:
- Infrastructure issues: Create issue in AnonymousWallInfra repository
- Backend issues: Create issue in AnonymousWall repository
- OCI issues: [OCI Support](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/contactingsupport.htm)

---

**Migration prepared by:** Infrastructure Team  
**Date:** 2026-02-02  
**Estimated migration time:** 30-45 minutes (excluding MySQL provisioning time)
