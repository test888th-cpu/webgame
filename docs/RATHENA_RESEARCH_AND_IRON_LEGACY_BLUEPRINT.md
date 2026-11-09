# rAthena Research and Iron Legacy Blueprint

## What this document is

This is research and design only. Nothing in it is implemented, and every proposal waits for the owner's approval.

- **Reference studied:** rAthena, https://github.com/rathena/rathena, commit `d4b8e7b8f16061cc2496d377ac8f777ce72a4f39` (6 Oct 2026). It was cloned outside this repository and read only.
- **Game compared:** The Iron Legacy, branch `claude/festive-curie-v1u8j1`, with the gameplay as on `main` at `1cd3bdb`. The measurements come from `docs/COMBAT_AND_PROGRESSION_BALANCE_AUDIT.md`.
- **Single document:** the system comparison (§18) and the combat and progression design (§19) are kept here instead of in two more files, so there is one source and no contradictions.

**Evidence labels:**

| Label | Meaning |
|---|---|
| [VERIFIED] | Read in source or data, with the file and function named |
| [MEASURED] | Reproduced by running code |
| [INFERRED] | Strongly implied by the implementation |
| [PROPOSED] | A new design for The Iron Legacy |
| [UNKNOWN] | Cannot be established now |

**Licence:**
- rAthena is GPL-3.0 (`LICENSE`) [VERIFIED].
- No rAthena code, database rows, item, monster or NPC content is copied here or into the game.
- Formulas are described in my own words, as mathematical facts about how the system behaves.
- Monster figures are aggregate statistics (medians by level band) computed from the databases, not entries.
- Every Iron Legacy proposal uses original formulas and the game's own data.
- Implementing anything derived from rAthena would still need the owner's approval and a licence review (§20).

---

## 1. Executive summary

**Lessons from rAthena** for a game whose problem is "ordinary gear carries a hero everywhere":

1. **A character's level is worth little by itself; gear is worth a lot.**
   - In Renewal, the stat part of attack gains only a quarter point per base level (`status_base_atk`).
   - Max HP comes from a per-job table scaled by VIT (`status_calc_maxhp_pc`).
   - Weapon attack, refine and cards carry the rest [VERIFIED].
   - In The Iron Legacy, level gives every hero +0.05 power and +10 HP a level. That is 30–60% of a late hero's power and most of its HP [MEASURED, audit §7].
2. **Defense is a curve, not a flat cut.**
   - Pre-Renewal: equipment DEF is a percentage, `(100 − DEF)%` with DEF capped at 100, plus a flat cut from VIT with a random part.
   - Renewal: `damage × (4000 + eDEF) / (4000 + 10·eDEF) − sDEF`, a hybrid with diminishing returns (`battle_calc_defense_reduction`) [VERIFIED].
   - The Iron Legacy's `max(1, raw − def)` makes gear worthless against small hits and makes high defense immune [VERIFIED / MEASURED].
3. **Monsters grow much faster than linearly with level.**
   - Renewal normal monsters' median HP per level rises from 30 at levels 25–49 to about 12,700 at 175–199. Median attack rises from 68 to about 3,900 [MEASURED from `db/re/mob_db.yml`].
   - The Iron Legacy's enemies grow linearly: +6% HP and +8% power a level (`LevelRules.enemy_stats`) [VERIFIED].
4. **Being swarmed is dangerous.**
   - When 3 or more monsters target a player, FLEE falls 10% per extra attacker (`agi_penalty_*` in `conf/battle/battle.conf`, applied in `is_attack_hitting`). DEF can fall the same way (`vit_penalty_*`) [VERIFIED].
   - The Iron Legacy caps attackers at 2 (`ZoneSim.MAX_ATTACKERS`) [VERIFIED].
5. **Big rewards follow damage and survival.**
   - Experience is split by each player's share of the damage (`mob_dead`, `exp_calc_type`).
   - The MVP is the living player on the map with the most damage dealt plus damage tanked; dead players are skipped (`mob_data::get_mvp_player`) [VERIFIED].
   - Healing items are not limited by fight; preparation is enforced by damage, not by food rules [INFERRED from the battle code having no per-fight item cap].

**Design direction for The Iron Legacy** [PROPOSED]. It keeps food unlimited and unchanged, and world-boss entries unlimited, as the owner requires:
- A **hybrid defense curve with a damage floor**, defense treated differently for heavy telegraphed attacks.
- **Level supplies less, gear and enhancement more.**
- **Enemy damage curves by role and chapter**, and boss attacks sized to **bursts that food cannot cover** inside its fixed 2-second cooldown.
- A small **swarm penalty** in place of the 2-attacker comfort cap.
- World bosses reward **damage and survival**, as the MVP rule does.

---

## 2. rAthena architecture overview

[VERIFIED by source tree; roles from file names and code]

| Part | Path | Responsibility |
|---|---|---|
| Login server | `src/login/` | Accounts, authentication |
| Char server | `src/char/` | Characters, persistence, inter-server data (guilds, parties, storage) |
| Map server | `src/map/` | The world: combat (`battle.cpp`), stats (`status.cpp`), monsters (`mob.cpp`), players (`pc.cpp`), parties (`party.cpp`), NPC script engine (`npc.cpp`, `script.cpp`), client packets (`clif.cpp`) |
| Shared code | `src/common/` | Constants such as `MAX_PARTY 12` (`mmo.hpp`), sockets, SQL |
| Databases | `db/re/`, `db/pre-re/`, `db/import-tmpl/` | YAML data per game mode. `import` overrides let a server customise without editing the base files |
| Configuration | `conf/battle/*.conf` | Battle rules as switches and rates (hit rates, penalties, drop and experience rates) |
| Content scripts | `npc/` | Shops, refiners, warps, quests and events as scripts on the map server |
| Documentation | `doc/` | Script commands, item bonus language, monster modes |

**Transferable principles:**
- Separate servers by responsibility.
- Rules in one place (`battle.cpp`) fed by data (`db/`) and switches (`conf/`).
- Content as data or scripts.
- An import layer for local overrides.

Renewal and Pre-Renewal are compile-time branches (`#ifdef RENEWAL`) over the same code, with separate databases [VERIFIED].

## 3. Source files researched

