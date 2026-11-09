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

All [PROPOSED], with existing food behaviour and entry rules untouched. **Superseded in part by DESIGN VALIDATION ROUND 2 (§V8):** items 1 (defense), 5 (swarm), 6 (burst) and 7 (enrage).

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

*Replaced by §V10 (Round 2). Kept for the record.*

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


---

# DESIGN VALIDATION ROUND 2

This section is validation only.
- **Gameplay code, data, assets, scenes and the backend:** unchanged.
- **Status:** nothing is approved or implemented.
- **Supersedes:** where this section disagrees with §1–§22 above, this section supersedes them. Each superseded proposal is listed in §V8.

## V0. How it was measured

| Item | What was used |
|---|---|
| Baseline | The game before PR #73 (commit `e0830ed`): unlimited food, unlimited world-boss entries, no global boss multipliers. These are the owner's production rules. |
| Where the candidates ran | A scratch worktree outside the repository. Defense models, the attacker cap and swarm pressure were wired in as test-only switches (patch in §V11). The repository was not touched. |
| Who plays | The game's own auto battle (`AutoPilot`). **Skilled** = as shipped: it dodges telegraphs and guards. **Unskilled** = the same, with every dodge and guard press removed. |
| Heroes, seeds | Oren (tank) and Mika (damage), 1–2 seeds each. Results are averaged; "KO 1/4" means 1 knock-out in 4 fights. |
| Food | "No food" = the starter's 3 buns only. "10 foods" = auto battle's default restock, eaten as the game does today: below 50% HP, 2-second shared cooldown. |
| Labels | [MEASURED] = produced by running the game's own rules. [PREDICTED] = calculated from measurements, not run. [PROPOSED] = design. |

**Profiles** (built from the game's own items; Oren's stats in §V2.1):

| Profile | Gear |
|---|---|
| **A, undergeared** | Starter kit + weapon, body and head of shop gear 10 levels behind, +0 |
| **B, properly equipped** | Full shop gear at level, +0 |
| **B5 / B10** | B at +5 / +10 |
| **C** | Shop armour + the best boss weapon and charm, +5 |
| **D** | The best item of any grade in every slot, +10 |

## V1. Defense formula validation

### V1.1 The candidates, in full

**Shared by every model.** The order is unchanged from the current `CombatRules._apply_hit`; only step 3 differs between models.

1. Perfect guard → parry (no damage).
2. `raw = move.damage × attacker.power` (`damage_for`).
3. **Defense reduction (the model).**
4. Counter: ×1.5 if the defender is exposed.
5. Critical: ×1.5 (hero only; the crit roll).
6. Guard: a blocked hit deals `max(1, round(dmg × 0.2))`.
7. HP is reduced.

Thrown objects and boss hazards use step 3 on their own damage (`thrown_hit`).

**Variables:**

| Symbol | Meaning |
|---|---|
| `raw` | The hit before defense |
| `DEF` | The defender's total defense |
| `L` | The attacker's level (enemy level for enemy attacks, hero level for hero attacks) |
| `heavy` | The move is `telegraph`, `knockdown` or `guard_break`; hazards and throws count as heavy |

**Models:**

| Model | Step 3 | Floor |
|---|---|---|
| **Current** [VERIFIED] | `raw − DEF` | 1 |
| **Percent** [PROPOSED alternative] | `raw × K / (K + DEF)`, K = 2L | 1 |
| **Hybrid** (Round 1) [PROPOSED alternative] | `raw × K / (K + DEF) − 0.25·DEF`, K = 2L | 15% of raw |
| **By attack type** (Round 1 "model D") [PROPOSED alternative] | Ordinary hits as Hybrid. Heavy hits: `raw × K / (K + DEF/2)`, K = 2L | 40% of raw (heavy) |
| **Hybrid-T** (this round) [PROPOSED] | Ordinary: `raw × K / (K + DEF) − 0.1·DEF`. Heavy: `raw × K / (K + DEF/2)`. K = 30 + 2L | 20% of raw, at least 1 (ordinary); 45% of raw (heavy) |

**Why K = 30 + 2L instead of 2L** [MEASURED, V1.2]:
- With K = 2L, the curve is far too steep early. At level 5 (K = 10), 9 DEF halves a hit, and the −0.25·DEF part makes B5 take 1 damage from ordinary blows: 260 hits to die, the immunity problem again.
- The constant 30 keeps early defense mild while keeping the late curve (K = 130 at level 50).

**Behaviour** of hybrid-T [MEASURED by calculation]:
- **Weak attacks:**
  - Never below 20%, so nobody is immune.
  - At level 48, an ordinary light hit of 53 deals 46 (A) to 29 (D).
- **Heavy attacks:**
  - Defense counts at half, never below 45%.
  - The Director's 128 deals 121 (A) to 102 (D). Dodging, not gear, answers them.
- **Boss attacks:** light hits follow the ordinary curve; heavy hits and hazards follow the heavy rule.
- **Minimum damage:** 1 remains only where 20% of raw rounds to 0 (training dummies, tiny hits).

### V1.2 Static comparison at every stage

[MEASURED by calculation]. The attacks are the game's own at each stage (raw = move × scaled power, from the audit's matrix, pre-#73). Each profile's HP and DEF come from `PlayerProfile.stats` (§V2.1). Each cell shows damage per hit, with hits to die in brackets.

**Early (Lv5: Sludge Foreman, canal_works)**: hero level 5, enemy level 5, K = 10. Profiles (HP / DEF): A 185/4, B 230/6, B5 260/9, B10 290/10, D 272/12

| Model | Attack (raw) | A dmg (hits) | B dmg (hits) | B5 dmg (hits) | B10 dmg (hits) | D dmg (hits) | B÷A | B5÷B | D÷B | D÷A |
|---|---|---|---|---|---|---|---|---|---|---|
| Current flat | mob light avg (7) | 3 (62) | 1 (230) | 1 (260) | 1 (290) | 1 (272) | 3.7× | 1.1× | 1.2× | 4.4× |
| Current flat | mob heavy max (25) | 21 (9) | 19 (12) | 16 (16) | 15 (19) | 13 (21) | 1.4× | 1.3× | 1.7× | 2.4× |
| Current flat | boss light (15) | 11 (17) | 9 (26) | 6 (43) | 5 (58) | 3 (91) | 1.5× | 1.7× | 3.5× | 5.4× |
| Current flat | boss heavy (38) | 34 (5) | 32 (7) | 29 (9) | 28 (10) | 26 (10) | 1.3× | 1.2× | 1.5× | 1.9× |
| Percent | mob light avg (7) | 5 (37) | 4 (58) | 4 (65) | 4 (72) | 3 (91) | 1.6× | 1.1× | 1.6× | 2.5× |
| Percent | mob heavy max (25) | 18 (10) | 16 (14) | 13 (20) | 12 (24) | 11 (25) | 1.4× | 1.4× | 1.7× | 2.4× |
| Percent | boss light (15) | 11 (17) | 9 (26) | 8 (32) | 8 (36) | 7 (39) | 1.5× | 1.3× | 1.5× | 2.3× |
| Percent | boss heavy (38) | 27 (7) | 24 (10) | 20 (13) | 19 (15) | 17 (16) | 1.4× | 1.4× | 1.7× | 2.3× |
| Hybrid | mob light avg (7) | 4 (46) | 3 (77) | 1 (260) | 1 (290) | 1 (272) | 1.7× | 3.4× | 3.5× | 5.9× |
| Hybrid | mob heavy max (25) | 17 (11) | 14 (16) | 11 (24) | 10 (29) | 8 (34) | 1.5× | 1.4× | 2.1× | 3.1× |
| Hybrid | boss light (15) | 10 (18) | 8 (29) | 6 (43) | 5 (58) | 4 (68) | 1.6× | 1.5× | 2.4× | 3.7× |
| Hybrid | boss heavy (38) | 26 (7) | 22 (10) | 18 (14) | 16 (18) | 14 (19) | 1.5× | 1.4× | 1.9× | 2.7× |
| By attack type | mob light avg (7) | 4 (46) | 3 (77) | 1 (260) | 1 (290) | 1 (272) | 1.7× | 3.4× | 3.5× | 5.9× |
| By attack type | mob heavy max (25) | 21 (9) | 19 (12) | 17 (15) | 17 (17) | 16 (17) | 1.4× | 1.3× | 1.4× | 1.9× |
| By attack type | boss light (15) | 10 (18) | 8 (29) | 6 (43) | 5 (58) | 4 (68) | 1.6× | 1.5× | 2.4× | 3.7× |
| By attack type | boss heavy (38) | 32 (6) | 29 (8) | 26 (10) | 25 (12) | 24 (11) | 1.4× | 1.3× | 1.4× | 2.0× |

**Early (Lv10: Furnace Baron, gang_hq)**: hero level 10, enemy level 12, K = 24. Profiles (HP / DEF): A 235/4, B 279/7, B5 310/10, B10 338/12, D 432/16

| Model | Attack (raw) | A dmg (hits) | B dmg (hits) | B5 dmg (hits) | B10 dmg (hits) | D dmg (hits) | B÷A | B5÷B | D÷B | D÷A |
|---|---|---|---|---|---|---|---|---|---|---|
| Current flat | mob light avg (13) | 9 (26) | 6 (46) | 3 (103) | 1 (338) | 1 (432) | 1.8× | 2.2× | 9.3× | 16.5× |
| Current flat | mob heavy max (33) | 29 (8) | 26 (11) | 23 (13) | 21 (16) | 17 (25) | 1.3× | 1.3× | 2.4× | 3.1× |
| Current flat | boss light (32) | 28 (8) | 25 (11) | 22 (14) | 20 (17) | 16 (27) | 1.3× | 1.3× | 2.4× | 3.2× |
| Current flat | boss heavy (63) | 59 (4) | 56 (5) | 53 (6) | 51 (7) | 47 (9) | 1.3× | 1.2× | 1.8× | 2.3× |
| Percent | mob light avg (13) | 11 (21) | 10 (28) | 9 (34) | 9 (38) | 8 (54) | 1.3× | 1.2× | 1.9× | 2.5× |
| Percent | mob heavy max (33) | 28 (8) | 26 (11) | 23 (13) | 22 (15) | 20 (22) | 1.3× | 1.3× | 2.0× | 2.6× |
| Percent | boss light (32) | 27 (9) | 25 (11) | 23 (13) | 21 (16) | 19 (23) | 1.3× | 1.2× | 2.0× | 2.6× |
| Percent | boss heavy (63) | 54 (4) | 49 (6) | 44 (7) | 42 (8) | 38 (11) | 1.3× | 1.2× | 2.0× | 2.6× |
| Hybrid | mob light avg (13) | 10 (24) | 8 (35) | 7 (44) | 6 (56) | 4 (108) | 1.5× | 1.3× | 3.1× | 4.6× |
| Hybrid | mob heavy max (33) | 27 (9) | 24 (12) | 21 (15) | 19 (18) | 16 (27) | 1.3× | 1.3× | 2.3× | 3.1× |
| Hybrid | boss light (32) | 26 (9) | 23 (12) | 20 (16) | 18 (19) | 15 (29) | 1.3× | 1.3× | 2.4× | 3.2× |
| Hybrid | boss heavy (63) | 53 (4) | 47 (6) | 42 (7) | 39 (9) | 34 (13) | 1.3× | 1.2× | 2.1× | 2.9× |
| By attack type | mob light avg (13) | 10 (24) | 8 (35) | 7 (44) | 6 (56) | 4 (108) | 1.5× | 1.3× | 3.1× | 4.6× |
| By attack type | mob heavy max (33) | 30 (8) | 29 (10) | 27 (11) | 26 (13) | 25 (17) | 1.2× | 1.2× | 1.8× | 2.2× |
| By attack type | boss light (32) | 26 (9) | 23 (12) | 20 (16) | 18 (19) | 15 (29) | 1.3× | 1.3× | 2.4× | 3.2× |
| By attack type | boss heavy (63) | 58 (4) | 55 (5) | 52 (6) | 50 (7) | 47 (9) | 1.3× | 1.2× | 1.8× | 2.3× |

**Mid (Lv24: Unit K-7, factory_drains)**: hero level 24, enemy level 26, K = 52. Profiles (HP / DEF): A 415/7, B 465/13, B5 518/20, B10 570/24, D 750/32

