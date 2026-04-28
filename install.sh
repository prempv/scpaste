#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${PROJECT_DIR}/scpaste.sh"

chmod +x "$SCRIPT"

missing=0
if ! command -v pngpaste >/dev/null 2>&1 \
   && [[ ! -x /opt/homebrew/bin/pngpaste ]] \
   && [[ ! -x /usr/local/bin/pngpaste ]]; then
  echo "missing: pngpaste   ->  brew install pngpaste"
  missing=1
fi
if [[ ! -d "/Applications/Hammerspoon.app" ]]; then
  echo "missing: Hammerspoon ->  brew install --cask hammerspoon"
  missing=1
fi
if [[ "$missing" -eq 1 ]]; then
  echo
  echo "install the above, then re-run ./install.sh"
  exit 1
fi

# Symlink scpaste into PATH. Prefer /usr/local/bin if writable, else ~/.local/bin.
if [[ -w /usr/local/bin ]] || ( [[ -d /usr/local/bin ]] && [[ "$(stat -f %u /usr/local/bin)" == "$(id -u)" ]] ); then
  TARGET="/usr/local/bin/scpaste"
else
  mkdir -p "${HOME}/.local/bin"
  TARGET="${HOME}/.local/bin/scpaste"
fi

ln -sfn "$SCRIPT" "$TARGET"
echo "linked: $TARGET -> $SCRIPT"

case ":$PATH:" in
  *":$(dirname "$TARGET"):"*) ;;
  *) echo "note: $(dirname "$TARGET") is not on PATH; add it to your shell rc" ;;
esac

cat <<EOF

next steps (Hammerspoon):

  1. open Hammerspoon once and grant accessibility permission.
  2. expose the module to Hammerspoon:
       mkdir -p ~/.hammerspoon
       ln -sfn "${PROJECT_DIR}/init.lua" ~/.hammerspoon/scpaste.lua
  3. add this to your ~/.hammerspoon/init.lua (edit hosts + hotkey to taste):

       local scpaste = require("scpaste")
       scpaste.hosts = {
         { text = "user@host-a", subText = "host-a" },
         { text = "user@host-b", subText = "host-b" },
       }
       scpaste.bind({ "alt", "shift" }, "v")

  4. Hammerspoon menu -> Reload Config.
  5. copy an image, hit your hotkey, pick a host, then Cmd+V in your terminal.

test the CLI directly:
  scpaste --host <user@host-or-ssh-alias> --dry-run
EOF
