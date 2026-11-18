# Owner decisions 1–7: findings, mappings and status

**Owner decisions:** 2026-11-17. **This document:** written the same day.

**Reference:** World of ClaudeCraft `d2b91e0884cb269422c28d0b42d2a30a01de130a`.

**Labels:**

- **VERIFIED:** read in reference source, or tested here.
- **PROPOSED:** awaiting approval.
- **DONE:** implemented and tested.
- **NOT STARTED.**

## Owner decisions, final reference fidelity audit (2026-11-17), binding for this phase

Recorded as given. The rounds below are kept unchanged for history.

| # | Owner decision | How it is applied |
|---|---|---|
| F1 | `farm_reactor_underworks` (level 21) stays **empty**. No replacement enemy; no source level changed. | Every slot is empty in `monster_area_candidates.json`; the reason is listed. Tested in `test_rpg_monster_registry.gd`. |
| F2 | A rare spawn is **not** a reference mini-boss. Its `rare` source classification is kept; no implicit promotion. | The earlier PROPOSED `proposed_role: mini_boss` is removed from the registry, the accessor (`RpgMonsterRegistry.proposed_role`) and the matrix. The matrix slot is `rare`. Recorded as rejected in [ADAPTATION_REGISTER.md](ADAPTATION_REGISTER.md). Tested: no `mini_boss` anywhere in the registry. |
| F3 | Creatures that do not fit the industrial-city theme stay in the reference registry, as `DEFERRED_THEME`. | 28 monsters are DEFERRED_THEME; none is removed. |
| F4 | The monster selection matrix stays **PROPOSED**; no placement is approved. | Unchanged; tested (no approved slot). |
| F5 | The loot registry stays **data only**; no roller or table in live gameplay. | Unchanged. The legacy loot file hashes are recorded and tested. |
| F6 | All reference ids, source values, relationships and gameplay semantics are preserved. | `source_fields` keeps every field; all tests and freshness checks pass; [REFERENCE_UNKNOWN_REPORT.md](REFERENCE_UNKNOWN_REPORT.md) covers the approximated-Math audit. |

### Owner directive: visual and art overhaul deferred (2026-11-17, binding)

- **Priority now:** gameplay and systems first.
- **Keep in use** until a separate visual-production phase:
  - existing scenes, maps, environments and themes;
  - character sprites and animations;
  - monster, boss and NPC visuals;
  - item icons, equipment visuals and placeholder assets.
- **No visual work for now:**
  - no visual redesign;
  - no asset replacement;
  - no scene restructuring to prepare for art;
  - no cosmetic work while gameplay systems remain incomplete.
- **The future phase** creates original, project-owned assets with documented
  provenance and commercial-use rights:
  - city, districts and environments;
  - every class appearance;
  - monsters, elites, bosses and world bosses;
  - NPCs;
  - items and icons;
  - animations and effects.

  It connects to gameplay data only through stable ids and asset mappings. It must not
  change monster ids or stats, item ids or attributes, NPC function, area progression,
  loot, encounters, progression or saves.
- **Phase gate:** it does not start automatically. When the required gameplay scope is
  complete and validated, readiness is reported, and the owner must explicitly
  authorise that phase.
- **This phase** touches no visual content.

## Owner decisions, round 2 (2026-11-17), and their status

| # | Owner decision | Status |
|---|---|---|
| 1 | Level mapping **not approved** until the Level 20 / 60 question is resolved | **Investigated, VERIFIED:** the player cap is 20; "60" is only a zone display band and the map schema's bound; enemies go to 22 (heroic), 23 (Rift S) and 24 (Scorching Wastes); Prestige and post-cap levels are cosmetic. **Revised proposal v2:** [AREA_LEVEL_MAPPING_PROPOSAL.md](AREA_LEVEL_MAPPING_PROPOSAL.md) (v1 in `history/`). **Nothing migrated.** |
| 2 | Keep the legacy upgrade, isolated to legacy items, clearly labelled; Rift Forge only for Rift gear, with its location rule | PLANNED in B2 (R9) and C1. Not implemented. |
| 3 | Keep existing +1 to +10 on legacy items; no coin refund; no stat conversion; migration tests | PLANNED (PHASE_B2_PLAN.md §6). Not implemented. |
| 4 | Godforged (25 items) → Legendary, as ADAPTED; ids and identity kept | PLANNED in B2 (R4): `rarity: legendary` + `legacy_tier: godforged`. Not implemented. |
| 5 | Interim Charm slot, for legacy only; per-charm mapping proposal later | PLANNED in B2 (R3) and C1. Per-charm proposal: not started. |
| 6 | Order: B2 registries → C1 slots and loot → C2 classes and abilities | B2 plan: [PHASE_B2_PLAN.md](PHASE_B2_PLAN.md) (dependency map, files, tests, save safety). B2 implementation: **not started.** |

