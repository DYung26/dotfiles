--[[
vim.api.nvim_create_autocmd("vimenter", {
  callback = function()
    -- print("clipboard =", vim.o.clipboard)
    if vim.fn.argc() == 0 then
      require("nvim-tree.api").tree.open()
    end
  end,
})
]]
vim.api.nvim_create_autocmd("filetype", {
  pattern = {
    "typescript", "typescriptreact", "lua", "javascript", "javascriptreact",
  },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
    vim.bo.formatexpr = ""
    vim.bo.indentexpr = ""
  end,
})
vim.api.nvim_create_autocmd("filetype", {
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("lspattach", {
  callback = function(args)
    local buf = args.buf
    local ft = vim.bo[buf].filetype

    -- language-specific indentation rules
    if ft == "typescriptreact" or ft == "lua"
       or ft == "javascript" or ft == "javascriptreact" then
      vim.bo[buf].shiftwidth = 2
      vim.bo[buf].tabstop = 2
      vim.bo[buf].expandtab = true
    elseif ft == "typescript" then
      vim.bo[buf].shiftwidth = 2
      vim.bo[buf].tabstop = 2
      vim.bo[buf].expandtab = true
    elseif ft == "python" then
      vim.bo[buf].shiftwidth = 4
      vim.bo[buf].tabstop = 4
      vim.bo[buf].expandtab = true
    end
  end,
})

vim.api.nvim_create_autocmd("sessionloadpost", {
  callback = function()
    require("nvim-tree.api").tree.open()
  end
})
-- Manually trigger an OSC 52 broadcast on every yank
-- This sends the text "through" SSH/Tmux to your local machine
vim.api.nvim_create_autocmd("TextYankPost", {
    --[[ callback = function()
        if vim.v.event.operator == "y" and vim.v.event.regname == "+" or vim.v.event.regname == "" then
            require('vim.ui.clipboard.osc52').copy('+')(vim.v.event.regcontents)
        end
    end, ]]
    callback = function()
        -- Trigger if the yank went to the default register or the system clipboard
        local reg = vim.v.event.regname
        if reg == "+" or reg == "*" or reg == "" then
            require('vim.ui.clipboard.osc52').copy('+')(vim.v.event.regcontents)
        end
    end,
})

--[[vim.api.nvim_create_user_command("resizetolongestline", function()
  local max_length = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local len = vim.fn.strdisplaywidth(line)
    if len > max_length then
      max_length = len
    end
  end
  vim.api.nvim_win_set_width(0, max_length + 2) -- +2 for padding
end, {})

vim.api.nvim_create_user_command("resizealltolongestline", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local max_length = 0

    for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      local len = vim.fn.strdisplaywidth(line)
      if len > max_length then
        max_length = len
      end
    end

    vim.api.nvim_win_set_width(win, max_length + 2)  -- add padding
  end
end, {})

vim.api.nvim_create_autocmd({ "bufreadpost", "bufwinenter" }, {
  pattern = "*",
  callback = function()
    vim.cmd("resizetolongestline")
  end,
})
]]
