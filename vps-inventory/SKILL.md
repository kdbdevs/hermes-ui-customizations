---
name: vps-inventory
description: Maintain and use the user's VPS/domain/service inventory for operations, deployment, and incident work.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
triggers:
  - VPS inventory
  - server inventory
  - host list
  - cek VPS
  - domain mapping
  - infrastructure audit
  - deploy target
  - server map
---

# VPS Inventory

Use this skill whenever the task involves choosing a server, checking where a
domain points, understanding what is installed on a VPS, planning deployment,
debugging web routing, or cleaning up mixed infrastructure.

## Inventory Locations

Host list:

```text
/root/hermes-inventory/hosts.tsv
```

Scan output:

```text
/root/hermes-inventory/scans/
```

Latest agent report:

```text
/root/hermes-inventory/INVENTORY.md
```

## Commands

Run a read-only scan:

```bash
scan-vps-inventory /root/hermes-inventory/hosts.tsv /root/hermes-inventory/scans
```

Render the latest scan:

```bash
latest=$(ls -t /root/hermes-inventory/scans/vps-inventory-*.jsonl | head -1)
render-vps-inventory "$latest" /root/hermes-inventory/INVENTORY.md
```

Read the current inventory before touching infrastructure:

```bash
sed -n '1,220p' /root/hermes-inventory/INVENTORY.md
```

## Rules

- Treat inventory as read-only evidence. Do not delete services, DNS records,
  folders, databases, or repositories unless the user explicitly asks.
- Never store plaintext passwords in reports, Git repos, or chat output.
- If the user provides passwords, use them only for access and keep generated
  reports redacted.
- Prefer SSH keys and host aliases. If a password-only host exists, mark
  `auth=password-redacted` in `hosts.tsv`.
- Before deploying, check the inventory for ports, reverse proxies, existing
  apps, Cloudflare routes, and backup jobs.
- If the scan is older than a day or the user says the VPS changed, rescan.

## What To Extract

For each host, maintain:

- provider, OS, kernel, architecture, uptime
- public/private IP addresses
- open/listening ports and bound processes
- web stack: Cloudflare Tunnel, Nginx, Apache, Caddy, OpenLiteSpeed, panels
- systemd services, user services, PM2, Docker/Podman containers
- app folders, Git repos, document roots, preview/app lab locations
- database services: MySQL/MariaDB, PostgreSQL, Redis, MongoDB
- cron/systemd timers and backup jobs
- domain/subdomain mapping when discoverable
- risks, unknowns, and cleanup recommendations

## Hermes Main Host Notes

The current Hermes main VPS is expected to include:

- Hermes UI behind `https://hermes.cloudnes.space`
- Webhook listener behind `https://webhook.cloudnes.space`
- Preview Lab behind `https://preview.cloudnes.space`
- App Lab catalog behind `https://apps.cloudnes.space`
- App Lab wildcard apps behind `https://<slug>.apps.cloudnes.space`

Confirm these from the latest inventory before relying on them.
