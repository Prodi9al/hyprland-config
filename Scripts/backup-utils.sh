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
    # Strip leading dot, then encode path unambiguously:
    #   '-' → '-.'  (escape literal dash)
    #   '/' → '--'  (path separator)
    # This keeps .config/a-b and .config/a/b distinct.
    local encoded
    encoded="${rel#.}"
    encoded="${encoded//-/-.}"
    encoded="${encoded//\//--}"
    echo "$encoded"
}

# Return the full backup path for a given source relative path.
backup_path() {
    local rel="$1"
    echo "${BACKUP_DIR}/$(backup_name "$rel")"
}

# Return a unique backup destination path for a given source relative path.
# If the base backup path already exists (file, directory, or dangling symlink),
# appends a timestamp to create a unique destination.
# Returns the path to use for writing a new backup.
backup_path_unique() {
    local rel="$1"
    local base
    base="$(backup_path "$rel")"

    if [[ -e "$base" || -L "$base" ]]; then
        echo "${base}.$(date +%s)"
    else
        echo "$base"
    fi
}

# Find the exact backup path for a given source relative path.
# Checks the base name first, then timestamped variants (newest first).
# Returns 0 and prints the path if found, returns 1 if no backup exists.
backup_lookup() {
    local rel="$1"
    local base
    base="$(backup_path "$rel")"

    if [[ -e "$base" || -L "$base" ]]; then
        echo "$base"
        return 0
    fi

    # Safely glob for timestamped variants without failing on no matches
    local shopt_state
    shopt_state="$(shopt -p nullglob)"
    shopt -s nullglob
    local -a matches=("$base".*)
    eval "$shopt_state" >/dev/null 2>&1

    if [[ ${#matches[@]} -gt 0 ]]; then
        local newest=""
        local newest_time=0
        local m
        for m in "${matches[@]}"; do
            local mtime
            mtime="$(stat -c %Y "$m" 2>/dev/null || echo 0)"
            if (( mtime > newest_time )); then
                newest_time=$mtime
                newest="$m"
            fi
        done
        if [[ -n "$newest" ]]; then
            echo "$newest"
            return 0
        fi
    fi

    return 1
}
