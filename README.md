# createDirTree.sh

A Bash script that creates a directory tree from an indented text representation, with support for named placeholders.
There are alternatives in Python, Rust and so on but a Bash implementation is easier to install for small projects.

## Usage

```bash
./createDirTree.sh [KEY:VALUE ...] < tree.txt
```

Replacements are passed as `KEY:VALUE` pairs on the command line. The tree structure is read from stdin.

## Input Format

The first line must be the root directory name, ending with `/`. Subsequent lines describe the tree using 4-space indentation, with directories ending in `/` and files having no trailing slash.

```
myproject/
    src/
        main.sh
        utils.sh
    tests/
        test_main.sh
    README.md
```

### Placeholders

Any part of a filename or directory name can contain a placeholder in the form `<KEY>`, which will be substituted with the corresponding `KEY:VALUE` argument.

```
<org>-<project>/
    src/
        <entrypoint>
    README.md
```

```bash
./createDirTree.sh org:acme project:widget entrypoint:main.sh < tree.txt
```

This produces:

```
acme-widget/
    src/
        main.sh
    README.md
```

Multiple placeholders per line are supported. An error is raised if a placeholder has no matching replacement.

## Requirements

- Bash 4.2 or later (for associative arrays and `-v` flag on `[[ ]]`)
- Standard Unix utilities: `mkdir`, `touch`, `pushd`, `popd`

## Limitations

- Indentation must be exactly 4 spaces per level. Tabs are not supported.
- The `tree` command output format (with `├──`, `└──`, `│` characters) is not yet fully supported.

## Error Handling

The script exits with a 1 status and a descriptive message on stderr for the following conditions:

- Wrong indentation (not a multiple of 4 spaces)
- Root line starts with spaces
- Root line does not end with `/`
- An unknown placeholder is encountered

## Example

Given `tree.txt`:

```
<name>/
├── src/
│   └── main.sh
├── docs/
│   └── index.md
└── .gitignore
```

Run:

```bash
./createDirTree.sh name:myapp < tree.txt
```

Result:

```
myapp/
├── src/
│   └── main.sh
├── docs/
│   └── index.md
└── .gitignore
```