| Area | Path | Function / identifier |
|---|---|---|
| Physical attack order | `src/map/battle.cpp` | `battle_calc_weapon_attack` (line about 5387) |
| Base weapon damage, variance, size | `battle.cpp` | `battle_calc_base_damage`, `battle_calc_sizefix` |
| Defense | `battle.cpp` | `battle_calc_defense_reduction` |
| Hit and flee | `battle.cpp` | `is_attack_hitting` |
| Critical | `battle.cpp` | `is_attack_critical` |
| Element, race, size and card fixes | `battle.cpp` | `battle_attr_fix`, `battle_calc_element_damage`, `battle_calc_cardfix` |
| Skill ratio and additions | `battle.cpp` | `battle_calc_attack_skill_ratio`, `battle_calc_skill_constant_addition` |
| Final damage, maps | `battle.cpp` | `battle_calc_damage`, `battle_calc_gvg_damage`, `battle_calc_bg_damage`, `battle_calc_pk_damage` |
| Derived stats | `src/map/status.cpp` | `status_calc_misc`, `status_base_atk`, `status_base_atk_min/max`, `status_calc_maxhp_pc` |
| Refine | `status.cpp` | `RefineDatabase`, refine application near `wa->atk2 += info->bonus / 100` and `refinedef += info->bonus` |
| Refine data | `db/re/refine.yml`, `db/pre-re/refine.yml` | Groups Armor and Weapon (levels 1–5), per refine level: Bonus, RandomBonus, Chances (Rate, BreakingRate) |
| Monsters | `db/re/mob_db.yml`, `db/pre-re/mob_db.yml` | Level, Hp, Attack, Attack2, Defense, MagicDefense, stats, Size, Race, Element, Ai, Class, Modes, Drops, MvpDrops |
| Monster modes | `doc/mob_db_mode_list.txt` | MD_MVP, MD_KNOCKBACKIMMUNE, MD_STATUSIMMUNE, MD_DETECTOR, AI presets |
| Death, experience, MVP, drops | `src/map/mob.cpp` | `mob_dead`, `mob_data::get_mvp_player`, drop-rate adjustment (about lines 2820–2890) |
| Level penalty | `db/re/level_penalty.yml` | Exp and Drop rates by level difference |
| Experience and HP tables | `db/re/job_exp.yml`, `db/re/job_basepoints.yml` | BaseExp per level, BaseHp per level |
| Battle switches | `conf/battle/battle.conf` | `min_hitrate`, `max_hitrate`, `agi_penalty_*`, `vit_penalty_*` |
| Party | `src/map/party.cpp`, `src/common/mmo.hpp` | Even-share bonus (`party_even_share_bonus`), `MAX_PARTY` |
| NPC content | `npc/merchants/`, `npc/re/merchants/`, `npc/warps/` | Refiners, shops, socket and enchant services, warps by city, dungeon and field |

## 4. Renewal vs Pre-Renewal comparison

| System | Pre-Renewal principle | Renewal principle | Recommended direction for The Iron Legacy |
|---|---|---|---|
| Physical damage | Weapon damage varies between a DEX-based minimum and the weapon's attack. Status attack is STR + (STR/10)² + DEX/5 + LUK/5, so every 10 STR adds a growing bonus [VERIFIED, `status_base_atk`, `battle_calc_base_damage`] | Damage is built from parts (status, weapon, equipment, mastery) with separate modifiers. Status attack is STR + DEX/5 + LUK/3 + Level/4 [VERIFIED, `status_base_atk`; parts in `battle_calc_weapon_attack`] | Keep one power stat, but split it into **level power (small)** and **gear power (large)**, as Renewal does [PROPOSED] |
| Defense | Equipment DEF is a percentage cut (DEF capped at 100), then VIT subtracts a flat amount with a random part [VERIFIED, `battle_calc_defense_reduction`] | `damage × (4000+eDEF)/(4000+10·eDEF) − sDEF`: a curve that never reaches 100%, plus a flat soft part [VERIFIED] | **A hybrid curve plus a small flat part and a floor of 15% of the raw hit** (§6, model C/D) [PROPOSED] |
| Equipment | Weapon level (1–4) sets refine gains; cards add bonuses [VERIFIED, refine.yml groups; item scripts] | Weapon levels 1–5 and armor levels 1–2; grade enchant systems (`enchantgrade.yml`) [VERIFIED by file] | Keep The Iron Legacy's grades and budget (`ItemRules`); let grade set enhancement gains (§8) [PROPOSED] |
| Refinement | Flat attack per refine level by weapon level (+2 to +7 a level), random over-refine bonus past the safe limit; armor +0.7 DEF a level; failure past the safe limit breaks the item in this table [VERIFIED, `db/pre-re/refine.yml`] | Same shape, larger and to +20; armor gains rise faster after +4; past +10 a failure breaks the item 20% of the time for armor level 1 and weapon levels 1–4, and 100% for armor level 2 and weapon level 5 [VERIFIED, `db/re/refine.yml`] | Keep the no-loss enhancement (failure keeps the item and level; pity) and its economy; change only what a level gives, scaled by grade (§8) [PROPOSED] |
| Level scaling | Level adds to hit and flee one for one, little to attack [VERIFIED, `status_calc_misc`] | Level adds to hit, flee and soft DEF/2, and attack by Level/4 [VERIFIED] | Reduce per-level power; keep per-level HP smaller than gear HP by midgame [PROPOSED] |
| Monster balance | Monsters grow steeply: median normal HP per level 40 → 370 between levels 0–24 and 75–99 [MEASURED] | Steeper and longer, to level 200 [MEASURED] | Enemy damage and HP grow faster than linearly by chapter, by role [PROPOSED] |
| EXP progression | Level difference penalty optional (config) [INFERRED from conf] | `level_penalty.yml`: up to +40% experience 10 levels above you, and as little as 10% at 31 below; drops reduced up to 50% at ±16 [VERIFIED] | The Iron Legacy already uses threat bands (`LevelRules.THREATS`); keep them; no drop penalty (player freedom) [PROPOSED] |

**Which mechanics help or hurt progression:**
- **Help:** Renewal's diminishing-returns defense (no immunity) and its small level share of attack. Pre-Renewal's percentage DEF made high DEF very strong (a near-cap DEF cut nearly all damage) [INFERRED].
- **Hurt:** refine with item breaking punishes heavily, and the game's owner wants a fair loop. Pre-Renewal's quadratic STR bonus snowballs.