| Model | Attack (raw) | A dmg (hits) | B dmg (hits) | B5 dmg (hits) | B10 dmg (hits) | D dmg (hits) | B÷A | B5÷B | D÷B | D÷A |
|---|---|---|---|---|---|---|---|---|---|---|
| Current flat | mob light avg (33) | 26 (16) | 20 (23) | 13 (40) | 9 (63) | 1 (750) | 1.5× | 1.7× | 32.3× | 47.0× |
| Current flat | mob heavy max (58) | 51 (8) | 45 (10) | 38 (14) | 34 (17) | 26 (29) | 1.3× | 1.3× | 2.8× | 3.5× |
| Current flat | boss light (42) | 35 (12) | 29 (16) | 22 (24) | 18 (32) | 10 (75) | 1.4× | 1.5× | 4.7× | 6.3× |
| Current flat | boss heavy (84) | 77 (5) | 71 (7) | 64 (8) | 60 (10) | 52 (14) | 1.2× | 1.2× | 2.2× | 2.7× |
| Percent | mob light avg (33) | 29 (14) | 26 (18) | 24 (22) | 23 (25) | 20 (38) | 1.2× | 1.2× | 2.1× | 2.6× |
| Percent | mob heavy max (58) | 51 (8) | 46 (10) | 42 (12) | 40 (14) | 36 (21) | 1.2× | 1.2× | 2.1× | 2.6× |
| Percent | boss light (42) | 37 (11) | 34 (14) | 30 (17) | 29 (20) | 26 (29) | 1.2× | 1.3× | 2.1× | 2.6× |
| Percent | boss heavy (84) | 74 (6) | 67 (7) | 61 (8) | 57 (10) | 52 (14) | 1.2× | 1.2× | 2.1× | 2.6× |
| Hybrid | mob light avg (33) | 27 (15) | 23 (20) | 19 (27) | 17 (34) | 12 (62) | 1.3× | 1.3× | 3.1× | 4.1× |
| Hybrid | mob heavy max (58) | 49 (8) | 43 (11) | 37 (14) | 34 (17) | 28 (27) | 1.3× | 1.3× | 2.5× | 3.2× |
| Hybrid | boss light (42) | 35 (12) | 30 (16) | 25 (21) | 23 (25) | 18 (42) | 1.3× | 1.3× | 2.7× | 3.5× |
| Hybrid | boss heavy (84) | 72 (6) | 64 (7) | 56 (9) | 51 (11) | 44 (17) | 1.3× | 1.3× | 2.3× | 3.0× |
| By attack type | mob light avg (33) | 27 (15) | 23 (20) | 19 (27) | 17 (34) | 12 (62) | 1.3× | 1.3× | 3.1× | 4.1× |
| By attack type | mob heavy max (58) | 54 (8) | 52 (9) | 49 (11) | 47 (12) | 44 (17) | 1.2× | 1.2× | 1.9× | 2.2× |
| By attack type | boss light (42) | 35 (12) | 30 (16) | 25 (21) | 23 (25) | 18 (42) | 1.3× | 1.3× | 2.7× | 3.5× |
| By attack type | boss heavy (84) | 79 (5) | 75 (6) | 70 (7) | 68 (8) | 64 (12) | 1.2× | 1.2× | 1.9× | 2.2× |

**Mid-late (Lv31: Big Sak, sak_tower)**: hero level 31, enemy level 33, K = 66. Profiles (HP / DEF): A 510/10, B 590/15, B5 671/22, B10 750/28, D 890/38

| Model | Attack (raw) | A dmg (hits) | B dmg (hits) | B5 dmg (hits) | B10 dmg (hits) | D dmg (hits) | B÷A | B5÷B | D÷B | D÷A |
|---|---|---|---|---|---|---|---|---|---|---|
| Current flat | mob light avg (22) | 12 (42) | 7 (84) | 1 (671) | 1 (750) | 1 (890) | 2.0× | 8.0× | 10.6× | 20.9× |
| Current flat | mob heavy max (73) | 63 (8) | 58 (10) | 51 (13) | 45 (17) | 35 (25) | 1.3× | 1.3× | 2.5× | 3.1× |
| Current flat | boss light (39) | 29 (18) | 24 (25) | 17 (39) | 11 (68) | 1 (890) | 1.4× | 1.6× | 36.2× | 50.6× |
| Current flat | boss heavy (100) | 90 (6) | 85 (7) | 78 (9) | 72 (10) | 62 (14) | 1.2× | 1.2× | 2.1× | 2.5× |
| Percent | mob light avg (22) | 19 (27) | 18 (33) | 16 (42) | 15 (50) | 14 (64) | 1.2× | 1.3× | 1.9× | 2.4× |
| Percent | mob heavy max (73) | 63 (8) | 59 (10) | 55 (12) | 51 (15) | 46 (19) | 1.2× | 1.2× | 1.9× | 2.4× |
| Percent | boss light (39) | 34 (15) | 32 (18) | 29 (23) | 27 (28) | 25 (36) | 1.2× | 1.3× | 1.9× | 2.4× |
| Percent | boss heavy (100) | 87 (6) | 81 (7) | 75 (9) | 70 (11) | 63 (14) | 1.2× | 1.2× | 1.9× | 2.4× |
| Hybrid | mob light avg (22) | 17 (30) | 14 (42) | 11 (61) | 8 (94) | 4 (222) | 1.4× | 1.4× | 5.3× | 7.4× |
| Hybrid | mob heavy max (73) | 61 (8) | 56 (11) | 49 (14) | 44 (17) | 37 (24) | 1.3× | 1.3× | 2.3× | 2.9× |
| Hybrid | boss light (39) | 31 (16) | 28 (21) | 24 (28) | 20 (38) | 15 (59) | 1.3× | 1.3× | 2.8× | 3.6× |
| Hybrid | boss heavy (100) | 84 (6) | 78 (8) | 70 (10) | 63 (12) | 54 (16) | 1.2× | 1.3× | 2.2× | 2.7× |
| By attack type | mob light avg (22) | 17 (30) | 14 (42) | 11 (61) | 8 (94) | 4 (222) | 1.4× | 1.4× | 5.3× | 7.4× |
| By attack type | mob heavy max (73) | 68 (8) | 66 (9) | 63 (11) | 60 (12) | 57 (16) | 1.2× | 1.2× | 1.7× | 2.1× |
| By attack type | boss light (39) | 31 (16) | 28 (21) | 24 (28) | 20 (38) | 15 (59) | 1.3× | 1.3× | 2.8× | 3.6× |
| By attack type | boss heavy (100) | 93 (5) | 90 (7) | 86 (8) | 82 (9) | 78 (11) | 1.2× | 1.2× | 1.7× | 2.1× |

**Late (Lv48: Director Wiroj, core_chamber)**: hero level 48, enemy level 50, K = 100. Profiles (HP / DEF): A 720/15, B 900/23, B5 1051/34, B10 1200/44, D 1390/66

| Model | Attack (raw) | A dmg (hits) | B dmg (hits) | B5 dmg (hits) | B10 dmg (hits) | D dmg (hits) | B÷A | B5÷B | D÷B | D÷A |
|---|---|---|---|---|---|---|---|---|---|---|
| Current flat | mob light avg (53) | 38 (19) | 30 (30) | 19 (55) | 9 (133) | 1 (1390) | 1.6× | 1.8× | 46.3× | 73.4× |
| Current flat | mob heavy max (163) | 148 (5) | 140 (6) | 129 (8) | 119 (10) | 97 (14) | 1.3× | 1.3× | 2.2× | 2.9× |
| Current flat | boss light (59) | 44 (16) | 36 (25) | 25 (42) | 15 (80) | 1 (1390) | 1.5× | 1.7× | 55.6× | 84.9× |
| Current flat | boss heavy (128) | 113 (6) | 105 (9) | 94 (11) | 84 (14) | 62 (22) | 1.3× | 1.3× | 2.6× | 3.5× |
| Percent | mob light avg (53) | 46 (16) | 43 (21) | 40 (26) | 37 (32) | 32 (43) | 1.3× | 1.3× | 2.1× | 2.8× |
| Percent | mob heavy max (163) | 142 (5) | 133 (7) | 122 (9) | 113 (11) | 98 (14) | 1.3× | 1.3× | 2.1× | 2.8× |
| Percent | boss light (59) | 51 (14) | 48 (19) | 44 (24) | 41 (29) | 36 (39) | 1.3× | 1.3× | 2.1× | 2.7× |
| Percent | boss heavy (128) | 111 (6) | 104 (9) | 96 (11) | 89 (13) | 77 (18) | 1.3× | 1.3× | 2.1× | 2.8× |
| Hybrid | mob light avg (53) | 42 (17) | 37 (24) | 31 (34) | 26 (46) | 15 (93) | 1.4× | 1.4× | 3.8× | 5.4× |
| Hybrid | mob heavy max (163) | 138 (5) | 127 (7) | 113 (9) | 102 (12) | 82 (17) | 1.4× | 1.3× | 2.4× | 3.2× |
| Hybrid | boss light (59) | 48 (15) | 42 (21) | 36 (29) | 30 (40) | 19 (73) | 1.4× | 1.4× | 3.4× | 4.9× |
| Hybrid | boss heavy (128) | 108 (7) | 98 (9) | 87 (12) | 78 (15) | 61 (23) | 1.4× | 1.3× | 2.5× | 3.4× |
| By attack type | mob light avg (53) | 42 (17) | 37 (24) | 31 (34) | 26 (46) | 15 (93) | 1.4× | 1.4× | 3.8× | 5.4× |
| By attack type | mob heavy max (163) | 152 (5) | 146 (6) | 139 (8) | 134 (9) | 123 (11) | 1.3× | 1.2× | 1.8× | 2.4× |
| By attack type | boss light (59) | 48 (15) | 42 (21) | 36 (29) | 30 (40) | 19 (73) | 1.4× | 1.4× | 3.4× | 4.9× |
| By attack type | boss heavy (128) | 119 (6) | 115 (8) | 109 (10) | 105 (11) | 96 (14) | 1.3× | 1.2× | 1.9× | 2.4× |

**World boss (Lv48 hero: Iron Colossus Lv52)**: hero level 48, enemy level 52, K = 104. Profiles (HP / DEF): A 720/15, B 900/23, B5 1051/34, B10 1200/44, D 1390/66

| Model | Attack (raw) | A dmg (hits) | B dmg (hits) | B5 dmg (hits) | B10 dmg (hits) | D dmg (hits) | B÷A | B5÷B | D÷B | D÷A |
|---|---|---|---|---|---|---|---|---|---|---|
| Current flat | boss light (84) | 69 (10) | 61 (15) | 50 (21) | 40 (30) | 18 (77) | 1.4× | 1.4× | 5.2× | 7.4× |
| Current flat | boss heavy (168) | 153 (5) | 145 (6) | 134 (8) | 124 (10) | 102 (14) | 1.3× | 1.3× | 2.2× | 2.9× |
| Percent | boss light (84) | 73 (10) | 69 (13) | 63 (17) | 59 (20) | 51 (27) | 1.3× | 1.3× | 2.1× | 2.8× |
| Percent | boss heavy (168) | 147 (5) | 138 (7) | 127 (8) | 118 (10) | 103 (13) | 1.3× | 1.3× | 2.1× | 2.8× |
| Hybrid | boss light (84) | 70 (10) | 63 (14) | 55 (19) | 48 (25) | 35 (40) | 1.4× | 1.3× | 2.8× | 3.9× |
| Hybrid | boss heavy (168) | 143 (5) | 132 (7) | 118 (9) | 107 (11) | 86 (16) | 1.4× | 1.3× | 2.4× | 3.2× |
| By attack type | boss light (84) | 70 (10) | 63 (14) | 55 (19) | 48 (25) | 35 (40) | 1.4× | 1.3× | 2.8× | 3.9× |
| By attack type | boss heavy (168) | 157 (5) | 151 (6) | 144 (7) | 139 (9) | 128 (11) | 1.3× | 1.2× | 1.8× | 2.4× |

**The tuned model against the current one:**

