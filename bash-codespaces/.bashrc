# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# bash theme - partly inspired by https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
__bash_prompt() {
    local userpart='`export XIT=$? \
        && [ ! -z "${GITHUB_USER:-}" ] && echo -n "\[\033[0;32m\]@${GITHUB_USER:-} " || echo -n "\[\033[0;32m\]\u " \
        && [ "$XIT" -ne "0" ] && echo -n "\[\033[1;31m\]➜" || echo -n "\[\033[0m\]➜"`'
    local gitbranch='`\
        if [ "$(git config --get devcontainers-theme.hide-status 2>/dev/null)" != 1 ] && [ "$(git config --get codespaces-theme.hide-status 2>/dev/null)" != 1 ]; then \
            export BRANCH="$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)"; \
            if [ "${BRANCH:-}" != "" ]; then \
                echo -n "\[\033[0;36m\](\[\033[1;31m\]${BRANCH:-}" \
                && if [ "$(git config --get devcontainers-theme.show-dirty 2>/dev/null)" = 1 ] && \
                    git --no-optional-locks ls-files --error-unmatch -m --directory --no-empty-directory -o --exclude-standard ":/*" > /dev/null 2>&1; then \
                        echo -n " \[\033[1;33m\]✗"; \
                fi \
                && echo -n "\[\033[0;36m\]) "; \
            fi; \
        fi`'
    local lightblue='\[\033[1;34m\]'
    local removecolor='\[\033[0m\]'
    PS1="${userpart} ${lightblue}\w ${gitbranch}${removecolor}\$ "
    unset -f __bash_prompt
}
__bash_prompt
export PROMPT_DIRTRIM=4

# Check if the terminal is xterm
if [[ "$TERM" == "xterm" ]]; then
    # Function to set the terminal title to the current command
    preexec() {
        local cmd="${BASH_COMMAND}"
        echo -ne "\033]0;${USER}@${HOSTNAME}: ${cmd}\007"
    }

    # Function to reset the terminal title to the shell type after the command is executed
    precmd() {
        echo -ne "\033]0;${USER}@${HOSTNAME}: ${SHELL}\007"
    }

    # Trap DEBUG signal to call preexec before each command
    trap 'preexec' DEBUG

    # Append to PROMPT_COMMAND to call precmd before displaying the prompt
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }precmd"
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Redundant safety net: post-create.sh already sets this system-wide in
# /etc/bash.bashrc, but export it here too in case this file ever takes
# precedence (e.g. stowed directly to ~/.bashrc) without post-create.sh
# having run first.
export LANG=C.UTF-8

run_cpp_script() {
    g++ -x c++ -o /tmp/temp.out "$1" -lcurl -ljsoncpp && /tmp/temp.out && rm /tmp/temp.out
}

export GPG_TTY=$(tty)

unset GITHUB_TOKEN

# pnpm
export PNPM_HOME="/home/codespace/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

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

rmtmp() {
    local count

    count=$(find . -type f -name ".syncthing.*.tmp" | wc -l)

    if [ "$count" -eq 0 ]; then
        echo "No syncthing tmp files found."
        return 0
    fi

    echo "Found $count syncthing tmp file(s):"
    find . -type f -name ".syncthing.*.tmp"
    echo

    read -rp "Delete them? [y/N] " confirm

    [[ "$confirm" =~ ^([yY]|yes|YES|Yes)$ ]] || {
        echo "Aborted."
        return 1
    }

    find . -type f -name ".syncthing.*.tmp" -exec rm -fv {} \;
}
