# Migration Guide: Hyprdots to Prodi

This guide helps you migrate from the Hyprdots project to Prodi9al Hyprland Config.

## Overview

Prodi9al Hyprland Config is inspired by the HyDE-Project/HyDE structure but customized for personal use. The directory structure follows a similar pattern:

```
Configs/.config/    -> ~/.config/
Configs/.local/     -> ~/.local/
Scripts/            -> Installation and maintenance scripts
Source/             -> Assets and documentation
dots.toml           -> Dotfile manifest
```

## Key Differences

| HyDE | Prodi9al |
|------|----------|
| `hyde-shell` | `prodi-shell` |
| `hyde.config` | `hyprland.lua` |
| `~/.local/share/hyde/` | `~/.local/share/prodi/` |
| `~/.local/lib/hyde/` | `~/.local/lib/prodi/` |

## Migration Steps

1. Clone this repository
2. Run `./Scripts/install.sh` to install dependencies and restore configs
3. If migrating from HyDE, back up your existing configs first
4. Install fonts and icons manually (not included in repo)
5. Configure your HTB token if using the waybar module

## Theme Names

Theme names follow the pattern `<Theme-Name>` (e.g., `Catppuccin Mocha`, `Jujutsu Kaisen`). Use `prodi-shell theme.switch` to change themes.
