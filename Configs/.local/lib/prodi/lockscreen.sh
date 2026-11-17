#!/usr/bin/env bash
[[ $PRODI_SHELL_INIT -ne 1 ]] && eval "$(prodi-shell init)"
lockscreen="${HYPRLAND_LOCKSCREEN:-hyprlock}"
lockscreen="${LOCKSCREEN:-$lockscreen}"
lockscreen="${PRODI_LOCKSCREEN:-$lockscreen}"
source "${LIB_DIR}/prodi/shutils/argparse.sh"
argparse_init "$@"
argparse_program "prodi-shell lockscreen"
argparse_header "Prodi Lockscreen Launcher"
argparse "--get" "" "Get the current lockscreen command"
argparse "--select,-S" "" "Select a layout for the current lockscreen, if its wrapper script offers one"
argparse_finalize

case $ARGPARSE_ACTION in
    get) echo "$lockscreen" && exit 0 ;;
    select)
        # The Waybar Prodi menu's "Lockscreen" entry runs `lockscreen --select`.
        # It used to fall through to the launch below, which passes every
        # argument on to the lockscreen: hyprlock.sh happens to know --select,
        # but any other lockscreen just started -- locking the screen instead of
        # offering a choice. Only a wrapper script can provide a selector, so
        # hand over only to one that declares --select through argparse.sh
        # (as hyprlock.sh does) and never start a lock here. A mere mention of
        # the flag, e.g. in a comment, doesn't count.
        wrapper=$(command -v "$lockscreen.sh" 2>/dev/null)
        if [[ -n $wrapper ]] &&
            grep -qE -- '^[[:space:]]*argparse[[:space:]]+"([^"]*,)?--select(,[^"]*)?"' "$wrapper" 2>/dev/null; then
            exec "$wrapper" --select
        fi
        echo "Error: no layout selector for lockscreen '$lockscreen'" >&2
        notify-send -a "Prodi Alert" -i "system-lock-screen" "Lockscreen" "No layout selector for '$lockscreen'" 2>/dev/null
        exit 1
        ;;
esac

unit_name="prodi-lockscreen.service"
args=(-u "$unit_name" -t service)
if which "$lockscreen.sh" 2> /dev/null 1>&2; then
    printf "Executing $lockscreen wrapper script : %s\n" "$lockscreen.sh"
    app.sh "${args[@]}" -- "$lockscreen.sh" "$@"
else
    printf "Executing raw command: %s\n" "$lockscreen"
    app.sh "${args[@]}" -- "$lockscreen" "$@"
fi
