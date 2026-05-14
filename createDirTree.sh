#!/bin/bash

declare -A REPLACEMENTS
parse_replacements() {
    for arg in "$@"; do
	[[ "$arg" != *:* ]] && { echo "Invalid argument '$arg': expected KEY:VALUE" >&2; return 1; }
	IFS=":" read -r key val <<< "$arg"
	[[ -z $key ]] && { echo "Invalid: empty key in '$arg'" >&2; return 1; }
	REPLACEMENTS["$key"]="$val"
    done
}

guess_format() {
    if [[ "${1:0:4}" == "    " ]]; then
	pattern="^([[:space:]]*)(.*)$"
    elif [[ "${1:0:4}" == "├── " ]]; then
	pattern="^([[:space:]]*[│   ]*[├└]── )(.*)$"
    else
	{ echo "Invalid input format: '$1'"; return 1; }
    fi
}

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [KEY:VALUE ...] < FILE

Creates a directory tree from an indented text description read from stdin.

Options:
  -h        Show this help message and exit
  -o DIR    Create the dir tree in directory DIR

Arguments:
  KEY:VALUE    Replacement pairs for placeholders in the tree (e.g. name:myapp)

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

while getopts ":ho:" opt; do
      case $opt in
	  h)
	      print_usage
	      exit 0
	      ;;
	  o)
	      init_dir="$OPTARG"
	      if [[ -n "$init_dir" ]]; then
		  cd "$init_dir" || { echo "Error: Cannot cd to '$init_dir'" >&2; exit 1; }
	      fi
	      ;;
	  \?)
	      echo "Invalid option: -$OPTARG" >&2
	      exit 1
	      ;;
	  :)
              echo "Option -$OPTARG requires an argument" >&2
              exit 1
              ;;
      esac
done
shift $((OPTIND - 1))
parse_replacements "$@" || exit $?

delta=4
parse_line() {
    # Parse a line from the tree structure and extract its level and cleaned name
    #
    # Usage: parse_line <line> <level_var> <name_var>
    #
    #   <line>      - A line from tree output (e.g., "    ├── src/")
    #   <level_var> - Name of variable to store the indentation level
    #   <name_var>  - Name of variable to store the cleaned file/directory name
    #
    # Returns: 0 on success, 1 on error (wrong indentation)
    # TODO: Make it work with tree output syntax. Deal with empty input?

    [[ $1 =~ $pattern ]] || { echo "The input line doesn't have the right format: $1" >&2; return 1; }

    local leading="${BASH_REMATCH[1]}"
    local name="${BASH_REMATCH[2]}"
    local count="${#leading}"

    ((count % delta)) && { echo "Bad syntax: Wrong indentation in line $lineNumber: $1" >&2; return 1; }

    printf -v "$2" "%s" $((count/delta))
    clean_name "$name" $3 || return 1

    return 0
}

clean_name() {
    # Clean a file/directory name by replacing <placeholder> patterns with values
    # from the REPLACEMENTS associative array.
    #
    # Usage: clean_name <input> <output_var>
    #
    #   <input>     - Raw name possibly containing <placeholders> (e.g., "<project dir>/")
    #   <output_var>- Name of variable to store the cleaned name
    #
    # Returns: 0 on success, 1 if an unknown placeholder is encountered
    #
    # Example:
    #   REPLACEMENTS["project dir"]="myapp"
    #   clean_name "<project dir>/src" result
    #   # result = "myapp/src"
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
mkdir -p "$cleanedRoot" || exit 1

read -r
secondLine="$REPLY"
guess_format "$secondLine" || exit 1

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
done < <(echo "$secondLine"; cat)

while popd > /dev/null 2>&1; do :; done
