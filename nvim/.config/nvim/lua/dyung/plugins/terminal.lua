require("toggleterm").setup({
  direction = "vertical",
  size = function(term)
    if term.direction == "vertical" then
      return vim.o.columns * 0.33
    elseif term.direction == "horizontal" then
      return 15
    end
  end,
  float_opts = {
    border = "curved",
    width = function()
      return math.floor(vim.o.columns * 0.85)
    end,
    height = function()
      return math.floor(vim.o.lines * 0.85)
    end,
  },
  persist_size = true,
  close_on_exit = false, -- keep the process alive when hidden
  start_in_insert = true,
  shell = vim.o.shell,
})

local Terminal = require("toggleterm.terminal").Terminal
local terminal_mod = require("toggleterm.terminal")

-- our own registry, so listing/selecting doesn't depend on toggleterm's
-- internal TermSelect filtering (which wasn't picking these up reliably)
local registry = {} -- id -> Terminal

local function register(term)
  registry[term.id] = term
  return term
end

-- quick-access vertical terminals, created lazily on first use — 1 through 9
local quick_terms = {}
local function get_quick(id)
  if not quick_terms[id] then
    quick_terms[id] = register(Terminal:new({ count = id, direction = "vertical", hidden = true }))
  end
  return quick_terms[id]
end
for i = 1, 9 do
  vim.keymap.set({ "n", "t" }, "<leader>t" .. i, function()
    get_quick(i):toggle()
  end, { desc = "toggle vertical terminal " .. i })
end

-- unlimited: spin up a brand new terminal beyond the quick slots
local next_id = 10
vim.keymap.set({ "n", "t" }, "<leader>ta", function()
  local term = register(Terminal:new({ count = next_id, direction = "vertical", hidden = true }))
  next_id = next_id + 1
  term:toggle()
end, { desc = "add a new terminal" })

-- one persistent floating terminal, for on-demand overlay use
local float_term = register(Terminal:new({ count = 999, direction = "float", hidden = true }))
vim.keymap.set({ "n", "t" }, "<leader>tt", function()
  float_term:toggle()
end, { desc = "toggle float terminal" })

-- list every terminal we've created (open or hidden) and jump to one
vim.keymap.set("n", "<leader>ts", function()
  local items = {}
  for id, term in pairs(registry) do
    if vim.api.nvim_buf_is_valid(term.bufnr or -1) then
      local state = term:is_open() and "open" or "hidden"
      table.insert(items, { id = id, term = term, label = string.format("[%d] %s — %s", id, term.direction, state) })
    end
  end
  if #items == 0 then
    vim.notify("No terminals created yet", vim.log.levels.INFO)
    return
  end
  table.sort(items, function(a, b) return a.id < b.id end)
  vim.ui.select(items, {
    prompt = "Terminals:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if choice then choice.term:open() end
  end)
end, { desc = "list/select terminals" })

-- actually kill (not just hide) the terminal you're currently in
vim.keymap.set("t", "<leader>tk", function()
  local id = vim.b.toggle_number
  if not id then return end
  local term = terminal_mod.get(id)
  if term then
    registry[id] = nil
    term:shutdown()
  end
end, { desc = "kill current terminal" })

-- keep C-h/j/k/l window nav working from inside terminal mode too
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
  vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
end
vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
