-- for miscellaneous Neovim configuration

vim.lsp.set_log_level("error")

-- ensure npm/node are available inside neovim
-- vim.env.path = vim.env.path
--   .. ':/usr/local/bin'
--   .. ':/usr/bin'
--   .. ':/home/dyung/.local/bin'
--   .. ':/home/dyung/.nvm/versions/node/v25.0.0/bin'
--   .. ':/home/dyung/.nvm/versions/node/v25.0.0/bin'

-- if vim.fn.has("win32") == 1 then
--   -- force neovim to use git bash if installed
--   vim.opt.shell = "c:/program files/git/bin/bash.exe"
--   vim.opt.shellcmdflag = "-c"
-- end
