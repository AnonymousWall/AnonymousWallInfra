# AnonymousWall Infrastructure

Terraform configuration for deploying the AnonymousWall mobile app backend on Oracle Cloud Infrastructure (OCI).

## Architecture Overview

This Terraform configuration deploys a complete production-ready infrastructure on OCI, including:

- **Networking**: VCN with public, private, and database subnets, Internet Gateway, NAT Gateway, Service Gateway, and VLANs
- **Compute**: Multiple backend instances with automatic scaling capabilities
- **Bastion Host**: Jump host for secure SSH access to backend instances
- **Database**: Autonomous Database (ADB) for data persistence
- **Load Balancer**: Flexible load balancer for distributing traffic
- **IAM**: Policies and dynamic groups for secure resource access
- **DNS**: Optional DNS configuration for custom domain setup

### Container Runtime

Backend instances use **Podman** as the container runtime. Oracle Linux 9 does not include Docker in its default repositories, and Oracle promotes Podman as an OCI-compliant alternative. Podman is fully compatible with Docker commands and Compose files, providing a drop-in replacement for Docker workflows.

## Architecture Diagram

```
Internet
    |
    +-- [Load Balancer] (Public Subnet)
    |         |
    |         v
    |   [Backend Instances] (Private Subnet)
    |         |
    |         v
    |   [Autonomous Database] (Database Subnet)
    |
    +-- [Bastion Host] (Public Subnet)
              |
              v
        [Backend Instances] (Private Subnet)
```

## Prerequisites

1. **OCI Account**: Active Oracle Cloud Infrastructure account
2. **Terraform**: Version 1.0 or higher
3. **OCI CLI**: Configured with appropriate credentials
4. **API Key**: OCI API key pair for authentication

## Setup Instructions

### 1. Configure OCI Credentials

Generate an API key pair if you haven't already:

```bash
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 600 ~/.oci/oci_api_key.pem
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

Add the public key to your OCI user settings:
1. Log in to OCI Console
2. Navigate to Identity > Users > Your User
3. Click "API Keys" > "Add API Key"
4. Upload the public key (`oci_api_key_public.pem`)
5. Note down the fingerprint

### 2. Configure Terraform Variables

Copy the example configuration file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..xxxxx"
user_ocid        = "ocid1.user.oc1..xxxxx"
fingerprint      = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"
compartment_ocid = "ocid1.compartment.oc1..xxxxx"

# Update other variables as needed
ssh_public_key      = "ssh-rsa AAAAB3Nza..."
availability_domain = "ABCD:US-ASHBURN-AD-1"
adb_admin_password  = "YourStrongPassword123!@#"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Deployment Plan

```bash
terraform plan
```

### 5. Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 6. Access Your Infrastructure

After deployment completes, Terraform will output important information:

```bash
terraform output
```

Key outputs include:
- `load_balancer_ip`: Public IP address of the load balancer
- `application_url`: URL to access your application
- `bastion_public_ip`: Public IP address of the bastion host for SSH access
- `ssh_access_instructions`: Instructions for accessing backend instances
- `adb_connection_strings`: Database connection strings (sensitive)

## Module Structure

```
.
├── main.tf                 # Main configuration
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── provider.tf            # Provider configuration
├── terraform.tfvars.example
└── modules/
    ├── network/           # VCN, subnets, gateways, VLANs
    ├── compute/           # Compute instances with VNICs
    ├── bastion/           # Bastion host for SSH access
    ├── database/          # Autonomous Database
    ├── load_balancer/     # Load balancer configuration
    ├── iam/               # IAM policies and dynamic groups
    └── dns/               # DNS zone and records
