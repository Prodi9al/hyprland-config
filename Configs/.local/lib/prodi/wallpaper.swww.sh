#!/usr/bin/env bash

#! A fallback script. Incase user explcitly set swww as wallpaper backend
notify-send "DEPRECATION NOTICE: swww backend is deprecated, please switch to awww or other supported backends. See 'prodi-shell wallpaper --help' for more info."

scrDir="$(dirname "$(realpath "$0")")"
source "$scrDir/globalcontrol.sh"
selected_wall="${1:-"$PRODI_CACHE_HOME/wall.set"}"
wallpaper_acquire_lock 15
trap 'flock -u "$WALLPAPER_LOCK_FD"' EXIT
case "$WALLPAPER_SET_FLAG" in
    p)
        xtrans=$WALLPAPER_SWWW_TRANSITION_PREV
        xtrans="${xtrans:-"outer"}"
        ;;
    n)
        xtrans=$WALLPAPER_SWWW_TRANSITION_NEXT
        xtrans="${xtrans:-"grow"}"
        ;;
esac
[ -z "$selected_wall" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "$selected_wall")"
if ! timeout 15 swww query &> /dev/null; then
    # Detached from our stdio: a daemon holding the caller's stdout keeps a
    # "$(wallpaper.sh ...)" capture open forever, which froze the installer (#2156).
    swww-daemon --format xrgb </dev/null &>/dev/null &
    disown
    timeout 15 swww query && timeout 15 swww restore
fi
is_video=$(file --mime-type -b "$selected_wall" | grep -c '^video/')
if [ "$is_video" -eq 1 ]; then
    print_log -sec "wallpaper" -stat "converting video" "$selected_wall"
    mkdir -p "$PRODI_CACHE_HOME/wallpapers/thumbnails"
    cached_thumb="$PRODI_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "$selected_wall" | cut -d' ' -f1).png"
    extract_thumbnail "$selected_wall" "$cached_thumb"
    selected_wall="$cached_thumb"
fi
xtrans=$WALLPAPER_SWWW_TRANSITION_DEFAULT
[ -z "$xtrans" ] && xtrans="grow"
[ -z "$wallFramerate" ] && wallFramerate=60
[ -z "$wallTransDuration" ] && wallTransDuration=0.4
print_log -sec "wallpaper" -stat "apply" "$selected_wall"
timeout 30 swww img "$(readlink -f "$selected_wall")" --transition-bezier .43,1.19,1,.4 --transition-type "$xtrans" --transition-duration "$wallTransDuration" --transition-fps "$wallFramerate" --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo "0,0")"
