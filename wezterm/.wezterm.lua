local wezterm = require 'wezterm';

wezterm.on("format-tab-title", function(tab)
  local title = tab.active_pane.title
  return " 🧠 " .. title .. " "
end)

return {
  enable_wayland = false,

  -- color_scheme = "Tokyo Night",
  -- color_scheme = "Dracula",
  color_scheme = "Catppuccin Mocha",

  font = wezterm.font_with_fallback ({
    "FiraCode Nerd Font",
    "JetBrains Mono",
    "Noto Color Emoji",
  }, {
    weight = "Bold",
  }),
  font_size = 8.0,
  bold_brightens_ansi_colors = true,

  enable_tab_bar = false,
  hide_tab_bar_if_only_one_tab = true,

  macos_window_background_blur = 20,
  -- window_background_blur = 20,

  window_background_opacity = 0.75,
  text_background_opacity = 1.0,

  -- window_background_image = "/home/dyung/Pictures/Saved Pictures/pix.png",
  window_background_image = "/home/dyung/Pictures/Saved Pictures/anime-sky-landscape-purple-hd-wallpaper-preview.jpg",
  window_background_image_hsb = {
    brightness = 0.1,
    hue = 1.0,
    saturation = 1.0,
  },

  -- colors = {
  --   foreground = "#FFFFFF",
  --   bright_foreground = "#FFFFFF",
  -- },

  window_decorations = "RESIZE",

  disable_default_key_bindings = false,
  use_ime = false,

  enable_kitty_keyboard = true,

  -- debounce_key_events = true
}
