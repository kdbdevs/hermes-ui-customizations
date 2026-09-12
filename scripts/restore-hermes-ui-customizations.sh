#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${HERMES_UI_BACKUP_REPO:-/root/hermes-ui-customizations}"
HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
HERMES_SRC="${HERMES_SRC:-/usr/local/lib/hermes-agent}"

cd "$REPO_DIR"

mkdir -p "$HERMES_HOME/dashboard-themes"
if [ -d themes ]; then
  find themes -maxdepth 1 -type f -name '*.yaml' -exec cp -f {} "$HERMES_HOME/dashboard-themes/" \;
fi

install -m 0644 plugins/kanban/dashboard/dist/index.js "$HERMES_SRC/plugins/kanban/dashboard/dist/index.js"
install -m 0644 plugins/kanban/dashboard/dist/style.css "$HERMES_SRC/plugins/kanban/dashboard/dist/style.css"

systemctl --user restart hermes-dashboard.service
echo "Hermes UI customizations restored and dashboard restarted."