| Stage | Attack | Model | A dmg (hits) | B dmg (hits) | B5 dmg (hits) | B10 dmg (hits) | D dmg (hits) | B÷A | B5÷B | B10÷B | D÷B |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Lv5 Foreman | mob light (7) | current | 3 (62) | 1 (230) | 1 (260) | 1 (290) | 1 (272) | 3.7× | 1.1× | 1.3× | 1.2× |
| Lv5 Foreman | mob light (7) | hybrid-T | 6 (31) | 5 (46) | 5 (52) | 5 (58) | 4 (68) | 1.5× | 1.1× | 1.3× | 1.5× |
| Lv5 Foreman | boss light (15) | current | 11 (17) | 9 (26) | 6 (43) | 5 (58) | 3 (91) | 1.5× | 1.7× | 2.3× | 3.5× |
| Lv5 Foreman | boss light (15) | hybrid-T | 13 (14) | 12 (19) | 11 (24) | 11 (26) | 10 (27) | 1.3× | 1.2× | 1.4× | 1.4× |
| Lv5 Foreman | boss heavy (38) | current | 34 (5) | 32 (7) | 29 (9) | 28 (10) | 26 (10) | 1.3× | 1.2× | 1.4× | 1.5× |
| Lv5 Foreman | boss heavy (38) | hybrid-T | 36 (5) | 35 (7) | 34 (8) | 34 (9) | 33 (8) | 1.3× | 1.2× | 1.3× | 1.3× |
| Lv10 Baron | mob light (13) | current | 9 (26) | 6 (46) | 3 (103) | 1 (338) | 1 (432) | 1.8× | 2.2× | 7.3× | 9.3× |
| Lv10 Baron | mob light (13) | hybrid-T | 12 (20) | 11 (25) | 10 (31) | 9 (38) | 8 (54) | 1.3× | 1.2× | 1.5× | 2.1× |
| Lv10 Baron | boss light (32) | current | 28 (8) | 25 (11) | 22 (14) | 20 (17) | 16 (27) | 1.3× | 1.3× | 1.5× | 2.4× |
| Lv10 Baron | boss light (32) | hybrid-T | 29 (8) | 28 (10) | 26 (12) | 25 (14) | 23 (19) | 1.2× | 1.2× | 1.4× | 1.9× |
| Lv10 Baron | boss heavy (63) | current | 59 (4) | 56 (5) | 53 (6) | 51 (7) | 47 (9) | 1.3× | 1.2× | 1.3× | 1.8× |
| Lv10 Baron | boss heavy (63) | hybrid-T | 61 (4) | 59 (5) | 58 (5) | 57 (6) | 55 (8) | 1.2× | 1.1× | 1.3× | 1.7× |
| Lv24 K-7 | mob light (33) | current | 26 (16) | 20 (23) | 13 (40) | 9 (63) | 1 (750) | 1.5× | 1.7× | 2.7× | 32.3× |
| Lv24 K-7 | mob light (33) | hybrid-T | 30 (14) | 27 (17) | 25 (21) | 23 (25) | 21 (36) | 1.2× | 1.2× | 1.4× | 2.1× |
| Lv24 K-7 | boss light (42) | current | 35 (12) | 29 (16) | 22 (24) | 18 (32) | 10 (75) | 1.4× | 1.5× | 2.0× | 4.7× |
| Lv24 K-7 | boss light (42) | hybrid-T | 38 (11) | 35 (13) | 32 (16) | 30 (19) | 27 (28) | 1.2× | 1.2× | 1.4× | 2.1× |
| Lv24 K-7 | boss heavy (84) | current | 77 (5) | 71 (7) | 64 (8) | 60 (10) | 52 (14) | 1.2× | 1.2× | 1.5× | 2.2× |
| Lv24 K-7 | boss heavy (84) | hybrid-T | 81 (5) | 78 (6) | 75 (7) | 73 (8) | 70 (11) | 1.2× | 1.2× | 1.3× | 1.8× |
| Lv31 Big Sak | mob light (22) | current | 12 (42) | 7 (84) | 1 (671) | 1 (750) | 1 (890) | 2.0× | 8.0× | 8.9× | 10.6× |
| Lv31 Big Sak | mob light (22) | hybrid-T | 19 (27) | 18 (33) | 16 (42) | 14 (54) | 12 (74) | 1.2× | 1.3× | 1.6× | 2.3× |
| Lv31 Big Sak | boss light (39) | current | 29 (18) | 24 (25) | 17 (39) | 11 (68) | 1 (890) | 1.4× | 1.6× | 2.8× | 36.2× |
| Lv31 Big Sak | boss light (39) | hybrid-T | 34 (15) | 32 (18) | 30 (22) | 27 (28) | 24 (37) | 1.2× | 1.2× | 1.5× | 2.0× |
| Lv31 Big Sak | boss heavy (100) | current | 90 (6) | 85 (7) | 78 (9) | 72 (10) | 62 (14) | 1.2× | 1.2× | 1.5× | 2.1× |
| Lv31 Big Sak | boss heavy (100) | hybrid-T | 95 (5) | 93 (6) | 90 (7) | 87 (9) | 83 (11) | 1.2× | 1.2× | 1.4× | 1.7× |
| Lv48 Director | mob light (53) | current | 38 (19) | 30 (30) | 19 (55) | 9 (133) | 1 (1390) | 1.6× | 1.8× | 4.4× | 46.3× |
| Lv48 Director | mob light (53) | hybrid-T | 46 (16) | 43 (21) | 39 (27) | 35 (34) | 29 (48) | 1.3× | 1.3× | 1.6× | 2.3× |
| Lv48 Director | boss light (59) | current | 44 (16) | 36 (25) | 25 (42) | 15 (80) | 1 (1390) | 1.5× | 1.7× | 3.2× | 55.6× |
| Lv48 Director | boss light (59) | hybrid-T | 51 (14) | 48 (19) | 43 (24) | 40 (30) | 33 (42) | 1.3× | 1.3× | 1.6× | 2.2× |
| Lv48 Director | boss heavy (128) | current | 113 (6) | 105 (9) | 94 (11) | 84 (14) | 62 (22) | 1.3× | 1.3× | 1.7× | 2.6× |
| Lv48 Director | boss heavy (128) | hybrid-T | 121 (6) | 118 (8) | 113 (9) | 109 (11) | 102 (14) | 1.3× | 1.2× | 1.4× | 1.8× |
| Lv48 vs Colossus | boss light (84) | current | 69 (10) | 61 (15) | 50 (21) | 40 (30) | 18 (77) | 1.4× | 1.4× | 2.0× | 5.2× |
| Lv48 vs Colossus | boss light (84) | hybrid-T | 74 (10) | 69 (13) | 64 (16) | 59 (20) | 50 (28) | 1.3× | 1.3× | 1.6× | 2.1× |
| Lv48 vs Colossus | boss heavy (168) | current | 153 (5) | 145 (6) | 134 (8) | 124 (10) | 102 (14) | 1.3× | 1.3× | 1.6× | 2.2× |
| Lv48 vs Colossus | boss heavy (168) | hybrid-T | 159 (5) | 155 (6) | 149 (7) | 144 (8) | 135 (10) | 1.3× | 1.2× | 1.4× | 1.8× |

### V1.3 Measured fights under each model

[MEASURED; 2 fights per cell, Oren and Mika; KO, fight time, damage taken per second while fighting, time to die without healing]

**Stage bosses, no food (KO, fight time, damage in per second, TTD)**

| Area | Profile | current | percent | hybrid | by type | hybrid-T |
|---|---|---|---|---|---|---|
| canal_works | A | 2/2, 29s, 12.4/s, TTD 12s | 2/2, 31s, 11.0/s, TTD 14s | 1/2, 38s, 9.0/s, TTD 17s | 2/2, 32s, 10.8/s, TTD 14s | 2/2, 29s, 12.8/s, TTD 12s |
| canal_works | B | 2/2, 29s, 13.5/s, TTD 13s | 2/2, 33s, 11.5/s, TTD 16s | 1/2, 38s, 9.7/s, TTD 19s | 2/2, 32s, 12.2/s, TTD 15s | 2/2, 29s, 13.9/s, TTD 13s |
| canal_works | B5 | 2/2, 31s, 14.0/s, TTD 15s | 1/2, 37s, 11.1/s, TTD 19s | 1/2, 37s, 10.5/s, TTD 20s | 1/2, 36s, 10.1/s, TTD 21s | 2/2, 28s, 15.6/s, TTD 13s |
| canal_works | C | 2/2, 31s, 14.0/s, TTD 15s | 1/2, 37s, 11.1/s, TTD 19s | 1/2, 37s, 10.5/s, TTD 20s | 1/2, 36s, 10.1/s, TTD 21s | 2/2, 28s, 15.6/s, TTD 13s |
| canal_works | D | 0/2, 38s, 6.7/s, TTD 34s | 0/2, 43s, 5.8/s, TTD 39s | 0/2, 39s, 4.8/s, TTD 48s | 0/2, 36s, 4.7/s, TTD 48s | 0/2, 36s, 8.6/s, TTD 26s |
| factory_drains | A | 2/2, 38s, 17.4/s, TTD 23s | 2/2, 37s, 18.4/s, TTD 22s | 2/2, 40s, 16.1/s, TTD 25s | 2/2, 37s, 17.9/s, TTD 22s | 2/2, 37s, 17.7/s, TTD 23s |
| factory_drains | B | 1/2, 52s, 12.8/s, TTD 35s | 1/2, 50s, 13.1/s, TTD 34s | 1/2, 54s, 12.6/s, TTD 36s | 1/2, 50s, 13.5/s, TTD 33s | 1/2, 48s, 14.7/s, TTD 31s |
| factory_drains | B5 | 0/2, 48s, 9.2/s, TTD 55s | 0/2, 52s, 11.5/s, TTD 44s | 1/2, 46s, 13.4/s, TTD 38s | 0/2, 47s, 10.3/s, TTD 49s | 0/2, 46s, 11.6/s, TTD 43s |
| factory_drains | C | 0/2, 49s, 5.5/s, TTD 102s | 0/2, 50s, 7.6/s, TTD 74s | 0/2, 50s, 6.4/s, TTD 88s | 0/2, 49s, 6.4/s, TTD 88s | 0/2, 47s, 11.1/s, TTD 51s |
| factory_drains | D | 0/2, 49s, 5.2/s, TTD 140s | 0/2, 50s, 9.8/s, TTD 75s | 0/2, 50s, 7.3/s, TTD 101s | 0/2, 49s, 7.6/s, TTD 97s | 0/2, 46s, 8.0/s, TTD 92s |
| core_chamber | A | 2/2, 75s, 12.3/s, TTD 57s | 1/2, 66s, 14.0/s, TTD 50s | 2/2, 66s, 14.3/s, TTD 49s | 2/2, 68s, 13.6/s, TTD 52s | 2/2, 73s, 12.7/s, TTD 56s |
| core_chamber | B | 0/2, 61s, 10.9/s, TTD 81s | 0/2, 59s, 11.1/s, TTD 80s | 0/2, 63s, 6.9/s, TTD 129s | 1/2, 68s, 10.1/s, TTD 87s | 2/2, 64s, 17.4/s, TTD 51s |
| core_chamber | B5 | 0/2, 58s, 9.9/s, TTD 105s | 0/2, 60s, 15.6/s, TTD 67s | 0/2, 62s, 14.6/s, TTD 71s | 0/2, 57s, 13.4/s, TTD 78s | 0/2, 56s, 12.6/s, TTD 82s |
| core_chamber | C | 0/2, 48s, 4.7/s, TTD 227s | 0/2, 49s, 10.4/s, TTD 101s | 0/2, 50s, 7.9/s, TTD 135s | 0/2, 47s, 5.4/s, TTD 195s | 0/2, 47s, 6.4/s, TTD 165s |
| core_chamber | D | 0/2, 42s, 5.1/s, TTD 269s | 0/2, 40s, 9.8/s, TTD 141s | 0/2, 38s, 5.2/s, TTD 263s | 0/2, 43s, 9.0/s, TTD 152s | 0/2, 42s, 8.8/s, TTD 156s |

**Stage bosses, 10 foods carried**

