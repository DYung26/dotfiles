local wezterm = require 'wezterm'
local act = wezterm.action
local config = {}

wezterm.on("format-tab-title", function(tab)
  local title = tab.tab_title
  if title and #title > 0 then
    return " 🧠 " .. title .. " "
  end
  return " 🧠 " .. tab.active_pane.title .. " "
end)

-- shared config
config.enable_wayland = false
config.color_scheme = "Catppuccin Mocha"

config.font = wezterm.font_with_fallback({
  "FiraCode Nerd Font",
  "JetBrains Mono",
  "Noto Color Emoji",
}, {
  weight = "Bold",
})

config.font_size = 8.0
config.bold_brightens_ansi_colors = true

config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

config.window_background_opacity = 0.75
config.text_background_opacity = 1.0

config.window_background_image_hsb = {
  brightness = 0.1,
  hue = 1.0,
  saturation = 1.0,
}

config.window_decorations = "RESIZE"
config.disable_default_key_bindings = false
config.use_ime = false
config.enable_kitty_keyboard = true

config.keys = {
  {
    key = ",",
    mods = "CTRL|SHIFT",
    action = act.PromptInputLine {
      description = "Rename tab:",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  {
    key = ".",
    mods = "CTRL|SHIFT",
    action = act.PromptInputLine {
      description = "Rename window:",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:set_right_status(line)
          window:set_title(line)
        end
      end),
    },
  },
  {
    key = "w",
    mods = "CTRL|SHIFT",
    action = act.PromptInputLine {
      description = "Rename workspace:",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          wezterm.mux.rename_workspace(window:active_workspace(), line)
        end
      end),
    },
  },
  {
    key = "s",
    mods = "CTRL|SHIFT",
    action = act.PromptInputLine {
      description = "New/switch workspace:",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
    },
  },
  {
    key = "9",
    mods = "CTRL|SHIFT",
    action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" },
  },
}

-- platform-specific overrides
if wezterm.target_triple:find("windows") then
  -- Use Git Bash instead of cmd.exe
  --[[ config.default_prog = {
    "C:/Program Files/Git/bin/bash.exe",
    "-l",
  } ]]

  -- Windows-specific background image
  config.window_background_image = "backgrounds/win-bg.jpg"

elseif wezterm.target_triple:find("apple") then
  config.macos_window_background_blur = 20
  config.window_background_image = "backgrounds/mac-bg.jpg"

else
  -- Linux and others
  config.window_background_image = "/home/dyung/Pictures/Saved Pictures/anime-sky-landscape-purple-hd-wallpaper-preview.jpg"
  -- "backgrounds/linux-bg.jpg"
end

return config
