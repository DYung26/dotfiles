print("init.lua loaded") -- replace with: vim.notify(...)

require("dyung.options")
require("dyung.keymaps")
require("dyung.autocmds")

require("dyung.plugins")

require("dyung.venv")
require("dyung.clipboard")

require("dyung.mason")
require("dyung.lsp")

require("dyung.core")
