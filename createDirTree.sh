#!/bin/bash

declare -A REPLACEMENTS
parse_replacements() {
    for arg in "$@"; do
	IFS=":" read -r key val <<< "$arg"
	REPLACEMENTS["$key"]="$val"
    done
}

parse_replacements "$@"

delta=4
parse_line() {
    #TODO: Make it work with tree output syntax. Deal with empty input?
    local leading="${1%%[![:space:]]*}"
    local count="${#leading}"

    ((count % delta)) && { echo "Bad syntax: Wrong indentation in line $lineNumber: $1" >&2; return 1; }

    printf -v "$2" "%s" $((count/delta))
    clean_name "${1##*[├└]── }" $3

    return 0
}

clean_name() {
    local input="$1"
    local output="$1"
    local placeholder replacement
    while [[ $output =~ \<([^>]+)\> ]]; do
	placeholder="${BASH_REMATCH[1]}"
	[[ ! -v REPLACEMENTS[$placeholder] ]] && { echo "Unknown placeholder '<$placeholder>' in: $input" >&2; exit 1; }
	replacement="${REPLACEMENTS[$placeholder]}"
	output="${output//<$placeholder>/$replacement}"
    done
    printf -v "$2" "%s" "$output"
}

read -r rootLine
clean_name "$rootLine" cleanedRoot
[[ $cleanedRoot =~ ^[[:space:]] ]] && { echo "Error: Root line starts with spaces: '$rootLine'" >&2 ; exit 1; }
[[ ! $cleanedRoot =~ /$ ]] && { echo "Error: Root line should end with '/': '$rootLine'" >&2 ; exit 1; }
mkdir -p "$cleanedRoot" && pushd "$cleanedRoot" > /dev/null

lineNumber=1
currentLevel=0
clean_input=$cleanedRoot
while read -r; do
    ((lineNumber++))
    prevLevel=$currentLevel
    prevInput=$clean_input

    parse_line "$REPLY" currentLevel clean_input || exit 1;
    (( currentLevel > prevLevel )) && pushd "$prevInput" > /dev/null
    if [[ "${clean_input: -1}" == "/" ]]; then
        for ((i=0; i<(prevLevel - currentLevel); i++)); do
	    popd > /dev/null
        done
	mkdir -p "$clean_input"
    else
        touch "$clean_input"
    fi
done

while popd > /dev/null 2>&1; do :; done
