#!/usr/bin/env python3
"""Keeps effects that nothing uses yet out of the browser build.

  python3 tools/assets/web_export_filter.py write   updates client/export_presets.cfg
  python3 tools/assets/web_export_filter.py check   exit 1 if it is out of date

A pixelfx effect whose recipe entry (art/pixelfx/effects.json) has a "use" starting
with "PROPOSED" is imported and recorded (provenance, credits) but wired to no skill,
monster or event yet, so the Web preset's exclude_filter leaves its sheet out of the
download (owner decision, 2026-11-17). Wiring an effect to gameplay means editing its
"use" to say where it is used; the next `write` then ships it. The editor, the tests
and the asset catalogue still see every effect.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "art" / "pixelfx" / "effects.json"
PRESETS = ROOT / "client" / "export_presets.cfg"
BASE = ["tests/*"]


def proposed() -> list[str]:
    effects = json.loads(RECIPE.read_text())["effects"]
    return sorted(k for k, v in effects.items() if str(v.get("use", "")).startswith("PROPOSED"))


def wanted_filter() -> str:
    return ", ".join(BASE + [f"assets/fx/pixelfx/{k}.png" for k in proposed()])


def current_filter(text: str) -> str:
    match = re.search(r'^exclude_filter="(.*)"$', text, re.M)
    return match.group(1) if match else ""


def main(argv: list[str]) -> int:
    if len(argv) != 2 or argv[1] not in ("write", "check"):
        print(__doc__)
        return 2
    text = PRESETS.read_text()
    want = wanted_filter()
    if argv[1] == "check":
        if current_filter(text) != want:
            print("client/export_presets.cfg exclude_filter is stale: run web_export_filter.py write")
            return 1
        print(f"web export filter: {len(proposed())} unused effects excluded")
        return 0
    new, count = re.subn(r'^exclude_filter=".*"$', f'exclude_filter="{want}"', text, flags=re.M)
    if count != 1:
        print("expected exactly one exclude_filter line")
        return 1
    PRESETS.write_text(new)
    print(f"wrote exclude_filter: {len(proposed())} unused effects excluded")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
