# hadron-two
# Proxmox Home Lab with AI Stack, ELK Security Monitoring, and DVWA

## Table of Contents
1. [Project Overview](#project-overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Quick Start](#quick-start)
5. [Installation and Setup](#installation-and-setup)
   - [Prerequisites](#prerequisites)
   - [Step 1: Bootstrap the Host](#step-1-bootstrap-the-host)
   - [Step 2: Create LXC Containers](#step-2-create-lxc-containers)
   - [Step 3: Set Up ELK Stack](#step-3-set-up-elk-stack)
   - [Step 4: Set Up DVWA](#step-4-set-up-dvwa)
   - [Step 5: Configure Beats](#step-5-configure-beats)
   - [Step 6: Configure Kibana Dashboards](#step-6-configure-kibana-dashboards)
6. [Attack Scenarios](#attack-scenarios)
7. [AI-Enhanced Alerting](#ai-enhanced-alerting)
8. [Docs](#docs)

---

## Project Overview

hadron-two is a self-hosted bare-metal lab running on Proxmox VE. It extends [soc-lab](https://github.com/adrin0/soc-lab) — migrating the ELK + DVWA security monitoring setup from VirtualBox VMs to lightweight LXC containers — and adds a locally-hosted AI stack (Ollama, Open WebUI, n8n) for GPU-accelerated inference and automated log analysis.

Key goals:
- Collect and visualize logs from a vulnerable web application (DVWA).
- Simulate cyberattacks for blue team analysis and detection practice.
- Generate plain-English incident summaries from Logstash alerts using a local LLM.
- Provide remote access to all services via WireGuard VPN.

---

## Features

- **Centralized Log Management:** ELK Stack collects and indexes logs from Beats agents running on DVWA.
- **Attack Simulation:** DVWA (LXC 105) is the pen-test target for SQL injection, brute force, and network scans.
- **Log Forwarding:** Filebeat, Metricbeat, and Packetbeat route logs to Elasticsearch via Logstash.
- **Visualization:** Kibana dashboards with pre-built views for Filebeat, Metricbeat, and Packetbeat.
- **AI-Enhanced Alerting:** n8n workflows call a local Ollama LLM to summarize alerts in plain English.
- **GPU Inference:** RTX 2060 SUPER passed through to Ollama (LXC 100) for local model serving.
- **Remote Access:** WireGuard VPN on the Proxmox host makes all LXC services reachable from anywhere.
- **One-Command Setup:** `bootstrap.sh` installs Node.js, Claude Code, and the Anthropic API key on a fresh host.

---

## Architecture

### Container Map

| LXC ID | Hostname   | CPU | RAM  | Port(s)              | Role                              | Status  |
|--------|------------|-----|------|----------------------|-----------------------------------|---------|
| 100    | ollama     | 4   | 8 GB | 11434                | GPU-accelerated LLM inference     | Running |
| 101    | open-webui | 2   | 4 GB | 3000                 | Web chat UI with RAG support      | Running |
| 102    | n8n        | 2   | 4 GB | 5678                 | Workflow automation + AI alerting | Running |
| 103    | qdrant     | 2   | 4 GB | 6333                 | Vector database for RAG pipelines | Planned |
| 104    | elk-stack  | 4   | 8 GB | 5602 / 9201 / 5045   | ELK Stack — log ingestion + Kibana| Planned |
| 105    | dvwa       | 2   | 2 GB | 80                   | Pen-test target + log source      | Planned |

**Hardware:** Ryzen 8-core, 47 GB RAM, RTX 2060 SUPER (8 GB VRAM)

### Network

All containers share the Proxmox LAN bridge (`vmbr0`). IPs are DHCP-assigned from the local router — no NAT adapters. WireGuard runs on the Proxmox host; once connected to `10.10.0.0/24`, all LXC services are reachable directly.

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

## Quick Start

On a fresh Proxmox VE host:

```bash
git clone https://github.com/adrin0/hadron-two
cd hadron-two
bash bootstrap.sh
```

After the script completes, reload the environment so `claude` is available:

```bash
source /etc/environment
claude
```

---

## Installation and Setup

### Prerequisites

- **Proxmox VE 8.x** installed on the bare-metal host
- **Git** (installed by `bootstrap.sh` if missing)
- **WireGuard** configured on the Proxmox host for remote access (optional)
- An **Anthropic API key** for Claude Code (prompted during `bootstrap.sh`)

### Step 1: Bootstrap the Host

Run `bootstrap.sh` from the repo root on the Proxmox host as root. It installs Node.js LTS, Claude Code, and writes `ANTHROPIC_API_KEY` to `/etc/environment`.

```bash
bash bootstrap.sh
```

### Step 2: Create LXC Containers

Create each container from the Proxmox host. Run the create scripts for the services you want to deploy:

```bash
# ELK Stack (LXC 104) — privileged, Docker inside LXC
bash soc/ELK/create-lxc.sh

# DVWA (LXC 105) — unprivileged
bash soc/DVWA/create-lxc.sh
```

Get each container's IP after creation:

```bash
pct exec 104 -- hostname -I
pct exec 105 -- hostname -I
```

### Step 3: Set Up ELK Stack

Push the setup script into LXC 104 and run it:

```bash
pct push 104 soc/ELK/setup.sh /root/setup.sh
pct exec 104 -- bash /root/setup.sh
```

Verify all three containers are running:

```bash
pct exec 104 -- docker ps
```

Access Kibana at `http://<LXC104_IP>:5602`

Verify Elasticsearch health:

```bash
curl http://<LXC104_IP>:9201/_cluster/health?pretty
```

Expected: `"status": "green"`

### Step 4: Set Up DVWA

Push the setup script into LXC 105 and run it:

```bash
pct push 105 soc/DVWA/setup.sh /root/setup.sh
pct exec 105 -- bash /root/setup.sh
```

Complete the post-install steps inside LXC 105:

1. Set a MySQL root password and create the DVWA database user:
   ```bash
   pct exec 105 -- bash
   mysql_secure_installation
   mysql -u root -p
   ```
   ```sql
   CREATE USER 'dvwa'@'localhost' IDENTIFIED BY '<password>';
   GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
   FLUSH PRIVILEGES;
   ```

2. Update `/var/www/html/DVWA/config/config.inc.php` with your MySQL credentials.

3. Complete DVWA initialization at `http://<LXC105_IP>/DVWA/setup.php`

4. Log in at `http://<LXC105_IP>/DVWA/login.php` (default: `admin` / `password`) and set the security level to **Low**.

### Step 5: Configure Beats

On LXC 105, update each Beat's YAML to point at LXC 104's IP. See [soc/docs/beats-config.md](soc/docs/beats-config.md) for the full config.

Key config block (same pattern for filebeat, metricbeat, packetbeat):

```yaml
output.elasticsearch:
  hosts: ["<LXC104_IP>:9201"]

setup.kibana:
  host: "<LXC104_IP>:5602"
```

Load dashboards and start each Beat:

```bash
sudo filebeat setup --dashboards && sudo systemctl start filebeat
sudo metricbeat setup --dashboards && sudo systemctl start metricbeat
sudo packetbeat setup --dashboards && sudo systemctl start packetbeat
```

Test connectivity:

```bash
sudo filebeat test output
sudo metricbeat test output
sudo packetbeat test output
```

### Step 6: Configure Kibana Dashboards

1. Open Kibana at `http://<LXC104_IP>:5602`.
2. Go to **Management → Stack Management → Index Patterns** and confirm `filebeat-*`, `metricbeat-*`, and `packetbeat-*` are present.
3. Go to **Dashboard** in the left menu.
4. Search for `Filebeat`, `Metricbeat`, or `Packetbeat` to load pre-built dashboards.
5. Go to **Discover** and select an index pattern to confirm events are flowing in real time.

---

## Attack Scenarios

These scenarios demonstrate the full attack → detect pipeline. Run each from the Proxmox host or any machine connected via WireGuard, targeting LXC 105's IP. Ensure DVWA is running and Beats are forwarding before starting.

### Scenario 1: SQL Injection with sqlmap

**Attack**
```bash
sqlmap -u "http://<LXC105_IP>/DVWA/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=<session>; security=low" \
  --dbs --batch
```

**What gets logged:** Apache access logs on LXC 105 show hundreds of GET requests to `/DVWA/vulnerabilities/sqli/` with payloads like `UNION SELECT`, `ORDER BY`, and `'` in the query string. Filebeat ships these to Logstash, which routes them to the `filebeat-*` index.

**Kibana:** Open the `filebeat-*` index in Discover. Filter `request: *UNION*` or `url.query: *sqli*`. Check request count by source IP to identify the scanner.

---

### Scenario 2: Brute Force Login with Hydra

**Attack**
```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
  http-post-form \
  "/DVWA/login.php:username=^USER^&password=^PASS^&Login=Login:Login failed" \
  <LXC105_IP> -t 4
```

**What gets logged:** Apache logs fill with POST requests to `/DVWA/login.php` returning 200 (login page re-render). High request volume from a single IP in a short window.

**Kibana:** In the `filebeat-*` index, filter `request: */DVWA/login.php*` and `http.request.method: POST`. Group by `source.ip` to see request counts. A spike of hundreds of requests per minute in a narrow time window indicates brute force.

---

### Scenario 3: Network Port Scan with Nmap

**Attack**
```bash
# Service version scan
nmap -sV -O -T4 <LXC105_IP>

# Stealthy SYN scan
nmap -sS -p 1-10000 <LXC105_IP>
```

**What gets logged:** Packetbeat captures TCP SYN packets and logs connection attempts across many ports in rapid succession. Metricbeat shows CPU and network spikes on LXC 105 during the scan.

**Kibana:** Open the `packetbeat-*` index. Filter on `type: flow` and group by `source.ip` and `destination.port`. A single source IP connecting to dozens of ports within seconds is a port scan signature. Cross-reference with `metricbeat-*` for resource impact.

---

## AI-Enhanced Alerting

hadron-two replaces the Python-based alert scripts from soc-lab with an n8n + Ollama pipeline:

1. **Logstash** detects a suspicious pattern (high request rate, unusual payload) and fires a webhook to LXC 102.
2. **n8n** (LXC 102) receives the webhook, formats the log context, and sends it to Ollama via HTTP.
3. **Ollama** (LXC 100) runs the request against a local model (no data leaves the network) and returns a plain-English incident summary.
4. **n8n** routes the summary to a notification channel (email, Slack webhook, or log file).

Example output:
> "High-volume POST requests to /DVWA/login.php from 10.10.0.5 — 847 requests in 90 seconds with consistent 'Login failed' responses. Pattern matches credential stuffing or dictionary attack (MITRE T1110). Recommend reviewing authentication logs and temporarily rate-limiting the source IP."

See [soc/docs/architecture.md](soc/docs/architecture.md) for the full pipeline diagram.

---

## Docs

| File | Description |
|------|-------------|
| [soc/README.md](soc/README.md) | SOC layer overview and setup order |
| [soc/docs/architecture.md](soc/docs/architecture.md) | Container map, network layout, log flow diagrams |
| [soc/docs/beats-config.md](soc/docs/beats-config.md) | Filebeat, Metricbeat, Packetbeat YAML config reference |
| [soc/docs/lxc-setup.md](soc/docs/lxc-setup.md) | General Proxmox LXC create/start/access reference |
| [soc/docs/screenshot-deliverables.md](soc/docs/screenshot-deliverables.md) | Milestone screenshot checklist |
| [deliverable.md](deliverable.md) | Progress report — what's built and how it compares to soc-lab |
| [ai-stack-ideas.md](ai-stack-ideas.md) | Project ideas for the AI stack |
| [llm-notes.md](llm-notes.md) | LLM provider comparisons |
