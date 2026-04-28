# scpaste

Ship the macOS clipboard image to a remote host's tmp dir over `scp`, and put the
remote path back on your local clipboard. No daemons, no persistent tunnels — a
hotkey + chooser triggers a single `scp` on demand. Designed for pasting images
into Claude Code / Codex CLI running on a remote SSH machine: copy the image,
hit `Cmd+Shift+V`, pick the host, then `Cmd+V` in your terminal — what you paste
is `/tmp/clip-<timestamp>.png`, ready for the agent to `Read`.

## Prereqs

- macOS
- `pngpaste` — `brew install pngpaste`
- Hammerspoon — `brew install --cask hammerspoon` (only if you want the hotkey;
  the CLI works without it)
- Key-based ssh auth to your targets (ssh-agent or `IdentityFile` in `~/.ssh/config`).
  `scpaste` runs `scp` with `BatchMode=yes`, so password prompts will fail.

## Install

```sh
./install.sh
```

Installs nothing globally except a symlink to `scpaste` on your `PATH`. Prints
the next steps for wiring `init.lua` into `~/.hammerspoon/`. Idempotent.

After install, edit `init.lua` and replace the `dev-box-a` / `dev-box-b`
placeholders with aliases from your `~/.ssh/config`.

## Usage

1. Copy an image to the clipboard (Cmd+Shift+4 + Ctrl, or Cmd+C on an image).
2. Hit `Cmd+Shift+V` anywhere on the desktop.
3. Pick the target host in the chooser.
4. Toast confirms; the remote path is on your clipboard.
5. Switch to your terminal and `Cmd+V`.

CLI without the hotkey:

```sh
scpaste --host my-dev-box
scpaste --host my-dev-box --remote-dir /home/prem/scratch
scpaste --host my-dev-box --dry-run
```

## Customization

- **Hotkey:** edit the `hs.hotkey.bind` line at the bottom of `init.lua`.
- **Hosts:** edit the `hosts` table at the top of `init.lua`, or externalize
  via `hosts.example.lua` and `require` it.
- **Remote dir:** pass `--remote-dir` from the CLI, or hard-code by editing the
  `task = hs.task.new(...)` args list in `init.lua`.

## Troubleshooting

- **"No image on clipboard"** — clipboard contains text or a file reference, not
  an image. Re-copy the image (screenshot tools always work).
- **"scp failed: ..."** — almost always ssh auth. Test with
  `ssh -o BatchMode=yes <host> true`. If it prompts, fix your key/agent setup.
- **Hotkey does nothing** — Hammerspoon needs Accessibility permission
  (System Settings -> Privacy & Security -> Accessibility). Also check for
  conflicts with other apps binding `Cmd+Shift+V`.
- **`scpaste` not found** — `~/.local/bin` may not be on `PATH`; add it to your
  shell rc, or re-run `install.sh` after `sudo chown $(id -u) /usr/local/bin`.
