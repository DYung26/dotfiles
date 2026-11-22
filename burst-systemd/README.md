# BURST cleanup timer

This package installs only the optional user-level cleanup timer. It is separate from the general systemd package so it can be stowed independently.

Preview and install:

    stow --simulate --verbose --no-folding --target="$HOME" burst-systemd
    stow --no-folding --target="$HOME" burst-systemd
    systemctl --user daemon-reload
    systemctl --user enable --now burst-cleanup.timer

The service runs the BURST CLI from ~/Projects/burst and reads optional provider credentials from ~/.config/burst/providers.env. Store the real file beside providers.env.example at burst-systemd/.config/burst/providers.env in the main dotfiles checkout; Stow links it into ~/.config/burst. Keep the target mode 0600. The real file is excluded from Git and Syncthing; only the placeholder example is tracked.

If a provider credential is absent, BURST defers cleanup for that provider and retries on the next hourly run. Codespaces cleanup uses the configured gh-26 profile.
