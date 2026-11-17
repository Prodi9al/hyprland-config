    # prodi-shell tab completion
    if command -v prodi-shell &>/dev/null; then
        compdef _prodi-shell prodi-shell
        eval "$(prodi-shell completion zsh)"
    fi
