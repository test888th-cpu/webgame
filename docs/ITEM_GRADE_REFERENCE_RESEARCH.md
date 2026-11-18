# Item grade reference research

**Status: research only.** No code or asset from these projects was copied into
this repository. No item stat, formula, ID, enhancement rule, drop or reward
was changed. The recommendations in §3 to §6 wait for the owner's approval.
Read this report with `docs/ITEM_POWER_AUDIT.md` (our own numbers).

The five repositories were cloned read-only into the session scratchpad,
outside the repository. Nothing was installed, built or run from them. The
numbers below were read from their source files as text.

| # | Repository | Commit read | Date | Engine / language | Licence found |
|---|---|---|---|---|---|
| 1 | ClarkWain/godot-arpg-kit | `f904748` | 2026-10-10 | Godot 4, GDScript | MIT (`LICENSE`, © 2026 "eiehihi") |
| 2 | GiuffreLab/adventurers-guild | `7c77721` | 2026-04-16 | Browser JavaScript | **None** (no `LICENSE` file, no `license` in `package.json`) |
| 3 | Menkos/inventory-forge | `93c4a30` | 2026-01-31 | Godot 4 editor plugin | MIT (`LICENSE`, © 2025 Menkos) |
| 4 | Jegethy/idle-godot | `1899721` | 2025-11-09 | Godot 4, GDScript | **No licence file.** The README says "open source and available for educational purposes"; that is not a licence grant |
| 5 | BAK2K3/CIRPG | `05d71c4` | 2026-07-01 | Python / Django | **None** (no `LICENSE` file) |

Labels used below:

- **[Verified]** is what the repository's code or data actually does, read at
  the commit above.
- **[Measured]** is a number I computed from their data files. The method is
  stated each time.
- **[Recommendation]** is my own proposal for The Iron Legacy.

## 1. Repository findings

### 1.1 ClarkWain/godot-arpg-kit (Godot ARPG framework)

**[Verified]**

- **Rarity:**
  - `ItemData.Rarity` has six grades, Common → Mythic (`scripts/items/item_data.gd`).
  - Rarity drives only presentation and sorting: a colour and a name, an
    inventory sort (`sort_by_rarity`), and a drop glow for Rare and above
    (`scripts/loot/dropped_item.gd`).
  - **No stat depends on rarity.** Stats are written by hand per item.
- **Stats:**
  - Equipment carries a list of `StatModifier`s (`scripts/stats/stat_modifier.gd`).
    Each has a type (`FLAT`, `PERCENT` or `OVERRIDE`), a priority and a source tag.
  - `StatsComponent` resolves a stat as `(base + Σflat) × (1 + Σpercent)`. An
    override replaces the result.
  - Stats include damage absorb % and reflect %.
- **Slots and requirements:**
  - 11 equipment slots, including two rings, an amulet, a belt and an off-hand.
  - `required_level` on every item.
- **Weapon types:** `WeaponData.WeaponType` has 11 types.
  - Each weapon carries `is_two_handed`, `attack_range`, `attack_speed`,
    min/max physical damage, min/max magic damage, and an optional special attack
    with a cooldown.
- **Special effects:**
  - `special_effects` is a list of string IDs ("lifesteal", "thorns"…) with a
    description.
  - Set bonuses are linked by a `set_bonus_id`.
  - Durability has a repair cost.
- **Rarity upgrade on drop:**
  - The loot component has a luck-based "rarity boost", but it is a stub. It
    only logs "rarity boost needs a new ItemData copy" and changes nothing
    (`scripts/loot/enemy_loot_component.gd`).
- **Validation:** unit tests for item data, instances, equipment runtime, weapon
  data, loot tables and the luck system (`tests/`).
- **Budgets:** no stat budget or balance check.

**Takeaways**

- **Useful:** the modifier model. "Flat, then percent, with a priority" is a clean,
  testable way to add *percentage* effects later without touching every item.
- **Not useful for grades:** rarity is only a label here. It is the same weakness
  our audit found: nothing ties grade to power.

### 1.2 GiuffreLab/adventurers-guild (idle guild management, browser)

