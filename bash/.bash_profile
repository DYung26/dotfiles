#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
# Add .NET Core SDK tools
export PATH="$PATH:/home/dyung/.dotnet/tools"
# Add Go binaries
export PATH="$PATH:$HOME/go/bin"

. "$HOME/.local/bin/env"


# Added by Antigravity CLI installer
export PATH="/home/dyung/.local/bin:$PATH"
