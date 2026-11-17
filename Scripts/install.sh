#!/usr/bin/env bash
# Prodi9al Hyprland Config — Install Script
# Sets up the full Hyprland desktop environment on Arch and Arch-based distros.
# Usage: ./Scripts/install.sh [--aur]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$REPO_DIR/Configs"

BACKUP_DIR="$HOME/.config/cfg_backups"
INSTALL_AUR=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --aur) INSTALL_AUR=true ;;
  esac
done

echo "==> Prodi9al Hyprland Config Installer"
echo ""

# 1. Verify Arch-based Linux
if [[ ! -f /etc/arch-release ]]; then
  echo "ERROR: This installer is designed for Arch and Arch-based distros only."
  echo "   Detected: $(cat /etc/os-release 2>/dev/null | grep '^PRETTY_NAME=' | cut -d'=' -f2 | tr -d '"' || 'unknown')"
  exit 1
fi

# 2. Install system dependencies
echo "==> Installing system dependencies..."
sudo pacman -Syu --needed --noconfirm \
  $(grep -v '^\s*#' "$SCRIPTS_DIR/pkg_core.lst" | tr '\n' ' ') \
  >/dev/null 2>&1

if [[ -f "$SCRIPTS_DIR/pkg_extra.lst" ]]; then
  echo "==> Installing extra packages (pacman)..."
  sudo pacman -S --needed --noconfirm \
    $(grep -v '^\s*#' "$SCRIPTS_DIR/pkg_extra.lst" | tr '\n' ' ') \
    >/dev/null 2>&1 || true
fi

echo "    Dependencies installed."

# 3. Optional AUR packages
if [[ "$INSTALL_AUR" == true ]]; then
  echo "==> Installing AUR packages..."
  if command -v yay &>/dev/null || command -v paru &>/dev/null || command -v pamac &>/dev/null; then
    bash "$SCRIPTS_DIR/install_aur.sh"
  else
    echo "    No AUR helper found (yay, paru, pamac). Skipping AUR packages."
    echo "    Install one first, then run: ./Scripts/install_aur.sh"
  fi
fi

echo ""

# 4. Back up existing configs
echo "==> Backing up existing configs to $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

# Back up .config dirs that will be overwritten
for d in hypr waybar dunst fastfetch gtk-3.0 gtk-4.0 kitty Kvantum nwg-look pypr qt5ct qt6ct swaync wlogout xsettingsd hyde rofi zsh uwsm fish starship swaylock lsd vim satty menus; do
  if [ -d "$HOME/.config/$d" ]; then
    cp -r "$HOME/.config/$d" "$BACKUP_DIR/config-$d" 2>/dev/null || true
    echo "    backed up .config/$d"
  fi
done

# Back up .config/ files that will be overwritten
for f in dolphinrc kdeglobals xdg-terminals.list electron-flags.conf baloofilerc libinput-gestures.conf spotify-flags.conf starship.toml; do
  if [ -f "$HOME/.config/$f" ]; then
    cp "$HOME/.config/$f" "$BACKUP_DIR/$f" 2>/dev/null || true
    echo "    backed up .config/$f"
  fi
done

# Back up .local/share dirs that will be overwritten
for d in themes icons fonts waybar sddm rofi hyde wallbash kio kxmlgui5 xdg-desktop-portal dolphin; do
  if [ -d "$HOME/.local/share/$d" ]; then
    cp -r "$HOME/.local/share/$d" "$BACKUP_DIR/share-$d" 2>/dev/null || true
    echo "    backed up .local/share/$d"
  fi
done

# Back up prodi framework if exists
for d in .local/lib/prodi .local/share/prodi .local/bin/prodi-shell .local/share/hypr; do
  if [ -e "$HOME/$d" ]; then
    cp -r "$HOME/$d" "$BACKUP_DIR/$(basename $d)" 2>/dev/null || true
    echo "    backed up $d"
  fi
done

echo "    Backup complete."

# 5. Restore configs from Configs/ to target locations
echo "==> Restoring configs..."

# Restore .config/ dirs
if [ -d "$CONFIGS_DIR/.config" ]; then
  cp -r "$CONFIGS_DIR/.config/"* "$HOME/.config/"
  echo "    Restored .config/*"