**[Verified]**

- **Six grades** in `js/data/equipment.js`: common, magic, rare, epic, legendary
  and celestial.
- **Every item has a hand-written `statBonus`** (atk, def, spd, crit, dodge,
  maxHp, mag) and a **`tier` 1–6 tied to rank F…S**.
  - **Rarity and tier move in lockstep** (tier 1 = common … tier 6 = celestial),
    so in this game **grade is the progression stage**.
- **Class rules:** `classReq` restricts items by class. Weapon roles are flags
  (`twoHanded`, `dagger`, `claw`, `bow`, `quiver`) that decide which slots and
  classes can use them.
- **Special effects:** high-tier items carry a `grantedSkill`, a named skill with
  its own data (`js/skills/equipment-skills.js`), rather than loose stat effects.
- **Character power:** `memberPower = 2·atk + def + spd + maxHp/10 + 1.5·mag +
  crit + dodge/2` (`js/game.js`). It is used to show recommended power for quests.
- **Enemies scale geometrically per rank** (`js/data/rankScales.js`): about ×1.88 HP
  and ×1.65 ATK per rank.
  - Difficulty sub-tiers (easy/standard/hard/brutal) multiply HP, ATK and reward.
  - The comments say the curve was "validated in rank-scaling-reference.xlsx"
    (the spreadsheet is not in the repository).
- **Enhancement:** none found.

**[Measured]** I parsed `equipment.js` as text. For each item I summed the stats
as atk + def + spd + crit + dodge + maxHp/5. This is my own crude sum, not the
game's formula.

| Slot | T1 common | T2 magic | T3 rare | T4 epic | T5 legendary | T6 celestial |
|---|---:|---:|---:|---:|---:|---:|
| weapon (avg) | 5.5 | 14.7 | 27.6 | 54.1 | 89.5 | 111.2 |
| armor (avg) | 4.8 | 11.4 | 23.7 | 40.6 | 70.5 | 101.0 |
| accessory (avg) | 3.2 | 7.4 | 12.1 | – | 31.8 | 83.9 |

- Steps run about ×1.6–2.7 per grade, falling to ×1.2–1.4 at the top.
- Within a grade the spread is wide: weapons at T3 run from 8 to 60. The spread
  is specialisation by class.

**Takeaways**

- **Useful:** binding grade to stage is the simplest way to make grades obviously
  better. Granting a skill is a clean way to give top items an identity.
- **Not transferable as is:**
  - The steps are much steeper than our level curve could absorb (§2.3 of the
    audit).
  - Our grades are not stages: each grade spans Lv 1–68.
  - There is no licence, so nothing may be reused (§7).

### 1.3 Menkos/inventory-forge (Godot item database editor plugin)

**[Verified]**

- **An editor tool, not a game.** `ItemDefinition` resources live in an
  `ItemDatabase`, edited in a dock (`addons/inventory_forge/`).
- **Rarity:** five grades. Rarity affects colour and translation keys only.
- **Equipment fields:**
  - `equippable`, `equip_slot` and `required_level` (0–100).
  - Flat integer stats `stat_atk`, `stat_def`, `stat_hp` and `stat_mp`.
- **Passives:** a typed `PassiveEntry` (an enum type, a value, and a trigger
  chance of 0–100%). These are data, not code.
- **Validation:**
  - **Per item** (`get_validation_warnings`): missing name or description key,
    missing icon, sell price above buy price, an equippable item with no slot,
    a consumable with no effect, a tradeable quest item, a craftable item with no
    ingredients, and inconsistent material flags.
  - **Per database:** duplicate IDs (`get_duplicate_ids`, `has_duplicate_id`),
    counts per rarity and category, and items with warnings.
  - Unit tests for the database, the item definition and loot tables.
- **Budgets:** no stat budget or grade rule.

**Takeaways**

- **Useful:** the validation pattern, with one warning list per item and
  cross-item checks per database. Our `ContentDB` already does most of this at
  load time. What we lack are **balance warnings** (§5).
- **Typed passives with a trigger chance** are a reasonable shape if items ever
  get effects. Our `PassiveRules` already uses this shape for skills.

