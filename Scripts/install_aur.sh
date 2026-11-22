#!/usr/bin/env bash
# Prodi9al Hyprland Config — AUR Package Installer
# Installs optional AUR packages for enhanced functionality.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Prodi9al AUR Package Installer"
echo ""

# Check for an AUR helper
AUR_HELPER=""
for helper in yay paru pamac; do
  if command -v "$helper" &>/dev/null; then
    AUR_HELPER="$helper"
    break
  fi
done

if [[ -z "$AUR_HELPER" ]]; then
  echo "No AUR helper found (yay, paru, or pamac)."
  echo "Install one first, then re-run this script."
  echo "Example: sudo pacman -S --needed base-devel git && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
  exit 1
fi

echo "==> Using AUR helper: $AUR_HELPER"

# Read AUR package list
EXTRA_LIST="$SCRIPTS_DIR/pkg_aur.lst"
if [[ ! -f "$EXTRA_LIST" ]]; then
  echo "No pkg_aur.lst found."
  exit 0
fi

mapfile -t PACKAGES < <(grep -Ev '^[[:space:]]*(#|$)' "$EXTRA_LIST")

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  echo "No extra packages listed."
  exit 0
fi

echo "==> Installing extra packages: ${PACKAGES[*]}"
"$AUR_HELPER" -S --needed --noconfirm "${PACKAGES[@]}"

echo ""
echo "==> AUR package install complete!"
