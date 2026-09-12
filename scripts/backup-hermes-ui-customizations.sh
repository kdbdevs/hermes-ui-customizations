#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${HERMES_UI_BACKUP_REPO:-/root/hermes-ui-customizations}"
HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
HERMES_SRC="${HERMES_SRC:-/usr/local/lib/hermes-agent}"
REMOTE_URL="${HERMES_UI_BACKUP_REMOTE:-https://github.com/kdbdevs/hermes-ui-customizations.git}"

mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

if [ ! -d .git ]; then
  git init -b main >/dev/null
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$REMOTE_URL"
else
  git remote set-url origin "$REMOTE_URL"
fi

mkdir -p themes plugins/kanban/dashboard/dist scripts metadata

if [ -d "$HERMES_HOME/dashboard-themes" ]; then
  find themes -mindepth 1 -maxdepth 1 -type f -name '*.yaml' -delete
  find "$HERMES_HOME/dashboard-themes" -maxdepth 1 -type f -name '*.yaml' -exec cp -f {} themes/ \;
fi

cp -f "$HERMES_SRC/plugins/kanban/dashboard/dist/index.js" plugins/kanban/dashboard/dist/index.js
cp -f "$HERMES_SRC/plugins/kanban/dashboard/dist/style.css" plugins/kanban/dashboard/dist/style.css

cp -f "$0" scripts/backup-hermes-ui-customizations.sh
chmod +x scripts/backup-hermes-ui-customizations.sh

cat > metadata/manifest.txt <<MANIFEST
generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
host=$(hostname)
hermes_src=$HERMES_SRC
hermes_home=$HERMES_HOME
theme_count=$(find themes -maxdepth 1 -type f -name '*.yaml' | wc -l | tr -d ' ')
kanban_index_sha256=$(sha256sum plugins/kanban/dashboard/dist/index.js | awk '{print $1}')
kanban_style_sha256=$(sha256sum plugins/kanban/dashboard/dist/style.css | awk '{print $1}')
MANIFEST

git add README.md themes plugins scripts metadata

if git diff --cached --quiet; then
  echo "No Hermes UI/theme changes to back up."
  exit 0
fi

git commit -m "Backup Hermes UI customizations $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null
git push -u origin main
echo "Hermes UI/theme backup pushed to $REMOTE_URL"
