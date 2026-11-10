# Input Leap + BleHid

Use Ctrl+Alt+V on the Linux client to switch Input Leap to Windows, then activate BleHid's iPhone target.

The helper sends Ctrl+Alt+Z, waits 400 ms, then sends Ctrl+Alt+CapsLock.

Input injection backends:
- Omarchy/Hyprland: wtype.
- Arch/GNOME Wayland: ydotool, with the per-user ydotoold service.

On Arch, ydotoold needs access to /dev/uinput; the current session already has a device ACL.
The Windows Input Leap server must have Ctrl+Alt+Z mapped to switch to the Windows host.
BleHid must be running and the iPhone paired/subscribed.
The helper uses the manually launched Input Leap clients; it does not start or alter the unfinished Windows service.