## 5. Character status system

**rAthena** [VERIFIED, `status_calc_misc`, `status_base_atk`, `status_calc_maxhp_pc`; Renewal unless noted]:

| Stat | What it gives |
|---|---|
| STR | Status attack |
| AGI | FLEE (+1 each), soft DEF (+1 per 5), attack speed |
| VIT | Max HP (+1% each), soft DEF (+1 per 2) |
| INT | Magic attack and magic defense |
| DEX | HIT (+1 each), minimum weapon damage, status attack (+1 per 5) |
| LUK | Crit (+0.3 each), perfect dodge (+0.1 each), status attack (+1 per 3) |

**Derived stats:**
- HIT = level + DEX + LUK/3 + 175.
- FLEE = level + AGI + LUK/5 + 100.
- Hit chance = HIT − FLEE (Pre-Renewal adds a base of 80), bounded by `min_hitrate` 5 and `max_hitrate` 100.

**Diminishing returns:** come from the defense curve and the hit bounds, not from the stats themselves; Pre-Renewal's (STR/10)² is even increasing [VERIFIED].

**Level:** gives little directly: HP grows through the job's table, attack by Level/4 [VERIFIED].

**The Iron Legacy** [VERIFIED, `PlayerProfile.stats`]:
- Stats: max_hp, power, defense, speed, crit and attack_speed.
- No allocatable stats, no HIT/FLEE: every attack in reach lands unless dodged, guarded or parried.

**Recommendation** [PROPOSED]:
- **Do not add the six RO attributes.** In a street brawler, aiming and dodging are the player's own hands, and HIT/FLEE would turn them into dice.
- Keep the six combat stats, plus at most **two new ones that create decisions:**
  - **Guard** (block reduction and stamina, today a fixed 20% and 1.5 energy per damage): lets a tank build exist.
  - **Toughness** (resistance to stun and knockdown, today fixed): lets heavy gear trade speed for staying on your feet.
- Re-split the sources of power:

  | Source | Level 50 power, today | Level 50 power, proposed |
  |---|---|---|
  | Hero base | about 1.0 | about 1.0 |
  | Level | +2.45 | about +1.5 (`per_level.power` 0.05 → about 0.03) |
  | Gear | +1.7 (B) to +4.4 (D) | about +2.5 (B) to +6 (D) |

  Then level supplies about a quarter of a late hero's power and gear about two thirds, close to Renewal's balance in spirit.

## 6. Damage calculation and defense

### rAthena's physical attack order

From `battle_calc_weapon_attack` [VERIFIED; Renewal path where the two differ]:

1. Multi-hit check (`battle_calc_multi_attack`).
2. Critical check (`is_attack_critical`). Crit chance is reduced by the target's LUK: 2 per point, or 3 when a monster is attacking a player.
3. Hit check (`is_attack_hitting`): HIT − FLEE, the swarm penalty, then the bounds.
4. Base damage: status, weapon and equipment parts. Each part has variance, and weapon damage is adjusted for the target's size (`battle_calc_base_damage`, `battle_calc_sizefix`).
5. Skill ratio (`battle_calc_attack_skill_ratio`), then skill constant additions.
6. Card, race and size fixes on the parts (`battle_calc_cardfix`).
7. Defense (`battle_calc_defense_reduction`), unless the attack ignores or pierces it. Some skills use a simple flat cut instead.
8. Post-defense modifiers (`battle_calc_attack_post_defense`).
9. Element (`battle_calc_element_damage` via `attr_fix.yml`).
10. Renewal applies the critical bonus here.
11. Final modifiers, then `battle_calc_damage` (barriers, map damage rules for guild war, battlegrounds and PvP).

Order matters: defense applies after the skill ratio and before element, so a strong skill is reduced as a percentage, not wiped out by a flat cut [VERIFIED].

**Minimum damage:** Renewal's curve never reaches zero, and soft DEF is subtracted after it. Pre-Renewal caps equipment DEF at 100. The VIT penalty keeps soft DEF at least 1 [VERIFIED].

### The Iron Legacy today

`CombatRules._apply_hit`, `damage_for` [VERIFIED]:
- `max(1, round(move.damage × power) − defense)`.
- Then counter ×1.5, crit ×1.5 (hero only), guard ×0.2.
- Hazards: `max(1, damage − defense)`.

**Weaknesses** [MEASURED, audit]:
- **Flat cut:** small hits deal 1–3 in chapter 1, and D at level 48 takes 1 per light hit (defense 66 against 53).
- **No curve and no floor**, other than 1 damage.
- **Level carries power:** 30–60% of a late hero's power.
- **Boss bases are uneven:** the chapter 1 Baron hits hardest per hit; the Security Chief is nearly harmless.

### Four models

Simulated on the game's own level-48 numbers [MEASURED by calculation; inputs from audit §11–12]:

| Model | Formula |
|---|---|
| **A, current** | `max(1, raw − def)` |
| **B, percentage** | `raw × K/(K + def)`, K = 2 × enemy level (100 at level 50) |
| **C, hybrid** | `max(0.15·raw, raw × K/(K+def) − 0.25·def)` |
| **D, by attack type** | Light hits use C. Heavy and telegraphed attacks count defense at half and keep at least 40% (`max(0.4·raw, raw × K/(K + def/2))`) |

The four defense levels come from the profiles:

| Defense | Profile | HP |
|---|---|---|
| Low, 15 | A | 705 |
| Medium, 23 | B | 885 |
| High, 34 | C (+5) | 1,059 |
| Endgame, 66 | D (+10) | 1,375 |

