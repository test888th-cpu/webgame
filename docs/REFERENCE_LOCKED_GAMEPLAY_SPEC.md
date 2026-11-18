# Reference-locked gameplay: source audit and specification (analysis only)

**Status: analysis and specification only.**

- No gameplay code, balance data, item data, skill, class, save or test was
  changed.
- Nothing was committed, pushed, merged or deployed.
- `docs/SIX_CLASS_PHASE1_ARCHITECTURE.md` (uncommitted, from the previous task) is
  preserved untouched.

## 0. Corrections (added with docs/RPG_CORE_PHASE1_SPEC.md)

The rest of this document is unchanged; these corrections take precedence.

- **Melee crit has a 5% base:** 0.05 + Agi × 0.0005 + shared bonus (`entity.ts`,
  line 775). The Lv 20 crit column in §D.1 is therefore 5 percentage points low:
  warrior **6.95%**, rogue **9.1%**, hunter **9.1%**.
- **The mage's spell crit** is 0.05 + Int × 0.0008 + shared = **11.48%**
  (`combat/spell_combat.ts`).
- **The mage's Spell Power** at Lv 20 is round(81 × 0.5) = **41** (40.5 rounds
  up), not 40.
- **Items marked UNKNOWN that are now traced:** the melee crit base, energy and
  focus regeneration (+20 and +10 per 2-second tick) and rage decay (−2 per tick
  out of combat). See `docs/RPG_CORE_PHASE1_SPEC.md` §2.

## Repository state

| Repository | State |
|---|---|
| Iron Legacy | branch `claude/stoic-cori-i4r01i`, HEAD `8fdd45b696f8c87170b5102dda24b7a7ba267a98`; working tree: this file and `docs/SIX_CLASS_PHASE1_ARCHITECTURE.md` (both untracked) |
| Reference | `levy-street/world-of-claudecraft` at **`d2b91e0884cb269422c28d0b42d2a30a01de130a`** (2026-11-16T20:00:19+13:00, "Merge pull request #4770"), read only with `git show`. Every value below is from this one commit; no versions are mixed |

Labels, as required:

- **REFERENCE-EXACT:** reproduced from reference source.
- **REFERENCE-ADAPTED:** derived from a reference value or formula, with the
  transformation shown.
- **EXISTING-IRON-LEGACY:** verified in this repository.
- **UNMAPPED:** no reliable reference equivalent.
- **UNKNOWN:** not established from the evidence read.

## The main finding (read this first)

The reference's formulas assume a different game. Six differences are structural:

1. **Level cap.** The reference has `MAX_LEVEL = 20` (`src/sim/types.ts`). All of
   its rank learn levels, stat-per-level curves, XP tables and item budgets are
   tuned for levels 1–20. The Iron Legacy runs to **70** (`progression.json`
   `max_level`), with enemies, items and world bosses tuned for 1–70.
2. **Combat model.**
   - The reference is **tab-target**: a melee swing rolls one hit table (miss →
     dodge → parry → block → crit) on a weapon swing timer (`speed`, seconds per
     swing), with a 1.5 s global cooldown and ranges in yards.
   - The Iron Legacy is a **hitbox beat 'em up** at 60 ticks/s: frame-timed
     moves, lanes, hitstun, poise, grabs and timed parries (`CombatRules.gd`).
   - "Weapon speed", "hit table" and "GCD" have no counterpart in our combat
     loop.
3. **Stats.**
   - Reference: Str, Agi, Sta, Int, Spi, Armor, plus crit, haste and hit ratings,
     Attack Power, Ranged AP and Spell Power.
   - The Iron Legacy: `power`, `max_hp`, `defense`, `crit`, `attack_speed` and
     `speed`, on 267 equipment items, all enemies, `ItemRules` and enhancement.
4. **Resources.** The reference has four (rage, energy, mana, focus). The Iron
   Legacy has one energy pool plus an Ultimate gauge.
5. **Specs and talents.** Many reference abilities are gated by specialisation
   (`specs: ['arms']` and so on). The Iron Legacy has no specs.
