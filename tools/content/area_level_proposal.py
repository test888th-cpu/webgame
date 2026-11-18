#!/usr/bin/env python3
"""Area-to-level mapping PROPOSAL v2 (owner Decision 1): docs/AREA_LEVEL_MAPPING_PROPOSAL.md.

  python3 tools/content/area_level_proposal.py

v1 (all cap content at enemy level 20) is kept as historical evidence in
docs/history/AREA_LEVEL_MAPPING_PROPOSAL_v1_2026-11-17.md. v2 adds the verified
investigation of the Level 20 / Level 60 question and gives every area an enemy
level taken from the reference content it corresponds to, instead of forcing
all cap content to 20.

Reads client/data/areas.json, quests.json, progression.json and
data/content_audit.json. Changes no game data: it only proposes. Every
reference value below was read in World of ClaudeCraft source at d2b91e08
(the file and constant are named next to it).
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CAP = 20  # MAX_LEVEL, src/sim/types.ts
HEROIC = 22  # heroic dungeon mob level, src/sim/content/dungeon_difficulty.ts
RIFT_C_CAP = 22  # RIFT_LEVEL_CAP, src/sim/rift/ranks.ts (C rank ramps 20..22)
# District -> (reference zone(s), band); bands are each zone file's levelRange.
STAGES = {
    "South Street": ("zone1 [1, 7] (start: proving_shore [1, 2])", 1, 7),
    "Port District": ("zone2 [6, 13]", 8, 13),
    "Industrial District": ("zone3 [13, 20]", 14, 17),
    "The Black Network": ("realm [15, 20], drakelands [16, 20], frostveil [17, 20]", 18, 20),
    "The Core Facility": ("level-20 zones (evergarden, galecrest, nightbloom ...)", 20, 20),
    "Main Control Centre": ("level-20 endgame zones", 20, 20),
}

FINDINGS = """## Investigation: Level 20 or Level 60? (all VERIFIED in source at `d2b91e08`)

| # | Question | Finding | Source |
|---|---|---|---|
| 1 | Normal player maximum level | **20.** `MAX_LEVEL = 20`. | `src/sim/types.ts` |
| 2 | What the capital's "60" is | **A zone label.** Goldcrest Harbor's `levelRange: [1, 60]` is a zone's *suggested level band*, read only for display: the map sidebar, continent map, map tooltips and the `/where` chat line (`src/ui/map_sidebar_*`, `continent_map_view.ts`, `src/sim/social/chat.ts`, `chat_readouts.ts`). The map-document schema clamps every zone's band to 1–60 (`src/sim/map_doc.ts` lines 1823–1825), so 60 is the schema's upper bound. Goldcrest "registers only the zone identity" and places nothing in the base world (`goldcrest.ts` header). **It is not a player level, enemy level or scaling rule.** | as named |
| 2b | Other "60"s | Pet and summon templates span 1–60 (`warlock_pets.ts`, `mage_pets.ts`, `necromancy.ts`), but pets are "created at the owner's level (createMob reads the passed level, not minLevel/maxLevel)". **Not an enemy level.** | `warlock_pets.ts` header |
| 3 | Normal enemy levels | Zone mobs run 1–20 by their zone's band (zone1 1–7, zone2 6–13, zone3 13–20, then the level-20 zones). Of 316 templates, 81 top out at exactly 20. World and raid bosses are at 20 (balgath, ignivar, korzul, nythraxis, thunzharr, bound_guardian). | `data/reference/woc_content_index.json` (scan) |
| 4a | Elite | Same level as its zone; stronger by the elite multipliers (HP ×2.3, damage ×1.5). | `src/sim/entity.ts` createMob (RpgMobs) |
| 4b | Heroic | **Every heroic dungeon mob is pinned to level 22**, "two above the level-20 player cap", with health and damage multipliers per dungeon. | `src/sim/content/dungeon_difficulty.ts` (`level: 22`) |
| 4c | Rift | C rank ramps from 20 up to `RIFT_LEVEL_CAP = 22`; S rank is flat `RIFT_S_LEVEL = 23`; `RIFT_MAX_MOB_LEVEL = 23` is also the game-wide credited-mob ceiling. The rank base levels (C 20, B 22, A 25, S 28) are portal descriptors, not mob levels. | `src/sim/rift/ranks.ts` |
| 4d | Other endgame | The Scorching Wastes have mobs at 20–24, with Ember of Korzul, a boss, at 24. | `scorching_wastes.ts` (scan) |
| 5 | Do endgame enemies exceed the player cap? | **Yes, by design:** heroic 22, Rift up to 23, Scorching Wastes up to 24. The rest of the endgame (zones, world bosses, raid and dungeon finals) is at 20. | as above |
| 6 | Does Prestige add power? | **No.** `prestige()` "leaves lifetimeXp, level, gear, talents, and learned abilities untouched — strictly cosmetic, zero power change". Post-cap virtual levels (to 200, ×1.1 per level) are "post-cap cosmetic progression". | `src/sim/progression/xp.ts`; `src/sim/types.ts` |

