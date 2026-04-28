-- scpaste: Hammerspoon binding.
-- Cmd+Shift+V -> chooser -> scp clipboard image to remote -> remote path on clipboard.
-- Change the hotkey by editing the hs.hotkey.bind line at the bottom.

local M = {}

-- Edit these to match aliases in your ~/.ssh/config (or use user@host).
local hosts = {
  { text = "dev-box-a", subText = "replace with your ssh host alias" },
  { text = "dev-box-b", subText = "replace with your ssh host alias" },
}

-- Absolute path to scpaste.sh. Update if you cloned elsewhere.
local scpasteBin = os.getenv("HOME") .. "/grl/work/scpaste/scpaste.sh"

local function run(host)
  local task = hs.task.new(scpasteBin, function(rc, stdout, stderr)
    if rc == 0 then
      local path = (stdout or ""):gsub("%s+$", "")
      hs.alert.show("-> " .. host .. "\n" .. path, 2)
    else
      local msg = (stderr or "scp failed"):gsub("%s+$", "")
      if msg == "" then msg = "scp failed (rc=" .. tostring(rc) .. ")" end
      hs.alert.show(msg, 3)
    end
  end, { "--host", host })
  task:start()
end

function M.push()
  local chooser = hs.chooser.new(function(choice)
    if not choice then return end
    run(choice.text)
  end)
  chooser:choices(hosts)
  chooser:placeholderText("scpaste -> host")
  chooser:show()
end

-- Change hotkey here, e.g. {"cmd","alt"}, "p"
hs.hotkey.bind({ "cmd", "shift" }, "v", M.push)

return M
