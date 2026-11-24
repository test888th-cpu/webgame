#!/usr/bin/env python3
"""Keep the gitleaks allowlist (.gitleaks.toml) as narrow as it claims.

  python3 tools/ci/check_registry_hash_lines.py [repo-root]

The allowlist lets the discord-api-token and generic-api-key rules pass a line of
the shape  "src/<path>.ts": "<64 lowercase hex>"  in five reference registry
files. Gitleaks matches lines, not JSON fields, so this check enforces the rest:
in those files every line of that shape must be an entry of the `inputs` field
(`source.inputs`, or the manifest's top-level `inputs`) with exactly that value.
A line of the same shape anywhere else in them fails here, so it can never hide a
credential behind the allowlist.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

LINE = re.compile(r'^\s*"(src/[A-Za-z0-9_./-]+\.ts)": "([0-9a-f]{64})",?$')
FILES = {
    "data/registry/reference_items.json": ("source", "inputs"),
    "data/registry/reference_loot_entries.json": ("source", "inputs"),
    "data/registry/reference_loot_tables.json": ("source", "inputs"),
    "data/registry/reference_monsters.json": ("source", "inputs"),
    "data/registry/reference_registry_manifest.json": ("inputs",),
}


def problems(root: Path) -> list[str]:
    out: list[str] = []
    for rel, field in FILES.items():
        path = root / rel
        if not path.exists():
            continue
        text = path.read_text()
        inputs = json.loads(text)
        for key in field:
            inputs = inputs.get(key, {}) if isinstance(inputs, dict) else {}
        shaped = 0
        for number, line in enumerate(text.split("\n"), 1):
            m = LINE.match(line)
            if not m:
                continue
            shaped += 1
            if not isinstance(inputs, dict) or inputs.get(m.group(1)) != m.group(2):
                out.append(f"{rel}:{number}: a hash-shaped line outside {'.'.join(field)}")
        if isinstance(inputs, dict) and shaped != len(inputs):
            out.append(f"{rel}: {shaped} hash-shaped lines for {len(inputs)} inputs entries")
    return out


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2]
    found = problems(root)
    for p in found:
        print(p)
    if found:
        return 1
    print("registry hash lines: all inside their inputs field")
    return 0


if __name__ == "__main__":
    sys.exit(main())
