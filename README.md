# hadron-two — Self-Hosted AI Infrastructure

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Platform](https://img.shields.io/badge/platform-Proxmox%20VE-E57000)
![GPU](https://img.shields.io/badge/GPU-RTX%202060%20SUPER-76B900?logo=nvidia)

A Proxmox-based home server running GPU-accelerated LLM inference and AI workflow automation. Designed to be terminal-managed, private-first, and modular — built as a leaner successor to an earlier overengineered iteration.

## Stack

| Service      | Container | Port  | Status     |
|--------------|-----------|-------|------------|
| Ollama       | LXC 100   | 11434 | Running    |
| Open WebUI   | LXC 101   | 3000  | Running    |
| n8n          | LXC 102   | 5678  | Running    |
| Qdrant       | LXC 103   | 6333  | Planned    |

**Hardware:** Ryzen 8-core, 47 GB RAM, RTX 2060 SUPER (8 GB VRAM)

## Access

Remote access is provided via WireGuard VPN (`10.10.0.0/24`). All services are reachable through the tunnel — nothing is exposed to the public internet.

## Networking

Managed natively on Proxmox VE. WireGuard runs on the host. VLANs are under evaluation. A sandboxed firewall zone isolates experimental workloads from the main LAN.

## Monitoring

ELK Stack integration is planned for endpoint and container log aggregation, building on the patterns established in [soc-lab](https://github.com/adrin0/soc-lab).

## Roadmap

See [ai-stack-ideas.md](ai-stack-ideas.md) for a tiered breakdown of planned projects — from n8n workflow automation and RAG pipelines to agentic research and local fine-tuning.

## Related

- [soc-lab](https://github.com/adrin0/soc-lab) — the predecessor security monitoring lab; ELK patterns here build on that foundation.
