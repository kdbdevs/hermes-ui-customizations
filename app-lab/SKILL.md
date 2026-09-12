---
name: app-lab
description: Deploy fullstack web apps with frontend, backend, APIs, database clients, logs, and public URLs.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
triggers:
  - fullstack app
  - web app
  - backend
  - API server
  - dashboard app
  - SaaS app
  - deploy app
  - live app
---

# Hermes App Lab

Use this skill whenever the user asks for a web app that needs a running
server, backend, API routes, auth mock, database mock, realtime updates,
server-side rendering, or anything more complex than a static HTML preview.

For static landing pages, wireframes, visual mockups, and built `dist` folders,
use `preview-lab` instead. Use App Lab when the app needs a live process.

## Public Contract

The App Lab catalog is:

```text
https://apps.cloudnes.space
```

Each deployed app gets its own URL:

```text
https://<slug>.apps.cloudnes.space/
```

## Deployment Commands

Choose a free port:

```bash
hermes-app-next-port
```

Deploy or redeploy an app:

```bash
hermes-app-deploy <app_dir> <slug> <port> "<start_command>" "<title>" "<summary>"
```

List registered apps:

```bash
hermes-app-list
```

Check logs:

```bash
journalctl -u hermes-app-<slug>.service -n 120 --no-pager
```

Restart an app:

```bash
systemctl restart hermes-app-<slug>.service
```

## Build Pattern

Use this layout unless the user gives an existing repo:

```text
/root/hermes-apps/<slug>/
```

The app must bind to:

```text
HOST=127.0.0.1
PORT=<assigned-port>
```

For Node apps, prefer start scripts that read `process.env.PORT`.
For Python/FastAPI apps, run uvicorn on `127.0.0.1:<port>`.

## Workflow

1. Clarify only if missing detail changes app scope, auth, or data model.
2. Decide whether the deliverable belongs in Preview Lab or App Lab.
3. Build in `/root/hermes-apps/<slug>`.
4. Add a real start command and make it respect `HOST` and `PORT`.
5. Run local smoke tests on `http://127.0.0.1:<port>/`.
6. Deploy with `hermes-app-deploy`.
7. Verify the public URL if Cloudflare wildcard routing is active.
8. Return the app URL, local path, service name, and any known limitations.

## Slug Rules

Use short lowercase slugs:

```text
shoe-crm
client-portal
ads-dashboard
```

Only use lowercase letters, numbers, and hyphens.

## Security

Never publish secrets, `.env` files, private keys, production tokens, customer
data, private logs, or OAuth credentials. Use `.env.example` and mock data
unless the user explicitly provides deployable secrets through a safe channel.

App Lab is for demos and internal tools. If the user wants production-grade
security, add auth, rate limits, backups, monitoring, update policy, and a
rollback plan before treating it as production.
