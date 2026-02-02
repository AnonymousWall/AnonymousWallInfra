# MySQL HeatWave Database Module

This module provisions an OCI MySQL HeatWave Database System.

## Features

- MySQL HeatWave Database System
- Configurable shape and storage
- Automated backups with configurable retention
- VCN integration (private subnet deployment)
- Maintenance window configuration
- Compatible with Always Free tier

## Usage

```hcl
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| compartment_ocid | The OCID of the compartment | string | - | yes |
| availability_domain | Availability domain for the MySQL database | string | - | yes |
| subnet_id | OCID of the subnet for MySQL database | string | - | yes |
| admin_username | Admin username for MySQL database | string | "admin" | no |
| admin_password | Admin password for MySQL database | string | - | yes |
| mysql_shape | Shape of the MySQL database system | string | "MySQL.VM.Standard.E3.1.8GB" | no |
| data_storage_size_in_gb | Data storage size in GB | number | 50 | no |
| mysql_private_ip | Private IP address for MySQL (within subnet) | string | "" | no |
| mysql_port | MySQL database port | number | 3306 | no |
| mysql_port_x | MySQL X Protocol port | number | 33060 | no |
| backup_enabled | Enable automatic backups | bool | true | no |
| backup_retention_days | Number of days to retain backups | number | 7 | no |
| backup_window_start_time | Backup window start time (HH:MM) | string | "02:00" | no |
| maintenance_window_start_time | Maintenance window (day HH:MM) | string | "sun 02:00" | no |

## Outputs

| Name | Description |
|------|-------------|
| mysql_id | OCID of the MySQL database system |
| mysql_endpoint | MySQL database endpoint (hostname) |
| mysql_ip_address | MySQL database IP address |
| mysql_port | MySQL database port |
| mysql_connection_string | MySQL JDBC connection string |
| mysql_admin_username | MySQL admin username |

## MySQL Shapes

### Always Free Tier
- **MySQL.VM.Standard.E3.1.8GB** - 1 OCPU, 8GB RAM (recommended for free tier)

### Paid Tier Options
- MySQL.VM.Standard.E3.1.8GB - 1 OCPU, 8GB RAM
- MySQL.VM.Standard.E3.2.16GB - 2 OCPU, 16GB RAM
- MySQL.VM.Standard.E3.4.32GB - 4 OCPU, 32GB RAM
- MySQL.VM.Standard.E3.8.64GB - 8 OCPU, 64GB RAM
- And more...

## Always Free Limitations

When using Always Free tier:
- 1 MySQL HeatWave instance per tenancy
- MySQL.VM.Standard.E3.1.8GB shape (1 OCPU, 8GB RAM)
- 50 GB storage
- Deployed in VCN subnet (private network)
- Automated backups included

## Network Configuration

The MySQL database is deployed in the database subnet with:
- Private IP address (within db_subnet_cidr)
- Port 3306 for MySQL protocol
- Port 33060 for MySQL X Protocol
- Security list rules required:
  - Ingress: TCP port 3306 from backend instances (private subnet)
  - Egress: All protocols to OCI services (for management)

## Backup Configuration

Default backup policy:
- Enabled by default
- 7-day retention
- Backup window: 02:00 (2 AM)
- Automated backups to OCI Object Storage

## Maintenance Window

Default maintenance window:
- Sunday at 02:00 (2 AM)
- Automatic patching and updates
- Minimal downtime

## Connection String Format

The module outputs a JDBC connection string in the format:
```
jdbc:mysql://<hostname>:3306/anonymous_wall
```

Example usage in application:
```yaml
environment:
  DATABASE_URL: jdbc:mysql://mysql-hostname.subnet.vcn.oraclevcn.com:3306/anonymous_wall
  DATABASE_USER: admin
  DATABASE_PASSWORD: ${MYSQL_PASSWORD}
```

## Security Considerations

1. **Password Security**
   - Use strong passwords (min 12 characters)
   - Include uppercase, lowercase, numbers, and special characters
   - Store securely (OCI Vault recommended for production)

2. **Network Security**
   - Database deployed in private subnet
   - Only accessible from backend instances
   - No public endpoint

3. **Access Control**
   - IAM policies for database management
   - Database user management via MySQL
   - Audit logging available

## Example: Complete Setup

```hcl
# In main.tf
module "mysql_database" {
  source = "./modules/mysql_heatwave"

  compartment_ocid    = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_id           = module.network.db_subnet_id
  admin_username      = "admin"
  admin_password      = var.mysql_admin_password
  mysql_private_ip    = "10.0.3.10"
  
  # Storage and shape
  mysql_shape             = "MySQL.VM.Standard.E3.1.8GB"
  data_storage_size_in_gb = 50
  
  # Backup configuration
  backup_enabled            = true
  backup_retention_days     = 7
  backup_window_start_time  = "02:00"
  
  # Maintenance
  maintenance_window_start_time = "sun 02:00"
  
  # Tags
  app_name    = var.app_name
  environment = var.environment
  tags        = var.tags
}

# Get connection details
output "database_connection_info" {
  value = {
    endpoint          = module.mysql_database.mysql_endpoint
    port              = module.mysql_database.mysql_port
    connection_string = module.mysql_database.mysql_connection_string
    username          = module.mysql_database.mysql_admin_username
  }
  sensitive = true
}
```

## Migration from Autonomous Database

If migrating from Oracle Autonomous Database to MySQL HeatWave:

1. Export data from Autonomous Database
2. Update Terraform configuration to use this module
3. Apply Terraform changes
4. Import data to MySQL HeatWave
5. Update application connection strings
6. Test connectivity and functionality

## References

- [OCI MySQL Database Documentation](https://docs.oracle.com/en-us/iaas/mysql-database/)
- [MySQL HeatWave Documentation](https://docs.oracle.com/en-us/iaas/mysql-database/doc/heatwave1.html)
- [Terraform OCI Provider - MySQL](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/mysql_mysql_db_system)
- [MySQL HeatWave Always Free](https://blogs.oracle.com/mysql/introducing-heatwave-always-free)
