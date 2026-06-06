print("init.lua loaded") -- replace with: vim.notify(...)

require("dyung.options")
require("dyung.keymaps")
require("dyung.autocmds")

require("dyung.venv")
require("dyung.clipboard")
require("dyung.mason")

require("dyung.plugins")
require("dyung.lsp")

require("dyung.core")
