#!/usr/bin/env bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to apply post install configs |--/ /-|#
#|/ /---+--------------------------------------+/ /---|#

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

cloneDir="${cloneDir:-$CLONE_DIR}"
flg_DryRun=${flg_DryRun:-0}

# sddm
if pkg_installed sddm; then
    print_log -c "[DISPLAYMANAGER] " -b "detected :: " "sddm"
    if [ ! -d /etc/sddm.conf.d ]; then
        [ "${flg_DryRun}" -eq 1 ] || sudo mkdir -p /etc/sddm.conf.d
    fi
    if [ ! -f /etc/sddm.conf.d/prodi.conf ]; then
        print_log -g "[DISPLAYMANAGER] " -b " :: " "configuring sddm..."
        if [[ ${flg_DryRun} -ne 1 ]]; then
            sudo touch /etc/sddm.conf.d/prodi.conf
        fi
        print_log -g "[DISPLAYMANAGER] " -b " :: " "sddm configured..."
    else
        print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is already configured..."
    fi

    if [ ! -f "/usr/share/sddm/faces/${USER}.face.icon" ] && [ -f "${cloneDir}/Source/face.icon" ]; then
        if [[ ${flg_DryRun} -ne 1 ]]; then
            sudo cp "${cloneDir}/Source/face.icon" /usr/share/sddm/faces/
        fi
        print_log -g "[DISPLAYMANAGER] " -b " :: " "avatar set for ${USER}..."
    fi

else
    print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is not installed..."
fi

# dolphin
if pkg_installed dolphin && pkg_installed xdg-utils; then
    print_log -c "[FILEMANAGER] " -b "detected :: " "dolphin"
    if [[ ${flg_DryRun} -ne 1 ]]; then
        xdg-mime default org.kde.dolphin.desktop inode/directory
    fi
    print_log -g "[FILEMANAGER] " -b " :: " "setting dolphin as default file explorer..."

else
    print_log -y "[FILEMANAGER] " -b " :: " "dolphin not installed..."
fi

echo ""
echo "==> Prodi post-install complete."
