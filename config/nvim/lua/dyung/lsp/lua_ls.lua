return {
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
}
