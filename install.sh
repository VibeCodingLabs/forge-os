#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$ROOT_DIR/bin/forge-menu.sh" 2>/dev/null || true
exec "$ROOT_DIR/bin/forge-menu.sh" "$@"
