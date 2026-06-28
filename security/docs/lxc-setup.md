# LXC Container Setup Reference

General reference for creating and managing Proxmox LXC containers in hadron-two.

## 1. Download an Ubuntu Template

From the Proxmox host:
```bash
pveam update
pveam available | grep ubuntu
pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```

Or via the Proxmox web UI: **Node → local → CT Templates → Templates → ubuntu-24.04**.

## 2. Create a Container

```bash
pct create <CTID> <template> \
  --hostname <name> \
  --memory <MB> \
  --cores <n> \
  --rootfs local-lvm:<GB> \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged <0|1> \
  --features nesting=1 \
  --ostype ubuntu
```

| Flag              | Notes                                                              |
|-------------------|--------------------------------------------------------------------|
| `--unprivileged 0`| **Privileged** — required for LXCs that run Docker (LXC 104)      |
| `--unprivileged 1`| **Unprivileged** — use for all other containers (safer default)    |
| `--features nesting=1` | Required for Docker-inside-LXC (must pair with `unprivileged 0`) |

## 3. Start / Stop / Delete

```bash
pct start <CTID>
pct stop <CTID>
pct destroy <CTID>
```

## 4. Access a Running Container

```bash
# Open a shell directly
pct exec <CTID> -- bash

# Push a local file into the container
pct push <CTID> ./local-file.sh /root/local-file.sh

# Pull a file out
pct pull <CTID> /etc/someconfig ./someconfig
```

## 5. Get the Container's IP

```bash
pct exec <CTID> -- hostname -I
```

## 6. Check Resource Usage

```bash
pct list
pct status <CTID>
```

## 7. Docker Inside LXC (LXC 104 only)

LXC 104 (elk-stack) is privileged with `nesting=1` so Docker can run inside it. After the container is created:

```bash
pct exec 104 -- docker ps
pct exec 104 -- docker compose -f /opt/elk/docker-compose.yml ps
```

If Docker fails to start inside the LXC, verify:
```bash
# Inside LXC 104
systemctl status docker
# On Proxmox host — confirm container is privileged:
pct config 104 | grep unprivileged
# Should return: unprivileged: 0
```
