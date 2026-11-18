# RPG core: Phase 1 audit, specification and Phase 2 foundation record

**Direction (owner-approved):** World of ClaudeCraft is the authoritative reference
for **all** gameplay and RPG systems.

- The existing world, scenes and visual identity stay.
- Every player-facing name becomes original content.
- The title may change, after research and approval.

**What this phase did not change** (no gameplay code, data or save format):

- `ContentDB` does not load the new modules or data, so nothing in the game
  calls them.
- No commit, push, merge or deploy.

Records this builds on, kept unchanged apart from a correction note:

- `docs/REFERENCE_LOCKED_GAMEPLAY_SPEC.md` (the first audit; §0 there records the
  corrections made here).
- `docs/SIX_CLASS_PHASE1_ARCHITECTURE.md` (Phase 0 baseline and earlier decisions
  D1–D10).

Labels used below:

- **REFERENCE-EXACT:** reproduced from reference source.
- **REFERENCE-ADAPTED:** derived from a reference value or formula, with the
  transformation shown.
- **ORIGINAL-CONTENT:** names, lore and presentation that are ours.
- **UNMAPPED:** no reliable reference equivalent.
- **UNKNOWN:** not established from the evidence read.

| Item | Value |
|---|---|
| Reference | `levy-street/world-of-claudecraft` @ **`d2b91e0884cb269422c28d0b42d2a30a01de130a`** (2026-11-16). Every value in this document and in the code below comes from this commit |
| Project | `claude/stoic-cori-i4r01i` @ `8fdd45b`, plus the uncommitted files listed in §9 |

## 1. Adoption inventory (Phase 1)

The reference simulation (`src/sim/`) has 1,565 TypeScript files in 30 areas. The
owner's list (classes, combat, skills, weapons and equipment, items and progression,
enemies and encounters, PvE and PvP) covers the following:

| System | Reference location | Status |
|---|---|---|
| Classes, base stats, resources | `content/classes.ts` (`CLASSES`), `entity.ts` | traced, **ported** (§6) |
| Derived stats, ratings | `entity.ts` `recalcPlayerStats`, `types.ts` | traced, **ported** |
| Hit table, armor, crit | `types.ts`, `combat/auto_attack.ts` `meleeSwing`/`rangedSwing` | traced, **ported** |
| Spell damage and crit | `combat/spell_combat.ts`, `combat/effect_dispatch.ts`, `types.ts` coefficients | formulas ported; per-spell effect dispatch not yet |
| Resources and regen | `combat/auras.ts` `updateRegen`, `mana_regen.ts`, `types.ts` rage | traced, **ported** |
| GCD and swing timer | `types.ts`, `auto_attack.ts` | traced, **ported** |
| Abilities and ranks | `content/classes.ts` `ABILITIES` (336 here; more in `content/talent_abilities_v2*.ts`, `paladin_core_abilities.ts`) | structure traced; per-ability porting is Phase 4 |
| Auras, buffs, debuffs, CC, DoTs | `combat/auras.ts`, `combat/cc.ts`, `combat/periodic_harm.ts`, `combat/aura_stacking.ts` | located, not yet traced |
| Talents and specs | `content/talents.ts`, `content/talent_rows.ts` (`ROW_LEVELS` = 5, 8, 11, 14, 17, 20; spec at 5) | structure traced |
| Weapons and equipment rules | `equipment_rules.ts`, `combat/form_swing.ts`, `types.ts` `WeaponInfo` | traced |
| Item budgets, quality, required level | `item_budget.ts`, `item_level.ts`, `item_level_req.ts`, `loot/`, `loot_quality/` | budget **ported**; loot not yet |
| Enemies | `entity.ts` `createMob`, `types.ts` `MobTemplate`, `mob/`, `mob_combat.ts` | stats **ported**; AI not yet |
| Bosses and encounters | `encounters/`, `instances/`, `MobTemplate` mechanic blocks (slams, swipe, boulders: every, windup, radius, min/max) | located; per-boss porting is Phase 5 |
| Progression and XP | `types.ts` `XP_TABLE`, `MAX_LEVEL`, `mobXpValue`, virtual levels, prestige; `progression/` | XP **ported**; post-cap not |
| PvP | `pvp/power.ts` (WARFARE ratings, Vitality), `pvp/` honor | traced |
| Threat | `combat/threat_modifiers.ts`, ability `threat` fields | located, not yet traced |
| Pets (Ranger) | `pet/` | located, not yet traced |
| Outside the listed scope (not adopted unless asked) | professions, market, mail, guilds, mounts, seasonal, delves, rifts, minigames, moderation, social, painted towns | listed for completeness |

## 2. Corrections and completed traces (REFERENCE-EXACT)

