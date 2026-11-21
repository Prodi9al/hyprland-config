#!/usr/bin/env bash
#|---/ /+------------------+---/ /|#
#|--/ /-| Global functions |--/ /-|#
#|/ /---+------------------+/ /---|#

set -e

scrDir="$(dirname "$(realpath "$0")")"
cloneDir="$(dirname "${scrDir}")"
cloneDir="${CLONE_DIR:-${cloneDir}}"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
cacheDir="${XDG_CACHE_HOME:-$HOME/.cache}/prodi"
aurList=("yay" "paru" "pikaur" "trizen" "aura" "pakku" "pacaur" "aurman" "pacseek" "aurutils")
shlList=("zsh" "fish")
pacmanCmd="${cloneDir}/Configs/.local/lib/prodi/pm.sh"

export cloneDir
export confDir
export cacheDir
export aurList
export shlList

pkg_installed() {
    local PkgIn=$1

    if pacman -Q "${PkgIn}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

chk_list() {
    vrType="$1"
    local inList=("${@:2}")
    for pkg in "${inList[@]}"; do
        if pkg_installed "${pkg}"; then
            printf -v "${vrType}" "%s" "${pkg}"
            export "${vrType}"
            return 0
        fi
    done
    return 1
}

aur_health_check() {
    local helper="$1"
    if command -v "${helper}" &>/dev/null; then
        if "${helper}" --version &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

chk_shell() {
    local candidate="${1:-}"
    local shell
    [ -n "${candidate}" ] || return 1
    for shell in "${shlList[@]}"; do
        [ "${shell}" = "${candidate}" ] && return 0
    done
    return 1
}

login_shell() {
    local entry
    entry="$(getent passwd "${USER}")" || return 1
    [ -n "${entry##*:}" ] || return 1
    basename "${entry##*:}"
}

setup_python_env() {
    local pythonEnvDir="${cacheDir}/python_env"
    if [ ! -f "${pythonEnvDir}/bin/deez" ]; then
        print_log -g "[python] " -b "setup :: " "Creating Python environment..."
        mkdir -p "${cacheDir}"
        python3 -m venv "${pythonEnvDir}"
        "${pythonEnvDir}/bin/pip" install --upgrade pip deez-dots 2>/dev/null || {
            print_log -err "[python] " -crit "error" "Failed to install deez-dots"
            return 1
        }
    fi
    export PYTHON_ENV_DIR="${pythonEnvDir}"
    export DEEZ_EXE="${pythonEnvDir}/bin/deez"
    return 0
}

print_log() {
    [[ "${PRINT_LOG:-true}" == "false" ]] && return 0
    while (("$#")); do
        case "$1" in
        -r | +r) echo -ne "\e[31m$2\e[0m" >&2; shift 2 ;;
        -g | +g) echo -ne "\e[32m$2\e[0m" >&2; shift 2 ;;
        -y | +y) echo -ne "\e[33m$2\e[0m" >&2; shift 2 ;;
        -b | +b) echo -ne "\e[34m$2\e[0m" >&2; shift 2 ;;
        -m | +m) echo -ne "\e[35m$2\e[0m" >&2; shift 2 ;;
        -c | +c) echo -ne "\e[36m$2\e[0m" >&2; shift 2 ;;
        -wt | +w) echo -ne "\e[37m$2\e[0m" >&2; shift 2 ;;
        -n | +n) echo -ne "\e[96m$2\e[0m" >&2; shift 2 ;;
        -stat) echo -ne "\e[4;30;46m $2 \e[0m :: " >&2; shift 2 ;;
        -crit) echo -ne "\e[30;41m $2 \e[0m :: " >&2; shift 2 ;;
        -warn) echo -ne "WARNING :: \e[30;43m $2 \e[0m :: " >&2; shift 2 ;;
        +) echo -ne "\e[38;5;$2m$3\e[0m" >&2; shift 3 ;;
        -sec) echo -ne "\e[32m[$2] \e[0m" >&2; shift 2 ;;
        -err) echo -ne "ERROR :: \e[4;31m$2 \e[0m :: " >&2; shift 2 ;;
        *) echo -ne "$1" >&2; shift ;;
        esac
    done
    echo "" >&2
}
