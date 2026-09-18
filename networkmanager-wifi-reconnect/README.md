# networkmanager-wifi-reconnect (archived, not stowed)

This was a NetworkManager dispatcher script that force-reconnected `wlp4s0`
faster than NetworkManager's own `autoconnect-retries` when it went down.
Originally lived at:

    /etc/NetworkManager/dispatcher.d/90-wifi-reconnect

Removed from `/etc/NetworkManager/dispatcher.d/` on 2026-09-12 because it
wasn't the cause of the disconnects (that turned out to be `iwlwifi`
beacon-loss disconnects on the Intel 8260, related to Bluetooth coexistence
— see `bt_coex_active` in `/etc/modprobe.d/iwlwifi.conf`), and
NetworkManager's built-in autoconnect already handles reconnection without
it.

Kept here for reference / in case it's useful again later. This package is
**not** part of the active stow set — it lives under `etc/` rather than a
`$HOME`-relative path, so `stow` should not be run on it. To restore it
manually:

    sudo cp networkmanager-wifi-reconnect/etc/NetworkManager/dispatcher.d/90-wifi-reconnect \
        /etc/NetworkManager/dispatcher.d/90-wifi-reconnect
    sudo chown root:root /etc/NetworkManager/dispatcher.d/90-wifi-reconnect
    sudo chmod 700 /etc/NetworkManager/dispatcher.d/90-wifi-reconnect
