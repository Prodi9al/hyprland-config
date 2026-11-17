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
SKIP_SYS_UPDATE=false
DRY_RUN=false

# Source shared backup naming utility
# shellcheck source=./backup-utils.sh
# shellcheck disable=SC1091
. "$SCRIPTS_DIR/backup-utils.sh"

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --aur) INSTALL_AUR=true ;;
    --skip-sys-update) SKIP_SYS_UPDATE=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

echo "==> Prodi9al Hyprland Config Installer"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "==> DRY RUN MODE — no changes will be made"
  echo ""
fi

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] $*"
  else
    "$@"
  fi
}

safe_backup() {
  local src="$1"
  local dst="$2"
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$src\" \"$dst\""
    return 0
  fi
  if ! cp -a "$src" "$dst" 2>/dev/null; then
    echo "FATAL: Failed to back up $src to $dst — aborting before any data loss."
    exit 1
  fi
}

safe_write_file() {
  local content="$1"
  local dst="$2"
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] write \"$dst\""
    return 0
  fi
  # Write with single-quoted heredoc to avoid shell interpretation of special chars
  printf '%s\n' "$content" > "$dst"
}

# 1. Verify Arch-based Linux
if [[ ! -f /etc/arch-release ]]; then
  echo "ERROR: This installer is designed for Arch and Arch-based distros only."
  echo "   Detected: $(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo 'unknown')"
  exit 1
fi

# 2. Install system dependencies
echo "==> Installing system dependencies..."
mapfile -t PKG_LIST < <(grep -Ev '^[[:space:]]*(#|$)' "$SCRIPTS_DIR/pkg_core.lst")
echo "    Packages: ${PKG_LIST[*]}"

if [[ "$SKIP_SYS_UPDATE" == true ]]; then
  echo "    Skipping system update (--skip-sys-update)."
else
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] sudo pacman -Syu --needed --noconfirm ${PKG_LIST[*]}"
  else
    read -r -p "    Run 'sudo pacman -Syu' to update system first? [y/N] " confirm_sysupdate
    if [[ "$confirm_sysupdate" =~ ^[Yy]$ ]]; then
      sudo pacman -Syu --needed --noconfirm
    else
      echo "    Skipping system update."
    fi
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "    [DRY RUN] sudo pacman -S --needed --noconfirm ${PKG_LIST[*]}"
else
  sudo pacman -S --needed --noconfirm "${PKG_LIST[@]}"
fi

echo "    Core dependencies installed."

if [[ -f "$SCRIPTS_DIR/pkg_extra.lst" ]]; then
  echo "==> Installing extra packages (pacman)..."
  mapfile -t EXTRA_LIST < <(grep -Ev '^[[:space:]]*(#|$)' "$SCRIPTS_DIR/pkg_extra.lst")
  echo "    Packages: ${EXTRA_LIST[*]}"

  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] sudo pacman -S --needed --noconfirm ${EXTRA_LIST[*]}"
  else
    sudo pacman -S --needed --noconfirm "${EXTRA_LIST[@]}"
  fi
  echo "    Extra packages installed."
fi

echo ""

# 3. Optional AUR packages
if [[ "$INSTALL_AUR" == true ]]; then
  echo "==> Installing AUR packages..."
  if command -v yay &>/dev/null || command -v paru &>/dev/null || command -v pamac &>/dev/null; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "    [DRY RUN] bash $SCRIPTS_DIR/install_aur.sh"
    else
      bash "$SCRIPTS_DIR/install_aur.sh"
    fi
  else
    echo "    No AUR helper found (yay, paru, pamac). Skipping AUR packages."
    echo "    Install one first, then run: ./Scripts/install_aur.sh"
  fi
fi

echo ""

# 4. Back up existing configs
echo "==> Backing up existing configs to $BACKUP_DIR..."
if [[ "$DRY_RUN" == true ]]; then
  echo "    [DRY RUN] Would create backup directory: $BACKUP_DIR"
  echo "    [DRY RUN] Would back up existing config files/directories"
else
  mkdir -p "$BACKUP_DIR"

# Back up .config dirs that will be overwritten
for d in hypr waybar dunst fastfetch gtk-3.0 gtk-4.0 kitty Kvantum nwg-look pypr qt5ct qt6ct swaync wlogout xsettingsd hyde rofi zsh uwsm fish starship swaylock lsd vim satty menus; do
  if [ -d "$HOME/.config/$d" ]; then
    safe_backup "$HOME/.config/$d" "$(backup_path_unique ".config/$d")"
    echo "    backed up .config/$d"
  fi
done

# Back up .config/ files that will be overwritten
for f in dolphinrc kdeglobals xdg-terminals.list electron-flags.conf baloofilerc libinput-gestures.conf spotify-flags.conf starship.toml; do
  if [ -f "$HOME/.config/$f" ]; then
    safe_backup "$HOME/.config/$f" "$(backup_path_unique ".config/$f")"
    echo "    backed up .config/$f"
  fi
done

# Back up nested .config files/dirs (path components with subdirectories)
if [[ -e "$HOME/.config/dconf/profile" || -L "$HOME/.config/dconf/profile" ]]; then
  safe_backup "$HOME/.config/dconf/profile" "$(backup_path_unique ".config/dconf/profile")"
  echo "    backed up .config/dconf/profile"
fi

# Back up .local/share dirs that will be overwritten
for d in themes icons fonts waybar sddm rofi hyde wallbash kio kxmlgui5 xdg-desktop-portal dolphin; do
  if [ -d "$HOME/.local/share/$d" ]; then
    safe_backup "$HOME/.local/share/$d" "$(backup_path_unique ".local/share/$d")"
    echo "    backed up .local/share/$d"
  fi
