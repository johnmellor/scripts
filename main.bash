# CONFIG

# Make bash append rather than overwrite the history on disk
shopt -s histappend

# Whenever displaying the prompt, write the previous line to disk
export PROMPT_COMMAND="history -a"

export PAGER='least'
export EDITOR='subl --wait'


# MISC

# Default to human readable figures
alias df='df -h'
alias du='du -h'

# Show differences in colour
#alias grep='grep --color'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

if ls --color=auto &> /dev/null; then
    alias l='ls -hF --color=auto'
    alias la='ls -AhF --color=auto'
    alias ll='ls -lhF --color=auto'
else
    # OS X (and BSD) don't support --color; set CLICOLOR instead.
    export CLICOLOR=1
    alias l='ls -hF'
    alias la='ls -AhF'
    alias ll='ls -lhF'
fi

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

# Pipe to this, to show output in $PAGER when appropriate.
pager-if-tty() {
    if [[ -t 1 ]]; then
        # stdout is a terminal
        ${PAGER-less}
    else
        # stdout is not a terminal
        cat
    fi
}

# Add -A <your-project-id> to override
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

__ansi_green_and_red=("$(echo $'\e[1;32m')" "$(echo $'\e[1;31m')")

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

# Prints name of current branch, or if HEAD is detached this
# prints "fatal: ref HEAD is not a symbolic ref" to stderr.
g-current-branch() {
    git symbolic-ref --short HEAD
}

# Prints name of current branch, or commit hash if HEAD is detached.
g-current-head() {
    g-current-branch 2> /dev/null || git rev-parse HEAD
}

# Prints upstream branch of $1 or $(g-current-branch).
gu() {
    local from; from="${1:-$(g-current-branch)}" &&
    git rev-parse --abbrev-ref "$from@{upstream}"
}
complete -o default -o nospace -F _complete_git_heads gu

alias gst='git status'
alias gbv='git branch -vv'
alias gds='git diff --stat'
alias gdu='git diff @{upstream}'
alias gdus='git diff --stat @{upstream}'
# Added author and relative date to oneline format (unfortunately this
# means ref names are all colored red instead of their correct colors.
alias glog='git log --graph --date-order --format="%C(yellow)%h%Creset%C(red bold)%d %C(bold blue)%an:%Creset%Creset %s %Cgreen(%cr)"'
alias gch='git checkout'
alias gcm='git checkout master'
alias gdc='git diff --cached'
alias gru='git rebase -i @{upstream}'

glu() {
    # If $1 is empty, this will act on the current branch.
    glog "$1"@{upstream}.."$1"
}
complete -o default -o nospace -F _complete_git_heads glu

gdl() {
    git diff -M --color "$@" | diff-lines -v | pager-if-tty
}
complete -o default -o nospace -F _complete_git_refs gdl

# If a merge conflict is resolved by rejecting all changes from a patch,
# `git rebase --continue` will complain as follows:
#    "No changes - did you forget to use 'git add'?
#     If there is nothing left to stage, chances are that something else
#     already introduced the same changes; you might want to skip this patch."
# grc detects this case, and runs `git rebase --skip` instead.
grc() {
    if git diff --quiet && git diff --cached --quiet; then
        # There were no unstaged or staged changes, so skip this patch.
        git rebase --skip
    else
        git rebase --continue
    fi
}

# Runs `git mergetool || grc` until merge conflicts are resolved.
grc-merge-loop() {
    for ((i = 0; i < 1000; i++)); do
        git mergetool || return 1
        grc && return 0
    done
    echo "${FUNCNAME[0]} giving up after 1000 iterations :-(" >&2
    return 1
}

# Faster equivalent to `gch child_branch && { git rebase || grc-merge-loop; }`.
gch-rebase() {
    if (( $# != 1 )); then
        echo "Usage: ${FUNCNAME[0]} child_branch"
        return 1
    fi
    # Equivalent to: git rebase --onto "$1@{upstream}" "$(git merge-base --fork-point "$1@{upstream}" "$1")" "$1" || grc-merge-loop
    git rebase --fork-point "$1@{upstream}" "$1" || grc-merge-loop
}
complete -o default -o nospace -F _complete_git_heads gch-rebase

# Checkout a branch, after rebasing it and all its ancestors.
gch-rebase-ancestors() {
    if (( $# != 1 )); then
        echo "Usage: ${FUNCNAME[0]} grandchild_branch"
        return 1
    fi
    local ancestors; ancestors=$(g-ancestors "$1") || return 1
    local branch
    while IFS= read -r branch || [[ -n $branch ]]; do
        # This works because gch-rebase uses --fork-point.
        gch-rebase "$branch" || return 1
    done <<< "$ancestors"
}
complete -o default -o nospace -F _complete_git_heads gch-rebase-ancestors

# Print the given or current branch name, preceded by all non-master local
# branches it depends on.
g-ancestors() {
    local branch; branch="${1:-$(g-current-branch)}" || return 1
    declare -a branches
    while true; do
        branches=("$branch" "${branches[@]}")  # Prepend
        branch="$(gu "$branch")" || return 1
        [[ $branch == "master" || $branch == */* ]] && break
    done
    for b in "${branches[@]}"; do
        echo "$b"
    done
}
complete -o default -o nospace -F _complete_git_heads g-ancestors

# Use case: B's upstream is A_old, and you want to rebase B so it tracks A_new instead.
# Then run g-rebase-set-upstream B A_new
g-rebase-set-upstream() {
    if (( $# < 1 || $# > 2 )); then
        echo "Usage: ${FUNCNAME[0]} [child_branch] new_parent_branch"
        return 1
    fi

    if (( $# == 2 )); then
        local child_branch="$1"
        shift
    else
        local child_branch; child_branch="$(g-current-branch)" || return 1
    fi
    local new_parent_branch="$1"
    shift

    local old_parent_branch; old_parent_branch="$(gu "$child_branch")" || return 1
    local ret=0
    if ! git rebase --onto "$new_parent_branch" "$old_parent_branch" "$child_branch"; then
        ret=1
    fi
    # Set the new upstream even if there is a rebase conflict. Otherwise it's
    # easy to forget to do so after resolving the conflict.
    if ! git branch --set-upstream-to="$new_parent_branch" "$child_branch"; then
        ret=1
    fi
    return $ret
}
complete -o default -o nospace -F _complete_git_heads g-rebase-set-upstream

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
    local file
    git grep $noindex $grepignorecase -lP "$1" | while IFS= read -r file || [[ -n $file ]]; do
        # Cygwin and MSYS don't support perl -i without backup :-|
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
    local REPLY
    while IFS= read -r || [[ -n $REPLY ]]; do
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
    local REPLY
    strip-ansi | diff-lines | tac | while IFS= read -r || [[ -n $REPLY ]]; do
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
