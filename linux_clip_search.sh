#!/bin/bash

# Instructions:
# - Run |gnome-control-center keyboard|
# - Go to System Settings > Keyboard > Shortcuts > Custom shortcuts
# - Add a new shortcut, with command: "/path/to/clip_search.sh"
# - Map it to e.g. Start+space
# - To use, select text and press e.g. Start+space

throw() {
    >&2 echo "$1"
    xmessage "$1" &
    exit 1
}
if ! hash o 2>/dev/null; then
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    throw "Please add $script_dir to your \$PATH"
fi
if ! hash xsel 2>/dev/null; then
    throw "Please run: sudo apt-get install xsel"
fi

sel=$(xsel)
if [[ -z $sel ]]; then
    throw "Empty selection"
fi

o "$sel" &> /dev/null && exit 0

cd ~/Code
o "$sel" &> /dev/null && exit 0

# Try |locate|, but only if selection doesn't contain whitespace.
if [[ "$sel" == "${sel%[[:space:]]*}" ]]; then
    # Try exact match first.
    locate_result=$(locate -n2 -e --basename --regex "^$sel\$")
    if [[ -z "$locate_result" ]]; then
        locate_result=$(locate -n2 -e --basename "$sel")
    fi
    if [[ -n "$locate_result" ]]; then
        # TODO: Show chooser when there are several results.
        if [[ $(echo "$locate_result" | wc -l) == "1" ]]; then
            o "$locate_result" &> /dev/null && exit 0
        fi
    fi
fi

search_query=$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$sel")
o "https://www.google.com/search?q=$search_query"