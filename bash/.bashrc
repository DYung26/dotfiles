#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$PATH:/usr/bin"

# export PS1='\[\e[0;36m\][\u@\h]:\w\$ \[\e[0m\]'
export PS1='\[\e[0;36m\][\u@\h \W]\$ \[\e[0m\]'
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
if [[ $- == *i* ]] && [[ -f ~/.local/share/blesh/ble.sh ]]; then
  source ~/.local/share/blesh/ble.sh
fi

ble-face auto_complete='fg=242' # ,bg=235'

export GPG_TTY=$(tty)