| Model | Attack (raw) | A undergeared dmg / hits-to-die | B basic dmg / hits-to-die | C +5 dmg / hits-to-die | D +10 dmg / hits-to-die | D÷A hits |
|---|---|---|---|---|---|---|
| A current flat | Normal light (avg mob) (53) | 38 / 19 | 30 / 30 | 19 / 56 | 1 / 1375 | 74.1× |
| A current flat | Strong (max mob light) (81) | 66 / 11 | 58 / 15 | 47 / 23 | 15 / 92 | 8.6× |
| A current flat | Elite heavy (max) (163) | 148 / 5 | 140 / 6 | 129 / 8 | 97 / 14 | 3.0× |
| A current flat | Story boss light (Director) (59) | 44 / 16 | 36 / 25 | 25 / 42 | 1 / 1375 | 85.8× |
| A current flat | Story boss heavy (Director) (128) | 113 / 6 | 105 / 8 | 94 / 11 | 62 / 22 | 3.6× |
| A current flat | World boss heavy (Colossus) (168) | 153 / 5 | 145 / 6 | 134 / 8 | 102 / 13 | 2.9× |
| B percent K=2xLv | Normal light (avg mob) (53) | 46 / 15 | 43 / 21 | 40 / 26 | 32 / 43 | 2.8× |
| B percent K=2xLv | Strong (max mob light) (81) | 70 / 10 | 66 / 13 | 60 / 18 | 49 / 28 | 2.8× |
| B percent K=2xLv | Elite heavy (max) (163) | 142 / 5 | 133 / 7 | 122 / 9 | 98 / 14 | 2.8× |
| B percent K=2xLv | Story boss light (Director) (59) | 51 / 14 | 48 / 18 | 44 / 24 | 36 / 38 | 2.8× |
| B percent K=2xLv | Story boss heavy (Director) (128) | 111 / 6 | 104 / 9 | 96 / 11 | 77 / 18 | 2.8× |
| B percent K=2xLv | World boss heavy (Colossus) (168) | 146 / 5 | 137 / 6 | 125 / 8 | 101 / 14 | 2.8× |
| C hybrid | Normal light (avg mob) (53) | 42 / 17 | 37 / 24 | 31 / 34 | 15 / 92 | 5.5× |
| C hybrid | Strong (max mob light) (81) | 67 / 11 | 60 / 15 | 52 / 20 | 32 / 43 | 4.1× |
| C hybrid | Elite heavy (max) (163) | 138 / 5 | 127 / 7 | 113 / 9 | 82 / 17 | 3.3× |
| C hybrid | Story boss light (Director) (59) | 48 / 15 | 42 / 21 | 36 / 29 | 19 / 72 | 4.9× |
| C hybrid | Story boss heavy (Director) (128) | 108 / 7 | 98 / 9 | 87 / 12 | 61 / 23 | 3.5× |
| C hybrid | World boss heavy (Colossus) (168) | 142 / 5 | 131 / 7 | 117 / 9 | 85 / 16 | 3.3× |
| D by attack type | Normal light (avg mob) (53) | 42 / 17 | 37 / 24 | 31 / 34 | 15 / 92 | 5.5× |
| D by attack type | Strong (max mob light) (81) | 67 / 11 | 60 / 15 | 52 / 20 | 32 / 43 | 4.1× |
| D by attack type | Elite heavy (max) (163) | 152 / 5 | 146 / 6 | 139 / 8 | 123 / 11 | 2.4× |
| D by attack type | Story boss light (Director) (59) | 48 / 15 | 42 / 21 | 36 / 29 | 19 / 72 | 4.9× |
| D by attack type | Story boss heavy (Director) (128) | 119 / 6 | 115 / 8 | 109 / 10 | 96 / 14 | 2.4× |
| D by attack type | World boss heavy (Colossus) (168) | 156 / 5 | 151 / 6 | 144 / 7 | 126 / 11 | 2.4× |

**Reading the table:**
- **Model A** makes D immune to light hits: 1,375 hits to die. The A–D ratio swings from about 3× (heavy hits) to 86× (light hits). That is the current problem: gear means everything against small hits and little against big ones.
- **Model B** gives a constant 2.8× everywhere. It is fair and readable, but a little flat for light hits, where gear should matter more.
- **Model C** gives 3–5.5× and keeps a floor, so nobody is immune.
- **Model D** keeps C for ordinary blows. It makes heavy, telegraphed boss attacks about equally dangerous to everyone: only 2.4× apart, at least 40% of the raw hit. So **gear protects you from attrition, and dodging protects you from the big attacks** (Principle 3).

**Recommendation** [PROPOSED]:
- **Model D**, with K and the floors in data (progression.json).
- Keep the 1-damage minimum only for training dummies.
- Move element, race and size to "not now": the game has no elements or races, and adding them is complexity without decisions for a brawler.

## 7. Equipment and item system

**rAthena** [VERIFIED]:
- Equipment slots by position. Weapon types and levels (1–5) set refine gains.
- Items carry scripted bonuses (`doc/item_bonus.txt`) and cards in sockets (socket services in `npc/merchants/socket_enchant*.txt`). Some equipment requires a level.
- Combinations exist as item combos in the item database [INFERRED from item_db docs].

**The Iron Legacy** [VERIFIED, audit §7]:
- 6 slots, 84 items, 5 grades with a budget formula, fixed stats, a level gate.
- No sets, sockets or random stats.

**Recommendation** [PROPOSED]: keep the identity, which is street gear with grades.

| Grade | Where it comes from | Role |
|---|---|---|
| Common / uncommon | Shops, ordinary drops | The baseline for the chapter |
| Rare | Elites and farming-ground elites | A reason to farm a district |
| Epic | Story bosses | The chapter's signature piece |
| Legendary | World bosses and rare boss drops | The long goal |

- **Replacement rhythm:** each chapter's shop set is beaten by its own epics. The next chapter's shop catches up with the last chapter's epic +5. So a +5 epic stays useful about one chapter and a +10 legendary about two.
- **Sets** (optional, after the formula work): 2- and 4-piece bonuses for each chapter's epic pieces, inside the grade budget (`ItemRules`), so completing a set is a choice and not a wall.

## 8. Refinement (enhancement)

**rAthena** [VERIFIED, `db/*/refine.yml`, `status.cpp`]:
- **Gains per level:** flat attack by weapon level (Pre-Renewal +2, +3, +5 and +7 a level for weapon levels 1–4), and armor +0.7 DEF a level. Renewal is larger and goes to +20.
- **Over-refine:** past the safe limit, a random bonus up to RandomBonus is added to each hit.
- **Success:** 100% to the safe limit (+4 to +7 depending on weapon level). Pre-Renewal then falls to 60%, 40% and 20% (10% for some).
- **Breaking:** in those tables a failure past the safe limit breaks the item (BreakingRate 100%). In Renewal, past +10 a failure breaks 20% of the time for armor level 1 and weapon levels 1–4, and 100% for armor level 2 and weapon level 5.
- **Share of power:** refine is a large part of a weapon's attack, but cards and the weapon's own attack also matter.

