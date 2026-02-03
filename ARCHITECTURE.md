# OCI Infrastructure Architecture

## Overview

This document describes the Oracle Cloud Infrastructure (OCI) architecture for the AnonymousWall mobile application backend.

## Components

### 1. Networking (modules/network)

**Resources Created:**
- Virtual Cloud Network (VCN): `10.0.0.0/16`
- Internet Gateway: For public internet access
- NAT Gateway: For private subnet internet access
- Service Gateway: For OCI services access
- VLAN: For high-performance networking (`10.0.10.0/24`)

**Subnets:**
- **Public Subnet** (`10.0.1.0/24`): Hosts the load balancer and bastion host
- **Private Subnet** (`10.0.2.0/24`): Hosts backend compute instances
- **Database Subnet** (`10.0.3.0/24`): Hosts the Autonomous Database

**Security Lists:**
- Public: Allows HTTP (80), HTTPS (443), and SSH (22) from internet
- Private: Allows traffic from load balancer on port 8080, SSH from VCN
- Database: Allows database traffic (1521-1522, 443) from private subnet

### 2. Bastion Host (modules/bastion)

**Resources Created:**
- Single bastion host instance in public subnet
- Instance Shape: Flexible (default: VM.Standard.E5.Flex with 1 OCPU, 1GB RAM)
- OS: Oracle Linux 8 (auto-selected latest image)
- Public IP address for external SSH access
- SSH access from internet (port 22)

**Purpose:**
- Provides secure SSH access to backend instances in private subnet
- Jump host for administrative tasks
- Isolated from application workload
- Minimal installation (no Docker or application tools)

### 3. Compute Instances (modules/compute)

**Resources Created:**
- Configurable number of compute instances (default: 2)
- Instance Shape: Flexible (default: VM.Standard.E4.Flex with 1 OCPU, 8GB RAM)
- OS: Oracle Linux 8 (auto-selected latest image)
- Primary VNICs: For network connectivity
- Secondary VNICs: For high-performance networking (optional)

**Cloud-Init Configuration:**
- Docker and Docker Compose installation (via get.docker.com convenience script)
- Firewall configuration for port 8080
- Application directory setup (`/opt/anonymouswall`)
- Systemd service template

### 4. Autonomous Database (modules/database)

**Resources Created:**
- Autonomous Database (ADB)
- Database Workload: OLTP (default)
- CPU Cores: 1 (default, auto-scaling enabled)
- Storage: 1 TB (default)
- Version: 19c (default)
- License Model: LICENSE_INCLUDED
- Network: Private subnet access only
- Wallet: For secure connections

**Features:**
- Auto-scaling enabled
- Automatic backups
- Private network access only
- TLS connections supported

### 5. Load Balancer (modules/load_balancer)

**Resources Created:**
- Flexible Load Balancer (10-100 Mbps)
- Backend Set with round-robin policy
- Health Checks: HTTP on port 8080, path `/health`
- Session Persistence: Cookie-based
- HTTP Listener on port 80
- HTTPS Listener (commented, requires SSL certificate)

**Health Check Configuration:**
- Protocol: HTTP
- Port: 8080
- Path: `/health`
- Interval: 10 seconds
- Timeout: 3 seconds
- Retries: 3

### 6. IAM Policies (modules/iam)

**Resources Created:**
- Dynamic Group for compute instances
- Policies for:
  - Object Storage access
  - Autonomous Database access
  - Load balancer operations
  - Monitoring and logging
  - Secrets management

**Security Principals:**
- Dynamic groups based on compartment membership
- Least privilege access model
- Service-specific policies

### 7. DNS (modules/dns)

**Resources Created (Optional):**
- DNS Zone (PRIMARY, GLOBAL scope)
- A Record pointing to load balancer IP
- CNAME Record for www subdomain
- TXT Record for domain verification (optional)

**Configuration:**
- Zone: User-defined domain
- Records: Automatic configuration
- TTL: 300 seconds (default)

## Network Architecture

```
                         Internet
                             |
                    [Internet Gateway]
                        /          \
                       /            \
                      /              \
             [Load Balancer]    [Bastion Host]
              (Public Subnet)   (Public Subnet)
                     |                 |
                     |                 | SSH
                     |                 |
                     v                 v
             [Backend Instances] <------
              (Private Subnet)
                     |
             [NAT Gateway] [Service Gateway]
                     |            |
                     v            v
              [Autonomous Database]
               (Database Subnet)
```

## Security Architecture

### Network Security

1. **Defense in Depth:**
   - Public subnet: Only load balancer exposed
   - Private subnet: Backend instances isolated
   - Database subnet: No internet access

2. **Security Lists:**
   - Stateful firewall rules
   - Least privilege network access
   - Protocol-specific rules

3. **Service Gateway:**
   - Secure access to OCI services
   - No public internet required

### IAM Security

1. **Dynamic Groups:**
   - Automatic membership based on tags
   - No long-lived credentials required

2. **Policies:**
   - Service-specific access
   - Compartment-scoped permissions
   - Resource-level controls

### Data Security

1. **Database:**
   - Private network only
   - TLS encryption in transit
   - Automatic backups
   - Wallet-based authentication

