-- keybinds for lsp

vim.g.mapleader = " " -- "\\"                                                                      -- set leader
vim.g.maplocalleader = "\\"


vim.keymap.set('n', '<leader>gv', 'ggvggq', { desc = 'format/wrap whole file' }) -- ggvg=
--[[vim.keymap.set('n', '<leader>fw', function()
  vim.opt.formatoptions:append("t") -- ensure wrap flag is on
  vim.cmd('normal! ggvggq')
end, { desc = 'format/wrap whole file' })
]]

-- rename symbol (variable, function, etc.)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "rename symbol" })
-- keybinding for replacing in current file and entire codebase

-- nnoremap <leader>r :%s/<c-r><c-w>//g<left><left>
-- replace word under cursor in current buffer
vim.keymap.set("n", "<leader>r", function()
  local word = vim.fn.expand("<cword>")
  vim.ui.input({ prompt = "replace '" .. word .. "' with: " }, function(repl)
    if repl then
      -- perform substitution globally
      vim.cmd(string.format("%%s/%s/%s/g", word, repl))
    end
  end)
end, { desc = "replace word under cursor in file interactively" })

-- nnoremap <leader>g :grep -r --exclude=.gitignore "<c-r><c-w>" . <cr>:cfdo %s/<c-r><c-w>//gc | update<cr>
-- project-wide search and replace with confirmation
vim.keymap.set("n", "<leader>g", function()
  local word = vim.fn.expand("<cword>")
  -- fill the quickfix list with grep results
  vim.cmd(string.format("grep! -r --exclude=.gitignore '%s' .", word))

  -- prompt user for replacement
  vim.ui.input({ prompt = "replace '" .. word .. "' with (empty to delete): " }, function(repl)
    if repl == nil then return end -- user cancelled

    -- apply replacement to all files in quickfix
    local qflist = vim.fn.getqflist()
    for _, item in ipairs(qflist) do
      local filename = item.filename
      vim.cmd(string.format("edit %s", filename))  -- open file
      vim.cmd(string.format("%%s/%s/%s/g", word, repl))  -- replace
      vim.cmd("update") -- save if modified
    end
    print("replacement done!")
  end)
end, { desc = "grep & replace word under cursor across project interactively" })

-- vim.keymap.set("n", "<leader>g", function()
--   local word = vim.fn.expand("<cword>")
--   vim.cmd(string.format("grep! -r --exclude=.gitignore '%s' .", word))
--   vim.cmd(string.format("cfdo %%s/%s//gc | update", word))
-- end, { desc = "grep & replace word under cursor (fast)" })


vim.keymap.set('n', 'gr', vim.lsp.buf.rename, { silent = true })
-- find all references of the symbol under cursor
vim.keymap.set('n', '<leader>gfr', vim.lsp.buf.references, { desc = "find references" })
-- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'go to definition' })
vim.keymap.set("n", "<leader>gd", function()
  vim.cmd("vsp")
  vim.lsp.buf.definition()
end, { desc = "go to definition in vsplit" })
vim.keymap.set("n", "<leader>gt", function()
  vim.cmd("tab split")
  vim.lsp.buf.definition()
end, { desc = "go to definition in new tab" })

vim.keymap.set("n", "<leader>tn", ":tabnew<cr>", { desc = "new tab" })
vim.keymap.set("n", "<leader>to", ":tabonly<cr>", { desc = "only this tab" })
vim.keymap.set("n", "<leader>tc", ":tabclose<cr>", { desc = "close tab" })
vim.keymap.set("n", "<leader>tl", ":tabnext<cr>", { desc = "next tab" })
vim.keymap.set("n", "<leader>th", ":tabprevious<cr>", { desc = "previous tab" })

vim.keymap.set("n", "<leader>yf", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  require('vim.ui.clipboard.osc52').copy('+')({path})
  print("copied: " .. path)
end, { desc = "yank file path" })

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "show diagnostics" })
vim.keymap.set("i", "<c-k>", vim.lsp.buf.signature_help, { desc = "signature help" })
-- indent and keep selection
vim.keymap.set("v", ">", ">gv", { desc = "indent and keep visual selection" })
vim.keymap.set("v", "<", "<gv", { desc = "outdent and keep visual selection" })

vim.keymap.set('n', '<leader>gb', '<cmd>Gitsigns toggle_current_line_blame<CR>', { desc = "Toggle git blame" })

vim.keymap.set("n", "<leader>wl", function()
  if vim.wo.winfixwidth then
    vim.wo.winfixwidth = false
    vim.wo.winfixheight = false
    vim.cmd('echo "🔓 split unlocked"')
  else
    vim.wo.winfixwidth = true
    vim.wo.winfixheight = true
    vim.cmd('echo "🔒 split locked"')
  end
end, { desc = "toggle split lock" })

-- vim.keymap.set(mode, key_combination, command, options)

local codespace = require("dyung.utils.codespace")

vim.keymap.set("n", "<leader>p", codespace.upload_project)
vim.keymap.set("n", "<leader>d", codespace.download_project)

vim.keymap.set("n", "<leader>cu", codespace.upload_git_changes)
vim.keymap.set("n", "<leader>cd", codespace.download_git_changes)
