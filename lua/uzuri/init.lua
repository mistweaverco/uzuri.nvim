local patch = require("uzuri.patch")

local M = {}

M.setup = function(opts)
  opts = opts or {}
  require("uzuri.config").update(opts)
  if opts.notify ~= false then
    require("uzuri.notify").setup(opts.notify)
    vim.notify = require("uzuri.notify") --luacheck: ignore
  end
  M.patch()
end

---Patch all the vim.ui methods
M.patch = function()
  if vim.fn.has("nvim-0.10") == 0 then
    vim.notify_once("uzuri has dropped support for Neovim <0.10. Please upgrade Neovim", vim.log.levels.ERROR)
    return
  end
  patch.all()
end

---Unpatch all the vim.ui methods
---@param names? string[] Names of vim.ui modules to unpatch
M.unpatch = function(names)
  if not names then
    return patch.all(false)
  elseif type(names) ~= "table" then
    names = { names }
  end
  for _, name in ipairs(names) do
    patch.mod(name, false)
  end
end

return M
