local UzuriNotificationBuf = require("uzuri.notify.service.buffer")
local util = require("uzuri.notify.util")

---@class NotificationService
---@field private _running boolean
---@field private _pending FIFOQueue
---@field private _animator WindowAnimator
---@field private _buffers table<integer, UzuriNotificationBuf>
---@field private _fps integer
local UzuriNotificationService = {}

---@class uzuri.notify.ServiceConfig
---@field fps integer

---@param config uzuri.notify.ServiceConfig
function UzuriNotificationService:new(config, animator)
  local service = {
    _config = config,
    _fps = config.fps(),
    _animator = animator,
    _pending = util.FIFOQueue(),
    _running = false,
    _buffers = {},
  }
  self.__index = self
  setmetatable(service, self)
  return service
end

function UzuriNotificationService:_run()
  self._running = true
  local succees, updated = pcall(self._animator.render, self._animator, self._pending, 1 / self._fps)
  if not succees then
    print("Error running notification service: " .. updated)
    self._running = false
    return
  end
  if not updated then
    self._running = false
    return
  end
  vim.defer_fn(function()
    self:_run()
  end, 1000 / self._fps)
end

---@param notif uzuri.notify.Notification;q
---@return integer
function UzuriNotificationService:push(notif)
  local buf = vim.api.nvim_create_buf(false, true)
  local notif_buf = UzuriNotificationBuf(buf, notif, { config = self._config })
  notif_buf:render()
  self._buffers[notif.id] = notif_buf
  self._pending:push(notif_buf)
  if not self._running then
    self:_run()
  end
  return buf
end

function UzuriNotificationService:replace(id, notif)
  local existing = self._buffers[id]
  if not (existing and existing:is_valid()) then
    vim.notify("No matching notification found to replace")
    return
  end
  existing:set_notification(notif)
  self._buffers[id] = nil
  self._buffers[notif.id] = existing
  pcall(existing.render, existing)
  local win = vim.fn.bufwinid(existing:buffer())
  if win ~= -1 then
    -- Highlights can change name if level changed so we have to re-link
    -- vim.wo does not behave like setlocal, thus we use setwinvar to set a
    -- local option. Otherwise our changes would affect subsequently opened
    -- windows.
    -- see e.g. neovim#14595
    vim.fn.setwinvar(
      win,
      "&winhl",
      "Normal:" .. existing.highlights.body .. ",FloatBorder:" .. existing.highlights.border
    )

    vim.api.nvim_win_set_width(win, existing:width())
    vim.api.nvim_win_set_height(win, existing:height())

    self._animator:on_refresh(win)
  end
end

function UzuriNotificationService:dismiss(opts)
  local notif_wins = vim.tbl_keys(self._animator.win_stages)
  for _, win in pairs(notif_wins) do
    pcall(vim.api.nvim_win_close, win, true)
  end
  if opts.pending then
    local cleared = 0
    while self._pending:pop() do
      cleared = cleared + 1
    end
    if not opts.silent then
      vim.notify("Cleared " .. cleared .. " pending notifications")
    end
  end
end

function UzuriNotificationService:pending()
  return self._pending:length()
end

---@return NotificationService
return function(config, animator)
  return UzuriNotificationService:new(config, animator)
end
