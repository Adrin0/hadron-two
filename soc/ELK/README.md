# ELK Stack — LXC 104

ELK Stack running inside a privileged Proxmox LXC container. Receives logs from Beats agents on other containers and exposes Kibana for visualization.

> Stack version: **ELK 7.17.x** (final 7.x LTS). See the [8.x migration guide](https://www.elastic.co/guide/en/elastic-stack/current/upgrading-elastic-stack.html) for future upgrades.

## Container Specs

| Field    | Value             |
|----------|-------------------|
| LXC ID   | 104               |
| Hostname | elk-stack         |
| CPU      | 4 cores           |
| RAM      | 8 GB              |
| Storage  | 100 GB            |
| Network  | vmbr0 (DHCP/LAN)  |
| Type     | Privileged (Docker requires this) |

## Ports (on LXC IP)

| Service       | Port  |
|---------------|-------|
| Kibana        | 5602  |
| Elasticsearch | 9201  |
| Logstash Beats| 5045  |

## Setup

### Step 1 — Create the container (run on Proxmox host)

```bash
chmod +x create-lxc.sh
./create-lxc.sh
```

### Step 2 — Install Docker and start ELK (run inside LXC 104)

```bash
pct exec 104 -- bash -s < setup.sh
```

Or SSH into the container and run:
```bash
chmod +x setup.sh
./setup.sh
```

### Step 3 — Verify

Access Kibana at `http://<LXC_104_IP>:5602`.

Check container status:
```bash
pct exec 104 -- docker compose -f /opt/elk/docker-compose.yml ps
```

## Files

- [`create-lxc.sh`](create-lxc.sh) — Provisions LXC 104 from the Proxmox host
- [`setup.sh`](setup.sh) — Installs Docker and starts the ELK stack inside the container
- [`docker-compose.yml`](docker-compose.yml) — ELK service definitions
- [`logstash.conf`](logstash.conf) — Logstash pipeline with AbuseIPDB enrichment
