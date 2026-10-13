-- Consistent, discoverable folding for code, configuration, and prose.
-- Prefer Neovim's LSP folding when an attached server provides it; use
-- Treesitter folding when available, then fall back to indentation folding.

local function has_treesitter_parser(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if ok and parser then
    return true
  end
  return false
end

local function configure_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end

  vim.api.nvim_win_call(win, function()
    -- Do not enable folds in special/prompt buffers.
    if vim.bo[buf].buftype ~= "" then
      vim.wo.foldenable = false
      return
    end

    local clients = vim.lsp.get_clients({ bufnr = buf })
    local supports_lsp_folding = false
    for _, client in ipairs(clients) do
      if client:supports_method("textDocument/foldingRange", buf) then
        supports_lsp_folding = true
        break
      end
    end

    if supports_lsp_folding then
      -- Neovim 0.10+ exposes the LSP folding expression natively.
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
    elseif has_treesitter_parser(buf) then
      -- Modern nvim-treesitter has moved away from the old setup API;
      -- use its language-independent fold query where the query exists.
      local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
      local query_ok = false
      if lang then
        query_ok = pcall(vim.treesitter.query.get, lang, "folds")
      end
      if query_ok then
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      else
        vim.wo.foldmethod = "indent"
      end
    else
      -- Always works, even before parsers or LSP servers load.
      vim.wo.foldmethod = "indent"
    end

    vim.wo.foldenable = true
    vim.wo.foldlevel = 99
    vim.wo.foldcolumn = "1"
    vim.wo.foldtext = "v:lua.require'dyung.folding'.foldtext()"
    vim.wo.foldminlines = 1
  end)
end

local M = {}

function M.foldtext()
  local first = vim.fn.getline(vim.v.foldstart):gsub("^%s+", "")
  local last = vim.v.foldend
  local lines = last - vim.v.foldstart + 1
  local suffix = lines == 1 and " line" or " lines"
  return string.format("  %s  ·  %d%s", first, lines, suffix)
end

function M.refresh()
  configure_buffer(vim.api.nvim_get_current_buf())
end

function M.setup()
  local group = vim.api.nvim_create_augroup("DyungFolding", { clear = true })

  vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
    group = group,
    callback = function(args)
      vim.schedule(function()
        configure_buffer(args.buf)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      vim.schedule(function()
        configure_buffer(args.buf)
      end)
    end,
  })

  -- Make the first view fully expanded; users can then close any structure.
  vim.o.foldlevelstart = 99
  vim.o.foldlevel = 99
  vim.schedule(M.refresh)
end

return M
