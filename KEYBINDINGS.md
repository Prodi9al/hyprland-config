# Keybindings

Prodi9al Hyprland Config keybindings are defined in `Configs/.config/hypr/hyprland.lua`.

## Super Key

The `SUPER` key (Windows key) is the primary modifier. A secondary `prodigalMod` modifier is also used for some binds.

## Window Management

| Keybinding | Action |
|------------|--------|
| SUPER + Q | Open Kitty terminal |
| SUPER + C | Close active window |
| SUPER + M | Exit/shutdown (hyprshutdown or Hyprland exit) |
| SUPER + E | File manager (dolphin) |
| SUPER + V | Toggle floating |
| SUPER + R | Open menu (wofi) |
| SUPER + D | App launcher (rofi drun) |
| SUPER + A | App selector (prodi-shell rofilaunch) |
| SUPER + P | Pseudo tile window |
| SUPER + J | Toggle split layout |
| SUPER + S | Toggle special workspace |
| SUPER + SHIFT + S | Move focused window to special workspace |
| SUPER + LEFT/RIGHT/UP/DOWN | Focus window in direction |
| SUPER + 1-10 | Switch to workspace |
| SUPER + SHIFT + 1-10 | Move window to workspace |

## Prodigal Mod Keybindings

| Keybinding | Action |
|------------|--------|
| PRODIGAL + Return | Open terminal |
| PRODIGAL + C | Close window |
| PRODIGAL + SHIFT + C | Open text editor |
| PRODIGAL + SPACE | Toggle floating |
| PRODIGAL + F | Toggle fullscreen |
| PRODIGAL + SHIFT + LEFT/RIGHT/UP/DOWN | Move window direction |

## Volume & Brightness

| Keybinding | Action |
|------------|--------|
| VOLUME_UP / VOLUME_DOWN | Volume control |
| VOLUME_MUTE | Toggle mute |
| XF86AudioMicMute | Toggle mic mute |
| BRIGHTNESS_UP / BRIGHTNESS_DOWN | Brightness control |

## Media Control

| Keybinding | Action |
|------------|--------|
| XF86AudioNext | Next track |
| XF86AudioPause | Pause/play |
| XF86AudioPlay | Play/pause |
| XF86AudioPrev | Previous track |

## System

| Keybinding | Action |
|------------|--------|
| F1 | Cycle display mode |
| F5 | Toggle audio mute |

See `Configs/.config/hypr/hyprland.lua` for the full keybinding configuration.
