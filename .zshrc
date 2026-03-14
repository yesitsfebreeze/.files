# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="nanotech"
ENABLE_CORRECTION="true"

COMPLETION_WAITING_DOTS="true"


HIST_STAMPS="dd/mm/yyyy"

# Standard plugins can be found in $ZSH/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git docker 1password macos)

source $ZSH/oh-my-zsh.sh

export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

export PATH="$HOME/.local/bin:$PATH"
alias ls="eza --group-directories-first --icons --all"

cd() {
  builtin cd "$@" || return
  ls
}

alias .="open ."
alias ..="cd .."
alias c='cd'
alias e="nvim"
alias dk="docker rm -f $(docker ps -a -q)"

di() {
  cd ~/dev/diw/diw-installer/customers/$@
}

dc() {
  cd ~/dev/diw/diw-sources/customers/$@
}



alias cl="claude --dangerously-skip-permissions"
alias oc="opencode"

# opencode
export PATH=/Users/feb/.opencode/bin:$PATH