| Item | Formula or value | Source |
|---|---|---|
| **Melee and ranged crit** (corrects the earlier spec, which omitted the base) | 0.05 + Agi × 0.0005 + shared bonus (+0.03 in berserker stance) | `entity.ts` (recalc, line 775) |
| Spell crit | 0.05 + Int × 0.0008 + shared bonus + spell-crit auras | `combat/spell_combat.ts` `SPELL_CRIT_BASE`, `SPELL_CRIT_PER_INT` |
| Regen tick | every 2 s (`tickCount % 40` at 20 ticks/s) | `combat/auras.ts` `updateRegen` |
| Energy | +20 per tick | same |
| Focus | +10 per tick (× hunter bonuses) | same |
| Rage decay | −2 per tick, out of combat only | same |
| Health regen out of combat | Sta × 0.3 + 2 per tick | same |
| Mana regen | (Spi / 3 + 4 + floor(L / 5)) × (1 + bonus) per tick; 30% while the five-second rule holds | `mana_regen.ts` |
| Swing timer | weapon speed × interval mult / (1 + haste); off hand its own | `auto_attack.ts` line 223 |
| Instant specials | normalized speed: dagger 1.7, else 2.4 | `combat/form_swing.ts` |
| Ranged shot | roll + RAP / 14 × speed; miss only (no dodge or parry); crit ×2; wands ignore armor | `auto_attack.ts` `rangedSwing` |
| Mob stats | HP = (hpBase + hpPerLevel × (L − 1)) × (2.3 if elite); damage = (dmgBase + dmgPerLevel × (L − 1)) × (1.5 if elite), weapon 0.8×–1.25×; armor = armorPerLevel × (L − 1) | `entity.ts` `createMob` |
| Required level | explicit, else the source level for rare and up; defaults rare 12, epic 18, legendary at the cap | `item_level_req.ts` |
| XP for a level | `XP_TABLE[min(L − 1, 19)]`; past the cap a lifetime counter drives cosmetic virtual levels at ×1.1 per level (`POSTCAP_GROWTH`), plus prestige ranks | `types.ts` |
| The 20% mob-miss cap | `min(meleeMiss, 0.2)`; never binds, because melee miss saturates at 19% | derived |

## 3. Level cap (owner asked for a defensible strategy)

**What the reference supports (VERIFIED):**

- Real levels 1–20: the XP table, ability ranks up to level 20, talent rows at
  5–20, item levels about 1–37 including heroic and raid tiers.
- Beyond 20: post-cap virtual levels, which are cosmetic, plus prestige.

**Two kinds of reference rule:**

- **Closed-form in level**, so they can be evaluated at any level without new
  coefficients:
  - class stats (base + per level);
  - HP and mana;
  - armor DR (`85L + 400`);
  - mob stats;
  - weapon DPS (`6.7 + 0.3L`);
  - stat budget (`L × q × s × 0.7`);
  - rage conversion;
  - kill XP (`45 + 5L`).

  Evaluating them past 20 keeps the reference's internal ratios. For example, a
  base-stat warrior's armor DR against an equal-level attacker is 14.5% at Lv 20
  and 14.3% at Lv 70.
- **Discrete tables that stop at 20:**
  - the XP table;
  - every ability's rank list and learn level;
  - talent rows;
  - all authored items and enemies.

  Extending them to 70 means writing about 50 new XP entries, new ranks for every
  ability and new talent rows. The reference provides none of that, so it would be
  **invented data**.

**Options:**

- **(A) Adopt the reference cap of 20** (REFERENCE-EXACT everywhere).
  - Remap the existing content levels 1–70 onto 1–20. That is a content-placement
    decision, not a balance coefficient; for example, area level → round(1 + (L −
    1) × 19 / 69), reviewed area by area.
  - Use the reference's post-cap virtual levels and prestige for long-term
    progression.
- **(B) Keep 70.** The closed-form rules extrapolate (label: REFERENCE-ADAPTED,
  "formula evaluated past its data range"), but ranks, talents and XP 21–70 need an
  approved extension basis.
  - The only reference curve past 20 is `POSTCAP_GROWTH` 1.1, which the reference
    uses for cosmetic levels. Using it for real levels would be a repurposing and
    must be labelled.

**Recommendation: A.** It is the only option with no invented data. Area and quest
levels change (§7), stories and maps do not. **Needs approval.**

## 4. Class mapping

