# CONFIG

# Make bash append rather than overwrite the history on disk
shopt -s histappend

# Whenever displaying the prompt, write the previous line to disk
export PROMPT_COMMAND="history -a"

# If `PAGER` is changed (e.g. back to `least`), make sure to set `DELTA_PAGER`
# to `less` to keep [git-]delta's navigation feature working:
# https://dandavison.github.io/delta/navigation-keybindings-for-large-diffs.html
export PAGER='less'
export LESS='-FR'

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

# Run command with low cpu and disk priority.
alias vnice='nice ionice -c 2 -n 7'
# Run command headless & with low cpu and disk priority.
alias xvnice='vnice xvfb-run -a -s "-screen 0 1024x768x24"'

time10() {
  times=10
  start_time=$(date +%s.%N)
  for ((i=0; i < times; i++)) ; do
      "$@" &> /dev/null
  done
  end_time=$(date +%s.%N)
  echo -n "Real time, avg of ${times} runs: "
  bc -l <<< "($end_time - $start_time) / $times"
}

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
            grep -iP --color=never "$@" | \
                q="$arg" perl -pe "s/\$ENV{q}/$(tput smso)\$&$(tput rmso)/gi"
        else
            grep -P --color=never "$@" | \
                q="$arg" perl -pe "s/\$ENV{q}/$(tput smso)\$&$(tput rmso)/g"
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

