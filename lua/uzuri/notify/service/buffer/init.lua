local api = vim.api

local UzuriNotifyBufHighlights = require("uzuri.notify.service.buffer.highlights")

---@class UzuriNotificationBuf
---@field highlights UzuriNotifyBufHighlights
---@field _config table
---@field _notif uzuri.notify.Notification
---@field _state "open" | "closed"
---@field _buffer number
---@field _height number
---@field _width number
---@field _max_width number | nil
local UzuriNotificationBuf = {}

local BufState = {
  OPEN = "open",
  CLOSED = "close",
}

function UzuriNotificationBuf:new(kwargs)
  local notif_buf = {
    _config = kwargs.config,
    _max_width = kwargs.max_width,
    _buffer = kwargs.buffer,
    _state = BufState.CLOSED,
    _width = 0,
    _height = 0,
  }
  setmetatable(notif_buf, self)
  self.__index = self
  notif_buf:set_notification(kwargs.notif)
  return notif_buf
end

function UzuriNotificationBuf:set_notification(notif)
  self._notif = notif
  self:_create_highlights()
end

function UzuriNotificationBuf:_create_highlights()
  local existing_opacity = self.highlights and self.highlights.opacity or 100
  self.highlights = UzuriNotifyBufHighlights(self._notif.level, self._buffer, self._config)
  if existing_opacity < 100 then
    self.highlights:set_opacity(existing_opacity)
  end
end

function UzuriNotificationBuf:open(win)
  if self._state ~= BufState.CLOSED then
    return
  end
  self._state = BufState.OPEN
  local record = self._notif:record()
  if self._notif.on_open then
    self._notif.on_open(win, record)
  end
  if self._config.on_open() then
    self._config.on_open()(win, record)
  end
end

function UzuriNotificationBuf:should_animate()
  return self._notif.animate
end

function UzuriNotificationBuf:close(win)
  if self._state ~= BufState.OPEN then
    return
  end
  self._state = BufState.CLOSED
  vim.schedule(function()
    if self._notif.on_close then
      self._notif.on_close(win)
    end
    if self._config.on_close() then
      self._config.on_close()(win)
    end
    pcall(api.nvim_buf_delete, self._buffer, { force = true })
  end)
end

function UzuriNotificationBuf:height()
  return self._height
end

function UzuriNotificationBuf:width()
  return self._width
end

function UzuriNotificationBuf:should_stay()
  if self._notif.keep then
    return self._notif.keep()
  end
  return false
end

function UzuriNotificationBuf:render()
  local notif = self._notif
  local buf = self._buffer

  local render_namespace = require("uzuri.notify.render.base").namespace()
  api.nvim_buf_set_option(buf, "filetype", "notify")
  api.nvim_buf_set_option(buf, "modifiable", true)
  api.nvim_buf_clear_namespace(buf, render_namespace, 0, -1)

  notif.render(buf, notif, self.highlights, self._config)

  api.nvim_buf_set_option(buf, "modifiable", false)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local width = self._config.minimum_width()
  for _, line in pairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  local success, extmarks =
    pcall(api.nvim_buf_get_extmarks, buf, render_namespace, 0, #lines, { details = true })
  if not success then
    extmarks = {}
  end
  local virt_texts = {}
  for _, mark in ipairs(extmarks) do
    local details = mark[4]
    for _, virt_text in ipairs(details.virt_text or {}) do
      virt_texts[mark[2]] = (virt_texts[mark[2]] or "") .. virt_text[1]
    end
  end
  for _, text in pairs(virt_texts) do
    width = math.max(width, vim.api.nvim_strwidth(text))
  end

  self._width = width
  self._height = #lines
end

function UzuriNotificationBuf:timeout()
  return self._notif.timeout
end

function UzuriNotificationBuf:buffer()
  return self._buffer
end

function UzuriNotificationBuf:is_valid()
  return self._buffer and vim.api.nvim_buf_is_valid(self._buffer)
end

function UzuriNotificationBuf:level()
  return self._notif.level
end

---@param buf number
---@param notification uzuri.notify.Notification;q
---@return UzuriNotificationBuf
return function(buf, notification, opts)
  return UzuriNotificationBuf:new(
    vim.tbl_extend("keep", { buffer = buf, notif = notification }, opts or {})
  )
end
