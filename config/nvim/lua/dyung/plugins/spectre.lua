vim.keymap.set("n", "<leader>S", function()
  require("spectre").toggle()
end, { desc = "Project search and replace" })
