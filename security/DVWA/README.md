# DVWA — LXC 105

Damn Vulnerable Web Application running inside an unprivileged Proxmox LXC container. Serves as the pen-test target for the hadron-two security lab and ships logs to the ELK stack via Beats.

## Container Specs

| Field    | Value            |
|----------|------------------|
| LXC ID   | 105              |
| Hostname | dvwa             |
| CPU      | 2 cores          |
| RAM      | 2 GB             |
| Storage  | 25 GB            |
| Network  | vmbr0 (DHCP/LAN) |
| Type     | Unprivileged     |

## Setup

### Step 1 — Create the container (run on Proxmox host)

```bash
chmod +x create-lxc.sh
./create-lxc.sh
```

### Step 2 — Install DVWA and Beats (run inside LXC 105)

```bash
pct push 105 setup.sh /root/setup.sh
pct exec 105 -- bash /root/setup.sh
```

### Step 3 — Configure DVWA

1. Open `http://<LXC_105_IP>/DVWA/setup.php` in your browser.
2. Click **Create / Reset Database** to initialize.
3. Log in at `http://<LXC_105_IP>/DVWA/login.php` with `admin` / `password`.

### Step 4 — Configure Beats to ship to ELK

Edit the Beat config files to point to your ELK container IP. See [../docs/beats-config.md](../docs/beats-config.md) for the full configuration steps.

## Files

- [`create-lxc.sh`](create-lxc.sh) — Provisions LXC 105 from the Proxmox host
- [`setup.sh`](setup.sh) — Installs Apache, MySQL, PHP, DVWA, and Beats inside the container