| Area | Profile | current | percent | hybrid | by type | hybrid-T |
|---|---|---|---|---|---|---|
| canal_works | A | 0/2, 42s, 9.5/s, TTD 17s | 0/2, 45s, 8.9/s, TTD 18s | 0/2, 46s, 8.0/s, TTD 20s | 0/2, 42s, 8.9/s, TTD 18s | 0/2, 39s, 10.3/s, TTD 16s |
| canal_works | B | 0/2, 42s, 10.5/s, TTD 18s | 0/2, 41s, 8.9/s, TTD 21s | 0/2, 43s, 8.3/s, TTD 23s | 0/2, 44s, 8.2/s, TTD 23s | 0/2, 43s, 10.8/s, TTD 18s |
| canal_works | B5 | 0/2, 37s, 9.5/s, TTD 22s | 0/2, 42s, 7.9/s, TTD 27s | 0/2, 45s, 7.0/s, TTD 31s | 0/2, 42s, 7.1/s, TTD 30s | 0/2, 38s, 10.0/s, TTD 21s |
| canal_works | C | 0/2, 37s, 9.5/s, TTD 22s | 0/2, 42s, 7.9/s, TTD 27s | 0/2, 45s, 7.0/s, TTD 31s | 0/2, 42s, 7.1/s, TTD 30s | 0/2, 38s, 10.0/s, TTD 21s |
| canal_works | D | 0/2, 37s, 6.1/s, TTD 37s | 0/2, 36s, 5.7/s, TTD 40s | 0/2, 38s, 4.7/s, TTD 48s | 0/2, 36s, 4.4/s, TTD 52s | 0/2, 35s, 8.0/s, TTD 28s |
| factory_drains | A | 0/2, 79s, 15.8/s, TTD 25s | 0/2, 79s, 16.8/s, TTD 24s | 0/2, 75s, 15.2/s, TTD 26s | 0/2, 80s, 16.4/s, TTD 24s | 0/2, 74s, 15.9/s, TTD 25s |
| factory_drains | B | 0/2, 67s, 11.8/s, TTD 38s | 0/2, 68s, 13.7/s, TTD 33s | 0/2, 69s, 11.6/s, TTD 39s | 0/2, 64s, 12.6/s, TTD 36s | 0/2, 61s, 13.9/s, TTD 32s |
| factory_drains | B5 | 0/2, 48s, 9.2/s, TTD 55s | 0/2, 52s, 11.5/s, TTD 44s | 0/2, 56s, 11.4/s, TTD 44s | 0/2, 47s, 10.3/s, TTD 49s | 0/2, 46s, 11.6/s, TTD 43s |
| factory_drains | C | 0/2, 49s, 5.5/s, TTD 102s | 0/2, 50s, 7.6/s, TTD 74s | 0/2, 50s, 6.4/s, TTD 88s | 0/2, 49s, 6.4/s, TTD 88s | 0/2, 44s, 11.0/s, TTD 51s |
| factory_drains | D | 0/2, 49s, 5.2/s, TTD 140s | 0/2, 50s, 10.1/s, TTD 73s | 0/2, 50s, 7.3/s, TTD 101s | 0/2, 49s, 7.6/s, TTD 97s | 0/2, 46s, 8.0/s, TTD 92s |
| core_chamber | A | 0/2, 83s, 21.9/s, TTD 32s | 0/2, 69s, 13.9/s, TTD 51s | 0/2, 74s, 18.1/s, TTD 39s | 0/2, 68s, 13.9/s, TTD 51s | 0/2, 67s, 13.5/s, TTD 52s |
| core_chamber | B | 0/2, 59s, 8.9/s, TTD 99s | 0/2, 57s, 12.4/s, TTD 72s | 0/2, 63s, 7.0/s, TTD 127s | 0/2, 65s, 11.0/s, TTD 81s | 0/2, 62s, 16.7/s, TTD 53s |
| core_chamber | B5 | 0/2, 57s, 10.1/s, TTD 103s | 0/2, 58s, 13.1/s, TTD 79s | 0/2, 61s, 13.1/s, TTD 79s | 0/2, 54s, 13.8/s, TTD 75s | 0/2, 50s, 13.5/s, TTD 77s |
| core_chamber | C | 0/2, 48s, 4.7/s, TTD 227s | 0/2, 51s, 10.4/s, TTD 102s | 0/2, 50s, 7.9/s, TTD 135s | 0/2, 47s, 5.4/s, TTD 195s | 0/2, 47s, 6.4/s, TTD 165s |
| core_chamber | D | 0/2, 42s, 5.1/s, TTD 269s | 0/2, 40s, 9.8/s, TTD 141s | 0/2, 38s, 5.2/s, TTD 263s | 0/2, 43s, 9.0/s, TTD 152s | 0/2, 42s, 8.8/s, TTD 156s |

**Streets, 10 foods carried**

| Area | Profile | current | percent | hybrid | by type | hybrid-T |
|---|---|---|---|---|---|---|
| rusted_corner | A | 0/2, 68s, 0.4/s, TTD 381s | 0/2, 68s, 0.5/s, TTD 314s | 0/2, 68s, 0.6/s, TTD 271s | 0/2, 68s, 0.5/s, TTD 314s | 0/2, 67s, 0.6/s, TTD 271s |
| rusted_corner | B | 0/2, 69s, 0.3/s, TTD 641s | 0/2, 69s, 0.5/s, TTD 387s | 0/2, 70s, 0.7/s, TTD 306s | 0/2, 69s, 0.5/s, TTD 410s | 0/2, 69s, 0.6/s, TTD 325s |
| rusted_corner | B5 | 0/2, 64s, 0.1/s, TTD 1679s | 0/2, 64s, 0.3/s, TTD 691s | 0/2, 64s, 0.2/s, TTD 979s | 0/2, 64s, 0.3/s, TTD 671s | 0/2, 63s, 0.5/s, TTD 511s |
| rusted_corner | C | 0/2, 64s, 0.1/s, TTD 1679s | 0/2, 64s, 0.3/s, TTD 691s | 0/2, 64s, 0.2/s, TTD 979s | 0/2, 64s, 0.3/s, TTD 671s | 0/2, 63s, 0.5/s, TTD 511s |
| rusted_corner | D | 0/2, 56s, 0.1/s, TTD 2082s | 0/2, 57s, 0.2/s, TTD 1090s | 0/2, 57s, 0.1/s, TTD 1762s | 0/2, 57s, 0.2/s, TTD 954s | 0/2, 56s, 0.3/s, TTD 881s |
| waste_pools | A | 0/2, 141s, 3.8/s, TTD 102s | 0/2, 136s, 4.7/s, TTD 84s | 0/2, 139s, 5.2/s, TTD 74s | 0/2, 139s, 4.7/s, TTD 83s | 0/2, 128s, 6.4/s, TTD 61s |
| waste_pools | B | 0/2, 116s, 2.6/s, TTD 172s | 0/2, 111s, 2.5/s, TTD 180s | 0/2, 112s, 1.6/s, TTD 267s | 0/2, 115s, 2.0/s, TTD 223s | 0/2, 107s, 2.3/s, TTD 192s |
| waste_pools | B5 | 0/2, 99s, 0.8/s, TTD 587s | 0/2, 100s, 2.6/s, TTD 190s | 0/2, 106s, 1.7/s, TTD 292s | 0/2, 102s, 2.6/s, TTD 192s | 0/2, 95s, 1.3/s, TTD 382s |
| waste_pools | C | 0/2, 104s, 1.8/s, TTD 312s | 0/2, 103s, 1.4/s, TTD 384s | 0/2, 105s, 1.9/s, TTD 287s | 0/2, 108s, 3.0/s, TTD 187s | 0/2, 106s, 3.0/s, TTD 181s |
| waste_pools | D | 0/2, 89s, 0.2/s, TTD 3295s | 0/2, 92s, 0.8/s, TTD 942s | 0/2, 98s, 0.7/s, TTD 1082s | 0/2, 92s, 1.4/s, TTD 507s | 0/2, 84s, 1.5/s, TTD 487s |
| reactor_walkway | A | 0/2, 128s, 16.4/s, TTD 42s | 0/2, 121s, 16.9/s, TTD 41s | 0/2, 120s, 14.0/s, TTD 50s | 0/2, 119s, 16.1/s, TTD 43s | 0/2, 124s, 15.8/s, TTD 44s |
| reactor_walkway | B | 0/2, 102s, 14.7/s, TTD 54s | 0/2, 108s, 13.4/s, TTD 59s | 0/2, 102s, 9.3/s, TTD 85s | 0/2, 121s, 18.8/s, TTD 42s | 0/2, 93s, 12.1/s, TTD 65s |
| reactor_walkway | B5 | 0/2, 85s, 8.3/s, TTD 108s | 0/2, 80s, 9.8/s, TTD 92s | 0/2, 84s, 10.1/s, TTD 89s | 0/2, 84s, 14.3/s, TTD 63s | 0/2, 82s, 7.1/s, TTD 127s |
| reactor_walkway | C | 0/2, 79s, 7.8/s, TTD 124s | 0/2, 77s, 11.5/s, TTD 84s | 0/2, 78s, 7.3/s, TTD 133s | 0/2, 80s, 11.9/s, TTD 81s | 0/2, 75s, 11.8/s, TTD 82s |
| reactor_walkway | D | 0/2, 66s, 6.5/s, TTD 183s | 0/2, 63s, 10.3/s, TTD 115s | 0/2, 65s, 8.1/s, TTD 146s | 0/2, 65s, 6.8/s, TTD 175s | 0/2, 66s, 7.0/s, TTD 171s |

### V1.4 Is the difference desirable at each stage?

[PROPOSED targets, judged against V1.2–V1.3]

The ratios below are hits to die relative to profile B. "D÷B" means D survives that many times as many hits as B.

| Stage | What should be true | Current | Percent | Hybrid / by type (K = 2L) | Hybrid-T |
|---|---|---|---|---|---|
| **Early (ch 1)** | Gear helps, but is never needed to learn. D÷B ≤ 1.5× and B÷A ≤ 1.5× on every hit | ✗: 1.2× to 9.3×; small hits deal 1 | ≈: 1.5–2.0× | ✗: B5 immune to small hits (260 hits) | ✓ at level 5: 1.3–1.5×. ≈ at level 10: 1.7–2.1×, where D already wears epic +10. B÷A 1.2–1.5× |
| **Mid (ch 2–3)** | Gear clearly helps against attrition. D÷B 1.5–2.2× on ordinary hits, ≤ 1.8× on heavies | ✗: 4.7× to 36× on light hits | ≈: 1.9–2.1× flat everywhere | ≈: 2.2–5.3× | ✓: 2.0–2.3× (light), 1.7–1.8× (heavy) |
| **Late (ch 4–6)** | Ordinary gear is not comfortable. D÷B 2–2.5× on ordinary hits, ≤ 2× on heavies; +5 worth about 1.25× | ✗: 36× to 56×; D immune to light hits | ≈: 1.9–2.1×, no stage growth | ≈: 3.4–3.8× light, 1.9× heavy | ✓: 2.2–2.3× light, 1.7–1.8× heavy, B5÷B 1.2–1.3× |
| **World boss** | Gear is a clear advantage, skill still needed | D÷B 5.2× (light) | 2.1× | 2.8× | 2.1× light, 1.8× heavy |

**Measured consequences** (V1.3):
- With food, every profile wins every sampled boss under every model. **No defense formula alone stops food from carrying profile A.** The formula's job is to remove immunity and to make defense count at every stage.
- Without food, hybrid-T at the Director: B goes down 2/2 (time to die 51 s against a 64 s fight), B5 survives (82 s), D's 269 s falls to 156 s. That is "late game asks for +5 or boss pieces", without +10.
- Profile A barely changes under any model: 12–57 s to die without food. A loses through low HP and slow kills. The A–B gap must come from gear HP and power (§V2), not from defense.

**Choice:** hybrid-T. Not chosen for its ratio range: chosen because the separation grows gently by stage, nobody becomes immune, and heavy attacks stay a skill check.

## V2. Equipment progression validation

### V2.1 Profile stats at each level

[MEASURED, `PlayerProfile.stats`, Oren]

