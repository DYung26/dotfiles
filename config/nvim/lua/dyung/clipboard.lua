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
end

vim.notify("clipboard at vimenter: " .. vim.o.clipboard)

-- SSH clipboard support with OSC 52
--[[ if os.getenv('SSH_TTY') then
    --[[ vim.g.clipboard = {
        name = 'TmuxClipboard',
        copy = {
            ['+'] = {'tmux', 'load-buffer', '-'},
            ['*'] = {'tmux', 'load-buffer', '-'},
        },
        paste = {
            ['+'] = {'tmux', 'save-buffer', '-'},
            ['*'] = {'tmux', 'save-buffer', '-'},
        },
        cache_enabled = 1,
    }

    vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
    }
end ]]


