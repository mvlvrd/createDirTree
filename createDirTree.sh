#!/bin/bash

declare -A REPLACEMENTS
parse_replacements() {
    for arg in "$@"; do
	[[ "$arg" != *:* ]] && { echo "Invalid argument '$arg': expected KEY:VALUE" >&2; return 1; }
	IFS=":" read -r key val <<< "$arg"
	REPLACEMENTS["$key"]="$val"
    done
}

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [KEY:VALUE ...] < tree.txt

Creates a directory tree from an indented text description read from stdin.

Arguments:
  KEY:VALUE    Replacement pairs for placeholders in the tree (e.g. name:myapp)

Options:
  -h, --help   Show this help message and exit

Input format:
  - First line: root directory name, must end with '/'
  - Subsequent lines: 4-space indented tree of files and directories
  - Directories must end with '/', files must not
  - Placeholders in the form <KEY> are substituted with matching KEY:VALUE args

Example:
<project dir>/
├── pyproject.toml
├── MANIFEST.in
└── <package dir>/
    ├── __init__.py
    ├── library.py
    ├── mid-end/
    ├── front-end/
        ├── package.json
        ├── tsconfig.json
        ├── webpack.config.js
        └── src/
            ├── index.ts
            └── <component>.ts
    └── back-end/
EOF
}

[[ "$1" == "-h" || "$1" == "--help" ]] && { print_usage; exit 0; }

parse_replacements "$@" || exit $?

delta=4
parse_line() {
    #TODO: Make it work with tree output syntax. Deal with empty input?
    local leading="${1%%[![:space:]]*}"
    local count="${#leading}"

    ((count % delta)) && { echo "Bad syntax: Wrong indentation in line $lineNumber: $1" >&2; return 1; }

    printf -v "$2" "%s" $((count/delta))
    clean_name "${1##*[├└]── }" $3 || return 1

    return 0
}

clean_name() {
    local input="$1"
    local output="$1"
    local placeholder replacement
    while [[ $output =~ \<([^>]+)\> ]]; do
	placeholder="${BASH_REMATCH[1]}"
	[[ ! -v REPLACEMENTS[$placeholder] ]] && { echo "Unknown placeholder '<$placeholder>' in: $input" >&2; return 1; }
	replacement="${REPLACEMENTS[$placeholder]}"
	output="${output//<$placeholder>/$replacement}"
    done
    printf -v "$2" "%s" "$output"
}

read -r rootLine
clean_name "$rootLine" cleanedRoot
[[ $cleanedRoot =~ ^[[:space:]] ]] && { echo "Error: Root line starts with spaces: '$rootLine'" >&2 ; exit 1; }
[[ ! $cleanedRoot =~ /$ ]] && { echo "Error: Root line should end with '/': '$rootLine'" >&2 ; exit 1; }
mkdir -p "$cleanedRoot" && pushd "$cleanedRoot" > /dev/null || exit 1

lineNumber=1
currentLevel=0
clean_input=$cleanedRoot
while read -r; do
    ((lineNumber++))
    prevLevel=$currentLevel
    prevInput=$clean_input

    [[ -z $REPLY ]] && { echo "Error: Empty input at line $lineNumber" ; exit 1; }
    parse_line "$REPLY" currentLevel clean_input || exit 1
    (( currentLevel > prevLevel )) && { pushd "$prevInput" > /dev/null || exit 1; }
    if [[ "${clean_input: -1}" == "/" ]]; then
        for ((i=0; i<(prevLevel - currentLevel); i++)); do
	    popd > /dev/null || exit 1
        done
	mkdir -p "$clean_input" || exit 1
    else
        touch "$clean_input" || exit 1
    fi
done

while popd > /dev/null 2>&1; do :; done