2. **Secrets:**
   - OCI Vault integration ready
   - Dynamic group access
   - No hardcoded credentials

## High Availability

1. **Compute:**
   - Multiple instances across availability domains
   - Load balancer health checks
   - Automatic failover

2. **Database:**
   - Autonomous Database (ADB) provides built-in HA
   - Automatic backups
   - Point-in-time recovery

3. **Load Balancer:**
   - Flexible shape for auto-scaling
   - Health checks for backend instances
   - Session persistence

## Scalability

1. **Horizontal Scaling:**
   - Increase `instance_count` for more backend instances
   - Load balancer automatically distributes traffic

2. **Vertical Scaling:**
   - Adjust instance shape (OCPUs, memory)
   - Database auto-scaling enabled

3. **Network Scaling:**
   - Flexible load balancer bandwidth (10-100 Mbps)
   - VLAN for high-performance networking

## Monitoring and Observability

### Metrics (Ready for Integration)

- Compute instance metrics
- Load balancer metrics
- Database performance metrics
- Network metrics

### Logging (Ready for Integration)

- Application logs
- Database audit logs
- Load balancer access logs
- Network flow logs

## Cost Optimization

1. **Flexible Shapes:**
   - Pay only for allocated resources
   - Easy to scale up/down

2. **Auto-Scaling:**
   - Database auto-scaling enabled
   - Adjust resources based on demand

3. **License Model:**
   - LICENSE_INCLUDED option available
   - Bring Your Own License (BYOL) supported

## Deployment Workflow

1. **Prerequisites:**
   - OCI account and credentials
   - Compartment created
   - API key configured

2. **Configuration:**
   - Copy `terraform.tfvars.example` to `terraform.tfvars`
   - Update with your specific values

3. **Deployment:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verification:**
   - Check outputs for resource information
   - Verify load balancer health checks
   - Test database connectivity

## Customization Options

### Required Variables

- `tenancy_ocid`: Your OCI tenancy
- `user_ocid`: Your OCI user
- `fingerprint`: API key fingerprint
- `private_key_path`: Path to API private key
- `compartment_ocid`: Target compartment
- `ssh_public_key`: SSH key for instance access
- `availability_domain`: Target availability domain
- `adb_admin_password`: Database admin password

### Optional Variables

- `instance_count`: Number of backend instances (default: 2)
- `instance_shape`: Compute instance shape
- `bastion_shape`: Bastion host shape (default: VM.Standard.E5.Flex)
- `bastion_ocpus`: Bastion host OCPUs (default: 1)
- `bastion_memory_in_gbs`: Bastion host memory (default: 1)
- `lb_min_bandwidth_mbps`: Minimum LB bandwidth
- `dns_zone_name`: Custom domain (optional)
- Network CIDR blocks
- Database configuration

## Maintenance

### Updates

1. **Terraform:**
   - Modify variables in `terraform.tfvars`
   - Run `terraform plan` to review changes
   - Run `terraform apply` to apply changes

2. **Instances:**
   - Updates via cloud-init on replacement
   - SSH access to backend instances via bastion host
   - SSH to bastion: `ssh -i <key> opc@<bastion-ip>`
   - SSH to backend: `ssh -i <key> -J opc@<bastion-ip> opc@<backend-private-ip>`

3. **Database:**
   - Automatic patching available
   - Manual updates via OCI console

### Backups

1. **Database:**
   - Automatic daily backups (ADB)
   - Retention configurable

2. **Terraform State:**
   - Store in OCI Object Storage
   - Enable versioning

3. **Configuration:**
   - Keep `terraform.tfvars` backed up securely
   - Version control for infrastructure code

## Disaster Recovery

1. **Database:**
   - Point-in-time recovery
   - Cross-region replication (manual setup)

2. **Infrastructure:**
   - Infrastructure as Code (IaC) approach
   - Deploy to different region with same configuration

3. **Data:**
   - Regular backups
   - Object Storage for critical data

## Troubleshooting

### Common Issues

1. **Authentication Errors:**
   - Verify API key fingerprint
   - Check private key permissions (should be 600)
   - Ensure user has required policies

2. **Resource Creation Failures:**
   - Check service limits
   - Verify compartment permissions
   - Ensure availability domain is correct

3. **Network Connectivity:**
   - Verify security list rules
   - Check route table configurations
   - Ensure gateways are configured

### Logs and Diagnostics

1. **Terraform:**
   - Set `TF_LOG=DEBUG` for detailed logs
   - Review `terraform.tfstate` for resource state

2. **OCI:**
   - Use OCI Console for resource status
   - Check audit logs for API calls
   - Review service health dashboard

## Future Enhancements

1. **Security:**
   - Add Web Application Firewall (WAF)
   - Implement bastion host for SSH access
   - Enable SSL/TLS on load balancer

2. **Monitoring:**
   - Add OCI Monitoring alarms
   - Configure logging analytics
   - Set up notifications

3. **Automation:**
   - CI/CD pipeline integration
   - Automated testing
   - Blue-green deployments

4. **High Availability:**
   - Multi-region deployment
   - Active-active configuration
   - Geographic load balancing

## References

- [OCI Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Best Practices](https://docs.oracle.com/en-us/iaas/Content/General/Reference/aqswhitepapers.htm)
