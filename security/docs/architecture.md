# hadron-two Architecture

All services run as Proxmox LXC containers on a single Ryzen host (RTX 2060 SUPER, 47 GB RAM, 8-core). Remote access is via WireGuard VPN (`10.10.0.0/24`).

## Container Map

| LXC ID | Hostname    | CPU | RAM   | Role                                          | Status    |
|--------|-------------|-----|-------|-----------------------------------------------|-----------|
| 100    | ollama      | 4   | 8 GB  | GPU-accelerated LLM inference (Ollama)        | Running   |
| 101    | open-webui  | 2   | 4 GB  | Web chat UI + RAG (Open WebUI)                | Running   |
| 102    | n8n         | 2   | 4 GB  | Workflow automation + AI log summarizer       | Running   |
| 103    | qdrant      | 2   | 4 GB  | Vector database for semantic search           | Planned   |
| 104    | elk-stack   | 4   | 8 GB  | ELK Stack — log ingestion + Kibana dashboards | Planned   |
| 105    | dvwa        | 2   | 2 GB  | DVWA — pen-test target + log source           | Planned   |

## Network

All containers share the Proxmox LAN bridge (`vmbr0`). IPs are assigned via DHCP from your local router. There are no NAT adapters — internet access flows through the Proxmox host's uplink.

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

WireGuard runs on the Proxmox host. Once connected to `10.10.0.0/24`, all LXC IPs are reachable directly.

## Log Flow

```
LXC 105 (DVWA)
  ├─ Filebeat   ──┐
  ├─ Metricbeat ──┤──► LXC 104 (ELK) :5045 ──► Logstash ──► Elasticsearch
  └─ Packetbeat ──┘                                               │
                                                               Kibana :5602
```

## AI-Enhanced Monitoring (Planned)

```
Logstash alert webhook
    │
    ▼
LXC 102 (n8n) ──► LXC 100 (Ollama) ──► Plain-English incident summary
                                              │
                                         Notification (email / webhook)
```

## Comparison with soc-lab

| Aspect          | soc-lab (VirtualBox)        | hadron-two (Proxmox)             |
|-----------------|-----------------------------|----------------------------------|
| Hypervisor      | VirtualBox                  | Proxmox VE                       |
| Container type  | Full VMs                    | LXC containers                   |
| Networking      | Host-only + NAT             | Single LAN bridge (vmbr0)        |
| Remote access   | None (local only)           | WireGuard VPN                    |
| AI integration  | None                        | Ollama + n8n for log analysis    |
| Storage         | Per-VM VMDK                 | Proxmox storage pool (local-lvm) |
