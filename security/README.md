# Security Monitoring Layer

This directory contains the security monitoring stack for hadron-two — an evolution of the patterns established in [soc-lab](https://github.com/adrin0/soc-lab), adapted for Proxmox LXC instead of VirtualBox VMs.

## What It Does

- **Centralized log ingestion** via ELK Stack (LXC 104) — collects Filebeat, Metricbeat, and Packetbeat data from all containers on the LAN.
- **Pen-test target** via DVWA (LXC 105) — a deliberately vulnerable web application for generating attack traffic and testing detection.
- **Threat enrichment** via AbuseIPDB API integration in Logstash — scores IPs seen in web logs.
- **AI-enhanced alerting** (planned) — n8n (LXC 102) + Ollama (LXC 100) pipeline to summarize Logstash alerts in plain English.
- **Semantic search over security events** (planned) — Qdrant (LXC 103) for vector-indexed log queries.

## Containers

| LXC ID | Hostname  | Role                              |
|--------|-----------|-----------------------------------|
| 104    | elk-stack | ELK Stack — log storage + Kibana  |
| 105    | dvwa      | DVWA — pen-test target            |

See [docs/architecture.md](docs/architecture.md) for the full hadron-two container map.

## Setup Order

1. Create and configure the ELK container first — [ELK/README.md](ELK/README.md)
2. Create and configure the DVWA container — [DVWA/README.md](DVWA/README.md)
3. Configure Beats on DVWA (and optionally other containers) to ship logs to ELK — [docs/beats-config.md](docs/beats-config.md)

## Differences from soc-lab

| Aspect               | soc-lab                        | hadron-two (this)                        |
|----------------------|--------------------------------|------------------------------------------|
| Virtualization       | VirtualBox VMs                 | Proxmox LXC containers                   |
| Networking           | Host-only + NAT adapters       | Proxmox bridge (vmbr0) + WireGuard VPN   |
| Container management | Manual VM setup                | `pct create` scripts                     |
| ELK access           | `192.168.56.x` host-only       | LAN IP via WireGuard tunnel              |
| AI integration       | None                           | n8n + Ollama for log summarization       |
