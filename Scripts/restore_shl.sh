#!/usr/bin/env bash
#|---/ /+---------------------------+---/ /|#
#|--/ /-| Script to configure shell |--/ /-|#
#|/ /---+---------------------------+/ /---|#

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

# shellcheck disable=SC2154
if resolve_shell; then
	print_log -sec "SHELL" -stat "detected" "${myShell}"
else
	print_log -sec "SHELL" -err "error" "no shell found..."
	exit 1
fi

# add zsh plugins
if [ "${myShell}" = "zsh" ] && pkg_installed zsh; then
	if [[ ${DRY_RUN} -ne 1 ]]; then
		read -r -p "Pre-install zsh plugins using oh-my-zsh? [y/N] " -n 1 PROMPT_INPUT
		echo ""
	else
		PROMPT_INPUT="y"
	fi

	if [[ "${PROMPT_INPUT}" == "y" || "${PROMPT_INPUT}" == "yes" ]]; then
		if ! pkg_installed oh-my-zsh-git; then
			if [[ ! -e "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
				print_log -sec "SHELL" -stat "cloning" "oh-my-zsh"
				if [[ ${DRY_RUN} -ne 1 ]]; then
					if ! sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended --keep-zshrc; then
						print_log -err "oh-my-zsh install failed..." "Please resolve this issue manually LATER..."
						print_log -warn "Continuing with existing oh-my-zsh..."
						exit 0
					fi
				fi
			else
				print_log -sec "SHELL" -stat "updating" "oh-my-zsh"
				zsh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/upgrade.sh)"
			fi
		fi

		#? Optional: oh-my-zsh
		if (pkg_installed oh-my-zsh-git || [[ -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]) && [[ ${DRY_RUN} -ne 1 ]]; then
			zsh_paths=(
				"$HOME/.oh-my-zsh"
				"/usr/local/share/oh-my-zsh"
				"/usr/share/oh-my-zsh"
			)
			for zsh_path in "${zsh_paths[@]}"; do [[ -d $zsh_path ]] && Zsh_Path=$zsh_path && break; done

			Zsh_rc="${ZDOTDIR:-$HOME}/.zshenv"
			Zsh_Path="${Zsh_Path:-$HOME/.oh-my-zsh}"
			Zsh_Plugins="$Zsh_Path/custom/plugins"
			Fix_Completion=""

			# generate plugins from list
			while read -r r_plugin; do
				z_plugin=$(awk -F '/' '{print $NF}' <<<"${r_plugin}")
				if [ "${r_plugin:0:4}" == "http" ] && [ ! -d "${Zsh_Plugins}/${z_plugin}" ]; then
					if [ -w "${Zsh_Plugins}" ]; then
						git clone "${r_plugin}" "${Zsh_Plugins}/${z_plugin}"
					else
						sudo git clone "${r_plugin}" "${Zsh_Plugins}/${z_plugin}"
					fi
				fi
				if [ "${z_plugin}" == "zsh-completions" ] && [ "$(grep -c 'fpath+=.*plugins/zsh-completions/src' "${Zsh_rc}")" -eq 0 ]; then
					Fix_Completion="\nfpath+=${ZSH_CUSTOM:-${ZSH:-/usr/share/oh-my-zsh}/custom}/plugins/zsh-completions/src"
				else
					[ -z "${z_plugin}" ] || w_plugin+=" ${z_plugin}"
				fi
			done < <(cut -d '#' -f 1 "${SCRIPTS_DIR}/restore_zsh.lst" | sed 's/ //g')

			# update plugin array in zshrc
			print_log -sec "SHELL" -stat "installing" "plugins (${w_plugin})"
			sed -i "/^prodi_plugins=/c\prodi_plugins=(${w_plugin})${Fix_Completion}" "${Zsh_rc}"
		else
			if [[ ${DRY_RUN} -eq "1" ]]; then
				while read -r r_plugin; do
					z_plugin=$(awk -F '/' '{print $NF}' <<<"${r_plugin}")
					[ -z "${z_plugin}" ] || w_plugin+=" ${z_plugin}"
				done < <(cut -d '#' -f 1 "${SCRIPTS_DIR}/restore_zsh.lst" | sed 's/ //g')
				print_log -sec "SHELL" -stat "installing" "plugins (${w_plugin})"
			else
				print_log -sec "SHELL" -err "error" "oh-my-zsh not installed, skipping plugin installation..."
			fi
		fi
	fi
fi

# set shell
shellPath="$(command -v "${myShell}" || true)"
if [ -z "${shellPath}" ]; then
	print_log -sec "SHELL" -err "error" "${myShell} is not installed, leaving the login shell alone..."
elif ! shell_listed "${shellPath}"; then
	print_log -sec "SHELL" -err "error" "${shellPath} is not listed in /etc/shells, leaving the login shell alone..."
elif [[ "$(login_shell)" != "${myShell}" ]]; then
	print_log -sec "SHELL" -stat "change" "shell to ${myShell}..."
	[[ ${DRY_RUN} -eq 1 ]] || chsh -s "${shellPath}"
else
	print_log -sec "SHELL" -stat "exist" "${myShell} is already set as shell..."
fi

print_log -g "[prodi shell]" -b " :: " "Shell configuration complete."
