local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "l3mon4d3/luasnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      require("dyung.plugins.cmp")
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("dyung.plugins.telescope")
    end,
  },

  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },

  { "nvim-telescope/telescope-file-browser.nvim" },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("dyung.plugins.tree")
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("dyung.plugins.git")
    end,
  },

  { "tpope/vim-fugitive" },

  {
    "sindrets/diffview.nvim",
    config = function()
      require("dyung.plugins.diffview")
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  {
    "numToStr/Comment.nvim",
    config = function()
      require("dyung.plugins.comment")
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("dyung.plugins.copilot")
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
      local patch = vim.fn.stdpath("config") .. "/scripts/patch-markdown-preview.py"
      local plugin = vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim"
      local output = vim.fn.system({ "python3", patch, plugin })
      if vim.v.shell_error ~= 0 then
        error("Failed to apply markdown-preview.nvim compatibility patches: " .. vim.fn.trim(output))
      end
    end,
    ft = { "markdown" },
    init = function()
      -- Keep the preview bound to localhost; Tailscale Serve exposes it privately.
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = "localhost"
      vim.g.mkdp_port = 8765
      vim.g.mkdp_echo_preview_url = 0
      vim.g.mkdp_combine_preview = 1
      vim.g.mkdp_combine_preview_auto_refresh = 1
      vim.g.mkdp_preview_options = {
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        content_editable = false,
        disable_filename = 0,
        toc = {},
        maid = { theme = "neutral" },
        katex = {},
        uml = {},
        sequence_diagrams = {},
        flowchart_diagrams = {},
      }
      vim.cmd([[
        function! MkdpRemoteOpen(url) abort
          let l:url = substitute(a:url, '^http://[^:]*:[0-9]*', 'https://ubuntu-s-1vcpu-1gb-sfo3-01.tail2e27e5.ts.net:8443', '')
          echom 'Markdown preview (open on your device): ' . l:url
        endfunction
      ]])
      vim.g.mkdp_browserfunc = "MkdpRemoteOpen"
    end,
  },

  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    config = function()
      require("markview").setup({})
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("dyung.plugins.indent")
    end,
  },

  {
    "seblyng/roslyn.nvim",
  },

  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("dyung.plugins.spectre")
    end,
  },

  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = false,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("dyung.plugins.treesitter")
    end,
  },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("dyung.plugins.terminal")
    end,
  },
}, {
  install = {
    missing = true,
  },
  checker = {
    enabled = false,
  },
})
