#!/usr/bin/env bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Workflow selector   |--/ /-|#
#|/ /---+---------------------+/ /---|#

set -euo pipefail

usage() {
    echo "Usage: prodi-shell workflows <command>"
    echo ""
    echo "Commands:"
    echo "  --select      Open workflow selector"
    echo "  --help, -h    Show this help message"
    exit 0
}

case "${1:-}" in
    --select)
        echo "==> Opening workflow selector..."
        if command -v rofi &>/dev/null; then
            rofi -show drun -theme-str '* { font: "JetBrainsMono Nerd Font 10"; }'
        elif command -v wofi &>/dev/null; then
            wofi --show drun
        else
            echo "Error: no launcher found (rofi or wofi)" >&2
            exit 1
        fi
        ;;
    --help|-h|"")
        usage
        ;;
    *)
        echo "Error: unknown workflows command '$1'" >&2
        usage
        ;;
esac
