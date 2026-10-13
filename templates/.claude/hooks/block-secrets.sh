#!/bin/bash
# PreToolUse hook — blocks Claude from reading, writing, grepping or shelling
# out to secret-shaped files anywhere in this repo.
# Defense-in-depth alongside .gitignore.
#
# Matching is anchored to the FILENAME, never to a substring anywhere in the
# path. An earlier version matched the bare word 'credentials', which blocked
# androidx.credentials — the Credential Manager API, which most apps need for sign-in.
# A deny rule's blast radius is whatever its pattern matches, so the
# pattern has to name the thing we actually mean.

input=$(cat)

# Secret-shaped basenames.
SECRET_RE='^\.env($|\.)|\.(pem|p12|jks|keystore)$|^(keystore|local)\.properties$|^google-services\.json$|^credentials\.json$|^service-account[^/]*\.json$'
# Committed placeholders — safe by construction; blocking them is pure friction.
ALLOW_RE='^\.env\.(example|sample|template|dist)$'

is_secret() {
  local name=${1##*/}                                   # basename
  [ -z "$name" ] && return 1
  printf '%s' "$name" | grep -qiE "$ALLOW_RE" && return 1
  printf '%s' "$name" | grep -qiE "$SECRET_RE"
}

deny() {
  local reason="Blocked by secrets guard: '$1' is a secret-shaped file (.env, *.pem, *.p12, *.jks, *.keystore, keystore/local.properties, google-services.json, credentials.json, service-account*.json). Handle secrets by hand, outside Claude Code."
  jq -n --arg reason "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')

if [ "$tool_name" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  # Split on whitespace and shell punctuation, strip quotes, test every token.
  while IFS= read -r tok; do
    tok=${tok//\"/}
    tok=${tok//\'/}
    [ -n "$tok" ] && is_secret "$tok" && deny "$tok"
  done < <(printf '%s\n' "$cmd" | tr ' \t\n|;&<>()$=,' '\n')
else
  # Read / Edit / Write carry file_path; Grep and Glob carry path.
  target=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
  [ -n "$target" ] && is_secret "$target" && deny "$target"
fi

exit 0
