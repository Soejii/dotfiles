#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export PATH="$HOME/flutter/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"

# ccache
export PATH="/usr/lib/ccache/bin:$PATH"
export CCACHE_DIR="$HOME/.ccache"
export CCACHE_MAXSIZE="5G"

# dotfiles bare repo
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# zoxide (smart cd)
eval "$(zoxide init bash)"

# fzf (fuzzy finder + Ctrl+R history)
source /usr/share/fzf/key-bindings.bash
source /usr/share/fzf/completion.bash