done

# Back up prodi framework if exists (use unique names to avoid collisions)
if [ -e "$HOME/.local/lib/prodi" ]; then
  safe_backup "$HOME/.local/lib/prodi" "$(backup_path_unique ".local/lib/prodi")"
  echo "    backed up .local/lib/prodi"
fi
if [ -e "$HOME/.local/share/prodi" ]; then
  safe_backup "$HOME/.local/share/prodi" "$(backup_path_unique ".local/share/prodi")"
  echo "    backed up .local/share/prodi"
fi
if [ -e "$HOME/.local/bin/prodi-shell" ]; then
  safe_backup "$HOME/.local/bin/prodi-shell" "$(backup_path_unique ".local/bin/prodi-shell")"
  echo "    backed up .local/bin/prodi-shell"
fi
if [ -e "$HOME/.local/share/hypr" ]; then
  safe_backup "$HOME/.local/share/hypr" "$(backup_path_unique ".local/share/hypr")"
  echo "    backed up .local/share/hypr"
fi

echo "    Backup complete."
fi

# 5. Restore configs from Configs/ to target locations
echo "==> Restoring configs..."

# Restore .config/ dirs
if [ -d "$CONFIGS_DIR/.config" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$CONFIGS_DIR/.config/\"* \"$HOME/.config/\""
  else
    cp -a "$CONFIGS_DIR/.config/"* "$HOME/.config/"
    echo "    Restored .config/*"
  fi
fi

# Restore .local/share/ dirs
if [ -d "$CONFIGS_DIR/.local/share" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$CONFIGS_DIR/.local/share/\"* \"$HOME/.local/share/\""
  else
    cp -a "$CONFIGS_DIR/.local/share/"* "$HOME/.local/share/"
    echo "    Restored .local/share/*"
  fi
fi

# Restore .local/lib/prodi
if [ -d "$CONFIGS_DIR/.local/lib/prodi" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$CONFIGS_DIR/.local/lib/prodi/\"* \"$HOME/.local/lib/prodi/\""
  else
    mkdir -p "$HOME/.local/lib/prodi"
    cp -a "$CONFIGS_DIR/.local/lib/prodi/"* "$HOME/.local/lib/prodi/"
    echo "    Restored .local/lib/prodi/*"
  fi
fi

# Restore .local/bin/prodi-shell
if [ -f "$CONFIGS_DIR/.local/bin/prodi-shell" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp \"$CONFIGS_DIR/.local/bin/prodi-shell\" \"$HOME/.local/bin/prodi-shell\""
    echo "    [DRY RUN] chmod +x \"$HOME/.local/bin/prodi-shell\""
  else
    mkdir -p "$HOME/.local/bin"
    cp "$CONFIGS_DIR/.local/bin/prodi-shell" "$HOME/.local/bin/prodi-shell"
    chmod +x "$HOME/.local/bin/prodi-shell"
    echo "    Restored .local/bin/prodi-shell"
  fi
fi

# Restore .local/share/hypr
if [ -d "$CONFIGS_DIR/.local/share/hypr" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$CONFIGS_DIR/.local/share/hypr/\"* \"$HOME/.local/share/hypr/\""
  else
    mkdir -p "$HOME/.local/share/hypr"
    cp -a "$CONFIGS_DIR/.local/share/hypr/"* "$HOME/.local/share/hypr/"
    echo "    Restored .local/share/hypr/*"
  fi
fi

echo "    Config restore complete."

# 6. Make scripts executable
if [[ "$DRY_RUN" == true ]]; then
  echo "    [DRY RUN] chmod +x \"$HOME/.config/waybar/scripts/htb.py\""
  echo "    [DRY RUN] chmod +x \"$HOME/.local/bin/prodi-shell\""
else
  chmod +x "$HOME/.config/waybar/scripts/htb.py" 2>/dev/null || true
  chmod +x "$HOME/.local/bin/prodi-shell" 2>/dev/null || true
fi

# 7. HTB token setup (Hack The Box waybar module - optional)
if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "==> Hack The Box Waybar Module Setup (optional) [DRY RUN]"
  echo "    Would prompt for HTB User ID and API token."
  echo "    Would write to $HOME/.config/waybar/scripts/htb_token.env"
else
echo ""
echo "==> Hack The Box Waybar Module Setup (optional)"
echo "    The waybar includes a Hack The Box rank module."
echo "    Press Enter to skip."
read -r -p "    Enter your HTB User ID (e.g. 2426022): " HTB_USER_ID || true
read -r -s -p "    Enter your HTB API token: " HTB_TOKEN || true
echo ""

TOKEN_FILE="$HOME/.config/waybar/scripts/htb_token.env"

if [[ -n "${HTB_TOKEN:-}" ]]; then
  printf 'export HTB_TOKEN=%s\n' "$HTB_TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  echo "    Wrote HTB token to $TOKEN_FILE"
else
  : > "$TOKEN_FILE"
fi

if [[ -n "${HTB_USER_ID:-}" ]]; then
  printf 'export HTB_USER_ID=%s\n' "$HTB_USER_ID" >> "$TOKEN_FILE"
  echo "    Set HTB_USER_ID=$HTB_USER_ID"
fi
fi

# 8. Ensure PATH includes local bin
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> \"$HOME/.bashrc\""
  else
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "    Added ~/.local/bin to PATH in ~/.bashrc"
  fi
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
