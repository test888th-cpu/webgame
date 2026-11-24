# Roster, progression, equipment and grades: reference-based specification

**Status: specification only (proposals for approval).**

- No gameplay, data, class, save or item change was made.
- The six `Rpg*` modules and `client/data/rpg_reference.json` stay isolated and are
  not connected to the game.
- Nothing was committed or pushed.

Reference: `levy-street/world-of-claudecraft` @
**`d2b91e0884cb269422c28d0b42d2a30a01de130a`** (all values from this commit).

Related records: `docs/RPG_CORE_PHASE1_SPEC.md`,
`docs/REFERENCE_LOCKED_GAMEPLAY_SPEC.md`, `docs/SIX_CLASS_PHASE1_ARCHITECTURE.md`,
`docs/NAMING_FRAMEWORK.md` and `docs/TITLE_RESEARCH.md`.

Labels used below:

- **REFERENCE-EXACT:** reproduced from reference source.
- **REFERENCE-ADAPTED:** derived from a reference value or formula, with the
  transformation shown.
- **ORIGINAL-CONTENT:** names, lore and presentation that are ours.
- **UNMAPPED:** no reliable reference equivalent.
- **UNKNOWN:** not established from the evidence read.

## 1. What the reference actually has (VERIFIED)

**Nine classes** (`src/sim/types.ts` `PlayerClass`), each with three
specialisations:

- **Source files:** `src/sim/content/talents_warrior.ts` and
  `src/sim/content/talents_classic.ts`; signatures via `spec(...)`.
- **When:** the spec is picked at Lv 5; talent rows open at
  `ROW_LEVELS = [5, 8, 11, 14, 17, 20]` (`src/sim/content/talent_rows.ts`).

