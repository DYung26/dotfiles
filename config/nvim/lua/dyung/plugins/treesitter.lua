require("nvim-treesitter.configs").setup({
  ensure_installed = {
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
  },

  highlight = {
    enable = true,
  },

  indent = {
    enable = true,
  },
})
