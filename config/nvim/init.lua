-- ~/.config/nvim/init.lua
print("init.lua loaded")

-- bootstrap packer.nvim if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({
      'git', 'clone', '--depth', '1',
      'https://github.com/wbthomason/packer.nvim', install_path
    })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- plugin setup
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- package manager
  use {
    'nvim-tree/nvim-tree.lua',
    requires = 'nvim-tree/nvim-web-devicons'
  }
  use {
    "williamboman/mason.nvim", -- lsp installer
    run = ":masonupdate"
  }
  use {
    "williamboman/mason-lspconfig.nvim", -- mason integration with lspconfig
    -- tag = "v1.27.0",
  }
  use "neovim/nvim-lspconfig"     -- lsp configurations
  use {
    'hrsh7th/nvim-cmp',           -- completion engine
    requires = {
      'hrsh7th/cmp-nvim-lsp',     -- lsp source for nvim-cmp
      'hrsh7th/cmp-buffer',       -- buffer completions
      'hrsh7th/cmp-path',         -- path completions
      'hrsh7th/cmp-cmdline',      -- command-line completions
      'l3mon4d3/luasnip',         -- snippet engine
      'saadparwaiz1/cmp_luasnip', -- snippet completions
    }
  }
  use {
    'nvim-telescope/telescope.nvim',
    -- tag = '0.2.1',
    requires = {
      {
        'nvim-lua/plenary.nvim'
      }
    }
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make'
  }
  use 'nvim-telescope/telescope-file-browser.nvim'
  use {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
  }
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup({
        mappings = { basic = true, extra = true },
      })
    end
  }
  use {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",       -- load when :Copilot is used
    event = "InsertEnter", -- or when entering insert mode
    config = function()
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
    end,
  }
  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        signs = {
          add          = { text = '+' },
          change       = { text = '~' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
        },
        current_line_blame = true, -- <== enables inline blame text
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- show at end of line
          delay = 100,           -- ms delay before showing
          ignore_whitespace = false,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> • <summary>',
      })
    end
  }
  use 'tpope/vim-fugitive'
  use({
    "iamcco/markdown-preview.nvim",
    run = function()
      vim.fn["mkdp#util#install"]()
    end,
    ft = { "markdown" },
  })
  use {
    "sindrets/diffview.nvim",
    requires = "nvim-lua/plenary.nvim",
  }
  use {
    'MeanderingProgrammer/render-markdown.nvim',
    requires = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  }

  --[[ require('gitblame').setup {
    enabled = true
  }

  use {
    "zbirenbaum/copilot-cmp",
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end
  }
  ]]

  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- vim.opt.shell = 'c:/\"program files\"/git/bin/bash.exe' -- use git bash as shell

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

vim.opt.clipboard = "unnamedplus"
vim.opt.shellcmdflag = '-lc'
vim.opt.shellquote = ''
vim.opt.shellxquote = ''
vim.opt.wrap = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.textwidth = 80
vim.opt.colorcolumn = "80"
vim.opt.formatoptions:append("t") -- auto-wrap text using textwidth
vim.opt.formatoptions:append("c") -- wrap comments using textwidth
vim.opt.formatoptions:append("q") -- allow formatting with gq
vim.opt.sessionoptions = {
  "buffers", "curdir", "tabpages", "winsize",
  "help", "globals"
}
vim.opt.termguicolors = true
vim.opt.sessionoptions:append("localoptions")
-- vim.opt.statusline:append " %y"
vim.opt.statusline = "%f %m %r %h %w [%{&filetype}] %=%-14.(%l,%c%v%) %p"
vim.lsp.set_log_level("error")
-- ensure npm/node are available inside neovim
-- vim.env.path = vim.env.path
--   .. ':/usr/local/bin'
--   .. ':/usr/bin'
--   .. ':/home/dyung/.local/bin'
--   .. ':/home/dyung/.nvm/versions/node/v25.0.0/bin'
--   .. ':/home/dyung/.nvm/versions/node/v25.0.0/bin'

