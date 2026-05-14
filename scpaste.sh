#!/usr/bin/env bash
set -euo pipefail

# scpaste: ship the macOS clipboard contents (image bitmap or file/folder
# selection from Finder) to a remote host's tmp dir, and put the remote
# path(s) back on the local clipboard.

SCPASTE_VERSION="0.2.0"

HOST=""
REMOTE_DIR="/tmp"
DRY_RUN=0

usage() {
  cat >&2 <<EOF
usage: scpaste --host <name> [--remote-dir <path>] [--dry-run]
       scpaste --version

  --host        ssh host alias (from ~/.ssh/config) or user@host
  --remote-dir  remote directory for the upload (default: /tmp)
  --dry-run     print what would happen, no scp
  --version     print version and exit
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --remote-dir) REMOTE_DIR="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --version|-V) echo "scpaste ${SCPASTE_VERSION}"; exit 0 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

[[ -z "$HOST" ]] && usage

TS="$(date +%s)"
REMOTE_DIR_TRIMMED="${REMOTE_DIR%/}"

# Resolve pngpaste: brew apple-silicon, brew intel, then PATH.
resolve_pngpaste() {
  local p
  for p in /opt/homebrew/bin/pngpaste /usr/local/bin/pngpaste; do
    [[ -x "$p" ]] && { echo "$p"; return; }
  done
  command -v pngpaste || true
}

# Read file URLs from the macOS pasteboard via NSPasteboard.
# Emits absolute paths, one per line. Empty output = nothing usable.
clipboard_files() {
  osascript -l JavaScript <<'JXA'
ObjC.import('AppKit');
const pb = $.NSPasteboard.generalPasteboard;
const classes = $.NSArray.arrayWithObject($.NSURL);
const urls = pb.readObjectsForClassesOptions(classes, $());
if (!urls || urls.count === 0) { '' }
else {
  const out = [];
  for (let i = 0; i < urls.count; i++) {
    const u = urls.objectAtIndex(i);
    if (u.isFileURL) out.push(ObjC.unwrap(u.path));
  }
  out.join('\n');
}
JXA
}

# scp one local path. Uses -r for directories. Echoes the remote path on success.
push_one() {
  local local_path="$1"
  local base remote
  base="$(basename -- "$local_path")"
  remote="${REMOTE_DIR_TRIMMED}/clip-${TS}-${base}"

  local scp_args=(-q -o BatchMode=yes)
  [[ -d "$local_path" ]] && scp_args+=(-r)

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] scp ${scp_args[*]} \"$local_path\" \"${HOST}:${remote}\"" >&2
    printf '%s' "$remote"
    return 0
  fi

  local err
  if ! err="$(scp "${scp_args[@]}" "$local_path" "${HOST}:${remote}" 2>&1)"; then
    local oneline
    oneline="$(echo "$err" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-200)"
    echo "scp failed: ${oneline}" >&2
    return 1
  fi
  printf '%s' "$remote"
}

# --- try image bitmap first ------------------------------------------------

PNGPASTE="$(resolve_pngpaste)"
LOCAL_PNG="$(mktemp -t scpaste).png"
trap 'rm -f "$LOCAL_PNG"' EXIT

if [[ -n "$PNGPASTE" ]] && "$PNGPASTE" "$LOCAL_PNG" 2>/dev/null && [[ -s "$LOCAL_PNG" ]]; then
  REMOTE_PNG="${REMOTE_DIR_TRIMMED}/clip-${TS}.png"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] scp $LOCAL_PNG ${HOST}:${REMOTE_PNG}" >&2
    echo "[dry-run] pbcopy <- ${REMOTE_PNG}" >&2
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
  exit 0
fi

# --- fall back to file URLs on the pasteboard ------------------------------

FILES_RAW="$(clipboard_files || true)"

FILES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  FILES+=("$line")
done <<< "$FILES_RAW"

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No image or file on clipboard" >&2
  exit 1
fi

REMOTES=()
for f in "${FILES[@]}"; do
  if [[ ! -e "$f" ]]; then
    echo "skipping (missing): $f" >&2
    continue
  fi
  if r="$(push_one "$f")"; then
    REMOTES+=("$r")
  else
    exit 1
  fi
done

if [[ ${#REMOTES[@]} -eq 0 ]]; then
  echo "nothing transferred" >&2
  exit 1
fi

joined="$(printf '%s\n' "${REMOTES[@]}")"
printf '%s' "$joined" | pbcopy
printf '%s\n' "${REMOTES[@]}"
