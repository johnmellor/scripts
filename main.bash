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

strip-ansi() {
    # From http://unix.stackexchange.com/a/4529
    perl -pe 's/\e\[?.*?[\@-~]//g'
}

# Highlights matches within colorized text without stripping colors.
# Grep may still omit matches if there are color codes within the match itself.
color-safe-grep() {
    local ignore_case
    for arg; do
        if [[ $arg == -i ]]; then
            ignore_case=true
        fi
        if [[ $arg == -* ]]; then
            continue
        fi
        if [[ -n $ignore_case ]]; then
            grep -iP --color=never "$@" | perl -pe "s/$arg/$(tput smso)\$&$(tput rmso)/gi"
        else
            grep -P --color=never "$@" | perl -pe "s/$arg/$(tput smso)\$&$(tput rmso)/g"
        fi
        return $?
    done
}
alias highlight='color-safe-grep -C99999'

alias gae-up='appcfg.py --oauth2 update .'


# HELPERS

__scripts_directory="${BASH_SOURCE%/*}"
__source_relative() {
    # source a path relative to the location of this script
    source "${__scripts_directory}/$1"
}


# PROMPT

__source_relative git-prompt.sh

# Show if there are unstaged (*) and/or staged (+) changes.
# Disable this with `git config bash.showDirtyState false` in large slow repos.
export GIT_PS1_SHOWDIRTYSTATE=1

# Show if there is anything stashed ($); disabled as not useful.
#export GIT_PS1_SHOWSTASHSTATE=1

# Show if there are untracked files (%); disabled as slow.
#export GIT_PS1_SHOWUNTRACKEDFILES=1

# Show how we're tracking relative to upstream.
export GIT_PS1_SHOWUPSTREAM='verbose git legacy'

__ansi_green_and_red=("$(echo -e "\e[1;32m")" "$(echo -e "\e[1;31m")")

dayname-2chars() { local dayname=$(date +%a); echo ${dayname:0:2}; }

export PS1='\[${__ansi_green_and_red[$? != 0]}\]$(dayname-2chars)|$(date +%H:%M)\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\] \[\e[1;35m\]$(__git_ps1 "(%s)")\[\e[0m\]\$ '


# GIT

__source_relative git-completion.bash

# TODO: These should be run only once.
git config --global push.default simple
git config --global diff.tool meld
git config --global merge.tool p4merge
git config --global mergetool.keepBackup false
git config --global merge.conflictstyle diff3

# WARNING: Uses undocumented functions, so may break in future versions of git.
_complete_git_heads()
{
    local cur words cword prev; _get_comp_words_by_ref -n =: cur words cword prev;
    __gitcomp "$(__git_heads)"
}
_complete_git_refs() {
    local cur words cword prev; _get_comp_words_by_ref -n =: cur words cword prev;
    __gitcomp "$(__git_refs)"
}

alias gst='git status'
alias gbv='git branch -vv'
alias gdu='git diff @{upstream}'
alias gdus='git diff --stat @{upstream}'
alias glog='git log --oneline'
alias gch='git checkout'
alias glu='glog @{upstream}...'
alias gcm='git checkout master'
alias gdc='git diff --cached'
alias grc='git rebase --continue'

gdl() {
    git diff -M --color "$@" | diff-lines -v | less -FRX
}
complete -o default -o nospace -F _complete_git_refs gdl

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

# Published to http://stackoverflow.com/a/12179492/691281
# (without the -v argument, for verbose mode)
# TODO: Doesn't handle 3-way merge diffs.
diff-lines() {
    local path=
    local line=
    while read; do
        esc=$'\033'
        if [[ $REPLY =~ ---\ (a/)?.* ]]; then
            if [[ $1 == -v ]]; then if [[ -n $path ]]; then echo; fi; echo "$REPLY"; fi
            continue
        elif [[ $REPLY =~ \+\+\+\ (b/)?([^[:blank:]$esc]+).* ]]; then
            if [[ $1 == -v ]]; then echo "$REPLY"; fi
            path=${BASH_REMATCH[2]}
        elif [[ $REPLY =~ @@\ -[0-9]+(,[0-9]+)?\ \+([0-9]+)(,[0-9]+)?\ @@.* ]]; then
            if [[ $1 == -v ]]; then echo "$REPLY"; fi
            line=${BASH_REMATCH[2]}
        elif [[ $REPLY =~ ^($esc\[[0-9;]+m)*([\ +-]) ]]; then
            echo "$path:$line:$REPLY"
            if [[ ${BASH_REMATCH[2]} != - ]]; then
                ((line++))
            fi
        fi
    done
}
alias dl='diff-lines -v'

# Best combined with the following to make all your grep output colorized:
# git config --global color.ui always
diff-grep() { diff-lines -v | color-safe-grep "$@"; }
alias dg='diff-grep'

diff-replace() {
    if (( $# != 2 )); then
        echo 'USAGE: git diff | diff-replace "(hello.*)world" "\1universe"'
        return 1
    fi
    strip-ansi | diff-lines | tac | while read; do
        if [[ $REPLY =~ ^([^:]+):([0-9]+):\+ ]]; then
            local file_path=${BASH_REMATCH[1]}
            local file_line=${BASH_REMATCH[2]}
            perl -pi -e "s%$1%$2%g if \$. == $file_line" "$file_path"
        fi
    done
}
alias dr='diff-replace'


# ALIAS CREATION

als() {
    sed -i "/^# <insert new aliases here>$/i alias $1='$2'" "${__scripts_directory}/main.bash"
    __source_relative main.bash
}

# <insert new aliases here>


# PLATFORM-SPECIFIC

if [[ $OSTYPE == "cygwin" || $OSTYPE == "msys" ]]; then
    __source_relative windows.bash
fi


# ALIAS COMPLETION

__source_relative alias_completion.bash