fi

# Restore .local/share/ dirs
if [ -d "$CONFIGS_DIR/.local/share" ]; then
  cp -r "$CONFIGS_DIR/.local/share/"* "$HOME/.local/share/"
  echo "    Restored .local/share/*"
fi

# Restore .local/lib/prodi
if [ -d "$CONFIGS_DIR/.local/lib/prodi" ]; then
  mkdir -p "$HOME/.local/lib/prodi"
  cp -r "$CONFIGS_DIR/.local/lib/prodi/"* "$HOME/.local/lib/prodi/"
  echo "    Restored .local/lib/prodi/*"
fi

# Restore .local/bin/prodi-shell
if [ -f "$CONFIGS_DIR/.local/bin/prodi-shell" ]; then
  mkdir -p "$HOME/.local/bin"
  cp "$CONFIGS_DIR/.local/bin/prodi-shell" "$HOME/.local/bin/prodi-shell"
  chmod +x "$HOME/.local/bin/prodi-shell"
  echo "    Restored .local/bin/prodi-shell"
fi

# Restore .local/share/hypr
if [ -d "$CONFIGS_DIR/.local/share/hypr" ]; then
  mkdir -p "$HOME/.local/share/hypr"
  cp -r "$CONFIGS_DIR/.local/share/hypr/"* "$HOME/.local/share/hypr/"
  echo "    Restored .local/share/hypr/*"
fi

echo "    Config restore complete."

# 6. Make scripts executable
chmod +x "$HOME/.config/waybar/scripts/htb.py" 2>/dev/null || true
chmod +x "$HOME/.local/bin/prodi-shell" 2>/dev/null || true

# 7. HTB token setup (Hack The Box waybar module - optional)
echo ""
echo "==> Hack The Box Waybar Module Setup (optional)"
echo "    The waybar includes a Hack The Box rank module."
echo "    Press Enter to skip."
read -r -p "    Enter your HTB User ID (e.g. 2426022): " HTB_USER_ID || true
read -r -s -p "    Enter your HTB API token: " HTB_TOKEN || true
echo ""

TOKEN_FILE="$HOME/.config/waybar/scripts/htb_token.env"

if [[ -n "${HTB_TOKEN:-}" ]]; then
  echo "export HTB_TOKEN=\"${HTB_TOKEN}\"" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  echo "    Wrote HTB token to $TOKEN_FILE"
else
  echo "    Skipping HTB token (module will show offline)."
  : > "$TOKEN_FILE"
fi

if [[ -n "${HTB_USER_ID:-}" ]]; then
  echo "export HTB_USER_ID=\"${HTB_USER_ID}\"" >> "$TOKEN_FILE"
  echo "    Set HTB_USER_ID=$HTB_USER_ID"
fi

# Persist HTB env vars in shell rc
RC_FILE="$HOME/.bashrc"
if [[ -n "${HTB_TOKEN:-}" ]] || [[ -n "${HTB_USER_ID:-}" ]]; then
  if ! grep -q "HTB_TOKEN\|HTB_USER_ID" "$RC_FILE" 2>/dev/null; then
    {
      echo ""
      echo "# Hack The Box waybar module"
      [[ -n "${HTB_USER_ID:-}" ]] && echo "export HTB_USER_ID=\"${HTB_USER_ID}\""
      [[ -n "${HTB_TOKEN:-}" ]] && echo "export HTB_TOKEN=\"${HTB_TOKEN}\""
    } >> "$RC_FILE"
    echo "    Added HTB env vars to $RC_FILE"
  fi
fi

# 8. Ensure PATH includes local bin
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo "    Added ~/.local/bin to PATH in ~/.bashrc"
fi

echo ""
echo "==> Install complete!"
echo ""
echo "Backup saved at: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or source ~/.bashrc)."
echo "  2. Install fonts (e.g. JetBrainsMono Nerd Font) and icons (e.g. BeautyLine, Bibata)."
echo "  3. Start Hyprland and press SUPER+R to open the menu."
echo "  4. Use \`prodi-shell theme.switch\` to change themes."
echo "  5. Use \`prodi-shell wallpaper\` to manage wallpapers."
