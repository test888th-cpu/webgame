# Phase B2: shared data registries (plan)

**Date:** 2026-11-17.

**Status** (owner-approved):

- **B2.1 (classes): DONE.**
- **B2.2 (equipment slots): DONE.**
- **R4/R5 (items, quality): DONE.** 2,263 reference items, evaluated from `ITEMS`;
  every item decision pending.
- **R6 (monsters): DONE, validated.** 379 templates, 0 UNKNOWN
  ([REFERENCE_MONSTER_REGISTRY.md](REFERENCE_MONSTER_REGISTRY.md)).
- **R7 (loot): DONE as a data registry.** 400 tables and 1,190 entries
  ([REFERENCE_LOOT_REGISTRY.md](REFERENCE_LOOT_REGISTRY.md)). The roller (`RpgLoot`)
  and any live integration are not started (stop point).
- **Final fidelity audit (2026-11-17): DONE.**
  - the 226 approximated Math calls traced per site, none reaching a registry;
  - owner decisions F1–F6 applied (level 21 empty, no rare → mini-boss, theme
    retained, matrix PROPOSED, loot data only, source preserved);
  - status totals complete.
- **Reward-source execution models (2026-11-17): DONE as data.**
  - All 7 sources are modelled and verified against the source functions, and the
    reference test goldens pass.
  - The monster count is reconciled (316 → 379, every difference classified).
  - The loot relationship graph is valid.
  - No live integration.
- **Visual and art overhaul: deferred** until the gameplay systems are complete, by
  owner directive ([ADOPTION_DECISIONS_IMPLEMENTATION.md](ADOPTION_DECISIONS_IMPLEMENTATION.md)).
- All of these are data only and not used by gameplay.
- R2 (abilities, talents), R8 (areas), R9 (upgrade rules) and R10 (Guide views) are
  not started.

**Placement change (owner decision):** the large reference registries live in
`data/registry/`, outside the Godot project, so the web build does not carry them.
Registry loading is in `client/sim/RpgRegistryLoader.gd`, not in `ContentDB`.

**Reference:** World of ClaudeCraft `d2b91e0884cb269422c28d0b42d2a30a01de130a`.

**Goal:** one authoritative registry per domain. Gameplay (`client/sim/`), the UI
(`client/scenes/`), the Guide, the audit tools and the tests all read it. No second
copy is maintained by hand.

## 1. Principles

1. **The registries are the one source of truth.** The data lives in `client/data/`
   (rule in CLAUDE.md "Boundaries": content is data, validated on load). Typed
   accessors live in `client/sim/`, reached through `ContentDB`, like
   `ItemCatalog` today.
2. **Every reference-backed record carries `ref: {id, file, commit}`.** It also
   carries our stable `id` and our `name`, which is original (NAMING_FRAMEWORK.md),
   and a `status`: VERIFIED, ADAPTED or LEGACY.
3. **Nothing is typed twice.** The reference-derived data is generated from
   `data/reference/*` indexes and the reference source at the pinned commit, by
   tools that run offline. The generated JSON is committed. A freshness test fails
   when it is stale. Hand-written data is only:
   - our ids;
   - display names;
   - the area mapping;
   - ADAPTED values, each with a reason.
4. **Legacy is labelled, not mixed.** Legacy items, their +N upgrades, Godforged
   and Charm stay in the existing files, flagged `legacy: true`. New rules refuse
   them, and legacy rules refuse new items (owner Decisions 2–5).
5. **The Guide reads registries and rules only.** It never reads constants of its
   own.

## 2. Dependency map

```
reference indexes (data/reference/*.json, pinned commit)
        |
        v
[R1] classes + specs ------------------> [R2] abilities + talents
        |                                      |
        v                                      v
[R3] equipment slots + proficiency  ---> [R4] items (reference + legacy)
        |                                      |
        |                                      +--> [R5] quality and per-copy quality
        v                                      |
[R6] monsters and bosses (templates) ---> [R7] loot tables (reference entries,
        |                                      roll groups, quest gates)
        v                                      |
[R8] zones and areas (levels: blocked          v
     on Decision 1 approval)            [R9] upgrade rules (Rift Forge; legacy
        |                                      workbench, isolated)
        +------------------+-------------------+
                           v
                  [R10] Guide data views (no new data)
```

- **Build order:** R1 → R3 → R4/R5 → R6 → R7 → R9 → R2 → R10.
- **R8 levels wait** for the owner's approval of AREA_LEVEL_MAPPING_PROPOSAL.md v2.
  Until then R8 carries the current levels unchanged.
- **C1** (slots and loot) needs R3, R4, R5 and R7.
- **C2** (classes and abilities) needs R1 and R2.

## 3. Registries

