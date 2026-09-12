#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${HERMES_UI_REPO_URL:-git@github.com:kdbdevs/hermes-ui-customizations.git}"
INSTALL_ROOT="${HERMES_UI_CUSTOMIZATIONS_DIR:-/root/hermes-ui-customizations}"
HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
HERMES_AGENT_DIR="${HERMES_AGENT_DIR:-/usr/local/lib/hermes-agent}"
PREVIEW_BASE_URL="${HERMES_PREVIEW_BASE_URL:-https://preview.cloudnes.space}"
APP_DOMAIN_ROOT="${HERMES_APP_LAB_DOMAIN_ROOT:-apps.cloudnes.space}"
APP_PUBLIC_BASE="${HERMES_APP_LAB_PUBLIC_BASE:-https://${APP_DOMAIN_ROOT}}"

INSTALL_THEME="${INSTALL_THEME:-1}"
INSTALL_KANBAN_WORKFLOW="${INSTALL_KANBAN_WORKFLOW:-1}"
INSTALL_PREVIEW_LAB="${INSTALL_PREVIEW_LAB:-1}"
INSTALL_APP_LAB="${INSTALL_APP_LAB:-1}"
INSTALL_VPS_INVENTORY="${INSTALL_VPS_INVENTORY:-1}"
INSTALL_AUTO_SYNC="${INSTALL_AUTO_SYNC:-1}"

log() {
  printf '[hermes-ui] %s\n' "$*"
}

warn() {
  printf '[hermes-ui] WARN: %s\n' "$*" >&2
}

require_root() {
  if [[ "$(id -u)" != "0" ]]; then
    echo "Run this installer as root on the Hermes VPS." >&2
    exit 1
  fi
}

ensure_repo_context() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ -f "$script_dir/themes/n8n-workflow.yaml" ]]; then
    cd "$script_dir"
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "git is required before installing Hermes UI customizations." >&2
    exit 1
  fi

  if [[ ! -d "$INSTALL_ROOT/.git" ]]; then
    log "Cloning $REPO_URL into $INSTALL_ROOT"
    mkdir -p "$(dirname "$INSTALL_ROOT")"
    git clone "$REPO_URL" "$INSTALL_ROOT"
  fi

  cd "$INSTALL_ROOT"
}

