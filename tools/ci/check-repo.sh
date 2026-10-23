#!/usr/bin/env bash
# Repository policy checks that need no toolchain:
#  - required project documents exist
#  - .env.example holds placeholders only
#  - no .env files or private keys are tracked
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
status=0
fail() { echo "::error::$*"; status=1; }

for doc in README.md ARCHITECTURE.md GAME_DESIGN.md NETWORKING.md DATABASE.md SECURITY.md \
           WEB_EXPORT.md PERFORMANCE.md CONTRIBUTING.md LICENSE CHANGELOG.md \
           DEPLOYMENT.md BACKUP_AND_RECOVERY.md CLAUDE.md .env.example; do
  [[ -f "$doc" ]] || fail "missing required file: $doc"
done

# Every assignment in .env.example must be empty, a local-dev default that is
# obviously not a secret, or a <placeholder>.
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  value="${line#*=}"
  if [[ "$line" =~ (PASSWORD|SECRET|TOKEN|KEY)= ]] && [[ -n "$value" && ! "$value" =~ ^\<.*\>$ ]]; then
    fail ".env.example: secret-looking variable must be a <placeholder>: ${line%%=*}"
  fi
done < .env.example

if git ls-files | grep -E '(^|/)\.env$|\.pem$|id_rsa|\.p12$|\.key$' ; then
  fail "tracked files above look like secrets or private keys"
fi

exit "$status"
