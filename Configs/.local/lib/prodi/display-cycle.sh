#!/bin/bash
# display-cycle.sh — Cycle projection modes via F1
# Modes: laptop-only → mirror → extend-right → external-only → (repeat)
# State stored in ~/.local/state/hyde/display-mode

STATE_FILE="$HOME/.local/state/hyde/display-mode"
STATE_DIR="$(dirname "$STATE_FILE")"
mkdir -p "$STATE_DIR"

INTERNAL="eDP-1"
CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop-only")

# Detect connected external monitor
EXTERNAL=$(hyprctl monitors all -j 2>/dev/null | python3 -c "
import json,sys
monitors = json.load(sys.stdin)
for m in monitors:
    if m['name'] != 'eDP-1':
        print(m['name'])
        break
" 2>/dev/null)

notify() {
    notify-send -i display "Display Mode" "$1" -t 2000 2>/dev/null || true
}

apply_laptop_only() {
    hyprctl keyword monitor "$INTERNAL,1920x1080@60,0x0,1.25"
    if [ -n "$EXTERNAL" ]; then
        hyprctl keyword monitor "$EXTERNAL,disable"
    fi
    # Move all workspaces back to internal
    for i in $(seq 1 10); do
        hyprctl dispatch moveworkspacetomonitor "$i $INTERNAL" 2>/dev/null
    done
    echo "laptop-only" > "$STATE_FILE"
    notify "💻 Laptop Only"
}

apply_mirror() {
    if [ -z "$EXTERNAL" ]; then
        notify "⚠️ No external monitor detected"
        echo "laptop-only" > "$STATE_FILE"
        return
    fi
    # Get external preferred resolution
    EXT_RES=$(hyprctl monitors all -j 2>/dev/null | python3 -c "
import json,sys
monitors = json.load(sys.stdin)
for m in monitors:
    if m['name'] != 'eDP-1':
        w,h = m['width'] or 1920, m['height'] or 1080
        r = m['refreshRate'] or 60
        print(f'{w}x{h}@{r:.2f}')
        break
" 2>/dev/null || echo "1920x1080@60.00")
    hyprctl keyword monitor "$EXTERNAL,$EXT_RES,0x0,1,mirror,$INTERNAL"
    echo "mirror" > "$STATE_FILE"
    notify "🪞 Mirror"
}

apply_extend() {
    if [ -z "$EXTERNAL" ]; then
        notify "⚠️ No external monitor detected"
        echo "laptop-only" > "$STATE_FILE"
        return
    fi
    EXT_RES=$(hyprctl monitors all -j 2>/dev/null | python3 -c "
import json,sys
monitors = json.load(sys.stdin)
for m in monitors:
    if m['name'] != 'eDP-1':
        w,h = m['width'] or 1920, m['height'] or 1080
        r = m['refreshRate'] or 60
        print(f'{w}x{h}@{r:.2f}')
        break
" 2>/dev/null || echo "1920x1080@60.00")
    hyprctl keyword monitor "$INTERNAL,1920x1080@60,0x0,1.25"
    hyprctl keyword monitor "$EXTERNAL,$EXT_RES,1920x0,1"
    echo "extend" > "$STATE_FILE"
    notify "🖥️ Extend Right"
}

apply_external_only() {
    if [ -z "$EXTERNAL" ]; then
        notify "⚠️ No external monitor detected"
        echo "laptop-only" > "$STATE_FILE"
        return
    fi
    EXT_RES=$(hyprctl monitors all -j 2>/dev/null | python3 -c "
import json,sys
monitors = json.load(sys.stdin)
for m in monitors:
    if m['name'] != 'eDP-1':
        w,h = m['width'] or 1920, m['height'] or 1080
        r = m['refreshRate'] or 60
        print(f'{w}x{h}@{r:.2f}')
        break
" 2>/dev/null || echo "1920x1080@60.00")
    hyprctl keyword monitor "$EXTERNAL,$EXT_RES,0x0,1"
    hyprctl keyword monitor "$INTERNAL,disable"
    # Move all workspaces to external
    for i in $(seq 1 10); do
        hyprctl dispatch moveworkspacetomonitor "$i $EXTERNAL" 2>/dev/null
    done
    echo "external-only" > "$STATE_FILE"
    notify "📺 External Only"
}

# Cycle to next mode
case "$CURRENT_MODE" in
    "laptop-only")   apply_mirror ;;
    "mirror")        apply_extend ;;
    "extend")        apply_external_only ;;
    "external-only") apply_laptop_only ;;
    *)               apply_laptop_only ;;
esac
