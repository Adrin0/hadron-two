#!/bin/bash
# Set up WireGuard VPN on a Proxmox VE 8.x host for remote access.
# Run as root after harden.sh. Generates server + first client keypair,
# writes /etc/wireguard/wg0.conf, and optionally configures DuckDNS DDNS.
# Must be run as root.

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: run this script as root." >&2
  exit 1
fi

WG_DIR="/etc/wireguard"
WG_CONF="${WG_DIR}/wg0.conf"
WG_IFACE="wg0"
WG_PORT="51820"
WG_SERVER_IP="10.10.0.1"
WG_CLIENT_IP="10.10.0.2"
WG_SUBNET="10.10.0.0/24"
LAN_IFACE="vmbr0"

# ── 1. Install WireGuard ──────────────────────────────────────────────────────

echo "Installing WireGuard..."
apt update
apt install -y wireguard

# ── 2. Generate server keypair ────────────────────────────────────────────────

echo "Generating server keypair..."
mkdir -p "$WG_DIR"
chmod 700 "$WG_DIR"

SERVER_PRIVKEY=$(wg genkey)
SERVER_PUBKEY=$(echo "$SERVER_PRIVKEY" | wg pubkey)

echo "$SERVER_PRIVKEY" > "${WG_DIR}/server.key"
echo "$SERVER_PUBKEY"  > "${WG_DIR}/server.pub"
chmod 600 "${WG_DIR}/server.key"

# ── 3. Generate first client keypair ─────────────────────────────────────────

echo "Generating client keypair..."
CLIENT_PRIVKEY=$(wg genkey)
CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)

echo "$CLIENT_PRIVKEY" > "${WG_DIR}/client.key"
echo "$CLIENT_PUBKEY"  > "${WG_DIR}/client.pub"
chmod 600 "${WG_DIR}/client.key"

# ── 4. Write wg0.conf ─────────────────────────────────────────────────────────

if [ -f "$WG_CONF" ]; then
  echo "Backing up existing ${WG_CONF} to ${WG_CONF}.bak..."
  cp "$WG_CONF" "${WG_CONF}.bak"
fi

cat > "$WG_CONF" << EOF
[Interface]
Address    = ${WG_SERVER_IP}/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIVKEY}

# NAT: forward VPN traffic to LXC containers on the LAN bridge.
PostUp   = iptables -A FORWARD -i ${WG_IFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${LAN_IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${WG_IFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${LAN_IFACE} -j MASQUERADE

[Peer]
# Client 1
PublicKey  = ${CLIENT_PUBKEY}
AllowedIPs = ${WG_CLIENT_IP}/32
EOF

chmod 600 "$WG_CONF"

# ── 5. Enable and start WireGuard ─────────────────────────────────────────────

echo "Enabling wg-quick@${WG_IFACE}..."
systemctl enable --now "wg-quick@${WG_IFACE}"

# ── 6. Optional: DuckDNS DDNS ─────────────────────────────────────────────────

echo ""
read -r -p "Set up DuckDNS for dynamic IP? (y/n): " SETUP_DDNS

if [[ "$SETUP_DDNS" =~ ^[Yy]$ ]]; then
  read -r -p "DuckDNS subdomain (e.g. 'myhomelab' for myhomelab.duckdns.org): " DUCK_SUBDOMAIN
  read -r -p "DuckDNS token: " DUCK_TOKEN

  cat > /etc/cron.d/duckdns << EOF
*/5 * * * * root curl -s "https://www.duckdns.org/update?domains=${DUCK_SUBDOMAIN}&token=${DUCK_TOKEN}&ip=" >> /var/log/duckdns.log 2>&1
EOF

  chmod 644 /etc/cron.d/duckdns

  # Run once now to confirm it works
  curl -s "https://www.duckdns.org/update?domains=${DUCK_SUBDOMAIN}&token=${DUCK_TOKEN}&ip=" >> /var/log/duckdns.log 2>&1
  echo "DuckDNS configured. Updates run every 5 minutes. Log: /var/log/duckdns.log"

  WG_ENDPOINT="${DUCK_SUBDOMAIN}.duckdns.org:${WG_PORT}"
else
  PUBLIC_IP=$(curl -s https://api.ipify.org || echo "<your-public-ip>")
  WG_ENDPOINT="${PUBLIC_IP}:${WG_PORT}"
  echo "Skipped DuckDNS. Using current public IP: ${PUBLIC_IP}"
fi

# ── 7. Print client config ────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  WireGuard client config — paste into the WireGuard app on your device"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[Interface]"
echo "Address    = ${WG_CLIENT_IP}/32"
echo "PrivateKey = ${CLIENT_PRIVKEY}"
echo "DNS        = 1.1.1.1"
echo ""
echo "[Peer]"
echo "PublicKey           = ${SERVER_PUBKEY}"
echo "Endpoint            = ${WG_ENDPOINT}"
echo "AllowedIPs          = ${WG_SUBNET}"
echo "PersistentKeepalive = 25"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "IMPORTANT: Copy the client config above now."
echo "Then delete the client private key from this server:"
echo "  rm ${WG_DIR}/client.key"
echo ""
echo "Verify the tunnel is up:"
echo "  wg show"
echo ""
echo "To add more clients, see the README Remote Access section."
echo ""
echo "Router step (manual): Forward UDP port ${WG_PORT} to this host's LAN IP:"
HOST_IP=$(hostname -I | awk '{print $1}')
echo "  $(hostname) LAN IP: ${HOST_IP}"