### 1.4 Jegethy/idle-godot (idle game, Godot)

**[Verified]**

- **Rarity:**
  - Five grades with drop weights 60/25/10/4/1 (`data/loot_weights.json`).
  - Per-rarity chances to roll a prefix and a suffix, and a per-rarity maximum
    number of affixes: 1/1/2/2/3.
- **Affixes** (`data/affixes.json`, `scripts/systems/AffixService.gd`):
  - **value = base × rarity_scaling[rarity] × (1 + per_wave_factor ×
    min(wave, 100))**.
  - Rarity and progression (the "wave", their equivalent of level) are
    **separate multipliers**.
  - Rarity curves are per affix, for example 1.0/1.2/1.5/2.0/2.75 for flat
    attack and 1.0/1.15/1.35/1.7/2.3 for speed.
- **Base items** (`data/items.json`) carry a fixed list of typed effects
  (`combat_attack_add`, `combat_attack_mult`, `idle_rate_multiplier`…).
- **Caps** (`scripts/config/BalanceConstants.gd`):
  - `ITEM_ATTACK_MULT_CAP` 5.0 and `ITEM_IDLE_MULT_CAP` 10.0, applied when gear
    is totalled (`scripts/autoload/inventory_system.gd`).
  - The wave scaling of affixes is capped at wave 100.
- **Comparison through the real formula:**
  - `GearAnalyzer.compare_items` builds the current loadout and the loadout with
    the candidate swapped in. It runs both through the same `LoadoutSimulation`
    (DPS and idle rate) and reports the % difference.
  - A threshold of 0.5% counts as an improvement.
- **Validation and tests:** deterministic affix rolls, affix wave scaling, the
  maximum affixes per rarity, loot rarity distribution, the analyzer difference,
  loadout simulation, and save migrations (`tests/`).

**Takeaways**

- **Useful (the most relevant project):**
  - **Rarity as a multiplier, kept apart from the level multiplier.**
  - **Caps applied where gear is totalled.**
  - **Items judged by running a whole loadout through the real formula**, not by
    comparing raw stats.
- **Different from us:** their items are rolled (base plus random affixes). Ours
  are fixed, hand-made items with stable IDs. The multipliers fit our design as
  **authoring targets and validation rules**, not as runtime rolls.

### 1.5 BAK2K3/CIRPG (Django web RPG)

**[Verified]**

- **Rarity rolls** (`codex/functions.py`, `rarity_recursive`): a weapon's rarity
  (1–5) is rolled by successive successful rolls. The success threshold falls as
  the character level rises, so higher levels see higher rarities.
- **Stat scaling** (`stat_modifier`, `modifier_multiplier`, `codex/models.py`
  `new_weapon`):
  - Each stat is multiplied **`rarity` times** by a random factor in
    [1 + (L−1)/5, 1 + (L−1)/5 + r/5].
  - Rarity therefore compounds. It sets both the number of multiplications and
    the width of the range.
- **Tests:** view and page tests only (`battle/tests.py`, `codex/tests.py`). No
  balance tests.

**[Measured]** I worked the multipliers out from the formula; nothing was run.

- At weapon level 5, the factor range per multiplication is ×1.8 to ×1.8 + r/5.
- A rarity-5 weapon applies it five times, so its stats come out between about
  18.9× and 172× the base.
- A rarity-1 weapon gets between 1.8× and 2.0×.

**Takeaways**

- **A cautionary example.**
  - Compounding, random grade multipliers make grade gaps explode and differ
    item to item.
  - Nothing bounds them and no test checks them.
- This is the opposite of what our audit recommends: fixed per-grade ratios with a
  tolerance band and a test.

## 2. Patterns across the five projects

