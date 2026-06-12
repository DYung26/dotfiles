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
    end,
    ft = { "markdown" },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("dyung.plugins.markdown")
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
}
}, {
  install = {
    missing = true,
  },
  checker = {
    enabled = false,
  },
})
