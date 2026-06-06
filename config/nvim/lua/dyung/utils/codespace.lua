local M = {}

local function cwd_info()
  local cwd = vim.fn.getcwd()

  cwd = cwd:gsub("^/([A-Za-z])/", "%1:/")

  local folder_name = vim.fn.fnamemodify(cwd, ":t")

  return cwd, folder_name
end

local function run(script, host, remote_path)
  local cwd, folder_name = cwd_info()

  vim.loop.spawn("bash", {
    args = {
      vim.fn.expand(script),
      host,
      remote_path,
      folder_name .. ".tar.gz",
    },
    detached = true,
  }, function()
    vim.schedule(function()
      vim.notify("Completed: " .. script)
    end)
  end)
end

function M.upload_project()
  local cwd = cwd_info()

  run(
    "~/upload-to-codespace.sh",
    "sturdy-space-happiness-rxv7gww64wjh55wv",
    select(1, cwd)
  )
end

function M.download_project()
  local cwd, folder_name = cwd_info()

  run(
    "~/download-from-codespace.sh",
    "sturdy-space-happiness-rxv7gww64wjh55wv",
    "/workspaces/" .. folder_name
  )
end

function M.upload_git_changes()
  local cwd = cwd_info()

  run(
    "~/codespace-upload-git-changes.sh",
    "vigilant-halibut-5g79vx55vxpv244wg",
    select(1, cwd)
  )
end

function M.download_git_changes()
  local _, folder_name = cwd_info()

  run(
    "~/codespace-download-git-changes.sh",
    "vigilant-halibut-5g79vx55vxpv244wg",
    "/workspaces/" .. folder_name
  )
end

return M
