# Content completeness audit: Phase A (repository and reference)

**Date:** 2026-11-17. **Status:** Phase A complete. Phases B–F are **not started**; they
wait on the owner decisions in §5. Nothing is committed.

**Reference:** World of ClaudeCraft
<https://github.com/levy-street/world-of-claudecraft> at
`d2b91e0884cb269422c28d0b42d2a30a01de130a` (unchanged since it was pinned).

- **VERIFIED:** read in the source, or implemented and tested in our game.
- **ADAPTED:** deliberately changed, with a reason.
- **PROPOSED:** suggested, not approved.
- **UNKNOWN:** not verified.

**Where the numbers come from:**

- **Our side:** the harness `client/tests/harness/ContentAudit.gd`. It goes through
  the game's own rules: `LootIndex`, `EnhanceRules` and `ContentDB`. Its report is
  `data/content_audit.json`.
- **Reference side:** text scans, never executed, of its source in
  `data/reference/*.json`. Records the reference builds in code are not seen, so
  **reference counts are lower bounds**.

## 1. Headline

**The current game runs on its own legacy rules, not on the reference.**

- Items, drops, upgrades, skills and the five heroes are all legacy.
- The reference formulas exist in `client/sim/Rpg*.gd` and pass their tests against
  reference values, but **nothing in play uses them yet** (Phase 6 of the adoption).
- **So no category below is reference-complete.** "Implemented" counts are of the
  legacy game.

**Within itself, the current game is consistent** (VERIFIED by the harness):

- 0 content validation errors;
- 0 items with no source;
- 0 enemies placed in no area;
- 0 drops naming a missing item;
- 0 chances outside 0..1;
- 0 items without an icon.

## 2. Coverage, with actual counts

| Category | Reference (scan) | Current game | Built on reference rules | In player Guide | Missing vs reference |
|---|---:|---:|---:|---|---|
| Items | ≥ 1,928 | 305 (249 + 56 catalog) | 0 | the existing Guide covers all 305 | all reference items: not adopted (§5.1) |
| Equipment pieces | ≥ 1,398 (armour 1,213 + weapons 168 + held off-hands 17) | 233 (`type: equipment`) | 0 | yes | 7 of 13 slots missing (neck, shoulder, waist, legs, offhand, ring2, trinket) |
| Skills / abilities | 422 records; 327 in the nine class kits | 45 legacy skills (5 heroes) + 403 moves | 0 | legacy skills only | all nine classes (Phases 3–4) |
| Classes | 9, with 27 specs and 18 talent options each | 5 heroes; 9 class sheets in `rpg_reference.json` (tests only) | stats only, in tests | no | specs, talents, kits |
| Monsters and bosses | ≥ 316 templates (155 elite, 26 rare, 30 boss) | 64 enemies: 28 monster, 11 elite, 5 mini-boss, 11 stage boss, 5 world boss, 3 raid world boss, 1 training dummy | 0 | yes | all reference mobs (§5.1) |
| Zones / areas | about 30 named zone modules, plus dungeons, delves and rifts | 58 areas | 0 | yes ("Maps") | world kept by owner decision; level mapping pending (§5.2) |
| Drop tables | mob `loot` lists: ≥ 744 entries (516 items, 216 money, 230 in exclusive roll groups, 65 quest-gated) | 4,490 drop paths over 63 enemies (own table 551, catalog table 2,516, farming ground 851, field elite 449, world-boss tiers 71 and kills 33, boss lists 19) | 0 | yes, with real chances | the reference loot model is not implemented (§3) |
| Enhancement rules | Rift Forge: 5 steps, essence 2/4/6/8/10, always succeeds, +1 item level each, Rift gear only | workbench +0..+10, success 100% down to 20%, +10% stats per level | 0 | yes | decision §5.3 |
| Shops / quests | many vendors, quests, professions and recipes | 2 shops, 12 quests | 0 | partly | professions and crafting not in the game |

> **Correction (2026-11-17, evaluated registries):** the reference counts in this
> table came from a text parse that missed helper-built records. The evaluated
> counts are 379 monster templates (364 in `MOBS`, 15 in the Studio overlay), 2,263
> items and 1,190 loot entries over 400 tables (REFERENCE_LOOT_REGISTRY.md). The
> figures above are kept as written for the record.

## 3. How drops work: reference vs current (VERIFIED from source)

| | Reference (`src/sim/types.ts` LootEntry, `src/sim/loot/*`) | Current game |
|---|---|---|
| **Roll** | each mob `loot` entry rolls independently at `chance` (0..1) | own table: independent per entry (`LootRules`) |
| **Exclusive groups** | entries sharing a `rollGroup` split **one** draw, so at most one drops | none |
| **Weighted selection** | not used for mob loot. **Correction (2026-11-17):** it is; `weightedLootGroup` turns weights into one roll group's chances when the module loads (Nythraxis's own loot, every heroic append); the roll itself is still the group's single draw | catalog table: chance per roll → category weight → grade weight → item, evenly (`DropTables`) |
| **Quest drops** | `questId`: only while that quest is active | quest rewards are separate |
| **Money** | `copper` base, paid at 0.6×–1.4× | `money: [min, max]` |
| **Bad-luck protection** | none for mob loot | "pity" on some boss drops |
| **Group loot** | personal, round-robin, need/greed and master loot; world bosses roll personal loot per contributor | single player; world-boss tiers |

**Guide policy differs.** The reference's generated Guide (`scripts/wiki/build_content.mjs`)
deliberately **never shows loot or balance numbers** (its spoiler policy). The
owner's Part 8 asks for exact drop rates, which is an ADAPTED choice for our game. The
existing in-game Guide already shows LootIndex's real chances.

