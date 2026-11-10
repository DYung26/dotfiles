# Input Leap + BleHid

On the Arch and Omarchy Hyprland clients, `Ctrl+Alt+B` runs
`~/bin/input-leap-blehid` to switch to the Windows host and activate BleHid's
existing iPhone target hotkey.

The helper sends these in order:

1. `Ctrl+Super+W`  matches the Windows Input Leap server binding
   `keystroke(Control+Meta+w) = switchToScreen(LAPTOP-AB9612IK)`.
2. `Ctrl+Alt+CapsLock`  BleHid's existing Windows target-cycle hotkey.

A 400 ms pause separates the two so Input Leap can complete the screen switch
before the BleHid hotkey is forwarded.

Requirements:
- The manually launched `input-leapc` client is connected on the Linux host.
- The Windows Input Leap server has the matching `Control+Meta+W` binding.
- BleHid is running on Windows and the iPhone is paired/subscribed.
- `wtype` is preferred on Wayland; `xdotool` is the fallback.

The Hyprland bindings are local machine configuration: Arch adds an `hl.bind`
in `~/.config/hypr/hyprland.lua`; Omarchy adds an `o.bind` in
`~/.config/hypr/bindings.lua`. The systemd client unit is intentionally not
started by this helper.
