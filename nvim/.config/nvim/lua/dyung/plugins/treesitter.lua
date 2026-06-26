local ts = require("nvim-treesitter")

ts.setup({})

local ensure_installed = {
  "lua",
  "vim",
  "vimdoc",
  "bash",
  "markdown",
  "markdown_inline",
  "python",
  "typescript",
  "javascript",
  "json",
  "yaml",
  "toml",
}

local installed = require("nvim-treesitter.config").get_installed()

local missing = vim
  .iter(ensure_installed)
  :filter(function(parser)
    return not vim.tbl_contains(installed, parser)
  end)
  :totable()

ts.install(missing)
