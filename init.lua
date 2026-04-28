-- scpaste: Hammerspoon module.
-- Pops a chooser, scp's the clipboard image to a remote host's tmp dir,
-- puts the resulting remote path on the local clipboard.
--
-- Usage from your ~/.hammerspoon/init.lua:
--
--   local scpaste = require("scpaste")
--   scpaste.hosts = {
--     { text = "user@host-a", subText = "host-a" },
--     { text = "user@host-b", subText = "host-b" },
--   }
--   scpaste.bind({ "alt", "shift" }, "v")

local M = {}

-- Defaults. Override `M.hosts` from your own ~/.hammerspoon/init.lua.
M.hosts = {
  { text = "user@host-a", subText = "replace with your ssh target" },
  { text = "user@host-b", subText = "replace with your ssh target" },
}

-- Optional remote dir override (passed to scpaste.sh as --remote-dir).
M.remoteDir = nil

-- Resolve the scpaste CLI. Set `M.bin` to override.
local function findBin()
  local home = os.getenv("HOME")
  local candidates = {
    home .. "/.local/bin/scpaste",
    "/usr/local/bin/scpaste",
    "/opt/homebrew/bin/scpaste",
  }
  for _, p in ipairs(candidates) do
    local f = io.open(p, "r")
    if f then f:close(); return p end
  end
  return nil
end

local function run(host)
  local bin = M.bin or findBin()
  if not bin then
    hs.alert.show("scpaste binary not found on PATH", 3)
    return
  end
  local args = { "--host", host }
  if M.remoteDir then
    table.insert(args, "--remote-dir")
    table.insert(args, M.remoteDir)
  end
  local task = hs.task.new(bin, function(rc, stdout, stderr)
    if rc == 0 then
      local path = (stdout or ""):gsub("%s+$", "")
      hs.alert.show("-> " .. host .. "\n" .. path, 2)
    else
      local msg = (stderr or "scp failed"):gsub("%s+$", "")
      if msg == "" then msg = "scp failed (rc=" .. tostring(rc) .. ")" end
      hs.alert.show(msg, 3)
    end
  end, args)
  task:start()
end

function M.push()
  local chooser = hs.chooser.new(function(choice)
    if not choice then return end
    run(choice.text)
  end)
  chooser:choices(M.hosts)
  chooser:placeholderText("scpaste -> host")
  chooser:show()
end

function M.bind(mods, key)
  return hs.hotkey.bind(mods, key, M.push)
end

return M
