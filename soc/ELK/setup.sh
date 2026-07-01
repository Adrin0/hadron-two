#!/bin/bash
# Run this script inside LXC 104 to install Docker and start the ELK stack.
# Must be run as root.

set -e

REPO_URL="https://github.com/adrin0/hadron-two"
INSTALL_DIR="/opt/elk"

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing dependencies..."
apt install -y curl git ca-certificates gnupg lsb-release

echo "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable --now docker

echo "Cloning repository..."
git clone $REPO_URL /tmp/hadron-two
mkdir -p $INSTALL_DIR
cp /tmp/hadron-two/soc/ELK/docker-compose.yml $INSTALL_DIR/
cp /tmp/hadron-two/soc/ELK/logstash.conf $INSTALL_DIR/

echo "Setting vm.max_map_count for Elasticsearch..."
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

echo "Starting ELK stack..."
cd $INSTALL_DIR
docker compose up -d

echo ""
echo "ELK stack is starting. Kibana will be available at:"
echo "  http://$(hostname -I | awk '{print $1}'):5602"
echo ""
echo "Logs: docker compose -f $INSTALL_DIR/docker-compose.yml logs -f"
