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
alias gh-26='GH_CONFIG_DIR=~/.config/gh-dyung26 gh'
alias gh-06='GH_CONFIG_DIR=~/.config/gh-dyung06 gh'
alias gh-df='GH_CONFIG_DIR=~/.config/gh-dyungfirm gh'
alias gh-odo='GH_CONFIG_DIR=~/.config/gh-oyedanolu gh'
alias gh-do='GH_CONFIG_DIR=~/.config/gh-danieloyekunle gh'
PS1='[\u@\h \W]\$ '

rmconflicts() {
    local count

    count=$(find . -type f -name "*.sync-conflict-*" | wc -l)

    if [ "$count" -eq 0 ]; then
        echo "No sync-conflict files found."
        return 0
    fi

    echo "Found $count sync-conflict file(s):"
    find . -type f -name "*.sync-conflict-*"
    echo

    read -rp "Delete them? [y/N] " confirm

    [[ "$confirm" =~ ^([yY]|yes|YES|Yes)$ ]] || {
        echo "Aborted."
        return 1
    }

    find . -type f -name "*.sync-conflict-*" -exec rm -fv {} \;
}

restoreconflicts() {
    local all=false opt count original conflict confirm

    while getopts "a" opt; do
        case "$opt" in
            a) all=true ;;
            *) echo "Usage: restoreconflicts [-a]"; return 1 ;;
        esac
    done

    local conflicts=()
    mapfile -t conflicts < <(find . -type f -name "*.sync-conflict-*")

    count=${#conflicts[@]}

    if [ "$count" -eq 0 ]; then
        echo "No sync-conflict files found."
        return 0
    fi

    echo "Found $count sync-conflict file(s):"
    printf '%s\n' "${conflicts[@]}"
    echo

    if [ "$all" = false ]; then
        read -rp "Review and restore them? [y/N] " confirm
        [[ "$confirm" =~ ^([yY]|yes|YES|Yes)$ ]] || {
            echo "Aborted."
            return 1
        }
    fi

    local backup_dir
    backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/restoreconflicts-backup-XXXXXX")
    local restored_originals=() restored_conflicts=() restored_had_original=()
    local restored=0

    for conflict in "${conflicts[@]}"; do
        original=$(echo "$conflict" | sed -E 's/\.sync-conflict-[0-9]{8}-[0-9]{6}-[A-Z0-9]{7}//')

        if [ "$all" = false ]; then
            if [ -f "$original" ]; then
                echo "--- $original"
                echo "+++ $conflict"
                git --no-pager diff --no-index --color --ignore-cr-at-eol -- "$original" "$conflict"
                echo
                read -rp "Restore $conflict into $original? [y/N] " confirm
            else
                echo "No matching original found for $conflict (expected: $original)"
                read -rp "Restore it as $original anyway? [y/N] " confirm
            fi

            [[ "$confirm" =~ ^([yY]|yes|YES|Yes)$ ]] || {
                echo "Skipped $conflict."
                continue
            }
        fi

        local backup_subdir="$backup_dir/$restored"
        mkdir -p "$backup_subdir"
        cp -f "$conflict" "$backup_subdir/conflict"
        if [ -f "$original" ]; then
            cp -f "$original" "$backup_subdir/original"
            restored_had_original+=(true)
        else
            restored_had_original+=(false)
        fi
        restored_originals+=("$original")
        restored_conflicts+=("$conflict")

        cp -fv "$conflict" "$original"
        rm -fv "$conflict"
        restored=$((restored + 1))
    done

    echo "Restored $restored file(s)."

    if [ "$restored" -eq 0 ]; then
        rm -rf "$backup_dir"
        return 0
    fi

    echo "Backups saved in $backup_dir"
    read -rp "Keep these changes, or revert them? [K/r] " confirm
    if [[ "$confirm" =~ ^([rR]|revert|REVERT|Revert)$ ]]; then
        local i
        for ((i = 0; i < restored; i++)); do
            original="${restored_originals[$i]}"
            conflict="${restored_conflicts[$i]}"
            if [ "${restored_had_original[$i]}" = true ]; then
                cp -fv "$backup_dir/$i/original" "$original"
            else
                rm -fv "$original"
            fi
            cp -fv "$backup_dir/$i/conflict" "$conflict"
        done
        echo "Reverted $restored file(s)."
    else
        echo "Changes kept."
    fi

    rm -rf "$backup_dir"
}

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
# export PS1='\[\e[0;36m\][\u@\h \W$(__git_ps1 " (%s)")]\[\e[0m\]\n\$ '
# export PS1=[\u@\h \W]\$

# Build PS1 dynamically each prompt: keep '$' on the same line unless the
# info line (user@host + dir + git status) reaches 3/4 of the current
# pane's width, in which case '$' moves to its own line instead of
# wrapping mid-line. tput cols reads the live pty, so this is correct
# per-pane in tmux even when panes are resized.
__ps1_update() {
    local git_status
    git_status=$(__git_ps1 " (%s)" 2>/dev/null)

    local plain_cwd="${PWD##*/}"
    [ -z "$plain_cwd" ] && plain_cwd="/"

    local info="[${USER}@${HOSTNAME%%.*} ${plain_cwd}${git_status}]"
    local cols
    cols=$(tput cols 2>/dev/null || echo "${COLUMNS:-80}")
    local threshold=$(( cols * 3 / 4 ))

    if [ "${#info}" -ge "$threshold" ]; then
        PS1='\[\e[0;36m\][\u@\h \W'"$git_status"']\[\e[0m\]\n\$ '
    else
        PS1='\[\e[0;36m\][\u@\h \W'"$git_status"']\[\e[0m\]\$ '
    fi
}
PROMPT_COMMAND="__ps1_update${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
export PS1

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


# Added by Antigravity CLI installer
export PATH="/home/dyung/.local/bin:$PATH"
