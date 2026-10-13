#!/bin/bash
# Regression tests for ktlint-format.sh. Run after any edit to the hook:
#
#   bash .claude/hooks/ktlint-format.test.sh
#
# The hook must never reject an edit for a reason Claude can't fix. The
# "ktlint missing" case is the reason this file exists: without it, every
# Kotlin edit was rejected with "ktlint: command not found".

HOOK="$(dirname "$0")/ktlint-format.sh"
pass=0; fail=0; skipped=0
work=$(mktemp -d)
trap 'rm -r "$work"' EXIT

run() { # file, [PATH override] → sets code
  if [ -n "$2" ]; then
    printf '{"tool_input":{"file_path":"%s"}}' "$1" | PATH="$2" "$BASH" "$HOOK" >/dev/null 2>&1
  else
    printf '{"tool_input":{"file_path":"%s"}}' "$1" | "$BASH" "$HOOK" >/dev/null 2>&1
  fi
  code=$?
}

expect() { # description, want_code
  if [ "$code" = "$2" ]; then
    pass=$((pass + 1)); printf '  ok   %s\n' "$1"
  else
    fail=$((fail + 1)); printf '  FAIL %s (got exit %s, want %s)\n' "$1" "$code" "$2"
  fi
}

echo "Never reject an edit Claude can't fix:"
printf '# notes\n' > "$work/notes.md"
run "$work/notes.md"; expect "non-Kotlin file is ignored" 0

printf 'fun main() {}\n' > "$work/NoKtlint.kt"
bin="$work/bin"; mkdir "$bin"; ln -s "$(command -v jq)" "$bin/jq"
run "$work/NoKtlint.kt" "$bin"; expect "ktlint missing: skip, don't reject" 0

if command -v ktlint >/dev/null 2>&1; then
  echo "With ktlint installed:"
  printf 'fun  main( ) {  println("x") }\n' > "$work/Fixable.kt"
  before=$(cat "$work/Fixable.kt")
  run "$work/Fixable.kt"; expect "fixable style is reformatted, edit accepted" 0
  if [ "$(cat "$work/Fixable.kt")" != "$before" ]; then
    pass=$((pass + 1)); printf '  ok   %s\n' "file was actually reformatted"
  else
    fail=$((fail + 1)); printf '  FAIL %s\n' "file was not reformatted"
  fi
  printf 'import java.util.*\n\nfun main() {}\n' > "$work/Unfixable.kt"
  run "$work/Unfixable.kt"; expect "unfixable violation goes back to Claude" 2
else
  skipped=3; echo "ktlint not installed: skipped 3 formatting cases"
fi

printf '\n%d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skipped"
[ "$fail" -eq 0 ]
