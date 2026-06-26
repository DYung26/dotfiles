-- initialize mason and mason-lspconfig
require("mason").setup({
    registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
    },
})
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
