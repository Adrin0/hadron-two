# hadron-two

A Proxmox-based self-hosted AI platform for running local LLM workloads and building AI projects.

hadron-two is the second iteration of my home AI infrastructure. Simplified from hadron-one to be terminal-managed and use Proxmox's native networking components.

## Stack

| LXC ID | Service     | Port(s)       | Status   | Role                                      |
|--------|-------------|---------------|----------|-------------------------------------------|
| 100    | Ollama      | 11434         | Running  | GPU-accelerated LLM inference             |
| 101    | Open WebUI  | 3000          | Running  | Web chat UI with RAG support              |
| 102    | n8n         | 5678          | Running  | Workflow automation + AI log summarizer   |
| 103    | Qdrant      | 6333          | Planned  | Vector database for RAG pipelines         |
| 104    | ELK Stack   | 5602 / 9201   | Planned  | Centralized log ingestion + Kibana        |
| 105    | DVWA        | 80            | Planned  | Pen-test target + log source              |

**Hardware:** Ryzen 8-core, 47 GB RAM, RTX 2060 SUPER (8 GB VRAM)

## Architecture

- Proxmox hypervisor managing all services as LXC containers
- All containers on a single LAN bridge (`vmbr0`)
- VLAN segmentation under evaluation
- WireGuard VPN on the host for remote access
- Firewall isolation for sandbox environments

See [security/docs/architecture.md](security/docs/architecture.md) for the full container map and log flow diagram.

## Security Monitoring Layer

The `security/` directory contains the Proxmox-adapted version of the [soc-lab](https://github.com/adrin0/soc-lab) setup — ELK Stack (LXC 104) for centralized log management and DVWA (LXC 105) as a pen-test target, extended with AI-enhanced alerting via n8n + Ollama.

- [security/README.md](security/README.md) — Overview and setup order
- [security/ELK/](security/ELK/) — ELK container provisioning and config
- [security/DVWA/](security/DVWA/) — DVWA container provisioning and config
- [security/docs/](security/docs/) — Architecture, LXC reference, Beats config

## Docs

- [ai-stack-ideas.md](ai-stack-ideas.md) — Project ideas to build on this stack
- [llm-notes.md](llm-notes.md) — LLM provider comparisons and notes
- [claude-tips.md](claude-tips.md) — Notes on using Claude for development
