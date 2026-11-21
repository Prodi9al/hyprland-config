#!/usr/bin/env bash
# Prodi9al Hyprland Config — Install Script
# Sets up the full Hyprland desktop environment on Arch and Arch-based distros.
# Usage: ./Scripts/install.sh [--aur] [--skip-sys-update] [--dry-run] [--unattended]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$REPO_DIR/Configs"

BACKUP_DIR="$HOME/.config/cfg_backups"
INSTALL_AUR=false
SKIP_SYS_UPDATE=false
DRY_RUN=false
UNATTENDED=false

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
    --unattended) UNATTENDED=true ;;
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
    if [[ "$UNATTENDED" == true ]]; then
      echo "    Unattended mode: running system update..."
      sudo pacman -Syu --needed --noconfirm
    else
      read -r -p "    Run 'sudo pacman -Syu' to update system first? [y/N] " confirm_sysupdate
      if [[ "$confirm_sysupdate" =~ ^[Yy]$ ]]; then
        sudo pacman -Syu --needed --noconfirm
      else
        echo "    Skipping system update."
      fi
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

# Lua modules via luarocks (not in pacman repos)
if ! lua -e "require('lfs')" 2>/dev/null; then
  echo "==> Installing Lua modules via luarocks..."
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] sudo luarocks install luafilesystem"
  else
    sudo luarocks install luafilesystem 2>/dev/null || echo "    Warning: luarocks install luafilesystem failed (may already be installed)"
  fi
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

# 4. Deploy dot groups from dots.toml manifest
echo "==> Deploying dot groups from dots.toml..."
DOTS_TOML="$SCRIPTS_DIR/dots.toml"

if [[ ! -f "$DOTS_TOML" ]]; then
  echo "    dots.toml not found — skipping dot group deployment."
else
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] Would parse $DOTS_TOML and deploy dot groups."
  else
    python3 - "$DOTS_TOML" "$CONFIGS_DIR" "$HOME" <<'PYEOF'
import sys, os, tomllib

dots_toml = sys.argv[1]
configs_dir = sys.argv[2]
home = sys.argv[3]

with open(dots_toml, "rb") as f:
    manifest = tomllib.load(f)

include_list = manifest.get("include", [])

for include_path in include_list:
    full_path = os.path.join(os.path.dirname(dots_toml), include_path)
    if not os.path.exists(full_path):
        print(f"    [skip] {include_path} — not found")
        continue

    with open(full_path, "rb") as f:
        dot = tomllib.load(f)

    for section_name, section in dot.items():
        if section_name == "include":
            continue
        if not isinstance(section, dict):
            continue

        pre_cmd = section.get("pre_command", "")
        post_cmd = section.get("post_command", "")

        if pre_cmd:
            print(f"    [pre] {section_name}: {pre_cmd}")
            os.system(pre_cmd)

        files = section.get("files", [])
        if isinstance(files, dict):
            files = [files]

        for file_entry in files:
            action = file_entry.get("action", "sync")
            source_root = file_entry.get("source_root", "")
            target_root = file_entry.get("target_root", "")
            paths = file_entry.get("paths", [])
            ignored = file_entry.get("ignored_paths", [])

            if isinstance(paths, str):
                paths = [paths]
            if isinstance(ignored, str):
                ignored = [ignored]

            # Expand env vars in roots
            source_root = os.path.expandvars(source_root)
            target_root = os.path.expandvars(target_root)

            abs_source = os.path.join(configs_dir, source_root) if not os.path.isabs(source_root) else source_root
            abs_target = os.path.expanduser(target_root)

            for p in paths:
                src = os.path.join(abs_source, p)
                dst = os.path.join(abs_target, p)

                if not os.path.exists(src):
                    print(f"    [skip] {p} — source not found")
                    continue

                if action == "preserve" and os.path.exists(dst):
                    print(f"    [preserve] {p} — target exists, skipping")
                    continue

                os.makedirs(os.path.dirname(dst), exist_ok=True)

                if os.path.isdir(src):
                    if os.path.exists(dst):
                        import shutil
                        shutil.rmtree(dst)
                    import shutil
                    shutil.copytree(src, dst)
                else:
                    import shutil
                    shutil.copy2(src, dst)

                print(f"    [{action}] {p}")

        if post_cmd:
            print(f"    [post] {section_name}: {post_cmd}")
            os.system(post_cmd)

print("    Dot group deployment complete.")
PYEOF
  fi
fi

echo ""

# 5. Back up existing configs (before overwrite)
echo "==> Backing up existing configs to $BACKUP_DIR..."
if [[ "$DRY_RUN" == true ]]; then
  echo "    [DRY RUN] Would create backup directory: $BACKUP_DIR"
