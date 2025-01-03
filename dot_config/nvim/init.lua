require("config.lazy")

vim.opt.number = true
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true
vim.bo.softtabstop = 4

vim.cmd [[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
]]
