require('gitsigns').setup({
  signs = {
    add          = { text = '+' },
    change       = { text = '~' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
  },
  current_line_blame = true, -- <== enables inline blame text
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- show at end of line
    delay = 100,           -- ms delay before showing
    ignore_whitespace = false,
  },
  current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> • <summary>',
})
