#!/usr/bin/env bash
# Prodi9al Hyprland Config — Theme Restore Script
# Imports and patches default themes from themepatcher.lst

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$(dirname "${SCRIPTS_DIR}")" && pwd)"
THEME_IMPORT_FILE="${1:-${SCRIPTS_DIR}/themepatcher.lst}"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
    esac
done

if [[ ! -f "$THEME_IMPORT_FILE" ]]; then
    echo "No themepatcher.lst found — skipping theme import."
    exit 0
fi

echo "==> Importing default themes from $THEME_IMPORT_FILE..."

export PATH="$HOME/.local/bin:$PATH"
defaultTheme=""

while IFS='"' read -r _ themeName _ themeRepo; do
    [[ -z "${themeName:-}" ]] && continue
    [[ "$themeName" =~ ^[[:space:]]*# ]] && continue

    themePath="${CONF_DIR}/prodi/themes/${themeName}"
    if [[ "$DRY_RUN" == true ]]; then
        echo "    [DRY RUN] Would import theme: ${themeName} from ${themeRepo}"
    else
        mkdir -p "${themePath}"
        echo "    Importing ${themeName}..."
        if ! "${REPO_DIR}/Configs/.local/lib/prodi/theme.patch.sh" "${themeName}" "${themeRepo}" "--skipcaching" "false"; then
            echo "    [WARNING] Could not import theme: ${themeName}"
        else
            echo "    [OK] Theme installed: ${themeName}"
            [[ -z "$defaultTheme" ]] && defaultTheme="${themeName}"
        fi
    fi
done < "$THEME_IMPORT_FILE"

if [[ "$DRY_RUN" != true && -n "$defaultTheme" ]]; then
    switch_script="${HOME}/.local/lib/prodi/theme.switch.sh"
    [[ ! -x "$switch_script" ]] && switch_script="${REPO_DIR}/Configs/.local/lib/prodi/theme.switch.sh"
    if [[ -x "$switch_script" ]]; then
        echo "==> Activating default theme: ${defaultTheme}..."
        if ! "$switch_script" -q -s "$defaultTheme"; then
            echo "    [WARNING] Could not activate theme '${defaultTheme}' (may require an active Wayland session)."
        fi
    fi
fi

echo "==> Theme import complete!"