-- if vim.fn.has("win32") == 1 then
--   -- force neovim to use git bash if installed
--   vim.opt.shell = "c:/program files/git/bin/bash.exe"
--   vim.opt.shellcmdflag = "-c"
-- end

require('Comment').setup({
  mappings = {
    basic = true,  -- enables `gcc` & `gc{motion}`
    extra = true,  -- enables `gbc` & `gb{motion}` for block comments
  },
})

-- auto-detect python virtual environment
local venv = os.getenv("virtual_env")
print("venv", venv)
if venv then
  local python_path = venv .. "/scripts/python.exe"
  local scripts_dir = venv .. "/scripts"
  if vim.fn.has("unix") == 1 then
    python_path = venv .. "/bin/python"
    scripts_dir = venv .. "/bin"
  end
  vim.g.python3_host_prog = python_path
  -- tell neovim to use this python for plugins
  vim.g.python3_host_prog = scripts_dir .. "/python"

  -- update neovim's path so :!python, :!pip, etc. use venv too
  vim.env.path = scripts_dir .. (vim.fn.has("win32") == 1 and ";" or ":") .. vim.env.path

  -- optional: print confirmation
  print("venv worked")
else
  print("venv fallback")
  -- fallback to system python if no venv active
  vim.g.python3_host_prog = "c:/users/oyeku/appdata/local/programs/python/python312/python.exe"
end


require("ibl").setup {
  indent = { char = "│" }, -- character for indent guides
  scope = { enabled = true }
}

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

-- vim.o.mouse = "" -- disable mouse

-- _
-- nvimtree config (optional: basic settings)
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

-- initialize mason and mason-lspconfig
require("mason").setup()
-- using the mason hook to automate auto-wiring lsps with a default setup
--[[
  require("mason-lspconfig").setup_handlers {
  -- default setup for all installed servers
  function(server_name)
    require("lspconfig")[server_name].setup({})
  end,
}
]]
-- to later override default customizations of lsps
--[[
require("mason-lspconfig").setup_handlers {
  function(server_name)
    require("lspconfig")[server_name].setup({})
  end,
  ["lua_ls"] = function()
    require("lspconfig").lua_ls.setup({
      settings = {
        lua = {
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    })
  end,
}
]]
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "pyright" }, -- auto-install
  automatic_installation = true,
})

-- nvim-cmp
-- set up capabilities for nvim-cmp to work with lspconfig
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local lspconfig = require("lspconfig")

lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    lua = {
      runtime = {
        version = 'luajit', -- neovim uses luajit
      },
      diagnostics = {
        globals = { 'vim' },
      },
      -- workspace = {
      --   library = vim.api.nvim_get_runtime_file("", true), -- include all runtime files
      --   checkthirdparty = false,                           -- avoid annoying prompts about third-party libraries
      -- },
      telemetry = {
        enable = false,
      },
    },
  },
}) -- lua
lspconfig.pyright.setup({
  capabilities = capabilities,
  settings = {
    python = {
      pythonpath = os.getenv("virtual_env") and (os.getenv("virtual_env") .. "/scripts/python.exe") or "python",
      venvpath = ".",
      venv = "venv",
      analysis = {
        -- exclude large or irrelevant directories from indexing
        exclude = {
          "**/node_modules",
          "**/__pycache__",
          "**/.venv",
          "**/venv",
          "**/build",
          "**/dist",
          "**/*.ipynb"  -- optional: exclude notebooks
        },
        pythonversion = "3.10",
        reportmissingimports = false,
        reportmissingtypestubs = false,
        uselibrarycodefortypes = true,
        autosearchpaths = true,
        extrapaths = { "c:/users/oyeku/plotkit" },
        diagnosticmode = "openfilesonly",
      },
    },
  },
  single_file_support = false, -- optional: faster for multi-buffer sessions
}) -- python
lspconfig.ts_ls.setup({
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("tsconfig.json", "package.json", ".git"),
  single_file_support = false,

  -- ignore large directories for file watching
  on_new_config = function(new_config, new_root_dir)
    new_config.settings = vim.tbl_deep_extend("force", new_config.settings or {}, {
      typescript = {
        tsserver = {
          watchoptions = {
            watchfile = "usefsevents",
            excludedirectories = {
              "**/node_modules",
              "**/dist",
              "**/build",
              "**/.next",
              "**/.turbo",
              "**/coverage",
              "**/.git",
              "**/out",
            },
          },
        },
      },
      javascript = {
        tsserver = {
          watchoptions = {
            excludedirectories = {
              "**/node_modules",
              "**/dist",
              "**/build",
              "**/.next",
              "**/.turbo",
              "**/coverage",
              "**/.git",
              "**/out",
            },
          },
        },
      },
    })
  end,

  init_options = {
    preferences = {
      disablesuggestions = false,
    },
  },

  settings = {
    typescript = {
      format = { enable = true },
      suggest = { completefunctioncalls = true },
    },
    javascript = {
      format = { enable = true },
    },
  },
}) -- javascript/typescript
-- lspconfig.golangci_lint_ls.setup({}) -- golang
-- lspconfig.jqls.setup({}) -- jq

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
vim.o.clipboard = "unnamedplus"
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

