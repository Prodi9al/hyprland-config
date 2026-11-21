#!/usr/bin/env bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| System commands     |--/ /-|#
#|/ /---+---------------------+/ /---|#

set -euo pipefail

usage() {
    echo "Usage: prodi-shell system <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  update [flags]   Update system packages"
    echo "  --help, -h       Show this help message"
    exit 0
}

cmd="${1:-}"
shift || true

case "$cmd" in
    update)
        echo "==> Updating system packages..."
        if command -v sudo &>/dev/null; then
            sudo pacman -Syu --needed --noconfirm "${@}"
        else
            pacman -Syu --needed --noconfirm "${@}"
        fi
        echo "==> System update complete."
        ;;
    --help|-h|"")
        usage
        ;;
    *)
        echo "Error: unknown system command '$cmd'" >&2
        usage
        ;;
esac
