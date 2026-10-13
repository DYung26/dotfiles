vim.opt.clipboard = "unnamedplus"
vim.opt.shellcmdflag = '-lc'
vim.opt.shellquote = ''
vim.opt.shellxquote = ''
vim.opt.wrap = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.textwidth = 80
vim.opt.colorcolumn = "80"
vim.opt.formatoptions:append("t") -- auto-wrap text using textwidth
vim.opt.formatoptions:append("c") -- wrap comments using textwidth
vim.opt.formatoptions:append("q") -- allow formatting with gq
vim.opt.sessionoptions = {
  "buffers", "curdir", "tabpages", "winsize",
  "help", "globals"
}
vim.opt.termguicolors = true

-- Folding defaults are global; dyung.folding selects the best method per buffer.
vim.opt.foldenable = true
vim.opt.foldlevel = 99       -- start expanded; folds remain available to close
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "1"     -- visible fold guides and clickable fold markers
vim.opt.foldminlines = 1
vim.opt.fillchars:append({ fold = "─", foldopen = "▾", foldclose = "▸", foldsep = "│" })
vim.opt.sessionoptions:append("localoptions")
-- vim.opt.statusline:append " %y"
vim.opt.statusline = "%f %m %r %h %w [%{&filetype}] %=%-14.(%l,%c%v%) %p"

-- vim.o.mouse = "" -- disable mouse

-- vim.opt.shell = 'c:/\"program files\"/git/bin/bash.exe' -- use git bash as shell
