#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scan_vps_inventory.sh <hosts.tsv> [output_dir]

hosts.tsv columns:
  host<TAB>user<TAB>auth<TAB>ref<TAB>tags<TAB>notes

The script is read-only on remote hosts. It writes JSONL snapshots locally.
Passwords are never printed or stored; use ssh keys or an SSH config alias.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

HOSTS_FILE="$1"
OUT_DIR="${2:-/root/hermes-inventory/scans}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_FILE="$OUT_DIR/vps-inventory-$STAMP.jsonl"

mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

scan_host() {
  local host="$1" user="$2" auth="$3" ref="$4" tags="$5" notes="$6"
  local target="${user}@${host}"
  local tmp
  tmp="$(mktemp)"
  local probe
  probe="$(mktemp)"
  local status="ok"

  cat > "$probe" <<'REMOTE'
set -u
section() { printf '\n__SECTION__ %s\n' "$1"; }
section os
hostnamectl 2>/dev/null || true
cat /etc/os-release 2>/dev/null || true
section ip
ip -brief addr 2>/dev/null || true
ip route 2>/dev/null || true
section resources
df -hT 2>/dev/null || true
free -h 2>/dev/null || true
uptime 2>/dev/null || true
section listeners
ss -ltnup 2>/dev/null || true
section system_services
systemctl --type=service --state=running --no-pager --no-legend 2>/dev/null || true
section user_services_root
systemctl --user --type=service --state=running --no-pager --no-legend 2>/dev/null || true
section timers
systemctl list-timers --all --no-pager 2>/dev/null || true
systemctl --user list-timers --all --no-pager 2>/dev/null || true
section web_stack
for bin in nginx apache2 httpd caddy openlitespeed lsws cloudflared docker podman pm2 node npm python3 php mysql psql redis-server; do
  command -v "$bin" >/dev/null 2>&1 && printf '%s=%s\n' "$bin" "$(command -v "$bin")"
done
dpkg -l 2>/dev/null | awk '/nginx|apache2|caddy|openlitespeed|cloudflared|docker|mysql|mariadb|postgresql|redis|nodejs|php/ {print $2, $3}' || true
section cloudflared
systemctl --no-pager --full status cloudflared 2>/dev/null | sed -n '1,80p' || true
journalctl -u cloudflared -n 40 --no-pager 2>/dev/null | sed -n '1,80p' || true
section app_dirs
find /root /home /var/www /srv /opt /var/lib -maxdepth 3 -type d \( -name .git -o -name 'public_html' -o -name 'www' -o -name 'htdocs' -o -name 'apps' -o -name 'projects' -o -name 'hermes*' \) -print 2>/dev/null | sort | sed -n '1,220p' || true
section cron
find /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /var/spool/cron/crontabs -maxdepth 1 -type f -printf '%m %u:%g %p\n' 2>/dev/null | sort || true
section hermes
if [ -d /root/.hermes ] || command -v hermes >/dev/null 2>&1; then
  printf 'hermes_detected=1\n'
  command -v hermes || true
  [ -f /root/.hermes/config.yaml ] && python3 - <<'PY' 2>/dev/null || true
import yaml
cfg=yaml.safe_load(open('/root/.hermes/config.yaml')) or {}
print('dashboard_theme=' + str((cfg.get('dashboard') or {}).get('theme')))
print('dashboard_public_url=' + str((cfg.get('dashboard') or {}).get('public_url')))
print('platforms=' + ','.join(k for k,v in (cfg.get('platforms') or {}).items() if isinstance(v,dict) and v.get('enabled')))
print('mcp_servers=' + ','.join((cfg.get('mcp_servers') or {}).keys()))
print('plugins=' + ','.join((cfg.get('plugins') or {}).get('enabled') or []))
PY
fi
REMOTE

  local local_ips
  local_ips="$(hostname -I 2>/dev/null || true)"
  if [[ "$host" == "self" || "$host" == "localhost" || "$host" == "127.0.0.1" || " $local_ips " == *" $host "* ]]; then
    if ! bash "$probe" >"$tmp" 2>&1; then
      status="error"
    fi
  else
    if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 "$target" 'bash -s' >"$tmp" 2>&1 < "$probe"; then
      status="error"
    fi
  fi

  python3 - "$host" "$user" "$auth" "$ref" "$tags" "$notes" "$status" "$tmp" <<'PY'
import datetime as dt
import json
import sys

host, user, auth, ref, tags, notes, status, tmp = sys.argv[1:9]
raw = open(tmp, encoding="utf-8", errors="replace").read()
sections = {}
current = "raw"
sections[current] = []
for line in raw.splitlines():
    if line.startswith("__SECTION__ "):
        current = line.removeprefix("__SECTION__ ").strip()
        sections.setdefault(current, [])
    else:
        sections.setdefault(current, []).append(line)
record = {
    "scanned_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
    "host": host,
    "user": user,
    "auth": auth,
    "ref": ref,
    "tags": [x.strip() for x in tags.split(",") if x.strip()],
    "notes": notes,
    "status": status,
    "sections": {k: "\n".join(v).strip() for k, v in sections.items()},
}
print(json.dumps(record, ensure_ascii=False))
PY
  rm -f "$tmp" "$probe"
}

while IFS=$'\t' read -r host user auth ref tags notes extra; do
  [[ -z "${host:-}" || "${host:0:1}" == "#" ]] && continue
  scan_host "$host" "${user:-root}" "${auth:-ssh-key}" "${ref:-$host}" "${tags:-}" "${notes:-}" >> "$OUT_FILE"
done < "$HOSTS_FILE"

chmod 600 "$OUT_FILE"
echo "$OUT_FILE"
