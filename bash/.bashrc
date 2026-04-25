#
# ~/.bashrc
#

# Enable git branch in prompt
if [ -f /usr/share/git/completion/git-prompt.sh ]; then
    . /usr/share/git/completion/git-prompt.sh
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export NVM_DIR="$HOME/.nvm"
if [ -n "$CODESPACE_NAME" ]; then
    export NVM_DIR="$HOME/nvm"
fi
if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    nvm use --lts > /dev/null
else
    # export PATH="$PATH:/usr/bin"
    :
fi

# Git prompt settings
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto"

# export PS1='\[\e[0;36m\][\u@\h]:\w\$ \[\e[0m\]'
export PS1='\[\e[0;36m\][\u@\h \W$(__git_ps1 " (%s)")]\$ \[\e[0m\]'
# export PS1=[\u@\h \W]\$

# pnpm
export PNPM_HOME="/home/dyung/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# [[ -r /usr/share/bash-completion/bash_completion ]] && \
#   . /usr/share/bash-completion/bash_completion

# Enable ble.sh (bash autosuggestions)
if [[ -z "$CODESPACE_NAME" ]] && [[ $- == *i* ]] && [[ -f ~/.local/share/blesh/ble.sh ]]; then
  source ~/.local/share/blesh/ble.sh
  type ble-face &>/dev/null && ble-face auto_complete='fg=242' # ,bg=235'
fi

if [ -n "$CODESPACE_NAME" ]; then
  if ! pgrep -x "syncthing" > /dev/null; then
    syncthing --no-browser > /dev/null 2>&1 &
    echo "Syncthing started in background."
  fi
fi

export GPG_TTY=$(tty)

unset GITHUB_TOKEN

. "$HOME/.local/bin/env"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
