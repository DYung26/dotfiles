-- auto-detect python virtual environment
local venv = os.getenv("virtual_env")
print("venv", venv)
if venv then
  local python_path = venv .. "/scripts/python.exe"
  local scripts_dir = venv .. "/scripts"
  if vim.fn.has("unix") == 1 then
    python_path = venv .. "/bin/python"
    scripts_dir = venv .. "/bin"
  end
  vim.g.python3_host_prog = python_path
  -- tell neovim to use this python for plugins
  vim.g.python3_host_prog = scripts_dir .. "/python"

  -- update neovim's path so :!python, :!pip, etc. use venv too
  vim.env.path = scripts_dir .. (vim.fn.has("win32") == 1 and ";" or ":") .. vim.env.path

  -- optional: print confirmation
  print("venv worked")
else
  print("venv fallback")
  -- fallback to system python if no venv active
  vim.g.python3_host_prog = "c:/users/oyeku/appdata/local/programs/python/python312/python.exe"
end
