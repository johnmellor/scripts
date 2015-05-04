# CONFIG

# Make bash append rather than overwrite the history on disk
shopt -s histappend

# Whenever displaying the prompt, write the previous line to disk
export PROMPT_COMMAND="history -a"


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

export PS1='\[\e[1;34m\]\!\[\e[0m\] \[\e[1;35m\]\w\[\e[0m\] \[\e[1;92m\]$(__git_ps1 "(%s)")\[\e[0m\]\$ '


# GIT

__source_relative git-completion.bash


# MISC

export EDITOR='subl --wait'

alias l='ls -hF --color=auto'
alias la='ls -AhF --color=auto'
alias ll='ls -lhF --color=auto'


# GIT

alias gst='git status'
alias gbv='git branch -vv'


# ALIAS COMPLETION

__source_relative alias_completion.bash