| Class | Specs (internal id, role) | Resource | Armor | Weapons |
|---|---|---|---|---|
| warrior | arms (dps), fury (dps), prot (tank) | rage | mail | warrior archetype; fury may dual-wield (Titan's Grip) |
| rogue | assassination, combat, subtlety (all dps) | energy | leather | warrior and rogue archetypes; dual wield; no two-handers |
| hunter | beast_mastery, marksmanship, survival (all dps) | focus | leather | warrior and rogue archetypes in melee; **ranged attack is a class property** (`CLASSES.hunter.ranged` 5–9, 2.3 s, 35 yd) |
| mage | arcane (healer), fire (dps), frost (dps) | mana | cloth | caster archetype (staff); a class wand ranged attack (`CLASSES.mage.ranged` 3–6, 1.8 s, 30 yd, arcane) |
| paladin | holy (healer), protection (tank), retribution (dps) | mana | mail | warrior and caster archetypes |
| priest | discipline (healer), holy (healer), shadow (dps) | mana | cloth | caster archetype |
| shaman | elemental (dps), enhancement (dps), restoration (healer) | mana | mail | warrior and caster; enhancement dual-wields |
| warlock | affliction, demonology, destruction (all dps) | mana | cloth | caster archetype |
| druid | balance (dps), feral (tank), restoration (healer) | mana (forms: rage, energy) | leather | caster archetype |

Sources for the table:

- Armor: `src/sim/equipment_rules.ts` (`MAIL_CLASSES`, `LEATHER_CLASSES`,
  `maxArmorTypeForClass`).
- Weapons: `WARRIOR_WEAPON_CLASSES`, `CASTER_WEAPON_CLASSES`,
  `ROGUE_WEAPON_CLASSES`, `canDualWield` (same file).
- Weapon proficiency is **shared by archetype, not locked to one family per
  class**.

## 2. Recommended reference-native roster (six classes)

The reference shapes the earlier six classes as follows:

- **Berserker** is the warrior's **fury spec**, not a class.
- **Lancer** has **no reference class**. The "lance" in the reference is a
  world-boss quest minigame (`src/sim/lance_trial.ts`), and the only spear is a
  plain crafted two-hander (`src/sim/content/profession_items.ts`, 30–41 damage,
  3.2 s).
- **Ranger's** bow is the hunter's class ranged attack.
- **Mage** follows `CLASSES.mage`.

Keeping six *classes* therefore means six reference classes.

**Recommended (PROPOSED):**

| # | Roster entry (display names are ORIGINAL-CONTENT later) | Reference class | What the earlier identity becomes |
|---:|---|---|---|
| 1 | Warrior | `warrior` (arms, fury, prot) | Warrior. **Berserker becomes the fury spec**, so it keeps its identity as a spec |
| 2 | Assassin | `rogue` | Assassin = rogue, with energy, combo points, stealth, poisons and dual daggers |
| 3 | Ranger | `hunter` | Ranger = hunter, with focus, pets and the class ranged attack (the bow is shown on the character) |
| 4 | Mage | `mage` | Mage = mage (arcane, fire, frost). The earlier "no magic" lore is rewritten as original content |
| 5 | **Paladin** | `paladin` | **Replaces Lancer.** Gives a second tank and a healer. A two-handed spear can be *shown* on a paladin (the reference spear is an ordinary two-hander), but no spear mechanics are claimed |
| 6 | **Priest** | `priest` | **Replaces the separate Berserker slot.** Gives the roster a dedicated healer |

**Why this six:**

- **Every class and spec is reference data**, with no invented kit.
- **All three roles are covered:**
  - Tanks: warrior prot, paladin protection.
  - Healers: paladin holy, priest discipline and holy, mage arcane.
  - DPS: every class.
- **Group and raid encounters need this.** The reference budgets raid loot per five
  intended players (`docs/design/instance-loot-budgets.md`), so its group content
  assumes a tank and a healer.
- **Five earlier identities survive:** Warrior, Assassin, Ranger, Mage and
  Berserker (as a spec).

**Alternatives (all reference classes, so equally valid mechanically):**

- **Druid** instead of Priest. It covers tank, healer and DPS, but needs the form
  system (bear, cat, moonkin).
- **Shaman** instead of Paladin. It brings a melee dual-wield spec plus a healer.
- **Warlock:** DPS only, with pets.

**The earlier identities as two roster entries** (Warrior = arms and prot,
Berserker = the warrior class locked to fury) is possible without inventing data.
It is not recommended:

- It breaks the reference's spec choice (one character picks its spec at Lv 5).
- It leaves the roster with no healer except the mage's arcane spec.
- Lancer would still be UNMAPPED.

**Weapon rule change:**

- The earlier approved rule was "one weapon family per class".
- The reference uses **archetype proficiency**: a warrior can use swords, axes,
  maces and two-handers. Adopting the reference means replacing the class-locked
  family rule with the reference's archetype rule.
- Signature weapons stay as presentation only:
  - Warrior: sword (fury: axes).
  - Assassin: daggers.
  - Ranger: bow (class ranged).
  - Mage: staff.
  - Paladin: two-hander or spear.
  - Priest: staff or mace.
- **Decision R2.**

## 3. Level progression (REFERENCE-EXACT where stated)

**Cap: 20** (`types.ts` `MAX_LEVEL = 20`). PROPOSED for adoption; the earlier spec
gives the reasons.

**What the reference provides for levels 1–20:**

| System | Rule | Source |
|---|---|---|
| XP per level | `XP_TABLE` = 400, 900, 1,400, 2,100, 2,800, 3,600, 4,500, 5,400, 6,500, 7,600, 8,800, 10,100, 11,400, 12,900, 14,400, 16,000, 17,700, 19,400, 21,300, 23,200 | `types.ts` |
| Kill XP | 45 + 5 × mobLevel; +5% per level above (max +4); zero at `zeroDiff` levels below (5 / 6 / 7 / 8 by player level) | `types.ts` `mobXpValue`, `zeroDiff` |
| Abilities | each has a `learnLevel` and `ranks[{rank, level, cost, effects}]` (for example warrior `heroic_strike` ranks at 1, 8, 14, 20) | `content/classes.ts` `ABILITIES` |
| Talents | spec at 5; rows at 5, 8, 11, 14, 17, 20 | `content/talents.ts`, `content/talent_rows.ts` |
| Post-cap | lifetime XP → cosmetic virtual levels (×1.1 per level, `POSTCAP_GROWTH`, up to `MAX_VIRTUAL_LEVEL` 200); prestige ranks at `PRESTIGE_XP_PER_RANK` = xpForLevel(20) = 23,200 | `types.ts` |
| Endgame | progression **by item level at level 20**: dungeon tiers, heroic variants (`HEROIC_VARIANT_SOURCE_LEVEL` 22: rare ilvl 25, epic 28), heroic five-player dungeons at ilvl 31, raids at 33/37; level-20 world bosses (for example `balgath_cyclops`, `thunzharr_waking_peak`: hpBase 4,000, +800 per level) | `item_budget.ts`, `tests/item_level.test.ts` ("five-mans 31, raid 33/37"), `content/*` mob templates |

**Nothing in levels 21–70 is created.** No XP entry, rank or talent row past 20.

### 3.1 Remapping the existing world (ORIGINAL-CONTENT placement, no balance values)

The world's areas, maps and story order stay. Only their **level numbers** move.

**Segment 1: levelling content (areas Lv 1–50) → 1–20.**

- Formula: `new = round(1 + (old − 1) × 19 / 49)`, reviewed area by area.

| Old area level | New level | Areas |
|---|---|---|
| 1, 2 | 1 | 3 |
| 3, 4 | 2 | 3 |
| 5, 6, 7 | 3 | 3 |
| 8, 9, 10 | 4 | 6 |
| 12 | 5 | 1 |
| 13, 15 | 6 | 3 |
| 16 | 7 | 1 |
| 19 | 8 | 1 |
| 21, 22 | 9 | 2 |
| 23, 24 | 10 | 2 |
| 26, 27 | 11 | 3 |
| 29 | 12 | 2 |
| 31, 33 | 13 | 2 |
| 35 | 14 | 1 |
| 37 | 15 | 2 |
| 39 | 16 | 1 |
| 42, 43 | 17 | 2 |
| 44, 45, 46 | 18 | 3 |
| 48 | 19 | 1 |
| 50 | 20 | 2 |

**Segment 2: post-50 content (Lv 53–70, 15 areas) → the level-20 endgame.** Their
difficulty becomes the reference's item-level tiers:

| Old content | Reference tier (PROPOSED) |
|---|---|
| Lv 53–55 (Sunken Reservoir, Coolant Vaults, Floodgate Barracks, Coolant Control Room) | level-20 normal dungeon / zone tier |
| Lv 58–60 (Reactor Underworks, Slag Furnace, Tank Hall) | heroic tier (source 22: rare 25 / epic 28) |
| Lv 62–65 (Crucible Pit, Foundry Depths, The Crucible) | heroic five-player tier (ilvl 31) |
| Lv 68–70 (Iron Heart, Sovereign Vault, Founder's Floor, Heart Core Chamber) | raid tier (ilvl 33 / heroic 37) |

**World bosses and raids:** the reference's world bosses are level 20. Ours that are
already Lv 52+ map to level-20 world bosses. **`tunnel_mother` (Lv 32 today) has no
reference counterpart below 20.** Decision P2: move it to the level-20 tier, or make
it a level-13 elite/boss encounter using a reference boss template.

**Enemies:** each existing enemy takes a **reference mob template of its role and
level band**.

- The library: 328 templates in `content/*.ts` (163 elite, 30 boss).
- Normal mobs: median hpBase 50, hpPerLevel 17.5, dmgBase 8, dmgPerLevel 2.1,
  attack speed 2.0, armorPerLevel 11.
- Elite and boss multipliers come from `createMob` (×2.3 HP, ×1.5 damage).
- The template values are REFERENCE-EXACT; *which* template is chosen is a content
  decision, recorded per enemy.
- Boss mechanics use the reference's mechanic blocks (`MobTemplate` slams, swipe,
  boulders: every, windup, radius, min/max). Boss skill ids stay our own and are
  never player ability ids.

## 4. Equipment (REFERENCE-EXACT unless stated)

| Topic | Reference rule | Source | Effect on our game |
|---|---|---|---|
| Slots | 13: mainhand, offhand, helmet, neck, shoulder, chest, waist, legs, gloves, feet, ring1, ring2, trinket | `types.ts` `ALL_EQUIP_SLOTS` | Our 6 map: head → helmet, body → chest, hands → gloves, weapon → mainhand, feet → feet, charm → trinket. Seven slots are added (decision E1) |
| Armor types | cloth < leather < mail, by class | `equipment_rules.ts` | new item field |
| Weapon data | `{min, max, speed}`, hand one/two/main, `dagger` | `types.ts` `WeaponInfo` | every weapon gets reference weapon data |
| Weapon DPS | 6.7 + 0.3 × ilvl; two-hand × 1.15 DPS, × 1.3 stats | `item_budget.ts` | |
| Stat budget | round(ilvl × quality × slot × 0.7) | `item_budget.ts` | ported (`RpgItemBudget`) |
| Item level | source level + quality bump (uncommon +1, rare +3, epic +6, legendary +10) | `item_budget.ts`, `item_level.ts` | |
| Required level | explicit, else the source level for rare and up; defaults 12 / 18 / cap | `item_level_req.ts` | |
| Per-copy quality | Ordinary 90%, Superior 9% (+2 ilvl), Exceptional 0.9% (+4), Magnificent 0.09% (+6), Transcendent 0.01% (+8); rolled on fresh drops of uncommon-or-better gear; never on vendor items or transfers | `docs/design/loot-quality.md`, `src/sim/loot/enemy_quality.ts`, `src/sim/loot/fresh_quality_grant.ts` | **replaces enhancement** (§5) |
| Class-locked drops | a locked drop rolls only if a present class can use it | `src/sim/loot/class_locked_drop.ts` | |

**Existing items (305 ids):**

- **Ids are kept.** Each is re-specified with reference item data: slot, armor type
  or weapon data, quality, item level and a primary-stat line.
- **The stat budget is exact.** Which primary stats an item carries (its stat
  identity) is a content choice, as in the reference, which authors a line and then
  normalises it to the budget (`normalizePrimaryStats`).
- **Old stats** (`power`, `max_hp`, `defense`, `crit`, `attack_speed`, `speed`) are
  not converted numerically; they are replaced.
- **Display names** become original (§6).

## 5. Enhancement +0 to +10: retire (recommended)

- **The reference has no enhancement system.**
- **Its per-copy power layer** is loot quality (§4): a random roll at drop, adding
  2, 4, 6 or 8 item levels of budget through the same budget formula.
- **The old +N** (+10% of each positive stat per level, a 100%–20% success ladder
  and material costs) is not carried forward.

PROPOSED:

1. Remove enhancement from gameplay.
2. In the save migration, archive each copy's old `+N` (nothing is deleted).
3. **Compensation (decision E2):**
   - (a) none, or
   - (b) a refund of the coins and materials actually spent. The coins spent can be
     reconstructed exactly from `progression.json` levels × the item-level bands,
     but the number of failed attempts cannot.
4. The upgrade materials (scrap metal, refined alloy, enhancement stones) become
   ordinary items until a reference system uses them. Note that profession crafting
   is outside the adopted scope.

No new enhancement formula is proposed.

## 6. Grade mapping (presentation only, no multipliers)

| Reference quality (mechanics) | Stat multiplier (REFERENCE-EXACT) | Our visual identity (ORIGINAL-CONTENT) |
|---|---:|---|
| `poor` | 0 | **grey** (new; we have no grade for it) |
| `common` | 0 (armor or weapon damage only) | **white** (Common) |
| `uncommon` | 0.55 | **green** (Uncommon) |
| `rare` | 0.8 | **blue** (Rare) |
| `epic` | 1.0 | **gold** (Epic; the reference shows purple, we keep gold as presentation) |
| `legendary` | 1.9 | **red** (Legendary; the reference shows orange) |

**Godforged (cyan) has no reference quality and gets no multiplier.** Options
(decision G1):

- **(a) Retire the grade.** Existing Godforged items become `legendary` at their
  source tier (world boss or raid ilvl), shown red.
- **(b) Keep "Godforged" as a display label** for `legendary` items from world
  bosses and raids, shown cyan. The quality stays `legendary` and the budget is
  unchanged. Recommended: it keeps the identity with zero balance effect.
- **(c) Show cyan for a Transcendent per-copy roll.** This would conflict with the
  reference's own badge-not-colour rule for per-copy quality.

## 7. Source paths behind each decision

| Decision | Source |
|---|---|
| Classes and specs | `src/sim/types.ts` `PlayerClass`; `src/sim/content/classes.ts` `CLASSES`; `src/sim/content/talents_warrior.ts`, `talents_classic.ts`; `src/sim/content/talent_rows.ts` |
| Weapons and armor | `src/sim/equipment_rules.ts`; `src/sim/types.ts` `WeaponInfo`, `ALL_EQUIP_SLOTS`; `src/sim/combat/auto_attack.ts`; `src/sim/combat/form_swing.ts` |
| Hunter and mage ranged | `CLASSES.hunter.ranged`, `CLASSES.mage.ranged` |
| Progression | `src/sim/types.ts` `XP_TABLE`, `MAX_LEVEL`, `mobXpValue`, `zeroDiff`, virtual levels, prestige |
| Item budgets and quality | `src/sim/item_budget.ts`, `src/sim/item_level.ts`, `src/sim/item_level_req.ts`, `docs/design/loot-quality.md`, `src/sim/loot/` |
| Enemies | `src/sim/entity.ts` `createMob`, `src/sim/types.ts` `MobTemplate`, `src/sim/content/*.ts` mob templates |
| Formulas already ported | `docs/RPG_CORE_PHASE1_SPEC.md` §6 |

## 8. Decisions needed

| # | Decision | Recommendation |
|---|---|---|
| R1 | Roster | Warrior, Assassin (rogue), Ranger (hunter), Mage, **Paladin**, **Priest**; Berserker becomes the warrior fury spec; Lancer is dropped (or shown as paladin presentation) |
| R2 | Weapon rule | the reference archetype proficiency replaces "one family per class" |
| P1 | Level cap | 20, with the two-segment remap of §3.1 |
| P2 | `tunnel_mother` (Lv 32 world boss) | move to the level-20 world boss tier |
| E1 | Equipment slots | adopt the 13 reference slots (UI and art work for 7 new slots) |
| E2 | Enhancement | retire, archive the levels; compensation (a) none or (b) a refund of coins spent |
| G1 | Godforged | (b) a display label on legendary world boss and raid items |
| N1 | Naming framework | `docs/NAMING_FRAMEWORK.md` |
| T1 | Title | `docs/TITLE_RESEARCH.md` |
