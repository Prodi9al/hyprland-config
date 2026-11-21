#!/usr/bin/env bash
#|---/ /+-------------------------------------+---/ /|#
#|--/ /-| Script to apply pre install configs |--/ /-|#
#|/ /---+-------------------------------------+/ /---|#

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}
flg_Nvidia=${flg_Nvidia:-1}

# Python environment setup
setup_python_env || exit 1

echo ""
echo "==> Prodi pre-install complete. Python environment ready at ${PYTHON_ENV_DIR}"
echo "    Run: ./Scripts/install.sh to perform full installation."