| Level | Profile | HP | Power | DEF | Crit | Attack speed | Gear score |
|---|---|---|---|---|---|---|---|
| 5 | A | 185 | 1.35 | 4 | 0.050 | 1.03 | 37 |
| 5 | B | 230 | 1.35 | 6 | 0.050 | 1.03 | 68 |
| 5 | B5 | 260 | 1.43 | 9 | 0.050 | 1.04 | 107 |
| 5 | B10 | 290 | 1.50 | 10 | 0.050 | 1.06 | 137 |
| 5 | C | 274 | 1.69 | 9 | 0.050 | 1.04 | 141 |
| 5 | D | 272 | 1.96 | 12 | 0.150 | 1.00 | 203 |
| 10 | A | 235 | 1.60 | 4 | 0.050 | 1.03 | 37 |
| 10 | B | 279 | 1.73 | 7 | 0.090 | 1.11 | 111 |
| 10 | B5 | 310 | 1.87 | 10 | 0.110 | 1.17 | 170 |
| 10 | B10 | 338 | 2.01 | 12 | 0.130 | 1.22 | 222 |
| 10 | C | 334 | 2.10 | 10 | 0.155 | 1.17 | 213 |
| 10 | D | 432 | 2.45 | 16 | 0.270 | 1.22 | 361 |
| 16 | A | 317 | 1.98 | 5 | 0.090 | 1.03 | 69 |
| 16 | B | 376 | 2.30 | 9 | 0.100 | 1.10 | 170 |
| 16 | B5 | 425 | 2.58 | 14 | 0.125 | 1.15 | 263 |
| 16 | B10 | 472 | 2.85 | 16 | 0.150 | 1.20 | 340 |
| 16 | C | 463 | 2.84 | 14 | 0.170 | 1.15 | 318 |
| 16 | D | 580 | 3.21 | 20 | 0.250 | 1.20 | 476 |
| 24 | A | 415 | 2.54 | 7 | 0.100 | 1.03 | 106 |
| 24 | B | 465 | 2.93 | 13 | 0.170 | 1.11 | 237 |
| 24 | B5 | 518 | 3.32 | 20 | 0.230 | 1.17 | 363 |
| 24 | B10 | 570 | 3.71 | 24 | 0.290 | 1.22 | 474 |
| 24 | C | 578 | 3.68 | 22 | 0.260 | 1.27 | 461 |
| 24 | D | 750 | 4.25 | 32 | 0.410 | 1.26 | 686 |
| 31 | A | 510 | 3.06 | 10 | 0.120 | 1.03 | 154 |
| 31 | B | 590 | 3.54 | 15 | 0.260 | 1.06 | 316 |
| 31 | B5 | 671 | 4.06 | 22 | 0.365 | 1.09 | 477 |
| 31 | B10 | 750 | 4.58 | 28 | 0.470 | 1.12 | 632 |
| 31 | C | 723 | 4.44 | 24 | 0.470 | 1.09 | 572 |
| 31 | D | 890 | 5.56 | 38 | 0.500 | 1.18 | 951 |
| 39 | A | 615 | 3.60 | 12 | 0.130 | 1.03 | 193 |
| 39 | B | 685 | 4.16 | 20 | 0.280 | 1.08 | 378 |
| 39 | B5 | 773 | 4.79 | 30 | 0.395 | 1.12 | 573 |
| 39 | B10 | 860 | 5.42 | 38 | 0.500 | 1.16 | 757 |
| 39 | C | 840 | 5.39 | 35 | 0.485 | 1.30 | 736 |
| 39 | D | 950 | 6.72 | 44 | 0.500 | 1.30 | 1126 |
| 48 | A | 720 | 4.21 | 15 | 0.150 | 1.03 | 236 |
| 48 | B | 900 | 5.04 | 23 | 0.330 | 1.19 | 528 |
| 48 | B5 | 1051 | 5.88 | 34 | 0.470 | 1.29 | 794 |
| 48 | B10 | 1200 | 6.73 | 44 | 0.500 | 1.30 | 1055 |
| 48 | C | 1074 | 6.32 | 34 | 0.500 | 1.30 | 880 |
| 48 | D | 1390 | 7.77 | 66 | 0.500 | 1.30 | 1478 |

### V2.2 Where power comes from

[MEASURED]. Each row adds one source to the one above it; the best items are the highest-scoring item of any grade per slot.

| Level | Source | Adds power | Adds HP | Adds DEF | Running total (power / HP / DEF) |
|---|---|---|---|---|---|
| 10 | hero base (level 1, no gear) | +1.00 | +130 | +2 | 1.00/130/2 |
| 10 | + level | +0.45 | +90 | +0 | 1.45/220/2 |
| 10 | + base equipment (shop set +0) | +0.28 | +59 | +5 | 1.73/279/7 |
| 10 | + grade (best items, +0) | +0.22 | +47 | +2 | 1.95/326/9 |
| 10 | + enhancement +5 | +0.25 | +54 | +5 | 2.20/380/14 |
| 10 | + enhancement +10 | +0.25 | +52 | +2 | 2.45/432/16 |
| 24 | hero base (level 1, no gear) | +1.00 | +130 | +2 | 1.00/130/2 |
| 24 | + level | +1.15 | +230 | +0 | 2.15/360/2 |
| 24 | + base equipment (shop set +0) | +0.78 | +105 | +11 | 2.93/465/13 |
| 24 | + grade (best items, +0) | +0.27 | +90 | +4 | 3.20/555/17 |
| 24 | + enhancement +5 | +0.53 | +98 | +9 | 3.73/653/26 |
| 24 | + enhancement +10 | +0.52 | +97 | +6 | 4.25/750/32 |
| 48 | hero base (level 1, no gear) | +1.00 | +130 | +2 | 1.00/130/2 |
| 48 | + level | +2.35 | +470 | +0 | 3.35/600/2 |
| 48 | + base equipment (shop set +0) | +1.69 | +300 | +21 | 5.04/900/23 |
| 48 | + grade (best items, +0) | +0.52 | +95 | +11 | 5.56/995/34 |
| 48 | + enhancement +5 | +1.11 | +199 | +17 | 6.67/1194/51 |
| 48 | + enhancement +10 | +1.10 | +196 | +15 | 7.77/1390/66 |

**Shares of power at level 48** (D):

| Source | Power | Share |
|---|---|---|
| Hero base | 1.0 | 13% |
| Level | 2.35 | 30% |
| Base equipment (shop set) | 1.69 | 22% |
| Grade (shop → best items, both +0) | 0.52 | 7% |
| Enhancement | 2.21 | 28% |

HP and DEF shares are similar. DEF comes 48% from enhancement.

**Findings:**
- **Grade is the weakest lever: 7%.** The grade budget (`ItemRules.GRADES`: epic 1.35, legendary 1.6) is offset by boss items' lower levels than the shop's top pieces.
- **Level still supplies about a third of power.**
- **Enhancement is strong** (28%) but costs only coins and materials (no loss), so it is the main gear lever today.

### V2.3 Each slot

[MEASURED]

| Level | Slot | Item in profile B | Removing it (power / HP / DEF) | Best item +10 in it (power / HP / DEF) | Share of B gear score |
|---|---|---|---|---|---|
| 10 | head | iron_helm | +0.00/-13/-2 | +0.00/+37/+4 | 15% |
| 10 | body | riveted_jacket | +0.00/-21/+0 | +0.00/+59/+4 | 18% |
| 10 | hands | fingerless_gloves | +0.00/+0/+0 | +0.16/+0/+0 | 6% |
| 10 | weapon | brass_knuckles | -0.21/+0/+0 | +0.51/+32/+0 | 26% |
| 10 | feet | street_runners | +0.00/+0/-1 | +0.00/+0/+1 | 11% |
| 10 | charm | jade_charm | -0.05/-25/+0 | +0.05/+25/+0 | 24% |
| 24 | head | hazmat_hood | +0.00/-40/-3 | +0.00/+40/+3 | 15% |
| 24 | body | plant_vest | +0.00/-40/-3 | +0.00/+100/+9 | 19% |
| 24 | hands | insulated_gloves | -0.17/+0/-1 | +0.25/+0/+3 | 14% |
| 24 | weapon | shock_baton | -0.54/+0/+0 | +0.82/+0/+2 | 29% |
| 24 | feet | lab_boots | +0.00/+0/-2 | +0.00/+40/+2 | 12% |
| 24 | charm | jade_charm | -0.05/-25/+0 | +0.25/+105/+0 | 11% |
| 48 | head | core_guard_helm | +0.00/-75/-6 | +0.00/+155/+12 | 13% |
| 48 | body | reactor_plate | +0.00/-85/-7 | +0.00/+165/+19 | 17% |
| 48 | hands | insulated_gauntlets | -0.37/+0/-2 | +0.85/+0/+6 | 12% |
| 48 | weapon | alloy_knuckles | -1.06/+0/+0 | +1.64/+0/+0 | 24% |
| 48 | feet | walkway_boots | +0.00/+0/-4 | +0.00/+0/+6 | 10% |
| 48 | charm | heart_of_iron_city | -0.24/-140/+0 | +0.24/+170/+0 | 24% |

**Measured in fights:** profile B at Big Sak (level 31, no food), with one slot removed or one slot upgraded:

| Profile (Big Sak, level 31, no food, 4 fights) | KO | Fight s | Damage in /s | TTD s | Power | DEF |
|---|---|---|---|---|---|---|
| B | 1/4 | 53 | 12.2 | 47 | 3.59 | 14 |
| B-weapon | 4/4 | 44 | 19.2 | 30 | 2.91 | 14 |
| B-body | 3/4 | 43 | 16.6 | 31 | 3.59 | 9 |
| B-head | 3/4 | 40 | 18.8 | 28 | 3.59 | 10 |
| B-hands | 4/4 | 47 | 18.9 | 30 | 3.35 | 13 |
| B-feet | 3/4 | 42 | 21.9 | 26 | 3.59 | 12 |
| B-charm | 3/4 | 44 | 17.8 | 29 | 3.48 | 14 |
| B+weapon | 0/4 | 45 | 14.3 | 40 | 5.15 | 14 |
| B+body | 1/4 | 55 | 10.9 | 61 | 3.59 | 22 |
| B+head | 0/4 | 63 | 10.3 | 64 | 3.59 | 20 |
| B+hands | 1/4 | 49 | 15.5 | 37 | 3.78 | 17 |
| B+feet | 0/4 | 61 | 10.3 | 56 | 3.59 | 20 |
| B+charm | 1/4 | 55 | 14.0 | 50 | 3.86 | 14 |

**Findings** [MEASURED]:
- **Every slot matters in a boss fight.** Removing any one raises losses from 1/4 to 3–4/4 and damage taken by 36–80%.
- **Feet** add only 1–4 DEF but their **speed** changes the fight: without them, 21.9 damage/s against 12.2.
- **Hands** are small early: 6% of the gear score at level 10, only +0.16 power at +10.
- **The weapon** is the biggest single upgrade: best +10 gives 0/4 losses and kills 15% faster.
- **Body, head and feet upgrades** add 9–17 s of time to die each.

**Proposals** [PROPOSED]:
1. **Spread grades more.** Epic 1.35 → about 1.5, legendary 1.6 → about 1.85, so a boss piece beats the shop clearly at its level. `ItemRules` tolerance and validation stay; items are re-derived from the budget, not hand-edited.
2. **Shift power from level to gear:** `per_level.power` 0.05 → about 0.03, with gear budgets up to match.
3. **Give hands a little defense or HP** at low levels.
4. **Story targets use B5 or C as the intended profile, never D.** So +10 stays optional (Principle 4).

## V3. Boss burst validation

### V3.1 Timing facts

[VERIFIED, moves.json, enemies.json, CombatRules]

**Boss heavy attacks:**
- Wind-up (`startup`, the telegraph) 20–32 ticks (0.33–0.53 s).
- Active 5–20 ticks; recovery 30–50 ticks (0.5–0.83 s), the punish window.
- Every one knocks down (`knockdown`).

**Hazards:** warned 50–65 ticks ahead (0.83–1.08 s).

**Dodge:**
- 20 ticks, invulnerable on ticks 2–14 (12 ticks), travels about 70 px.
- Costs 20 energy; energy refills 0.25 a tick, so 5 dodges from full, then one per 1.33 s.

**After a knockdown:** 50 ticks down plus 36 ticks of grace, all invulnerable (1.43 s). Stun-lock protection knocks the hero down after 40 ticks of stun.

**Consequences:**
- **Two boss heavies cannot land inside one 2-second food interval** unless the second lands in the last 34 ticks after the grace ends. The real burst is heavy + hazard, or light combos before or after a heavy.
- **Attacks that a dodge alone cannot cover:**
  - Active longer than the 12 invulnerable ticks: `wiroj_ruin` (16), `zero_frenzy` (20), `k7_overdrive` (14), `subject_frenzy` (14).
  - Wind-ups at 20 ticks: `foreman_sweep`, `wiroj_ruin`, `subject_frenzy`, `champ_rush`. These leave about 5 ticks after a typical 15-tick (250 ms) human reaction. The 250 ms reaction time is an assumption [INFERRED].

### V3.2 Measured burst, dodging and skill

[MEASURED]
- "Worst 2 s burst" = the most HP lost in any 120-tick window of the fight.
- "÷ ½ HP" compares it with the health left when the hero eats (below 50%). 1.0 or more means a burst can kill straight through the food timing.