**The Iron Legacy** [VERIFIED, audit §8]:
- +10% of the item's own positive stats a level, so +10 is 2.0× the item.
- Rates 100% → 20%; a failure keeps the item and its level and adds 5% pity.
- Expected cost to +10 per item: about 9,300 coins, 78 scrap and 24 alloy.

**Recommendation** [PROPOSED]. The enhancement economy (costs, rates, pity, no loss) is not changed:

| Question | Recommendation |
|---|---|
| Base vs enhancement share | About 65% of a late hero's gear power from the item, 35% from enhancement at +10 (today 50/50 at +10) |
| Grade scaling | Higher grades gain a little more a level (uncommon 8%, rare 9%, epic 10%, legendary 11%), so enhancing the best piece is worth it |
| +5 vs +10 | +5 ≈ the next chapter's shop piece; +10 ≈ +60% over +5 in the item's stats, not a doubling |
| Boss survivability | Through defense and HP on the curve (§6), not through a separate boss stat |
| Farming efficiency | Through power, so +5 clears a district about 25% faster |
| No breaking | Keep it: The Iron Legacy is a fair-loop browser game |

## 9. Monster and boss database

**rAthena** [VERIFIED, `mob_db.yml` header; modes doc]:
- Fields: Level, Hp, BaseExp, JobExp, MvpExp, Attack/Attack2, Defense, MagicDefense, six stats, ranges, Size, Race, Element, speeds, Ai preset, Class (Normal, Boss, Guardian…), Modes, Drops, MvpDrops.
- MVPs: MD_MVP makes them resist Coma, shows the MVP sign, and pays MVP experience and items. Bosses are often knockback- and status-immune.

**Median statistics** (computed by me; not data entries) [MEASURED]:

| Renewal | Median HP | Median attack |
|---|---|---|
| Normal, levels 25–49 | 1,176 | 68 |
| Normal, levels 100–124 | 25,020 | 680 |
| Normal, levels 175–199 | 2.4 million | 3,894 |
| MVP, levels 100–124 | 2.8 million | 2,868 |

- MVPs carry about 100× a normal monster's HP at the same level.
- Pre-Renewal normal monsters' HP per level rises 40 → 370 from levels 0–24 to 75–99.
- Renewal entries of about 2 billion HP at levels 100–124 are guild or event objects (Boss class), not fights [INFERRED].

**The Iron Legacy** [VERIFIED, enemies.json]:
- 38 kinds. Base stats on a level-1 scale, then linear growth.
- Roles exist in practice: normal, elite (`elite: true`), boss (`boss: true`), world boss (world_boss.json). Phases, hazards, shields and summons are data.

**Proposed structure:** add only the fields that create decisions [PROPOSED]:

| Field | Meaning |
|---|---|
| `role` | `normal`, `strong`, `elite`, `story_boss` or `world_boss`. Replaces scattered flags. `strong` is a normal kind at +1 tier (a bruiser), for wave variety without elite rewards |
| `chapter_curve` | Which growth curve this kind uses for HP and power: steeper than linear by chapter, per role |
| `intent` (bosses) | `{level, gear_grade, plus, fight_seconds, ttd_seconds}`: the intended player and fight. Used by tests, not by combat |
| `dangerous` (moves) | Heavy and telegraphed attacks: they use the "by type" defense (§6 D) and are named in the boss card |
| `recovery_ticks` (moves) | The opening after a big attack. Today implied by move recovery |

**Story boss intents** [PROPOSED, to be tuned with the harness]:

| Boss | Level | Gear expected | Fight | TTD (no food) | Identity |
|---|---|---|---|---|---|
| Sludge Foreman | 5 | shop +0 | 30–40 s | 40 s | teaches telegraphs, slow |
| Pit Champion | 10 | shop +0 | 30–40 s | 35 s | fast jabs, dodge practice |
| Furnace Baron | 12 | shop +2 | 40 s | 35 s | the chapter 1 wall; heat hazards |
| Harbourmaster Chen | 18 | shop +2 | 40 s | 35 s | hooks pull you into the crane drops |
| Security Chief | 23 | shop +3 / rare | 40 s | 35 s | re-based up; adds and baton combos |
| Unit K-7 | 26 | epic or shop +3 | 45 s | 35 s | shield phases |
| Ringmaster | 29 | epic | 45 s | 35 s | arena hazards |
| Big Sak | 33 | epic +2 | 45 s | 32 s | heavy bruiser |
| Subject Twelve | 37 | epic +3 | 50 s | 32 s | mutation bursts |
| Commander Arthit | 41 | epic +4 | 50 s | 30 s | soldier combos |
| Director Wiroj | 50 | epic +5 | 55 s | 30 s | three phases, every hazard |

## 10. Boss design and MVP philosophy

**rAthena principles** [VERIFIED / INFERRED]:
- MVPs are rare and strong, and appear on a timer: spawn delays are in `npc/` spawn scripts [INFERRED].
- Anyone may fight; rewards go by damage. The MVP prize goes to the living top contributor of damage plus damage tanked (`get_mvp_player`).
- Preparation is enforced by damage, statuses and immunities (`MD_STATUSIMMUNE`, `MD_KNOCKBACKIMMUNE`).

**For The Iron Legacy** [PROPOSED]:
- **Story boss:**
  - It must teach and test. A fight of about 40–55 s, two or three dangerous attacks with clear warnings and a recovery window after each.
  - Fair for the intended profile without food. It is lost by profile A even with food, through bursts (§13), not through endurance limits.
  - Its epic drop is the reward for the chapter.
- **World boss (today, single-player):**
  - One round's pool; unlimited entries, as required.
  - A **dodge-or-fall attack** every phase, sized to a C profile's HP (35–50%).
  - An **announced enrage** in the round's last 20 minutes: faster attacks and a larger hazard volley.
  - Rewards stay "only the kill pays" with personal tiers.
- **World boss (future online):** see §14 and §17. Nothing online exists today [VERIFIED].

## 11. Item drop and farming economy

**rAthena** [VERIFIED, `mob.cpp` drop-rate adjustment, `level_penalty.yml`]:
- Each drop has a rate out of 10,000, adjusted by size (`drop_rate` is halved or doubled by size in some cases), LUK options, item-boost statuses, VIP and caps, and a level-difference drop penalty.
- Item ratios can be overridden (`mob_item_ratio`). MVPs have separate MVP drops.