## Round 1 status (kept for history)

## Status by decision

| # | Decision | Status |
|---|---|---|
| 7 | Unused PixelFX effects out of the browser build | **DONE** (§7) |
| 4 | Public drop rates, reconciled | **DONE** for the current data (§4); values for adopted content follow it |
| 2 | Level mapping | **PROPOSED**: [AREA_LEVEL_MAPPING_PROPOSAL.md](AREA_LEVEL_MAPPING_PROPOSAL.md), every area, conflicts and save plan |
| 5 | 13 slots | **VERIFIED and PROPOSED** (§5); not implemented |
| 6 | Rarity and Godforged | **VERIFIED and PROPOSED** (§6); not implemented |
| 3 | Rift Forge and the workbench | **VERIFIED and PROPOSED** (§3); not implemented |
| 1 | Systems and content adoption | Phase B1 indexes complete (§1); B2, C, D, E and F **NOT STARTED** |

## 1. Phase B1: reference data indexes

| Index | Count | Notes |
|---|---:|---|
| Ability records | 422 | all 327 class-kit abilities parsed; `faithforged_guard` (paladin, retribution, "Debt of Light") added from source line 305 |
| Item records | 1,947 | 1,928 by text scan, plus 19 trinkets built by the `trinket()` helper (`trinkets.ts`) |
| Mob templates | 316 | 155 elite, 26 rare, 30 boss |
| Mob loot entries | 744 | **every item a loot entry names now has a record.** The five "unknown" items were trinkets. |

Files: `data/reference/woc_abilities_index.json` and `woc_content_index.json`.

**Remaining scan limit:** other helper-built records (for example Rift bands and heroic
variants) may still be missing. Their builder files must be read before those systems
are adopted.

## 3. Rift Forge and the workbench

**Reference, VERIFIED in source:**

| Rule | Value | Source |
|---|---|---|
| Who can upgrade | Rift gear only; others get `not_rift_gear` | `src/sim/rift/progression.ts` |
| Steps | 5 | `RIFT_BAND_MAX_UPGRADE = 5`, `band_ladder.ts` |
| Cost per step | 2, 4, 6, 8, 10 `rift_essence` (`2 + 2 × level`) | `riftUpgradeCost`, `content/rift/items.ts` |
| Success | always; no failure, downgrade or destruction | `progression.ts` upgrade path |
| Effect | +1 item level per step; stats rebuilt from the band ladder | `rebuildRolledStats` |
| Also | gem sockets (`gemSlots`), a separate forge action | `rift` on the item instance |
| Where | near the Rift Forge (`nearRiftForge`) | `rift/forge_gate.ts` |

**The workbench today:** +0 to +10 on any worn item, 100% down to 20% success, coins plus
scrap metal and refined alloy, +10% of the item's stats per level
([ENHANCEMENT_BALANCE_AUDIT.md](ENHANCEMENT_BALANCE_AUDIT.md)).

**PROPOSED disposition:**

- The workbench becomes the **Rift Forge interaction**, with the reference rules, for Rift
  gear only.
- The universal +0 to +10 is retired, so there are never two overlapping systems.

**Prerequisite:** Rift gear and Rift Essence must exist. They come from the reference's
Rift system (rift clears, bands, essence), which is not adopted yet. Until then
**nothing would be upgradable**, so the workbench needs a decision:

- **(a)** keep the legacy workbench active, clearly labelled, until the Rift exists, then
  switch; or
- **(b)** disable upgrading until the Rift exists.

**Existing +N on saves:** the reference has no equivalent outside Rift gear. The
options are:

- keep the bonus frozen on the copy and read it only while legacy items exist; or
- refund the spent materials (the save does not record coins spent).

Owner decision.

## 4. Drop rates: reconciliation of the reported values (VERIFIED)

These values come from LootIndex steps re-multiplied in `docs/DROP_RATE_AUDIT.md`: 2,516
selected-drop paths, 0 mismatches.

| Reported | Exact items | Source and steps | Per kill | Expected kills |
|---|---|---|---:|---:|
| about 730 kills each | `dragonscale_hood`, `gilded_brawler_helm`, `glacier_crown`, `jewelled_crown`, `obsidian_crown`, `phoenix_feather_hat`, `phoenix_tiara` (epic headgear) | boss catalog table: 2 rolls at 100% × headgear 10% × epic 4.8% × 1/7 | 0.13710% | 729 |
| 0.02% | `lion_king_crown` (legendary) | the same table: headgear 10% × legendary 0.2% × 1/2 | 0.019999% | 5,000 |
| 0.0002% | the same 7 epic hats, from **elites** | street table: 8% × headgear 3.4% × epic 0.5% × 1/7 | 0.000194% | ≈ 514,700 |