| Id | Registry | Data file (new unless noted) | Accessor | Source |
|---|---|---|---|---|
| R1 | classes, specs, resources, base stats | `client/data/rpg_reference.json` (exists; extend with specs) | `RpgStats` (exists), new `ClassRegistry.gd` | `content/classes.ts`, spec defs |
| R2 | abilities, ranks, talents | `client/data/rpg/abilities.json`, `talents.json` | `AbilityRegistry.gd` | `classes.ts`, `paladin_core_abilities.ts`, `priest.ts`, `talent_abilities_v2_*.ts`, `talent_rows.ts`, `choice_rows.ts` |
| R3 | 13 equipment slots, armour and weapon proficiency, the legacy Charm slot | `client/data/rpg/equipment_slots.json` | `EquipmentRules.gd` | `types.ts` ALL_EQUIP_SLOTS, `equipment_rules.ts` |
| R4 | items | reference items: `client/data/rpg/items.json` (generated); legacy: `items.json` and `item_catalog.json` (exist; add `legacy`) | `ContentDB.item()` (exists, one lookup for both) | `content/items.ts` and zone item modules |
| R5 | quality tiers (poor to legendary), per-copy quality (90 / 9 / 0.9 / 0.09 / 0.01%) | `client/data/rpg/quality.json` | `RpgQuality.gd` | `types.ts`, `loot_quality/core.ts` |
| R6 | mob templates, elite and boss flags | `client/data/rpg/mobs.json` (generated subset mapped to our enemies) | `RpgMobs` (exists) | zone modules, `entity.ts` createMob |
| R7 | loot entries (chance, rollGroup, questId, copper band) | in each mob record | `RpgLoot.gd` (roller), extended `LootIndex` (resolver) | `types.ts` LootEntry, `loot/loot_roll.ts`, `weighted_loot_group.ts` |
| R8 | areas and their levels | `client/data/areas.json` (exists) | `AreaRules` (exists) | zone `levelRange`; Decision 1 |
| R9 | Rift Forge rules; legacy workbench | `client/data/rpg/rift_forge.json`; `progression.json` "enhance" (exists, marked legacy) | new `RiftForge.gd`; `EnhanceRules` (exists, legacy-only) | `rift/progression.ts`, `band_ladder.ts`, `forge_gate.ts` |
| R10 | Guide views | none: reads R1–R9 | `GuidePages.gd`, `GuideScreen.gd` (exist) | — |

## 4. Files B2 will modify or add

**Modify:**

- `client/sim/ContentDB.gd`: load and validate the new registries.
- `client/sim/ItemCatalog.gd`: mark legacy items.
- `client/sim/EnhanceRules.gd`: refuse non-legacy items, and say that it is legacy.
- `client/sim/LootIndex.gd`: resolve reference loot entries.
- `client/data/items.json` and `item_catalog.json`: `legacy: true`. Godforged
  becomes `rarity: "legendary"` plus `legacy_tier: "godforged"` (owner Decision 4,
  ADAPTED).
- `client/data/progression.json`: the enhance block marked legacy.
- `client/data/rpg_reference.json`: specs.
- `client/tests/harness/ContentAudit.gd`: cover the registries.
- `tools/content/render_*.py`.
- Docs: CONTENT_COMPLETENESS_AUDIT.md, REFERENCE_TRACEABILITY_MATRIX.md,
  ADOPTION_DECISIONS_IMPLEMENTATION.md, CHANGELOG.md.

**Add:**

- `client/data/rpg/*.json`, as listed in §3.
- `client/sim/ClassRegistry.gd`, `AbilityRegistry.gd`, `EquipmentRules.gd`,
  `RpgQuality.gd`, `RpgLoot.gd`, `RiftForge.gd`.
- `tools/content/build_reference_registries.py`: generates the reference-derived
  JSON from the pinned source, with a freshness check.
- Tests: `client/tests/unit/test_registry_*.gd`.

**Not touched in B2:**

- scenes, maps, art and presentation, except the Guide pages in E;
- player levels, XP and item level requirements (owner Decision 1);
- the save format (that is C1).

## 5. Test plan

| Area | Tests |
|---|---|
| Registry integrity | unique ids across files; every `ref` resolves to a reference index record at the pinned commit; required fields; enums (slot, quality, school, resource) valid |
| Freshness | generated registries equal a fresh generation (like `provenance.py check`) |
| Reference parity | values checked against reference tests or golden files where they exist, for example `tests/parity/golden/l1_loot_distribution.json` and `master_loot.json` for the loot roller in C1 |
| Legacy isolation | the legacy upgrade refuses a reference item; the Rift Forge refuses non-Rift gear and refuses away from the forge; a reference item cannot go in the Charm slot |
| Godforged | 25 items read as legendary with `legacy_tier: godforged`; no rule reads a `godforged` rarity any more; drop tables have no conflicting rarity weight (the old `godforged` weight is removed only where it is 0, or reported) |
| Guide parity | each Guide page's figures equal the registry and resolver values (spawned view compared to the rules) |
| Regression | the full suite (996 today) stays green; the content audit keeps 0 problems |

## 6. Save-migration safety plan (for C1, when the save version changes)

1. **Fixtures first.** Before any format change, commit save fixtures at v13:
   - a new game;
   - mid-game with +N items;
   - with Godforged and charm items;
   - level 70.

   Each test loads and round-trips them.
2. **Migration is additive.** v14 adds:
   - the 13-slot map;
   - per-copy quality;
   - a legacy section.

   It never deletes a field it cannot map. Unknown items are parked, never dropped
   (the existing `test_item_safety` rule).
3. **Legacy data is kept exactly:**
   - legacy items keep their ids, stats and `+N`;
   - charms stay in the interim Charm slot;
   - the five legacy slots map to mainhand, helmet, chest, gloves and feet.
4. **No level or XP change** until Decision 1 is approved. Then it is a separate
   version step with its own fixtures.
5. **Proof:** tests load every fixture, compare the item ids, `+N`, money and progress
   before and after, and save and reload. A failure blocks the change.
6. **Rollback:** the old loader path stays readable for one version; the migration
   is pure (`PlayerProfile.migrate`).