| Class (ORIGINAL names to come) | Reference basis | Status |
|---|---|---|
| Warrior (sword) | `warrior` class: arms and protection specs, rage, the warrior kit | REFERENCE-EXACT mechanics |
| Assassin (dual daggers) | `rogue` class: energy, combo points, stealth, poisons, dual wield, `backstab` needs a dagger | REFERENCE-EXACT. Under the new direction these are reference systems to adopt, not invent |
| Berserker (axe) | `warrior` **fury spec**: berserker stance, enrage, Titan's Grip, `whirlwind`; shares the warrior base stats and kit | needs a decision: in the reference this is a spec of Warrior, not a class (§8 C2) |
| Lancer (spear) | **none**. The reference "lance" is a world-boss quest minigame (`lance_trial.ts`, the Shardpike); its spear is a plain crafted two-hander (`profession_items.ts`) | **UNMAPPED** (§8 C1) |
| Mage (staff) | `mage` class: mana, schools, cast times, the mage kit | REFERENCE-EXACT. The old Story Bible "no magic" rule is now content to rewrite (ORIGINAL-CONTENT) |
| Ranger (bow) | `hunter` class: focus, pets, ranged attack as a class property (`ranged: {5–9, 2.3 s, 35 yd}`), melee main hand | REFERENCE-EXACT, but the bow is not an item in the reference (§8 C3) |

The approved "one weapon family per class" rule is stricter than the reference's
archetype pools. It can be expressed as `requiredClass` data, the reference's own
field, without new numbers.

## 5. Grades and enhancement

| Our grade | Reference quality | Notes |
|---|---|---|
| Common (white) | `common` | the reference gives commons **0 primary stats** (armor or weapon damage only) |
| Uncommon (green) | `uncommon` (0.55) | |
| Rare (blue) | `rare` (0.8) | |
| Epic (gold) | `epic` (1.0) | |
| Legendary (red) | `legendary` (1.9) | |
| Godforged (cyan) | **none** | UNMAPPED (§8 G1). The reference's per-copy "Transcendent" quality, or its raid-tier item level, are the nearest ideas, not grades |

**Enhancement +0 to +10:** the reference has none. Its nearest mechanics are
per-copy loot quality (+2 item levels per tier, applied through the same budget) and
enchants. Options for +0 to +10 are in §8 G2. No stat change is proposed until one is
chosen.

## 6. Phase 2: new core modules (implemented and tested, not connected)

All modules are pure static functions in `client/sim/`, covered by the purity test.
The constants carry their reference names in comments.

| File | Contents (all REFERENCE-EXACT) | Reference source |
|---|---|---|
| `client/sim/RpgStats.gd` | rating conversions; base + per-level stats; `hp_from_stamina`; `mana_from_intellect`; AP rules (2 × Str, Str + Agi, Str); ranged AP 2 × Agi; SP 0.5 × Int; crit, spell crit and dodge; armor + 2 × Agi; max HP; resource pool; `sheet()` | `entity.ts`, `types.ts`, `spell_combat.ts` |
| `client/sim/RpgHitTable.gd` | above-level miss table [0, 2.5, 8, 14]; melee miss; spell hit; swing miss (mob cap); armor DR (85L + 400, cap 75%); mob armor ramp; mob dodge; crit vs level; single-roll `resolve` | `types.ts`, `auto_attack.ts` |
| `client/sim/RpgDamage.gd` | weapon roll; melee hit (roll + AP / 14 × speed, crit ×2); ranged hit; after armor (at least 1); normalized speed; spell coefficients (direct, DoT, AoE 0.333); spell crit ×1.5; dual-wield constants | `auto_attack.ts`, `effect_dispatch.ts`, `form_swing.ts`, `types.ts` |
| `client/sim/RpgResources.gd` | rage conversion, from dealing, from taking; spirit and mana regen; energy, focus and rage-decay tick values; health regen; GCD (1.5, floor 0.75); swing interval | `types.ts`, `mana_regen.ts`, `auras.ts`, `auto_attack.ts` |
| `client/sim/RpgItemBudget.gd` | `QUALITY_STAT_MULT`, `SLOT_STAT_MULT`, `QUALITY_ILVL_BONUS`; `primary_stat_budget`; `weapon_dps_budget` (2H ×1.15); item level; `scale_weapon_damage`; required-level defaults | `item_budget.ts`, `item_level_req.ts` |
| `client/sim/RpgMobs.gd` | `createMob` stats (elite ×2.3 HP, ×1.5 damage; 0.8–1.25 spread); `zero_diff`; `xp_value`; `XP_TABLE`; `xp_for_level` | `entity.ts`, `types.ts` |
| `client/data/rpg_reference.json` | warrior, rogue, hunter and mage class data (base stats, per level, HP, mana, resource, AP rule, ranged weapon), with source and commit | `content/classes.ts` |
| `client/tests/unit/test_rpg_core.gd` | 9 tests. Expected values are the reference's own test values (`tests/mana_regen.test.ts` 28 / 42 / 8 / 13; `tests/item_level.test.ts` 0 / 6 / 7; `tests/combat_rating.test.ts` 0.075 / 0.01 / 0.05 and miss(20, 23) = 0.19) and its formulas worked by hand (Lv 20 warrior: HP 812, armor 356, AP 122, crit 6.95%; mage: mana 1,491, SP 41, spell crit 11.48%; armor DR 14.495%; swing 20.93) | |

