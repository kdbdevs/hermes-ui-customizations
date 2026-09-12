# Hermes UI Customizations

Private backup for Herdi's Hermes dashboard customizations.

This repository intentionally backs up only allowlisted UI assets:

- dashboard themes from `/root/.hermes/dashboard-themes`
- Kanban dashboard bundle files from `/usr/local/lib/hermes-agent/plugins/kanban/dashboard/dist`
- restore and backup helper scripts

Do not add Hermes runtime config, API keys, environment files, databases, logs, session data, or memory vault contents here.

## Restore

Run on the Hermes VPS:

```bash
/root/hermes-ui-customizations/scripts/restore-hermes-ui-customizations.sh
```

The restore script copies the backed-up theme and Kanban dashboard files into place, then restarts the Hermes dashboard service.
