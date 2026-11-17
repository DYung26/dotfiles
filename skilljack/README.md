# Skilljack configuration

This package manages the non-secret base configuration at `~/.skilljack/config.json`.

Keep shared source configuration in `~/.skilljack/config.json`. Optional machine-specific additions belong in the ignored `~/.skilljack/config.local.json` file. Do not put credentials or private tokens in the tracked base file.

The local overlay is deliberately excluded from both Git and Syncthing. Stow does not manage that file.
