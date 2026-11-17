#!/usr/bin/env bash
# Prodi9al Hyprland Config — Uninstall Script
# Removes all dotfiles and restores backups if available.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$(dirname "${SCRIPTS_DIR}")" && pwd)"
CONFIGS_DIR="$REPO_DIR/Configs"

BACKUP_DIR="$HOME/.config/cfg_backups"

echo "==> Prodi9al Hyprland Config Uninstaller"
echo ""

read -r -p "This will remove all restored dotfiles. Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Remove restored .config/ dirs
echo "==> Removing restored .config/ dirs..."
for d in hypr waybar dunst fastfetch gtk-3.0 gtk-4.0 kitty Kvantum nwg-look pypr qt5ct qt6ct swaync wlogout xsettingsd hyde rofi zsh uwsm fish starship swaylock lsd vim satty menus; do
  if [ -d "$HOME/.config/$d" ]; then
    rm -rf "$HOME/.config/$d"
    echo "    removed .config/$d"
  fi
done

# Remove restored .config/ files
for f in dolphinrc kdeglobals xdg-terminals.list electron-flags.conf baloofilerc libinput-gestures.conf spotify-flags.conf; do
  if [ -f "$HOME/.config/$f" ]; then
    rm -f "$HOME/.config/$f"
    echo "    removed .config/$f"
  fi
done

# Remove restored .local/share/ dirs
echo "==> Removing restored .local/share/ dirs..."
for d in themes waybar rofi sddm wallbash kio kxmlgui5 xdg-desktop-portal dolphin; do
  if [ -d "$HOME/.local/share/$d" ]; then
    rm -rf "$HOME/.local/share/$d"
    echo "    removed .local/share/$d"
  fi
done

# Remove prodi framework
echo "==> Removing Prodi framework..."
for d in .local/lib/prodi .local/share/prodi .local/bin/prodi-shell .local/share/hypr; do
  if [ -e "$HOME/$d" ]; then
    rm -rf "$HOME/$d"
    echo "    removed $d"
  fi
done

# Restore from backup if available
if [ -d "$BACKUP_DIR" ]; then
  echo "==> Restoring from backup at $BACKUP_DIR..."
  for backup in "$BACKUP_DIR"/config-* "$BACKUP_DIR"/share-* "$BACKUP_DIR"/prodi-* "$BACKUP_DIR"/hypr; do
    [ -e "$backup" ] || continue
    name=$(basename "$backup")
    if [[ "$name" == config-* ]]; then
      target="$HOME/.config/${name#config-}"
    elif [[ "$name" == share-* ]]; then
      target="$HOME/.local/share/${name#share-}"
    elif [[ "$name" == prodi-* ]]; then
      target="$HOME/.local/${name#prodi-}"
    else
      target="$HOME/.local/share/hypr"
    fi
    if [ -d "$backup" ]; then
      cp -r "$backup" "$target"
      echo "    restored $target"
    elif [ -f "$backup" ]; then
      cp "$backup" "$target"
      echo "    restored $target"
    fi
  done
fi

# Remove PATH and HTB env additions from .bashrc
RC_FILE="$HOME/.bashrc"
if [ -f "$RC_FILE" ]; then
  echo "==> Cleaning up $RC_FILE..."
  sed -i '/# Hack The Box waybar module/d' "$RC_FILE" 2>/dev/null || true
  sed -i '/export HTB_USER_ID=/d' "$RC_FILE" 2>/dev/null || true
  sed -i '/export HTB_TOKEN=/d' "$RC_FILE" 2>/dev/null || true
  sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$RC_FILE" 2>/dev/null || true
  echo "    Cleaned up $RC_FILE"
fi

echo ""
echo "==> Uninstall complete!"
echo "    Backup (if any) kept at: $BACKUP_DIR"
