#!/bin/bash
# Regression tests for block-secrets.sh.
#
# Case 1 is the reason this file exists: an earlier hook matched the bare
# substring 'credentials' and blocked androidx.credentials — the Credential
# Manager API most apps need for sign-in. Run this after any edit
# to the hook.
#
#   bash .claude/hooks/block-secrets.test.sh

HOOK="$(dirname "$0")/block-secrets.sh"
pass=0; fail=0

check() { # description, payload, expected(allow|deny)
  local out verdict
  out=$(printf '%s' "$2" | bash "$HOOK")
  [ -n "$out" ] && verdict=deny || verdict=allow
  if [ "$verdict" = "$3" ]; then
    pass=$((pass + 1)); printf '  ok   %s\n' "$1"
  else
    fail=$((fail + 1)); printf '  FAIL %s (got %s, want %s)\n' "$1" "$verdict" "$3"
  fi
}

echo "Legitimate Android work must not be blocked:"
check "androidx.credentials source file" '{"tool_name":"Read","tool_input":{"file_path":"android/core/data/CredentialsRepository.kt"}}' allow
check "androidx.credentials in a gradle command" '{"tool_name":"Bash","tool_input":{"command":"./gradlew :app:dependencies | grep androidx.credentials"}}' allow
check "committed .env.example placeholder" '{"tool_name":"Read","tool_input":{"file_path":"backend/.env.example"}}' allow
check "directory merely named credentials" '{"tool_name":"Read","tool_input":{"file_path":"docs/credentials/README.md"}}' allow
check "ordinary build command" '{"tool_name":"Bash","tool_input":{"command":"./gradlew assembleDebug"}}' allow

echo "Secrets must be blocked:"
check "read .env" '{"tool_name":"Read","tool_input":{"file_path":"backend/.env"}}' deny
check "write .env" '{"tool_name":"Write","tool_input":{"file_path":"backend/.env"}}' deny
check "edit .env.local" '{"tool_name":"Edit","tool_input":{"file_path":"backend/.env.local"}}' deny
check "grep into .env" '{"tool_name":"Grep","tool_input":{"pattern":"KEY","path":"backend/.env"}}' deny
check "upload keystore .jks" '{"tool_name":"Read","tool_input":{"file_path":"android/app/debug.jks"}}' deny
check "release .keystore" '{"tool_name":"Read","tool_input":{"file_path":"android/release.keystore"}}' deny
check "keystore.properties" '{"tool_name":"Read","tool_input":{"file_path":"android/keystore.properties"}}' deny
check "local.properties" '{"tool_name":"Read","tool_input":{"file_path":"android/local.properties"}}' deny
check "google-services.json" '{"tool_name":"Read","tool_input":{"file_path":"android/app/google-services.json"}}' deny
check "service-account json" '{"tool_name":"Read","tool_input":{"file_path":"ops/service-account-prod.json"}}' deny
check "pem certificate" '{"tool_name":"Read","tool_input":{"file_path":"ops/server.pem"}}' deny
check "secret as final bash token" '{"tool_name":"Bash","tool_input":{"command":"cat backend/.env"}}' deny
check "secret behind a = flag" '{"tool_name":"Bash","tool_input":{"command":"docker run --env-file=backend/.env app"}}' deny
check "quoted secret mid-pipeline" '{"tool_name":"Bash","tool_input":{"command":"grep TOKEN \"backend/.env\" | head"}}' deny
check "keytool against a .jks" '{"tool_name":"Bash","tool_input":{"command":"keytool -list -keystore android/app/debug.jks"}}' deny

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
