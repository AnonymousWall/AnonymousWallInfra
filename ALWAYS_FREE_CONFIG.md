# OCI Always Free Configuration Guide

This document explains the changes made to configure the infrastructure to use OCI Always Free resources and recommendations for additional optimizations.

## Changes Made

### 1. MySQL Database System - COMPLETED ✓
The MySQL database module has been updated to use a standard configuration:

**Changes:**
- Set `mysql_shape_name` to define the VM shape for the database instance
- Set `mysql_data_storage_size_in_gb` for storage allocation
- Configured `mysql_subnet_id` for VCN integration (required for MySQL)
- Removed ADB-specific attributes:
  - `is_free_tier` (MySQL does not have an Always Free tier)
  - `is_mtls_connection_required` (MySQL uses standard authentication)
  - Public endpoint only restrictions (MySQL requires VCN integration)
  - Wallet authentication (MySQL uses username/password authentication)

**MySQL Database System Configuration:**
- **Note:** MySQL Database System is **NOT** part of OCI Always Free tier
- Requires a paid OCI account or credits
- Minimum configuration: VM.Standard.E2.1 shape (1 OCPU, 8 GB RAM)
- Storage: Minimum 50 GB, expandable up to 64 TB
- **VCN integration required** - must be deployed in a private subnet
- Supports standard MySQL authentication (username/password)
- Accessible via private IP within VCN or through bastion/VPN

### 2. Compute Instances - RECOMMENDATIONS

**Current Configuration:**
- Shape: `VM.Standard.E4.Flex`
- OCPUs: 1
- Memory: 8 GB
- Count: 2 instances
- **Status: NOT Always Free compatible**

**Always Free Options:**

#### Option A: VM.Standard.E2.1.Micro (AMD)
- Up to 2 instances
- 1 OCPU per instance
- 1 GB RAM per instance
- **Limitation:** Very limited memory (1 GB)

#### Option B: VM.Standard.A1.Flex (Arm - RECOMMENDED)
- Up to 4 instances
- Total quota: 4 OCPUs and 24 GB RAM (3,000 OCPU hours and 18,000 GB hours per month)
- Flexible distribution across instances

**Recommended Configuration for Always Free:**
```hcl
instance_shape = "VM.Standard.A1.Flex"
instance_ocpus = 1
instance_memory_in_gbs = 6  # Changed from 8 GB to 6 GB
instance_count = 2  # Can use up to 4 instances
```

This would use 2 OCPUs and 12 GB total, leaving room for 2 more OCPUs and 12 GB if needed.

**To apply these changes:**
1. Update `terraform.tfvars` or your variable values:
   - `instance_shape = "VM.Standard.A1.Flex"`
   - `instance_memory_in_gbs = 6`
2. Ensure your application can run on Arm architecture
3. Update the instance image to use an Arm-compatible OS image

### 3. Load Balancer - RECOMMENDATIONS

**Current Configuration:**
- Shape: flexible
- Min bandwidth: 10 Mbps
- Max bandwidth: 100 Mbps
- **Status: Partially compatible with Always Free**

**Always Free Limits:**
- 1 load balancer per account
- Fixed 10 Mbps bandwidth
- Cannot use flexible bandwidth settings

**Recommended Configuration for Always Free:**
```hcl
lb_shape = "flexible"
lb_min_bandwidth_mbps = 10
lb_max_bandwidth_mbps = 10  # Changed from 100 to 10
```

Note: The current configuration already uses `lb_min_bandwidth_mbps = 10` as the minimum, which is compatible. However, setting `lb_max_bandwidth_mbps = 10` ensures you're using the Always Free tier.

**To apply these changes:**
Update `terraform.tfvars` or your variable values:
- `lb_max_bandwidth_mbps = 10`

### 4. Network Resources - COMPATIBLE ✓

**Current Configuration:**
- VCN with public, private, and database subnets
- **Status: Compatible with Always Free**

**Always Free Limits:**
- 2 VCNs per account
- Current configuration uses 1 VCN ✓

**Important Note:**
- VCN DNS labels must be 1-15 characters long and alphanumeric only
- The configuration automatically generates a DNS label using the first 12 characters of the app name: `lower(substr(replace(var.app_name, "-", ""), 0, 12))`
- For "anonymouswall", this becomes "anonymouswal" (12 chars)
- **Recommendation**: Keep your `app_name` variable concise (≤15 characters) to avoid truncation issues

**Removed Resources:**
- VLAN resource has been removed as VLANs are not available in the Always Free tier (requires VMware SKU whitelisting)

**Important:** The database subnet is required and actively used by the MySQL Database System for VCN integration. MySQL instances must be deployed in a private subnet and cannot use public endpoints directly.

## Summary of Terraform Variable Updates

To make the entire infrastructure Always Free compatible, update your `terraform.tfvars` file:

```hcl
# Compute - Use Arm-based Always Free instances
instance_shape = "VM.Standard.A1.Flex"
instance_ocpus = 1
instance_memory_in_gbs = 6  # Max 24 GB total across all instances
instance_count = 2  # Up to 4 instances allowed

# Load Balancer - Use Always Free limits
lb_min_bandwidth_mbps = 10
lb_max_bandwidth_mbps = 10  # Fixed at 10 Mbps for Always Free

# MySQL Database configuration
# Note: MySQL Database System is NOT part of Always Free tier
# Requires paid account or credits. Consider alternative Always Free database options:
# - Autonomous Database (up to 2 instances with Always Free)
# - Or use self-managed MySQL on Always Free Compute instances
```

## Additional Always Free Resources

The following Always Free resources are available and could be added to the infrastructure:

1. **Block Volumes**: 2 volumes, 200 GB total
2. **Object Storage**: 10 GB
3. **Archive Storage**: 10 GB
4. **Notifications**: 1 million per month
5. **Monitoring**: 500 million ingestion datapoints, 1 billion retrieval datapoints
6. **Service Connector Hub**: 2 service connectors

## Important Notes

1. **Regional Availability**: Always Free resources are only available in your home region
2. **Account Limits**: These limits apply per OCI account/tenancy
3. **No Expiration**: Always Free resources do not expire
4. **Upgrade Path**: You can upgrade to paid resources at any time by changing the configuration

## Testing the Configuration

After making changes:

```bash
# Initialize Terraform
terraform init

# Validate the configuration
terraform validate

# Review the plan
terraform plan

# Apply the changes (when ready)
terraform apply
```

## References

- [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [OCI Terraform Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Compute Shapes](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm)
