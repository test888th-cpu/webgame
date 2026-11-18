#!/usr/bin/env python3
"""Place the reference monsters on The Iron Legacy's existing areas.

  python3 tools/content/build_placement.py [--check]

Reads client/data/areas.json (the existing maps, their level order, camps and
bosses), client/data/enemies.json (the existing art) and
client/data/rpg/runtime_pack.json (the reference monsters the engine can fight) and
writes client/data/rpg/placement.json. Nothing here is a game rule: it only decides
which reference monster stands where, by the owner's order of 2026-11-18 ("keep the
city theme for now; monsters in level order as before so the player can level;
bosses, mini-bosses and farming grounds where they were").

Status: PROPOSED (docs/GAME_MIGRATION_REGISTER.md, PLACE-*). Every monster keeps its
reference id, level band, stats and loot; only the area it stands in and the
existing sprite that draws it are this game's choice:

* level: an area's legacy level L (2 to 48 on the story route, up to 70 beyond)
  maps onto the reference's 1 to 20 (types.ts MAX_LEVEL) by
  t = clamp(round(1 + (L - 2) * 19 / 46), 1, 20), keeping the old order;
* monsters: those whose band reaches within one level of t, else the nearest band
  below; a monster spawns inside its own band (the camp spawner's rule);
* count and positions: the area's old enemy count along its old encounter and camp
  positions (pixels, 16 per yard on the street axis: ADAPTED, PROD-SCALE);
* art: the area's old enemy sprites, in turn (the city look stays);
* bosses and mini-bosses: BLOCKED until the reference boss engine is ported; the
  slot is recorded with the old boss id so it returns to the same map.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AREAS = ROOT / "client/data/areas.json"
ENEMIES = ROOT / "client/data/enemies.json"
PACK = ROOT / "client/data/rpg/runtime_pack.json"
OUT = ROOT / "client/data/rpg/placement.json"
PX_PER_YARD = 16
MAX_PER_AREA = 18


def target_level(legacy: int) -> int:
    return max(1, min(20, int(1 + (legacy - 2) * 19 / 46 + 0.5)))


def candidates(roster: dict, t: int) -> list[str]:
    near = [k for k, m in roster.items() if m["level_min"] <= t + 1 and m["level_max"] >= t - 1]
    if not near:
        below = [m["level_max"] for m in roster.values() if m["level_max"] < t]
        top = max(below) if below else min(m["level_min"] for m in roster.values())
        near = [k for k, m in roster.items()
                if m["level_max"] == top or (not below and m["level_min"] == top)]

    def key(k: str) -> tuple:
        m = roster[k]
        return (abs((m["level_min"] + m["level_max"]) / 2 - t), k)

    return sorted(near, key=key)[:3]


def old_enemies(area: dict) -> list[tuple[str, float]]:
    """(enemy id, x in pixels) for every enemy the old area put on the street."""
    out: list[tuple[str, float]] = []
    for enc in area.get("encounters", []):
        lo, hi = enc.get("arena", [enc.get("trigger_x", 400), enc.get("trigger_x", 400) + 600])
        flat = [e for wave in enc.get("waves", []) for e in wave]
        for i, e in enumerate(flat):
            out.append((e, lo + (hi - lo) * (i + 1) / (len(flat) + 1)))
    for p in area.get("placed", []):
        out.append((p["enemy"], float(p.get("x", 400))))
    spawning = area.get("spawning")
    if isinstance(spawning, dict):
        size = int(spawning.get("camp_size", [2, 3])[-1])
        pool = list(spawning.get("pool", {}))
        for c, cx in enumerate(spawning.get("camps", [])):
            for i in range(size):
                out.append((pool[(c + i) % len(pool)], float(cx) + (i - size / 2) * 48))
    return out


def build() -> dict:
    areas = json.loads(AREAS.read_text())["areas"]
    enemies = json.loads(ENEMIES.read_text())
    enemies = enemies.get("enemies", enemies)
    pack = json.loads(PACK.read_text())
    roster = pack["trial_monsters"]
    placed: dict = {}
    for aid, area in areas.items():
        if area.get("safe") or area.get("arena"):
            continue
        olds = old_enemies(area)
        bosses = sorted({e for e, _ in olds if enemies.get(e, {}).get("boss")})
        trash = [(e, x) for e, x in olds
                 if not enemies.get(e, {}).get("boss") and not enemies.get(e, {}).get("training")]
        if not trash and not bosses and not area.get("mini_boss"):
            continue
        t = target_level(int(area.get("level", 1)))
        picks = candidates(roster, t)
        skins = sorted({str(enemies[e].get("sprite", e)) for e, _ in trash if e in enemies})
        if not skins:
            skins = sorted({str(enemies[b].get("sprite", b)) for b in bosses if b in enemies})
        spawns = []
        step = max(1, len(trash) // MAX_PER_AREA + (1 if len(trash) % MAX_PER_AREA else 0))
        for i, (_, x) in enumerate(trash[::step][:MAX_PER_AREA]):
            mid = picks[i % len(picks)]
            spawns.append({
                "monster": mid,
                "x": round(x / PX_PER_YARD, 2),
                "sprite": skins[picks.index(mid) % len(skins)] if skins else "",
            })
        record = {
            "legacy_level": int(area.get("level", 1)),
            "target_level": t,
            "monsters": picks,
            "spawns": spawns,
            "kind": area.get("kind", "boss_arena" if area.get("world_boss") else "street"),
            "status": "PROPOSED",
        }
        slots = bosses + ([str(area["mini_boss"])] if isinstance(area.get("mini_boss"), str) else [])
        if slots or area.get("mini_boss"):
            record["boss_slots"] = [{
                "legacy_id": b,
                "status": "BLOCKED",
                "reason": "the reference boss and elite engine is not ported "
                          "(docs/GAME_MIGRATION_REGISTER.md section 5, item 5)",
            } for b in (slots or ["mini_boss"])]
        placed[aid] = record
    return {
        "_comment": "Generated by tools/content/build_placement.py; do not edit by hand. "
                    "PROPOSED placement of reference monsters on the existing areas.",
        "px_per_yard": PX_PER_YARD,
        "level_map": "t = clamp(round(1 + (L - 2) * 19 / 46), 1, 20)",
        "areas": placed,
    }


def main() -> int:
    text = json.dumps(build(), indent=1, sort_keys=True) + "\n"
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text() != text:
            print("placement.json is stale: run tools/content/build_placement.py")
            return 1
        print("placement.json is current")
        return 0
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
