#!/bin/bash
# Lists changes that lower the quality bar instead of fixing the code, and
# fails if there are any. A human decides at merge whether each is legitimate.
# Usage: check-bar.sh <base-ref>   (e.g. origin/main)
# Adapted from the "floor" in constraint-driven-development
# (addyosmani/agent-skills, MIT), for Android.
set -u
base=${1:?usage: check-bar.sh <base-ref>}
git rev-parse --verify -q "$base" >/dev/null || { echo "check-bar: unknown base ref $base" >&2; exit 2; }
range="$base...HEAD"
TESTS=('*/src/test/*' '*/src/androidTest/*' '*/src/*Test/*')
found=0

section() { # title, matches
  [ -z "$2" ] && return
  found=1
  echo "$1"
  printf '%s\n' "$2" | sed 's/^/  /'
}

section "Suppressions added:" "$(git diff -U0 "$range" -- '*.kt' '*.kts' |
  grep '^+[^+]' | grep -E '@Suppress|@SuppressLint|@file:Suppress|@Ignore|ktlint-disable' | cut -c2-)"

section "Test files deleted:" "$(git diff --name-only --diff-filter=D "$range" -- "${TESTS[@]}")"

section "Assertions removed from tests:" "$(git diff -U0 "$range" -- "${TESTS[@]}" |
  grep '^-[^-]' | grep -E '\bassert[A-Za-z]*\(|\.(isEqualTo|isTrue|isFalse|assertExists|assertDoesNotExist|assertIs[A-Za-z]*)\(' | cut -c2-)"

section "Lint baseline, lint or ktlint config, or CI changed:" "$(git diff --name-only "$range" -- \
  '*lint-baseline.xml' '*lint.xml' '*.editorconfig' '.github/workflows/*' '.github/scripts/*')"

# New reference images are new tests; changed or deleted ones were re-recorded.
section "Screenshot references re-recorded or deleted:" "$(git diff --name-only --diff-filter=MD "$range" -- \
  '*/screenshotTest/reference/*' '*/reference/*.png')"

if [ "$found" -eq 1 ]; then
  echo "check-bar: the changes above make checks easier to pass. Explain each in the PR, or fix the code." >&2
  exit 1
fi
echo "check-bar: nothing lowered."
