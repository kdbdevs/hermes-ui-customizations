# Hermes UI Customizations

Public installer for Herdi's Hermes dashboard customizations.

This repository intentionally backs up only allowlisted UI assets:

- dashboard themes from `/root/.hermes/dashboard-themes`
- Kanban dashboard bundle files from `/usr/local/lib/hermes-agent/plugins/kanban/dashboard/dist`
- Preview Lab tools for static UI previews
- restore and backup helper scripts

Do not add Hermes runtime config, API keys, environment files, databases, logs, session data, inventory files, App Lab projects, or memory vault contents here.

## Protect Custom UI Before Updating Hermes

Hermes updates can replace bundled dashboard files. If that happens, the custom
theme and Kanban Flow UI can disappear from the live dashboard, even though the
backup repository is still safe.

Run this before updating Hermes:

```bash
sudo -i
hermes-ui-backup
```

Run this after updating Hermes:

```bash
sudo -i
hermes-ui-restore
```

The restore command pulls the latest repo version, saves a timestamped snapshot
of the active Hermes dashboard files into `/root/hermes-backups`, reinstalls the
custom theme and Kanban Flow files, then restarts the Hermes dashboard.

## Install on Another Hermes VPS

The repository is public, so another Hermes VPS can clone it directly:

```text
docs/FRIEND_INSTALL.md
```

Quick install:

```bash
sudo -i
git clone https://github.com/kdbdevs/hermes-ui-customizations.git /root/hermes-ui-customizations
cd /root/hermes-ui-customizations

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
hermes-ui-restore
```

The restore script copies the backed-up theme and Kanban dashboard files into place, then restarts the Hermes dashboard service.
