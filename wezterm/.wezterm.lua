local wezterm = require 'wezterm'
local config = {}

wezterm.on("format-tab-title", function(tab)
  local title = tab.active_pane.title
  return " 🧠 " .. title .. " "
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
