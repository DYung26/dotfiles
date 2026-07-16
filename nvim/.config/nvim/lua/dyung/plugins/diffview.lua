require('diffview').setup({
  keymaps = {
    view = {
      { "n", "<leader>zr", "<Cmd>windo set foldlevel=99<CR>", { desc = "diffview: expand all folds" } },
      { "n", "<leader>zm", "<Cmd>windo set foldlevel=0<CR>", { desc = "diffview: collapse all folds" } },
    },
  },
})
