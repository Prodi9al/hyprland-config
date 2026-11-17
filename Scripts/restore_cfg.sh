#!/usr/bin/env bash
# Prodi9al Hyprland Config — Config Restore Script
# Restores dotfiles from Configs/ to target locations with backup.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$(dirname "${SCRIPTS_DIR}")" && pwd)"
CONFIGS_DIR="$REPO_DIR/Configs"

BACKUP_DIR="$HOME/.config/cfg_backups"

echo "==> Prodi9al Config Restore"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Restore each mapping from restore_cfg.lst
RESTORE_LIST="$SCRIPTS_DIR/restore_cfg.lst"
if [[ ! -f "$RESTORE_LIST" ]]; then
  echo "No restore_cfg.lst found."
  exit 1
fi

while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue

  source_rel=$(echo "$line" | cut -d'>' -f1 | xargs)
  target_exp=$(echo "$line" | cut -d'>' -f2 | xargs)

  source_path="$REPO_DIR/$source_rel"
  # Expand ~ in target
  target_path="${target_exp/#\~/$HOME}"

  if [[ ! -e "$source_path" ]]; then
    echo "SKIP (not found): $source_rel"
    continue
  fi

  # Back up existing target if it exists
  if [[ -e "$target_path" ]]; then
    backup_name="$(basename "$target_path")"
    cp -r "$target_path" "$BACKUP_DIR/$backup_name" 2>/dev/null || true
    echo "Backed up: $target_path"
    rm -rf "$target_path"
  fi

  # Restore
  mkdir -p "$(dirname "$target_path")"
  cp -r "$source_path" "$target_path"
  echo "Restored: $target_path"

done < "$RESTORE_LIST"

echo ""
echo "==> Restore complete!"
echo "    Backups saved at: $BACKUP_DIR"