| Boss area | Profile | Model | Skill | KO | Damage in /s | Worst 2 s burst | Burst ÷ HP left after eating (½ HP) | Heavy attacks started / landed (avoided) | Dodges | Knockdowns | Time stunned | Foods |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gang_hq | A | current | skilled | 1/4 | 15.9 | 103 | 0.94 | 4.2 / 2.2 (47%) | 2.8 | 3.8 | 15% | 10.0 |
| gang_hq | A | current | unskilled | 0/4 | 16.9 | 118 | 1.07 | 5.0 / 3.2 (35%) | 0.0 | 3.8 | 16% | 12.5 |
| gang_hq | B | current | skilled | 0/4 | 12.8 | 102 | 0.77 | 3.5 / 1.8 (50%) | 2.8 | 2.5 | 14% | 7.5 |
| gang_hq | B | current | unskilled | 0/4 | 16.1 | 104 | 0.79 | 4.2 / 3.2 (24%) | 0.0 | 3.2 | 18% | 10.5 |
| gang_hq | C | current | skilled | 0/4 | 11.1 | 84 | 0.53 | 2.5 / 1.5 (40%) | 1.2 | 1.5 | 14% | 1.5 |
| gang_hq | C | current | unskilled | 0/4 | 14.8 | 88 | 0.55 | 3.2 / 2.8 (15%) | 0.0 | 3.0 | 17% | 3.0 |
| gang_hq | D | current | skilled | 0/4 | 7.0 | 62 | 0.30 | 2.2 / 0.8 (67%) | 2.2 | 0.8 | 13% | 0.2 |
| gang_hq | D | current | unskilled | 0/4 | 10.5 | 76 | 0.36 | 3.0 / 2.5 (17%) | 0.0 | 2.5 | 14% | 1.2 |
| factory_drains | A | current | skilled | 0/4 | 17.3 | 151 | 0.76 | 9.0 / 3.0 (67%) | 10.5 | 3.5 | 14% | 8.2 |
| factory_drains | A | current | unskilled | 0/4 | 18.8 | 135 | 0.67 | 9.2 / 4.8 (49%) | 0.0 | 5.2 | 14% | 9.8 |
| factory_drains | B | current | skilled | 0/4 | 14.8 | 116 | 0.52 | 7.0 / 4.2 (39%) | 7.0 | 4.8 | 11% | 5.5 |
| factory_drains | B | current | unskilled | 0/4 | 16.6 | 118 | 0.53 | 9.0 / 4.2 (53%) | 0.0 | 4.8 | 14% | 6.0 |
| factory_drains | C | current | skilled | 0/4 | 7.4 | 68 | 0.24 | 4.5 / 2.0 (56%) | 4.2 | 2.0 | 7% | 0.5 |
| factory_drains | C | current | unskilled | 0/4 | 11.1 | 90 | 0.32 | 4.5 / 3.2 (28%) | 0.0 | 4.0 | 9% | 1.5 |
| factory_drains | D | current | skilled | 0/4 | 6.8 | 68 | 0.19 | 4.0 / 2.0 (50%) | 4.5 | 2.2 | 11% | 0.0 |
| factory_drains | D | current | unskilled | 0/4 | 7.9 | 74 | 0.20 | 4.2 / 2.5 (41%) | 0.0 | 3.0 | 11% | 0.2 |
| control_room | A | current | skilled | 0/4 | 21.9 | 220 | 0.73 | 7.8 / 2.5 (68%) | 6.0 | 4.2 | 11% | 5.0 |
| control_room | A | current | unskilled | 0/4 | 29.3 | 205 | 0.68 | 10.8 / 5.0 (53%) | 0.0 | 8.5 | 15% | 7.8 |
| control_room | B | current | skilled | 0/4 | 17.7 | 136 | 0.41 | 8.2 / 2.5 (70%) | 6.2 | 3.0 | 13% | 3.2 |
| control_room | B | current | unskilled | 0/4 | 23.7 | 189 | 0.56 | 6.0 / 3.0 (50%) | 0.0 | 5.0 | 15% | 4.5 |
| control_room | C | current | skilled | 0/4 | 8.2 | 98 | 0.24 | 4.5 / 1.2 (72%) | 4.0 | 1.5 | 9% | 0.0 |
| control_room | C | current | unskilled | 0/4 | 14.4 | 108 | 0.26 | 4.2 / 2.0 (53%) | 0.0 | 3.0 | 12% | 0.8 |
| control_room | D | current | skilled | 0/4 | 7.9 | 94 | 0.20 | 4.8 / 1.8 (63%) | 2.5 | 2.2 | 10% | 0.0 |
| control_room | D | current | unskilled | 0/4 | 10.4 | 102 | 0.22 | 3.8 / 1.2 (67%) | 0.0 | 3.0 | 12% | 0.0 |
| core_chamber | A | current | skilled | 0/4 | 19.2 | 220 | 0.63 | 7.8 / 4.0 (48%) | 17.2 | 4.0 | 8% | 5.0 |
| core_chamber | A | current | unskilled | 0/4 | 14.3 | 160 | 0.45 | 4.0 / 3.5 (12%) | 0.0 | 3.5 | 6% | 2.5 |
| core_chamber | B | current | skilled | 0/4 | 11.0 | 140 | 0.32 | 4.2 / 2.2 (47%) | 12.0 | 2.2 | 6% | 1.0 |
| core_chamber | B | current | unskilled | 0/4 | 14.1 | 166 | 0.38 | 3.5 / 3.2 (7%) | 0.0 | 3.2 | 6% | 1.5 |
| core_chamber | C | current | skilled | 0/4 | 7.7 | 122 | 0.23 | 3.0 / 1.5 (50%) | 8.5 | 1.5 | 4% | 0.0 |
| core_chamber | C | current | unskilled | 0/4 | 12.9 | 164 | 0.31 | 3.8 / 2.8 (27%) | 0.0 | 2.8 | 7% | 0.2 |
| core_chamber | D | current | skilled | 0/4 | 5.9 | 106 | 0.15 | 3.0 / 2.2 (25%) | 7.5 | 2.2 | 5% | 0.0 |
| core_chamber | D | current | unskilled | 0/4 | 5.0 | 60 | 0.09 | 2.0 / 1.8 (12%) | 0.0 | 1.8 | 6% | 0.0 |
| gang_hq | A | hybrid-T | skilled | 1/4 | 18.2 | 110 | 1.00 | 4.0 / 2.8 (31%) | 1.5 | 2.8 | 17% | 10.0 |
| gang_hq | A | hybrid-T | unskilled | 1/4 | 20.2 | 118 | 1.08 | 3.2 / 2.8 (15%) | 0.0 | 2.8 | 19% | 10.8 |
| gang_hq | B | hybrid-T | skilled | 0/4 | 15.1 | 110 | 0.83 | 3.0 / 1.8 (42%) | 2.2 | 2.2 | 16% | 7.5 |
| gang_hq | B | hybrid-T | unskilled | 1/4 | 19.5 | 104 | 0.79 | 3.0 / 2.8 (8%) | 0.0 | 2.8 | 19% | 8.0 |
| gang_hq | C | hybrid-T | skilled | 0/4 | 13.8 | 90 | 0.57 | 2.8 / 1.8 (36%) | 2.0 | 2.8 | 13% | 2.2 |
| gang_hq | C | hybrid-T | unskilled | 0/4 | 15.6 | 102 | 0.64 | 2.5 / 2.2 (10%) | 0.0 | 2.2 | 16% | 3.0 |
| gang_hq | D | hybrid-T | skilled | 0/4 | 11.7 | 86 | 0.41 | 2.8 / 1.2 (55%) | 1.5 | 1.5 | 14% | 0.8 |
| gang_hq | D | hybrid-T | unskilled | 0/4 | 14.4 | 100 | 0.48 | 2.8 / 2.2 (18%) | 0.0 | 2.5 | 15% | 1.8 |
| factory_drains | A | hybrid-T | skilled | 0/4 | 16.9 | 133 | 0.67 | 7.5 / 2.8 (63%) | 8.5 | 3.5 | 12% | 7.2 |
| factory_drains | A | hybrid-T | unskilled | 0/4 | 20.9 | 150 | 0.75 | 10.0 / 4.8 (52%) | 0.0 | 5.5 | 14% | 9.0 |
| factory_drains | B | hybrid-T | skilled | 0/4 | 15.9 | 116 | 0.52 | 7.0 / 3.5 (50%) | 8.2 | 3.8 | 11% | 5.5 |
| factory_drains | B | hybrid-T | unskilled | 0/4 | 20.1 | 134 | 0.60 | 9.8 / 4.2 (56%) | 0.0 | 5.2 | 14% | 7.2 |
| factory_drains | C | hybrid-T | skilled | 0/4 | 11.0 | 94 | 0.34 | 4.5 / 1.2 (72%) | 4.2 | 1.8 | 9% | 1.0 |
| factory_drains | C | hybrid-T | unskilled | 0/4 | 14.5 | 105 | 0.37 | 5.0 / 2.8 (45%) | 0.0 | 2.8 | 11% | 2.0 |
| factory_drains | D | hybrid-T | skilled | 0/4 | 10.4 | 89 | 0.24 | 4.2 / 1.5 (65%) | 3.8 | 1.5 | 10% | 0.5 |
| factory_drains | D | hybrid-T | unskilled | 0/4 | 14.2 | 112 | 0.31 | 4.2 / 2.5 (41%) | 0.0 | 3.0 | 11% | 0.8 |
| control_room | A | hybrid-T | skilled | 0/4 | 23.0 | 213 | 0.71 | 7.2 / 2.2 (69%) | 6.0 | 3.8 | 11% | 4.8 |
| control_room | A | hybrid-T | unskilled | 0/4 | 29.5 | 223 | 0.74 | 7.5 / 4.0 (47%) | 0.0 | 5.8 | 13% | 6.5 |
| control_room | B | hybrid-T | skilled | 0/4 | 20.6 | 181 | 0.54 | 6.8 / 2.5 (63%) | 5.5 | 3.5 | 11% | 3.2 |
| control_room | B | hybrid-T | unskilled | 0/4 | 29.0 | 217 | 0.65 | 6.5 / 3.2 (50%) | 0.0 | 5.0 | 14% | 4.8 |
| control_room | C | hybrid-T | skilled | 0/4 | 17.7 | 144 | 0.35 | 4.8 / 1.0 (79%) | 5.0 | 1.8 | 11% | 1.2 |
| control_room | C | hybrid-T | unskilled | 0/4 | 25.7 | 185 | 0.45 | 4.8 / 2.0 (58%) | 0.0 | 3.8 | 13% | 2.5 |
| control_room | D | hybrid-T | skilled | 0/4 | 16.5 | 158 | 0.34 | 3.5 / 1.5 (57%) | 2.2 | 2.2 | 10% | 0.5 |
| control_room | D | hybrid-T | unskilled | 0/4 | 23.1 | 169 | 0.36 | 3.2 / 2.2 (31%) | 0.0 | 3.8 | 12% | 1.5 |
| core_chamber | A | hybrid-T | skilled | 0/4 | 18.5 | 235 | 0.67 | 5.8 / 3.0 (48%) | 13.0 | 3.0 | 7% | 4.2 |
| core_chamber | A | hybrid-T | unskilled | 0/4 | 18.9 | 213 | 0.60 | 3.8 / 3.8 (0%) | 0.0 | 3.8 | 6% | 3.8 |
| core_chamber | B | hybrid-T | skilled | 0/4 | 16.9 | 222 | 0.50 | 5.0 / 3.0 (40%) | 13.2 | 3.0 | 6% | 2.8 |
| core_chamber | B | hybrid-T | unskilled | 0/4 | 15.7 | 156 | 0.35 | 2.5 / 2.2 (10%) | 0.0 | 2.2 | 6% | 1.2 |
| core_chamber | C | hybrid-T | skilled | 0/4 | 10.6 | 137 | 0.26 | 3.2 / 1.5 (54%) | 8.5 | 1.5 | 4% | 0.2 |
| core_chamber | C | hybrid-T | unskilled | 0/4 | 17.0 | 186 | 0.35 | 3.2 / 2.2 (31%) | 0.0 | 2.2 | 7% | 0.8 |
| core_chamber | D | hybrid-T | skilled | 0/4 | 11.6 | 155 | 0.23 | 2.8 / 2.0 (27%) | 7.2 | 2.0 | 5% | 0.0 |
| core_chamber | D | hybrid-T | unskilled | 0/4 | 14.4 | 121 | 0.18 | 2.2 / 2.0 (11%) | 0.0 | 2.0 | 7% | 0.0 |

**Findings** [MEASURED]:
- **Today, bursts do not beat food late.**
  - Profile A's worst 2 s at the Director is 0.45–0.67 of its half HP (current and hybrid-T), so A survives on food.
  - Only Gang HQ (Furnace Baron, chapter 1) reaches 0.94–1.08, where A fell once in 4.
  - The Round 1 claim that "two hits inside 2 s kill A" is **not true** of the current bosses.
- **Dodging works but is not perfect.** Skilled auto battle avoids 25–79% of heavy attacks; unskilled 0–67% (some miss through positioning and knockdown grace).
- **Skill vs gear:**
  - Auto-battle-level skill is worth about one gear tier: A skilled ≈ B unskilled in damage taken (Gang HQ 15.9 vs 16.1/s; Factory Drains 17.3 vs 16.6; Control Room 21.9 vs 23.7).
  - A skilled undergeared hero does not match an unskilled +5 hero: at the Control Room 21.9 vs 14.4 (C unskilled).
  - A human dodging better than AutoPilot would close more of the gap [PREDICTED].
- **Stun-lock** is contained: 4–18% of a fight stunned; knockdowns 1–8.5 per fight; no runaway loops observed.

### V3.3 What it takes to make bursts matter

