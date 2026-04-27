setup() {
    load 'test_helper/bats-assert/load'
}

@test "1st" {
expected_1="/tmp/NM
├── docs
│   └── index.md
└── src
    ├── .gitignore
    └── main.sh"
rm -fr /tmp/NM
run bash createDirTree.sh -o /tmp name:NM < tree.txt
assert_success
run tree -a --noreport /tmp/NM
assert_output "$expected_1"
}

@test "2nd" {
expected_2="/tmp/prj
├── MANIFEST.in
├── pck
│   ├── back-end
│   ├── front-end
│   │   ├── package.json
│   │   ├── src
│   │   │   ├── Button.ts
│   │   │   └── index.ts
│   │   ├── tests
│   │   │   ├── test1.txt
│   │   │   └── test2.txt
│   │   ├── tsconfig.json
│   │   └── webpack.config.js
│   ├── __init__.py
│   ├── library.py
│   └── mid-end
└── pyproject.toml"
rm -fr /tmp/prj
run bash createDirTree.sh -o /tmp "project dir":prj "package dir":pck component:Button < skel.txt
assert_success
run tree -a --noreport /tmp/prj
assert_output "$expected_2"
}
