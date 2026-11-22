#!/usr/bin/env zsh

#! ██████╗░░█████╗░  ███╗░░██╗░█████╗░████████╗  ███████╗██████╗░██╗████████╗
#! ██╔══██╗██╔══██╗  ████╗░██║██╔══██╗╚══██╔══╝  ██╔════╝██╔══██╗██║╚══██╔══╝
#! ██║░░██║██║░░██║  ██╔██╗██║██║░░██║░░░██║░░░  █████╗░░██║░░██║██║░░░██║░░░
#! ██║░░██║██║░░██║  ██║╚████║██║░░██║░░░██║░░░  ██╔══╝░░██║░░██║██║░░░██║░░░
#! ██████╔╝╚█████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░  ███████╗██████╔╝██║░░░██║░░░
#! ╚═════╝░░╚════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░  ╚══════╝╚═════╝░╚═╝░░░╚═╝░░░


# Sources vital global environment variables and configurations // Users are encouraged to use ./user.zsh for customization
# shellcheck disable=SC1091
if ! . "$ZDOTDIR/conf.d/prodi/env.zsh"; then
    echo "Error: Could not source $ZDOTDIR/conf.d/prodi/env.zsh"
    return 1
fi

if [[ $- == *i* ]] && [ -f "$ZDOTDIR/conf.d/prodi/terminal.zsh" ]; then
    . "$ZDOTDIR/conf.d/prodi/terminal.zsh" || echo "Error: Could not source $ZDOTDIR/conf.d/prodi/terminal.zsh"
fi
