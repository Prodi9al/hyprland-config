#!/usr/bin/env bash
[[ $PRODI_SHELL_INIT -ne 1 ]] && eval "$(prodi-shell init)"

notify-send -a "Deprecation Notice" "prodi-launch.sh is deprecated. Please use prodi-shell open instead." -i dialog-information

prodi-shell open "$@"
