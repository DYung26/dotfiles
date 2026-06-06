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
    end,
  }
  use {
    'lewis6991/gitsigns.nvim',
    config = function()
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

  use({
    "seblyng/roslyn.nvim",
    config = function()
      require("roslyn").setup({
        -- Add your custom config here later
      })
    end
  })

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
