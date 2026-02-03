# Quick Start Guide

## Overview

This guide will help you quickly deploy the AnonymousWall backend infrastructure on Oracle Cloud Infrastructure (OCI) using Terraform.

## What Gets Deployed

This Terraform configuration creates a complete, production-ready backend infrastructure:

### Infrastructure Components

1. **Network Layer**
   - Virtual Cloud Network (VCN) with CIDR `10.0.0.0/16`
   - 3 subnets: Public, Private, and Database
   - Internet Gateway, NAT Gateway, and Service Gateway
   - VLAN for high-performance networking
   - Security Lists with proper firewall rules

2. **Compute Layer**
   - 2 backend instances (configurable)
   - VM.Standard.E4.Flex shape (1 OCPU, 8GB RAM by default)
   - Oracle Linux 9
   - Docker CE and Docker Compose v2 pre-installed
   - Primary and secondary VNICs
   - Deployed in private subnet (no public IPs)

3. **Bastion Host**
   - Jump host for SSH access to backend instances
   - Deployed in public subnet with public IP
   - VM.Standard.E5.Flex shape (1 OCPU, 1GB RAM by default)
   - Oracle Linux 9

4. **Database Layer**
   - Autonomous Database (ADB)
   - OLTP workload optimized
   - 1 CPU core, 1TB storage (auto-scaling enabled)
   - Private network access only
   - Automatic backups

5. **Load Balancer**
   - Flexible load balancer (10-100 Mbps)
   - Round-robin distribution
   - Health checks on backend instances
   - HTTP listener on port 80

6. **IAM Security**
   - Dynamic groups for compute instances
   - Policies for database, storage, monitoring
   - Least privilege access model

7. **DNS (Optional)**
   - DNS zone management
   - A records for load balancer
   - CNAME for www subdomain

## Prerequisites

### 1. OCI Account Setup

- Active OCI account with admin access
- Compartment created for the project
- Note down your compartment OCID

### 2. Local Setup

- Terraform CLI (>= 1.0) installed
- OCI CLI (optional, but recommended)
- SSH key pair for instance access

## Step-by-Step Deployment

### Step 1: Clone the Repository

```bash
git clone https://github.com/AnonymousWall/AnonymousWallInfra.git
cd AnonymousWallInfra
```

### Step 2: Generate OCI API Key

```bash
# Create OCI directory
mkdir -p ~/.oci

# Generate private key
openssl genrsa -out ~/.oci/oci_api_key.pem 2048

# Set permissions
chmod 600 ~/.oci/oci_api_key.pem

# Generate public key
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

### Step 3: Add API Key to OCI

1. Login to [OCI Console](https://cloud.oracle.com/)
2. Click your profile icon → User Settings
3. Under Resources → API Keys
4. Click "Add API Key"
5. Upload `~/.oci/oci_api_key_public.pem`
6. Copy the fingerprint shown

### Step 4: Get Required OCIDs

You'll need these OCIDs (you can find them in OCI Console):

1. **Tenancy OCID**: Profile menu → Tenancy → OCID
2. **User OCID**: Profile menu → User Settings → OCID
3. **Compartment OCID**: Identity → Compartments → Your Compartment → OCID
4. **Availability Domain**: Compute → Instances → Check available ADs

Example AD format: `xxxx:US-ASHBURN-AD-1`

### Step 5: Generate SSH Key (if needed)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/oci_instance_key
# Public key will be at ~/.ssh/oci_instance_key.pub
```

### Step 6: Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Minimum required configuration:**

```hcl
# OCI Authentication
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaXXXXXXXX"
user_ocid        = "ocid1.user.oc1..aaaaaaaXXXXXXXX"
fingerprint      = "12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"  # or your preferred region
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaXXXXXXXX"

# SSH Access
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC..." # content of ~/.ssh/oci_instance_key.pub

# Availability Domain (check in OCI Console)
availability_domain = "xxxx:US-ASHBURN-AD-1"

# Database Password (must be complex)
adb_admin_password = "YourComplexPassword123!@#"
```

### Step 7: Initialize Terraform

```bash
terraform init
```

This will download the OCI provider and initialize the backend.

### Step 8: Review the Plan

```bash
terraform plan
```

Review the output to see what resources will be created. You should see approximately 30+ resources.

### Step 9: Deploy!

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes approximately 10-15 minutes.

### Step 10: Get Outputs

After successful deployment:

```bash
terraform output
```

Important outputs:
- `load_balancer_ip`: Your application's public IP
- `application_url`: URL to access your app
- `bastion_public_ip`: Bastion host public IP for SSH access
- `instance_private_ips`: Backend instance private IPs
- `ssh_access_instructions`: Complete SSH access guide

## Post-Deployment

### Verify Deployment

1. **Check Load Balancer:**
   ```bash
   curl http://$(terraform output -raw load_balancer_ip)
   ```

2. **Check Backend Health:**
   - Go to OCI Console → Networking → Load Balancers
   - Select your load balancer
   - Check Backend Set health status

3. **Check Database:**
   - Go to OCI Console → Oracle Database → Autonomous Database
   - Verify database is "Available"

### Access Backend Instances

Backend instances are in a private subnet and accessible via the bastion host:

**Get SSH Instructions:**
```bash
terraform output ssh_access_instructions
```

