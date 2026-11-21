#!/usr/bin/env bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to adapt locale to system     |--/ /-|#
#|/ /---+--------------------------------------+/ /---|#

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

# Source shared functions
# shellcheck source=./global_fn.sh
# shellcheck disable=SC1091
. "$SCRIPTS_DIR/global_fn.sh"

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
dataDir="${XDG_DATA_HOME:-$HOME/.local/share}"

kbLayout=""
if command -v localectl >/dev/null 2>&1; then
	kbLayout=$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/{print $2; exit}')
fi

# --- keyboard layout ------------------------------------------------------
hyprLua="${confDir}/hypr/hyprland.lua"
if [ -f "${hyprLua}" ] && ! grep -q "kb_layout" "${hyprLua}"; then
	if [ -n "${kbLayout}" ] && [ "${kbLayout}" != "us" ]; then
		if [[ ${DRY_RUN} -eq 1 ]]; then
			print_log -y "[LOCALE] " -b "dry-run :: " "Would set kb_layout to '${kbLayout}'"
		else
			{
				echo ""
				echo "-- Auto-detected from 'localectl' on first install; edit or remove freely."
				echo "hl.config({"
				echo "	input = {"
				echo "		kb_layout = \"${kbLayout}\","
				echo "	},"
				echo "})"
			} >>"${hyprLua}"
			print_log -g "[LOCALE] " -b "keyboard :: " "kb_layout set to '${kbLayout}'"
		fi
	fi
fi

# --- clock: time format (12h vs 24h), from LC_TIME's t_fmt ----------------
clockFile="${dataDir}/waybar/modules/clock.jsonc"
if [ -f "${clockFile}" ] && command -v jq >/dev/null 2>&1; then
	timeFmt=$(locale -k LC_TIME 2>/dev/null | grep '^t_fmt=' | cut -d= -f2 | tr -d '"')
	newTimeFmt="{:%I:%M %p}"
	if [[ "${timeFmt}" == *%I* || "${timeFmt}" == *%p* || "${timeFmt}" == *%r* ]]; then
		newTimeFmt="{:%I:%M %p}"
	elif [[ "${timeFmt}" == *%H* || "${timeFmt}" == *%T* || "${timeFmt}" == *%k* ]]; then
		newTimeFmt="{:%H:%M}"
	fi

	# --- clock: date order (day/month/year position), from LC_TIME's d_fmt ---
	dateFmt=$(locale -k LC_TIME 2>/dev/null | grep '^d_fmt=' | cut -d= -f2 | tr -d '"')
	order=""
	while read -r tok; do
		case "${tok}" in
			%d | %e) order+="d" ;;
			%m) order+="m" ;;
			%Y | %y) order+="y" ;;
		esac
	done < <(grep -oE '%[a-zA-Z]' <<<"${dateFmt}")

	newDateSeg="%d·%m·%y"
	if [ "${#order}" -eq 3 ] && [[ "${order}" == *d* && "${order}" == *m* && "${order}" == *y* ]]; then
		newDateSeg=""
		for i in 0 1 2; do
			case "${order:${i}:1}" in
				d) newDateSeg+="%d" ;;
				m) newDateSeg+="%m" ;;
				y) newDateSeg+="%y" ;;
			esac
			[ "${i}" -lt 2 ] && newDateSeg+="·"
		done
	fi

	currentFmt=$(jq -r '.clock.format // ""' "${clockFile}" 2>/dev/null)
	currentAlt=$(jq -r '.clock["format-alt"] // ""' "${clockFile}" 2>/dev/null)
	newAlt=$(jq -rn --arg alt "${currentAlt}" --arg seg "${newDateSeg}" '$alt | sub("%d·%m·%y"; $seg)')

	if [ "${currentFmt}" != "${newTimeFmt}" ] || [ "${currentAlt}" != "${newAlt}" ]; then
		if [[ ${DRY_RUN} -eq 1 ]]; then
			print_log -y "[LOCALE] " -b "dry-run :: " "Would update clock time/date format"
		else
			tmp="$(mktemp)"
			if jq --arg fmt "${newTimeFmt}" --arg alt "${newAlt}" \
				'.clock.format = $fmt | .clock["format-alt"] = $alt' \
				"${clockFile}" >"${tmp}" 2>/dev/null; then
				mv "${tmp}" "${clockFile}"
				print_log -g "[LOCALE] " -b "clock :: " "time/date format matched to locale"
			else
				rm -f "${tmp}"
				print_log -warn "[LOCALE] " "Failed to update clock format in ${clockFile}"
			fi
		fi
	fi
