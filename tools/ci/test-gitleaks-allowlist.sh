#!/usr/bin/env bash
# Regression test for the gitleaks allowlist in .gitleaks.toml.
#
#   tools/ci/test-gitleaks-allowlist.sh <path-to-gitleaks>
#
# Builds a throwaway git repository with the repository's .gitleaks.toml and runs
# the real gitleaks over it. Token-like values are generated at run time, so no
# secret-looking literal is ever committed here. It proves:
#   * the allowed line (a "src/....ts" key with a 64-hex value in a registry's
#     inputs) passes;
#   * the Discord rule still fires on the same line in an unrelated file, and on a
#     Discord-named field outside inputs in the same registry file;
#   * the generic API key rule still fires in a registry file and elsewhere;
#   * an unrelated rule (a GitHub token) still fires on an allowed-looking key;
#   * check_registry_hash_lines.py rejects a hash-shaped line outside inputs.
set -euo pipefail

GITLEAKS="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 - "$ROOT" "$WORK" <<'PY'
import json, secrets, string, sys
from pathlib import Path
root, work = Path(sys.argv[1]), Path(sys.argv[2])
(work / ".gitleaks.toml").write_text((root / ".gitleaks.toml").read_text())
hex64 = lambda: secrets.token_hex(32)
alnum = lambda n: "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(n))
cases = {}
# 1. allowed: the registries' own shape
reg = work / "data/registry/reference_items.json"
reg.parent.mkdir(parents=True)
allowed = {"src/ui/discord_widget.ts": hex64(), "src/world_api.ts": hex64()}
# 3 and 5: credentials in other fields of the same registry file
discord_field = hex64()
api_key = alnum(40)
reg.write_text(json.dumps({
    "source": {"inputs": allowed},
    "notes": {"discord_bot_token": discord_field, "api_key": api_key},
}, indent=1, sort_keys=True) + "\n")
# 2 and 6: the allowed line shape in an unrelated file
other = work / "client/data/other.json"
other.parent.mkdir(parents=True)
other.write_text(json.dumps({"inputs": {"src/ui/discord_widget.ts": hex64(),
                                       "src/world_api.ts": hex64()}}, indent=1) + "\n")
# 7: a GitHub token as the value of an allowed-looking key in a registry file
gh = work / "data/registry/reference_monsters.json"
gh.write_text(json.dumps({"source": {"inputs": {"src/ui/panel.ts": "ghp_" + alnum(36)}}},
                         indent=1) + "\n")
expect = {
    "allowed hash lines pass": ("data/registry/reference_items.json", "src/", False),
    "discord rule: same line in an unrelated file": ("client/data/other.json", "discord", True),
    "discord rule: discord field outside inputs in a registry": ("data/registry/reference_items.json", "discord_bot_token", True),
    "generic rule: api_key in a registry": ("data/registry/reference_items.json", "api_key", True),
    "generic rule: same line in an unrelated file": ("client/data/other.json", "world_api", True),
    "github rule: token under an allowed-looking key": ("data/registry/reference_monsters.json", "ghp_", True),
}
(work / "expect.json").write_text(json.dumps(expect))
PY

cd "$WORK"
git init -q . && git -c user.name=t -c user.email=t@example.invalid add -A
git -c user.name=t -c user.email=t@example.invalid commit -qm cases
"$GITLEAKS" git --no-banner --exit-code 0 --report-format json --report-path report.json . >/dev/null 2>&1

python3 - <<'PY'
import json, sys
found = json.load(open("report.json"))
expect = json.load(open("expect.json"))
failed = 0
for name, (path, needle, want) in expect.items():
    hits = [f for f in found if f["File"] == path and needle in f["Match"]]
    if needle == "src/":  # the allowed lines: no finding on them at all
        hits = [f for f in found if f["File"] == path and f["Match"].lstrip().startswith('"src/')]
    ok = bool(hits) == want
    rules = sorted({f["RuleID"] for f in hits})
    print(("PASS" if ok else "FAIL"), name, "->", rules or "no finding")
    failed += not ok
sys.exit(1 if failed else 0)
PY

# The structural guard: a hash-shaped line outside inputs must fail.
python3 - "$WORK" <<'PY'
import json, secrets, sys
from pathlib import Path
reg = Path(sys.argv[1]) / "data/registry/reference_items.json"
doc = json.loads(reg.read_text())
doc["notes"]["src/ui/discord_widget.ts"] = secrets.token_hex(32)
reg.write_text(json.dumps(doc, indent=1, sort_keys=True) + "\n")
PY
if python3 "$ROOT/tools/ci/check_registry_hash_lines.py" "$WORK" >/dev/null; then
  echo "FAIL structural guard: a hash line outside inputs was accepted"
  exit 1
fi
echo "PASS structural guard: a hash line outside inputs is rejected"