# Destructuring assignment for bash arrays.
destructure() {
    (($# >= 3 && $# % 2 == 1)) && [[ ${@:1 + $# / 2:1} == "=" ]] || {
        echo 'USAGE: destructure k1 k2 _ k3 ... = "${arr[@]}"' >&2
        return 1
    }
    for ((i = 1, j = 2 + $# / 2; i <= $# / 2; i++, j++)); do
        local -n key="${!i}"
        key="${!j}"
    done
}

# Similar to less but with syntax highlighting provided by vim.
vless() {
    $(vim -e -T dumb --cmd 'exe "set t_cm=\<C-M>"|echo $VIMRUNTIME|quit' | tr -d '\015')/macros/less.sh "$@"
}

# Add -A <your-project-id> to override
alias gae-up='appcfg.py --oauth2 update .'

tick_emoji="✔️"
cross_emoji="❌"

# Show desktop notification with exit status when long running command finishes.
# Usage:
#   sleep 10; donealert
#alias donealert='notify-send --urgency=low -i "$([ $? = 0 ] && echo "${tick_emoji}" || echo "${cross_emoji}")" "$(history 1|sed -E '\''s/^\s*[0-9]+\s*//;s/\[[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\s\+[0-9]{4}\]\s+//;s/[;&|]\s*donealert$//'\'')"'
alias donealert='notify-send --urgency=low -i "$([ $? = 0 ] && echo "${tick_emoji}" || echo "${cross_emoji}")" "$(fc -ln -1|sed -E '\''1 s/^\s+//;s/[;&|]\s*donealert$//'\'')"'

# Ping yourself a chat message with exit status when long running command
# finishes. Requires `chatme` on your PATH.
# Usage:
#   sleep 10; donechat
#alias donechat='chatme "$([ $? = 0 ] && echo "${tick_emoji}" || echo "${cross_emoji}")" "$(history 1|sed -E '\''s/^\s*[0-9]+\s*//;s/\[[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\s\+[0-9]{4}\]\s+//;s/[;&|]\s*donechat$//'\'')"'
alias donechat='chatme "$([ $? = 0 ] && echo "${tick_emoji}" || echo "${cross_emoji}")" "$(fc -ln -1|sed -E '\''1 s/^\s+//;s/[;&|]\s*donechat$//'\'')"'


# Ping yourself a chat message with stdout+stderr, only if the wrapped command
# fails. Requires `chatme` on your PATH.
# Usage:
#   chatmon sleep 10
# chatmon() {
#     tmpfile=$(mktemp --tmpdir chatmon-err.XXXXXXXXXX)
#     trap "{ rm -f '$tmpfile'; }" EXIT
#     tmpfifo=$(mktemp -u --tmpdir chatmon-fifo.XXXXXXXXXX)
#     mkfifo -m 600 "$tmpfifo"
#     trap "{ rm -f '$tmpfifo'; }" EXIT
#     # This variant sends only stderr. Unfortunately the added latency
#     # causes stdout and stderr to display out of sync.
#     "$@" 2> >(tee "$tmpfile"; : >"$tmpfifo")
#     ret=$?
#     read <"$tmpfifo"  # Wait for tee to finish.
#     if (($ret != 0)); then
#         cat <(echo -e "Failed: $*\n") $tmpfile | chatme
#     fi
# }
chatmon() {(
    set -o pipefail
    if [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]]; then
        echo "USAGE: ${FUNCNAME[0]} some_command and its arguments"
        return
    fi
    tmpfile=$(mktemp --tmpdir chatmon.XXXXXXXXXX)
    trap "{ rm -f '$tmpfile'; }" EXIT
    "$@" |& tee "$tmpfile" || {
        ret=$?
        cat <(echo -e "Failed: $*\n") $tmpfile | chatme
        return $ret
    }
)}


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

export PS1='\[${__ansi_green_and_red[$? != 0]}\]$(dayname-2chars)|$(date +%H:%M)\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\]\[\e[1;35m\]$(__git_ps1 " (%s)")\[\e[0m\]\$ '


# GIT

__source_relative git-completion.bash

# Allow overriding git config from an environment variable.
# USAGE: git_config_overrides='-c foo=bar -c baz=qux' git <command>
# Spaces are not supported in keys/values!
git() { command git $git_config_overrides "$@"; }

alias gst='git status'
alias gds='git diff -M --stat'
alias gdm='git diff -M $(g-main)'
alias gddm='gdd $(g-main)'
# Added author and relative date to oneline format (unfortunately this
# means ref names are all colored red instead of their correct colors.
alias glog='git log --format="%C(yellow)%h%Creset%C(red bold)%d %C(bold blue)%an:%Creset%Creset %s %Cgreen(%cr)%Creset"'
alias glog-graph='glog --graph --date-order'  # Slow
alias gca='git commit --amend --no-edit'
alias gcm='git checkout $(g-main)'
alias gc-='git checkout -'
alias gdc='git diff -M --cached'
alias gcp='git cherry-pick'
alias gsh='git show'
alias gshs='git show --stat=$COLUMNS --stat-graph-width=$(($COLUMNS/5))'

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

# Prints name of the (main/master) local branch that is tracking origin/HEAD.
#
# If multiple local branches are pulling directly from origin/HEAD, this will
# print the one with the most recent commit, but that is obviously brittle.
#
# Note that the origin/HEAD of the local repository is set when it is cloned and
# won't automatically update if the remote repository changes its HEAD branch.
# Use `git remote set-head origin --auto` to update origin/HEAD in this case. Or
# to take this into account one could run `git remote show origin` but that
# takes almost half a second. Its output would contain the name of the remote
# HEAD:
# > HEAD branch: master
# and a list of local branches that track and push from/to each remote branch:
# > Local branch configured for 'git pull':
# >   master merges with remote master
# > Local ref configured for 'git push':
# >   master pushes to master (up to date)`

g-main() {
    git for-each-ref --format='%(refname:short) <- %(upstream:short)' refs/heads --sort=-committerdate | grep -E " <- $(git rev-parse --abbrev-ref origin/HEAD)$" | { read -r first _; echo $first; }
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

g-is-branch() {
    git show-ref --quiet --verify -- "refs/heads/$1"
}
complete -o default -o nospace -F _complete_git_heads g-is-branch

# Prints upstream branch of $1 or $(g-current-branch).
gu() {
    git rev-parse --abbrev-ref "$1@{u}"
}
complete -o default -o nospace -F _complete_git_heads gu

# Prints sha1 at which branch $1 - or the current branch if empty - forked from
# its upstream branch. Falls back to merge-base (with warning) if reflog doesn't
# go back far enough.
g-upstream-fork-point() {
    git merge-base --fork-point "$1"@{u} "${1:-HEAD}" && return
    echo "Warning: could not find fork-point." >&2
    git merge-base "$1"@{u} "${1:-HEAD}"
}

glu() {
    # If first parameter is an argument to glog, assume we're operating on HEAD.
    if [[ -z "$1" || "$1" == -* ]]; then
        set -- HEAD "$@"
    fi
    glog $(g-upstream-fork-point "$1").."$1" "${@:2}"
}
complete -o default -o nospace -F _complete_git_heads glu

gru() {
    git rebase -i $(g-upstream-fork-point) "$@"
}

alias grr='git rebase -i --root'

gdu() {
    # TODO: "gdu --stat topic" will fail. Only "gdu topic --stat" works. Need
    # better argument parsing.
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        # Doesn't include uncommited changes, or use fork-point.
        #git diff @{u}...
        # Includes uncommitted changes, but not new untracked files.
        git diff -M $(g-upstream-fork-point) "$@"
    else
        git diff -M $(g-upstream-fork-point "$1") "$1" "${@:2}"
    fi
}
complete -o default -o nospace -F _complete_git_heads gdu

gdus() {
    gdu "$@" --stat=$COLUMNS --stat-graph-width=$(($COLUMNS/5))
}
complete -o default -o nospace -F _complete_git_heads gdus

gdd() {
    git difftool --dir-diff "$@" &
}
complete -o default -o nospace -F _complete_git_refs gdd

gddc() {
    gdd "$@" --cached
}
complete -o default -o nospace -F _complete_git_refs gddc

gddh() {
    # If first parameter is empty or a param, assume we're operating on HEAD.
    if [[ -z "$1" || "$1" == -* ]]; then
        set -- HEAD "$@"
    fi
    gdd "$1"^ "$1" "${@:2}"
}
complete -o default -o nospace -F _complete_git_refs gddh

gddu() {
    # TODO: "gddu --cached topic" will fail. Only "gddu topic --cached" works.
    # Need better argument parsing.
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        # Includes uncommitted changes, but not new untracked files.
        gdd $(g-upstream-fork-point) "$@"
    else
        gdd $(g-upstream-fork-point "$1") "$1" "${@:2}"
    fi
}
complete -o default -o nospace -F _complete_git_heads gddu

# Increasing this shows behind count for older branches, instead of ????, but
# slows down `aheadbehind`.
__AHEADBEHIND_MAX_BEHIND=1000

# Alternative to `git rev-list --left-right --count $1...$1@{u}`. Much faster
# for branches that are very far behind, for which it prints ???? instead of
# calculating the exact count. Counts may be approximate if a lot of merging has
# happened.
aheadbehind() {
    local ahead=$(git rev-list "$1@{u}..$1" | wc -l)
    local behind=$(
        git rev-list -$__AHEADBEHIND_MAX_BEHIND "$1@{u}" |
        grep -Fv -f <(git rev-list -$(($__AHEADBEHIND_MAX_BEHIND + $ahead)) "$1") |
        wc -l)

    if (( $ahead > 0 )); then
        printf "+$ahead"
    fi
    if (( $behind > 0 )); then
        (( $behind == $__AHEADBEHIND_MAX_BEHIND )) && printf -- "-????" || printf -- "-$behind"
    fi
}
# Like `git branch -vv`, but sorted in date order, and much faster but only
# approximate ahead/behind counts if some branches are very old.
# See also http://stackoverflow.com/questions/5188320/how-can-i-get-a-list-of-git-branches-ordered-by-most-recent-commit
gbv() {
    # Using cat runs subcommands in parallel, which is 10x faster than serial.
    local lines=$(git for-each-ref --shell --sort=committerdate refs/heads --format='<(echo -n %(committerdate:short) %(objectname:short) %(HEAD) %(refname:short) [%(color:blue)%(upstream:short)%(color:reset)) <(aheadbehind %(refname:short)) <(echo "]" %(contents:subject))')
    eval cat "${lines//$'\n'/ }"
}
gbvv() {
    __AHEADBEHIND_MAX_BEHIND=10000 gbv "$@"
}

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

g-continue() {
    if [[ -e $(git rev-parse --git-dir)/CHERRY_PICK_HEAD ]]; then
        git cherry-pick --continue
    elif [[ -e $(git rev-parse --git-dir)/REVERT_HEAD ]]; then
        git revert --continue
    elif [[ -d $(git rev-parse --git-dir)/rebase-merge || -d $(git rev-parse --git-dir)/rebase-apply ]]; then
        grc
    else
        echo "No rebase, cherry-pick or revert in progress!" >&2
        return 69  # Custom exit code so g-merge-loop can distinguish this case.
    fi
}

# Runs `git mergetool || g-continue` until merge conflicts are resolved.
g-merge-loop() {
    for ((i = 0; i < 1000; i++)); do
        git mergetool || return 1
        g-continue && return 0
        if (($? == 69)); then return 69; fi
    done
    echo "${FUNCNAME[0]} giving up after 1000 iterations :-(" >&2
    return 1
}

# Faster `git checkout child_branch && { git rebase || g-merge-loop; }`,
# but won't checkout the branch if rebase is unnecessary.
_gch_rebase_if_necessary() {
    if (( $# != 1 )); then
        echo "Usage: ${FUNCNAME[0]} child_branch"
        return 1
    fi
    if [[ $(git merge-base "$1" "$1"@{u}) == $(git rev-parse "$1"@{u}) ]]; then
        # Already up to date.
        return 0
    fi
    echo "Previous tip of \"$1\" was $(git rev-parse "$1")"
    # Equivalent to: git rebase --onto "$1"@{u} \
    #                "$(g-upstream-fork-point "$1")" \
    #                "$1" || g-merge-loop
    git rebase --fork-point "$1"@{u} "$1" || g-merge-loop
}
complete -o default -o nospace -F _complete_git_heads _gch_rebase_if_necessary

# Faster `git checkout child_branch && { git rebase || g-merge-loop; }`.
gch-rebase() {
    if (( $# != 1 )); then
        echo "Usage: ${FUNCNAME[0]} child_branch"
        return 1
    fi
    _gch_rebase_if_necessary "$1"
    if [[ $(g-current-head) != $1 ]]; then
        git checkout "$1"
    fi
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
    (
        # Split unquoted $ancestors at linebreaks without globbing. Don't use while read
        # since that prevents git mergetool etc from getting input from stdin.
        IFS=$'\n'
        set -o noglob
        for branch in $ancestors; do
            # This works because _gch_rebase_if_necessary uses --fork-point.
            _gch_rebase_if_necessary "$branch" || return 1
        done
        if [[ $(g-current-head) != $1 ]]; then
            git checkout "$1"
        fi
    )
}
complete -o default -o nospace -F _complete_git_heads gch-rebase-ancestors

gch() {
    if (( $# == 1 )) && g-is-branch "$1"; then
        gch-rebase-ancestors "$1"  # It's almost as fast as git checkout!
    else
        git checkout "$@"
    fi
}
complete -o default -o nospace -F _complete_git_heads gch

# Print the given or current branch name, preceded by all non-master local
# branches it depends on.
g-ancestors() {
    local branch; branch="${1:-$(g-current-branch)}" || return 1
    local main; main="$(g-main)" || return 1
    declare -a branches
    while true; do
        branches=("$branch" "${branches[@]}")  # Prepend
        branch="$(gu "$branch")" || return 1
        [[ $branch == "$main" || $branch == */* ]] && break
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

    echo "Previous tip of \"$child_branch\" was $(git rev-parse "$child_branch")"

    local old_parent_branch; old_parent_branch="$(gu "$child_branch")" || return 1
    local ret=0
    if ! { git rebase --fork-point --onto "$new_parent_branch" "$old_parent_branch" "$child_branch" || g-merge-loop; }; then
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

# Posted to http://stackoverflow.com/a/36463546/691281.
g-fork-off-n() {
    if [[ $# != 2 || ! $1 =~ ^[0-9]+$ ]]; then
        echo "USAGE: $FUNCNAME <num_commits> <new_branch>" >&2
        return 1
    fi
    git reset --keep HEAD~$1 && git checkout -t -b "$2" && git cherry-pick ..HEAD@{2}
}

# USAGE: git-cherry-contains <commit>
# Prints each local branch containing an equivalent commit.
# Posted to http://stackoverflow.com/a/31158368/691281.
git-cherry-contains() {
    local sha; sha=$(git rev-parse --verify "$1") || return 1
    local branch
    while IFS= read -r branch; do
        if ! git cherry "$branch" "$sha" "$sha^" | grep -qE "^\+ $sha"; then
            echo "$branch"
        fi
    done < <(git for-each-ref --format='%(refname:short)' refs/heads/)
}

# To search without replacing:
# git grep [--no-index] [-i] -nP <regex> [-- '*.ext' ['*.ext']* ]

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
    local regex
    local repl
    # Escape $ & @ for perl. Use %s so printf doesn't expand escapes like \b.
    regex=$(printf "%s" "$1" | sed 's/[@$]/\\&/g')
    repl=$(printf "%s" "$2" | sed 's/[@$]/\\&/g')
    local file
    git grep $noindex $grepignorecase -lP "$1" | while IFS= read -r file || [[ -n $file ]]; do
        # Cygwin and MSYS don't support perl -i without backup :-|
        perl -wi.gitreplacebak -pe "s%$regex%$repl%g$perlignorecase" "$file" &&
        rm "$file.gitreplacebak"
    done
}

raw-replace() {
    git-replace --no-index "$@"
}

# Adds intra-line diffs to git diff output. More robust than --color-words.
# USAGE: wd git diff
wd() {
    local diff_highlight
    if [[ -e /usr/share/git/diff-highlight/diff-highlight ]]; then
        diff_highlight=(perl /usr/share/git/diff-highlight/diff-highlight)
    elif [[ -e /usr/share/doc/git/contrib/diff-highlight/diff-highlight ]]; then
        diff_highlight=(perl /usr/share/doc/git/contrib/diff-highlight/diff-highlight)
    elif [[ -e /usr/share/doc/git/contrib/diff-highlight/diff-highlight.perl ]]; then
        diff_highlight=(perl /usr/share/doc/git/contrib/diff-highlight/diff-highlight.perl)
    else
        diff_highlight=(cat)
    fi
    # eval quoted printf trick so aliases get expanded properly in "$@"
    # (http://stackoverflow.com/a/3179059/691281).
    eval $(printf "%q " git_config_overrides="-c color.ui=always" "$@") | "${diff_highlight[@]}"
}

# Published to http://stackoverflow.com/a/12179492/691281
# (without the -v argument, for verbose mode)
# TODO: Doesn't handle 3-way merge diffs.
diff-lines() {
    local esc=$'\e'
    local ansi=$'\e\\[[0-9;]*m'
    local REPLY=
    local path=
    local line=
    # For each line in stdin...
    while IFS= read -r || [[ -n $REPLY ]]; do
        # ...match the start of the line, ignoring leading ANSI escapes.
        if [[ $REPLY =~ ^($ansi)*---\ (a/)?.* ]]; then
            if [[ $1 == -v ]]; then if [[ -n $path ]]; then echo; fi; echo "$REPLY"; fi
            continue
        elif [[ $REPLY =~ ^($ansi)*\+\+\+\ (b/)?([^[:blank:]$esc]+).* ]]; then
            if [[ $1 == -v ]]; then echo "$REPLY"; fi
            path=${BASH_REMATCH[3]}
        elif [[ $REPLY =~ ^($ansi)*@@\ -[0-9]+(,[0-9]+)?\ \+([0-9]+)(,[0-9]+)?\ @@.* ]]; then
            if [[ $1 == -v ]]; then echo "$REPLY"; fi
            line=${BASH_REMATCH[3]}
        elif [[ $REPLY =~ ^($ansi)*([\ +-\\]) ]]; then
            echo "$path:$line:$REPLY"
            if [[ ${BASH_REMATCH[2]} =~ [\ +] ]]; then
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

# e.g. to delete all added lines containing FOO: git diff | dr '.*FOO.*\n' ''
diff-replace() {
    if (( $# != 2 )); then
        echo 'USAGE: git diff | diff-replace "(hello.*)world" "\1universe"'
        return 1
    fi
    # Escape $ & @ for perl. Use %s so printf doesn't expand escapes like \b.
    regex=$(printf "%s" "$1" | sed 's/[@$]/\\&/g')
    repl=$(printf "%s" "$2" | sed 's/[@$]/\\&/g')
    local REPLY
    strip-ansi | diff-lines | tac | while IFS= read -r || [[ -n $REPLY ]]; do
        if [[ $REPLY =~ ^([^:]+):([0-9]+):\+ ]]; then
            local file_path=${BASH_REMATCH[1]}
            local file_line=${BASH_REMATCH[2]}
            # TODO: Should call perl once per file, not once per added line!
            perl -wi -pe "s%$regex%$repl%g if \$. == $file_line" "$file_path"
        fi
    done
}
alias dr='diff-replace'


# PROCESS TREES

pt() { pstree -h -U -T -l -Cage "$USER" "$@" | $PAGER; }
pta() { pstree -h -U -T -l -Cage --arguments "$USER" "$@" | $PAGER; }
ptp() { pstree -h -U -T -l -Cage -p -g "$USER" "$@" | $PAGER; }
ptpa() { pstree -h -U -T -l -Cage -p -g --arguments "$USER" "$@" | $PAGER; }


# DISABLE FLOW CONTROL SO CTRL+S CAN SEARCH FORWARDS THROUGH SHELL HISTORY

# https://superuser.com/a/1067896
stty -ixon


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
if [[ $(uname -r) =~ [Mm]icrosoft ]]; then
    true  # Put WSL customizations here.
fi


# ALIAS COMPLETION

__source_relative alias_completion.bash
