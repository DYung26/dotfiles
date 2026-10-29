if vim.fn.has("win32") == 1 then
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
elseif vim.env.SSH_TTY then
  if vim.env.TMUX then
    -- Let tmux/psmux forward OSC 52 to the terminal. This keeps SSH clipboard
    -- integration working on both Linux tmux and Windows psmux without relying
    -- on psmux-specific `load-buffer -w` behavior.
    local osc52 = require("vim.ui.clipboard.osc52")
    vim.g.clipboard = {
      name = "OSC 52 via tmux",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      paste = {
        ["+"] = { "tmux", "save-buffer", "-" },
        ["*"] = { "tmux", "save-buffer", "-" },
      },
    }
  else
    local osc52 = require("vim.ui.clipboard.osc52")
    vim.g.clipboard = {
      name = "OSC 52",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      paste = {
        ["+"] = function() return { {}, "v" } end,
        ["*"] = function() return { {}, "v" } end,
      },
    }
  end
end

vim.notify("clipboard at vimenter: " .. vim.o.clipboard)