**Option 1: SSH with Agent Forwarding (Two Steps)**
```bash
# Step 1: SSH to bastion with agent forwarding
ssh -A -i ~/.ssh/oci_instance_key opc@$(terraform output -raw bastion_public_ip)

# Step 2: From bastion, SSH to backend (key is forwarded)
ssh opc@<backend-private-ip>
```

**Option 2: SSH ProxyJump (One Command - Recommended)**
```bash
# SSH directly to backend via bastion in one command
ssh -i ~/.ssh/oci_instance_key -J opc@$(terraform output -raw bastion_public_ip) opc@<backend-private-ip>
```

**Option 3: SSH Config (Best for Frequent Use)**

Add to `~/.ssh/config`:
```
Host bastion
    HostName <bastion-public-ip>
    User opc
    IdentityFile ~/.ssh/oci_instance_key

Host backend-*
    User opc
    IdentityFile ~/.ssh/oci_instance_key
    ProxyJump bastion
```

Then simply:
```bash
ssh backend-<backend-private-ip>
```

### Deploy Your Application

1. **SSH to instance:**
   ```bash
   ssh -i ~/.ssh/oci_instance_key opc@<instance-ip>
   ```

2. **Navigate to app directory:**
   ```bash
   cd /opt/anonymouswall
   ```

3. **Create docker-compose.yml:**
   ```yaml
   version: '3.8'
   services:
     backend:
       image: your-backend-image:latest
       ports:
         - "8080:8080"
       environment:
         - DB_CONNECTION_STRING=<from terraform output>
   ```

4. **Start application:**
   ```bash
   docker compose up -d
   ```

## Configuration Options

### Scale Compute Instances

Edit `terraform.tfvars`:
```hcl
instance_count = 4  # Increase to 4 instances
```

Then apply:
```bash
terraform apply
```

### Upgrade Instance Size

```hcl
instance_ocpus         = 2
instance_memory_in_gbs = 16
```

### Add DNS

```hcl
dns_zone_name    = "yourdomain.com"
dns_record_domain = "api.yourdomain.com"
```

Update nameservers at your domain registrar with the nameservers from terraform output.

## Monitoring

### OCI Console

- **Compute**: Compute → Instances
- **Database**: Oracle Database → Autonomous Database
- **Network**: Networking → Load Balancers
- **Monitoring**: Observability → Monitoring

### Metrics

View metrics for:
- CPU utilization
- Memory usage
- Network traffic
- Database performance

## Costs

Estimated monthly costs (may vary by region):

- Compute (2 instances): ~$50-70
- Autonomous Database (1 OCPU): ~$180-200
- Load Balancer (Flexible): ~$25-30
- Network: ~$10-20
- **Total**: ~$265-320/month

Cost-saving tips:
- Use Always Free tier resources for development
- Stop non-production resources when not in use
- Use Reserved Instances for production

## Troubleshooting

### Issue: "Service limit exceeded"

**Solution**: Request limit increase in OCI Console → Governance → Limits

### Issue: "Authorization failed"

**Solutions**:
- Verify API key fingerprint
- Check user permissions in IAM
- Ensure correct compartment OCID

### Issue: "Image not found"

**Solution**: Specify image OCID in terraform.tfvars:
```hcl
instance_image_ocid = "ocid1.image.oc1.iad.aaaaaa..."
```

Get image OCID from: Compute → Images → Oracle Images

### Issue: Database connection fails

**Solutions**:
- Verify security list rules
- Check database status in console
- Ensure instances are in same VCN

## Cleanup

**Warning**: This will delete ALL resources!

```bash
terraform destroy
```

Type `yes` when prompted. This operation takes about 5-10 minutes.

## Security Best Practices

1. **Never commit secrets:**
   - `terraform.tfvars` is gitignored
   - Use OCI Vault for sensitive data

2. **Use strong passwords:**
   - Database password: 12+ characters, mixed case, numbers, symbols

3. **Rotate credentials:**
   - API keys every 90 days
   - Database passwords regularly

4. **Enable MFA:**
   - Enable for your OCI user account

5. **Monitor access:**
   - Review audit logs regularly
   - Set up alerts for suspicious activity

## Next Steps

1. **Configure SSL/TLS:**
   - Obtain SSL certificate
   - Uncomment HTTPS listener in load balancer module

2. **Set up CI/CD:**
   - Automate application deployment
   - Use OCI DevOps or external CI/CD

3. **Enable Monitoring:**
   - Configure alarms for critical metrics
   - Set up log aggregation

4. **Backup Strategy:**
   - Configure backup policies
   - Test restore procedures

5. **Disaster Recovery:**
   - Set up cross-region replication
   - Document recovery procedures

## Support

- **Documentation**: See README.md and ARCHITECTURE.md
- **Issues**: Create an issue in the repository
- **OCI Support**: https://support.oracle.com

## Useful Commands

```bash
# Show outputs
terraform output

# Show specific output
terraform output load_balancer_ip

# Refresh state
terraform refresh

# Show state
terraform show

# List resources
terraform state list

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

## Additional Resources

- [OCI Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Architecture Center](https://docs.oracle.com/solutions/)
- [OCI Best Practices](https://docs.oracle.com/en-us/iaas/Content/General/Reference/aqswhitepapers.htm)

---

**Last Updated**: 2026-01-31  
**Version**: 1.0.0
