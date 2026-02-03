# Network Connectivity Troubleshooting Guide

## Issue: Packages Not Installing During Cloud-Init

If packages (podman, git, etc.) are not being installed on the backend instances, this indicates a network connectivity issue preventing the instances from reaching Oracle's package repositories.

## Debugging Steps

### 1. Check Cloud-Init Logs

SSH into the instance and check the cloud-init debug logs:

```bash
# SSH to instance via bastion
ssh -i ~/.ssh/oci_instance_key -J opc@<bastion-ip> opc@<backend-private-ip>

# Check cloud-init output
sudo cat /var/log/cloud-init-output.log

# Check our custom network debug log
sudo cat /var/log/cloud-init-debug.log

# Check cloud-init status
sudo cloud-init status --long
```

### 2. Verify Network Configuration

Check if the instance has proper network connectivity:

```bash
# Check network interfaces
ip addr show

# Check routing table
ip route show

# Check DNS resolution
cat /etc/resolv.conf
nslookup oracle.com

# Test internet connectivity
ping -c 3 8.8.8.8
ping -c 3 oracle.com
curl -I https://yum.oracle.com
```

### 3. Verify NAT Gateway Configuration

The backend instances are in a private subnet and rely on the NAT Gateway for internet access.

**Check in OCI Console:**
1. Go to Networking → Virtual Cloud Networks → Your VCN
2. Select "NAT Gateways" from the left menu
3. Verify the NAT Gateway is in "Available" state
4. Note the NAT Gateway OCID

**Verify Route Table:**
1. Go to "Route Tables" → Private Route Table
2. Ensure there's a route rule:
   - Destination CIDR: `0.0.0.0/0`
   - Target Type: NAT Gateway
   - Target: Your NAT Gateway

### 4. Verify Security Lists

**Private Subnet Security List:**
1. Go to "Security Lists" → Private Security List
2. Check Egress Rules - should have:
   - Destination: `0.0.0.0/0`
   - Protocol: All
   - Description: Allow all outbound

### 5. Common Issues and Solutions

#### Issue: NAT Gateway Not Created
**Symptom:** NAT Gateway doesn't exist or is in "Creating" state for too long

**Solution:** Check service limits and ensure NAT Gateway quota is available
```bash
oci limits resource-availability get \
  --compartment-id <compartment_ocid> \
  --service-name vcn \
  --limit-name nat-gateway-count
```

#### Issue: Route Table Not Associated
**Symptom:** Private subnet doesn't have the correct route table

**Solution:** Verify in Terraform or OCI Console that the private subnet uses the private route table

#### Issue: Security List Blocking Traffic
**Symptom:** Can ping but can't access yum repositories

**Solution:** Ensure egress rules allow all traffic or at least HTTPS (443)

#### Issue: Service Gateway Missing
**Symptom:** Cannot access Oracle Services Network

**Solution:** Verify Service Gateway is created and added to private route table
```hcl
# Should be in private route table
route_rules {
  destination       = "<oracle_services_cidr>"
  destination_type  = "SERVICE_CIDR_BLOCK"
  network_entity_id = oci_core_service_gateway.main.id
}
```

### 6. Manual Package Installation Test

After fixing network issues, test package installation manually:

```bash
# Update package cache
sudo yum clean all
sudo yum makecache

# List available repositories
sudo yum repolist

# Try installing a package
sudo yum install -y podman

# Check if podman was installed
podman --version
```

### 7. Re-run Cloud-Init (After Network Fix)

If you fixed the network issue and want to retry cloud-init:

```bash
# Clean cloud-init
sudo cloud-init clean --logs

# Re-run cloud-init
sudo cloud-init init
sudo cloud-init modules --mode config
sudo cloud-init modules --mode final

# Check status
sudo cloud-init status --long
```

## Terraform Verification

Ensure your Terraform configuration has:

1. **NAT Gateway** in network module
2. **Private Route Table** with NAT Gateway as default route
3. **Service Gateway** for Oracle Services Network (optional but recommended)
4. **Security List** allowing all egress traffic from private subnet

## Getting Help

When reporting issues, include:
1. Output from `/var/log/cloud-init-debug.log`
2. Output from `/var/log/cloud-init-output.log`
3. Output from `sudo cloud-init status --long`
4. Network configuration (`ip addr`, `ip route`, `/etc/resolv.conf`)
5. NAT Gateway state from OCI Console
6. Route table configuration from OCI Console
