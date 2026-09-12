# Hermes UI Customizations

Private backup and installer for Herdi's Hermes dashboard customizations.

This repository intentionally backs up only allowlisted UI assets:

- dashboard themes from `/root/.hermes/dashboard-themes`
- Kanban dashboard bundle files from `/usr/local/lib/hermes-agent/plugins/kanban/dashboard/dist`
- Preview Lab tools for static UI previews
- restore and backup helper scripts

Do not add Hermes runtime config, API keys, environment files, databases, logs, session data, or memory vault contents here.

## Install on Another Hermes VPS

Because this repository is private, give the friend's VPS read-only access with
a GitHub deploy key first:

```text
docs/FRIEND_INSTALL.md
```

Quick install after deploy key access works:

```bash
sudo -i
git clone git@github.com-hermes-ui:kdbdevs/hermes-ui-customizations.git /root/hermes-ui-customizations
cd /root/hermes-ui-customizations

HERMES_PREVIEW_BASE_URL=https://preview.friend-domain.com \
./install.sh
```

The installer adds:

- `n8n Workflow` dashboard theme
- Kanban visual workflow UI patch
- Preview Lab on `127.0.0.1:8088`
- daily auto-sync timer from GitHub

Manual update:

```bash
/root/hermes-ui-customizations/sync.sh
```

## Restore

Run on the Hermes VPS:

```bash
/root/hermes-ui-customizations/scripts/restore-hermes-ui-customizations.sh
```

The restore script copies the backed-up theme and Kanban dashboard files into place, then restarts the Hermes dashboard service.
