#!/usr/bin/env bash
#|---/ /+------------------------------+---/ /|#
#|--/ /-| Chaotic AUR helper (prodi) |--/ /-|#
#|/ /---+------------------------------+/ /---|#

set -euo pipefail

execName="$0 $*"

check_Root() {
	if [ "$EUID" -ne 0 ]; then
		echo "Error: [ $execName ] must be run as root!"
		exit 1
	fi
}

check_Ping() {
	if ! ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
		echo "Error: No internet connection."
		exit 1
	fi
}

write_ChaoticAUR() {
	is_ChaoticAUR=$(grep "chaotic-aur" /etc/pacman.conf >/dev/null 2>&1; echo $?)

	if [ "$1" == "append" ]; then
		echo "Appending Chaotic AUR"
		if [ "$is_ChaoticAUR" -eq 0 ]; then
			echo "Chaotic-AUR already in pacman.conf..."
		else
			echo "Appending Chaotic-AUR in pacman.conf..."
			echo -e "\r\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >>/etc/pacman.conf
		fi
	elif [ "$1" == "remove" ]; then
		echo "Removing Chaotic AUR from pacman.conf"
		if grep -q 'chaotic-aur' /etc/pacman.conf; then
			sed -i '/chaotic-aur/d' /etc/pacman.conf
			sed -i '/chaotic-mirrorlist/d' /etc/pacman.conf
		else
			echo "Chaotic-AUR is not present in pacman.conf..."
		fi
	fi
}

check_Integrity() {
	is_ChaoticAUR=$(grep "chaotic-aur" /etc/pacman.conf >/dev/null 2>&1; echo $?)

	if [ "$is_ChaoticAUR" -ne 0 ]; then
		echo "Chaotic AUR entry not found in pacman.conf"
		return 1
	fi

	if ! pacman-key -l | grep 3056513887B78AEB >/dev/null; then
		echo "Chaotic AUR key not found"
		return 1
	fi

	if ! pacman -Qq chaotic-keyring 2>/dev/null; then
		echo "Chaotic AUR keyring not found"
		return 1
	fi

	if ! pacman -Qq chaotic-mirrorlist 2>/dev/null; then
		echo "Chaotic AUR mirrorlist not found"
		return 1
	fi

	return 0
}

install() {
	box_me() {
		local s="Prodi: $*"
		local cols=${COLUMNS:-80}
		local line
		line=$(printf '=%.0s' $(seq 1 $((cols - 2))))
		echo " ═${s//?/═}"
		echo "║$s ║"
		echo " ═${s//?/═}"
	}

	box_me "Installing the key"
	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || {
		echo "Failed to install the key"
		exit 1
	}
	pacman-key --lsign-key 3056513887B78AEB || {
		echo "Failed to locally sign the key"
		exit 1
	}

	box_me "Downloading the keyring"
	pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' || {
		echo "Failed to download the keyring"
		exit 1
	}

	box_me "Downloading the mirrorlist"
	pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || {
		echo "Failed to download the mirrorlist"
		exit 1
	}

	write_ChaoticAUR "append" || {
		echo "Failed to append Chaotic AUR"
		exit 1
	}

	box_me "Refreshing the mirrorlists"
	pacman -Sy || {
		echo "Failed to refresh the mirrorlists"
		exit 1
	}

	box_me "Chaotic-AUR has been successfully installed!"
}

purge() {
	box_me() {
		local s="Prodi: $*"
		local cols=${COLUMNS:-80}
		local line
		line=$(printf '=%.0s' $(seq 1 $((cols - 2))))
		echo " ═${s//?/═}"
		echo "║$s ║"
		echo " ═${s//?/═}"
	}

	if pacman-key -l | grep 3056513887B78AEB >/dev/null; then
		echo "Deleting the key"
		pacman-key --delete EF925EA60F33D0CB85C44AD13056513887B78AEB
	fi

	if pacman -Qq chaotic-keyring 2>/dev/null; then
		echo "Uninstalling the keyring"
		pacman -Rns --noconfirm chaotic-keyring
	fi

	if pacman -Qq chaotic-mirrorlist 2>/dev/null; then
		echo "Uninstalling the mirrorlist"
		pacman -Rns --noconfirm chaotic-mirrorlist
	fi

	write_ChaoticAUR "remove"
	pacman -Sy
	echo "Chaotic-AUR has been successfully purged"
}

if ! command -v pacman >/dev/null 2>&1; then
	echo "Error: pacman not detected"
	exit 1
fi

case "$1" in
--install)
	check_Ping
	check_Root
	if check_Integrity >/dev/null; then
		echo "Chaotic AUR already installed. Reinstall? [y/N]"
		read -r ans
		if [ "$ans" != "Y" ] && [ "$ans" != "y" ]; then
			echo "Chaotic AUR: Operation Cancelled."
			exit 0
		fi
	fi
	install
	;;
--uninstall)
	check_Root
	purge
	;;
*)
	cat <<HELP
Invalid option: $1
Usage: $0 [option]
    --install    Install chaotic AUR
    --uninstall  Uninstall chaotic AUR
HELP
	;;
esac
