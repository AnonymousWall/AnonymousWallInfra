#!/bin/bash
# Script to distribute bastion's SSH public key to backend instances
# Run this after the infrastructure is deployed

set -e

echo "===================================================="
echo "Bastion SSH Key Distribution Script"
echo "===================================================="
echo ""

# Check if required tools are available
if ! command -v terraform &> /dev/null; then
    echo "Error: terraform command not found"
    exit 1
fi

if ! command -v ssh &> /dev/null; then
    echo "Error: ssh command not found"
    exit 1
fi

# Get Terraform outputs
echo "Fetching infrastructure information..."
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
BACKEND_IPS=$(terraform output -json backend_private_ips 2>/dev/null | jq -r '.[]')

if [ -z "$BASTION_IP" ]; then
    echo "Error: Could not get bastion IP from terraform output"
    exit 1
fi

echo "Bastion IP: $BASTION_IP"
echo "Backend IPs: $BACKEND_IPS"
echo ""

# Prompt for SSH key path
read -p "Enter path to your SSH private key [~/.ssh/id_rsa]: " SSH_KEY
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}

if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

echo ""
echo "Step 1: Fetching bastion's public key..."
BASTION_PUBKEY=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no opc@"$BASTION_IP" "cat /home/opc/.ssh/id_ed25519.pub" 2>/dev/null)

if [ -z "$BASTION_PUBKEY" ]; then
    echo "Error: Could not fetch bastion's public key"
    echo "Make sure the bastion has finished initializing (wait a few minutes after deployment)"
    exit 1
fi

echo "✓ Bastion public key retrieved:"
echo "  $BASTION_PUBKEY"
echo ""

echo "Step 2: Adding bastion's key to backend instances..."
for BACKEND_IP in $BACKEND_IPS; do
    echo "  Processing backend: $BACKEND_IP"
    
    # SSH through bastion to backend and add the key
    ssh -i "$SSH_KEY" -A -o StrictHostKeyChecking=no -J opc@"$BASTION_IP" opc@"$BACKEND_IP" \
        "echo '$BASTION_PUBKEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "    ✓ Key added successfully"
    else
        echo "    ✗ Failed to add key (you may need to use -A flag with your initial SSH)"
    fi
done

echo ""
echo "===================================================="
echo "Setup complete!"
echo "===================================================="
echo ""
echo "You can now SSH from bastion to backend instances:"
echo "  1. SSH to bastion: ssh -i $SSH_KEY opc@$BASTION_IP"
echo "  2. SSH to backend: ssh opc@<backend-ip>"
echo ""
