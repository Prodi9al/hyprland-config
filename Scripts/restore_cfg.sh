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

# Source shared backup naming utility
# shellcheck source=./backup-utils.sh
# shellcheck disable=SC1091
. "$SCRIPTS_DIR/backup-utils.sh"

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

safe_backup() {
  local src="$1"
  local dst="$2"
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] cp -a \"$src\" \"$dst\""
    return 0
  fi
  if ! cp -a "$src" "$dst"; then
    echo "FATAL: Failed to back up $src to $dst — aborting before any data loss."
    exit 1
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

  source_rel=$(echo "$line" | awk -F' -> ' '{print $1}')
  target_exp=$(echo "$line" | awk -F' -> ' '{print $2}')

  source_path="$CONFIGS_DIR/$source_rel"
  # Expand ~ in target
  target_path="${target_exp/#\~/$HOME}"

  if [[ ! -e "$source_path" ]]; then
    echo "SKIP (not found): $source_rel"
    continue
  fi

  # Derive backup path using shared naming convention
  backup_path="$(backup_path "$source_rel")"

  # Back up existing target if it exists (backup failure is fatal)
  target_existed=false
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    target_existed=true
    if [[ -e "$backup_path" || -L "$backup_path" ]]; then
      backup_path="${backup_path}.$(date +%s)"
    fi
    safe_backup "$target_path" "$backup_path"
    echo "Backed up: $target_path → $backup_path"
  fi

  # Restore via rename-original to avoid failure window
  if [[ "$DRY_RUN" == true ]]; then
    echo "    [DRY RUN] Would restore: $source_rel → $target_path"
  else
    mkdir -p "$(dirname "$target_path")"

    if [[ -d "$source_path" ]]; then
      # Directory: stage its contents, then replace target directory
      staging="$(mktemp -d "$(dirname "$target_path")/.restore-staging-XXXXXX")"
      if ! cp -a "$source_path"/. "$staging"/; then
        echo "ERROR: cp staging failed for $source_rel"
        rm -rf "$staging" 2>/dev/null || true
        exit 1
      fi

      # Rename original to rollback directory (same filesystem, unique via mktemp -d)
      rollback_dir="$(mktemp -d "$(dirname "$target_path")/.rollback-$(backup_name "$source_rel")-XXXXXX")"
      rollback="$rollback_dir/$(basename "$target_path")"
      if [[ -e "$target_path" || -L "$target_path" ]]; then
        if ! mv "$target_path" "$rollback"; then
          echo "ERROR: Could not rename $target_path to rollback"
          rm -rf "$staging" 2>/dev/null || true
          rm -rf "$rollback_dir" 2>/dev/null || true
          exit 1
        fi
      fi

      # Move staged content into place
      if ! mv "$staging" "$target_path"; then
        echo "ERROR: mv failed for $target_path — restoring from backup"
        rm -rf "$staging" 2>/dev/null || true
        recovery_ok=false
        if $target_existed && [[ -e "$rollback" || -L "$rollback" ]]; then
          rm -rf "$target_path" 2>/dev/null || true
          if mv "$rollback" "$target_path"; then
            echo "Restored from rollback: $target_path"
            recovery_ok=true
          else
            echo "ERROR: Rollback recovery failed — rollback preserved at $rollback_dir"
          fi
        elif $target_existed && [[ -e "$backup_path" || -L "$backup_path" ]]; then
          rm -rf "$target_path" 2>/dev/null || true
          cp -a "$backup_path" "$target_path"
          echo "Restored from backup: $target_path"
          recovery_ok=true
        else
          echo "ERROR: No rollback or backup available for recovery"
        fi
        if $recovery_ok && [[ -e "$rollback_dir" || -L "$rollback_dir" ]]; then
          rm -rf "$rollback_dir" 2>/dev/null || true
        fi
        exit 1
      fi

      # Remove rollback directory now that restore is confirmed
      if [[ -e "$rollback_dir" || -L "$rollback_dir" ]]; then
        rm -rf "$rollback_dir" 2>/dev/null || true
      fi

      echo "Restored: $target_path"
    else
      # File: stage the file itself, then atomically replace target file
      staging="$(mktemp -d "$(dirname "$target_path")/.restore-staging-XXXXXX")"
      source_name="$(basename "$source_path")"
      if ! cp -a "$source_path" "$staging/$source_name"; then
        echo "ERROR: cp staging failed for $source_rel"
        rm -rf "$staging" 2>/dev/null || true
        exit 1
      fi

      # Rename original to rollback directory (same filesystem, unique via mktemp -d)
      rollback_dir="$(mktemp -d "$(dirname "$target_path")/.rollback-$(backup_name "$source_rel")-XXXXXX")"
      rollback="$rollback_dir/$(basename "$source_path")"
      if [[ -e "$target_path" || -L "$target_path" ]]; then
        if ! mv "$target_path" "$rollback"; then
          echo "ERROR: Could not rename $target_path to rollback"
          rm -rf "$staging" 2>/dev/null || true
          exit 1
        fi
      fi

      # Move staged file into place
      if ! mv "$staging/$source_name" "$target_path"; then
        echo "ERROR: mv failed for $target_path — restoring from backup"
        rm -rf "$staging" 2>/dev/null || true
        recovery_ok=false
        if $target_existed && [[ -e "$rollback" || -L "$rollback" ]]; then
          rm -f "$target_path" 2>/dev/null || true
          if mv "$rollback" "$target_path"; then
            echo "Restored from rollback: $target_path"
            recovery_ok=true
          else
            echo "ERROR: Rollback recovery failed — rollback preserved at $rollback_dir"
          fi
        elif $target_existed && [[ -e "$backup_path" || -L "$backup_path" ]]; then
          rm -f "$target_path" 2>/dev/null || true
          cp -a "$backup_path" "$target_path"
          echo "Restored from backup: $target_path"
          recovery_ok=true
        else
          echo "ERROR: No rollback or backup available for recovery"
        fi
        if $recovery_ok && [[ -e "$rollback_dir" || -L "$rollback_dir" ]]; then
          rm -rf "$rollback_dir" 2>/dev/null || true
        fi
        exit 1
      fi

      rmdir "$staging"

      # Remove rollback directory now that restore is confirmed
      if [[ -e "$rollback_dir" || -L "$rollback_dir" ]]; then
        rm -rf "$rollback_dir" 2>/dev/null || true
      fi

      echo "Restored: $target_path"
    fi
  fi

done < "$RESTORE_LIST"

echo ""
echo "==> Restore complete!"
if [[ "$DRY_RUN" == true ]]; then
  echo "    (No changes were made — dry run mode)"
else
  echo "    Backups saved at: $BACKUP_DIR"
fi