fi

# --- keybindings: WYSIWYG remap of punctuation-triggered binds ------------
keyBindsFile="${dataDir}/hypr/lua/key_binds.lua"
remapFile="${confDir}/hypr/locale_remap.lua"
if [ -f "${keyBindsFile}" ] && [ -f "${hyprLua}" ] && command -v xkbcli >/dev/null 2>&1 &&
	[ -n "${kbLayout}" ] && [ "${kbLayout}" != "us" ]; then

	xkb_code_sym_pairs() {
		xkbcli compile-keymap --layout "$1" 2>/dev/null | gawk '
			/^\s*key <[A-Z0-9]+>\s*\{/ {
				match($0, /<([A-Z0-9]+)>/, c); match($0, /\[\s*([A-Za-z0-9_]+)/, s)
				if (c[1] != "" && s[1] != "") print c[1], s[1]
			}'
	}

	declare -A usSym2Code=() tgtCode2Sym=()
	while read -r code sym; do
		[ -n "${code}" ] && usSym2Code["${sym}"]="${code}"
	done < <(xkb_code_sym_pairs us)
	while read -r code sym; do
		[ -n "${code}" ] && tgtCode2Sym["${code}"]="${sym}"
	done < <(xkb_code_sym_pairs "${kbLayout}")

	remaps=()
	while read -r triggerName; do
		[[ "${triggerName}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
		code="${usSym2Code[${triggerName}]:-}"
		[ -n "${code}" ] || continue
		tgtSym="${tgtCode2Sym[${code}]:-}"
		[ -n "${tgtSym}" ] || continue
		[ "${tgtSym}" = "${triggerName}" ] && continue
		remaps+=("${triggerName}:${tgtSym}")
	done < <(grep -oE 'MOD \.\. " \+ [^"]+"' "${keyBindsFile}" | sed -E 's/.*\+ //; s/"$//' | awk '{print $NF}' | sort -u)

	unbindLines=""
	bindLines=""
	for pair in "${remaps[@]}"; do
		us="${pair%%:*}"
		tgt="${pair##*:}"
		while read -r lineno; do
			bindLine=$(sed -n "${lineno}p" "${keyBindsFile}")
			descLine=$(sed -n "$((lineno - 1))p" "${keyBindsFile}")
			[[ "${descLine}" == _F\ =\ * ]] || continue
			combo="${bindLine#*MOD .. \"}"
			combo="${combo%%\"*}"
			newBindLine="${bindLine/+ ${us}\"/+ ${tgt}\"}"
			unbindLines+="hl.unbind(MOD .. \"${combo}\")"$'\n'
			bindLines+="${descLine}"$'\n'
			bindLines+="${newBindLine}"$'\n\n'
		done < <(grep -nF "+ ${us}\"" "${keyBindsFile}" | cut -d: -f1)
	done
	remapBody="${unbindLines}${unbindLines:+$'\n'}${bindLines}"

	if [ -n "${remapBody}" ]; then
		newRemapFile=$(
			echo "-- Auto-generated by Scripts/restore_locale.sh -- do not edit, it is"
			echo "-- overwritten on every restore. Remaps US-authored punctuation binds"
			echo "-- to the physically same key on the '${kbLayout}' layout."
			echo "local MOD = prodi.config.modifiers.main"
			echo ""
			printf '%s' "${remapBody}"
		)

		if [ ! -f "${remapFile}" ] || [ "$(cat "${remapFile}" 2>/dev/null)" != "${newRemapFile}" ]; then
			if [[ ${DRY_RUN} -eq 1 ]]; then
				print_log -y "[LOCALE] " -b "dry-run :: " "Would remap keybinds for '${kbLayout}': ${remaps[*]}"
			else
				printf '%s\n' "${newRemapFile}" >"${remapFile}"
				print_log -g "[LOCALE] " -b "keybinds :: " "remapped for '${kbLayout}': ${remaps[*]}"
			fi
		fi

		if ! grep -q 'check_require("locale_remap")' "${hyprLua}"; then
			if [[ ${DRY_RUN} -ne 1 ]]; then
				{
					echo ""
					echo "-- Loads Scripts/restore_locale.sh's generated keybind remap, if any."
					echo "check_require(\"locale_remap\")"
				} >>"${hyprLua}"
			fi
		fi
	fi
fi

print_log -g "[prodi locale]" -b " :: " "Locale adaptation complete."