**Conclusion.** The player cap is 20; levels past it are cosmetic. Endgame difficulty
comes from three things:

- item levels (dungeon and raid gear, per-copy quality +2/+4/+6/+8 item levels, the
  Rift Forge's +1 per step);
- elite, boss and heroic multipliers;
- a few enemy levels above 20, up to 24.

## Enemies above 22: evidence (VERIFIED in source)

**Rift** (`src/sim/rift/ranks.ts`, 45 templates in `content/rift/mobs.ts`: 32 elite, 13 boss):

- C rank ramps from 20 to `RIFT_LEVEL_CAP = 22`. B and A hold a flat 22.
- **Only S rank** puts every floor at a flat `RIFT_S_LEVEL = 23`, "one step above the
  fairness cap, to signal that S-rank is the hardest tier".
- The source calls 22 "the classic fairness cap (two above the level-20 player cap,
  matching the heroic dungeon pin)". Difficulty above it comes from a heroic stat
  transform, not from levels.

**Scorching Wastes** (`content/scorching_wastes.ts`) is "a custom-map endgame desert
zone … mobs run level 19-24 against the level-20 cap, so the back half plays as hard
elite content". It is "data-only and base-world-safe": it lives on a custom map, **not
in the reference's base world**.

| Id | Level | Kind |
|---|---|---|
| duskmane_prowler, glasscarab | 19–20 | normal |
| cinder_wisp | 20 | normal |
| duneblade_marauder | 20–21 | normal |
| karesh_the_parched | 21 | rare elite |
| vigil_sentinel | 21 | elite |
| emberveil_zealot, sunbaked_revenant | 21–22 | normal |
| ashen_courtier, cinder_elemental, emberveil_pyromancer | 22–23 | normal |
| **moltenheart_colossus**, **sunspeaker_atharis** | **23** | rare elites |
| **ember_of_korzul** | **24** | elite boss |

**Can a level-20 player fight them?** These are the reference rules as implemented in
`RpgHitTable`, computed in Godot:

| Enemy level | Player melee miss | Spell hit | Crit (from 20%) | Enemy dodge |
|---:|---:|---:|---:|---:|
| 20 | 5% | 96% | 20.0% | 5.0% |
| 22 | 13% | 88% | 19.6% | 6.0% |
| 23 | 19% | 82% | 19.4% | 6.5% |
| 24 | 19% | 82% | 19.2% | 7.0% |

The level-gap table stops at a 3-level gap (`ABOVE_LEVEL_MISS_PCT`), so 23 and 24 cost
the same. The reference answers the gap with:

- hit rating (10 per 1%);
- higher item levels (heroic and raid gear, per-copy quality, the Rift Forge);
- groups.

There are no special bonuses, and none are added here.

**Decision for The Iron Legacy (PROPOSED):**

| Content | Adopt now? | Reason |
|---|---|---|
| Enemies at 20–22 (heroic and Rift C/B/A analogues) | yes: lairs 22, deep farming grounds 20–22 (both ADAPTED) | inside the reference's own "fairness cap"; reachable with endgame gear |
| Rift S rank (all mobs at 23) | **not now** | belongs to the Rift system (portals, ranks, the heroic transform, Rift gear and the Rift Forge), which is not adopted yet. Revisit with the Rift; then 23 is a special endgame tier, never farming |
| Scorching Wastes (19–24, boss at 24) | **no: EXCLUDED** (owner decision, 2026-11-17) | custom-map content outside the reference's base world, and a desert setting that does not fit our industrial city. Its 14 templates stay in the reference index with their levels and ids, marked excluded, and are not mapped onto our areas |

**Farming does not go to 23–24.** The reference keeps 23 for its hardest instanced tier,
and 24 for one boss on a custom map.

