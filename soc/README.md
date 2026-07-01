# hadron-two SOC Layer — Progress Report

A Proxmox-based security monitoring layer extending [soc-lab](https://github.com/adrin0/soc-lab): ELK Stack for centralized log ingestion, DVWA as a pen-test target, and AI-enhanced alerting via n8n + Ollama — all running as LXC containers on a single bare-metal host.

---

## Overview

soc-lab established the pattern: run DVWA to generate attack traffic, ship logs to an ELK stack, and analyze them in Kibana. hadron-two rebuilds that same pipeline on Proxmox instead of VirtualBox, replaces full VMs with lightweight LXC containers, and adds an AI layer that generates plain-English incident summaries from Logstash alerts using a locally-hosted LLM.

**Hardware:** Ryzen 8-core, 47 GB RAM, RTX 2060 SUPER (8 GB VRAM)

---

## Architecture

### Container Map

| LXC ID | Hostname   | CPU | RAM  | Role                                          | Status   |
|--------|------------|-----|------|-----------------------------------------------|----------|
| 100    | ollama     | 4   | 8 GB | GPU-accelerated LLM inference (Ollama)        | Running  |
| 101    | open-webui | 2   | 4 GB | Web chat UI + RAG (Open WebUI)                | Running  |
| 102    | n8n        | 2   | 4 GB | Workflow automation + AI log summarizer       | Running  |
| 103    | qdrant     | 2   | 4 GB | Vector database for semantic search           | Planned  |
| 104    | elk-stack  | 4   | 8 GB | ELK Stack — log ingestion + Kibana dashboards | Planned  |
| 105    | dvwa       | 2   | 2 GB | DVWA — pen-test target + log source           | Planned  |

### Network

All containers share the Proxmox LAN bridge (`vmbr0`). DHCP-assigned IPs, no NAT. WireGuard runs on the Proxmox host for remote access over `10.10.0.0/24`.

```
Internet
    │
    ▼
Proxmox Host (vmbr0 bridge)
    ├── LXC 100  ollama      :11434
    ├── LXC 101  open-webui  :3000
    ├── LXC 102  n8n         :5678
    ├── LXC 103  qdrant      :6333
    ├── LXC 104  elk-stack   :5602 (Kibana)  :9201 (ES)  :5045 (Beats input)
    └── LXC 105  dvwa        :80
```

### Log Flow

```
LXC 105 (DVWA)
  ├─ Filebeat   ──┐
  ├─ Metricbeat ──┤──► LXC 104 (ELK) :5045 ──► Logstash ──► Elasticsearch
  └─ Packetbeat ──┘                                               │
                                                               Kibana :5602
```

### AI-Enhanced Alerting (Planned)

```
Logstash alert webhook
    │
    ▼
LXC 102 (n8n) ──► LXC 100 (Ollama) ──► Plain-English incident summary
                                              │
                                         Notification (email / webhook)
```

---

## What Was Built

### ELK Stack — LXC 104 (`soc/ELK/`)

A Docker Compose stack running Elasticsearch, Logstash, and Kibana inside a privileged LXC container (privileged + `nesting=1` required for Docker).

**`docker-compose.yml`** defines three services pinned to Elastic 7.17.26:
- Elasticsearch on `:9201` with a persistent `esdata` volume
- Logstash on `:5045` (Beats input) with the pipeline config bind-mounted
- Kibana on `:5602` pointed at the internal Elasticsearch service

**`logstash.conf`** routes incoming Beats traffic to separate daily indices:

```
input  { beats { port => 5045 } }

filter {
  metricbeat  → add_field source_type: system_metrics
  packetbeat  → add_field source_type: network_traffic
}

output {
  filebeat   → index filebeat-%{+YYYY.MM.dd}
  metricbeat → index metricbeat-%{+YYYY.MM.dd}
  packetbeat → index packetbeat-%{+YYYY.MM.dd}
}
```

**`setup.sh`** is a single-run provisioning script that runs inside LXC 104:
- Installs Docker CE from the official APT repository
- Clones this repo and copies the Compose stack to `/opt/elk/`
- Sets `vm.max_map_count=262144` (Elasticsearch requirement, persisted to `/etc/sysctl.conf`)
- Runs `docker compose up -d`

**`create-lxc.sh`** creates LXC 104 on the Proxmox host with the correct flags (`--unprivileged 0`, `--features nesting=1`).

---

### DVWA — LXC 105 (`soc/DVWA/`)

A standard LAMP stack running DVWA as a pen-test target, with all three Elastic Beats installed to forward logs to LXC 104.

**`setup.sh`** runs inside LXC 105 and:
- Installs Apache, MySQL, PHP, and required extensions
- Adds the Elastic 7.x APT repository and installs `filebeat`, `metricbeat`, `packetbeat`
- Clones DVWA from the official repo into `/var/www/html/` with open permissions
- Enables all three Beat services (start deferred to manual configuration step)

Post-install steps (manual):
1. Set MySQL credentials and create the `dvwa` database user
2. Update `DVWA/config/config.inc.php` with those credentials
3. Configure Beats YAML files to point at LXC 104's IP (see below)
4. Complete DVWA initialization at `/DVWA/setup.php`

**`create-lxc.sh`** creates LXC 105 as unprivileged (no Docker needed).

---

### Beats Configuration (`soc/docs/beats-config.md`)

Each Beat on LXC 105 is configured to output directly to Elasticsearch on LXC 104 (`:9201`) and load pre-built Kibana dashboards on first run.

Key config block (same pattern for filebeat, metricbeat, packetbeat):

```yaml
output.elasticsearch:
  hosts: ["<ELK_LXC_IP>:9201"]

setup.kibana:
  host: "<ELK_LXC_IP>:5602"
```

Dashboard setup command (run once per Beat):
```bash
sudo filebeat setup --dashboards
sudo metricbeat setup --dashboards
sudo packetbeat setup --dashboards
```

Validation:
```bash
sudo filebeat test output    # confirm ES reachable
sudo metricbeat test output
sudo packetbeat test output
```

---

## Progression from soc-lab

| Aspect         | soc-lab (VirtualBox)   | hadron-two (Proxmox)              |
|----------------|------------------------|-----------------------------------|
| Hypervisor     | VirtualBox             | Proxmox VE                        |
| Container type | Full VMs               | LXC containers                    |
| Networking     | Host-only + NAT        | Single LAN bridge (vmbr0)         |
| Remote access  | None (local only)      | WireGuard VPN                     |
| AI integration | None                   | Ollama + n8n for log analysis     |
| Storage        | Per-VM VMDK            | Proxmox storage pool (local-lvm)  |

The core pipeline (DVWA → Beats → Logstash → Elasticsearch → Kibana) is identical to soc-lab. The infrastructure layer is rebuilt for production-grade bare-metal use, and an AI alerting path is added on top.

---

## Current Status

| Component                     | Status    |
|-------------------------------|-----------|
| Ollama (LXC 100)              | Running   |
| Open WebUI (LXC 101)          | Running   |
| n8n (LXC 102)                 | Running   |
| ELK Stack provisioning scripts | Done      |
| DVWA provisioning scripts      | Done      |
| Beats configuration docs       | Done      |
| ELK Stack deployment (LXC 104) | Planned   |
| DVWA deployment (LXC 105)      | Planned   |
| Beats forwarding live          | Planned   |
| n8n → Ollama alert pipeline    | Planned   |
| Qdrant / RAG (LXC 103)        | Planned   |

---

## Repository Layout

```
soc/
├── README.md               # Setup order and overview
├── ELK/
│   ├── create-lxc.sh       # Create LXC 104 on Proxmox host
│   ├── docker-compose.yml  # Elasticsearch + Logstash + Kibana
│   ├── logstash.conf       # Beats routing pipeline
│   └── setup.sh            # Provision Docker + start ELK inside LXC 104
├── DVWA/
│   ├── create-lxc.sh       # Create LXC 105 on Proxmox host
│   └── setup.sh            # Install LAMP + DVWA + Beats inside LXC 105
└── docs/
    ├── architecture.md         # Container map, network diagram, log flow
    ├── beats-config.md         # Per-beat YAML config and dashboard setup
    ├── lxc-setup.md            # General Proxmox LXC reference
    └── screenshot-deliverables.md  # Milestone screenshot checklist
```
