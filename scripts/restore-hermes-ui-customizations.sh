#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${HERMES_UI_CUSTOMIZATIONS_DIR:-${HERMES_UI_BACKUP_REPO:-/root/hermes-ui-customizations}}"
HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
HERMES_AGENT_DIR="${HERMES_AGENT_DIR:-${HERMES_SRC:-/usr/local/lib/hermes-agent}}"
BACKUP_ROOT="${HERMES_UI_RESTORE_BACKUP_ROOT:-/root/hermes-backups/hermes-ui-customizations}"
RESTORE_PULL="${HERMES_UI_RESTORE_PULL:-1}"

log() {
  printf '[hermes-ui-restore] %s\n' "$*"
}

warn() {
  printf '[hermes-ui-restore] WARN: %s\n' "$*" >&2
}

die() {
  printf '[hermes-ui-restore] ERROR: %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ "$(id -u)" != "0" ]]; then
    die "Run this restore command as root on the Hermes VPS."
  fi
}

ensure_repo() {
  [[ -d "$REPO_DIR" ]] || die "Custom UI repo not found: $REPO_DIR"
  [[ -d "$REPO_DIR/.git" ]] || die "Not a git repository: $REPO_DIR"
  cd "$REPO_DIR"

  if [[ "$RESTORE_PULL" == "1" ]]; then
    log "Pulling latest custom UI from GitHub"
    git fetch --prune origin
    git pull --ff-only
  fi
}

backup_current_files() {
  local dist="$HERMES_AGENT_DIR/plugins/kanban/dashboard/dist"
  local stamp
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  local backup_dir="$BACKUP_ROOT/$stamp"

  install -d "$backup_dir/kanban-dashboard-dist" "$backup_dir/dashboard-themes"

  if [[ -f "$dist/index.js" ]]; then
    cp -a "$dist/index.js" "$backup_dir/kanban-dashboard-dist/index.js"
  fi
  if [[ -f "$dist/style.css" ]]; then
    cp -a "$dist/style.css" "$backup_dir/kanban-dashboard-dist/style.css"
  fi
  if [[ -d "$HERMES_HOME/dashboard-themes" ]]; then
    find "$HERMES_HOME/dashboard-themes" -maxdepth 1 -type f -name '*.yaml' -exec cp -a {} "$backup_dir/dashboard-themes/" \;
  fi

  cat > "$backup_dir/manifest.txt" <<MANIFEST
created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
host=$(hostname)
hermes_agent_dir=$HERMES_AGENT_DIR
hermes_home=$HERMES_HOME
repo_dir=$REPO_DIR
MANIFEST

  log "Snapshot saved: $backup_dir"
}

install_themes() {
  install -d "$HERMES_HOME/dashboard-themes"

  if [[ -d themes ]]; then
    find themes -maxdepth 1 -type f -name '*.yaml' -exec install -m 0644 {} "$HERMES_HOME/dashboard-themes/" \;
    log "Dashboard themes restored"
  else
    warn "No themes directory found; skipping themes"
  fi
}

install_kanban_workflow() {
  local dist="$HERMES_AGENT_DIR/plugins/kanban/dashboard/dist"
  local source_dir=""

  [[ -d "$dist" ]] || die "Hermes Kanban dashboard dist not found: $dist"

  if [[ -f kanban-workflow/index.js && -f kanban-workflow/style.css ]]; then
    source_dir="kanban-workflow"
  elif [[ -f plugins/kanban/dashboard/dist/index.js && -f plugins/kanban/dashboard/dist/style.css ]]; then
    source_dir="plugins/kanban/dashboard/dist"
  else
    die "Kanban workflow files not found in repo."
  fi

  if command -v node >/dev/null 2>&1; then
    node --check "$source_dir/index.js"
  fi

  install -m 0644 "$source_dir/index.js" "$dist/index.js"
  install -m 0644 "$source_dir/style.css" "$dist/style.css"
  log "Kanban workflow UI restored from $source_dir"
}

restart_hermes() {
  local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/0}"

  XDG_RUNTIME_DIR="$runtime_dir" systemctl --user restart hermes-dashboard.service >/dev/null 2>&1 || warn "Could not restart hermes-dashboard.service"
  XDG_RUNTIME_DIR="$runtime_dir" systemctl --user restart hermes-gateway.service >/dev/null 2>&1 || true

  if XDG_RUNTIME_DIR="$runtime_dir" systemctl --user is-active hermes-dashboard.service >/dev/null 2>&1; then
    log "Hermes dashboard is active"
  else
    warn "Hermes dashboard status is not active; check: systemctl --user status hermes-dashboard.service"
  fi
}

main() {
  require_root
  ensure_repo
  backup_current_files
  install_themes
  install_kanban_workflow
  restart_hermes
  log "Custom Hermes UI restored. Hard refresh the browser if cached assets are still visible."
}

main "$@"
