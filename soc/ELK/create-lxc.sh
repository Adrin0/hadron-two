#!/bin/bash
# Run this script on the Proxmox host to create LXC 104 (ELK Stack).
# Must be run as root.

set -e

CTID=104
HOSTNAME="elk-stack"
MEMORY=8192
CORES=4
DISK="local-lvm:100"
BRIDGE="vmbr0"

# Update the path below to match your downloaded Ubuntu template.
# List available templates: pveam list local
TEMPLATE="local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

echo "Creating LXC $CTID ($HOSTNAME)..."

pct create $CTID $TEMPLATE \
  --hostname $HOSTNAME \
  --memory $MEMORY \
  --cores $CORES \
  --rootfs $DISK \
  --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
  --unprivileged 0 \
  --features nesting=1 \
  --ostype ubuntu \
  --start 0

echo "Container $CTID created."
echo ""
echo "Starting container..."
pct start $CTID

echo ""
echo "LXC $CTID is running. Get its IP with:"
echo "  pct exec $CTID -- hostname -I"
echo ""
echo "Next: push setup.sh into the container and run it:"
echo "  pct push $CTID setup.sh /root/setup.sh"
echo "  pct exec $CTID -- bash /root/setup.sh"