else
  mkdir -p "$BACKUP_DIR"

  # Back up .config dirs that will be overwritten
  for d in hypr waybar dunst fastfetch gtk-3.0 gtk-4.0 kitty Kvantum nwg-look pypr qt5ct qt6ct swaync wlogout xsettingsd prodi rofi zsh uwsm fish starship swaylock lsd vim satty menus; do
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

  # Back up nested .config files/dirs
  if [[ -e "$HOME/.config/dconf/profile" || -L "$HOME/.config/dconf/profile" ]]; then
    safe_backup "$HOME/.config/dconf/profile" "$(backup_path_unique ".config/dconf/profile")"
    echo "    backed up .config/dconf/profile"
  fi

  # Back up .local/share dirs that will be overwritten
  for d in themes icons fonts waybar sddm rofi prodi wallbash kio kxmlgui5 xdg-desktop-portal dolphin; do
    if [ -d "$HOME/.local/share/$d" ]; then
      safe_backup "$HOME/.local/share/$d" "$(backup_path_unique ".local/share/$d")"
      echo "    backed up .local/share/$d"
    fi
  done

  # Back up prodi framework if exists
  if [ -e "$HOME/.local/lib/prodi" ]; then
    safe_backup "$HOME/.local/lib/prodi" "$(backup_path_unique ".local/lib/prodi")"
    echo "    backed up .local/lib/prodi"
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

echo ""

# 6. Restore remaining configs not covered by dots.toml (fallback bulk restore)
echo "==> Restoring remaining configs..."