[PREDICTED from V3.2, hybrid-T]

| Item | Proposal |
|---|---|
| Scale-up | Make late bosses' (chapter 4 onward) **heavy attacks only** about **1.6×** larger in data (`moves.json` damage), not a global multiplier |
| Profile A | Burst ÷ ½ HP rises from about 0.6–0.7 to about 1.0–1.1, an upper estimate since only the heavy part of a burst is scaled: two dangerous hits close together kill through the food timing unless one is dodged |
| Profile B | Rises from about 0.35–0.54 to about 0.6–0.85: still alive, and still eating |
| Profile D | Rises from about 0.18–0.34 to about 0.3–0.55: comfortable |

**Avoidability rules for every attack that is scaled up** [PROPOSED]:
- Wind-up of at least 24 ticks, plus the existing visual telegraph.
- Active window of at most 12 ticks, or a reach the 70 px dodge leaves.
- A recovery window of at least 30 ticks.
- No hazard warning under 50 ticks.

The four moves above that break these rules (V3.1) are fixed first.

**Damage when dodging:**
- Dodging successfully: 0. Dodging badly: the full hit. There is no partial damage today [VERIFIED, `is_vulnerable`].
- Keep it: a clean, readable rule.

## V4. Swarm system review

[MEASURED]
- **A:** today's cap of 2.
- **B:** a cap of 3.
- **C:** a cap of 3 plus +5% damage per engaged enemy beyond 2 within 90 px (test-only).

Streets from chapters 2–6, profiles A, B and D, 10 foods.

| Street | Profile | Variant | KO | Clear s | Damage in /s | TTD s | Worst 2 s burst | Knockdowns | Time stunned | Foods |
|---|---|---|---|---|---|---|---|---|---|---|
| container_yard | A | A: max 2 (today) | 0/2 | 122 | 3.1 | 90 | 51 | 3.5 | 4% | 1.5 |
| container_yard | A | B: max 3 | 0/2 | 123 | 3.7 | 75 | 60 | 4.0 | 5% | 3.5 |
| container_yard | A | C: max 3 + pressure | 0/2 | 123 | 3.8 | 74 | 64 | 4.0 | 5% | 3.5 |
| container_yard | A | A, unskilled | 0/2 | 126 | 4.6 | 62 | 72 | 4.0 | 7% | 3.5 |
| container_yard | A | C, unskilled | 0/2 | 129 | 6.4 | 44 | 90 | 10.0 | 7% | 7.0 |
| container_yard | B | A: max 2 (today) | 0/2 | 97 | 1.9 | 190 | 32 | 1.0 | 4% | 0.0 |
| container_yard | B | B: max 3 | 0/2 | 105 | 2.3 | 151 | 50 | 2.0 | 5% | 1.0 |
| container_yard | B | C: max 3 + pressure | 0/2 | 105 | 2.3 | 151 | 50 | 2.0 | 5% | 1.0 |
| container_yard | B | A, unskilled | 0/2 | 115 | 3.3 | 105 | 48 | 2.0 | 9% | 1.5 |
| container_yard | B | C, unskilled | 0/2 | 109 | 4.7 | 74 | 57 | 5.0 | 9% | 2.5 |
| container_yard | D | A: max 2 (today) | 0/2 | 84 | 0.7 | 816 | 14 | 2.0 | 2% | 0.0 |
| container_yard | D | B: max 3 | 0/2 | 75 | 0.2 | 2523 | 5 | 0.5 | 4% | 0.0 |
| container_yard | D | C: max 3 + pressure | 0/2 | 75 | 0.2 | 2523 | 5 | 0.5 | 4% | 0.0 |
| container_yard | D | A, unskilled | 0/2 | 84 | 0.7 | 854 | 16 | 1.5 | 5% | 0.0 |
| container_yard | D | C, unskilled | 0/2 | 78 | 0.5 | 1028 | 14 | 2.0 | 5% | 0.0 |
| waste_pools | A | A: max 2 (today) | 0/2 | 141 | 3.8 | 102 | 68 | 4.0 | 3% | 2.5 |
| waste_pools | A | B: max 3 | 0/2 | 128 | 3.8 | 102 | 78 | 4.0 | 2% | 2.0 |
| waste_pools | A | C: max 3 + pressure | 0/2 | 128 | 3.8 | 102 | 78 | 4.0 | 2% | 2.0 |
| waste_pools | A | A, unskilled | 0/2 | 143 | 7.2 | 54 | 106 | 9.0 | 5% | 5.5 |
| waste_pools | A | C, unskilled | 0/2 | 137 | 6.3 | 62 | 84 | 7.5 | 4% | 4.5 |
| waste_pools | B | A: max 2 (today) | 0/2 | 116 | 2.6 | 172 | 56 | 3.0 | 2% | 0.5 |
| waste_pools | B | B: max 3 | 0/2 | 115 | 2.5 | 176 | 58 | 2.5 | 3% | 0.5 |
| waste_pools | B | C: max 3 + pressure | 0/2 | 115 | 2.5 | 176 | 58 | 2.5 | 3% | 0.5 |
| waste_pools | B | A, unskilled | 0/2 | 122 | 4.4 | 99 | 80 | 4.0 | 5% | 2.5 |
| waste_pools | B | C, unskilled | 0/2 | 117 | 5.4 | 82 | 80 | 6.5 | 5% | 3.0 |
| waste_pools | D | A: max 2 (today) | 0/2 | 89 | 0.2 | 3295 | 12 | 0.5 | 1% | 0.0 |
| waste_pools | D | B: max 3 | 0/2 | 91 | 0.5 | 1368 | 22 | 1.0 | 2% | 0.0 |
| waste_pools | D | C: max 3 + pressure | 0/2 | 91 | 0.5 | 1368 | 22 | 1.0 | 2% | 0.0 |
| waste_pools | D | A, unskilled | 0/2 | 88 | 0.8 | 884 | 24 | 1.5 | 2% | 0.0 |
| waste_pools | D | C, unskilled | 0/2 | 87 | 1.5 | 483 | 29 | 3.0 | 3% | 0.0 |
| machine_hall | A | A: max 2 (today) | 0/2 | 112 | 5.4 | 107 | 71 | 3.0 | 3% | 2.0 |
| machine_hall | A | B: max 3 | 0/2 | 107 | 6.0 | 96 | 111 | 1.0 | 5% | 3.0 |
| machine_hall | A | C: max 3 + pressure | 0/2 | 107 | 6.1 | 94 | 117 | 1.0 | 5% | 3.0 |
| machine_hall | A | A, unskilled | 0/2 | 112 | 14.4 | 40 | 176 | 11.5 | 7% | 6.5 |
| machine_hall | A | C, unskilled | 0/2 | 99 | 12.9 | 45 | 173 | 7.0 | 8% | 5.5 |
| machine_hall | B | A: max 2 (today) | 0/2 | 97 | 6.2 | 105 | 101 | 4.0 | 5% | 1.0 |
| machine_hall | B | B: max 3 | 0/2 | 87 | 5.8 | 111 | 99 | 2.5 | 5% | 1.0 |
| machine_hall | B | C: max 3 + pressure | 0/2 | 89 | 5.3 | 124 | 105 | 2.0 | 5% | 1.0 |
| machine_hall | B | A, unskilled | 0/2 | 99 | 8.4 | 78 | 126 | 6.0 | 6% | 2.0 |
| machine_hall | B | C, unskilled | 0/2 | 82 | 11.1 | 59 | 159 | 7.0 | 8% | 2.0 |
| machine_hall | D | A: max 2 (today) | 0/2 | 60 | 1.1 | 810 | 28 | 1.5 | 3% | 0.0 |
| machine_hall | D | B: max 3 | 0/2 | 60 | 0.2 | 5382 | 4 | 0.0 | 3% | 0.0 |
| machine_hall | D | C: max 3 + pressure | 0/2 | 60 | 0.2 | 4816 | 5 | 0.0 | 3% | 0.0 |
| machine_hall | D | A, unskilled | 0/2 | 57 | 2.5 | 372 | 49 | 2.5 | 4% | 0.0 |
| machine_hall | D | C, unskilled | 0/2 | 56 | 1.6 | 579 | 30 | 1.5 | 5% | 0.0 |
| reactor_walkway | A | A: max 2 (today) | 0/2 | 128 | 16.4 | 42 | 262 | 9.0 | 4% | 7.5 |
| reactor_walkway | A | B: max 3 | 0/2 | 119 | 11.7 | 59 | 248 | 5.0 | 4% | 4.0 |
| reactor_walkway | A | C: max 3 + pressure | 0/2 | 123 | 14.8 | 47 | 263 | 7.0 | 5% | 6.5 |
| reactor_walkway | A | A, unskilled | 0/2 | 126 | 22.5 | 31 | 280 | 11.5 | 8% | 10.0 |
| reactor_walkway | A | C, unskilled | 1/2 | 123 | 26.8 | 26 | 262 | 13.0 | 8% | 14.0 |
| reactor_walkway | B | A: max 2 (today) | 0/2 | 102 | 14.7 | 54 | 176 | 8.0 | 4% | 5.0 |
| reactor_walkway | B | B: max 3 | 0/2 | 113 | 14.2 | 56 | 186 | 8.0 | 5% | 5.0 |
| reactor_walkway | B | C: max 3 + pressure | 0/2 | 111 | 15.8 | 50 | 244 | 9.0 | 5% | 5.5 |
| reactor_walkway | B | A, unskilled | 0/2 | 95 | 14.4 | 55 | 238 | 8.0 | 3% | 4.0 |
| reactor_walkway | B | C, unskilled | 0/2 | 100 | 18.9 | 42 | 220 | 11.5 | 6% | 6.0 |
| reactor_walkway | D | A: max 2 (today) | 0/2 | 66 | 6.5 | 183 | 110 | 3.0 | 1% | 0.0 |
| reactor_walkway | D | B: max 3 | 0/2 | 66 | 6.8 | 175 | 110 | 3.0 | 6% | 0.0 |
| reactor_walkway | D | C: max 3 + pressure | 0/2 | 66 | 6.8 | 173 | 110 | 3.0 | 6% | 0.0 |
| reactor_walkway | D | A, unskilled | 0/2 | 62 | 10.1 | 117 | 126 | 4.5 | 3% | 0.5 |
| reactor_walkway | D | C, unskilled | 0/2 | 71 | 11.8 | 101 | 148 | 6.0 | 6% | 1.5 |

**Findings:**
- **Raising the cap to 3 changes damage taken by −29% to +21% for A and B**, inside the noise of 2 fights. D's very small values (0.2–1.1 per second) swing more in both directions. Auto battle pulls camps one at a time, and enemy cooldowns of 28–59 ticks rarely line up three attacks.
- **Pressure (C) matters only for unskilled heroes.** In the Reactor Walkway, A unskilled under C fell once in 2, with 13 knockdowns and 14 foods; under today's rule: 11.5 knockdowns, no fall.
- **Escape** is unchanged: the hero always has dodge, knockdown grace and the safe west end.
- **Stun-lock risk** rises slightly with C for unskilled heroes: knockdowns 10 vs 4 in Container Yard.

