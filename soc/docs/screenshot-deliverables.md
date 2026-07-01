# Screenshot Deliverables — SOC Layer Progress

Portfolio of proof-of-work screenshots documenting the build-out of the security monitoring layer as a continuation of [soc-lab](https://github.com/adrin0/soc-lab). Each section maps to a deployment milestone. Check off items as you capture them.

---

## Milestone 1 — AI Stack (Running)

These containers are live. Capture screenshots before moving to ELK/DVWA.

| # | What to Screenshot | Where | Notes |
|---|--------------------|-------|-------|
| 1.1 | `pct list` output showing LXC 100–102 running | Proxmox host terminal | Shows active containers |
| 1.2 | Open WebUI home screen | `http://<LXC101>:3000` | Confirm chat UI is up |
| 1.3 | Open WebUI chat — test prompt with local Ollama model | `http://<LXC101>:3000` | Shows GPU inference working |
| 1.4 | n8n workflow editor — any active workflow | `http://<LXC102>:5678` | Shows automation layer |
| 1.5 | Ollama model list | `pct exec 100 -- ollama list` | Shows loaded models |

---

## Milestone 2 — ELK Stack Deployment (LXC 104)

Capture during and after running `soc/ELK/setup.sh` inside LXC 104.

| # | What to Screenshot | Where | Notes |
|---|--------------------|-------|-------|
| 2.1 | `pct create 104` command completing | Proxmox host terminal | LXC created |
| 2.2 | `setup.sh` running — Docker install output | LXC 104 terminal | Shows provisioning |
| 2.3 | `docker compose up -d` — all 3 containers starting | LXC 104 terminal | elasticsearch, logstash, kibana |
| 2.4 | `docker ps` showing all 3 containers `Up` | LXC 104 terminal | Health check |
| 2.5 | Kibana loading screen / welcome page | `http://<LXC104>:5602` | First browser hit |
| 2.6 | Kibana home — fully loaded | `http://<LXC104>:5602` | ELK is live |
| 2.7 | Elasticsearch health check response | `curl http://<LXC104>:9201/_cluster/health?pretty` | `status: green` |

---

## Milestone 3 — DVWA Deployment (LXC 105)

Capture during and after running `soc/DVWA/setup.sh` inside LXC 105.

| # | What to Screenshot | Where | Notes |
|---|--------------------|-------|-------|
| 3.1 | `pct create 105` command completing | Proxmox host terminal | LXC created |
| 3.2 | `setup.sh` running — Apache + DVWA clone output | LXC 105 terminal | Shows provisioning |
| 3.3 | DVWA setup page | `http://<LXC105>/DVWA/setup.php` | Pre-install checks |
| 3.4 | DVWA setup page — "Database Created" success message | `http://<LXC105>/DVWA/setup.php` | DB init complete |
| 3.5 | DVWA login page | `http://<LXC105>/DVWA/login.php` | App is accessible |
| 3.6 | DVWA home — security level set to Low | `http://<LXC105>/DVWA/` | Ready for testing |

---

## Milestone 4 — Beats + Log Forwarding

Capture after configuring Beats on LXC 105 per `soc/docs/beats-config.md`.

| # | What to Screenshot | Where | Notes |
|---|--------------------|-------|-------|
| 4.1 | `filebeat test output` — success | LXC 105 terminal | Confirms ES reachable |
| 4.2 | `metricbeat test output` — success | LXC 105 terminal | Confirms ES reachable |
| 4.3 | `packetbeat test output` — success | LXC 105 terminal | Confirms ES reachable |
| 4.4 | `systemctl status filebeat metricbeat packetbeat` — all active | LXC 105 terminal | Beats running |
| 4.5 | Kibana → Discover — `filebeat-*` index with log entries | `http://<LXC104>:5602` | Logs flowing |
| 4.6 | Kibana → Discover — `metricbeat-*` index with metric entries | `http://<LXC104>:5602` | Metrics flowing |
| 4.7 | Kibana → Discover — `packetbeat-*` index with network entries | `http://<LXC104>:5602` | Traffic captured |
| 4.8 | Kibana → Dashboard — Filebeat pre-built dashboard | `http://<LXC104>:5602` | Shows log volume |
| 4.9 | Kibana → Dashboard — Metricbeat system overview | `http://<LXC104>:5602` | CPU/mem of DVWA host |

---

## Milestone 5 — Attack Simulation + Log Capture

Run DVWA attacks and confirm they appear in Kibana. Demonstrates the full soc-lab → hadron-two log pipeline.

| # | What to Screenshot | Where | Notes |
|---|--------------------|-------|-------|
| 5.1 | DVWA — SQL Injection page (submit a payload) | `http://<LXC105>/DVWA/` | Active attack |
| 5.2 | DVWA — Brute Force page (submit failed login) | `http://<LXC105>/DVWA/` | Active attack |
| 5.3 | DVWA — Command Injection page | `http://<LXC105>/DVWA/` | Active attack |
| 5.4 | Kibana → Discover — Apache access log entries from attacks | `http://<LXC104>:5602` | Logs captured |
| 5.5 | Kibana → Discover — filter by `host.ip: <LXC105_IP>` | `http://<LXC104>:5602` | Scoped to DVWA host |
| 5.6 | Kibana → Discover — SQL injection log entries visible | `http://<LXC104>:5602` | Attack logged |
| 5.7 | Kibana → Dashboard — traffic spike during attack window | `http://<LXC104>:5602` | Timeline view |

---

## Milestone 6 — AI-Enhanced Alerting (n8n + Ollama)

Capture after wiring the Logstash → n8n → Ollama pipeline.

| # | What to Screenshot | Where | Notes |
|---|--------------------|-------|-------|
| 6.1 | n8n workflow — webhook trigger + Ollama HTTP node | `http://<LXC102>:5678` | Workflow design |
| 6.2 | n8n execution log — successful run triggered by a Logstash alert | `http://<LXC102>:5678` | Execution output |
| 6.3 | Ollama plain-English incident summary output | n8n execution output | AI-generated alert |
| 6.4 | Full pipeline diagram annotated in terminal or whiteboard | Any | Architecture proof |

---

## Milestone 7 — soc-lab Comparison

Final set showing hadron-two vs soc-lab side-by-side context.

| # | What to Screenshot | Where | Notes |
|---|--------------------|-------|-------|
| 7.1 | `pct list` — all 6 LXCs running (100–105) | Proxmox host terminal | Full stack live |
| 7.2 | Proxmox web UI — Resources view showing all containers | `https://<PROXMOX_IP>:8006` | Visual cluster view |
| 7.3 | `soc/docs/architecture.md` comparison table rendered | GitHub or markdown preview | Side-by-side diff |

---

## Naming Convention

Save screenshots as:

```
soc/docs/screenshots/M<milestone>-<item>-<slug>.png
```

Examples:
- `soc/docs/screenshots/M2-2.6-kibana-home.png`
- `soc/docs/screenshots/M5-5.4-apache-logs-kibana.png`
- `soc/docs/screenshots/M6-6.3-ollama-alert-summary.png`

---

## Progress

| Milestone | Status |
|-----------|--------|
| 1 — AI Stack | ⬜ In progress |
| 2 — ELK Deployment | ⬜ Planned |
| 3 — DVWA Deployment | ⬜ Planned |
| 4 — Beats + Log Flow | ⬜ Planned |
| 5 — Attack Simulation | ⬜ Planned |
| 6 — AI Alerting | ⬜ Planned |
| 7 — Comparison | ⬜ Planned |
