#!/usr/bin/env python3
"""Area-to-monster selection matrix (PROPOSED): docs/MONSTER_SELECTION_MATRIX.md and
data/registry/monster_area_candidates.json.

  python3 tools/content/render_monster_matrix.py [--check]

Inputs: data/registry/reference_monsters.json (VERIFIED reference monsters) and the
owner-approved area levels (tools/content/area_level_proposal.py area_rows). Nothing
here places a monster in the game: every row is a candidate for review, every empty
slot stays empty, and every reference monster gets exactly one status.

Rules (all PROPOSED unless marked):
* only PENDING_REVIEW monsters are candidates (EXCLUDED, DEFERRED and NOT_AN_ENEMY
  never are);
* the source level and the placement level are separate fields. A monster fits an
  area at level L when its own source range contains L (VERIFIED level, no
  adaptation). The reference level is never changed;
* the only exception is the heroic dungeon level: the reference runs every dungeon
  enemy at level 22 on heroic (content/dungeon_difficulty.ts). A dungeon enemy may
  fill an area at exactly 22 through that level, recorded as an ADAPTED placement
  with its own adaptation record. An area at 21 gets no heroic enemy: 22 is not 21,
  and no other adaptation is approved;
* story areas, arenas and farming grounds up to 20 take world and delve enemies;
  dungeon enemies stay with the level-22 heroic placements;
* roles are the source classification only (VERIFIED): normal, elite, rare,
  boss, world boss. A rare spawn fills only a "rare" slot: the reference has no
  mini-boss flag, and a rare is never promoted (owner decision 2026-11-17);
* no promotion: a slot whose role has no candidate stays empty and is listed;
* theme fit for an industrial port city, by the reference `family`: GOOD (humanoid,
  beast, elemental, burrower, spider) first, POSSIBLE (undead, ogre, troll, demon)
  after. A POOR fit (dragonkin, mudfin, reptile) is DEFERRED_THEME: listed per area,
  never deleted, waiting for a theme decision;
* at most CAPS candidates per role per area, the best theme first, then the closest
  level, then the id.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "content"))
import area_level_proposal  # noqa: E402

MONSTERS = ROOT / "data/registry/reference_monsters.json"
CANDIDATES_OUT = ROOT / "data/registry/monster_area_candidates.json"
DOC_OUT = ROOT / "docs/MONSTER_SELECTION_MATRIX.md"
GOOD = {"humanoid", "beast", "elemental", "burrower", "spider"}
POSSIBLE = {"undead", "ogre", "troll", "demon"}
POOR = {"dragonkin", "mudfin", "reptile"}
CAPS = {"normal": 6, "elite": 4, "rare": 3, "boss": 3, "world_boss": 3}
ROLES = ["normal", "elite", "rare", "boss", "world_boss"]
ROLE_FOR_KIND = {
    "story": ["normal", "elite", "rare", "boss"],
    "farming ground": ["normal", "elite", "rare"],
    "lair": ["elite", "boss"],
    "world boss arena": ["world_boss", "boss"],
    "arena": ["normal", "elite"],
    "hub": [],
}
HEROIC_LEVEL = 22
HEROIC_ADAPTATION = {
    "id": "ADAPT-HEROIC-22",
    "status": "ADAPTED (owner-approved band 20-22 for lairs and deep farming grounds, 2026-11-17); each placement PROPOSED",
    "reference": "src/sim/content/dungeon_difficulty.ts heroic tuning `level: 22`",
    "original": "the dungeon enemy's own normal-mode source range (kept in source_level)",
    "adapted": "placed at level 22, the level the reference itself gives the same enemy on heroic",
    "why": "above 20 the reference's only non-Rift enemies are dungeon enemies on heroic; lairs and deep farming grounds sit at 22",
    "behaviour": "unchanged: the record is used as written; this matrix applies no heroic stat multiplier and changes no mechanic",
    "impact": "the area's enemies are level 22 against the level-20 cap, as heroic dungeons are in the reference",
    "validation": "client/tests/unit/test_rpg_monster_registry.gd test_matrix_levels_and_adaptations",
}


def theme(mob: dict) -> str:
    family = str(mob["family"])
    return "GOOD" if family in GOOD else "POSSIBLE" if family in POSSIBLE else "POOR"


def fit(mob: dict, kind: str, level: int) -> dict | None:
    """How a monster can sit in an area at `level`, or None."""
    lo, hi = int(mob["level"]["min"]), int(mob["level"]["max"])
    source = {"min": lo, "max": hi}
    if mob["context"] in ("world", "delve") and kind != "lair" and lo <= level <= hi:
        return {"source_level": source, "placement_level": level, "level_match": "VERIFIED: within the source range"}
    if mob["context"] == "dungeon" and level == HEROIC_LEVEL and mob.get("heroic_level") == HEROIC_LEVEL:
        return {"source_level": source, "placement_level": level, "heroic_level": HEROIC_LEVEL,
                "level_match": "ADAPTED: heroic level 22", "adaptation": HEROIC_ADAPTATION["id"]}
    return None


def build() -> tuple[dict, str]:
    mobs = json.loads(MONSTERS.read_text())["monsters"]
    rows = area_level_proposal.area_rows()
    pool = {k: v for k, v in mobs.items() if v["selection"] == "PENDING_REVIEW"}
    areas: dict[str, dict] = {}
    proposed: set[str] = set()
    theme_deferred: set[str] = set()
    ranked_out: set[str] = set()
    adaptations: list[dict] = []
    for area_id, kind, _old, _player, enemy_level, _analogue, status, _unlock in rows:
        level = int(enemy_level)
        slots: dict[str, dict] = {}
        for want in ROLE_FOR_KIND.get(kind, []):
            fits, poor = [], []
            for mob_id, mob in pool.items():
                if mob["classification"] != want:
                    continue
                how = fit(mob, kind, level)
                if how is None:
                    continue
                lo, hi = how["source_level"]["min"], how["source_level"]["max"]
                rec = {"id": mob_id, "family": mob["family"], **how}
                if theme(mob) == "POOR":
                    poor.append(rec)
                else:
                    fits.append(((theme(mob) != "GOOD"), abs((lo + hi) / 2 - level), mob_id, rec))
            fits.sort(key=lambda f: f[:3])
            chosen = [f[3] for f in fits[:CAPS[want]]]
            ranked_out.update(f[2] for f in fits[CAPS[want]:])
            proposed.update(r["id"] for r in chosen)
            theme_deferred.update(r["id"] for r in poor)
            for r in chosen:
                if r.get("adaptation"):
                    adaptations.append({"area": area_id, "role": want, "monster": r["id"],
                                        "source_level": r["source_level"], "placement_level": level,
                                        "adaptation": r["adaptation"]})
            slots[want] = {
                "candidates": chosen,
                "deferred_theme": sorted((r for r in poor), key=lambda r: r["id"]),
                "empty": not chosen,
                "empty_reason": None if chosen else (
                    f"no PENDING_REVIEW {want.replace('_', ' ')} has a source range containing level {level}"
                    + (" and the heroic level is 22, not 21; filling it needs an owner-approved adaptation" if level == 21 else "")
                    + ("; the slot is left empty (no promotion)" )
                ),
            }
        areas[area_id] = {"kind": kind, "placement_level": level, "level_status": status, "slots": slots}

    statuses: dict[str, dict] = {}
    for mob_id, mob in sorted(mobs.items()):
        if mob["selection"] != "PENDING_REVIEW":
            statuses[mob_id] = {"status": mob["selection"].split(":")[0], "reason": mob["selection"]}
        elif mob_id in proposed:
            statuses[mob_id] = {"status": "PROPOSED", "reason": "a candidate in at least one area (PROPOSED)"}
        elif mob_id in theme_deferred:
            statuses[mob_id] = {"status": "DEFERRED_THEME", "reason": f"fits an area by level and role, but family '{mob['family']}' waits for a theme decision (PROPOSED)"}
        elif mob_id in ranked_out:
            statuses[mob_id] = {"status": "RANKED_OUT", "reason": "fits an area but ranked below the per-area cap (PROPOSED)"}
        else:
            statuses[mob_id] = {"status": "NO_FITTING_AREA", "reason": "no area at a level in its source range needs its role (PROPOSED)"}

    empty = [{"area": a, "role": r, "placement_level": info["placement_level"], "reason": s["empty_reason"]}
             for a, info in areas.items() for r, s in info["slots"].items() if s["empty"]]
    doc = {
        "_comment": "PROPOSED candidates only (tools/content/render_monster_matrix.py). No monster is placed in the game by this file. Source levels and placement levels are separate; every adaptation is listed; empty slots stay empty; every reference monster has one status.",
        "adaptation_register": [HEROIC_ADAPTATION],
        "adapted_placements": adaptations,
        "areas": areas,
        "empty_slots": empty,
        "monsters": statuses,
    }
    return doc, render(doc, mobs)


def render(doc: dict, mobs: dict) -> str:
    counts: dict[str, int] = {}
    for s in doc["monsters"].values():
        counts[s["status"]] = counts.get(s["status"], 0) + 1
    a = doc["adaptation_register"][0]
    lines = [
        "# Monster selection matrix: PROPOSED (not applied)", "",
        "Generated by `tools/content/render_monster_matrix.py`; do not edit by hand. The rules",
        "are in the script's header. The previous version is kept in",
        "[history/MONSTER_SELECTION_MATRIX_v1_2026-11-17.md](history/MONSTER_SELECTION_MATRIX_v1_2026-11-17.md).",
        "",
        "- **Nothing here is in the game:** this is a candidate list for review.",
        "- **Source level and placement level are separate.** A candidate's own range",
        "  (VERIFIED) must contain the area's level, except for the one adaptation below.",
        "- **Classification is the source's** (normal, elite, rare, boss, world boss). The",
        "  reference has no mini-boss flag; a rare spawn fills only a rare slot and is",
        "  never promoted (owner decision, 2026-11-17).",
        "- **`farm_reactor_underworks` (level 21) stays empty** (owner decision,",
        "  2026-11-17): nothing in the reference fits 21, and no enemy is invented.",
        "- **Empty slots stay empty.** No monster is promoted to fill a role.",
        "- **A poor theme fit is DEFERRED_THEME,** listed per area, never deleted.",
        "",
        f"**{len(doc['monsters'])} reference monsters, one status each:**",
        "",
    ]
    for k in sorted(counts):
        lines.append(f"- {k}: {counts[k]}")
    lines += [
        "",
        "## Adaptation register",
        "",
        "| Id | Reference | Original | Adapted | Why | Behaviour | Impact | Validation | Status |",
        "|---|---|---|---|---|---|---|---|---|",
        f"| {a['id']} | {a['reference']} | {a['original']} | {a['adapted']} | {a['why']} | {a['behaviour']} | {a['impact']} | `{a['validation']}` | {a['status']} |",
        "",
        f"It is used by {len(doc['adapted_placements'])} placements, all at level 22 (listed in",
        "`data/registry/monster_area_candidates.json`, `adapted_placements`). No area at",
        "21 uses it.",
        "",
        "## Id collisions",
        "",
        "`training_dummy` exists in both the game (`iron_legacy:training_dummy`, its own",
        "practice dummy, 120 HP) and the reference (`reference:training_dummy`, 999,999 base",
        "HP, NOT_AN_ENEMY). Each keeps its own record; the audit is",
        "`data/registry/id_collisions.json`. No item ids collide.",
        "",
        "## Per area",
        "",
        "Each cell lists candidates as `id` (source min–max → placement level). `—` means the",
        "area kind has no such role; *empty* means the role has no candidate.",
        "",
        "| Area | Kind | Level | Normal | Elite | Rare | Boss | World boss |",
        "|---|---|---:|---|---|---|---|---|",
    ]
    for area_id, info in doc["areas"].items():
        cells = []
        for want in ROLES:
            slot = info["slots"].get(want)
            if slot is None:
                cells.append("—")
                continue
            parts = [f"`{c['id']}` ({c['source_level']['min']}–{c['source_level']['max']}→{c['placement_level']}"
                     + (", ADAPTED" if c.get("adaptation") else "") + ")" for c in slot["candidates"]]
            if slot["empty"]:
                parts.append("*empty*")
            if slot["deferred_theme"]:
                parts.append("DEFERRED_THEME: " + ", ".join(f"`{c['id']}`" for c in slot["deferred_theme"]))
            cells.append("; ".join(parts))
        lines.append(f"| `{area_id}` | {info['kind']} | {info['placement_level']} | " + " | ".join(cells) + " |")
    lines += ["", "## Empty slots", "", "| Area | Role | Level | Reason |", "|---|---|---:|---|"]
    for e in doc["empty_slots"]:
        lines.append(f"| `{e['area']}` | {e['role']} | {e['placement_level']} | {e['reason']} |")
    lines += ["", "## Every reference monster", "", "| Monster | Family | Source level | Context | Classification | Status | Reason |",
              "|---|---|---|---|---|---|---|"]
    for mob_id, s in doc["monsters"].items():
        m = mobs[mob_id]
        lines.append(f"| `{mob_id}` | {m['family']} | {int(m['level']['min'])}–{int(m['level']['max'])} | {m['context']} | "
                     f"{m['classification']} | {s['status']} | {s['reason']} |")
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    doc, text = build()
    data = json.dumps(doc, indent=1, sort_keys=True) + "\n"
    if "--check" in argv:
        stale = [p for p, t in ((CANDIDATES_OUT, data), (DOC_OUT, text)) if not p.exists() or p.read_text(encoding="utf-8") != t]
        for p in stale:
            print("stale:", p.relative_to(ROOT))
        return 1 if stale else 0
    CANDIDATES_OUT.write_text(data, encoding="utf-8")
    DOC_OUT.write_text(text, encoding="utf-8")
    counts: dict[str, int] = {}
    for s in doc["monsters"].values():
        counts[s["status"]] = counts.get(s["status"], 0) + 1
    print("matrix:", counts, f"adapted placements {len(doc['adapted_placements'])}, empty slots {len(doc['empty_slots'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
