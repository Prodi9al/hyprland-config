#!/usr/bin/env bash
# Prodi9al Hyprland Config — Uninstall Script
# Removes restored dotfiles and restores backups if available.
# Manifest-driven: only touches items the installer manages.

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

echo "==> Prodi9al Hyprland Config Uninstaller"
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

# Read the restore manifest to know exactly what the installer manages
RESTORE_LIST="$SCRIPTS_DIR/restore_cfg.lst"
if [[ ! -f "$RESTORE_LIST" ]]; then
  echo "No restore_cfg.lst found — cannot uninstall safely."
  exit 1
fi

read -r -p "This will remove all restored dotfiles and restore backups. Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Collect all managed targets from the manifest
declare -a MANAGED_DIRS=()
declare -a MANAGED_FILES=()

while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue

  source_rel=$(echo "$line" | awk -F' -> ' '{print $1}')
  target_exp=$(echo "$line" | awk -F' -> ' '{print $2}')
  target_path="${target_exp/#\~/$HOME}"

  if [[ -d "$CONFIGS_DIR/$source_rel" ]]; then
    MANAGED_DIRS+=("$target_path")
  elif [[ -f "$CONFIGS_DIR/$source_rel" ]]; then
    MANAGED_FILES+=("$target_path")
  fi
done < "$RESTORE_LIST"

# Helper: restore a managed item from its backup using staging-and-rename
#   $1 = target_path, $2 = source_rel (for backup lookup)
restore_managed_item() {
  local target_path="$1"
  local source_rel="$2"

  backup_path="$(backup_lookup "$source_rel" 2>/dev/null)" || true

  if [[ -n "$backup_path" && (-e "$backup_path" || -L "$backup_path") ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "    [DRY RUN] Would restore backup: $backup_path → $target_path"
      return 0
    fi

    # Determine if backup is a directory or file
    local backup_is_dir=false
    [[ -d "$backup_path" ]] && backup_is_dir=true

    # Copy backup to staging first (verify it works before touching target)
    mkdir -p "$(dirname "$target_path")"
    staging="$(mktemp -d "$(dirname "$target_path")/.restore-staging-XXXXXX")"
    if $backup_is_dir; then
      if ! cp -a "$backup_path"/. "$staging"/ 2>/dev/null; then
        echo "ERROR: Failed to read backup $backup_path — leaving target intact."
        rm -rf "$staging" 2>/dev/null || true
        return 1
      fi
    else
      local source_name
      source_name="$(basename "$backup_path")"
      if ! cp -a "$backup_path" "$staging/$source_name" 2>/dev/null; then
        echo "ERROR: Failed to read backup $backup_path — leaving target intact."
        rm -rf "$staging" 2>/dev/null || true
        return 1
      fi
    fi

    # Rename original to rollback directory (same filesystem, unique via mktemp -d)
    rollback_dir="$(mktemp -d "$(dirname "$target_path")/.uninstall-rollback-$(backup_name "$source_rel")-XXXXXX")"
    rollback="$rollback_dir/$(basename "$target_path")"
    if [[ -e "$target_path" || -L "$target_path" ]]; then
      if ! mv "$target_path" "$rollback"; then
        echo "ERROR: Could not move $target_path to rollback — aborting to prevent data loss."
        rm -rf "$staging" 2>/dev/null || true
        rm -rf "$rollback_dir" 2>/dev/null || true
        exit 1
      fi
    fi

    # Move staged content into place
    if $backup_is_dir; then
      if ! mv "$staging" "$target_path"; then
        echo "ERROR: Failed to restore $target_path from backup — attempting rollback."
        rm -rf "$target_path" 2>/dev/null || true
        if [[ -e "$rollback" || -L "$rollback" ]]; then
          rm -rf "$target_path" 2>/dev/null || true
          mv "$rollback" "$target_path"
          echo "Restored original target from rollback: $target_path"
        fi
        rm -rf "$staging" 2>/dev/null || true
        rm -rf "$rollback_dir" 2>/dev/null || true
        return 1
      fi
    else
      local source_name
      source_name="$(basename "$backup_path")"
      if ! mv "$staging/$source_name" "$target_path"; then
        echo "ERROR: Failed to restore $target_path from backup — attempting rollback."
        rm -rf "$target_path" 2>/dev/null || true
        if [[ -e "$rollback" || -L "$rollback" ]]; then
          rm -f "$target_path" 2>/dev/null || true
          mv "$rollback" "$target_path"
          echo "Restored original target from rollback: $target_path"
        fi
        rm -rf "$staging" 2>/dev/null || true
        rm -rf "$rollback_dir" 2>/dev/null || true
        return 1
      fi

      rmdir "$staging"
    fi

    rm -rf "$rollback_dir" 2>/dev/null || true
    echo "Restored from backup: $target_path"
    return 0
  elif [[ -e "$target_path" || -L "$target_path" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "    [DRY RUN] Would remove: $target_path (no backup available)"
    else
      rm -rf "$target_path"
      echo "Removed (no backup): $target_path"
    fi
    return 0
  fi

  return 0
}

# Restore each managed directory from its backup (if a backup exists)
echo "==> Restoring backed-up configs..."

for target_path in "${MANAGED_DIRS[@]}"; do
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

source_rel=$(echo "$line" | awk -F' -> ' '{print $1}')
  target_exp=$(echo "$line" | awk -F' -> ' '{print $2}')
    manifest_target="${target_exp/#\~/$HOME}"

    if [[ "$manifest_target" != "$target_path" ]]; then
      continue
    fi

    restore_managed_item "$target_path" "$source_rel"
    break
  done < "$RESTORE_LIST"
done

for target_path in "${MANAGED_FILES[@]}"; do
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

source_rel=$(echo "$line" | awk -F' -> ' '{print $1}')
  target_exp=$(echo "$line" | awk -F' -> ' '{print $2}')
    manifest_target="${target_exp/#\~/$HOME}"

    if [[ "$manifest_target" != "$target_path" ]]; then
      continue
    fi

    restore_managed_item "$target_path" "$source_rel"
    break
  done < "$RESTORE_LIST"
done

# Remove PATH addition from .bashrc
RC_FILE="$HOME/.bashrc"
if [ -f "$RC_FILE" ]; then
  # shellcheck disable=SC2016
  if grep -q 'export PATH="\$HOME\/.local\/bin:\$PATH"' "$RC_FILE" 2>/dev/null; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "    [DRY RUN] Would clean PATH from $RC_FILE"
    else
      # shellcheck disable=SC2016
      sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$RC_FILE" 2>/dev/null || true
      echo "    Cleaned up PATH from $RC_FILE"
    fi
  fi
fi

echo ""
echo "==> Uninstall complete!"
if [[ "$DRY_RUN" == true ]]; then
  echo "    (No changes were made — dry run mode)"
else
  echo "    Backups kept at: $BACKUP_DIR"
fi
