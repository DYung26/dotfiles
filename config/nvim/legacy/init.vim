call plug#begin('~/AppData/Local/nvim/plugged')
" below are some vim plugins for demonstration purpose.
" add the plugin you want to use here.
Plug 'joshdick/onedark.vim'
Plug 'iCyMind/NeoSolarized'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'kyazdani42/nvim-web-devicons' " Optional: for file icons

Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/plenary.nvim' " Required dependency for telescope.nvim
" Plug 'nvim-telescope/telescope-lsp.nvim'

" Completion engine plugin
Plug 'hrsh7th/nvim-cmp'

" LSP (Language Server Protocol) support
Plug 'neovim/nvim-lspconfig'

" Sources for nvim-cmp
Plug 'hrsh7th/cmp-nvim-lsp'  " LSP source for nvim-cmp
Plug 'hrsh7th/cmp-buffer'    " Buffer completions
Plug 'hrsh7th/cmp-path'      " Path completions
Plug 'hrsh7th/cmp-cmdline'   " Command-line completions

" Snippet engine and source
Plug 'L3MON4D3/LuaSnip'      " Snippet engine
Plug 'saadparwaiz1/cmp_luasnip' " Snippet completions

" Snippet collection (for various languages)
Plug 'rafamadriz/friendly-snippets'

" Vertical lines that indicate the identation level of blocks of code
Plug 'lukas-reineke/indent-blankline.nvim'
call plug#end()

set clipboard+=unnamedplus
set wrap
" set foldmethod=indent
" set foldlevel=99
" set foldenable

" set tabstop=2       " Number of spaces a tab counts for
" set shiftwidth=2    " Number of spaces for indentation when using '>'
" set expandtab       " Convert tabs to spaces
" set softtabstop=2   " Makes backspace treat 2 spaces as a tab

"set equalalways " Automatically resize splits when opening/closing
" vim.api.nvim_create_autocmd("VimResized", {
"  pattern = "*",
"  command = "wincmd =",
"})
nnoremap <leader>wl :if &winfixwidth \| set nowinfixwidth nowinfixheight \| echo "🔓 Split Unlocked" \| else \| set winfixwidth winfixheight \| echo "🔒 Split Locked" \| endif<CR>

autocmd FileType html,jsx,typescriptreact setlocal tabstop=2 shiftwidth=2 expandtab

lua << EOF
require("ibl").setup { -- indent-blankline
    indent = { char = '│' },  -- Character used for the vertical lines
    scope = {
        show_start = false,
        show_end = false,
    },
    exclude = {
        filetypes = { "help", "terminal", "dashboard" },
        buftypes = { "nofile" },
    },
}
EOF
" Customize the highlight group to make the indent character bolder
highlight IndentBlanklineChar guifg=#00ff00 "gui=bold

lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "python", "go", "typescript" }, -- or "all"
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
  -- fold = {
  --  enable = true,
  -- },
}
-- set foldmethod='expr'
-- set foldexpr='nvim_treesitter#foldexpr()'

-- nvim-tree configuration
require'nvim-tree'.setup {
  auto_reload_on_write = true, -- Reloads the tree when a file is written to
  disable_netrw = true, -- Disables netrw (recommended)
  hijack_cursor = false, -- Keeps the cursor in the first column
  hijack_netrw = true, -- Hijack netrw window
  hijack_unnamed_buffer_when_opening = false, -- Open the tree if it's not the current buffer
  -- ignore_buffer_on_setup = false, -- Don't open the tree on setup
  -- open_on_setup = false, -- Opens the tree when setting up
  -- open_on_setup_file = false, -- Opens the tree when opening a file
  open_on_tab = false, -- Opens the tree when switching tabs
  -- ignore_ft_on_setup = {}, -- Don't open the tree for specific file types
  update_cwd = true, -- Updates the tree to the current working directory
  respect_buf_cwd = true, -- Respects buffer cwd when opening the tree
  renderer = {
    add_trailing = false, -- Adds a trailing slash to folder names
    group_empty = false, -- Groups empty folders together
    -- highlight_git = true, -- Highlights git changes
    full_name = false, -- Shows full names for files
    root_folder_modifier = ':~', -- Modifier for the root folder
    indent_markers = {
      enable = true, -- Show indent markers
    },
  },
  diagnostics = {
    enable = true, -- Enable diagnostics
    show_on_dirs = true, -- Show diagnostics for directories
    debounce_delay = 50, -- Delay for diagnostics
  },
  filters = {
    dotfiles = false, -- Show dotfiles
    custom = {}, -- Custom filters
  },
  git = {
    enable = true, -- Enable git integration
    ignore = true, -- Show ignored files
    timeout = 1000, -- Git command timeout
  },
  actions = {
    open_file = {
      quit_on_open = false, -- Close the tree when a file is opened
    },
  },
  view = {
    width = 30, -- Tree width
    side = 'left', -- Tree position
    -- hide_root_folder = false, -- Hide the root folder
    preserve_window_proportions = false, -- Preserve window proportions
    number = false, -- Show line numbers
    relativenumber = false, -- Show relative line numbers
    signcolumn = "yes", -- Show the sign column
  }
}
EOF

