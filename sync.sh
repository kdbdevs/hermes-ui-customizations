#!/usr/bin/env bash
set -euo pipefail

DIR="${HERMES_UI_CUSTOMIZATIONS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "$DIR"

if [[ ! -d .git ]]; then
  echo "Not a git repository: $DIR" >&2
  exit 1
fi

git fetch --prune origin
git pull --ff-only

exec "$DIR/install.sh" "$@"