-- nvim-cmp
-- set up nvim-cmp.
local cmp = require 'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- for `luasnip` users.
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<c-b>'] = cmp.mapping.scroll_docs(-4),
    ['<c-f>'] = cmp.mapping.scroll_docs(4),
    ['<c-space>'] = cmp.mapping.complete(),
    ['<cr>'] = cmp.mapping.confirm({ select = true }), -- accept currently selected item.
    ['<tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require('luasnip').expand_or_jumpable() then
        require('luasnip').expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ['<s-tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require('luasnip').jumpable(-1) then
        require('luasnip').jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = 'copilot' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  })
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

-- vim.keymap.set(mode, key_combination, command, options)
vim.keymap.set('n', '<c-n>', ':NvimTreeToggle<cr>', { noremap = true, silent = true })      -- toggle file tree with <c-n> -- <leader>n
vim.keymap.set('n', '<c-f>', ':NvimTreeFocus<cr>', { noremap = true, silent = true })       -- toggle file tree with <c-f>
vim.g.mapleader = " " -- "\\"                                                                      -- set leader
vim.g.maplocalleader = "\\"
vim.keymap.set("n", "<leader>ff", "<cmd>telescope find_files<cr>", { desc = "find files" }) -- <leader>ff to open telescope find_files
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

vim.o.clipboard = "unnamedplus"
vim.notify("clipboard at vimenter: " .. vim.o.clipboard)

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


-- keybinds for lsp
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

--[[
vim.keymap.set('n', '<leader>up', function()
  vim.cmd('!~/upload-to-codespace.sh effective-yodel-wrv7jpwpj65g35jrv ~/assessly assessly.tar.gz &')
end, { desc = 'upload to codespace' })
]]

-- upload current working directory to codespace
vim.keymap.set("n", "<leader>p", function()
  -- get current working directory
  local cwd = vim.fn.getcwd()

  -- convert msys path (/c/users/...) → windows style (c:/users/...)
  cwd = cwd:gsub("^/([a-za-z])/", "%1:/")

  -- extract just the folder name
  local folder_name = vim.fn.fnamemodify(cwd, ":t")

  print("codespace upload started...")

  vim.loop.spawn("bash", {
    args = {
      vim.fn.expand("~/upload-to-codespace.sh"),
      "sturdy-space-happiness-rxv7gww64wjh55wv", -- "effective-yodel-wrv7jpwpj65g35jrv",-- "upgraded-space-giggle-4j9rx7vg4jgrc7xgq",
      cwd,
      folder_name .. ".tar.gz"
    },
    detached = true
  }, function()
    vim.schedule(function()
      vim.api.nvim_echo({{"codespace upload completed.", "moremsg"}}, false, {})
    end)
  end)
end, { desc = "upload to codespace" })

