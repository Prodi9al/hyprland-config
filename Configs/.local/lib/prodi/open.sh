#!/usr/bin/env bash
#|---/ /+----------------------------+---/ /|#
#|--/ /-| Open files and apps      |--/ /-|#
#|/ /---+----------------------------+/ /---|#

set -euo pipefail

usage() {
    echo "Usage: prodi-shell open <target> [args...]"
    echo ""
    echo "Open a file, directory, or application with the default handler."
    echo ""
    echo "Options:"
    echo "  --fall <app> <target>  Open target with a specific application"
    echo "  --help, -h             Show this help message"
    exit 0
}

if [[ $# -eq 0 ]]; then
    usage
fi

target="$1"
shift || true

# Parse --fall <app>
app=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fall)
            app="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            break
            ;;
    esac
done

if [[ -n "$app" ]]; then
    # Open target with a specific application
    if command -v "$app" &>/dev/null; then
        "$app" "$target" &
    else
        echo "Error: application '$app' not found" >&2
        exit 1
    fi
else
    # Open with default handler
    if command -v xdg-open &>/dev/null; then
        xdg-open "$target" &
    elif command -v open &>/dev/null; then
        open "$target" &
    else
        echo "Error: no file opener found (xdg-open or open)" >&2
        exit 1
    fi
fi