**Recommendation** [PROPOSED]:
- **Keep `MAX_ATTACKERS = 2`.** Variant B gains nothing measurable. Variant C mostly punishes unskilled play through more knockdowns, against Hard but Fair.
- Put mob pressure into **elite roles** instead (elites' heavy hits already carry most street damage) and into the defense curve.

## V5. World boss validation

**Unchanged** (owner rules): unlimited entries, no attempt counts, no forced waiting, the current reward rules, and no contribution requirement.

**Today** [MEASURED, audit §15, pre-#73]:

| Profile | One attempt lasts, 10 foods | Damage out /s |
|---|---|---|
| A | 61–94 s | 27–64 |
| D | 194–513 s | 76–134 |

A solo A hero can empty the 3-player Tunnel Mother in about 45 minutes of hitting. The 5- and 10-player bosses are out of solo reach.

**Proposed enrage** [PROPOSED]:

| Item | Design |
|---|---|
| Trigger | Time-based: minute 40 of the 60-minute round. The same for everyone and computable from the round's clock (`WorldBossRules.window`), so a future server and every client agree. Not HP-based, which would punish groups for being fast. |
| Warning | 60 s before: a banner on the boss bar ("The Colossus overheats in 60 s"), a distinct sound, and a 10-second countdown. Enrage then shows a red boss bar for the rest of the round. |
| Escalation | Attack frequency +25% (AI cooldown ×0.8) and one more hazard in each volley. No damage multiplier: the threat grows through pace and space, so it stays dodgeable and gear-neutral. |
| Expected response | More dodging, more distance from hazards, faster damage. Weaker heroes fall more often and re-enter as they like. |

**Effect by profile** [PREDICTED; incoming damage scales with attack rate (about +33%) and hazard count]:

| Profile | One attempt lasts, with food (today → enraged) |
|---|---|
| A | 61–94 s → about 45–70 s |
| D | 194–513 s → about 145–385 s |

- Kill time drops for strong groups (more risk, same damage).
- Weak solo heroes contribute less per attempt but can always come back.

**Large-scale multiplayer** [PREDICTED / UNKNOWN until IL-7]:
- Single-target attacks spread over many players, so per-player pressure falls with crowd size. Hazards are area attacks and keep their danger in a crowd. The extra volley therefore scales naturally with density.
- No HP or damage scaling by player count is needed for the enrage itself.
- Server cost: the enrage is a timer and two parameters, so negligible. The crowd's effect on hazard count needs a load test.

**Contribution requirements:** not proposed. Before any is considered, a fairness analysis must cover:
- Healers or supports, if added.
- Players who join late in the round.
- Heroes who fall early through bad luck.
- AFK detection that does not punish slow devices.
- How shares interact with the existing personal tiers.

## V6. Production rules: PR #73 inventory

On `main` at `1cd3bdb` [VERIFIED by `git show`]. **Nothing is removed or changed by this document.**

| # | Item | Where | Purpose | Impact | Alternatives (owner-compliant) |
|---|---|---|---|---|---|
| 1 | **Food cap: 6 per boss fight** (violates "unlimited food") | `client/data/progression.json:13` (`"boss_fight_food": 6`); `client/sim/FoodRules.gd:22` `boss_food_left`, `:31` `why_not`; `client/sim/ZoneSim.gd:65` `boss_food`, `:622` refusal, `:627` counter; `client/sim/AutoPilot.gd:143`; `client/scenes/game/Game.gd:406–407, 574` (messages); `client/scenes/ui/Hotbar.gd:83` (dimmed slot); `client/sim/ContentDB.gd:866` (validation); `README.md:51`; tests `client/tests/unit/test_food.gd:71, 98` | Stop food from out-healing bosses | Undergeared heroes lose the finale even with food (audit §12). Also makes food feel arbitrary. | Remove. Replace with hybrid-T, burst-sized heavy attacks and the power split (V1–V3) |
| 2 | **World boss tries: 3 per round** (violates "unlimited entries") | `client/data/world_boss.json:9, 85, 142` (`"attempts": 3`); `client/sim/WorldBossRules.gd:13` (doc), `:71–72` refusal, `:77–81` `attempts_left`, `:85–87` `begin_attempt`, `:119` state; `client/sim/WorldBossRun.gd:36`; `client/sim/PlayerProfile.gd:381` (save field); `client/scenes/game/GameMenus.gd:644–647, 697–698` (text); `client/sim/ContentDB.gd:398` (validation); test `client/tests/unit/test_world_boss.gd:88` | Stop solo grinding of group bosses | A solo hero can no longer kill the Tunnel Mother without top gear. Saves now carry an `attempts` count per round (harmless when ignored). | Remove. Use the enrage (V5) and gear-led damage instead |
| 3 | **Director Wiroj ×2.2 power** (a global multiplier on one boss, not approved) | `client/data/enemies.json`, `director_wiroj` (entry at line 1936): power 1.0 → 2.2; phases 1.05 → 2.31 and 1.15 → 2.53 | Make the finale dangerous | Hits everyone 2.2×. D's time to die falls 234 → 54 s (audit §12). C loses 2/4 without food. | Revert. Re-base the Director's heavy attacks only (V3.3) under hybrid-T, with per-boss intents |
| 4 | **Subject Twelve ×1.5** (same) | `client/data/enemies.json`, `subject_twelve` (entry at line 1675): power 1.0 → 1.5; phase 1.1 → 1.65 | Remove a soft spot in chapter 5 | Raises all its damage for every profile | Revert; re-base by intent like 3 |

**Also present:**
- **Tests that encode the violations:**
  - `test_food.gd`: `test_a_boss_fight_allows_only_a_few_foods`, `test_food_cannot_stand_in_for_gear_against_the_final_boss`.
  - `test_world_boss.gd`: `test_a_round_allows_a_few_tries`.

  These would be removed with items 1 and 2.
- **The unmerged branch commit `15fbb0f`** already removes items 1 and 2, but adds a gear-score check that fails 2 tests. It is recommended not to merge it as is.
- **Not a violation:** the CHANGELOG and the Dockerfile apt fix in PR #73.

## V7. Consolidated test matrix

**Labels:**
- **M** = measured in this round or the audit (reproducible with §V11).
- **P** = a prediction to verify after implementation.
- **T** = an automated test to add.

| Area | Case | Status | Result / target |
|---|---|---|---|
| Level progression | Profile stats levels 5–48 | M | V2.1 |
| Level progression | Level's share of power at level 48 | M | 30% today → about 20% proposed (P) |
| Equipment grade | Grade's share at level 48 | M | 7% today → about 15% (P) |
| Enhancement | +5 and +10 shares | M | 28% today at +10 |
| Enhancement | B5÷B hits to die, late | M | 1.2–1.3× (hybrid-T) |
| Enhancement | T: +N gives 10%·N of each positive stat | T | exact |
| Slots | Each slot removed or upgraded, boss fight | M | V2.3; every slot matters |
| Defense formula | Five models × six stages × five profiles (static) | M | V1.2 |
| Defense formula | Five models × bosses and streets (fights) | M | V1.3 |
| Defense formula | T: floors (20% ordinary, 45% heavy), monotonic in DEF, K = 30 + 2L | T | exact |
| Normal enemy damage | Street damage taken per profile | M | V1.3 streets |
| Normal enemy damage | T: hits-to-die for B falls monotonically by chapter | T | target |
| Elite damage | Elite heavy hits by stage | M | V1.2 (mob heavy max) |
| Boss damage | Burst ÷ ½ HP per profile | M | V3.2 |
| Boss damage | Burst ÷ ½ HP after heavies ×1.6 (late) | P | A about 1.0–1.1, B ≤ 0.85, D ≤ 0.55 |
| Boss damage | T: every heavy has wind-up ≥ 24, active ≤ 12 (or reach < dodge travel), recovery ≥ 30 | T | data check |
| Food healing | 10 foods, every model | M | everyone survives today's bosses (V1.3) |
| Food healing | T: food rules unchanged (heal amounts, 2 s cooldown, no caps) | T | regression guard for the owner's rule |
| Dodge | Heavy attacks avoided, skilled vs unskilled | M | 25–79% vs 0–67% |
| Dodge | Skilled A vs unskilled B / C | M | A skilled ≈ B unskilled; C unskilled better |
| Swarm | Cap 2 / 3 / 3 + pressure | M | V4: keep 2 |
| Stun-lock | Time stunned, knockdowns | M | 4–18%, no loops |
| World boss | One attempt per profile (no enrage) | M | audit §15 |
| World boss | With enrage | P | A about −25% time alive; D about −25% |
| World boss | T: entries unlimited; no attempt state consulted | T | regression guard for the owner's rule |
| World boss | Many players, shared pool | UNKNOWN | needs IL-7 and a load test |

## V8. Recommended final design

[PROPOSED; pending approval]
1. **Restore the owner's rules on main:** remove the food cap and the world-boss tries (V6 items 1–2).
2. **Revert the two boss multipliers** (V6 items 3–4), replaced by step 5's per-attack re-basing.
3. **Defense: hybrid-T.**
   - Ordinary hits: `max(max(1, 0.2·raw), raw·K/(K+DEF) − 0.1·DEF)`.
   - Heavy hits, hazards and throws: `max(0.45·raw, raw·K/(K+DEF/2))`.
   - K = 30 + 2 × attacker level. Constants in data.
   - Order of steps unchanged.
4. **Power split and grade spread:**
   - `per_level.power` about 0.03.
   - Grades epic about 1.5 and legendary about 1.85.
   - Hands gain a little defense early.
   - Items re-derived from `ItemRules` budgets.
5. **Late bosses' heavy attacks about 1.6× in `moves.json` (chapter 4 onward)**, tuned per boss against intents. The avoidability rules (V3.3) apply first.
6. **Keep `MAX_ATTACKERS = 2`.** Elites carry street pressure.
7. **World boss enrage:** time-based at minute 40, 60 s warning, +25% attack rate, +1 hazard per volley, no damage multiplier. Unlimited entries and current rewards kept.
8. **Intended profiles:**
   - Chapters 1–2: B.
   - Chapters 3–4: B with some +3 or boss pieces.
   - Chapters 5–6: B5 or C.
   - +10 is never required for the story.

**Superseded from Round 1:**

| Earlier proposal | Replaced by |
|---|---|
| Model D with K = 2L (§6, §19.1) | Hybrid-T |
| "Two heavies inside 2 s" (§13) | Heavy + hazard or combo bursts, with avoidability rules |
| Swarm 3 + 5% (§19.5) | Keep 2 |
| Enrage in the "last 20 minutes" with a faster-attacks-only rule (§10) | V5 |

## V9. Remaining risks

- **AutoPilot is not a human.** Dodge rates, burst and skill-vs-gear need a few recorded human sessions, especially at the four fast-wind-up moves.
- **Few seeds.** 2–4 fights per cell, so small differences (under about 20%) are noise. Implementation should re-measure with 8+ seeds per cell.
- **K approximation.** In the scratch runs, K was set from the area level for both directions (the hero's attacks too). In-game, K would use each attacker's own level; the result should be close but must be re-measured.
- **Tuning debt.** Farm income, the story-auto test and every harness band move with the defense curve, and must be re-tuned in the same PR.
- **File-size limits.** `ZoneSim.gd` and `Game.gd` are at the 1000-line lint limit. New logic belongs in helpers (`DefenseRules`).
- **Readability.** Bigger heavy attacks need clear telegraphs, or they read as unfair deaths.

## V10. Owner approval checklist

- [ ] Remove the food cap from main (V6 #1).
- [ ] Remove the world-boss tries from main (V6 #2).
- [ ] Revert Director ×2.2 (V6 #3).
- [ ] Revert Subject Twelve ×1.5 (V6 #4).
- [ ] Do not merge the gear-check commit `15fbb0f` as is.
- [ ] Approve hybrid-T (V1.1), constants: K = 30 + 2L, floors 20% / 45%, flat 0.1.
- [ ] Approve the power split (`per_level.power` about 0.03) and the grade spread (epic about 1.5, legendary about 1.85).
- [ ] Approve late bosses' heavy attacks about 1.6× with the avoidability rules (V3.3).
- [ ] Approve keeping `MAX_ATTACKERS = 2` (V4).
- [ ] Approve the world-boss enrage design (V5); no contribution requirement.
- [ ] Approve the intended profile per chapter (V8.8).
- [ ] Approve the test matrix (V7) as the definition of done.

## V11. Reproducing these results

**Scratch only;** nothing here goes into the repository without approval.

1. Check out `e0830ed` into a separate worktree.
2. In that copy, `ZoneSim.gd`'s `const MAX_ATTACKERS := 2` became `static var MAX_ATTACKERS := 2`.
3. `CombatRules.damage_for` and `thrown_hit` call a test switch `x_reduce(raw, defense, heavy, to_hero)`:
   - It applies the selected model.
   - `x_k = 2 × (area level + 2)`; hybrid-T uses `30 + x_k`.
   - Optional swarm pressure: `raw × (1 + 0.05 × engaged enemies beyond 2 within 90 px)`, only when the defender is the hero.
4. **Profiles:** built as in V0 from `ProgressionHarness.gear` and the best-scoring items.
5. **Unskilled:** `input.dodge = false; input.guard = false` after `AutoPilot.think`.
6. **Recorded per fight:**
   - Knock-out, fight time.
   - HP lost per second while in an encounter.
   - Worst 120-tick window of HP lost.
   - Heavy (`telegraph`) attacks started (swing events) and landed (hit events on the hero).
   - Dodges started, knockdowns (entries into DOWN), share of fight in HITSTUN, foods eaten.
7. **Runs:**
   - 4 models + hybrid-T × bosses `canal_works`, `factory_drains`, `core_chamber` and streets `rusted_corner`, `waste_pools`, `reactor_walkway`; profiles A, B, B5, C, D; Oren and Mika; no food and 10 foods.
   - Burst: `gang_hq`, `factory_drains`, `control_room`, `core_chamber` × A–D × skilled and unskilled × 2 seeds.
   - Swarm: `container_yard`, `waste_pools`, `machine_hall`, `reactor_walkway` × A, B, D × the three variants.
   - Slots: `sak_tower`, profile B with each slot removed or upgraded, no food, 2 seeds.
