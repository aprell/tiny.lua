#!/usr/bin/env bash
# ShellChecked

set -eu
set -o pipefail

for test in "${1:-examples}"/*.tiny; do
    if grep -q CHECK "$test"; then
        ./tiny "$test" | FileCheck "$test"
    fi
done