```

## Network Architecture

- **VCN**: `10.0.0.0/16`
- **Public Subnet**: `10.0.1.0/24` (Load Balancer)
- **Private Subnet**: `10.0.2.0/24` (Backend Instances)
- **Database Subnet**: `10.0.3.0/24` (Autonomous Database)
- **VLAN**: `10.0.10.0/24` (High-performance networking)

## Security

### Network Security

- Public subnet allows inbound HTTP (80), HTTPS (443), and SSH (22)
- SSH access to bastion can be restricted to specific CIDR blocks via `ssh_allowed_cidrs` variable
- Private subnet only allows traffic from public subnet on port 8080
- Database subnet only allows traffic from private subnet on database ports
- SSH access to backend instances via bastion host in public subnet only
- Backend instances isolated in private subnet with no direct internet access

### IAM Policies

- Dynamic groups for compute instances
- Policies for:
  - Object Storage access
  - Database access
  - Load balancer operations
  - Monitoring and logging
  - Secrets management

### Best Practices

1. **Secrets Management**: Never commit `terraform.tfvars` to version control
2. **State Management**: Use remote state storage (OCI Object Storage)
3. **Access Control**: Use least privilege principle for IAM policies
4. **Network Segmentation**: Keep databases in private subnets
5. **Monitoring**: Enable OCI monitoring and logging

## Customization

### Scaling Compute Instances

Modify `instance_count` in `terraform.tfvars`:

```hcl
instance_count = 4  # Scale to 4 instances
```

### Changing Instance Shape

Update `instance_shape`, `instance_ocpus`, and `instance_memory_in_gbs`:

```hcl
instance_shape         = "VM.Standard.E4.Flex"
instance_ocpus         = 2
instance_memory_in_gbs = 16
```

### Adding SSL/TLS

1. Obtain SSL certificate
2. Uncomment the HTTPS listener in `modules/load_balancer/main.tf`
3. Configure certificate details
4. Redeploy with `terraform apply`

### DNS Configuration

To configure a custom domain:

```hcl
dns_zone_name    = "example.com"
dns_record_domain = "api.example.com"
```

## Monitoring and Maintenance

### View Resource Status

```bash
# List all compute instances
oci compute instance list --compartment-id <compartment_ocid>

# Check load balancer health
oci lb load-balancer list --compartment-id <compartment_ocid>

# Database status
oci db autonomous-database list --compartment-id <compartment_ocid>
```

### Backup and Disaster Recovery

- **Database**: ADB automatically backs up daily
- **Terraform State**: Store in OCI Object Storage with versioning
- **Configuration**: Keep `terraform.tfvars` backed up securely

## SSH Access to Backend Instances

Backend instances are deployed in a private subnet for security. SSH access is provided through a bastion host in the public subnet.

### Security Configuration

By default, SSH access to the bastion host is allowed from any IP (`0.0.0.0/0`). **For production environments**, restrict this to specific IP addresses or CIDR blocks:

```hcl
# In terraform.tfvars
ssh_allowed_cidrs = ["1.2.3.4/32", "10.20.0.0/16"]  # Your IP(s)
```

### Getting the Bastion IP

After deployment, get the bastion host public IP:

```bash
terraform output bastion_public_ip
```

### SSH Access Methods

**Method 1: SSH with Agent Forwarding (For Interactive Use)**

```bash
# SSH to bastion with agent forwarding
ssh -A -i ~/.ssh/oci_instance_key opc@<bastion-public-ip>

# From bastion, SSH to any backend instance (key is forwarded)
ssh opc@<backend-private-ip>
```

**Method 2: SSH ProxyJump (One Command - Best for Automation)**

```bash
# SSH directly to backend instance via bastion in one command
ssh -i ~/.ssh/oci_instance_key -J opc@<bastion-public-ip> opc@<backend-private-ip>
```

**Method 3: SSH Config File (Best for Frequent Use)**

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

Then connect simply:

```bash
ssh backend-<backend-private-ip>
```

### View SSH Instructions

Get complete SSH access instructions with backend IPs:

```bash
terraform output ssh_access_instructions
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources. Make sure you have backups of any important data.

## Cost Optimization

1. Use Flex shapes for compute instances to adjust resources as needed
2. Enable auto-scaling for the database
3. Use Reserved Instances for production workloads
4. Monitor usage with OCI Cost Analysis

## Troubleshooting

### Common Issues

**Issue**: Terraform cannot authenticate
- Verify API key fingerprint matches OCI console
- Check private key path is correct
- Ensure user has necessary permissions

**Issue**: Resources fail to create
- Check compartment OCID is correct
- Verify availability domain exists in your region
- Ensure service limits are not exceeded

**Issue**: Cannot connect to instances
- Backend instances are in a private subnet and only accessible via the bastion host
- Use the bastion host public IP to connect: `ssh -i <key> opc@<bastion-ip>`
- From bastion, SSH to backend instances using their private IPs
- Alternatively, use SSH ProxyJump: `ssh -i <key> -J opc@<bastion-ip> opc@<backend-private-ip>`
- Verify security list rules allow SSH from bastion to backend instances
- Check NAT gateway is configured
- Ensure SSH key is correct

### Getting Help

- [OCI Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Forums](https://cloudcustomerconnect.oracle.com/resources/9c8fa8f96f/summary)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue in the repository
- Contact the infrastructure team

## Version History

- **v1.0.0** (2026-01-31): Initial release
  - VCN with multi-tier networking
  - Compute instances with auto-scaling
  - Autonomous Database
  - Load balancer with health checks
  - IAM policies and dynamic groups
  - Optional DNS configuration