**Nothing in the reference is level 60.** v1's error was giving all cap content enemy
level 20. v2 gives each area the level of the reference content it corresponds to.
"""


def load(rel: str) -> dict:
    return json.loads((ROOT / rel).read_text())


def area_rows() -> list[tuple]:
    """Every area: (id, kind, current level, player level needed, enemy level,
    reference analogue, status, unlock). Shared with render_monster_matrix.py."""
    data = load("client/data/areas.json")
    areas = data["areas"]
    starts = {d["from"]: d["name"] for d in data["districts"]}
    audit = load("data/content_audit.json")
    quests = load("client/data/quests.json")["quests"]
    progression = load("client/data/progression.json")

    story: list[tuple[str, str]] = []
    district = None
    for area_id, area in areas.items():
        if area_id in starts:
            district = starts[area_id]
        if district and not any(k in area for k in ("spawning", "world_boss", "mini_boss")) \
                and area_id not in ("main_city", "pvp_arena") and len(story) < 31:
            story.append((area_id, district))
    story_district = dict(story)
    proposed: dict[str, int] = {}
    for name, (_ref, lo, hi) in STAGES.items():
        members = sorted((a for a, d in story if d == name), key=lambda a: areas[a]["level"])
        for i, area_id in enumerate(members):
            step = 0 if len(members) == 1 else i / (len(members) - 1)
            proposed[area_id] = lo + round(step * (hi - lo))
    story_by_level = sorted(((areas[a]["level"], a) for a, _ in story))
    story_end = max(areas[a]["level"] for a, _ in story)

    def stage_of(level: int) -> str:
        best = story_by_level[0][1]
        for lv, a in story_by_level:
            if lv <= level:
                best = a
        return best

    # Farming grounds past the end of the story ramp like a Rift C rank: 20 up to 22.
    beyond = sorted((v["level"], k) for k, v in areas.items() if "spawning" in v and "mini_boss" not in v
                    and v["level"] > story_end)

    rows = []
    for area_id, area in areas.items():
        old = area["level"]
        if area_id in proposed:
            kind = "story"
            enemy = proposed[area_id]
            analogue = STAGES[story_district[area_id]][0]
            status = "PROPOSED (levelling band VERIFIED)" if enemy < CAP else "PROPOSED (endgame zone level 20 VERIFIED)"
        elif area_id == "main_city":
            kind, enemy, analogue, status = "hub", 1, "capital hub (Goldcrest: display band [1, 60], no enemies)", "PROPOSED"
        elif "mini_boss" in area:
            kind, enemy, analogue = "lair", HEROIC, "heroic dungeon (mobs pinned to 22)"
            status = "ADAPTED, PROPOSED: our lairs are not reference dungeons"
        elif "world_boss" in area:
            base = proposed[stage_of(old)]
            kind = "world boss arena"
            if base < CAP:
                enemy, analogue = base, f"stage of {stage_of(old)}"
            else:
                enemy, analogue = CAP, "world and raid bosses (level 20)"
            status = "PROPOSED"
        elif "spawning" in area and old > story_end:
            kind = "farming ground"
            i = [k for _, k in beyond].index(area_id)
            step = 0 if len(beyond) == 1 else i / (len(beyond) - 1)
            enemy = CAP + round(step * (RIFT_C_CAP - CAP))
            analogue = "Rift C rank (ramps 20 to 22)"
            status = "ADAPTED, PROPOSED: our grounds are not Rift floors"
        else:
            kind = "farming ground" if "spawning" in area else "arena"
            enemy = proposed[stage_of(old)]
            analogue = f"stage of {stage_of(old)}"
            status = "PROPOSED"
        rows.append((area_id, kind, old, min(enemy, CAP), enemy, analogue, status, area.get("unlock")))

    return rows


def main() -> int:
    audit = load("data/content_audit.json")
    quests = load("client/data/quests.json")["quests"]
    progression = load("client/data/progression.json")
    rows = area_rows()
    enemies_in: dict[str, list[str]] = {}
    for enemy_id, enemy in audit["enemies"].items():
        for place in enemy["places"]:
            enemies_in.setdefault(place["area"], []).append(enemy_id)
    quests_in: dict[str, list[str]] = {}
    for quest_id, quest in quests.items():
        area = quest.get("objective", {}).get("area", "")
        quests_in.setdefault(area, []).append(f"{quest_id} ({quest.get('rewards', {}).get('xp', 0)} XP)")
    high_items = sum(1 for v in audit["items"].values() if v["level"] and v["level"] > CAP)

    lines = [
        "# Area to level mapping v2: APPROVED by the owner 2026-11-17, NOT APPLIED", "",
        "Generated by `tools/content/area_level_proposal.py`; do not edit by hand.",
        "",
        "- **Approved:**",
        "  - story levels 1–20;",
        "  - lairs at 22 (ADAPTED);",
        "  - deep farming grounds at 20–22 (ADAPTED);",
        "  - level 23 only for the Rift's hardest tier, after the Rift is implemented and",
        "    validated;",
        "  - Scorching Wastes **excluded**.",
        "- **The player cap stays 20.** Level 23–24 enemies never enter ordinary farming",
        "  grounds.",
        "- **Not applied:** saves, XP, quests, item requirements and live level scaling are",
        "  unchanged until their own phases are approved. Area levels in",
        "  `client/data/areas.json` are as before.",
        "- **Reference enemy levels and ids stay VERIFIED source data** in",
        "  `data/reference/woc_content_index.json`. The area assignments below are ADAPTED",
        "  or PROPOSED, as labelled.",
        "- **v1** is kept at",
        "  [history/AREA_LEVEL_MAPPING_PROPOSAL_v1_2026-11-17.md](history/AREA_LEVEL_MAPPING_PROPOSAL_v1_2026-11-17.md).",
        "",
        FINDINGS,
        "## The revised rule",
        "",
        "1. **Levelling (story districts 1–4):** each district takes the band of the",
        "   reference zone at the same stage. Areas keep their order and are spread over",
        "   the band. Not a multiplier of old levels.",
        "2. **Endgame story (The Core Facility, Main Control Centre):** level 20, like the",
        "   reference's level-20 zones.",
        "3. **Side content keeps its stage,** except where the reference has harder content",
        "   for the same role:",
        "   - **Lairs** (a mini-boss and its ground) are like heroic dungeons: enemies at",
        "     **22**. ADAPTED: our lairs are not reference dungeons.",
        "   - **Farming grounds past the story's end** ramp like a Rift C rank, from **20 to",
        "     22**. ADAPTED: our grounds are not Rift floors.",
        "   - **World-boss arenas** at the cap are **20**, like reference world and raid",
        "     bosses.",
        "4. **Player-level requirement** for an area: its enemy level, capped at 20. Nothing",
        "   asks for a level the player cannot reach.",
        "5. **Nothing above 22 is proposed now,** by evidence (above), not as a ceiling: 22 is",
        "   the reference's own fairness cap. 23 (Rift S rank) is deferred until the Rift is",
        "   adopted, and then only as a special endgame tier. 24 (Scorching Wastes, a custom",
        "   map) is not adopted.",
        "6. **Endgame progression after 20** comes from item levels (dungeon and raid gear,",
        "   per-copy quality, the Rift Forge), not from character levels. Post-cap XP and",
        "   Prestige are cosmetic.",
        "",
        "| District | Reference anchor | Proposed band |",
        "|---|---|---|",
    ]
    for name, (ref, lo, hi) in STAGES.items():
        lines.append(f"| {name} | {ref} | {lo}–{hi} |")
    lines += [
        "",
        "## Every area",
        "",
        "| Area | Kind | Current Lv | Player level needed (proposed) | Enemy level (proposed) | Reference analogue | Status | Unlock | Enemies | Quests (XP) |",
        "|---|---|---:|---:|---:|---|---|---|---:|---|",
    ]
    for area_id, kind, old, player, enemy, analogue, status, unlock in rows:
        lines.append(
            f"| `{area_id}` | {kind} | {old} | {player} | {enemy} | {analogue} | {status} |"
            f" {json.dumps(unlock) if unlock else '-'} | {len(set(enemies_in.get(area_id, [])))} |"
            f" {'; '.join(quests_in.get(area_id, [])) or '-'} |")
    lines += [
        "",
        "## Conflicts with the reference progression (unchanged from v1, still open)",
        "",
        f"1. **Level cap:** `progression.json` max_level is {progression.get('max_level')}; the",
        "   reference's is 20 (VERIFIED). Post-cap levels are cosmetic.",
        f"2. **Item levels:** {high_items} items have a level above 20. They become item",
        "   levels, not level requirements, when reference items replace them.",
        "3. **Quest XP:** absolute values tuned to the old curve. The reference quest XP",
        "   rule is not yet read: UNKNOWN.",
        "4. **Enemy stats** move to the reference mob formula (RpgMobs) with the levels",
        "   above.",
        "5. **Unlocks:** unaffected, because they are progress-based.",
        "",
        "## Save migration plan (not implemented; waits for approval)",
        "",
        "- **Character level:** a character at or below 20 is unchanged. Above 20, the",
        "  character becomes 20 and its **total earned XP is kept** as lifetime XP. That",
        "  feeds the cosmetic post-cap levels and Prestige, which grant no power, so nothing",
        "  a player earned is lost or turned into power.",
        "- **Area progress, unlocks and item ids:** unchanged.",
        "- **Tests:**",
        "  - every v13 fixture loads under the new version;",
        "  - a level-70 save becomes level 20 with its full XP kept;",
        "  - a level-10 save is unchanged;",
        "  - round trips.",
        "",
        "## Owner decision (2026-11-17)",
        "",
        "The mapping is approved with the boundaries above. Applying it, together with the",
        "save rule and any XP or quest change, needs its own approved phase.",
    ]
    (ROOT / "docs" / "AREA_LEVEL_MAPPING_PROPOSAL.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote docs/AREA_LEVEL_MAPPING_PROPOSAL.md v2 ({len(rows)} areas)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
