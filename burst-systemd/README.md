# BURST cleanup timer

This package installs only the optional user-level cleanup timer. It is separate from the general systemd package so it can be stowed independently.

Preview and install:

    stow --simulate --verbose --no-folding --target="$HOME" burst-systemd
    stow --no-folding --target="$HOME" burst-systemd
    systemctl --user daemon-reload
    systemctl --user enable --now burst-cleanup.timer

The service runs the BURST CLI from ~/Projects/burst and reads optional provider credentials from ~/.config/burst/providers.env. Keep that file local, mode 0600, and out of Git and Syncthing. Do not create it until provider credentials are ready.

If a provider credential is absent, BURST defers cleanup for that provider and retries on the next hourly run. Codespaces cleanup uses the configured gh-26 profile.