**How to read these:**

- **Expected kills** = 1/p, an average.
- The chance of at least one drop in N kills is 1 − (1 − p)^N. For 729 kills at
  0.1371% that is about 63%; 50% needs 506 kills and 90% needs 1,679.

**What the Guide shows:** these numbers come from LootIndex, the resolver play uses.
For adopted reference content, a 1:1-mapped enemy keeps the reference's `chance`, and
an adapted one documents its own.

## 5. Equipment slots (VERIFIED and PROPOSED)

**The reference has 13 slots** (`ALL_EQUIP_SLOTS`, `src/sim/types.ts`): mainhand,
offhand, helmet, neck, shoulder, chest, waist, legs, gloves, feet, ring1, ring2,
trinket. Items declare `ring`, which goes into ring1 or ring2 when equipped. The
frozen 11-slot launch list in `launch_paperdoll_slots.ts` is not the live list.

| Current slot (items) | Reference slot | Migration of a worn item |
|---|---|---|
| weapon (48) | mainhand | moves as is |
| head (65) | helmet | moves as is |
| body (46) | chest | moves as is |
| hands (38) | gloves | moves as is |
| feet (39) | feet | moves as is |
| charm (31) | **no direct equivalent** (neck, ring or trinket) | PROPOSED: kept in a legacy charm bag slot until replaced, never dropped |
| — | offhand, neck, shoulder, waist, legs, ring1, ring2, trinket | new: empty on old saves |

**Legacy stats are not reference stats.** Our items use power, crit, max HP, defense
and attack speed; the reference uses str, agi, sta, int, spi, armour and ratings.
Converting them would be invented numbers. **PROPOSED:** under Decision 1, worn legacy
items migrate by slot as above. Reference items, which have reference stats, become
the active itemisation. Legacy items stay readable, with their stats, until
replaced. Nothing is dropped from a save.

**Work (not started):**

- the save format v14;
- the 13-slot equipment UI, with placeholder icons per slot;
- stats moved to RpgStats with gear;
- class armour and weapon proficiency (`equipment_rules.ts`);
- the Guide;
- tests for old and new saves.

## 6. Rarity (VERIFIED and PROPOSED)

The reference's item quality is `'poor' | 'common' | 'uncommon' | 'rare' | 'epic' |
'legendary'` (`src/sim/types.ts`). Separately, each copy of a drop rolls a permanent
loot quality (`src/sim/loot_quality/core.ts`):

| Copy quality | Chance | Budget |
|---|---:|---|
| Ordinary | 90% | none extra |
| Tier 1 | 9% | +2 item levels |
| Tier 2 | 0.9% | +4 item levels |
| Tier 3 | 0.09% | +6 item levels |
| Tier 4 | 0.01% | +8 item levels |

| Current rarity | Reference quality | Internal id | Migration |
|---|---|---|---|
| — | poor | `poor` | new (grey junk) |
| common | common | `common` | same id |
| uncommon | uncommon | `uncommon` | same id |
| rare | rare | `rare` | same id |
| epic | epic | `epic` | same id |
| legendary | legendary | `legendary` | same id |
| **godforged** (25 items) | **none.** "Godforged" appears nowhere in the reference content (0 hits) | — | PROPOSED, needs approval (below) |

**Godforged options** (the 25 items: 6 weapons, 6 charms, 4 hands, 4 body, 3 head,
2 feet):

- **(a)** Retire the tier. Those items become legendary, the reference's top tier, keeping
  their ids and names, and their rarity is recorded as `legendary` with a
  `legacy_tier: godforged` note.
- **(b)** Remove them from drops and keep them as legacy items only.

Not mapped silently. Saves keep the item ids either way.

## 7. PixelFX browser build (DONE)

- **How it works:** `tools/assets/web_export_filter.py` writes the Web preset's
  `exclude_filter`. It leaves out each effect whose recipe `use` says "PROPOSED" (the
  37). CI runs its `check`.
- **Wiring an effect:** change its `use` to name the skill or event that plays it. The
  next `write` ships it.
- **Measured:**
  - `index.pck` is **19.2 MB**; it was 29.4 MB with them and 18.2 MB at HEAD.
  - The remaining +0.9 MB is the 18 class sprite sheets.
  - Exactly the 25 used effect sheets are packed.
  - The browser smoke test passes on that build.
- **Kept as before:** lazy loading, provenance and credits for all 62 effects, and the
  editor and tests still see every effect.
- **The skill → effect mapping** starts empty: no implemented skill uses a new effect
  yet. It is not filled in to look used.