**The Iron Legacy** [VERIFIED, audit §7]:

| Source | What drops |
|---|---|
| Ordinary enemies | Common (3–4%) and uncommon (4–20%) |
| One elite entry | The only rare drop (35%) |
| Bosses | Epic (20–30%) and legendary (6%, some with pity) |
| Farming-ground elites | 3 extra loot rolls and their district's epic prizes |

**Zone-to-item progression** [PROPOSED; uses existing items where they fit, new items need approval]:

| District (farming ground) | Normal enemies | Elites | Story boss | World boss |
|---|---|---|---|---|
| South Street (Saltmarket Backlots, Rail Sidings) | scrap, food, common/uncommon street gear | rare gloves and feet | the Foreman, Champion and Baron epics | — |
| Port District (Harbour Stacks) | scrap, alloy (rare), uncommon dock gear | rare head and body | Chen epics | — |
| Industrial (Plant Outskirts) | alloy, uncommon work gear | rare weapons | Chief and K-7 epics | Tunnel Mother legendaries |
| Black Network (Network Backrooms) | alloy, coins | rare charms | Ringmaster and Sak epics | — |
| Core Facility (Facility Annex) | alloy, high coins | rare high-level gear | Twelve and Arthit epics | — |
| Iron Legacy (Core Overflow) | top materials | rare level 45–50 | Director epics | Colossus and Subject Zero legendaries |

Each district then has gear found nowhere else, so visiting districts is worth it [PROPOSED].

## 12. Character level and EXP progression

**rAthena** [VERIFIED, `job_exp.yml`, `level_penalty.yml`, `mob_dead`]:
- Experience per level grows steeply: for example 42,165 at level 50, 143,684 at 75 and 1.25 million at 98 for first jobs. Second and third tables run on to 200.
- Monster experience goes by damage share, with a level-difference bonus or penalty.

**The Iron Legacy** [VERIFIED, progression.json `xp`]:
- `100 + 100·(level−1) + 5·(level−1)²` per level, with threat bands for experience.
- One story pass ends at level 47–49 (`test_harness.gd`).

**Recommendation** [PROPOSED]:
- Keep the curve and the bands.
- **Do not add drop penalties.** Farming freedom matters, and gear is the gate instead.
- With §5's power split, a level 50 hero in poor gear has about the power of a level 40 hero in fitting gear. A high level alone no longer outperforms preparation.

## 13. Healing and survivability (owner requirements)

**Fixed and kept exactly as they are** [VERIFIED behaviour]:
- Food heals 25, 50, 120 and 220 instantly.
- 2-second shared cooldown (`skills.json item_cooldown = 120`).
- No caps of any kind. Auto battle eats below 50% HP.
- World-boss entries are unlimited.

**Why an undergeared hero can still fall with unlimited food** [INFERRED by calculation; PROPOSED design]:
- **Rate:** food restores at most 220 HP per 2 s, so 110 HP/s. Damage taken at the final boss is 10–43 per second today [MEASURED], so on rate alone any hero survives.
- **So the answer is burst, not rate.**
  - Auto battle and most players eat once below half health. After eating, nothing can be eaten for 2 s.
  - A sequence of hits that removes more than the remaining half inside that window kills, however much food is carried.
  - With model D, a telegraphed heavy boss attack of raw R deals about 0.93R to profile A and 0.75R to profile D.
- **Worked example: the Director with heavy attacks re-based to about 190 raw** (one heavy, or a heavy plus hazard, inside 2 s):

  | Profile | HP | One heavy hit | Two heavies inside 2 s |
  |---|---|---|---|
  | A | 705 | about 177 (25%) | about 354, the whole half left after eating: falls |
  | D | 1,375 | about 142 (10%) | 21%: comfortable |

- **Dodging** (12 invulnerable ticks out of a 20-tick dodge) avoids a heavy entirely, so a skilled A player survives by skill, which is fair.
- **Survival then depends on gear** (HP and defense against bursts) **and skill** (dodging), not on food stock. No food rule changes.
- **Attrition:** keep ordinary damage below the heal rate, so food stays a comfort and not a wall.

## 14. Party and multiplayer design

**rAthena** [VERIFIED]:
- Parties up to 12 (`MAX_PARTY`), an even-share experience bonus (`party_even_share_bonus`), experience by damage, the MVP by damage plus tanking.
- Swarm penalties on FLEE and DEF. Monster targeting rules by AI mode: change-target, assist, random target in some presets.

**The Iron Legacy:**
- Single-player.
- No parties, no server combat, no shared pools. The backend is accounts and saves (`backend/src`) [VERIFIED].

**Future architecture** [PROPOSED; nothing to implement now]:
- **Parties of 5** for party bosses.
  - Experience by damage share, with a small bonus per member (as an even-share bonus).
  - Loot rolled per player, so there is no loot fighting.
- **Server-authoritative**, reusing the pure `client/sim` rules on the IL-7 zone server, with seeded RNG:
  - damage
  - boss HP and phases
  - drops
  - contribution
  - death and respawn
- **Contribution** = damage dealt + damage taken while alive near the boss (as `get_mvp_player` counts dealt plus tanked).
- **Reward eligibility:** the round's kill pays everyone above a minimum contribution, and the top contributor alive gets a prize roll. The current single-player rule (falling keeps your damage) stays as is unless the owner approves a change.
- **Anti-cheat:** clients send inputs only. The server validates movement, cooldowns and reach, and rate-limits actions.
- **Death and respawn:** respawn at the arena entrance after 10 s. Entries stay unlimited.

## 15. NPC and world structure

**rAthena** [VERIFIED by `npc/` tree]:
- NPCs are scripts: shops (`npc/merchants/shops.txt`), refiners (`refine.txt`, `advanced_refiner.txt`, `blessed_refiner.txt`), socket and enchant services, warps by city, dungeon and field (`npc/warps/`), quests and events.
- They run on the map server's script engine and are configurable.

