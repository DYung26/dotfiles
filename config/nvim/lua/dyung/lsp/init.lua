local capabilities =
  require("cmp_nvim_lsp").default_capabilities()

local lspconfig = require("lspconfig")

local function with_capabilities(config)
  return vim.tbl_extend(
    "force",
    { capabilities = capabilities },
    config
  )
end

lspconfig.lua_ls.setup(
  with_capabilities(
    require("dyung.lsp.lua_ls")
  )
)

lspconfig.pyright.setup(
  with_capabilities(
    require("dyung.lsp.pyright")
  )
)

lspconfig.ts_ls.setup(
  with_capabilities(
    vim.tbl_extend(
      "force",
      {
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern(
          "tsconfig.json",
          "package.json",
          ".git"
        ),
      },
      require("dyung.lsp.ts_ls")
    )
  )
)

-- lspconfig.golangci_lint_ls.setup({}) -- golang
-- lspconfig.jqls.setup({}) -- jq
