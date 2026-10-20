#!/bin/bash
# Tests for pre-push. Run: bash .githooks/pre-push.test.sh
set -u
HOOKS="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0

git init -q --bare "$T/remote.git"
git init -q -b main "$T/repo"
cd "$T/repo"
git config user.email test@example.com; git config user.name test
git commit -q --allow-empty -m init
git remote add origin "$T/remote.git"
git push -q origin main                 # seed main before the hook is on
git config core.hooksPath "$HOOKS"
git checkout -q -b feat
git commit -q --allow-empty -m one

check() { # name, expected (allowed|blocked), command...
  # "blocked" means the hook refused it, not that git failed for another reason.
  local name=$1 want=$2 out; shift 2
  if out=$("$@" 2>&1); then got=allowed
  elif printf '%s' "$out" | grep -q '^pre-push:'; then got=blocked
  else got="failed for another reason: $(printf '%s' "$out" | tail -1)"; fi
  if [ "$got" = "$want" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $name: want $want, got $got"; fi
}

check "new feature branch"         allowed git push origin feat
check "feature branch, fast-forward" allowed sh -c 'git commit -q --allow-empty -m two && git push origin feat'
check "push to main"               blocked sh -c 'git checkout -q main && git commit -q --allow-empty -m direct && git push origin main; r=$?; git checkout -q feat; exit $r'
check "push HEAD:main"             blocked git push origin HEAD:main
check "push via git -C"            blocked git -C "$T/repo" push origin HEAD:main
check "force push feature"         blocked sh -c 'git reset -q --hard HEAD~1 && git commit -q --allow-empty -m rewritten && git push -f origin feat'
check "force-with-lease feature"   blocked git push --force-with-lease origin feat
check "delete main"                blocked git push origin :main
check "delete feature branch"      allowed git push origin :feat
check "tag"                        allowed sh -c 'git tag v1 && git push origin v1'
check "--no-verify skips the hook (why it's denied in settings.json)" allowed git push --no-verify origin HEAD:main

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
