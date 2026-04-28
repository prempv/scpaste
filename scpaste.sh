#!/usr/bin/env bash
set -euo pipefail

# scpaste: ship the macOS clipboard image to a remote host's tmp dir
# and put the remote path on the local clipboard.

HOST=""
REMOTE_DIR="/tmp"
DRY_RUN=0

usage() {
  cat >&2 <<EOF
usage: scpaste --host <name> [--remote-dir <path>] [--dry-run]

  --host        ssh host alias (from ~/.ssh/config) or user@host
  --remote-dir  remote directory for the image (default: /tmp)
  --dry-run     print what would happen, no scp
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --remote-dir) REMOTE_DIR="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

[[ -z "$HOST" ]] && usage

# Resolve pngpaste: brew apple-silicon, brew intel, then PATH.
PNGPASTE=""
for candidate in /opt/homebrew/bin/pngpaste /usr/local/bin/pngpaste; do
  [[ -x "$candidate" ]] && PNGPASTE="$candidate" && break
done
[[ -z "$PNGPASTE" ]] && PNGPASTE="$(command -v pngpaste || true)"
if [[ -z "$PNGPASTE" ]]; then
  echo "pngpaste not found; brew install pngpaste" >&2
  exit 1
fi

TS="$(date +%s)"
LOCAL_PNG="$(mktemp -t scpaste).png"
REMOTE_PNG="${REMOTE_DIR%/}/clip-${TS}.png"

trap 'rm -f "$LOCAL_PNG"' EXIT

if ! "$PNGPASTE" "$LOCAL_PNG" 2>/dev/null; then
  echo "No image on clipboard" >&2
  exit 1
fi
if [[ ! -s "$LOCAL_PNG" ]]; then
  echo "No image on clipboard" >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] scp $LOCAL_PNG ${HOST}:${REMOTE_PNG}"
  echo "[dry-run] pbcopy <- ${REMOTE_PNG}"
  echo "${REMOTE_PNG}"
  exit 0
fi

if ! SCP_ERR="$(scp -q -o BatchMode=yes "$LOCAL_PNG" "${HOST}:${REMOTE_PNG}" 2>&1)"; then
  ONELINE="$(echo "$SCP_ERR" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-200)"
  echo "scp failed: ${ONELINE}" >&2
  exit 1
fi

printf '%s' "$REMOTE_PNG" | pbcopy
echo "$REMOTE_PNG"
