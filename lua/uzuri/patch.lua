local all_modules = { "input", "select" }

local M = {}

if not vim.ui then
  vim.ui = {}
end

local enabled_mods = {}
M.original_mods = {}

---@param key string
---@return boolean?
M.is_enabled = function(key)
  local enabled = enabled_mods[key]
  if enabled == nil then
    enabled = require("uzuri.config")[key].enabled
  end
  return enabled
end

for _, key in ipairs(all_modules) do
  M.original_mods[key] = vim.ui[key]
  vim.ui[key] = function(...)
    if M.is_enabled(key) then
      require(string.format("uzuri.%s", key))(...)
    else
      return M.original_mods[key](...)
    end
  end
end

---Patch or unpatch all vim.ui methods
---@param enabled? boolean When nil, use the default from config
M.all = function(enabled)
  for _, name in ipairs(all_modules) do
    M.mod(name, enabled)
  end
end

---@param name string
---@param enabled? boolean When nil, use the default from config
M.mod = function(name, enabled)
  enabled_mods[name] = enabled
end

return M
