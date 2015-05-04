# CONFIG

# Make bash append rather than overwrite the history on disk
shopt -s histappend

# Whenever displaying the prompt, write the previous line to disk
export PROMPT_COMMAND="history -a"

export EDITOR='subl --wait'
export LESS='-FRX'


# MISC

# Default to human readable figures
alias df='df -h'
alias du='du -h'

# Show differences in colour
#alias grep='grep --color'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias l='ls -hF --color=auto'
alias la='ls -AhF --color=auto'
alias ll='ls -lhF --color=auto'

#alias lr='less -R'

alias gae-up='appcfg.py --oauth2 update .'


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

# TODO: These should be run only once.
git config --global push.default simple
git config --global merge.conflictstyle diff3

alias gst='git status'
alias gbv='git branch -vv'
alias gdu='git diff @{upstream}'
alias gdus='git diff --stat @{upstream}'
alias glog='git log --oneline'
alias gch='git checkout'
alias glu='glog @{upstream}...'
alias gcm='git checkout master'
alias gdc='git diff --cached'

git-replace() {
    if (( $# < 2 )); then
        echo "USAGE: git-replace [-i] <from_regex> <to_text>"
        return 1
    fi
    while [[ $1 == -i || $1 == --no-index ]]; do
        if [[ $1 == -i ]]; then
            local grepignorecase=-i
            local perlignorecase=i
            shift
        fi
        if [[ $1 == --no-index ]]; then
            local noindex=--no-index
            shift
        fi
    done
    # Cygwin and MSYS don't support perl -i without backup :-|
    git grep $noindex $grepignorecase -lP "$1" | while read file; do
        perl -i.gitreplacebak -pe "s%$1%$2%g$perlignorecase" "$file" &&
        rm "$file.gitreplacebak"
    done
}

raw-replace() {
    git-replace --no-index "$@"
}


# ALIAS CREATION

als() {
    sed -i "/^# <insert new aliases here>$/i alias $1='$2'" "${__scripts_directory}/main.bash"
    __source_relative main.bash
}

# <insert new aliases here>


# ALIAS COMPLETION

__source_relative alias_completion.bash