**Test run** (Godot 4.7.2):

- `godot --headless --path client --script res://tests/TestRunner.gd`: **984
  passed, 0 failed** (975 existing + 9 new).
- `gdformat --check .` and `gdlint .`: clean (278 files).
- The first run had 2 failures, both wrong expectations in the new test file, not
  module errors:
  - The 20% mob-miss cap cannot bind, because melee miss saturates at 19%.
  - An XP-table index was off by one.
  - Both were fixed to match the reference (`xp_for_level` now mirrors
    `xpForLevel`).

**Not yet ported** (later phases):

- Ability effect dispatch, auras, CC, DoTs and threat.
- Talents and specs.
- Pets.
- Mob AI and boss mechanics.
- Loot rolls.
- WARFARE PvP ratings.
- Post-cap progression.

## 7. Migration impact (design; nothing migrated)

Fields VERIFIED in `PlayerProfile` (save v13): hero, name, level, xp, money,
equipment, inventory, enhance, quests, defeated, area, hp, tutorial, street memory,
hotbar, world boss rounds, lairs.

| Data | Impact | Proposed rule (needs approval) |
|---|---|---|
| hero, job | Classes replace jobs; heroes become appearance (Phase 1 D2) | v14 adds `class` (empty means chosen once on load); the hero stays as appearance |
| level, xp | If cap 20 (option A), old levels 1–70 map to 1–20 | Map by the same content transform, keep the old level in an `archive` block |
| equipment and inventory ids (305) | Ids kept; stats re-budgeted; names become display names | No id change; the item's data changes. Unknown ids go to a `dormant_items` list, not dropped (fixes today's silent drop) |
| enhance (+0 to +10) | Depends on §8 G2 | Keep the levels in `archive` until decided |
| money, quests, defeated, area | Kept; area and quest levels move with the remap | No player-visible loss |
| world boss and lair state | Kept | |
| Fixtures | Copies of v1–v13 saves (the existing migration tests) | Every rule tested on copies only |

## 8. Decisions needed (genuine gaps only)

- **L1 Level cap:** option A (reference cap 20 + content remap + post-cap virtual
  levels), recommended, or option B (keep 70 with an approved extension basis).
- **C1 Lancer:** UNMAPPED.
  - (a) Warrior arms mechanics with a two-handed spear (the reference's two-hand
    rules; the same kit as Warrior: no distinct mechanics).
  - (b) Replace Lancer with a reference class (paladin, shaman, druid, priest or
    warlock): a roster change.
  - (c) Design a new Lancer kit: invented, so it needs its own approval.
- **C2 Berserker:** the reference has it as the warrior's fury spec.
  - (a) Berserker = the warrior class locked to fury; Warrior = arms and
    protection. One class definition, two roster entries.
  - (b) Merge them into Warrior with a fury spec: a roster change.
- **C3 Ranger's bow:** a class property in the reference (hunter `ranged`), not an
  item.
  - (a) Keep that model, with the bow item purely as the visual.
  - (b) Bow items carrying `WeaponInfo` (the reference's weapon shape, applied to a
    ranged slot it does not have): an adaptation.
- **G1 Godforged:** UNMAPPED. Treat it as legendary at a higher source item level
  (the reference raid-tier model), or as a separate tier with an approved basis.
- **G2 Enhancement:** (a) retire it (archive the levels); (b) re-express each +N
  as reference per-copy quality steps (+2 item levels each); (c) keep it as a
  cosmetic-only feature.
- **N1 Naming (Phase 3):** approve a naming approach (a new naming bible,
  replacing the Story Bible's names) before content renaming starts.
- **T1 Title (Phase 8):** research with web and store searches is scheduled last,
  per your sequence; nothing is renamed before your approval.

## 9. Working tree after this phase

All of these are untracked new files; no existing file was modified:

- `docs/REFERENCE_LOCKED_GAMEPLAY_SPEC.md`
- `docs/SIX_CLASS_PHASE1_ARCHITECTURE.md`
- `docs/RPG_CORE_PHASE1_SPEC.md`
- `client/data/rpg_reference.json`
- `client/sim/Rpg{Stats,HitTable,Damage,Resources,ItemBudget,Mobs}.gd` with their
  `.uid` files
- `client/tests/unit/test_rpg_core.gd` with its `.uid`

`docs/REFERENCE_LOCKED_GAMEPLAY_SPEC.md` gains only a §0 correction note.
