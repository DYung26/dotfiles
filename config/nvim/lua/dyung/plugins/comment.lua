require('ts_context_commentstring').setup({
  enable_autocmd = false,
})

require('Comment').setup({
  pre_hook = function(ctx)
    local ok, result = pcall(
      require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      ctx
    )
    if ok and result then return result end
    return vim.bo.commentstring
  end,
})
