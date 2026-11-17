#!/usr/bin/env bash
# Shared backup naming utilities for Prodi9al Hyprland Config lifecycle scripts.
# All scripts (install.sh, restore_cfg.sh, uninstall.sh) must use the same
# naming scheme so backups created by one can be found by another.

# Derive a collision-free backup name from a source relative path.
#   .config/hypr          → config-hypr
#   .local/share/themes   → local-share-themes
#   .config/starship.toml → config-starship.toml
#   .local/lib/prodi      → local-lib-prodi
backup_name() {
    local rel="$1"
    # Strip leading dot, replace slashes with dashes
    echo "${rel#.}" | sed 's/\//-/g'
}

# Return the full backup path for a given source relative path.
backup_path() {
    local rel="$1"
    echo "${BACKUP_DIR}/$(backup_name "$rel")"
}
