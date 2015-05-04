# HELPERS

__scripts_directory="${BASH_SOURCE%/*}"
__source_relative() {
    # source a path relative to the location of this script
    source "${__scripts_directory}/$1"
}


# MISC

alias l='ls -hF --color=auto'
alias la='ls -AhF --color=auto'
alias ll='ls -lhF --color=auto'


# GIT

alias gst='git status'
alias gbv='git branch -vv'


# ALIAS COMPLETION

__source_relative alias_completion.bash