6. **Item quality.** The reference has poor, common, uncommon, rare, epic and
   legendary, and common gives **no primary stats**. There is no Godforged.

**Consequence:** "REFERENCE-EXACT" numbers can be used only if The Iron Legacy
adopts the reference's stat model, combat resolution, resource model and a 1–20
level scale. That replaces the existing combat core and re-stats every item and
enemy, which the task also forbids ("Do not replace the existing Godot
architecture", "Preserve every existing working system").

Without that, every number needs a transformation, and choosing the
transformation is itself a decision. §G lists exactly these decisions. Nothing
below is labelled REFERENCE-ADAPTED unless the transformation is shown, and no
transformation has been applied to game data.

## A. Reference source audit (files read at `d2b91e08`)

| Area | File | What was read |
|---|---|---|
| Repo rules | `CLAUDE.md`, `src/sim/CLAUDE.md`, `src/sim/pvp/CLAUDE.md` | architecture; `types.ts` holds the global tuning constants and classic formulas; `entity.ts` `recalcPlayerStats` is "the ONE place derived stats are computed" |
| Constants and formulas | `src/sim/types.ts` | `TICK_RATE` 20, `GCD` 1.5, `MIN_GCD` 0.75, `MELEE_RANGE` 5, rating conversions (haste and crit 20 per 1%, hit 10 per 1%), `XP_TABLE`, `MAX_LEVEL` 20, `mobXpValue`, rage math, `meleeMissChance`, `spellHitChance`, `swingMissChance`, `armorReduction`, `mobArmorReduction`, spell coefficients, `WeaponInfo`, `MobTemplate` |
| Derived stats | `src/sim/entity.ts` `recalcPlayerStats` (line 335), `hpFromStamina` (315), `manaFromIntellect` (321) | base + per-level stats, gear, sets, auras, armor from Agi, AP by class, Ranged AP, Spell Power, crit, dodge, haste and hit, max HP, mana |
| Classes and abilities | `src/sim/content/classes.ts` (`ClassDef`, `CLASSES`, `ABILITIES`) | 9 classes; 336 abilities in this file (warrior 53, mage 60, hunter 40, rogue 28, …); per-rank data (`ranks: [{rank, level, cost, effects}]`) |
| Ability shape | `src/sim/types.ts` `AbilityDef` (line 4451) | id, class, cost, castTime, cooldown, range, minRange, projectile, school, requiresTarget, passive, specs, ranks |
| Melee resolution | `src/sim/combat/auto_attack.ts` `meleeSwing` (line 526), `rangedSwing` (445) | the single-roll hit table, damage formula, crit ×2, armor DR, block; dual-wield constants |
| Ability damage | `src/sim/combat/effect_dispatch.ts` (lines 2642, 3238, 3689) | crit multiplier: physical ×2, spell ×1.5 (+ bonuses) |
| Spell crit | `src/sim/combat/spell_combat.ts` | a separate spell-crit pool (Intellect in place of Agility) |
| Damage application | `src/sim/combat/damage.ts` `dealDamage` (line 210) | final application, immunities; crit, dodge, miss and armor are resolved upstream |
| Equipment gate | `src/sim/equipment_rules.ts` `canEquipItem` (422), `weaponArchetypeForItem` (387), `canDualWield` (406) | archetype weapon sets, dual-wield rule, `questTool` exception |
| Item budget | `src/sim/item_budget.ts`, `src/sim/item_level.ts` | `QUALITY_STAT_MULT`, `SLOT_STAT_MULT`, `QUALITY_ILVL_BONUS`, `primaryStatBudget`, `weaponDpsBudget` (from the earlier adaptation audit) |
| Items | `src/sim/content/items.ts` (`worn_sword`, `gnarled_staff`, `rusty_dagger`), `src/sim/content/profession_items.ts` (`Ironbark Boar Spear`) | weapon `{min, max, speed}` |
| PvP | `src/sim/pvp/power.ts` | WARFARE offense and defense ratings (10 per 1%, cap 0.30 each), Vitality (6 per 1%, cap +80% HP), `pvpDamageMultiplier` |
| Loot | `src/sim/loot/class_locked_drop.ts`, `docs/design/instance-loot-budgets.md`, `docs/design/loot-quality.md` | class-locked drops, encounter budgets, per-copy quality |

**Tests named in the sources** (not run here; the reference is not built):
`tests/item_level.test.ts`, `tests/spell_power.test.ts`, `tests/honor.test.ts`
(WARFARE Vitality), `tests/item_compare.test.ts`, `tests/loot_quality*.test.ts`,
`tests/twohand_rebudget.test.ts`.

**Not traced (UNKNOWN until read):**
- Where a melee crit base, if any, is added. `critChance = agi × 0.0005 +
  sharedCritBonus (+ stance)`; the spell-crit comment says "the same 5% base".
- Energy and focus regeneration rates.
- The talent ability files (`talent_abilities_v2*.ts`).
- Per-boss mechanic values beyond their structure.

## B. Skills: reference specification

### B.1 Data structure (REFERENCE-EXACT, `AbilityDef`)

- **Fields:** `id`, `name`, `class`, `learnLevel`, `cost` (resource),
  `castTime` (s; 0 = instant), `cooldown` (s; 0 = GCD only), `range` (yards; 0 =
  melee), `minRange`, `school`, `requiresTarget`, `effects[]`, `specs`,
  `excludeSpecs`, `offGcd`, `onNextSwing`, `exclusiveGroup`, `threat`, and
  `ranks[]`.
- **Each rank:** `{rank, level, cost, threatFlat, effects}`.

Worked example, `heroic_strike` ("Reaver Strike", warrior):

| Rank | Level | Cost | Weapon-damage bonus | Ratio to rank 1 |
|---:|---:|---:|---:|---:|
| 1 | 1 | 15 rage | 11 | 1.00 |
| 2 | 8 | 15 | 21 | 1.91 |
| 3 | 14 | 15 | 32 | 2.91 |
| 4 | 20 | 15 | 44 | 4.00 |

Other notes on `heroic_strike`:

- It is `onNextSwing`, `offGcd` and excluded from all three specs; only the
  pre-spec filler uses it.
- Ranks change the effect value and threat, not the cost or cooldown. The pattern
  repeats in the ranked abilities read (`sinister_strike` 3 extra ranks,
  `fireball` 3, `frostbolt` 3, `raptor_strike` 3, `eviscerate` 2, `backstab` 2).

### B.2 Global rules (REFERENCE-EXACT)

| Rule | Value or formula | Source |
|---|---|---|
| Global cooldown | 1.5 s; `GCD / spellHasteMult`, floored at `MIN_GCD` 0.75 s | `types.ts` |
| Physical crit | damage × (2 + `critDmgPhysBonus`) | `auto_attack.ts`, `effect_dispatch.ts` |
| Spell crit | damage × (1.5 + `critDmgSpellBonus`); heals × (1.5 + heal bonus) | `effect_dispatch.ts`, `heal.ts` |
| Spell coefficient | direct: clamp(castTime, 1.5, 3.5) / 3.5; DoT: duration / 15; AoE × 0.333 | `types.ts` (`SPELL_COEFF_*`) |
| Spell Power | 0.5 × Int + gear and aura SP | `entity.ts` |
| Ranged and melee "attack spells" | flat parts scale off AP × 0.15 with the same shape | `RANGED_SPELL_AP_SCALE`, `MELEE_SPELL_AP_SCALE` |
| Rage | from dealing: 7.5 × dmg / c(L), c(L) = 0.0091 L² + 3.23 L + 4.27; from taking: dmg / (1.5 × attacker level) | `types.ts` |

### B.3 Class mapping for skills

| Iron Legacy class | Reference class or spec | Adaptable reference abilities (ids) | Gaps |
|---|---|---|---|
| Warrior (sword) | `warrior` (no spec, arms, prot) | `heroic_strike`, `charge`, `overpower`, `slam` (arms), `cleave` (arms), `execute`, `thunder_clap`, `battle_shout`, `defensive_stance`, `shield_block` | Shields and stances have no Iron Legacy counterpart; rage resource (§D) |
| Assassin (dual daggers) | `rogue` | `sinister_strike`, `backstab` (needs a dagger, `WeaponInfo.dagger`), `eviscerate` (finisher), `slice_and_dice`, `evasion`, `sprint`, `kick`, `gouge`, poisons | **Combo points**, **stealth** and **energy** are reference systems not in our game; UNMAPPED until they are approved |
| Berserker (axe) | `warrior` **fury spec**: `whirlwind`, `berserker_stance`, enrage (`ENRAGE_*`), Titan's Grip (`TITANS_GRIP_DMG_PENALTY` 0.12) | `whirlwind`, `berserker_rage`, `execute`, `bloodrage`, `enrage_passive` | It is a *spec* of the warrior in the reference, not a class: it shares the warrior kit. A separate class identity is UNMAPPED |
| Lancer (spear) | **none** | — | **UNMAPPED.** The reference has no spear class, spear mechanic or reach rule; the only spear is a crafted two-hander with plain weapon stats (`profession_items.ts` "Ironbark Boar Spear", 30–41 dmg, 3.2 s) |
| Mage (staff) | `mage` | `fireball`, `frostbolt`, `arcane_missiles` (arcane spec), `frost_nova`, `blizzard`, `arcane_explosion`, `blink`, `ice_barrier`, `polymorph` | Mana; cast times interrupted by damage; schools. Conflicts with Story Bible §1 "no magic" (see Phase 1 D1) |
| Ranger (bow) | `hunter` | `arcane_shot`, `aimed_shot` (MM spec), `volley`, `rapid_fire` (MM), `concussive_shot`, `raptor_strike`, `wing_clip` | In the reference the **bow is part of the class definition** (`hunter.ranged: {min 5, max 9, speed 2.3, maxRange 35}`), not an item. Pet abilities (`tame_beast`, `pack_command`) have no pet system here; focus resource UNMAPPED |

**Ability counts per reference class** (in `classes.ts`): warrior 53, mage 60,
hunter 40, rogue 28. The full ability-by-ability spec (every rank, value and
effect) can be produced per class once §G decides which reference systems come
along. Producing it now would list values that cannot be used as-is.

## C. Weapons and equipment: reference specification

| Item | Value | Label |
|---|---|---|
| Weapon data | `WeaponInfo {min, max, speed (s per swing), dagger?}`; `hand`: onehand / twohand / mainhand | REFERENCE-EXACT |
| Examples | `worn_sword` common 2–5 dmg, 2.0 s; `gnarled_staff` common 3–6, 2.9 s, +1 Int; `rusty_dagger` common; spear (crafted, two-hand) 30–41, 3.2 s | REFERENCE-EXACT |
| Weapon DPS budget | `weaponDpsBudget(level) = 6.7 + 0.3 × level`; two-hand DPS × 1.15, stats × 1.3 | REFERENCE-EXACT (`item_budget.ts`) |
| Melee swing damage | `(roll(min, max) × rollMult + AP / 14 × swingSpeed) × mult + bonus`; × (2 + bonus) on crit; × (1 − armorDR) | REFERENCE-EXACT (`meleeSwing`) |
| Dual wield | off-hand auto attack × 0.5 (`OFFHAND_AUTO_ATTACK_DMG_MULT`); +10% white miss (`DUAL_WIELD_WHITE_MISS_PENALTY`); only rogue, fury warrior and enhancement shaman can dual wield | REFERENCE-EXACT |
| Class weapon rules | archetype sets: warrior weapons (warrior, rogue, hunter, shaman, paladin), caster (mage, priest, warlock, shaman, paladin, druid), rogue (rogue, hunter); rogue cannot use two-handers; `questTool` items are usable by anyone | REFERENCE-EXACT (`equipment_rules.ts`) |
| Weapon families as a field | **none.** Skin types are cosmetic only (`WeaponSkinType`: sword, axe, mace, dagger, staff, wand, bow, crossbow; no spear) | REFERENCE-EXACT |
| Class-locked weapon per class (the Iron Legacy rule) | No equivalent: reference classes share archetype pools | UNMAPPED (our rule stands as an approved Iron Legacy decision) |

**Example [REFERENCE-EXACT arithmetic]:**

- A Lv 20 warrior with base stats only has AP 122.
- Swinging `worn_sword` (2–5, 2.0 s) averages 3.5 + 122 / 14 × 2.0 = **20.9**
  before crit and armor.

## D. Character stats and combat formulas

### D.1 Reference (REFERENCE-EXACT, `entity.ts` and `types.ts`)

**Stats:**

- **Primary stats:** `base + perLevel × (L − 1)` per class.

  | Class | Base (Str/Agi/Sta/Int/Spi/Armor) | Per level |
  |---|---|---|
  | warrior | 23/20/22/10/11/50 | 2/1/2/0/0/12 |
  | rogue | 17/25/17/11/12/40 | 1/3/2/0/0/8 |
  | hunter | 14/25/19/13/14/45 | 1/3/2/1/1/8 |
  | mage | 10/12/14/24/22/25 | 0/0/2/3/2/4 |

- **Armor:** stat armor + 2 × Agi (+ forms, talents, auras).
- **Max HP:** `baseHp + hpPerLevel × (L − 1) + hpFromStamina(Sta)`, where
  `hpFromStamina(s) = min(s, 20) + max(0, s − 20) × 10`.
  - baseHp / hpPerLevel: warrior 50/18, rogue 45/15, hunter 50/15, mage 40/15.
- **Mana:** `baseMana + manaPerLevel × (L − 1) + manaFromIntellect(Int)`, where
  `manaFromIntellect(i) = min(i, 20) + max(0, i − 20) × 15`.
  - Rage, energy and focus are capped at 100.
- **Attack Power:** warrior, paladin, shaman and druid 2 × Str; rogue and hunter
  Str + Agi; others Str. Plus a bonus, × (1 + AP%).
  - Hunter Ranged AP = 2 × Agi.
- **Spell Power:** 0.5 × Int + bonus.
- **Crit:** Agi × 0.0005 + shared bonus (crit rating / 2000, talents, sets,
  auras).
- **Dodge:** 0.05 + Agi × 0.0005 + bonus.
- **Ratings:** haste 20, crit 20, hit 10 per 1%.

**Hit and mitigation:**

- **Melee miss:** `5% + aboveLevel(diff)` (diff = target − attacker), with
  aboveLevel = [0, 2.5, 8, 14] (saturates at 14).
  - Below your level: −0.2% per level. Clamped to 0.5–95%.
  - A mob hitting a player is capped at 20% miss (`MOB_VS_PLAYER_MAX_MISS`).
  - Hit rating subtracts.
- **Spell hit:** 96% at equal level; +1% per level below; minus aboveLevel above.
  Clamped to 5–99%.
- **Armor DR:** `min(0.75, armor / (armor + 85 × attackerLevel + 400))`. A mob
  hitting a higher-level player has its DR capped toward 20% over a 3-level ramp.
- **Mob dodge vs player:** 0.05 + 0.005 per level above.

**Resolution order** (one roll): miss → dodge → parry → block → hit; then crit
(×2 physical); then × (1 − armor DR); block reduces by the block value.

**PvP (WARFARE):** gear rating to offense and defense, capped at 0.30 each.
Hostile-player damage × (1 + offense) × (1 − defense). Vitality +HP up to 80%,
except in PvE instances. There are **no per-class PvP coefficients**.

**Worked examples at Lv 20** (base stats, no gear):

| Class | HP | Armor | AP | Ranged AP | Spell Power | Crit | Dodge | Resource |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| warrior | 812 | 356 | 122 | – | – | 1.95% | 6.95% | rage 100 |
| rogue | 700 | 356 | 118 | – | – | 4.1% | 9.1% | energy 100 |
| hunter | 725 | 361 | 115 | 164 | – | 4.1% | 9.1% | focus 100 |
| mage | 665 | 125 | 10 | – | 40 | 0.6% (+ spell pool) | 5.6% | mana 1,491 |

- 356 armor against a Lv 20 attacker: DR **14.5%** (42.3% against Lv 1).
- Melee miss by level gap −5 / 0 / +1 / +2 / +3: 4% / 5% / 7.5% / 13% / 19%.

### D.2 The Iron Legacy today (EXISTING-IRON-LEGACY)

- **Hero stats** (`PlayerProfile.stats`): HP = hero base + 10 per level + gear;
  power = hero base + 0.05 per level + gear; defense, speed, crit (base 0.05,
  cap 0.5) and attack speed (0.7–1.3).
- **Damage** (`CombatRules`): `move.damage × attacker.power`, minus flat defense in
  PvE; a share `def / (def + 90)` in PvP; crit × 1.5; PvP combo decay; skills
  scaled by `BalanceProfile` pve/pvp profiles.
- **Enemies** (`LevelRules`): power × (1 + 0.08 per level), HP × (1 + 0.06 per
  level), defense +1 per 8 levels.
- **Tick rate** 60/s (the reference uses 20/s).

### D.3 What could transfer without inventing numbers

- **Dimensionless ratios** transfer exactly in meaning:
  - rank growth (`heroic_strike` 1 : 1.91 : 2.91 : 4.0);
  - crit multipliers (physical 2.0, spell 1.5);
  - spell coefficient shapes;
  - the armor-DR curve *shape* (it needs the armor scale);
  - per-class stat *proportions*;
  - the dual-wield off-hand 0.5;
  - the two-hand 1.15 / 1.3 premiums.
- **Durations in seconds** transfer exactly, as 60 ticks per second: cooldowns,
  cast times, buff durations, the GCD. That makes them REFERENCE-ADAPTED with a
  unit change only.
- **Absolute magnitudes** do not transfer: HP, AP, armor, damage numbers,
  resource sizes, level thresholds and item budgets. They depend on the 1–20
  scale and the reference's stat model. Mapping them needs a level and scale
  transform (§G).

## E. Loot and item progression

| Topic | Reference (REFERENCE-EXACT) | Iron Legacy (EXISTING) | Mapping |
|---|---|---|---|
| Grades | poor, common, uncommon, rare, epic, legendary | common, uncommon, rare, epic, legendary, godforged | poor: none; **godforged: UNMAPPED** |
| Stat budget | `round(level × QUALITY_STAT_MULT × SLOT_STAT_MULT × 0.7)`; quality mult poor 0, common 0, uncommon 0.55, rare 0.8, epic 1.0, legendary 1.9 | `ItemRules`: (10 + 2L) × slot × grade; grades 0.85 / 1.0 / 1.15 / 1.35 / 1.6 / 2.2 | Reference common = **0 primary stats**; ours = 0.85. The ratios differ (reference epic/rare 1.25, legendary/epic 1.9) |
| Item level | source level + rarity bump (uncommon +1, rare +3, epic +6, legendary +10) | authored | |
| Per-copy quality | Ordinary to Transcendent, +0 to +8 item levels, 90 / 9 / 0.9 / 0.09 / 0.01% | enhancement +0 to +10 (+10% of base per level), not random | Different mechanics; the enhancement link is unapproved, so nothing is proposed |
| Class-locked loot | a locked drop rolls only if a present class can use it | none | Fits a six-class roster; a reward-table change, so it needs approval |
| Encounter budget | raid: 1 equipment drop per 5 intended players per boss kill | per-boss tables | A guideline only |
| PvP gear | WARFARE ratings on honor gear | none | UNMAPPED |

## F. Compatibility matrix

| Reference system | Direct | Translate | No equivalent | Notes |
|---|:---:|:---:|:---:|---|
| `AbilityDef` data shape (+ ranks) | ✓ | | | fits `skills.json` (it already has cooldown, unlock_level, pve/pvp profiles) |
| Rank growth ratios, crit multipliers, coefficient shapes | | ✓ (dimensionless) | | |
| Cooldowns, cast times, durations (s → ticks × 60) | | ✓ (units) | | |
| GCD 1.5 s | | ✓ only if a GCD is approved | | our skills have per-skill cooldowns, no GCD |
| Hit table (miss, dodge, parry, block) | | | ✓ | our hits are hitbox contacts; a roll would add a second miss layer |
| Weapon swing timer, AP / 14 × speed | | ✓ needs weapon speed on items | | our attack timing is move frames |
| Str, Agi, Sta, Int, Spi, ratings | | | ✓ (without a stat-model replacement) | |
| Armor DR curve | | ✓ needs the armor scale | | replaces flat defense |
| Rage, energy, mana, focus | | ✓ per class, if approved | | today one energy pool |
| Specs and talents | | | ✓ | |
| Equipment gate (`canEquipItem`) | ✓ (pattern) | | | |
| Class-locked drops | ✓ (pattern) | | | |
| WARFARE PvP ratings | | | ✓ | ours: per-skill pvp profiles + defense share |
| Boss mechanic blocks (windup, radius, min–max) | ✓ (shape) | | | our bosses have their own data; values do not transfer |
| Item budget | | ✓ (formula already analogous) | | |
| Godforged | | | ✓ | |
| Lancer / spear | | | ✓ | |

## G. Unresolved decisions (genuine gaps only)

1. **Stat and combat core.**
   - (a) Adopt the reference stat model and hit-table resolution: every item,
     enemy, `ItemRules`, enhancement and test is reworked. This is the only route
     to REFERENCE-EXACT numbers.
   - (b) Keep the Iron Legacy core; take only the reference's data structures,
     dimensionless ratios and second-based timings.
2. **Level scale.** If any absolute reference value is used, how do levels 1–70 map
   onto the reference's 1–20? For example, `L_ref = 1 + (L − 1) × 19 / 69`. That
   transform would be ours, not the reference's, so it needs approval.
3. **Resources.** Keep one energy pool, or adopt rage, energy, mana and focus
   per class.
4. **UNMAPPED classes and mechanics.**
   - Lancer: no reference spear class.
   - Berserker: a reference *spec*, not a class.
   - Assassin's combo points and stealth.
   - Ranger's pet and focus.
   - Mage against Story Bible §1.
5. **Godforged** has no reference grade multiplier.
6. **The global cooldown:** adopt one or not.
7. **The hit table:** adopt a miss/dodge roll on top of hitboxes, or not.

The Phase 1 decisions D1–D10 (`docs/SIX_CLASS_PHASE1_ARCHITECTURE.md`) remain
open alongside these.

## H. Implementation plan (smallest safe sequence; nothing starts before §G)

1. **Data shape only** (no values): add the `AbilityDef`-style fields to
   `skills.json` validation (class, weapon family, category, range, target,
   ranks[] with level and effects). Existing skills stay valid. Tests: schema
   only.
2. **The equipment gate** (`ClassRules.can_wield`, the reference `canEquipItem`
   pattern) and the class-weapon table from the approved roster. No stat values.
3. **Unit-only transfers:** cooldowns and durations of approved reference
   abilities in seconds → ticks (× 60), with each value's source id recorded in
   the data (`"source": "woc:d2b91e08:heroic_strike#r1"`).
4. **Dimensionless transfers:** rank ratios and crit multipliers, applied to Iron
   Legacy base magnitudes, once §G 1–2 are decided.
5. **Per class**, only after its UNMAPPED items are approved: skills, then the
   resource, then auto-combat selection through the same validation.
6. **Verification matrix** (per class × weapon × skill rank × stat × mode),
   deterministic seeds, the existing harnesses; reports labelled as here.
