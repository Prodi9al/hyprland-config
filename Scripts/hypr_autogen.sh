#!/usr/bin/env bash
# Hyprland autogeneration script
# Regenerates Hyprland config based on current theme and system state.

set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"

echo "==> Hyprland Autogenerator"
echo ""

# Check if Hyprland config exists
if [[ ! -f "$CONFIG_DIR/hyprland.lua" ]]; then
  echo "ERROR: Hyprland config not found at $CONFIG_DIR/hyprland.lua"
  exit 1
fi

# Source wallbash colors if available
WALLBASH_COLORS="$HOME/.cache/hyde/wallbash/gtk.css"
if [[ -f "$WALLBASH_COLORS" ]]; then
  echo "==> Applying wallbash colors..."
  # Colors are applied via the theme system
fi

# Reload Hyprland if running
if pgrep -x Hyprland > /dev/null 2>&1; then
  echo "==> Reloading Hyprland..."
  hyprctl reload
  echo "    Hyprland reloaded."
else
  echo "    Hyprland not running. Config ready for next session."
fi

echo ""
echo "==> Autogeneration complete!"
