return {
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
      tsserver = { useSyntaxServer = "never" },
    },
    javascript = {
      format = { enable = true },
    },
  },
}
