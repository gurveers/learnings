#!/bin/bash
# Tests for check-bar.sh. Run: bash .github/scripts/check-bar.test.sh
set -u
SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-bar.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
cd "$T" && git init -q -b main . && git config user.email t@example.com && git config user.name t

mk() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
mk app/src/main/kotlin/Vm.kt 'class Vm'
mk app/src/test/kotlin/VmTest.kt $'class VmTest {\n  @Test fun loads() { assertEquals(1, 1) }\n}'
mk app/src/test/kotlin/OtherTest.kt 'class OtherTest'
mk app/lint-baseline.xml '<issues/>'
mk .editorconfig 'root = true'
mk .github/workflows/ci.yml 'name: CI'
mk app/src/debug/screenshotTest/reference/Home.png 'old'
git add -A && git commit -qm base

# case: name, expected (pass|fail), expected text in output, change...
check() {
  local name=$1 want=$2 text=$3; shift 3
  git checkout -q -B "c$((pass+fail))" main
  sh -c "$*" && git add -A && git commit -qm change --allow-empty
  out=$(bash "$SCRIPT" main 2>&1); rc=$?
  got=pass; [ $rc -eq 1 ] && got=fail; [ $rc -gt 1 ] && got="error $rc"
  if [ "$got" = "$want" ] && printf '%s' "$out" | grep -qF -- "$text"; then pass=$((pass+1))
  else fail=$((fail+1)); echo "FAIL: $name (want $want with '$text', got $got)"; printf '%s\n' "$out" | sed 's/^/    /'; fi
}

check "clean change"              pass "nothing lowered"  "echo 'class Vm2' > app/src/main/kotlin/Vm2.kt"
check "new test"                  pass "nothing lowered"  "echo 'class NewTest' > app/src/test/kotlin/NewTest.kt"
check "new reference image"       pass "nothing lowered"  "echo new > app/src/debug/screenshotTest/reference/Settings.png"
check "@Suppress added"           fail '@Suppress("UNCHECKED_CAST")' "printf '@Suppress(\"UNCHECKED_CAST\")\nclass Vm\n' > app/src/main/kotlin/Vm.kt"
check "@Ignore added"             fail "@Ignore"          "sed -i.bak 's/  @Test/  @Ignore @Test/' app/src/test/kotlin/VmTest.kt && rm app/src/test/kotlin/VmTest.kt.bak"
check "ktlint-disable added"      fail "ktlint-disable"   "echo '// ktlint-disable' >> app/src/main/kotlin/Vm.kt"
check "test file deleted"         fail "OtherTest.kt"     "git rm -q app/src/test/kotlin/OtherTest.kt"
check "assertion removed"         fail "assertEquals"     "sed -i.bak 's/ assertEquals(1, 1) / /' app/src/test/kotlin/VmTest.kt && rm app/src/test/kotlin/VmTest.kt.bak"
check "lint baseline grew"        fail "lint-baseline.xml" "echo '<issue/>' >> app/lint-baseline.xml"
check ".editorconfig changed"     fail ".editorconfig"    "echo 'ktlint_standard_no-wildcard-imports = disabled' >> .editorconfig"
check "workflow edited"           fail "ci.yml"           "echo '# x' >> .github/workflows/ci.yml"
check "reference re-recorded"     fail "Home.png"         "echo new > app/src/debug/screenshotTest/reference/Home.png"
out=$(bash "$SCRIPT" no-such-ref 2>&1); rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q "unknown base ref"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: unknown base ref (rc $rc)"; fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
