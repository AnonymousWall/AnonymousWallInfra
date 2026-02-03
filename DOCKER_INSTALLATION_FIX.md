# Docker Installation Fix for Existing Instances

## Problem
Existing backend instances provisioned before the Docker installation fix do not have Docker installed. This is because cloud-init only runs during instance creation.

## Important: Network Connectivity Check

Backend instances are in a **private subnet** and require NAT Gateway for internet access. Before attempting manual installation, verify network connectivity:

```bash
# Test internet connectivity
ping -c 3 8.8.8.8

# Test DNS resolution
nslookup google.com

# Test package repository access
sudo dnf check-update
```

If these commands fail or hang:
1. Verify NAT Gateway is properly configured in Terraform
2. Check route tables allow traffic to NAT Gateway
3. Verify security lists allow outbound traffic
4. **Strongly Recommended**: Use Option 2 (Re-provision) instead - it's more reliable and ensures proper configuration

## Solution Options

### ⭐ Option 2: Re-provision Instances with Terraform (Recommended)

**This is the most reliable approach**, especially if experiencing network issues with manual installation.

This option will recreate the instances with the proper Docker installation from cloud-init.

**⚠️ Warning**: This will destroy and recreate the instances, causing downtime. Back up any data first.

#### Step 1: Taint the existing instances

Mark the instances for recreation:

```bash
# List instance resources
terraform state list | grep oci_core_instance.backend

# Taint each instance (replace [INDEX] with 0, 1, etc.)
terraform taint 'module.compute.oci_core_instance.backend[0]'
terraform taint 'module.compute.oci_core_instance.backend[1]'
# ... repeat for all backend instances
```

#### Step 2: Apply the changes

```bash
# Review the plan
terraform plan

# Apply the changes to recreate instances
terraform apply
```

The new instances will have Docker properly installed via cloud-init.

### Option 3: Destroy and Recreate Specific Instances

If you need more control:

```bash
# Target specific instance for replacement
terraform destroy -target='module.compute.oci_core_instance.backend[0]'
terraform apply -target='module.compute.oci_core_instance.backend[0]'
```

### Option 1: Manually Install Docker on Existing Instances (Quick Fix)

**⚠️ Note**: This requires the instance to have working internet connectivity through the NAT Gateway. If `dnf install` commands hang, use Option 2 (Re-provision) instead.

SSH to each backend instance and run the following commands:

```bash
# Add yum-utils if not present
sudo dnf install -y yum-utils

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Remove conflicting packages (Podman, etc.)
sudo dnf remove -y docker docker-* podman buildah runc || true

# Install Docker CE and related packages
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add opc user to docker group
sudo usermod -aG docker opc

# Verify installation
docker --version
docker compose version

# Log out and back in for group changes to take effect
```

After logging back in, test Docker:
```bash
docker run hello-world
```

## Verification

After installation (either method), verify Docker is working:

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Test Docker
docker run hello-world

# Check Docker service status
sudo systemctl status docker

# Verify user is in docker group
groups | grep docker
```

## Why This Happened

The original cloud-init configuration attempted to install Docker using package names (`docker`, `docker-compose`) that don't exist in Oracle Linux 9 repositories. The fix:

1. Adds Docker's official repository
2. Removes conflicting packages (Podman)
3. Installs Docker CE with correct package names
4. Uses Docker Compose v2 (plugin)

**Important**: Cloud-init only runs when an instance is **first created**. Updating the Terraform configuration does not automatically update existing instances.

## Troubleshooting

### Issue: `dnf install` commands hang or timeout

**Root Cause**: Backend instances are in a private subnet and require NAT Gateway for internet access.

**Solutions**:

1. **Check if cloud-init is still running**:
   ```bash
   # Check cloud-init status
   sudo cloud-init status
   
   # If it shows "running", wait for it to complete
   # Check logs to see what it's doing
   sudo tail -f /var/log/cloud-init-output.log
   ```

2. **Verify network connectivity**:
   ```bash
   # Test basic connectivity
   ping -c 3 8.8.8.8
   
   # Test DNS
   nslookup download.docker.com
   
   # Check if dnf can reach repos
   sudo dnf clean all
   sudo timeout 30 dnf check-update
   ```

3. **Check for locked package manager**:
   ```bash
   # Check if dnf is locked by another process
   sudo ps aux | grep dnf
   sudo ps aux | grep yum
   
   # If cloud-init is running, wait for it to complete
   # Or check if there are stale locks
   sudo rm -f /var/run/yum.pid
   sudo rm -f /var/lib/dnf/rpmdb_lock_*
   ```

4. **Verify NAT Gateway configuration**:
   - Go to OCI Console → Networking → Virtual Cloud Networks
   - Select your VCN → Route Tables
   - Check private subnet route table has route to NAT Gateway (0.0.0.0/0 → NAT Gateway)
   - Check NAT Gateway is in "Available" state

5. **If network issues persist**:
   - **Best solution**: Re-provision the instance with Terraform (Option 2)
   - This ensures proper network configuration and Docker installation via cloud-init
   - Manual installation requires working outbound internet connectivity

### Issue: Commands work but Docker still not installed after following steps

- Make sure to log out and back in after adding user to docker group
- Check Docker service: `sudo systemctl status docker`
- Check Docker installation: `sudo dnf list installed | grep docker`
- Review installation logs: `sudo cat /var/log/cloud-init-output.log`
