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

# Collect all managed targets from the manifest
declare -a MANAGED_TARGETS=()
declare -a MANAGED_FILES=()

while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue

  source_rel=$(echo "$line" | cut -d'>' -f1 | xargs)
  target_exp=$(echo "$line" | cut -d'>' -f2 | xargs)
  target_path="${target_exp/#\~/$HOME}"

  if [[ -d "$REPO_DIR/$source_rel" ]]; then
    MANAGED_TARGETS+=("$target_path")
  elif [[ -f "$REPO_DIR/$source_rel" ]]; then
    MANAGED_FILES+=("$target_path")
  fi
done < "$RESTORE_LIST"

read -r -p "This will remove all restored dotfiles and restore backups. Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Restore each managed item from its backup (if a backup exists)
echo "==> Restoring backed-up configs..."

for target_path in "${MANAGED_TARGETS[@]}"; do
  # Derive backup name from the manifest source path
  # We need to find which source maps to this target — re-read the manifest
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    source_rel=$(echo "$line" | cut -d'>' -f1 | xargs)
    target_exp=$(echo "$line" | cut -d'>' -f2 | xargs)
    manifest_target="${target_exp/#\~/$HOME}"

    if [[ "$manifest_target" != "$target_path" ]]; then
      continue
    fi

    backup_name="$(echo "$source_rel" | sed 's/^\.//; s/\//-/g')"
    backup_path="$BACKUP_DIR/$backup_name"

    if [[ -e "$backup_path" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "    [DRY RUN] Would restore backup: $backup_path → $target_path"
      else
        # Remove existing target first to avoid nested directories
        rm -rf "$target_path"
        mkdir -p "$(dirname "$target_path")"
        cp -r "$backup_path" "$target_path"
        echo "Restored from backup: $target_path"
      fi
    elif [[ -e "$target_path" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "    [DRY RUN] Would remove: $target_path (no backup available)"
      else
        rm -rf "$target_path"
        echo "Removed (no backup): $target_path"
      fi
    fi
    break
  done < "$RESTORE_LIST"
done

for target_path in "${MANAGED_FILES[@]}"; do
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    source_rel=$(echo "$line" | cut -d'>' -f1 | xargs)
    target_exp=$(echo "$line" | cut -d'>' -f2 | xargs)
    manifest_target="${target_exp/#\~/$HOME}"

    if [[ "$manifest_target" != "$target_path" ]]; then
      continue
    fi

    backup_name="$(echo "$source_rel" | sed 's/^\.//; s/\//-/g')"
    backup_path="$BACKUP_DIR/$backup_name"

    if [[ -e "$backup_path" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "    [DRY RUN] Would restore backup: $backup_path → $target_path"
      else
        mkdir -p "$(dirname "$target_path")"
        cp "$backup_path" "$target_path"
        echo "Restored from backup: $target_path"
      fi
    elif [[ -e "$target_path" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "    [DRY RUN] Would remove: $target_path (no backup available)"
      else
        rm -f "$target_path"
        echo "Removed (no backup): $target_path"
      fi
    fi
    break
  done < "$RESTORE_LIST"
done

# Remove PATH addition from .bashrc
RC_FILE="$HOME/.bashrc"
if [ -f "$RC_FILE" ]; then
  if grep -q 'export PATH="\$HOME\/.local\/bin:\$PATH"' "$RC_FILE" 2>/dev/null; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "    [DRY RUN] Would clean PATH from $RC_FILE"
    else
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
