#!/bin/bash
# Run on a fresh Proxmox VE host (Debian 12) after cloning this repo.
# Installs Node.js LTS, Claude Code, and optionally sets ANTHROPIC_API_KEY.
# Must be run as root.

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: run this script as root." >&2
  exit 1
fi

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing prerequisites..."
apt install -y \
  curl \
  git \
  ca-certificates

echo "Adding NodeSource LTS repository..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

echo "Installing Node.js..."
apt install -y nodejs

echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo ""
echo "Claude Code installed: $(claude --version 2>/dev/null || echo 'installed')"
echo ""

read -r -s -p "Enter your ANTHROPIC_API_KEY (leave blank to skip): " API_KEY
echo ""

if [ -n "$API_KEY" ]; then
  if grep -q "^ANTHROPIC_API_KEY=" /etc/environment 2>/dev/null; then
    sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=\"$API_KEY\"|" /etc/environment
    echo "Updated ANTHROPIC_API_KEY in /etc/environment."
  else
    echo "ANTHROPIC_API_KEY=\"$API_KEY\"" >> /etc/environment
    echo "Added ANTHROPIC_API_KEY to /etc/environment."
  fi
else
  echo "Skipped API key setup. Set it manually:"
  echo "  echo 'ANTHROPIC_API_KEY=\"sk-ant-...\"' >> /etc/environment"
fi

echo ""
echo "Bootstrap complete."
echo ""
echo "To start using Claude Code:"
echo "  source /etc/environment"
echo "  claude"
echo ""
echo "To provision the ELK stack (LXC 104), run:"
echo "  bash soc/ELK/setup.sh"
echo ""
echo "To provision DVWA (LXC 105), run:"
echo "  bash soc/DVWA/setup.sh"
