# HELPERS

__scripts_directory="${BASH_SOURCE%/*}"
__source_relative() {
    # source a path relative to the location of this script
    source "${__scripts_directory}/$1"
}


# PROMPT

__source_relative git-prompt.sh

# Show if there are unstaged (*) and/or staged (+) changes
export GIT_PS1_SHOWDIRTYSTATE=1

# Show if there is anything stashed ($)
#export GIT_PS1_SHOWSTASHSTATE=1

# Show if there are untracked files (%)
export GIT_PS1_SHOWUNTRACKEDFILES=1

# Show how we're tracking relative to upstream
export GIT_PS1_SHOWUPSTREAM="verbose"

export PS1="\[\e[33m$(tput bold)\]\w\[\e[0m\]$(__git_ps1 ' (%s)')$ "


# GIT

__source_relative git-completion.bash


# MISC

alias l='ls -hF --color=auto'
alias la='ls -AhF --color=auto'
alias ll='ls -lhF --color=auto'


# GIT

alias gst='git status'
alias gbv='git branch -vv'


# ALIAS COMPLETION

__source_relative alias_completion.bash
