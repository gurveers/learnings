#!/bin/bash
# PostToolUse hook — auto-format Kotlin files Claude just edited.
# Unfixable violations go back to Claude (exit 2 + stderr) so it fixes them itself.
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in *.kt|*.kts) ;; *) exit 0 ;; esac
[ -f "$f" ] || exit 0
out=$(ktlint --format "$f" 2>&1) || { printf 'ktlint could not auto-fix %s:\n%s\n' "$f" "$out" >&2; exit 2; }
exit 0
