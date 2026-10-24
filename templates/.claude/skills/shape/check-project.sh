#!/bin/bash
# Is this app repo ready for /shape? Prints one line per check and exits
# 0 if all pass, 1 if any fail, 2 on bad usage. Needs git; uses gh for the
# remote check (skipped, and counted as a failure, if gh can't answer).
# Usage: check-project.sh <path-to-app-repo>
set -u
dir=${1:?usage: check-project.sh <path-to-app-repo>}
[ -d "$dir" ] || { echo "❌ $dir is not a folder"; exit 1; }
cd "$dir" || exit 2
fails=0
ok()  { printf '✅ %s\n' "$1"; }
bad() { printf '❌ %s\n' "$1"; fails=$((fails+1)); }

# 1. git repo with a Gradle project
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ "$(git rev-parse --show-toplevel)" = "$(pwd -P)" ]; then
  ok "git repo"
else
  bad "git repo (run git init -b main at the project root)"
fi
if [ -f settings.gradle.kts ] || [ -f settings.gradle ]; then ok "Gradle project"; else bad "Gradle project (no settings.gradle(.kts) at the root)"; fi

# 2. private GitHub remote with main pushed
url=$(git remote get-url origin 2>/dev/null || true)
if [ -z "$url" ]; then
  bad "GitHub remote (no origin)"
else
  private=$(gh repo view "$url" --json isPrivate -q .isPrivate 2>/dev/null || true)
  case "$private" in
    true)  ok "private GitHub remote" ;;
    false) bad "private GitHub remote (origin is public)" ;;
    *)     bad "private GitHub remote (gh couldn't read $url)" ;;
  esac
  if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then ok "main pushed"; else bad "main pushed (origin has no main)"; fi
fi

# 3. push guard on
if [ "$(git config core.hooksPath 2>/dev/null)" = ".githooks" ] && [ -x .githooks/pre-push ]; then
  ok "push guard on"
else
  bad "push guard on (needs .githooks/pre-push and git config core.hooksPath .githooks)"
fi

# 4. project files
missing=""
for f in .github/workflows/ci.yml .github/scripts/check-bar.sh .github/pull_request_template.md .claude/rules/android.md docs/specs docs/adr; do
  [ -e "$f" ] || missing="$missing $f"
done
if [ -z "$missing" ]; then ok "project files"; else bad "project files (missing:$missing)"; fi

# 5. root CLAUDE.md written by the owner
if [ -s CLAUDE.md ] && ! grep -q 'TODO(owner)' CLAUDE.md; then
  ok "CLAUDE.md written"
else
  bad "CLAUDE.md written (missing, empty, or still has TODO(owner) placeholders)"
fi

[ "$fails" -eq 0 ] && { echo "Ready."; exit 0; }
echo "Not ready: $fails check(s) failed."
exit 1
