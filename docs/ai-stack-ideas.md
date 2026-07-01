# What Can I Build With This Stack?

## Context

Running stack on `hadron` (RTX 2060 SUPER, 47 GB RAM, 8-core Ryzen):
- **Ollama** (LXC 100, `:11434`) — GPU LLM inference, `llama3.2:3b` loaded
- **Open WebUI** (LXC 101, `:3000`) — multi-model chat UI, RAG-ready
- **n8n** (LXC 102, `:5678`) — 400+ integrations, webhooks, schedules, visual workflow builder
- **Qdrant** (LXC 103, `:6333`) — not yet deployed; unlocks semantic search / RAG

Remote access via WireGuard (`10.10.0.0/24`).

---

## Tier 1 — Ready to Build Now (no new services)

### 1. Automated Daily Digest
**What:** n8n fetches RSS feeds / Hacker News / GitHub releases on a schedule, Ollama summarises and filters by interest, result delivered via email or webhook to your phone.  
**Nodes:** Schedule → HTTP Request (RSS) → Ollama (summarise) → Gmail / Webhook  
**Effort:** 1–2 hours

### 2. Smart Alert Summariser
**What:** Point n8n at your Proxmox syslog or any monitoring webhook; Ollama converts raw log noise into plain-English incident summaries.  
**Nodes:** Webhook → Ollama (classify + summarise) → notification  
**Effort:** 2–3 hours

### 3. Private Multi-Model Playground
**What:** Pull additional models into Ollama (Mistral 7B, Qwen2.5, Phi-3, CodeLlama) and use Open WebUI's built-in model comparison view to evaluate them side-by-side.  
**Action:** `pct exec 100 -- ollama pull mistral` etc.  
**Effort:** 30 minutes of pulling + experimentation

### 4. Local Code Review / Copilot
**What:** n8n webhook receives a git diff (via a pre-push hook or GitHub webhook), Ollama reviews it, posts findings back as a comment or Slack message.  
**Nodes:** Webhook → Code node (extract diff) → Ollama → HTTP Request (GitHub API / Slack)  
**Effort:** 2–4 hours

### 5. Document Q&A (file-drop pipeline)
**What:** Drop a PDF/TXT into a watched folder (n8n File Trigger or HTTP upload), n8n chunks it, Ollama answers questions about it; Open WebUI already has a built-in document upload for ad-hoc use.  
**Effort:** 1 hour for n8n pipeline; zero effort in Open WebUI (already available)

---

## Tier 2 — After Deploying Qdrant (Phase 4)

### 6. Personal Knowledge Base / Second Brain
**What:** Ingest Markdown notes, PDFs, bookmarks → embed with `nomic-embed-text` via Ollama → store in Qdrant → chat against your entire knowledge base from Open WebUI or n8n.  
**Stack:** n8n (ingest + chunk) → Ollama embeddings → Qdrant → Ollama (generate) → Open WebUI (query)  
**Effort:** 3–6 hours to build the pipeline

### 7. Self-Hosted Perplexity
**What:** n8n webhook receives a question → Brave/SearXNG search → fetch top pages → embed + store ephemerally in Qdrant → RAG answer with citations via Ollama.  
**Requires:** SearXNG container (trivial to add) or Brave Search API key  
**Effort:** 4–8 hours

### 8. Codebase Assistant
**What:** Embed an entire git repo into Qdrant, then chat with it: "which function handles auth?", "where is X called?". Useful for onboarding or archaeology.  
**Stack:** n8n (git clone + chunk by file) → Ollama embed → Qdrant → Ollama RAG  
**Effort:** 3–5 hours

### 9. Email Archive Search
**What:** n8n fetches email (IMAP) → embeds bodies → Qdrant stores. Natural-language search across years of email without exposing anything to external APIs.  
**Effort:** 4–6 hours

---

## Tier 3 — More Ambitious (may need 1–2 additional containers)

### 10. Agentic Research Pipeline
**What:** Give n8n an AI Agent node (Ollama as the LLM, Qdrant + web search as tools). Ask it a research question; it autonomously searches, reads pages, cross-references your knowledge base, and returns a structured report.  
**New container:** Optional SearXNG for private web search  
**Effort:** 1–2 days

### 11. Home Automation Brain
**What:** n8n integrates with Home Assistant (or direct MQTT). Voice/text commands → Ollama intent parsing → n8n routes to correct smart-home action. Add Qdrant to remember device state history and answer "was the kitchen light on yesterday at 9pm?"  
**New container:** Home Assistant (or connect to existing)  
**Effort:** Variable

### 12. Slack / Discord AI Bot
**What:** n8n Slack/Discord trigger → Ollama (with Qdrant RAG over team docs) → reply in thread. Private, no OpenAI API costs, runs on your hardware.  
**Effort:** 3–5 hours after Qdrant is up

### 13. Local Fine-Tuning Pipeline
**What:** Collect conversations from Open WebUI (already logged), format into JSONL, fine-tune a small model (Phi-3 mini / Qwen2.5 1.5B) with Unsloth or Axolotl in a new GPU-passthrough LXC.  
**New container:** LXC with GPU passthrough, Python ML stack  
**Effort:** 1–2 days setup, then ongoing

---

## Recommended Starting Path

1. **Today:** Pull 2–3 more models (`mistral`, `qwen2.5:7b`, `codellama`) — baseline capability boost, zero risk.
2. **This week:** Build the daily digest workflow in n8n — validates the Ollama→n8n integration end-to-end.
3. **Next:** Deploy Qdrant (Phase 4 from the existing plan — it's already written out) and build the personal knowledge base. That's the highest-leverage single addition to the stack.
4. **Then:** The knowledge base pipeline becomes the foundation for Perplexity, the codebase assistant, and the research agent.

---

## Hardware Headroom

| Model size | VRAM needed | Fits on RTX 2060 SUPER? |
|------------|-------------|-------------------------|
| 3B (llama3.2:3b) | ~2 GB | Yes — running now |
| 7B Q4 (mistral, etc.) | ~4.5 GB | Yes |
| 13B Q4 | ~8 GB | Tight — likely fits |
| 70B Q4 | ~40 GB | No (8 GB VRAM) — CPU offload only |

**Recommended model set:** `llama3.2:3b` (fast/cheap), `mistral:7b` or `qwen2.5:7b` (balanced), `codellama:7b` (code tasks), `nomic-embed-text` (RAG embeddings).
