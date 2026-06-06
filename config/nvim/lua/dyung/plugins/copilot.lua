require("copilot").setup({
  suggestion = {
    enabled = true,
    auto_trigger = true,
    debounce = 75,
    keymap = {
      accept = "<c-l>",
      next = "<c-]>",
      prev = "<c-k>",
      dismiss = "<c-e>",
    },
  },
  panel = {
    enabled = true,
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<cr>",
      refresh = "gr",
      open = "<m-cr>"
    },
  },
  filetypes = {
    markdown = false,
    help = false,
    gitcommit = true,
    ["*"] = true,
  },
})
