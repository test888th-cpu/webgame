# Reference traceability matrix

**Reference:** World of ClaudeCraft at `d2b91e0884cb269422c28d0b42d2a30a01de130a`.

**Rule:** every rule taken from the reference is listed here with its source, our
location and the test that pins it. **What is implemented is not yet connected to
play**: the game still uses its legacy rules (CONTENT_COMPLETENESS_AUDIT.md §1).

**Status values:**

- **VERIFIED:** our module reproduces the reference value, and a test checks it
  against the reference's own test values or values worked from its formulas.
- **UNKNOWN:** not checked.
- **NOT IMPLEMENTED:** reference system with no module here yet.

All tests below are in `client/tests/unit/test_rpg_core.gd`.

## Implemented rules

| System | Reference source | Reference id | Reference value | Our location | Adaptation | Test | Status |
|---|---|---|---|---|---|---|---|
| Rating conversion | `src/sim/types.ts` | HASTE/CRIT/HIT_RATING_PER_PCT | 20 / 20 / 10 rating per 1% | `RpgStats` consts | exact | test_rating_conversions_match_the_reference_tests | VERIFIED |
| HP from stamina | `src/sim/entity.ts` | hpFromStamina | min(s, 20) + 10 × max(0, s − 20) | `RpgStats.hp_from_stamina` | exact | test_stamina_and_intellect_pools | VERIFIED |
| Mana from intellect | `src/sim/entity.ts` | manaFromIntellect | min(i, 20) + 15 × max(0, i − 20) | `RpgStats.mana_from_intellect` | exact | test_stamina_and_intellect_pools | VERIFIED |
| Class base stats and growth (9 classes) | `src/sim/content/classes.ts` | CLASSES | per class (`client/data/rpg_reference.json`) | `RpgStats.base_stats`, `sheet` | exact | test_all_nine_class_sheets_at_levels_1_and_20 | VERIFIED |
| Attack and spell power, crit, dodge, armour from agility | `src/sim/entity.ts` | recalcPlayerStats | 2×Str or Str+Agi or Str; SP 0.5×Int; crit 5% + 0.05%/Agi; spell crit 5% + 0.08%/Int; armour +2/Agi | `RpgStats` | exact | test_level_20_sheets_match_the_worked_reference_values | VERIFIED |
| Melee miss and level gap | `src/sim/types.ts` | meleeMissChance, ABOVE_LEVEL_MISS_PCT | 5% + [0, 2.5, 8, 14]; −0.2%/level below; clamp 0.5–95% | `RpgHitTable` | exact | test_hit_table_matches_the_reference | VERIFIED |
| Spell hit | `src/sim/types.ts` | spellHitChance | 96% base | `RpgHitTable.spell_hit_chance` | exact | test_hit_table_matches_the_reference | VERIFIED |
| Mob against player miss cap | `src/sim/types.ts` | swingMissChance | cap 20% | `RpgHitTable.swing_miss_chance` | exact | test_hit_table_matches_the_reference | VERIFIED |
| Single-roll attack table | `src/sim/combat/auto_attack.ts` | meleeSwing | miss → dodge → parry → block → hit | `RpgHitTable.resolve` | exact | test_hit_table_matches_the_reference | VERIFIED |
| Armour reduction | `src/sim/types.ts` | armorReduction, mobArmorReduction | min(0.75, a/(a + 85L + 400)), mob ramp | `RpgHitTable` | exact | test_armor_reduction_matches_the_reference | VERIFIED |
| Melee and ranged damage | `src/sim/combat/auto_attack.ts` | meleeSwing, rangedSwing | (roll + AP/14 × speed) × mult + bonus; crit ×2 | `RpgDamage` | exact | test_melee_and_ranged_damage | VERIFIED |
| Spell coefficients and crit | `src/sim/types.ts`, `combat/effect_dispatch.ts` | spell coeffs | clamp(cast, 1.5, 3.5)/3.5; DoT duration/15; AoE ×0.333; spell crit ×1.5 | `RpgDamage` | exact | test_melee_and_ranged_damage | VERIFIED |
| Normalised weapon speed | `src/sim/combat/form_swing.ts` | normalized speeds | dagger 1.7, others 2.4 | `RpgDamage.normalized_speed` | exact | test_melee_and_ranged_damage | VERIFIED |
| Rage | `src/sim/types.ts` | rage conversion | c(L) = 0.0091L² + 3.23L + 4.27 | `RpgResources` | exact | test_resources_match_the_reference_tests | VERIFIED |
| Regen tick, mana five-second rule | `src/sim/mana_regen.ts`, `combat/auras.ts` | updateRegen | every 2 s; energy +20, focus +10 | `RpgResources` | exact; ticks ×60 for the game | test_resources_match_the_reference_tests | VERIFIED |
| GCD and swing timer | `src/sim/types.ts`, `combat/auto_attack.ts` | GCD, MIN_GCD | 1.5 s, floor 0.75 s; speed/(1 + haste) | `RpgResources` | exact | test_resources_match_the_reference_tests | VERIFIED |
| Item budgets | `src/sim/item_budget.ts`, `item_level_req.ts` | QUALITY_STAT_MULT, weapon DPS | round(L × q × s × 0.7); DPS 6.7 + 0.3L | `RpgItemBudget` | exact | test_item_budget_matches_the_reference_tests | VERIFIED |
| Mob stats | `src/sim/entity.ts` | createMob | elite HP ×2.3, damage ×1.5; weapon 0.8–1.25 | `RpgMobs.stats` | exact | test_mob_stats_and_xp | VERIFIED |
| XP table, cap, kill XP | `src/sim/types.ts` | XP_TABLE, MAX_LEVEL, mobXpValue, zeroDiff | 20 levels, cap 20 | `RpgProgression` | exact | test_mob_stats_and_xp | VERIFIED |
| Post-cap and prestige | `src/sim/types.ts` | POSTCAP_GROWTH, MAX_VIRTUAL_LEVEL, PRESTIGE_XP_PER_RANK | ×1.1 per level, 200 levels, 23,200 per rank | `RpgProgression` | exact | test_progression_cap_post_cap_and_prestige | VERIFIED |
| Specialisations (27) | `content/talents_classic.ts`, `talents_warrior.ts`, `spec_primary_stat.ts` | spec() / SpecDef, SPEC_PRIMARY_STAT | 3 per class: role, primary stat, signature | `rpg_reference.json` "specs", `RpgClassRegistry` | exact data; display names INTERIM | test_rpg_registry.gd | VERIFIED (data only) |
| Spec level, talent rows | `content/talents.ts`, `talent_rows.ts` | SPEC_UNLOCK_LEVEL = ROW_LEVELS[0], ROW_LEVELS, OPTIONS_PER_ROW | 5; [5, 8, 11, 14, 17, 20]; 3 | `rpg/talent_structure.json` | exact | test_rpg_registry.gd | VERIFIED (data only) |
| Equipment slots | `src/sim/types.ts` | ALL_EQUIP_SLOTS | 13 slots | `rpg/equipment_slots.json`, `RpgEquipmentRules` | exact; legacy Charm slot separate (ADAPTED) | test_rpg_registry.gd | VERIFIED (data only) |
| Class equipment rules | `src/sim/equipment_rules.ts` | MAIL/LEATHER_CLASSES, weapon groups, canDualWield, canDualWieldTwoHand, rogue two-hand ban, resolveEquipSlot, legendary unique | as source | `rpg/equipment_slots.json`, `rpg_reference.json` | exact | test_rpg_registry.gd | VERIFIED (data only) |
| Quality tiers | `src/sim/types.ts` | ItemDef quality union | poor, common, uncommon, rare, epic, legendary | `rpg/quality.json`, `RpgQuality` | exact | test_rpg_items_registry.gd | VERIFIED (data only) |
| Per-copy quality | `src/sim/loot_quality/core.ts` | createLootQuality | draw 0..9999: < 9000 plain; < 9900 t1; < 9990 t2; < 9999 t3; else t4; +2 item levels per tier | `rpg/quality.json`, `RpgQuality` | exact | test_rpg_items_registry.gd | VERIFIED (data only) |
| Item records | `ITEMS` in `src/sim/data.ts` (with the heroic variants added at load) and `STUDIO_CONTENT.items` | ItemDef | 2,263 items (2,221 + 42), every source field | `data/registry/reference_items.json` | exact fields, evaluated; selection per item | test_rpg_items_registry.gd | VERIFIED (data only) |
| Monster records | `MOBS` in `src/sim/data.ts` and `STUDIO_CONTENT.mobs`; MobTemplate in `src/sim/types.ts` | MobTemplate | 379 templates (364 + 15): every source field, 0 UNKNOWN | `data/registry/reference_monsters.json`, `RpgMonsterRegistry` | exact fields, evaluated; classification from flags (VERIFIED), a rare spawn stays rare (owner decision F2); selection per monster; area candidates PROPOSED | test_rpg_monster_registry.gd | VERIFIED (data only) |
| Loot tables and entries | LootEntry in `src/sim/types.ts`; monster `loot`, `HEROIC_BOSS_LOOT`; rollers `loot/loot_roll.ts`, `world_boss.ts` | LootEntry | 400 tables, 1,190 entries, exact chances (weightedLootGroup shares included), group sums not normalised, copper 0.6x to 1.4x; 7 reward sources (data VERIFIED, draw procedure cited, NOT MODELLED) | `data/registry/reference_loot_tables.json`, `reference_loot_entries.json`, `loot_selection.json`, `RpgLootRegistry` | exact; adoption separate (nothing adopted) | test_rpg_loot_registry.gd | VERIFIED (data only) |
| Reward-source execution models (7) | `buddy_drops.ts`, `world_quest_item_slots.ts`, `hoard_loot.ts`, `rift/hoard_reward_roll.ts`, `rift/progression.ts`, `delves/drowned_litany_loot.ts`, `weekly_reward_open.ts` (and their callers) | rollBossBuddyDrops, worldQuestItemRewardForQuest, rollHoardBossDrop, rollHoardReward, addRiftClearGearLoot, drownedLitanyChestItemsForTier, prepareWeeklyRewardOpen | triggers, eligibility, ordered draws, ownership, reset; rng.ts semantics | `reference_loot_tables.json` `execution_model`, `tools/content/reward_models.py` | exact; documented source rules, not game logic | `verify_reward_models.py` (source vs model, every draw compared; reference test goldens; negative controls), test_rpg_reward_models.gd, test_reward_models.py | VERIFIED (data only) |
| Monster count reconciliation | `src/sim/data.ts` MOBS, `studio_content.ts` | n/a | earlier text match 316 = 302 + 14; evaluated 379 = 364 + 15; 63 missed, each classified from the syntax tree | `reference_monsters.json` `count_reconciliation` | n/a | test_rpg_reward_models.gd | VERIFIED |
| Loot relationship graph | all registries | n/a | monster → table → entry → item; quest gates (67, 9 in the overlay's quests); reward source → monsters, items, tables, model; 0 problems | `reference_registry_manifest.json` `loot_graph` | n/a | test_rpg_reward_models.gd | VERIFIED |
| Approximated Math isolation | ECMAScript implementation-approximated functions | n/a | 226 calls at 27 sites, all spatial; 0 reach a registry; one ulp up or down and gross changes alter no registry byte | `data/registry/reference_registry_manifest.json` `math_audit`, `math_perturbation_audit.json` | exact taint tracking; the builder fails on an unconfined decision | test_rpg_loot_registry.gd `test_approximated_math_never_reaches_a_registry` | VERIFIED (evidence) |
| Id namespaces | n/a | n/a | `reference:<id>` and `iron_legacy:<id>`; one shared bare id (`training_dummy`) | `RpgRegistryLoader`, `data/registry/id_collisions.json` | ADAPTED architecture (ours, not the reference's) | test_rpg_registry_loader.gd | VERIFIED (data only) |
| Heroic enemy level | `content/dungeon_difficulty.ts` | heroic tuning `level: 22` | 22 | `heroic_level` on dungeon enemies | exact | test_rpg_monster_registry.gd | VERIFIED (data only) |

## Reference systems not implemented yet

| System | Reference source | Status |
|---|---|---|
| Mob loot roller (independent entries, roll groups, quest gates, money band) | `src/sim/types.ts` LootEntry, `src/sim/loot/loot_roll.ts`, `weighted_loot_group.ts` | NOT IMPLEMENTED as a roller; its tables and rules are recorded as data (REFERENCE_LOOT_REGISTRY.md) |
| Item upgrade (Rift Forge) | `src/sim/rift/progression.ts`, `band_ladder.ts` | NOT IMPLEMENTED (owner decision §5.3) |
| Abilities, specs, talents | `content/classes.ts`, `talent_rows.ts`, `choice_rows.ts` | NOT IMPLEMENTED (SKILL_DATABASE_CATALOG.md) |
| Party loot, world-boss personal loot | `src/sim/loot/*`, `world_boss.ts` | NOT IMPLEMENTED (single player until IL-7) |
| Professions and crafting | `content/professions.ts`, `recipes.ts` | NOT IMPLEMENTED |
| Ranges and distances | `src/sim/types.ts` MELEE_RANGE 5 yd and others | NOT IMPLEMENTED (unit mapping to pixels pending) |

## Reference values not verified (UNKNOWN)

None in the registries at this commit: 0 UNKNOWN values in monsters, items, loot
entries and reward-source data. The two items listed here before are resolved, and
the draw procedures that are not modelled are listed in
[REFERENCE_UNKNOWN_REPORT.md](REFERENCE_UNKNOWN_REPORT.md). Every adaptation is in
[ADAPTATION_REGISTER.md](ADAPTATION_REGISTER.md).

## Levels (owner-approved mapping v2, 2026-11-17; not applied)

| Item | Reference value (VERIFIED) | Source | Our use | Status |
|---|---|---|---|---|
| Player cap | 20 (`MAX_LEVEL`) | `src/sim/types.ts` | cap 20 | VERIFIED; not applied yet |
| Post-cap and Prestige | cosmetic only, to virtual level 200 | `src/sim/progression/xp.ts` | cosmetic | VERIFIED |
| Heroic mobs | level 22 | `content/dungeon_difficulty.ts` | lairs at 22 | ADAPTED (approved) |
| Rift C/B/A | 20–22 (`RIFT_LEVEL_CAP`) | `src/sim/rift/ranks.ts` | deep farming grounds 20–22 | ADAPTED (approved) |
| Rift S | 23 (`RIFT_S_LEVEL`) | `src/sim/rift/ranks.ts` | only with the Rift, after it is implemented and validated | DEFERRED |
| Capital "60" | zone display band and map-schema bound, not a level | `goldcrest.ts`, `src/sim/map_doc.ts` | never used as a level | VERIFIED |

## Reference content intentionally excluded

| Content | Reference source | Records | Reason | Decided |
|---|---|---:|---|---|
| Scorching Wastes zone and its mobs (levels 19–24, boss `ember_of_korzul` 24) | `src/sim/content/scorching_wastes.ts` | 14 mob templates, plus that file's items, quests and NPCs | a custom-map desert outside the reference base world; does not fit the industrial-city world | owner, 2026-11-17 |
