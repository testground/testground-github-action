*NOTE*: This repository was forked from https://github.com/coryschwartz/testground-github-action to continue its' active development (initially to include the following fix: https://github.com/coryschwartz/testground-github-action/pull/2).

# testground-github-action

Submit jobs to [testground](https://testground.ai) and view the outcome in Github.


## usage:

As a code checker for PRs:

```yaml
---
name: Testground PR Checker

on: [push]

jobs:
  testground:
    runs-on: ubuntu-latest
    name: ${{ matrix.composition_file }}
    strategy:
      matrix:
        include:
          - backend_endpoint: http://<testground_daemon>
            plan_directory: </path/to/testplan/directory>
            composition_file: </path/to/composition.toml
    steps:
      - uses: actions/checkout@v2
      - name: ${{ matrix.composition_file }}
        id:
        uses: testground/testground-github-action@v1.0
        with:
          backend_endpoint: ${{ matrix.backend_endpoint }}
          plan_directory: ${{ matrix.plan_directory }}
          composition_file: ${{ matrix.composition_file }}

```
