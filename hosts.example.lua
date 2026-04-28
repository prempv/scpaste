-- Optional: externalize your hosts list to its own file.
-- Save this as ~/.hammerspoon/scpaste_hosts.lua, then in init.lua replace the
-- inline `hosts` table with:
--
--   local hosts = require("scpaste_hosts")
--
-- Add a third entry by appending another row.

return {
  { text = "dev-box-a",  subText = "primary work box" },
  { text = "dev-box-b",  subText = "secondary / staging" },
  { text = "user@10.0.0.42", subText = "ad-hoc, not in ssh config" },
}
