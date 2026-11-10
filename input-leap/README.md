# Input Leap + BleHid

Use Ctrl+Alt+V on the Linux client to switch Input Leap to the Windows host, then activate BleHid's existing iPhone target hotkey.

The helper sends these in order:

1. Ctrl+Alt+Z to trigger the Windows-switch binding configured in Input Leap.
2. Ctrl+Alt+CapsLock to select/cycle BleHid's target.

A 400 ms pause separates the two keystrokes so the screen switch can complete.

Requirements:
- The manually launched input-leapc client is connected on the Linux host.
- The Windows Input Leap server has Ctrl+Alt+Z configured to switch to that host.
- BleHid is running on Windows and the iPhone is paired/subscribed.
- wtype is used on Omarchy; xdotool is the fallback used on GNOME/Arch.

Ctrl+Alt+V is configured in Omarchy's Hyprland bindings and in Arch's GNOME custom keyboard shortcuts. The unfinished Windows Input Leap service is not managed by this helper.
