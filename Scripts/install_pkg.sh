#!/usr/bin/env bash
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install pkgs from input list |--/ /-|#
#|/ /---+----------------------------------------+/ /---|#

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$(dirname "${SCRIPTS_DIR}")" && pwd)"

DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

# Source shared functions
. "$SCRIPTS_DIR/global_fn.sh"

listPkg="${1:-"${SCRIPTS_DIR}/pkg_core.lst"}"
archPkg=()
aurhPkg=()

print_log -g "[prodi packages]" -b " :: " "Reading package list: ${listPkg}"

while IFS= read -r line; do
	# Strip comments and skip empty
	pkg="${line%%#*}"
	pkg="${pkg// /}"
	[[ -z "${pkg}" ]] && continue

	if pkg_installed "${pkg}"; then
		print_log -y "[skip] " "${pkg}"
	elif pacman -Si "${pkg}" &>/dev/null; then
		repo=$(pacman -Si "${pkg}" | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
		print_log -b "[queue] " "${pkg}" -b " :: " -g "${repo}"
		archPkg+=("${pkg}")
	else
		print_log -b "[queue] " "${pkg}" -b " :: " -g "aur"
		aurhPkg+=("${pkg}")
	fi

done <"${listPkg}"

install_packages() {
	local -n pkg_array=$1
	local pkg_type=$2
	local install_cmd=$3

	if [[ ${#pkg_array[@]} -gt 0 ]]; then
		print_log -b "[install] " "${pkg_type} packages..."
		if [[ ${DRY_RUN} -eq 1 ]]; then
			for pkg in "${pkg_array[@]}"; do
				print_log -b "[pkg] " "${pkg}"
			done
		else
			${install_cmd} -S "${pkg_array[@]}"
		fi
	fi
}

echo ""
install_packages archPkg "arch" "sudo pacman"
echo ""
install_packages aurhPkg "aur" "yay"

print_log -g "[prodi packages]" -b " :: " "Package installation complete."
