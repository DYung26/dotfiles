vim.g.loaded_netrw = 1
vim.g.loaded_netrwplugin = 1

require('nvim-tree').setup({
  renderer = {
    indent_markers = {
      enable = true,  -- show indent guides (lines)
      inline_arrows = true, -- optional: small arrows instead of just lines
    },
  },
  filters = {
    dotfiles = false,
    git_ignored = false,
    custom = { ".*sync-conflict.*" },
  },
  git = {
    enable = true,
    ignore = false,
  },
  update_focused_file = {
    enable = true,
    update_root = false, -- Change to true if you want the root to change too
  },
})
--[[{
  actions = {
    open_file = {
      quit_on_open = true, -- optional
    },
  },
  -- this helps prevent duplicate tree buffers
  hijack_directories = {
    enable = false,
  },
})
]]

vim.keymap.set('n', '<leader>nf', ':NvimTreeFindFile<CR>', { desc = 'NvimTree Find File' })
vim.keymap.set('n', '<leader>na', function()
  require('nvim-tree.api').tree.expand_all()
end, { desc = 'NvimTree Expand All' })
vim.keymap.set('n', '<leader>nc', function()
  require('nvim-tree.api').tree.collapse_all()
end, { desc = 'NvimTree Collapse All' })
vim.keymap.set('n', '<c-n>', ':NvimTreeToggle<cr>', { noremap = true, silent = true })
vim.keymap.set('n', '<c-f>', ':NvimTreeFocus<cr>', { noremap = true, silent = true })
