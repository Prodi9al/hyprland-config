#!/usr/bin/env bash
#|---/ /+------------------------------------+---/ /|#
#|--/ /-| Script to extract fonts and themes |--/ /-|#
#|/ /---+------------------------------------+/ /---|#

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

while IFS= read -r lst; do
	# Skip lines starting with #
	[[ "$lst" =~ ^[[:space:]]*# ]] && continue
	# Check if the line has the correct number of fields
	if [ "$(echo "$lst" | awk -F '|' '{print NF}')" -ne 2 ]; then
		continue
	fi

	fnt=$(awk -F '|' '{print $1}' <<<"$lst")
	tgt=$(awk -F '|' '{print $2}' <<<"$lst")
	tgt=$(eval "echo $tgt")

	if [[ "${tgt}" =~ /(usr|usr\/local)\/share/ && -d /run/current-system/sw/share/ ]]; then
		print_log -warn "nixos" "Detected NixOS system, skipping ${tgt}..."
		continue
	fi

	if [ ! -d "${tgt}" ]; then
		if [[ ${DRY_RUN} -ne 1 ]]; then
			mkdir -p "${tgt}" 2>/dev/null || sudo mkdir -p "${tgt}"
		else
			print_log -y "[dry-run]" -b " :: " "Would create directory: ${tgt}"
		fi
	fi

	if [[ ${DRY_RUN} -eq 1 ]]; then
		print_log -y "[dry-run]" -b " :: " "Would extract ${fnt}.tar.gz → ${tgt}"
		continue
	fi

	if [ -w "${tgt}" ]; then
		tar -xzf "${REPO_DIR}/Source/arcs/${fnt}.tar.gz" -C "${tgt}/"
	else
		print_log -warn "not writable" "Extracting as root: ${tgt}"
		if ! sudo tar -xzf "${REPO_DIR}/Source/arcs/${fnt}.tar.gz" -C "${tgt}/" 2>/dev/null; then
			print_log -err "extraction by root FAILED" " giving up..."
			print_log -warn "The above error can be ignored if '${tgt}' is not writable..."
		fi
	fi
	print_log "${fnt}.tar.gz" -r " --> " "${tgt}..."

done <"${SCRIPTS_DIR}/restore_fnt.lst"

echo ""
print_log -stat "rebuild" "font cache"
fc-cache -f