# Restore .local/lib/prodi (framework scripts)
if [ -d "$CONFIGS_DIR/.local/lib/prodi" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$CONFIGS_DIR/.local/lib/prodi/\"* \"$HOME/.local/lib/prodi/\""
  else
    mkdir -p "$HOME/.local/lib/prodi"
    cp -a "$CONFIGS_DIR/.local/lib/prodi/"* "$HOME/.local/lib/prodi/"
    echo "    Restored .local/lib/prodi/*"
  fi
fi

# Restore .local/state/prodi/lua_state (default color/theme state for fresh installs)
if [ -d "$CONFIGS_DIR/.local/state/prodi/lua_state" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] mkdir -p \"$HOME/.local/state/prodi/lua_state\" && cp -a \"$CONFIGS_DIR/.local/state/prodi/lua_state/\"* \"$HOME/.local/state/prodi/lua_state/\""
  else
    mkdir -p "$HOME/.local/state/prodi/lua_state"
    cp -a "$CONFIGS_DIR/.local/state/prodi/lua_state/"* "$HOME/.local/state/prodi/lua_state/"
    echo "    Restored .local/state/prodi/lua_state/*"
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

# Restore .local/share/hypr (lua modules, schema)
if [ -d "$CONFIGS_DIR/.local/share/hypr" ]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$CONFIGS_DIR/.local/share/hypr/\"* \"$HOME/.local/share/hypr/\""
  else
    mkdir -p "$HOME/.local/share/hypr"
    cp -a "$CONFIGS_DIR/.local/share/hypr/"* "$HOME/.local/share/hypr/"
    echo "    Restored .local/share/hypr/*"
  fi
fi

echo "    Remaining config restore complete."

echo ""

# 7. Run restore helpers (app/link restoration after config deploy)
if [[ "$DRY_RUN" != true ]]; then
  echo "==> Running restore helpers..."
  if [ -f "$SCRIPTS_DIR/extra/restore_app.sh" ]; then
    bash "$SCRIPTS_DIR/extra/restore_app.sh" --dry-run="$DRY_RUN" 2>/dev/null || echo "    Warning: restore_app.sh completed with warnings"
  fi
  if [ -f "$SCRIPTS_DIR/extra/restore_lnk.sh" ]; then
    bash "$SCRIPTS_DIR/extra/restore_lnk.sh" --dry-run="$DRY_RUN" 2>/dev/null || echo "    Warning: restore_lnk.sh completed with warnings"
  fi
  echo "    Restore helpers complete."
else
  echo "==> Skipping restore helpers (dry run mode)."
fi

echo ""

# 8. Generate theme state on fresh install (themes applied via theme pipeline)
echo "==> Generating theme state for fresh install..."
if [[ "$DRY_RUN" != true ]] && [[ "$UNATTENDED" != true ]]; then
  export LIB_DIR="$HOME/.local/lib"
  export SHARE_DIR="$HOME/.local/share"
  export PATH="$HOME/.local/lib/prodi:$HOME/.local/bin:${PATH}"

  if source "$HOME/.local/lib/prodi/globalcontrol.sh" 2>/dev/null; then
    echo "    Prodi environment initialized."

    # Apply themes via theme.switch.sh (generates colors.lua, ui.lua, hypr_theme.lua)
    if "$HOME/.local/lib/prodi/theme.switch.sh" -q 2>/dev/null; then
      echo "    Theme color state generated (colors.lua, ui.lua, hypr_theme.lua)."
    else
      echo "    Warning: theme state generation skipped — run 'prodi-shell reload theme' manually."
    fi

    # Generate wallpaper cache
    if "$HOME/.local/lib/prodi/wallpaper/cache.sh" commence -t "" 2>/dev/null; then
      echo "    Wallpaper cache generated."
    else
      echo "    Warning: wallpaper cache generation skipped."
    fi

    # Update waybar configuration with theme colors
    if "$HOME/.local/lib/prodi/waybar.py" --update 2>/dev/null; then
      echo "    Waybar configuration updated with theme colors."
    else
      echo "    Warning: waybar update skipped."
    fi
  else
    echo "    Warning: prodi environment could not be initialized — theme state not generated."
  fi
elif [[ "$UNATTENDED" == true ]]; then
  echo "    Skipping theme state generation (unattended mode). Run 'prodi-shell reload theme' after first boot."
else
  echo "    Skipping theme state generation (dry run mode)."
fi

echo ""

# 9. Make scripts executable
if [[ "$DRY_RUN" == true ]]; then
  echo "    [DRY RUN] chmod +x \"$HOME/.config/waybar/scripts/htb.py\""
  echo "    [DRY RUN] chmod +x \"$HOME/.local/bin/prodi-shell\""
else
  chmod +x "$HOME/.config/waybar/scripts/htb.py" 2>/dev/null || true
  chmod +x "$HOME/.local/bin/prodi-shell" 2>/dev/null || true
fi

# 10. HTB token setup (Hack The Box waybar module - optional)
if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "==> Hack The Box Waybar Module Setup (optional) [DRY RUN]"
  echo "    Would prompt for HTB User ID and API token."
else
  if [[ "$UNATTENDED" == true ]]; then
    echo ""
    echo "==> Hack The Box Waybar Module Setup (optional) [UNATTENDED]"
    echo "    Reading HTB credentials from environment variables..."
    HTB_USER_ID="${HTB_USER_ID:-}"
    HTB_TOKEN="${HTB_TOKEN:-}"
    if [[ -z "$HTB_TOKEN" ]]; then
      echo "    No HTB_TOKEN in environment; skipping HTB setup."
    fi
  else
    echo ""
    echo "==> Hack The Box Waybar Module Setup (optional)"
    echo "    The waybar includes a Hack The Box rank module."
    echo "    Press Enter to skip."
    read -r -p "    Enter your HTB User ID (e.g. 2426022): " HTB_USER_ID || true
    read -r -s -p "    Enter your HTB API token: " HTB_TOKEN || true
    echo ""
  fi

  # HTB User IDs are numeric. Reject anything else up front so it can never
  # corrupt the token file via the sed replacement below (e.g. &, |, backslash).
  if [[ -n "${HTB_USER_ID:-}" && ! "$HTB_USER_ID" =~ ^[0-9]+$ ]]; then
    echo "    Invalid HTB User ID (expected digits only); ignoring it."
    HTB_USER_ID=""
  fi

  TOKEN_FILE="$HOME/.config/waybar/scripts/htb_token.env"
  mkdir -p "$(dirname "$TOKEN_FILE")"

  if [[ -n "${HTB_TOKEN:-}" ]]; then
    # Never silently destroy existing credentials: back them up first.
    if [ -s "$TOKEN_FILE" ]; then
      TOKEN_BACKUP="${TOKEN_FILE}.bak.$(date +%Y%m%d%H%M%S)"
      cp -a "$TOKEN_FILE" "$TOKEN_BACKUP"
      chmod 600 "$TOKEN_BACKUP"
      echo "    Backed up existing HTB credentials to $TOKEN_BACKUP"
    fi
    {
      printf 'export HTB_TOKEN=%s\n' "$HTB_TOKEN"
      [[ -n "${HTB_USER_ID:-}" ]] && printf 'export HTB_USER_ID=%s\n' "$HTB_USER_ID"
    } > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "    Wrote HTB token to $TOKEN_FILE"
  elif [ -s "$TOKEN_FILE" ]; then
    echo "    No token entered; existing HTB credentials left untouched."
    if [[ -n "${HTB_USER_ID:-}" ]]; then
      if grep -q '^export HTB_USER_ID=' "$TOKEN_FILE" 2>/dev/null; then
        sed -i "s|^export HTB_USER_ID=.*|export HTB_USER_ID=${HTB_USER_ID}|" "$TOKEN_FILE"
      else
        printf 'export HTB_USER_ID=%s\n' "$HTB_USER_ID" >> "$TOKEN_FILE"
      fi
      chmod 600 "$TOKEN_FILE"
      echo "    Set HTB_USER_ID=$HTB_USER_ID"
    fi
  else
    echo "    No token entered; skipping HTB setup."
  fi
fi

# 11. Ensure PATH includes ~/.local/bin.
RC_FILE="$HOME/.bashrc"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
if [ -f "$RC_FILE" ] && grep -qF "$PATH_LINE" "$RC_FILE" 2>/dev/null; then
  echo "    ~/.local/bin already on PATH in $RC_FILE; leaving it untouched."
elif [[ "$DRY_RUN" == true ]]; then
  echo "    [DRY RUN] append marker-wrapped PATH entry to \"$RC_FILE\""
else
  {
    echo '# >>> prodi: ~/.local/bin on PATH >>>'
    echo "$PATH_LINE"
    echo '# <<< prodi: ~/.local/bin on PATH <<<'
  } >> "$RC_FILE"
  echo "    Added ~/.local/bin to PATH in $RC_FILE"
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
echo "  4. Theme color state is already generated — use \`prodi-shell theme.switch\` to change themes."
echo "  5. Use \`prodi-shell wallpaper\` to manage wallpapers."