vim.keymap.set("n", "<leader>d", function()
  -- get current working directory
  local cwd = vim.fn.getcwd()

  -- convert msys path (/c/users/...) → windows style (c:/users/...)
  cwd = cwd:gsub("^/([a-za-z])/", "%1:/")

  -- extract just the folder name
  local folder_name = vim.fn.fnamemodify(cwd, ":t")

  print("codespace download started...")

  vim.loop.spawn("bash", {
    args = {
      vim.fn.expand("~/download-from-codespace.sh"),
      "sturdy-space-happiness-rxv7gww64wjh55wv", -- "effective-yodel-wrv7jpwpj65g35jrv", -- "upgraded-space-giggle-4j9rx7vg4jgrc7xgq",
      "/workspaces/" .. folder_name, -- string.format("/workspaces/%s", folder_name),
      folder_name .. ".tar.gz"
    },
    detached = true
  }, function()
    vim.schedule(function()
      vim.api.nvim_echo({{"codespace download completed.", "moremsg"}}, false, {})
    end)
  end)
end, { desc = "upload to codespace" })

-- upload git changes to codespace
vim.keymap.set("n", "<leader>cu", function()
  -- get current working directory
  local cwd = vim.fn.getcwd()

  -- convert msys path (/c/users/...) → windows style (c:/users/...)
  cwd = cwd:gsub("^/([a-za-z])/", "%1:/")

  -- extract just the folder name
  local folder_name = vim.fn.fnamemodify(cwd, ":t")

  print("codespace upload started...")

  vim.loop.spawn("bash", {
    args = {
      vim.fn.expand("~/codespace-upload-git-changes.sh"),
      -- "root@api.assessly.dyung.me",
      "vigilant-halibut-5g79vx55vxpv244wg",
      -- "sturdy-space-happiness-rxv7gww64wjh55wv",
      -- "effective-yodel-wrv7jpwpj65g35jrv",
      -- "upgraded-space-giggle-4j9rx7vg4jgrc7xgq",
      cwd,
      folder_name .. ".tar.gz"
    },
    detached = true
  }, function()
    vim.schedule(function()
      vim.api.nvim_echo({{"codespace upload completed.", "moremsg"}}, false, {})
    end)
  end)
end, { desc = "upload to codespace" })

vim.keymap.set("n", "<leader>cd", function()
  -- get current working directory
  local cwd = vim.fn.getcwd()

  -- convert msys path (/c/users/...) → windows style (c:/users/...)
  cwd = cwd:gsub("^/([a-za-z])/", "%1:/")

  -- extract just the folder name
  local folder_name = vim.fn.fnamemodify(cwd, ":t")

  print("codespace download started...")

  vim.loop.spawn("bash", {
    args = {
      vim.fn.expand("~/codespace-download-git-changes.sh"),
      -- "root@api.assessly.dyung.me",
      "vigilant-halibut-5g79vx55vxpv244wg",
      -- "sturdy-space-happiness-rxv7gww64wjh55wv",
      -- "effective-yodel-wrv7jpwpj65g35jrv",
      -- "upgraded-space-giggle-4j9rx7vg4jgrc7xgq",
      "/workspaces/" .. folder_name, -- string.format("/workspaces/%s", folder_name),
      folder_name .. ".tar.gz"
    },
    detached = true
  }, function()
    vim.schedule(function()
      vim.api.nvim_echo({{"codespace download completed.", "moremsg"}}, false, {})
    end)
  end)
end, { desc = "upload to codespace" })
-- ~/download-from-codespace.sh effective-yodel-wrv7jpwpj65g35jrv /workspaces/shaare-backend shaare-backend.tar.gz

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
vim.keymap.set('n', '<leader>nf', ':NvimTreeFindFile<CR>', { desc = 'NvimTree Find File' })