| Question | What the projects do [Verified] |
|---|---|
| 1. How do higher grades get a real base-stat advantage? | (a) Grade = stage: adventurers-guild ties rarity to tier. (b) Grade = multiplier: idle-godot `rarity_scaling`; CIRPG compounding. (c) Hand-authored, rarity as a label: ClarkWain, inventory-forge. Only (a) and (b) guarantee an advantage. |
| 2. How are budgets spread over slots? | No project writes a slot budget down. adventurers-guild shows it by convention: weapons carry the most stats per tier, then armour, accessories and off-hands ([Measured] table, §1.2). |
| 3. How do they stop lower grades outperforming higher ones? | idle-godot by construction (multiplier ≥ 1 per step). adventurers-guild by binding grade to tier. No project has a test for inversions. |
| 4. How are weapon types balanced? | ClarkWain: per-type range, speed, two-handedness and damage range. adventurers-guild: class and slot flags plus stat mix. Neither balances types numerically. |
| 5. How are special effects weighed against stats? | adventurers-guild: effects are separate granted skills on top of the stats. idle-godot: effects are typed values valued by a loadout simulation. ClarkWain and inventory-forge: effects are free-form, with no valuation. |
| 6. How is rarity kept apart from level? | idle-godot: two separate multipliers (rarity × wave). CIRPG: mixed into one roll. adventurers-guild: no separation (rarity is the tier). |
| 7. How do they validate big databases? | inventory-forge: per-item warnings, duplicate IDs, counts. idle-godot: tests for scaling, distribution, affix limits and the analyzer. CIRPG: none. No project checks grade ordering. |

## 3. Recommendations for The Iron Legacy [Recommendation]

1. **Keep fixed, hand-made items with stable IDs.** Do not switch to random affixes:
   - it would change every save,
   - break the drop database and the Guide,
   - and conflict with "never trust the client" unless rolled on the server.
2. **Adopt idle-godot's separation as an authoring rule, not a runtime roll.**
   - The **target value** of an item is the slot's level curve times a grade
     multiplier.
   - The level curve is today's Common median for that slot and level band
     (`docs/ITEM_POWER_AUDIT.md` §4).
   - The grade multipliers are 1.0 / 1.3 / 1.7 / 2.2 / 2.9 / 3.8 (§4 below).
3. **Value items through our real formulas, like idle-godot's GearAnalyzer.**
   - The audit's item value (§2.3 there) is that idea for per-item checks.
   - Whole-set checks should use the existing progression harness, because flat
     defense makes set value non-linear.
4. **Cap-aware budgets, as idle-godot caps where gear is totalled.**
   - Our caps already exist (crit 0.5, attack speed 1.3).
   - The budget should not count stats past what a full set can use.
5. **Add balance warnings, like inventory-forge's per-item warning list, as a test.**
   - Every equipment item stays within its grade target, plus or minus the
     tolerance.
   - No strict inversion (§5).
   - Give it its own allowlist for deliberate specialisations, each with a reason.
6. **If items ever gain effects, grant named skills or typed passives** (as
   adventurers-guild and inventory-forge do).
   - That would reuse our `PassiveRules` shape instead of free-form strings.
   - Value effects separately from base stats, through the harness.
   - This is not proposed now: no item has effects today (audit §7).
7. **Do not follow CIRPG's compounding multipliers or ClarkWain's label-only
   rarity.** Both are the failures our audit found or would create.

## 4. Proposed grade progression model [Recommendation]

The reference curve 50 / 80 / 120 / 170 / 250 / 350 is a ×7 range from Common to
Godforged. The audit (§12) shows what that would cost here.

Today's top grade, Godforged, sits at an index of about 140–200, so applying the
reference would roughly double Godforged and every world boss and arena tier above
it. The recommended **Model B** keeps the reference's *shape* (each step clearly
bigger) at a scale the game can absorb:

| Grade | Reference index | Model B index | Grade multiplier (× Common, same slot and level) | Step |
|---|---:|---:|---:|---:|
| Common | 50 | 50 | 1.0 | – |
| Uncommon | 80 | 65 | 1.3 | +30% |
| Rare | 120 | 85 | 1.7 | +31% |
| Epic | 170 | 110 | 2.2 | +29% |
| Legendary | 250 | 145 | 2.9 | +32% |
| Godforged | 350 | 190 | 3.8 | +31% |

Model B compared with the projects:

- idle-godot's flat-attack affix curve (1.0 / 1.2 / 1.5 / 2.0 / 2.75 over five
  grades) is close to Model B's first five steps (1.0 / 1.3 / 1.7 / 2.2 / 2.9).
- adventurers-guild's steps (×1.6–2.7) correspond to grade-as-stage. Ours is
  grade-within-level, so smaller steps are right.

Tolerance: ±15% of the target value within a grade, wider only for a listed
specialisation.

## 5. Slot budget recommendations [Recommendation]

Our data already gives each slot a clear role. The audit's tables show it (§4,
"median raw stats"). The recommendation is to write those roles down as the slot
budget and keep them:

| Slot | Primary budget | Secondary | Not in budget | Median Epic value today, Lv 56–70 [Measured, audit §4] |
|---|---|---|---|---|
| weapon | power | crit | defense (token only) | 65% |
| body | max_hp, defense | – | power | 58% |
| head | max_hp, defense | crit | power | 42% |
| charm | max_hp | power or crit (specialisation) | – | 41% |
| hands | power, crit | defense | – | 33% |
| feet | defense, attack_speed | speed (movement, not valued) | power | 30% |

Rules:

1. A slot's grade target is met through its primary stats. A secondary stat may
   replace part of a primary stat when the item value still meets the target.
   That is a "specialisation", and it is recorded.
2. Crit and attack speed beyond the set-level caps count for nothing.
   - Endgame Rare and higher sets already exceed the crit cap (audit §6.3).
   - New budget goes into power, HP or defense instead.
3. Flat defense is the most sensitive stat at both ends of the game: very strong
   early, and at the hit floor for enhanced endgame sets. Grade raises should
   favour HP over defense at Lv 50+.

## 6. Compatibility with our item system [Recommendation]

- **IDs and saves:**
  - No ID changes are needed.
  - Stats are data read at runtime (`PlayerProfile.gear_stats`), so a stat change
    needs no save migration.
  - Enhancement levels stay per copy.
- **Enhancement:** `EnhanceRules.bonus_at` scales every grade the same (+10% of
  base per level). Model B needs no change there. Grade ratios carry through
  +0 to +10 unchanged (audit §6).
- **Arena:** rivals take the best item from data (`ArenaLoadout.best_item`), so they
  follow automatically. `test_arena_integrity` and the class-balance tests must be
  re-run.
- **Generated docs and Guide:**
  - `docs/ITEM_DROP_DATABASE.md` and the Guide pages read item data.
  - After any stat change, run `res://tests/harness/DropReportRun.gd`.
- **Validation:** a new unit test (for example `test_item_grade_budget.gd`) can
  read the audit's value formula from a small pure helper in `client/sim/`. It
  would check the grade targets and inversions, with an allowlist of deliberate
  specialisations.
- **World bosses and Godforged:** Model B keeps Godforged values as they are. No
  reward table, source or raid label changes. Source questions stay in
  `docs/GODFORGED_IMPACT_REPORT.md`.

## 7. Licences and commercial use

This is not legal advice. It records what the repositories contain at the commits
read.

| Repository | Licence | May we reuse code commercially? | Conditions |
|---|---|---|---|
| ClarkWain/godot-arpg-kit | MIT | Yes | Keep the copyright and licence notice with any copied portion. Its docs and comments are in Chinese. Check any assets separately (none were reviewed). |
| Menkos/inventory-forge | MIT | Yes | Keep the copyright and licence notice. It is an editor plugin; we would adapt ideas, not ship the plugin. |
| GiuffreLab/adventurers-guild | none | **No**, without the author's written permission | With no licence, default copyright applies. Ideas and general techniques are not copyrightable, but code and data (item lists, curves) must not be copied. |
| Jegethy/idle-godot | none (a README line only) | **No**, without permission | "Available for educational purposes" grants no rights to copy or distribute, so treat it as unlicensed. |
| BAK2K3/CIRPG | none | **No**, without permission | Default copyright. The README's images are hosted externally. |

Nothing from any of the five was copied into this repository. The
recommendations above are general techniques: separate multipliers, cap-aware
budgets, validation warnings and loadout comparison. We would implement them in
our own code.
