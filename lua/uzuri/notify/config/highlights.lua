local M = {}

function M.setup()
  vim.cmd([[
    hi default link UzuriNotifyBackground Normal
    hi default UzuriNotifyERRORBorder guifg=#8A1F1F
    hi default UzuriNotifyWARNBorder guifg=#79491D
    hi default UzuriNotifyINFOBorder guifg=#4F6752
    hi default UzuriNotifyDEBUGBorder guifg=#8B8B8B
    hi default UzuriNotifyTRACEBorder guifg=#4F3552
    hi default UzuriNotifyERRORIcon guifg=#F70067
    hi default UzuriNotifyWARNIcon guifg=#F79000
    hi default UzuriNotifyINFOIcon guifg=#A9FF68
    hi default UzuriNotifyDEBUGIcon guifg=#8B8B8B
    hi default UzuriNotifyTRACEIcon guifg=#D484FF
    hi default UzuriNotifyERRORTitle  guifg=#F70067
    hi default UzuriNotifyWARNTitle guifg=#F79000
    hi default UzuriNotifyINFOTitle guifg=#A9FF68
    hi default UzuriNotifyDEBUGTitle  guifg=#8B8B8B
    hi default UzuriNotifyTRACETitle  guifg=#D484FF
    hi default link UzuriNotifyERRORBody Normal
    hi default link UzuriNotifyWARNBody Normal
    hi default link UzuriNotifyINFOBody Normal
    hi default link UzuriNotifyDEBUGBody Normal
    hi default link UzuriNotifyTRACEBody Normal

    hi default link UzuriNotifyLogTime Comment
    hi default link UzuriNotifyLogTitle Special
  ]])
end

M.setup()

vim.cmd([[
  augroup NvimUzuriNotifyRefreshHighlights
    autocmd!
    autocmd ColorScheme * lua require('uzuri.notify.config.highlights').setup()
  augroup END
]])

return M
