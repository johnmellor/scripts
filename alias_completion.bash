# Automatically add completion for all aliases to commands having completion functions
# Fork of https://superuser.com/revisions/437508/21
function alias_completion {
    local namespace="alias_completion"

    # parse function based completion definitions, where capture group 2 => function and 3 => trigger
    local compl_regex='complete( +[^ ]+)* -F ([^ ]+) ("[^"]+"|[^ ]+)'
    # parse alias definitions, where capture group 1 => trigger, 2 => command, 3 => command arguments
    local alias_regex="alias ([^=]+)='(\"[^\"]+\"|[^ ]+)(( +[^ ]+)*)'"

    # create array of function completion triggers, keeping multi-word triggers together
    eval "local completions=($(complete -p | sed -Ene "/$compl_regex/s//'\3'/p"))"
    (( ${#completions[@]} == 0 )) && return 0

    # create temporary file for wrapper functions and completions
    local tmp_file; tmp_file=$(mktemp 2>/dev/null || mktemp -t 'tmp') || return 1

    local completion_loader; completion_loader="$(complete -p -D 2>/dev/null | sed -Ene 's/.* -F ([^ ]*).*/\1/p')"

    # read in "<alias> '<aliased command>' '<command args>'" lines from defined aliases
    local line; while read line; do
        eval "local alias_tokens; alias_tokens=($line)" 2>/dev/null || continue # some alias arg patterns cause an eval parse error
        local alias_name="${alias_tokens[0]}" alias_cmd="${alias_tokens[1]}" alias_args="${alias_tokens[2]# }"

        # Skip aliases to pipes, boolean control structures and other command lists,
        # by leveraging that bash errs when unquoted metacharacters appear in an array
        # assignment (e.g. `x=(cmd1 | cmd2)` is a syntax error).
        #
        # We can't just `eval "x=($alias_args)"` because that would execute command
        # substitutions ($(), ``, and even <(), >()). Instead we escape $, (, ), `
        # and disable globbing (set -f), so eval parses without side effects.
        #
        # This also determines the word count for COMP_CWORD: each escaped $(...)
        # becomes a single literal word (e.g. `\$\(g-main\)`), which is correct for
        # quoted "$(cmd)" and for unquoted $(cmd) that expands to a single word.
        # Unquoted $(cmd) that expands to multiple words at runtime will have an
        # approximate count — a pre-existing limitation since the wrapper bakes in
        # a fixed COMP_CWORD offset regardless.
        #
        # Limitation: if unquoted $() contains metacharacters (e.g. `$(cmd | pipe)`),
        # escaping the parens exposes them to the top-level parser, falsely rejecting
        # the alias. This is acceptable since such aliases have unknowable word counts.
        local _safe="${alias_args//\$/\\\$}"
        _safe="${_safe//\(/\\(}"
        _safe="${_safe//\)/\\)}"
        _safe="${_safe//\`/\\\`}"
        local _had_noglob=0; [[ $- == *f* ]] && _had_noglob=1
        set -o noglob
        eval "local alias_arg_words; alias_arg_words=($_safe)" 2>/dev/null
        local _eval_ok=$?
        (( _had_noglob )) || set +o noglob
        if (( _eval_ok != 0 )); then
            continue
        fi

        # skip alias if there is no completion function triggered by the aliased command
        if [[ ! " ${completions[*]} " =~ " $alias_cmd " ]]; then
            if [[ -n "$completion_loader" ]]; then
                # force loading of completions for the aliased command
                eval "$completion_loader $alias_cmd"
                # 124 means completion loader was successful
                [[ $? -eq 124 ]] || continue
                completions+=($alias_cmd)
            else
                continue
            fi
        fi
        local new_completion="$(complete -p "$alias_cmd")"

        # create a wrapper inserting the alias arguments if any
        if [[ -n $alias_args ]]; then
            local compl_func="${new_completion/#* -F /}"; compl_func="${compl_func%% *}"
            # avoid recursive call loops by ignoring our own functions
            if [[ "${compl_func#_$namespace::}" == $compl_func ]]; then
                local compl_wrapper="_${namespace}::${alias_name}"
                    echo "function $compl_wrapper {
                        (( COMP_CWORD += ${#alias_arg_words[@]} ))
                        COMP_WORDS=($alias_cmd $alias_args \${COMP_WORDS[@]:1})
                        (( COMP_POINT -= \${#COMP_LINE} ))
                        COMP_LINE=\${COMP_LINE/$alias_name/$alias_cmd $alias_args}
                        (( COMP_POINT += \${#COMP_LINE} ))
                        $compl_func
                    }" >> "$tmp_file"
                    new_completion="${new_completion/ -F $compl_func / -F $compl_wrapper }"
            fi
        fi

        # replace completion trigger by alias
        new_completion="${new_completion% *} $alias_name"
        echo "$new_completion" >> "$tmp_file"
    done < <(alias -p | sed -Ene "s/$alias_regex/\1 '\2' '\3'/p")
    source "$tmp_file" && rm -f "$tmp_file"
}; alias_completion
