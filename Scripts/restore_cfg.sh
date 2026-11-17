#!/usr/bin/env bash
# Prodi9al Hyprland Config — Config Restore Script
# Restores dotfiles from Configs/ to target locations with safe backup.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$(dirname "${SCRIPTS_DIR}")" && pwd)"
CONFIGS_DIR="$REPO_DIR/Configs"

BACKUP_DIR="$HOME/.config/cfg_backups"
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

echo "==> Prodi9al Config Restore"
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

# Create backup directory
if [[ "$DRY_RUN" == true ]]; then
  echo "    [DRY RUN] Would create backup directory: $BACKUP_DIR"
else
  mkdir -p "$BACKUP_DIR"
fi

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

  # Derive a unique, collision-free backup name from the relative path
  # .config/hypr → config-hypr, .local/lib/prodi → local-lib-prodi
  backup_name="$(echo "$source_rel" | sed 's/^\.//; s/\//-/g')"
  backup_path="$BACKUP_DIR/$backup_name"

  # Back up existing target if it exists (non-destructive: keep original + backup)
  if [[ -e "$target_path" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "    [DRY RUN] Would back up existing target: $target_path → $backup_path"
    else
      # If backup already exists, append a timestamp to avoid overwriting
      if [[ -e "$backup_path" ]]; then
        backup_path="${backup_path}.$(date +%s)"
      fi
      cp -r "$target_path" "$backup_path" 2>/dev/null || true
      echo "Backed up: $target_path → $backup_path"
    fi
  fi

  # Restore
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] Would restore: $source_rel → $target_path"
  else
    mkdir -p "$(dirname "$target_path")"
    # Remove existing target first so cp -r doesn't create a nested directory
    # (cp -r source target/ would create target/source/ if target already exists)
    rm -rf "$target_path"
    cp -r "$source_path" "$target_path"
    echo "Restored: $target_path"
  fi

done < "$RESTORE_LIST"

echo ""
echo "==> Restore complete!"
if [[ "$DRY_RUN" == true ]]; then
  echo "    (No changes were made — dry run mode)"
else
  echo "    Backups saved at: $BACKUP_DIR"
fi
