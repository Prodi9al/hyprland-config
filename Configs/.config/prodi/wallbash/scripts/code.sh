#!/usr/bin/env bash

# shellcheck source=$HOME/.local/bin/prodi-shell
# shellcheck disable=SC1091
if ! source "$(command -v prodi-shell)"; then
    echo "[wallbash] code :: Error: prodi-shell not found."
    echo "[wallbash] code :: Is Prodi installed?"
    exit 1
fi

cacheDir="${cacheDir:-$XDG_CACHE_HOME/prodi}"
# confDir="${confDir:-$XDG_CONFIG_HOME}"
readarray -t codeConf < <(find -L "$confDir" -mindepth 1 -maxdepth 1 -type d -name "Code*" -o -name "VSCodium*" -o -name "Cursor*" | sort)
readarray -t codeVsix < <(find -L "$HOME" -mindepth 1 -maxdepth 1 -type d -name ".vscode*" -o -name ".cursor" | sort)
# tmpFile="/tmp/$(id -u)$(basename ${0}).tmp"

#// install  ext
for i in "${!codeVsix[@]}"; do
    [[ -z "${codeVsix[i]}" ]] && continue
    file=$(find -L "${codeVsix[i]}" -type f -path "*extensions/thehydeproject*" -name "wallbash.json")
    if [ -z "${file}" ]; then
        CODE_WALLBASH_SHA256="${CODE_WALLBASH_SHA256:-ece5b19dfa7b9ad45a07eaf87f9aa20c4ccfaf6b0fe98cc9608c2788df72ba8f}"
        [ -f "${cacheDir}/landing/Code_Wallbash.vsix" ] || curl -L -o "${cacheDir}/landing/Code_Wallbash.vsix" https://github.com/HyDE-Project/code-wallbash/raw/856295e20cc347ded8c3c51e38e0ab8f6144e3e2/release/Code_Wallbash.vsix
        echo "${CODE_WALLBASH_SHA256}  ${cacheDir}/landing/Code_Wallbash.vsix" | sha256sum -c - || { echo "[wallbashcode] VSIX checksum mismatch"; exit 1; }
        case ${codeVsix[i]} in
        *".cursor"*)
            echo "[wallbashcode] Cursor IDE: Manual intervention required for extension installation."
            echo "[wallbashcode] Read the instructions here: https://www.cursor.com/how-to-install-extension "
            ;;
        *)
            pkg_installed code-insiders && code-insiders --install-extension "${cacheDir}/landing/Code_Wallbash.vsix"
            pkg_installed code && code --install-extension "${cacheDir}/landing/Code_Wallbash.vsix"
            pkg_installed vscodium && vscodium --install-extension "${cacheDir}/landing/Code_Wallbash.vsix"
            echo "[wallbashcode] Installed: in ${codeVsix[i]}"
            ;;
        esac
    fi
done

#// apply theme

cat <<NOTICE
[wallbashcode] To apply the Wallbash theme, open the command palette (Ctrl+Shift+P)
[wallbashcode]  and type "Preferences: Color Theme" and select "Wallbash".
NOTICE

set_theme="${1:-"Wallbash"}"
for i in "${!codeConf[@]}"; do
    [ -d "${codeConf[i]}/User" ] || continue
    [ -f "${codeConf[i]}/User/settings.json" ] || echo -e "{\n \"workbench.colorTheme\":\"Wallbash\" \n}" >"${codeConf[i]}/User/settings.json"
    extTheme="$(
        "$LIB_DIR/hyde/parse.json.py" -CRQ '.["workbench.colorTheme"]' "${codeConf[i]}/User/settings.json"
    )"
    if [ "${extTheme}" != "${set_theme}" ]; then
        "$LIB_DIR/hyde/parse.json.py" -CU '.["workbench.colorTheme"]' "${set_theme}" "${codeConf[i]}/User/settings.json"
        echo "[wallbashcode] Theme set to: ${set_theme} in ${codeConf[i]}"
    #! jq '.["workbench.colorTheme"] = "Wallbash"' "${codeConf[i]}/User/settings.json" >"${tmpFile}" && mv "${tmpFile}" "${codeConf[i]}/User/settings.json" # DEPRECATED
    fi
done