**The Iron Legacy** [VERIFIED, areas.json `npcs`, CITY_AND_FARMING_BLUEPRINT.md]:
- NPCs are data roles in areas: quests, shop, taxi (story and farming), workbench and others.
- The quest card handles quests from anywhere (PR #72).

**Proposal** [PROPOSED]: keep NPCs as data roles with one handler per role (as today). Add roles only when a service needs one:

| Place | NPCs / services |
|---|---|
| Main City | Workbench (enhance), item shop, storage (new), market (future, online), guild (future), quest givers, farming and story taxis (existing), world-boss board (event times, rewards, the gear advice) |
| Story areas | Quest givers, boss gate (the boss card: intended gear, dangerous attacks) |
| Farming grounds | Entry board (level, prizes, elites); farming opens and auto battle is allowed as soon as its story requirement is met, as today, with no separate manual first clear |
| World-boss arenas | Round timer, participation, reward tiers |

## 16. Architecture comparison

| Principle | rAthena | The Iron Legacy now | Proposal |
|---|---|---|---|
| Combat logic separate | `battle.cpp`, `status.cpp` on the map server [VERIFIED] | `client/sim/` pure rules [VERIFIED] | Keep; add `DefenseRules`, `StatusRules` helpers (ZoneSim and Game.gd are at the 1000-line limit) |
| Status calculation | One function family | `PlayerProfile.stats` | One `StatusRules.compute(profile)` returning every derived stat, so UI, sim and server agree |
| Item database | YAML plus scripted bonuses | items.json, budget-checked | Keep JSON; no scripts (security, simplicity) |
| Monster database | YAML | enemies.json | Add role, curves and intents (§9) |
| Configuration | `conf/battle` switches | progression.json, skills.json | Gather balance switches in one `balance.json` with validation |
| Content scripts | NPC script engine | Data roles | Keep data roles; no script engine (safer for a browser game) |
| Persistence | Char server and SQL | backend (PostgreSQL), saves | Keep the backend as the only writer |
| Server authority | Map server | Planned IL-7 | Reuse the sim |
| Overrides | `db/import` | none | Not needed now |

## 17. Performance and 4,000 CCU

- **A. Existing, verified:** a browser client and an account/save backend. No zone servers, no shared state, no load tests [VERIFIED].
- **B. Future proposal:**
  - Zone servers (headless Godot export of `client/`, IL-7), each running a few farming grounds or arenas at 60 ticks.
  - A gateway for login and routing; the backend for persistence; one authoritative world-boss shard per boss holding the shared pool.
  - Contribution is batched to the backend once per few seconds; drops are generated on the server.
  - Parties and guilds live in the backend with a cache.
  - In the spirit of rAthena's split of login, char and map, without copying it.
- **C. Unknown:** whether 4,000 concurrent players, or even one world-boss arena of hundreds, fits a Godot headless server's tick budget [UNKNOWN]. It needs load tests of one zone with simulated clients. No CCU claim is made here.

## 18. Comparative analysis

| System | rAthena design | The Iron Legacy current design | Gap | Recommendation and why it fits |
|---|---|---|---|---|
| Character stats | Six allocated attributes feed derived stats; level gives little attack [VERIFIED] | Six combat stats, level gives +0.05 power and +10 HP every level [VERIFIED] | Level carries power | Reduce per-level power, keep stats simple; add Guard and Toughness only. A brawler needs few, readable stats |
| Damage formula | Parts, ratio, defense curve, element, final [VERIFIED] | raw × power − def, crit, guard [VERIFIED] | No curve, no floor | Model D: curve plus floor plus heavy-attack rule. Keeps the brawler's directness |
| Defense | Percentage (Pre-Renewal) or hybrid curve (Renewal) [VERIFIED] | Flat cut, minimum 1 [VERIFIED] | Immunity and uselessness at the ends | Hybrid curve with a 15% floor |
| Equipment | Slots, weapon levels, cards, scripts [VERIFIED] | 6 slots, grades, budget [VERIFIED] | No sets; damage share of gear small | Grade-led gains, optional sets later. Keeps the game's own identity |
| Refinement | Flat gains by weapon level, over-refine, breaking [VERIFIED] | +10% of stats a level, no loss, pity [VERIFIED] | Gains equal for all grades | Grade-scaled gains, no breaking. A fair loop for a browser game |
| Monster database | Rich fields, steep curves [VERIFIED / MEASURED] | Base and linear growth [VERIFIED] | Late enemies too soft relative to the hero | Role and chapter curves, intents |
| Boss mechanics | Immunities, AI modes, skills [VERIFIED] | Phases, hazards, shields, summons [VERIFIED] | Uneven bases; no dodge-or-fall attacks | Dangerous attacks with recovery windows |
| MVP / world boss | MVP to the living top contributor; timed spawns [VERIFIED] | Pool per round, kill pays, unlimited entries [VERIFIED] | No threat growth; persistence beats preparation | Enrage, dodge-or-fall attacks, contribution; entries stay unlimited |
| Item drops | Rates, modifiers, level penalty, caps [VERIFIED] | Fixed chances, pity on some [VERIFIED] | Few rare sources; districts similar | District-specific prizes (§11); no level penalty |
| EXP progression | Steep table, damage share, level penalty [VERIFIED] | Quadratic table, threat bands [VERIFIED] | — | Keep |
| NPC architecture | Script engine [VERIFIED] | Data roles [VERIFIED] | Fewer services | Add roles as needed, no scripting |
| Party system | Up to 12, even share [VERIFIED] | None [VERIFIED] | All | 5-player parties at IL-7 |
| Online architecture | Login / char / map servers [VERIFIED] | Backend only [VERIFIED] | Zone servers | IL-7 headless sim, load-tested |

## 19. Recommended Iron Legacy design

All [PROPOSED], with existing food behaviour and entry rules untouched.

1. **Defense:** model D (§6), with K = 2 × enemy level, a 15% floor for ordinary hits and a 40% floor for dangerous attacks. Values in data.
2. **Power sources:**
   - `per_level.power` 0.05 → about 0.03.
   - Gear power budgets up about 40%, through `ItemRules` budget weights, so every item is re-derived, not hand-edited.
3. **HP:** keep +10 a level; raise gear max_hp so gear is about half of a late hero's HP.
4. **Enemies:**
   - HP and power curves by role and chapter (steeper from chapter 3).
   - Re-base the soft bosses (Security Chief up; Subject Twelve and Director re-measured under model D, replacing main's ×1.5 and ×2.2).
   - Elites +20% to +40% damage by chapter.
5. **Swarm:** replace the comfort of `MAX_ATTACKERS = 2` with 3 attackers from chapter 3, plus a small rule: each enemy beyond 2 within reach adds 5% damage taken. A readable version of rAthena's FLEE and DEF penalties.
6. **Bosses:** intents per boss (§9), dangerous attacks with warnings and recovery windows, and burst sizing so food covers attrition but not bursts (§13).
7. **World bosses:**
   - Dodge-or-fall attacks, an announced enrage, contribution tracking. Unlimited entries and the current reward rule kept unless the owner approves a minimum-contribution rule.
8. **Enhancement:** grade-scaled gains (8–11% a level); costs, rates, pity and no-loss unchanged.
9. **Targets** (from the audit, §18): the intended profile's no-food time to die is 30–45 s against its boss; D vs B is about 2× kill speed and about 3× time to die.

## 20. Risks and trade-offs

| Item | Risk | Trade-off |
|---|---|---|
| Defense curve | High: every hit, every tuned number (farm income, harness tests) moves | The one change that fixes immunity and uselessness together |
| Power split | Medium: existing heroes feel weaker until re-geared | Gear matters; announce in patch notes |
| Bursty boss attacks | Medium: frustration if warnings are unclear | Clear telegraphs and recovery windows; test with humans |
| Swarm rule | Low–medium: auto battle must pull carefully | Ordinary fights regain tension |
| Sets | Medium: new system | Optional, last |
| Licence | rAthena is GPL-3.0: copying code or data would bind the project to GPL | Only ideas and maths are used; original formulas and data; a licence review before any code that closely follows rAthena |

## 21. Implementation roadmap

Proposal only; each phase is one PR, measured with the harness before and after:

| Phase | Work | Depends on | Risk |
|---|---|---|---|
| 0 | Owner decides on main's PR #73 changes (food cap, tries, ×2.2 and ×1.5) and the unmerged gear-check commit. The food cap and tries must go per the owner's rules | — | low |
| 1 | `DefenseRules` (model D) behind a data switch; tests for each floor and curve | 0 | high |
| 2 | Power split and gear budgets (`ItemRules`, progression.json); profiles re-measured | 1 | medium |
| 3 | Enemy role and chapter curves, boss re-basing and intents (enemies.json); per-boss TTD tests | 1–2 | medium |
| 4 | Dangerous attacks, recovery windows, swarm rule (BossMechanics, EnemyBrain, ZoneSim helpers) | 3 | medium |
| 5 | World boss enrage and contribution record (single-player) | 4 | medium |
| 6 | Grade-scaled enhancement gains | 2 | low |
| 7 | District prizes and optional sets | 3, 6 | medium |
| 8 | Balance band tests (`test_balance_bands.gd`) in CI | all | low |
| IL-7 | Server authority, parties, shared pools, load tests | the zone server | high |

## 22. Owner approval checklist

- [ ] Remove PR #73's food cap and world-boss tries from main (required by the owner's rules), and decide on the Director ×2.2 and Subject Twelve ×1.5.
- [ ] Decide on the unmerged gear-check commit `15fbb0f` (it fails 2 tests; recommended not to merge).
- [ ] Approve model D (hybrid defense, floors, heavy-attack rule).
- [ ] Approve moving power from level to gear (`per_level.power` about 0.03).
- [ ] Approve the time-to-die and fight-time targets per chapter (§9, §19.9).
- [ ] Approve burst-sized dangerous attacks as the answer to unlimited food.
- [ ] Approve the swarm rule (3 attackers from chapter 3, +5% per extra).
- [ ] Approve the world-boss enrage. Keep or change the reward rule (minimum contribution?).
- [ ] Approve grade-scaled enhancement gains (economy unchanged).
- [ ] Approve district-specific prizes (new items need art and data).
- [ ] Decide on sets (yes / later / no).
- [ ] Confirm the licence position: ideas and maths only, no rAthena code or data.

## 23. Source references

**rAthena** at commit `d4b8e7b8f16061cc2496d377ac8f777ce72a4f39`:
- `src/map/battle.cpp`: `battle_calc_weapon_attack`, `battle_calc_base_damage`, `battle_calc_sizefix`, `battle_calc_defense_reduction`, `battle_calc_attack_post_defense`, `is_attack_hitting`, `is_attack_critical`, `battle_attr_fix`, `battle_calc_element_damage`, `battle_calc_cardfix`, `battle_calc_attack_skill_ratio`, `battle_calc_skill_constant_addition`, `battle_calc_damage`, `battle_calc_gvg_damage`, `battle_calc_bg_damage`, `battle_calc_pk_damage`.
- `src/map/status.cpp`: `status_calc_misc`, `status_base_atk`, `status_base_atk_min`, `status_base_atk_max`, `status_calc_maxhp_pc`, `RefineDatabase` and refine application.
- `src/map/mob.cpp`: `mob_dead`, `mob_data::get_mvp_player`, drop-rate adjustment.
- `src/map/party.cpp`: `party_even_share_bonus` use.
- `src/common/mmo.hpp`: `MAX_PARTY`.
- `db/re/` and `db/pre-re/`: `refine.yml`, `mob_db.yml`, `job_exp.yml`, `job_basepoints.yml`, `level_penalty.yml` (Renewal), `size_fix.yml`, `attr_fix.yml`, `item_db_equip.yml`.
- `conf/battle/battle.conf`: `min_hitrate`, `max_hitrate`, `agi_penalty_type`, `agi_penalty_count`, `agi_penalty_num`, `vit_penalty_*`.
- `doc/mob_db_mode_list.txt`: modes and AI presets.
- `npc/merchants/`, `npc/re/merchants/`, `npc/warps/`.
- `LICENSE` (GPL-3.0).

**The Iron Legacy:**
- `client/sim/CombatRules.gd` (`damage_for`, `_apply_hit`, `thrown_hit`, `is_vulnerable`).
- `client/sim/PlayerProfile.gd` (`stats`, `gear_stats`).
- `client/sim/LevelRules.gd` (`enemy_level`, `enemy_stats`, `enemy_ai`).
- `client/sim/ZoneSim.gd` (`MAX_ATTACKERS`, `use_item`).
- `client/sim/ItemRules.gd`, `EnhanceRules.gd`, `FoodRules.gd`, `WorldBossRules.gd`, `WorldBossRun.gd`, `BossMechanics.gd`.
- `client/data/*.json`.
- `docs/COMBAT_AND_PROGRESSION_BALANCE_AUDIT.md` (all measurements).
