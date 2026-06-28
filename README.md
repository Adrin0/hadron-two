# hadron-two

A Proxmox-based self-hosted AI platform for running local LLM workloads and building AI projects.

hadron-two is the second iteration of my home AI infrastructure. Simplified from hadron-one to be terminal-managed and use Proxmox's native networking components.

## Stack

- **Ollama** — Local LLM inference
- **Open WebUI** — Web-based chat interface
- **n8n** — Workflow automation
- **Qdrant** — Vector database for RAG pipelines
- **WireGuard** — VPN for remote access
- **ELK Stack** — Endpoint monitoring (planned)

## Architecture

- Proxmox hypervisor managing containerized services
- VLAN segmentation (in progress)
- Firewall isolation for sandbox environments
- WireGuard on the host for secure remote access

## Docs

- [ai-stack-ideas.md](ai-stack-ideas.md) — Project ideas to build on this stack
- [llm-notes.md](llm-notes.md) — LLM provider comparisons and notes
- [claude-tips.md](claude-tips.md) — Notes on using Claude for development
