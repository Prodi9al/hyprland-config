#!/usr/bin/env bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Waybar controls     |--/ /-|#
#|/ /---+---------------------+/ /---|#

set -euo pipefail

usage() {
    echo "Usage: prodi-shell waybar <command>"
    echo ""
    echo "Commands:"
    echo "  -n, --next      Reload waybar (next config)"
    echo "  -p, --prev      Restart waybar"
    echo "  --help, -h      Show this help message"
    exit 0
}

case "${1:-}" in
    -n|--next)
        echo "==> Reloading waybar..."
        if pgrep -x waybar &>/dev/null; then
            pkill -RTMIN+19 waybar 2>/dev/null || true
            sleep 0.5
            waybar & disown
        else
            waybar & disown
        fi
        echo "==> Waybar reloaded."
        ;;
    -p|--prev)
        echo "==> Restarting waybar..."
        if pgrep -x waybar &>/dev/null; then
            killall waybar 2>/dev/null || true
            sleep 1
            waybar & disown
        else
            waybar & disown
        fi
        echo "==> Waybar restarted."
        ;;
    --help|-h|"")
        usage
        ;;
    *)
        echo "Error: unknown waybar command '$1'" >&2
        usage
        ;;
esac