## 4. Findings in the current data (VERIFIED by the harness; no value changed)

1. **Hard-to-get drops.** 215 items come only from drops; this table is by best
   source (DROP_RATE_AUDIT.md "Rare drops"):

   | Best chance per kill | Items |
   |---|---:|
   | 1% or more | 163 |
   | 0.1% to 1% | 51 |
   | under 0.1% | 1 |

   - The worst is the legendary *Lion King Crown*: 0.02% per boss kill, about
     5,000 kills on average.
   - Catalog epics from ordinary elites are about 0.0002% per kill (about 515,000
     kills). Their better source is bosses at about 0.14% (about 730 kills).
   - Whether that is intended is a design decision.
2. **Upgrade power gap.** +10 gives +100% of an item's positive stats. Reaching it
   from +0 costs about 11,844 coins on average for a level-1 item, and twice or three
   times that for items of level 51 or 61. The reference's Rift Forge adds at most 5
   item levels. ENHANCEMENT_BALANCE_AUDIT.md has the details.
3. **Correction to my earlier reports.** I wrote that the reference has no
   enhancement equivalent. **It has one:** the Rift Forge (§2).
4. **Reference data gaps: resolved** (ADOPTION_DECISIONS_IMPLEMENTATION.md §1).
   - `faithforged_guard` is the paladin's "Debt of Light", read from source.
   - The 5 unknown loot items are trinkets built by the `trinket()` helper (19 trinkets
     added to the index).

## 5. Owner decisions that block Phases B–F (decided 2026-11-17: see ADOPTION_DECISIONS_IMPLEMENTATION.md)

1. **Scale of adoption.** The reference holds about 1,900 items, 316+ mobs, about 30
   zones, dungeons, raids, delves, rifts, professions, PvP and mounts. That fits a 3D
   open world; our game is 58 side-scrolling areas. The options are:
   - (a) adopt **systems and rules** completely, plus the **content subset** that fits
     our areas: reference items and mobs mapped to our areas, with display names
     renamed (recommended);
   - (b) attempt every reference item and mob, which means many new areas.

   Exact drop rates can only be "reference-verified" for enemies that map 1:1 to a
   reference mob.
2. **Level mapping.** The reference caps at level 20, with post-cap levels to 200; our
   areas run from level 1 to 70. The two-segment remap proposed earlier still needs
   approval.
3. **Enhancement:**
   - (a) adopt the Rift Forge rules (5 steps, always succeeds, +1 item level) for the
     equivalent gear;
   - (b) keep the workbench as an ADAPTED system, with the owner's explicit approval
     and its own balance tests;
   - (c) both, for different gear.
4. **Drop rates in the Guide:** confirm that showing exact chances is wanted, given
   the reference's no-loot policy. Recommended: yes, from LootIndex as now.
5. **Equipment slots:** adopt the 13 reference slots (approved earlier). This needs a
   save migration (v14) and art for 7 new slots.
6. **Godforged:** how it is represented has not been decided.

## 6. Phase plan once decided (not started)

- **B.** Registries for reference items, mobs and drops in our data format. Each record
  keeps its reference id, our id and our display name (NAMING_FRAMEWORK.md).
- **C.** Connect them to play: replace LootRules and DropTables with the reference
  roller (independent entries, roll groups, quest gates, money band), test it against
  the reference's golden files (`tests/parity/golden/l1_loot_distribution.json`,
  `master_loot.json`), and migrate saves.
- **D.** Deterministic balance runs: all nine classes against the same enemies, elites
  and bosses (`client/tests/harness/`).
- **E.** Extend the existing Guide (`LootIndex`) to classes, skills, talents, upgrades
  and progression.
- **F.** Full audit, export and performance.

## 7. The audit documents

| Document | Contents | Made by |
|---|---|---|
| [DROP_RATE_AUDIT.md](DROP_RATE_AUDIT.md) | every drop path with its real chance; rare-drop expectations | `render_content_audit.py` |
| [ITEM_DATABASE_CATALOG.md](ITEM_DATABASE_CATALOG.md) | all 305 current items with their sources | same |
| [MONSTER_BOSS_DROP_CATALOG.md](MONSTER_BOSS_DROP_CATALOG.md) | all 64 enemies, their areas and drop counts | same |
| [ENHANCEMENT_BALANCE_AUDIT.md](ENHANCEMENT_BALANCE_AUDIT.md) | the implemented upgrade table, and the reference's Rift Forge | same |
| [SKILL_DATABASE_CATALOG.md](SKILL_DATABASE_CATALOG.md) | the nine classes' 327 kit abilities, and the 45 legacy skills | `render_reference_catalog.py` |
| [EQUIPMENT_AND_RARITY_CATALOG.md](EQUIPMENT_AND_RARITY_CATALOG.md) | reference slots and qualities against the current game | same |
| [REFERENCE_TRACEABILITY_MATRIX.md](REFERENCE_TRACEABILITY_MATRIX.md) | every reference rule implemented so far, with its test | by hand |
| [CLASS_AND_COMBAT_BALANCE_AUDIT.md](CLASS_AND_COMBAT_BALANCE_AUDIT.md) | what can and cannot be balance-tested now | by hand |
| [PLAYER_GUIDE_DATA_SPEC.md](PLAYER_GUIDE_DATA_SPEC.md) | how the Guide stays one source of truth | by hand |

**To regenerate:** run the harness (header of `ContentAudit.gd`), then both renderers.
