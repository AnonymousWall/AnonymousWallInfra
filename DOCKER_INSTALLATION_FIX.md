# Docker Installation Fix for Existing Instances

## Problem
Existing backend instances provisioned before the Docker installation fix do not have Docker installed. This is because cloud-init only runs during instance creation.

## Solution Options

### Option 1: Manually Install Docker on Existing Instances (Quick Fix)

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

### Option 2: Re-provision Instances with Terraform (Recommended)

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
