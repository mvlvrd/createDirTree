setup() {
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-support/load'
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    TMPDIR="$(mktemp -d)"
}

teardown() {
    rm -fr "$TMPDIR"
}

assert_dir_tree() {
    local input_file="$1"
    local output_name="$2"
    local expected="$3"
    shift 3

    local output_dir="$TMPDIR/$output_name"
    run bash createDirTree.sh -o "$TMPDIR" "$@" < "${DIR}/${input_file}"
    assert_success
    run tree -F -a --noreport "$output_dir"
    assert_output "${TMPDIR}/${expected}"
}

SIMPLE_TREE_ARGS=(name:NM)
SIMPLE_TREE_EXPECTED="NM/
├── docs/
│   └── index.md
└── src/
    ├── .gitignore
    └── main.sh"

PROJECT_SKELETON_ARGS=("project dir":prj "package dir":pck component:Button)
PROJECT_SKELETON_EXPECTED="prj/
├── MANIFEST.in
├── pck/
│   ├── back-end/
│   ├── front-end/
│   │   ├── package.json
│   │   ├── src/
│   │   │   ├── Button.ts
│   │   │   └── index.ts
│   │   ├── tests/
│   │   │   ├── test1.txt
│   │   │   └── test2.txt
│   │   ├── tsconfig.json
│   │   └── webpack.config.js
│   ├── __init__.py
│   ├── library.py
│   └── mid-end/
└── pyproject.toml"

@test "project skeleton from skel.txt" {
    assert_dir_tree skel.txt prj "$PROJECT_SKELETON_EXPECTED" "${PROJECT_SKELETON_ARGS[@]}"
}

@test "simple tree from tree.txt" {
    assert_dir_tree tree.txt NM "$SIMPLE_TREE_EXPECTED" "${SIMPLE_TREE_ARGS[@]}"
}

@test "project skeleton from skel_ws.txt (with whitespace)" {
    assert_dir_tree skel_ws.txt prj "$PROJECT_SKELETON_EXPECTED" "${PROJECT_SKELETON_ARGS[@]}"
}

@test "simple tree from tree_ws.txt (with whitespace)" {
    assert_dir_tree tree_ws.txt NM "$SIMPLE_TREE_EXPECTED" "${SIMPLE_TREE_ARGS[@]}"
}

@test "project skeleton from skel_full.txt" {
    assert_dir_tree skel_full.txt prj "$PROJECT_SKELETON_EXPECTED" "${PROJECT_SKELETON_ARGS[@]}"
}

@test "simple tree from tree_full.txt" {
    assert_dir_tree tree_full.txt NM "$SIMPLE_TREE_EXPECTED" "${SIMPLE_TREE_ARGS[@]}"
}
