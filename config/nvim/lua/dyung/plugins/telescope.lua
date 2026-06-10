local actions = require("telescope.actions")

require('telescope').setup {
  defaults = {
    file_ignore_patterns = { "node_modules", ".git", "dist", "build" }, -- ignore these directories
    path_display = { "smart" }, -- , "filename_first" },  -- options: "truncate", "tail", "smart"
    --[[pickers = {
      lsp_references = { path_display = { "smart" } },
    },]]
    mappings = {
      i = {
        ["<c-s>"] = actions.select_horizontal, -- open in horizontal split
        ["<c-x>"] = actions.select_vertical,   -- open in vertical split
        ["<c-t>"] = actions.select_tab,        -- open in tab
      },
      n = { -- normal mode in telescope
        ["s"] = actions.select_horizontal,
        ["v"] = actions.select_vertical,
        ["t"] = actions.select_tab,
      },
    },
  },
}
-- telescope config for fancier ui
-- require('telescope').load_extension('fzf')
-- require('telescope').load_extension('file_browser')


-- telescope keybinds - https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#pickers
vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, {})                -- lists files in cd
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, {})                 -- live search string in cd
vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, {})                   -- lists open buffers in cnvim instance
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, {})                 -- lists available help tags
vim.keymap.set('n', '<leader>fs', require('telescope.builtin').current_buffer_fuzzy_find, {}) -- live fuzzy search in cbuffer
vim.keymap.set('n', '<leader>fr', require('telescope.builtin').lsp_references, { desc = "lsp references" }) -- lists lsp references for word under the cursor
vim.keymap.set('n', '<leader>fw', require('telescope.builtin').grep_string, {}) -- search for string under cursor or selection in cd
vim.keymap.set('n', '<leader>gd', require('telescope.builtin').lsp_definitions, { desc = 'lsp definitions' }) -- goto or list the definition of the word under the cursor
--[[vim.keymap.set('n', '<leader>fw', function()
  require('telescope.builtin').grep_string({ search = vim.fn.input("grep > ") })
end, {})
]]
-- https://chatgpt.com/s/t_689db88d088c8191804959c539f023bc
