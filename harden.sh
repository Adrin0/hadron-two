#!/bin/bash
# Harden a fresh Proxmox VE 8.x host using native tools.
# Run as root after bootstrap.sh.
#
# WARNING: This script enables the Proxmox firewall with a DROP inbound policy
#          and disables SSH password authentication. Before running:
#            1. Ensure your SSH public key is in /root/.ssh/authorized_keys.
#            2. Review the allowed ports below and add any you need.
#          A misconfigured firewall can lock you out of SSH and the web UI.

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: run this script as root." >&2
  exit 1
fi

NODENAME=$(hostname)
CLUSTER_FW="/etc/pve/firewall/cluster.fw"
NODE_FW="/etc/pve/nodes/${NODENAME}/host.fw"

# ── Preflight check ───────────────────────────────────────────────────────────

if [ ! -f /root/.ssh/authorized_keys ] || [ ! -s /root/.ssh/authorized_keys ]; then
  echo ""
  echo "ERROR: /root/.ssh/authorized_keys is missing or empty."
  echo "Add your SSH public key before running this script, or SSH password"
  echo "authentication will be disabled and you will lose remote access."
  echo ""
  echo "  ssh-copy-id root@<proxmox-ip>"
  echo "  # or manually:"
  echo "  mkdir -p /root/.ssh && echo '<your-pubkey>' >> /root/.ssh/authorized_keys"
  echo ""
  exit 1
fi

# ── 1. Proxmox built-in firewall ─────────────────────────────────────────────

echo "Configuring Proxmox firewall..."

mkdir -p "$(dirname "$CLUSTER_FW")" "$(dirname "$NODE_FW")"

# Datacenter-level firewall — applies to the host and all LXCs/VMs.
# Add any additional ports you need before the DROP policy takes effect.
cat > "$CLUSTER_FW" << EOF
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
# Management
IN ACCEPT -p tcp -dport 22    # SSH
IN ACCEPT -p tcp -dport 8006  # Proxmox web UI
# WireGuard VPN (adjust port if you changed the default)
IN ACCEPT -p udp -dport 51820
# ICMP (ping) — useful for network troubleshooting
IN ACCEPT -p icmp
EOF

# Node-level firewall enable
cat > "$NODE_FW" << EOF
[OPTIONS]
enable: 1
EOF

systemctl restart pve-firewall
echo "Proxmox firewall enabled."
echo "  Inbound policy : DROP"
echo "  Allowed ports  : 22 (SSH), 8006 (Proxmox UI), 51820/udp (WireGuard), ICMP"

# ── 2. SSH hardening ──────────────────────────────────────────────────────────

echo "Hardening SSH..."

SSHD_CONF="/etc/ssh/sshd_config"
cp -n "${SSHD_CONF}" "${SSHD_CONF}.bak"

# Apply each setting: update if the line exists (commented or not), append if absent.
apply_sshd_setting() {
  local KEY="$1"
  local VALUE="$2"
  if grep -qE "^#?${KEY}" "${SSHD_CONF}"; then
    sed -i -E "s|^#?${KEY}.*|${KEY} ${VALUE}|" "${SSHD_CONF}"
  else
    echo "${KEY} ${VALUE}" >> "${SSHD_CONF}"
  fi
}

apply_sshd_setting PermitRootLogin        prohibit-password
apply_sshd_setting PasswordAuthentication no
apply_sshd_setting MaxAuthTries           3
apply_sshd_setting LoginGraceTime         20
apply_sshd_setting X11Forwarding          no
apply_sshd_setting ClientAliveInterval    300
apply_sshd_setting ClientAliveCountMax    2

systemctl restart sshd
echo "SSH hardened."
echo "  Root login     : key only (password disabled)"
echo "  MaxAuthTries   : 3"

# ── 3. fail2ban ───────────────────────────────────────────────────────────────

echo "Installing and configuring fail2ban..."

apt install -y fail2ban

# Jail config for SSH and the Proxmox web UI
cat > /etc/fail2ban/jail.d/proxmox.conf << 'EOF'
[sshd]
enabled  = true
port     = ssh
maxretry = 3
bantime  = 1h
findtime = 10m

[proxmox-web]
enabled  = true
port     = 8006
filter   = proxmox
logpath  = /var/log/daemon.log
maxretry = 3
bantime  = 1h
findtime = 10m
EOF

# Filter for Proxmox authentication failures in daemon.log
cat > /etc/fail2ban/filter.d/proxmox.conf << 'EOF'
[Definition]
failregex = pvedaemon\[.*\]: authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =
EOF

systemctl enable --now fail2ban
echo "fail2ban enabled."
echo "  SSH            : ban after 3 failures in 10 min (1h ban)"
echo "  Proxmox web UI : ban after 3 failures in 10 min (1h ban)"

# ── 4. Kernel hardening (sysctl) ──────────────────────────────────────────────

echo "Applying sysctl hardening..."

# Note: rp_filter is intentionally omitted — strict mode (1) can break
# asymmetric routing on Proxmox bridge interfaces used by LXCs/VMs.
cat > /etc/sysctl.d/99-harden.conf << 'EOF'
# SYN flood protection
net.ipv4.tcp_syncookies = 1

# Ignore ICMP redirects (prevent MITM via routing manipulation)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Do not send ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log packets with impossible source addresses
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore broadcast pings (Smurf attack mitigation)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Protect against TCP time-wait assassination
net.ipv4.tcp_rfc1337 = 1

# NOTE: net.ipv4.ip_forward is intentionally left at its Proxmox default (1).
# Disabling it would break LXC/VM networking and WireGuard.
EOF

sysctl -p /etc/sysctl.d/99-harden.conf
echo "Kernel hardening applied."

# ── 5. Disable unused services ────────────────────────────────────────────────

echo "Disabling unused services..."

for SVC in rpcbind nfs-common; do
  if systemctl is-enabled "$SVC" &>/dev/null; then
    systemctl disable --now "$SVC"
    echo "  Disabled: $SVC"
  fi
done

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "Hardening complete."
echo ""
echo "Verify with:"
echo "  pve-firewall status"
echo "  fail2ban-client status"
echo "  sshd -T | grep -E 'permitrootlogin|passwordauthentication|maxauthtries'"
echo ""
echo "To open additional ports (e.g. WireGuard clients accessing LXC services),"
echo "edit ${CLUSTER_FW} and restart: systemctl restart pve-firewall"
