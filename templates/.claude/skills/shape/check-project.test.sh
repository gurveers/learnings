#!/bin/bash
# Tests for check-project.sh. Run: bash check-project.test.sh
# A fake gh answers the "is it private?" question; a local bare repo is origin.
set -u
SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-project.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0

mkdir -p "$T/bin"
cat > "$T/bin/gh" <<'GH'
#!/bin/bash
[ "${FAKE_GH:-private}" = broken ] && exit 1
[ "${FAKE_GH:-private}" = public ] && echo false || echo true
GH
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH"

# A ready app repo; each case copies it and breaks one thing.
make_ready() {
  local d=$1
  git init -q --bare "$d.remote.git"
  git init -q -b main "$d"
  ( cd "$d"
    git config user.email t@example.com; git config user.name t
    touch settings.gradle.kts
    mkdir -p .githooks .github/workflows .github/scripts .claude/rules docs/specs docs/adr
    printf '#!/bin/sh\nexit 0\n' > .githooks/pre-push; chmod +x .githooks/pre-push
    touch .github/workflows/ci.yml .github/scripts/check-bar.sh .github/pull_request_template.md .claude/rules/android.md docs/specs/.keep docs/adr/.keep
    echo "# Habits: a habit tracker for me" > CLAUDE.md
    git add -A; git commit -qm init
    git remote add origin "$d.remote.git"; git push -q origin main
    git config core.hooksPath .githooks )
}

check() { # name, expected exit, expected text, setup command (run in the repo copy), [fake gh answer]
  local name=$1 want=$2 text=$3 setup=$4 gh=${5:-private} d="$T/case$((pass+fail))"
  make_ready "$d"
  ( cd "$d" && eval "$setup" ) >/dev/null 2>&1
  out=$(FAKE_GH=$gh bash "$SCRIPT" "$d" 2>&1); rc=$?
  if [ "$rc" = "$want" ] && printf '%s' "$out" | grep -qF -- "$text"; then pass=$((pass+1))
  else fail=$((fail+1)); echo "FAIL: $name (want exit $want with '$text', got $rc)"; printf '%s\n' "$out" | sed 's/^/    /'; fi
}

check "ready"                 0 "Ready."                          "true"
check "no settings.gradle"    1 "❌ Gradle project"                "git rm -q settings.gradle.kts"
check "no remote"             1 "❌ GitHub remote (no origin)"     "git remote remove origin"
check "public remote"         1 "origin is public"                "true" public
check "gh can't answer"       1 "gh couldn't read"                "true" broken
check "main not pushed"       1 "❌ main pushed"                   'git init -q --bare ../empty.git && git remote set-url origin ../empty.git'
check "push guard off"        1 "❌ push guard on"                 "git config --unset core.hooksPath"
check "pre-push missing"      1 "❌ push guard on"                 "rm .githooks/pre-push"
check "rules file missing"    1 ".claude/rules/android.md"        "rm .claude/rules/android.md"
check "CI missing"            1 ".github/workflows/ci.yml"        "rm .github/workflows/ci.yml"
check "ADR folder missing"    1 "docs/adr"                        "rm -r docs/adr"
check "CLAUDE.md placeholder" 1 "❌ CLAUDE.md written"             "echo 'TODO(owner): what the app is' >> CLAUDE.md"
check "CLAUDE.md missing"     1 "❌ CLAUDE.md written"             "rm CLAUDE.md"

# Cases outside the copy-a-ready-repo pattern.
out=$(bash "$SCRIPT" "$T/nope" 2>&1); rc=$?
if [ $rc -eq 1 ] && printf '%s' "$out" | grep -q "is not a folder"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: missing folder ($rc)"; fi
mkdir -p "$T/plain"; out=$(bash "$SCRIPT" "$T/plain" 2>&1); rc=$?
if [ $rc -eq 1 ] && printf '%s' "$out" | grep -q "❌ git repo"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: not a git repo ($rc)"; fi
make_ready "$T/sub"; mkdir -p "$T/sub/app"; out=$(bash "$SCRIPT" "$T/sub/app" 2>&1); rc=$?
if [ $rc -eq 1 ] && printf '%s' "$out" | grep -q "❌ git repo"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: subfolder of a repo ($rc)"; fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
