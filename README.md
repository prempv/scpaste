# scpaste

Ship the macOS clipboard image to a remote host's tmp dir over `scp`, and put the
remote path back on your local clipboard. No daemons, no persistent tunnels — a
hotkey + chooser triggers a single `scp` on demand. Designed for pasting images
into Claude Code / Codex CLI running on a remote SSH machine: copy the image,
hit your hotkey, pick the host, then `Cmd+V` in your terminal — what you paste
is `/tmp/clip-<timestamp>.png`, ready for the agent to `Read`.

## Prereqs

- macOS
- `pngpaste` — `brew install pngpaste`
- Hammerspoon — `brew install --cask hammerspoon` (only if you want the hotkey;
  the CLI works standalone without it)
- Key-based ssh auth to your targets (ssh-agent or `IdentityFile` in `~/.ssh/config`).
  `scpaste` runs `scp` with `BatchMode=yes`, so password prompts will fail.

## Install

```sh
./install.sh
```

Installs nothing globally except a symlink to `scpaste` on your `PATH`. Prints
the next steps for wiring the Hammerspoon module into `~/.hammerspoon/`.
Idempotent.

## Usage

### CLI

```sh
scpaste --host my-dev-box
scpaste --host my-dev-box --remote-dir /home/you/scratch
scpaste --host my-dev-box --dry-run
```

### Hotkey via Hammerspoon

After running `install.sh`, add this to your `~/.hammerspoon/init.lua`:

```lua
local scpaste = require("scpaste")
scpaste.hosts = {
  { text = "user@host-a", subText = "host-a" },
  { text = "user@host-b", subText = "host-b" },
}
scpaste.bind({ "alt", "shift" }, "v")
```

Reload Hammerspoon's config (menu bar -> Reload Config). Then:

1. Copy an image to the clipboard (Cmd+Shift+4 + Ctrl, or Cmd+C on an image).
2. Hit `Alt+Shift+V` anywhere on the desktop.
3. Pick the target host in the chooser.
4. Toast confirms; the remote path is on your clipboard.
5. Switch to your terminal and `Cmd+V`.

## Customization

The Hammerspoon module exposes:

- `scpaste.hosts` — list of `{ text = "user@host", subText = "..." }` entries.
- `scpaste.remoteDir` — override the remote directory (default `/tmp` on the host).
- `scpaste.bin` — override the path to the `scpaste` CLI (auto-discovered by default).
- `scpaste.bind(mods, key)` — bind a hotkey. Call once.
- `scpaste.push()` — show the chooser programmatically (use this if you want to
  bind your own hotkey or trigger from a menu).

## Troubleshooting

- **"No image on clipboard"** — clipboard contains text or a file reference, not
  an image. Re-copy the image (screenshot tools always work).
- **"scp failed: ..."** — almost always ssh auth. Test with
  `ssh -o BatchMode=yes <host> true`. If it prompts, fix your key/agent setup.
- **Hotkey does nothing** — Hammerspoon needs Accessibility permission
  (System Settings -> Privacy & Security -> Accessibility). Also check for
  conflicts with other apps binding the same chord.
- **`scpaste` not found** — `~/.local/bin` may not be on `PATH`; add it to your
  shell rc, or re-run `install.sh` after `sudo chown $(id -u) /usr/local/bin`.