lua << EOF
require('telescope').setup {
    defaults = {
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
        },
        prompt_prefix = "> ",
        selection_caret = "> ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "descending",
        layout_strategy = "horizontal",
        layout_config = {
            horizontal = {
                mirror = false,
            },
            vertical = {
                mirror = false,
            },
        },
        file_sorter = require'telescope.sorters'.get_fuzzy_file,
        file_ignore_patterns = {},
        generic_sorter = require'telescope.sorters'.get_generic_fuzzy_sorter,
        path_display = {},
        winblend = 0,
        border = {},
        borderchars = {
            '─', '│', '─', '│', '╭', '╮', '╯', '╰'
        },
        color_devicons = true,
        use_less = true,
        set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
        file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
        grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
        qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,

        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker
    }
}
-- Load the LSP extension for Telescope
-- require('telescope').load_extension('lsp_handlers')
EOF

" Keybinding for toggling NvimTree
nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <C-f> :NvimTreeFocus<CR> -- Move focus to the NvimTree window
nnoremap <C-p> :wincmd p<CR> -- Go back to the previous window

" Keybinding for telescope.nvim
nnoremap <leader>ff :Telescope find_files<CR>
nnoremap <leader>fg :Telescope live_grep<CR>
nnoremap <leader>fb :Telescope buffers<CR>
nnoremap <leader>fw :Telescope current_buffer_fuzzy_find<CR>
nnoremap <leader>fh :Telescope help_tags<CR>
" Keybinding for Go to Definition
nnoremap <leader>gd :lua require('telescope.builtin').lsp_definitions()<CR>
" Keybinding for Find References
nnoremap <leader>gr :lua require('telescope.builtin').lsp_references()<CR>

nnoremap <silent>gr :lua vim.lsp.buf.rename()<CR>

" NvimTree keybindings for creating files and directories
let g:nvim_tree_create_file_key = "<Leader>n" " Keybinding for creating files and directories

" Move line up with Shift + Up Arrow
nnoremap <S-Up> :m .-2<CR>==

" Move line down with Shift + Down Arrow
nnoremap <S-Down> :m .+1<CR>==

" Setup nvim-cmp.
lua << EOF
local cmp = require'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(), -- Naviget to the next suggestion
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-y>'] = cmp.config.disable, -- Disable <C-y> for completion confirmation
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item.
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
  })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'cmp_git' }, -- You can specify the `git` source here if you've installed it.
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Setup LSP config.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
require('lspconfig').pyright.setup{
  cmd = { "pyright-langserver.cmd", "--stdio" },
  capabilities = capabilities,
}
require('lspconfig').ts_ls.setup{
  cmd = { "typescript-language-server.cmd", "--stdio" },
  capabilities = capabilities,
}
require('lspconfig').html.setup{
  capabilities = capabilities,
}
require('lspconfig').cssls.setup{
  cmd = { "vscode-css-language-server.cmd", "--stdio" },
  capabilities = capabilities,
}
require('lspconfig').lua_ls.setup{
  capabilities = capabilities,
}
require('lspconfig').clangd.setup{
  capabilities = capabilities,
}
require('lspconfig').gopls.setup{
    cmd = { "gopls" },
    capabilities = capabilities,
}
-- lua require('lsp-config')
EOF

" Save session and save all work
lua << EOF
-- Function to save the session
function save_session()
    local filename = "./*.vim" -- vim.fn.input("Session filename: ", "", "file")
    if filename ~= "" then
        vim.cmd("mksession! " .. filename)
    end
end

-- Keybinding for Ctrl+s
vim.api.nvim_set_keymap('n', '<C-s>', ':wa<CR>:lua save_session()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-q>', ':wqa<CR>:lua save_session()<CR>', { noremap = true, silent = true })
EOF

" Keybinding for replacing in current file and entire codebase
nnoremap <leader>R :%s/<C-r><C-w>//g<Left><Left>
nnoremap <leader>G :grep -r --exclude=.gitignore "<C-r><C-w>" . <CR>:cfdo %s/<C-r><C-w>//gc | update<CR>

" setting the correct shell in Neovim - Git Bash
set shell=C:\PROGRA~1\Git\bin\bash.exe
set shellcmdflag=-c
set shellquote=
set shellxquote=

" Set maximum line length to 80 characters and enable auto-wrap
set textwidth=80
set wrap

" prevent horizontal scrolling -- prevent wrapping in the middle of words
set linebreak