copy_skill_to_profiles() {
  local src="$1"
  local category="$2"
  local name="$3"

  [[ -f "$src" ]] || {
    warn "Skill file not found: $src"
    return
  }

  install -d "$HERMES_HOME/skills/$category/$name"
  install -m 0644 "$src" "$HERMES_HOME/skills/$category/$name/SKILL.md"

  if compgen -G "$HERMES_HOME/profiles/*" >/dev/null; then
    for profile_dir in "$HERMES_HOME"/profiles/*; do
      [[ -d "$profile_dir" ]] || continue
      install -d "$profile_dir/skills/$category/$name"
      install -m 0644 "$src" "$profile_dir/skills/$category/$name/SKILL.md"
    done
  fi
}

install_theme() {
  [[ "$INSTALL_THEME" == "1" ]] || return
  [[ -f themes/n8n-workflow.yaml ]] || {
    warn "Theme file missing: themes/n8n-workflow.yaml"
    return
  }

  install -d "$HERMES_HOME/dashboard-themes"
  install -m 0644 themes/n8n-workflow.yaml "$HERMES_HOME/dashboard-themes/n8n-workflow.yaml"
  log "Installed theme: n8n-workflow"
}

install_kanban_workflow() {
  [[ "$INSTALL_KANBAN_WORKFLOW" == "1" ]] || return
  [[ -f kanban-workflow/index.js && -f kanban-workflow/style.css ]] || {
    warn "Kanban workflow files missing; skipping visual workflow patch"
    return
  }

  local dist="$HERMES_AGENT_DIR/plugins/kanban/dashboard/dist"
  if [[ ! -d "$dist" ]]; then
    warn "Kanban dashboard dist not found at $dist"
    return
  fi

  if [[ -f "$dist/index.js" && ! -f "$dist/index.js.pre-hermes-ui.bak" ]]; then
    cp "$dist/index.js" "$dist/index.js.pre-hermes-ui.bak"
  fi
  if [[ -f "$dist/style.css" && ! -f "$dist/style.css.pre-hermes-ui.bak" ]]; then
    cp "$dist/style.css" "$dist/style.css.pre-hermes-ui.bak"
  fi

  install -m 0644 kanban-workflow/index.js "$dist/index.js"
  install -m 0644 kanban-workflow/style.css "$dist/style.css"
  log "Installed Kanban workflow UI patch"
}

install_preview_lab() {
  [[ "$INSTALL_PREVIEW_LAB" == "1" ]] || return
  [[ -f preview-lab/preview_server.py && -f preview-lab/hermes-preview-publish ]] || {
    warn "Preview Lab files missing; skipping"
    return
  }

  install -d /opt/hermes-preview-lab /var/lib/hermes-previews/sites
  install -m 0755 preview-lab/preview_server.py /opt/hermes-preview-lab/preview_server.py
  install -m 0755 preview-lab/hermes-preview-publish /usr/local/bin/hermes-preview-publish

  sed "s#^Environment=HERMES_PREVIEW_BASE_URL=.*#Environment=HERMES_PREVIEW_BASE_URL=${PREVIEW_BASE_URL}#" \
    preview-lab/hermes-preview-lab.service > /etc/systemd/system/hermes-preview-lab.service

  systemctl daemon-reload
  systemctl enable --now hermes-preview-lab.service
  systemctl restart hermes-preview-lab.service

  copy_skill_to_profiles preview-lab/SKILL.md productivity preview-lab
  log "Installed Preview Lab at $PREVIEW_BASE_URL"
}

install_app_lab() {
  [[ "$INSTALL_APP_LAB" == "1" ]] || return
  [[ -f app-lab/app_lab_proxy.js && -f app-lab/hermes-app-deploy ]] || {
    warn "App Lab files missing; skipping"
    return
  }

  install -d /opt/hermes-app-lab /var/lib/hermes-apps /root/hermes-apps
  install -m 0755 app-lab/app_lab_proxy.js /opt/hermes-app-lab/app_lab_proxy.js
  install -m 0755 app-lab/hermes-app-deploy /usr/local/bin/hermes-app-deploy
  install -m 0755 app-lab/hermes-app-list /usr/local/bin/hermes-app-list
  install -m 0755 app-lab/hermes-app-next-port /usr/local/bin/hermes-app-next-port

  sed \
    -e "s#^Environment=HERMES_APP_LAB_DOMAIN_ROOT=.*#Environment=HERMES_APP_LAB_DOMAIN_ROOT=${APP_DOMAIN_ROOT}#" \
    -e "s#^Environment=HERMES_APP_LAB_PUBLIC_BASE=.*#Environment=HERMES_APP_LAB_PUBLIC_BASE=${APP_PUBLIC_BASE}#" \
    app-lab/hermes-app-lab.service > /etc/systemd/system/hermes-app-lab.service

  if [[ ! -f /var/lib/hermes-apps/registry.json ]]; then
    printf '{"apps":{}}\n' > /var/lib/hermes-apps/registry.json
  fi

  systemctl daemon-reload
  systemctl enable --now hermes-app-lab.service
  systemctl restart hermes-app-lab.service

  copy_skill_to_profiles app-lab/SKILL.md productivity app-lab
  log "Installed App Lab at $APP_PUBLIC_BASE"
}

install_vps_inventory() {
  [[ "$INSTALL_VPS_INVENTORY" == "1" ]] || return
  [[ -f vps-inventory/scan_vps_inventory.sh && -f vps-inventory/render_inventory_report.py ]] || {
    warn "VPS Inventory files missing; skipping"
    return
  }

  install -d /root/hermes-inventory/scans /opt/hermes-vps-inventory
  install -m 0755 vps-inventory/scan_vps_inventory.sh /usr/local/bin/scan-vps-inventory
  install -m 0755 vps-inventory/render_inventory_report.py /usr/local/bin/render-vps-inventory
  install -m 0644 vps-inventory/README.md /opt/hermes-vps-inventory/README.md
  install -m 0644 vps-inventory/hosts.example.tsv /root/hermes-inventory/hosts.example.tsv

  if [[ ! -f /root/hermes-inventory/hosts.tsv ]]; then
    install -m 0644 vps-inventory/hosts.example.tsv /root/hermes-inventory/hosts.tsv
  fi

  copy_skill_to_profiles vps-inventory/SKILL.md operations vps-inventory
  log "Installed VPS Inventory tools"
}

install_auto_sync() {
  [[ "$INSTALL_AUTO_SYNC" == "1" ]] || return
  [[ -f sync.sh ]] || {
    warn "sync.sh missing; skipping auto-sync timer"
    return
  }

  cat > /etc/systemd/system/hermes-ui-customizations-sync.service <<SERVICE
[Unit]
Description=Sync Hermes UI customizations from GitHub
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=${INSTALL_ROOT}
ExecStart=/bin/bash ${INSTALL_ROOT}/sync.sh
SERVICE

  cat > /etc/systemd/system/hermes-ui-customizations-sync.timer <<'TIMER'
[Unit]
Description=Daily Hermes UI customizations sync

[Timer]
OnBootSec=5min
OnUnitActiveSec=24h
Persistent=true

[Install]
WantedBy=timers.target
TIMER

  systemctl daemon-reload
  systemctl enable --now hermes-ui-customizations-sync.timer
  log "Installed auto-sync timer: hermes-ui-customizations-sync.timer"
}

restart_hermes_dashboard() {
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}" systemctl --user restart hermes-dashboard.service >/dev/null 2>&1 || true
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}" systemctl --user restart hermes-gateway.service >/dev/null 2>&1 || true
}

main() {
  require_root
  ensure_repo_context
  chmod +x install.sh sync.sh 2>/dev/null || true

  install_theme
  install_kanban_workflow
  install_preview_lab
  install_app_lab
  install_vps_inventory
  install_auto_sync
  restart_hermes_dashboard

  cat <<SUMMARY

Hermes UI customizations installed.

Theme:
  Open Hermes UI -> Config/System -> Theme -> select "n8n Workflow".

Recommended Cloudflare Tunnel routes:
  preview subdomain -> http://localhost:8088
  apps root         -> http://localhost:18080
  *.apps wildcard  -> http://localhost:18080

Manual update:
  ${INSTALL_ROOT}/sync.sh

SUMMARY
}

main "$@"
