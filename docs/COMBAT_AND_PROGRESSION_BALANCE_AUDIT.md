# Combat and Progression Balance Audit

Audit only: nothing in this report changes the game. Every finding carries a label:

- **[VERIFIED]**: read directly from source or data, with the file and function named.
- **[MEASURED]**: produced by running the game's own simulation (`ZoneSim`, `AutoPilot`, `WorldBossRun`) headless.
- **[PROPOSED]**: a design for later, not built.
- **[UNKNOWN]**: cannot be settled with the evidence available; the measurement needed is named.

## 0. What was audited, and how

**Code audited** [VERIFIED]:

| Version | Commit | Contents |
|---|---|---|
| **Pre-#73** | `e0830ed` | The game as the owner played it when reporting the problems. |
| **Main** | `1cd3bdb` | What is deployed now. Includes PR #73: 6 foods per boss fight, Subject Twelve ×1.5 and Director Wiroj ×2.2 power, 3 world-boss tries per round. |
| **Branch HEAD** | `15fbb0f` | Not merged, no PR. Removes the food cap and the tries, and adds a gear-score check (`client/sim/GearCheck.gd`). Its own test run failed 2 tests (section 21). Measurements below are of pre-#73 and main, not of this commit. |

**How it was audited:**
- Both versions were checked out into separate worktrees outside the repository. The audit scripts were copied into those worktrees only; the repository's working tree was not touched.
- Every number comes from the game's own rules: `LevelRules.enemy_stats`, `PlayerProfile.stats`, `CombatRules`, `AutoPilot`, `WorldBossRun`.
- Simulated play is **AutoPilot**, the game's own auto battle. It guards, dodges telegraphed attacks and eats below 50% HP, with no human reaction time or positioning. A skilled human will usually take less damage than these figures, so every survival number here is a floor for a good player [MEASURED].
- **Seeds:** 2 per boss fight, for 2 heroes (Oren the tank, Mika the damage dealer), so 4 fights per cell. Streets used 1 seed per hero. World-boss attempts used 1 seed per hero.

**Player profiles** [PROPOSED as test fixtures, built from repository items]:

| Profile | Gear |
|---|---|
| **A, undergeared** | The hero's starter kit plus 3 slots (weapon, body, head) of shop gear 10 levels below the area, all +0. The other slots stay at the starter kit or empty. |
| **B, basic** | Full shop gear at the area's level, +0 (`ProgressionHarness.gear(level, "shop")`). |
| **C, progressed** | Shop armour plus the best boss-drop weapon and charm at or below the level (`"boss"`), all +5. |
| **D, highly prepared** | The highest-scoring item of any grade at or below the level in every slot, all +10. |

**Food:**
- Each profile was run with no extra food, and with 10 of the food auto battle would buy (`FoodRules.shopping_list`, about a third of max HP per bite). 10 is auto battle's default restock, `auto_food`.
- The starter kit's 3 steamed buns are always carried, so "no food" profiles still eat up to 3 buns.

---

## 1. Executive Summary

**The question:** why can a hero in ordinary, incomplete, un-upgraded gear finish the story and fight world bosses without risk?

**What was measured** [MEASURED, pre-#73]:
- **Food:** profile A loses every story boss, 4 fights of 4, without food. With the 10 foods auto battle restocks, it beats every story boss except Gang HQ (1 loss in 4), the final boss included. Food can be eaten every 2 seconds, and in those fights A eats 5–10 foods, restoring 1–3 times its maximum health.
- **Ordinary monsters:** hit for about 1–20 against hero defense through most of the story.
- **Gear gap:** a hero in B gear takes 0.3–5.5 damage per second in the street fights of chapters 1–5 (2 to 13 minutes of standing still to die). D takes 0.1–1.2 per second. Profile A kills bosses only about 1–2× slower than D.

**Root causes in brief** (section 17):

1. **Unlimited, instant, fast food.** A 2-second shared cooldown and no limit per fight let healing replace defense entirely.
2. **Flat defense with a minimum of 1 damage.** Defense is subtracted from every hit, so a little defense erases ordinary monsters' small hits. A lot of defense makes the late game nearly immune: profile D has 66 defense against light hits averaging 53 at level 48.
3. **Hero growth outpaces enemy growth.** From level 1 to 48, hero health grows about 5.5× (B) to 7.0× (D) and hero power 4.4× (B) to 6.0× (D). Enemy power grows 4.9× and enemy health 3.9× over levels 1–50. Late bosses (Security Chief, Subject Twelve, Director Wiroj) also have lower base power than the mid-game ones. So the threat per hit falls as the story goes on.
4. **Death is cheap and world bosses keep their damage.** A knock-out costs 10% of carried coins and puts the hero back at full health just short of the boss. A world boss round keeps every attempt's damage and allows unlimited attempts, so a solo profile-A hero can empty the Tunnel Mother's 3-player pool in about 45 minutes of hitting, inside the 60-minute window.

**What does not exist** [VERIFIED]:
- Equipment set bonuses.
- Randomised equipment stats (every item has fixed stats).
- Mini-boss as a type (stories use elites).
- PvP.
- Server-side combat or a shared world-boss pool (backend is accounts and saves only; IL-7).
- 50 sub-stages: the story has 6 chapters and 30 combat areas.

**Recommended direction** [PROPOSED]:
- Keep the architecture. Rebalance by role and level, not with a global multiplier.
  1. Move defense to a percentage curve, or a curve with a damage floor.
  2. Make food a slower heal-over-time or per-food cooldown, not unlimited burst healing (no count cap, as the owner asked).
  3. Re-curve enemy damage and health against expected gear by chapter.
  4. Retune the soft bosses individually.
  5. Give world bosses fair, telegraphed, rising pressure (an enrage) and a minimum-contribution rule for rewards, instead of tries limits.
- Approve section 18's targets before any change.

## 2. Verified Existing Game Architecture

| Layer | Where | Notes |
|---|---|---|
| Combat rules | `client/sim/CombatRules.gd` (`tick`, `_apply_hit`, `damage_for`, `thrown_hit`, `is_vulnerable`) | Fixed 60 ticks/s. Pure functions, shared with the future server [VERIFIED]. |
| Fighters | `client/sim/Fighter.gd` | power, defense, max_hp, crit_chance, attack_speed, grace, stun meter, armor/poise, unshaken (bosses) [VERIFIED]. |
| Zone | `client/sim/ZoneSim.gd` (`spawn_enemy`, `_attack_tokens`, `use_item`, phases) | At most `MAX_ATTACKERS = 2` enemies attack at once; 120-tick shared item cooldown [VERIFIED]. |
| Enemy AI | `client/sim/EnemyBrain.gd`, `LevelRules.enemy_ai` | Cooldowns shorten 1.2% per level, to half at most [VERIFIED]. |
| Hero stats | `client/sim/PlayerProfile.gd` (`stats`, `gear_stats`) | Base + per-level + gear + enhance [VERIFIED]. |
| Enemy stats | `client/sim/LevelRules.gd` (`enemy_level`, `enemy_stats`, `phase_stats`) | Per-level scaling from a level-1 base [VERIFIED]. |
| Bosses | `client/sim/BossMechanics.gd`, enemies.json `phases`, `hazard`, `shield`, `summon` | Phases, hazards that scale with boss power, shields [VERIFIED]. |
| Items | `client/data/items.json`, `client/sim/ItemRules.gd` (grade budget), `EnhanceRules.gd` | 84 gear items; budget-checked grades; enhance +0 to +10 [VERIFIED]. |
| Food | `client/sim/FoodRules.gd`, `ZoneSim.use_item`, `skills.json item_cooldown` | Food items heal 25, 50, 120 and 220 [VERIFIED]. |
| World bosses | `client/sim/WorldBossRules.gd`, `WorldBossRun.gd`, `data/world_boss.json` | Per-round pool, rewards on kill only [VERIFIED]. |
| Online | `backend/src` (accounts, saves) | No combat, no shared boss pool. The zone server is planned for IL-7 (CLAUDE.md) [VERIFIED]. |

**Content counts** [VERIFIED, from areas.json, enemies.json and STORY_BIBLE.md §5]:
- 6 chapters:
  1. South Street: 10 areas, depot_yard (hub) to gang_hq.
  2. Port District: 4 areas.
  3. Industrial District: 4 areas.
  4. The Black Network: 4 areas.
  5. The Core Facility: 4 areas.
  6. The Iron Legacy: 4 areas.
- 30 combat areas, levels 2–48.
- 11 story bosses, 3 world bosses, 7 farming grounds.
- 38 enemy kinds, of which 14 are bosses and 7 are elites.
- The brief's "5 stories × 10 sub-stages = 50" is **not** what is built.

## 3. Current Player Stat Formula

`PlayerProfile.stats()` [VERIFIED]:

```
max_hp  = hero.max_hp + per_level.max_hp(10) * (level-1) + gear.max_hp
power   = hero.power  + per_level.power(0.05) * (level-1) + gear.power
defense = hero.defense + gear.defense                 (no level growth)
speed   = max(0.3, hero.speed + gear.speed)
crit    = clamp(hero.crit or 0.05 + gear.crit, 0, 0.5)
attack_speed = clamp(hero.attack_speed + gear.attack_speed, 0.7, 1.3)
gear.X  = sum over 6 slots of item.stats.X + EnhanceRules.bonus (item.stats.X * 0.1 * plus, positive stats only; max_hp and defense rounded)
```

**Base stats** (heroes.json) [VERIFIED]:

| Hero | max HP | Power | DEF |
|---|---|---|---|
| Mika | 100 | 1.1 | 0 |
| Oren | 130 | 1.0 | 2 |
| Riku | 115 | 1.05 | 1 |
| Kan | 110 | 1.0 | 1 |
| Dao | 120 | 0.95 | 2 |
| Pong | 140 | 1.0 | 3 |

- Level 50 adds +490 HP and +2.45 power, the same for every hero [VERIFIED].
- **Job or class modifiers:** none beyond these bases and each hero's skill set [VERIFIED].
- **Buffs, debuffs, passives:** no timed buff or debuff system and no passive abilities [VERIFIED by search of `client/sim`].
- **Skills:** all four of each hero's skills unlock by level 3. Their damage (22–52 base) scales only with power [VERIFIED, skills.json and moves.json].
- **Healing and regeneration:**
  - No healing skills and no HP regeneration in combat [VERIFIED].
  - Full heal on entering the city (`heal_on_enter`) or after a knock-out (`Game._recover`) [VERIFIED].
  - Energy regenerates 0.25 per tick (`CombatRules.ENERGY_REGEN`) [VERIFIED].
- **Invulnerability** [VERIFIED, `CombatRules.is_vulnerable`]:
  - Dodge: ticks 2–14 of a 20-tick dodge (20 energy).
  - DOWN and KO.
  - `grace`: 36 ticks after getting up from a stun-lock knockdown.
  - Stun-lock protection: at most 40 ticks of stun, then a knockdown (`HERO_STUN_LIMIT`).
  - Measured, the hero spends 0–14% of a fight unable to be hit [MEASURED].
- **Death** [VERIFIED, `Game._recover`, `EconomyRules.defeat_loss`]:
  - Lose 10% of carried coins.
  - Back at full HP at the area's west end, or just short of the boss fight lost.
  - Fights already won stay won.

**Profile stats at representative points** (Oren) [MEASURED, from `PlayerProfile.stats` and `ItemRules.copy_score`]:

| Area (Lv) | A: HP / power / DEF / gear score | B | C | D |
|---|---|---|---|---|
| saltmarket (2) | 155/1.20/4/37 | 175/1.20/4/53 | 193/1.28/5/80 | 210/1.35/6/106 |
| canal_works (3) | 165/1.25/4/37 | 195/1.25/4/58 | 218/1.33/5/87 | 232/1.46/10/143 |
| gang_hq (10) | 235/1.60/4/37 | 279/1.73/7/111 | 334/2.10/10/213 | 432/2.45/16/361 |
| crane_yard (16) | 317/1.98/5/69 | 376/2.30/9/170 | 463/2.84/14/318 | 580/3.21/20/476 |
| factory_drains (24) | 415/2.54/7/106 | 465/2.93/13/237 | 578/3.68/22/461 | 750/4.25/32/686 |
| sak_tower (31) | 510/3.06/10/155 | 590/3.54/15/316 | 723/4.44/24/572 | 890/5.56/38/951 |
| test_labs (35) | 550/3.26/10/155 | 645/3.96/20/379 | 800/4.44/37/633 | 910/6.06/42/1028 |
| control_room (39) | 615/3.60/12/193 | 685/4.16/20/379 | 840/5.39/35/737 | 950/6.72/44/1126 |
| core_chamber (48) | 720/4.21/15/236 | 900/5.04/23/528 | 1074/6.32/34/880 | 1390/7.77/66/1478 |

## 4. Current Monster Stat Formula

`LevelRules` [VERIFIED]:

```
enemy level   = area level + level_bonus (elite +1, boss +2) (enemy_level)
steps         = level - 1
max_hp        = base_hp * (1 + 0.06 * steps)
power         = base_power * (1 + 0.08 * steps)
defense       = base_defense + floor(steps / 8)
speed         = base_speed * min(1.25, 1 + 0.008 * steps)
AI cooldown   = base_cooldown * max(0.5, 1 - 0.012 * steps), at least 20 ticks; reaction likewise
heavy_chance  = base + 0.005 * steps (max 0.6); guard_chance 0.015*(level-3) (max 0.45); dodge 0.012*(level-8) (max 0.3)
boss phases   = phase stats on the same level-1 scale, then the same scaling (phase_stats)
```

**Elites:**
- Story elites are their own enemy kinds, fighting 1 level up [VERIFIED].
- Farming-ground elites (`FarmSpawner`) get 3× HP, 1.25× power and 3× rewards [VERIFIED].

**Bosses** [VERIFIED]:
- They fight 2 levels up and are `unshaken`: never flinch; they are broken by piled damage (`BREAK_SHARE 0.35`).
- They have phases, and some have hazards (damage × boss power), shields and summons.

**Mini-bosses:** no such type exists [VERIFIED].

## 5. Current Damage Calculation Formula

From `CombatRules._apply_hit`, in order [VERIFIED]:

1. **Reach and vulnerability:** `in_reach` (lane depth tolerance, reach box) and `is_vulnerable` (not dodging in i-frames, not DOWN, not in grace).
2. **Perfect guard:** if the defender's perfect guard is open, the hit becomes a parry. No damage; the attacker is stunned 30 ticks (hero only).
3. **Base:** `full = max(1, round(move.damage × attacker.power) − defender.defense)` (`damage_for`).
4. **Counter:** if the defender is `exposed`, `full × 1.5`.
5. **Critical:** if the attacker has crit chance (the hero) and the hit is not blocked, `rng < crit` gives `full × 1.5`.
6. **Guard:** a blocked hit from the front without guard-break deals `max(1, round(full × 0.2))` and drains energy 1.5 per damage. At 0 energy, guard breaks (40-tick stun).
7. **HP:** `hp −= damage`, never below 0.

**Thrown objects and boss hazards:** `thrown_hit` deals `max(1, damage − defense)`, with guard as above. Hazard damage is `data.damage × boss.power` (`BossMechanics`) [VERIFIED].

**Not present** [VERIFIED by search]:
- Percentage damage reduction.
- Damage caps.
- Random variance (other than crit).
- Armour penetration.
- PvP modifiers.
- Duplicated reductions.

**Picked-up weapons** replace the moveset and add move damage (weapons.json). They do not scale power [VERIFIED].

## 6. Current Defense and Damage Reduction Analysis

Defense is a **flat subtraction per hit with a minimum of 1** [VERIFIED]. Consequences [MEASURED]:

- **Early game.** Ordinary monsters' light hits are 6–18 (×power) through chapters 1–2, against hero defense of 4–9. In Rusted Corner (level 4) an average hit taken is 1–3. A profile B hero there loses about 0.3 HP per second (would last about 13 minutes); profile D loses 0.1 per second.
- **Late game.** Profile D at level 48 has 66 defense. Ordinary monster light hits there average 53 (max 81), so D takes 1 per light hit. Over the Facility and Black Network streets, D takes 0.9–1.2 per second and would last about an hour.
- **Bosses.** Defense subtracts the same flat amount from boss blows. A boss hit of 30 against 23 defense deals 7, while the same hit against 13 defense deals 17: about 2.4× the damage for 10 points of defense. This cliff shape makes small defense differences decisive in the middle and irrelevant at the extremes.
- **Hit rate.** `MAX_ATTACKERS = 2`, with enemy cooldowns of 28–59 ticks, caps how many blows arrive. Even a crowd of 8 lands about as much as 2 enemies [VERIFIED / MEASURED].

## 7. Equipment Grade Analysis

**Grades and budget** [VERIFIED, `ItemRules`]:
- Item budget = `(10 + 2 × level) × slot weight × grade`.
- Slot weights: weapon 1.3, body 0.92, head 0.73, charm 0.75, hands 0.66, feet 0.55.
- Grades: common 0.85, uncommon 1.0, rare 1.15, epic 1.35, legendary 1.6.
- An item's score must be within 15% of its budget, and shops sell only common and uncommon.

**Catalogue** [VERIFIED]:
- 84 items: 5 common, 34 uncommon, 13 rare, 16 epic, 16 legendary.
- By slot: weapon 17, head 14, body 14, hands 14, feet 14, charm 11.
- Every item has fixed stats: no random rolls.

**Drops** [VERIFIED, enemies.json `loot.drops`, `LootRules.roll`]:

| Grade | Where it drops | Chance per kill |
|---|---|---|
| Common | Ordinary enemies | 3–4% |
| Uncommon | 29 entries, mostly ordinary enemies | 4–20% |
| Rare | Only one entry, from an elite | 35% |
| Epic | Story bosses | 20–30% |
| Legendary | Bosses | 6%, with a pity mechanic for some drops |

- Rare gear is otherwise reached only through other sources [UNKNOWN: sources outside drops were not traced item by item].
- **Item level gate:** a hero may wear an item only at or above its level (`equip_problem`) [VERIFIED].

**Impact** [MEASURED]:
- Gear score at level 48: B 528, C (boss weapon and charm, +5) 880, D (+10 best) 1478. A has 236.
- Hero power at level 48: A 4.21, B 5.04, C 6.32, D 7.77. Because level gives +2.35 of that for everyone, gear is only 30–60% of a late hero's power. The level carries the rest.

## 8. Enhancement +0 to +10 Analysis

**Rules** [VERIFIED, `EnhanceRules`, progression.json `enhance`]:
- Each level adds 10% of the item's own positive stats. So +5 is ×1.5 and +10 is ×2.0 of the item's stats.
- Success rates: 100%, 95%, 90%, 80%, 70%, 60%, 50%, 40%, 30%, 20%.
- A failure keeps the item and its level and adds 5% pity to the next try.

**Expected cost per item, pity included** [MEASURED, computed from the table]:

| Target | Expected attempts | Coins | Scrap | Alloy |
|---|---|---|---|---|
| +5 | 5.8 | 753 | 10.9 | 0 |
| +10 | 17.6 | 9,341 | 77.8 | 23.6 |

For 6 slots at +10: about 56,000 coins, 467 scrap and 142 alloy.

**Effect** [MEASURED]:
- Against the final boss, D (+10) takes 6.0 damage per second and B (+0) 10.6 (pre-#73).
- D clears it in 41 s, B in 64 s.
- Enhancement matters in numbers, but the B hero already wins without food, so it is not needed (Problem D).

## 9. Equipment Set Bonus Analysis

**No set system exists** [VERIFIED]: no item has a set field and no code reads one. "Set bonuses" in the brief are a design wish. Any proposal here is new scope [PROPOSED, section 19.5].

## 10. HP and Healing Analysis

**Food** [VERIFIED]:
- Steamed bun 25, ginger tea 50, rice box 120, herbal tonic 220 (prices 10–90).
- Instant heal, 120-tick (2 s) shared cooldown (`skills.json item_cooldown`).
- No limit per fight on pre-#73 code; 6 per boss fight on main, which the owner has asked to remove.
- Auto battle eats below 50% HP and restocks 10.

**Effect** [MEASURED]:
- **Food is the decisive factor for undergeared heroes.** Pre-#73, profile A at the final boss without food lost 4/4. With 10 foods it won 4/4, eating 5 (705 HP of hero, about 1,100 HP healed).
- At Gang HQ, Factory Drains and Sak Tower, A ate 8.5–10 foods per boss, and won.
- **Maximum heal rate:** 110 HP/s with tonics, against measured boss damage of 10–40 per second, so healing can out-pace any boss while food lasts.
- **Food quantity:** carried amount is limited only by coins and the 99-per-purchase cap, so a few hundred coins buys several full health bars [VERIFIED, `ShopRules.MAX_AMOUNT`].
- **Food vs gear cost:** 10 tonics cost 900 coins; enhancing one slot to +5 costs about 753 coins. So food competes directly with gear, and wins.

## 11. Story 1–6 Difficulty Progression Matrix

**Columns:**
- Data at each area's level, pre-#73. Main differs only in Subject Twelve ×1.5 and Director Wiroj ×2.2 power.
- "Mob" means non-boss enemies, elites included. "Light hit" is the move's damage × power before defense.
- "B hits-to-die" is profile B's HP ÷ (hit − B's defense): how many of those hits kill a basic hero. It is a static figure, not counting dodges, guards or food [VERIFIED / MEASURED].

| Ch | Area | Lv | Mobs (elite) | Mob HP avg | Mob power avg | Mob DEF avg | Mob light hit avg/max | Mob heavy max | Mob cooldown (ticks) | Stage boss (Lv) | Boss HP | Boss power | Boss DEF | Boss light/heavy | B: HP / DEF | B hits-to-die (avg mob light) | B hits-to-die (boss light) | D DEF |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 South Street | saltmarket | 2 | 14 (1) | 45 | 1.09 | 0.2 | 6/9 | 23 | 49 | - | - | - | - | -/- | 175 / 4 | 88 | - | 6 |
| 1 South Street | canal_works | 3 | 7 (1) | 58 | 1.19 | 0.3 | 7/10 | 25 | 49 | sludge_foreman (5) | 570 | 1.72 | 2 | 15/38 | 195 / 4 | 65 | 18 | 10 |
| 1 South Street | rusted_corner | 4 | 16 (1) | 54 | 1.25 | 0.1 | 9/10 | 26 | 57 | - | - | - | - | -/- | 220 / 6 | 73 | - | 12 |
| 1 South Street | parking_lot | 5 | 16 (0) | 62 | 1.33 | 0.4 | 9/10 | 23 | 59 | - | - | - | - | -/- | 230 / 6 | 77 | - | 12 |
| 1 South Street | rail_yards | 6 | 15 (0) | 71 | 1.44 | 0.5 | 10/11 | 25 | 49 | - | - | - | - | -/- | 237 / 6 | 59 | - | 12 |
| 1 South Street | night_market | 7 | 17 (3) | 102 | 1.54 | 0.4 | 9/12 | 31 | 41 | - | - | - | - | -/- | 244 / 7 | 122 | - | 10 |
| 1 South Street | fight_club | 8 | 6 (0) | 92 | 1.61 | 0.7 | 10/12 | 27 | 49 | pit_champion (10) | 585 | 1.98 | 3 | 18/40 | 259 / 7 | 86 | 24 | 10 |
| 1 South Street | refinery | 9 | 17 (6) | 147 | 1.79 | 2.4 | 12/14 | 32 | 44 | - | - | - | - | -/- | 269 / 7 | 54 | - | 10 |
| 1 South Street | rat_nest | 10 | 20 (3) | 71 | 1.76 | 1.2 | 11/14 | 36 | 39 | - | - | - | - | -/- | 279 / 7 | 70 | - | 16 |
| 1 South Street | gang_hq | 10 | 8 (4) | 176 | 1.92 | 2.8 | 13/14 | 33 | 43 | furnace_baron (12) | 863 | 2.26 | 4 | 32/63 | 279 / 7 | 46 | 11 | 16 |
| 2 Port District | port_road | 12 | 12 (1) | 186 | 2.11 | 2.6 | 15/16 | 36 | 51 | - | - | - | - | -/- | 320 / 8 | 46 | - | 16 |
| 2 Port District | freight_market | 13 | 17 (7) | 185 | 2.19 | 2.8 | 15/16 | 38 | 44 | - | - | - | - | -/- | 346 / 9 | 58 | - | 18 |
| 2 Port District | container_yard | 15 | 18 (6) | 202 | 2.37 | 2.9 | 17/18 | 41 | 48 | - | - | - | - | -/- | 366 / 9 | 46 | - | 20 |
| 2 Port District | crane_yard | 16 | 8 (3) | 231 | 2.52 | 3.5 | 18/18 | 42 | 46 | harbourmaster_chen (18) | 1212 | 2.36 | 5 | 31/61 | 376 / 9 | 42 | 17 | 20 |
| 3 Industrial | factory_gate | 19 | 12 (7) | 277 | 2.73 | 4.6 | 19/20 | 47 | 41 | - | - | - | - | -/- | 431 / 12 | 62 | - | 24 |
| 3 Industrial | production_line | 21 | 8 (4) | 310 | 2.90 | 4.8 | 23/44 | 50 | 41 | security_chief (23) | 974 | 2.76 | 5 | 19/44 | 435 / 13 | 44 | 72 | 28 |
| 3 Industrial | waste_pools | 23 | 19 (4) | 302 | 3.04 | 4.3 | 29/46 | 56 | 42 | - | - | - | - | -/- | 455 / 13 | 28 | - | 32 |
| 3 Industrial | factory_drains | 24 | 8 (1) | 337 | 3.17 | 4.8 | 33/48 | 58 | 43 | unit_k7 (26) | 1750 | 3.00 | 7 | 42/84 | 465 / 13 | 23 | 16 | 32 |
| 4 Black Network | warehouse_row | 26 | 12 (0) | 274 | 3.07 | 5.4 | 18/23 | 59 | 34 | - | - | - | - | -/- | 540 / 15 | 180 | - | 34 |
| 4 Black Network | underground_ring | 27 | 8 (3) | 323 | 3.21 | 5.6 | 22/30 | 66 | 31 | ringmaster (29) | 1501 | 3.24 | 6 | 32/65 | 550 / 15 | 79 | 32 | 36 |
| 4 Black Network | counting_house | 29 | 12 (1) | 357 | 3.42 | 6.0 | 23/31 | 70 | 36 | - | - | - | - | -/- | 570 / 15 | 71 | - | 36 |
| 4 Black Network | sak_tower | 31 | 7 (1) | 349 | 3.53 | 5.7 | 22/33 | 73 | 30 | big_sak (33) | 1694 | 3.56 | 8 | 39/100 | 590 / 15 | 84 | 25 | 38 |
| 5 Core Facility | facility_gate | 33 | 12 (1) | 474 | 3.91 | 7.8 | 30/60 | 75 | 34 | - | - | - | - | -/- | 625 / 18 | 52 | - | 40 |
| 5 Core Facility | test_labs | 35 | 8 (0) | 579 | 4.32 | 7.2 | 42/56 | 74 | 33 | subject_twelve (37) | 2022 | 3.88 | 7 | 47/93 | 645 / 20 | 29 | 24 | 42 |
| 5 Core Facility | machine_hall | 37 | 12 (6) | 611 | 4.46 | 9.2 | 36/65 | 82 | 31 | - | - | - | - | -/- | 665 / 20 | 42 | - | 42 |
| 5 Core Facility | control_room | 39 | 7 (1) | 618 | 4.57 | 8.3 | 36/61 | 85 | 28 | commander_arthit (41) | 2108 | 4.20 | 9 | 50/118 | 685 / 20 | 43 | 23 | 44 |
| 6 Iron Legacy (finale) | core_approach | 42 | 12 (3) | 618 | 4.80 | 9.1 | 42/73 | 146 | 28 | - | - | - | - | -/- | 755 / 22 | 38 | - | 46 |
| 6 Iron Legacy (finale) | cooling_tunnels | 44 | 12 (0) | 733 | 5.20 | 8.0 | 53/67 | 89 | 29 | - | - | - | - | -/- | 775 / 23 | 26 | - | 46 |
| 6 Iron Legacy (finale) | reactor_walkway | 46 | 12 (7) | 820 | 5.44 | 9.9 | 63/79 | 157 | 30 | - | - | - | - | -/- | 795 / 23 | 20 | - | 48 |
| 6 Iron Legacy (finale) | core_chamber | 48 | 5 (2) | 800 | 5.56 | 10.2 | 53/81 | 163 | 28 | director_wiroj (50) | 3546 | 4.92 | 11 | 59/128 | 900 / 23 | 30 | 25 | 66 |

**What the matrix shows** [MEASURED]:
- **Ordinary monsters stay harmless far into the game.** Hits-to-die for profile B from an average light hit:

  | Chapter | Hits to die |
  |---|---|
  | 1 | 65–90 |
  | 2 | 23–46 |
  | 3 | 23–46 |
  | 4 | 24–75 |
  | 5–6 | 25–44 |

  The early fights are mostly flat defense eating hits; enemies become a threat only in chapter 3.
- **Story bosses do not rise with the story.** Hits-to-die for profile B from a boss's light hit:

  | Boss | Hits to die |
  |---|---|
  | Foreman | 18 |
  | Baron | 11 |
  | Chen | 17 |
  | Security Chief | 72 |
  | K-7 | 16 |
  | Ringmaster | 32 |
  | Big Sak | 25 |
  | Subject Twelve | 24 |
  | Arthit | 23 |
  | Director | 25 |

  The **Furnace Baron** (chapter 1 finale, level 12) is the most dangerous boss per hit in the whole story. The **Security Chief** (level 23) is nearly harmless. The **Director** is no more dangerous than chapter 2's boss.
- **Spikes and dips:**
  - Spikes: Gang HQ (4 elites and the Baron at level 10), Production Line (light hits up to 44 at level 21, double the area before) and the Reactor Walkway (7 elites, heavy hits of 157).
  - Dips: the Security Chief, Warehouse Row (no elites; light hits fall from 33 to 18 after Factory Drains) and Subject Twelve.
- **Recommended level vs area level:** the game shows each area's level as its suggestion (threat colours in `LevelRules.THREATS`). No separate recommended level exists [VERIFIED].
- **Expected gear grade, enhancement and completeness:** not defined anywhere in data [UNKNOWN]. The harness assumes shop gear at level (`ProgressionHarness.gear`). Section 18 proposes them.
- **Expected encounter duration:** measured only at the representative points in section 12. The other 18 areas are [UNKNOWN]. The same script (`_sim.gd`, MODE street) measures them in about a minute each.

## 12. Four Player Profile Simulation

**Pre-#73** (the version the owner played) [MEASURED]. "boss" rows are the stage boss alone (every other encounter pre-cleared). "street" rows are a whole area of ordinary and elite fights. TTK is the fight time; TTD is hero HP ÷ damage taken per second while fighting.

| Encounter | Food | Profile | KO | Fight time s (TTK) | Damage in /s | TTD s | Avg hit taken | Max hit | Invulnerable share | Foods eaten | Hero HP |
|---|---|---|---|---|---|---|---|---|---|---|---|
| boss canal_works | 0 | A | 4/4 | 29 | 12.4 | 12 | 17.7 | 35 | 6% | 3.0 | 150 |
| boss canal_works | 0 | B | 3/4 | 32 | 11.7 | 16 | 17.4 | 35 | 6% | 3.0 | 185 |
| boss canal_works | 0 | C | 2/4 | 35 | 11.3 | 19 | 17.0 | 31 | 8% | 3.0 | 213 |
| boss canal_works | 0 | D | 0/4 | 36 | 6.8 | 34 | 12.3 | 26 | 6% | 2.5 | 227 |
| boss canal_works | 10 | A | 0/4 | 40 | 9.4 | 18 | 17.6 | 35 | 6% | 3.8 | 160 |
| boss canal_works | 10 | B | 0/4 | 40 | 10.1 | 19 | 17.6 | 35 | 6% | 4.2 | 190 |
| boss canal_works | 10 | C | 0/4 | 37 | 9.2 | 24 | 16.1 | 31 | 6% | 3.2 | 213 |
| boss canal_works | 10 | D | 0/4 | 37 | 6.2 | 37 | 12.1 | 26 | 6% | 1.2 | 227 |
| boss gang_hq | 0 | A | 4/4 | 26 | 18.4 | 12 | 24.2 | 46 | 5% | 3.0 | 220 |
| boss gang_hq | 0 | B | 4/4 | 28 | 18.4 | 14 | 23.0 | 57 | 10% | 3.0 | 264 |
| boss gang_hq | 0 | C | 1/4 | 36 | 12.7 | 28 | 20.9 | 54 | 8% | 2.5 | 319 |
| boss gang_hq | 0 | D | 0/4 | 36 | 7.0 | 60 | 15.6 | 41 | 5% | 0.8 | 417 |
| boss gang_hq | 10 | A | 1/4 | 51 | 15.7 | 14 | 27.6 | 56 | 12% | 10.0 | 220 |
| boss gang_hq | 10 | B | 0/4 | 50 | 12.8 | 20 | 23.9 | 57 | 8% | 7.5 | 264 |
| boss gang_hq | 10 | C | 0/4 | 41 | 11.1 | 30 | 21.1 | 54 | 6% | 1.5 | 319 |
| boss gang_hq | 10 | D | 0/4 | 36 | 7.0 | 60 | 15.6 | 41 | 5% | 0.2 | 417 |
| boss crane_yard | 0 | A | 4/4 | 30 | 18.4 | 16 | 26.0 | 57 | 10% | 3.0 | 302 |
| boss crane_yard | 0 | B | 3/4 | 36 | 15.8 | 23 | 25.1 | 51 | 8% | 3.0 | 361 |
| boss crane_yard | 0 | C | 0/4 | 45 | 9.8 | 46 | 19.0 | 46 | 8% | 3.2 | 448 |
| boss crane_yard | 0 | D | 0/4 | 42 | 9.1 | 62 | 16.4 | 45 | 11% | 1.0 | 565 |
| boss crane_yard | 10 | A | 0/4 | 65 | 15.2 | 20 | 29.1 | 60 | 10% | 5.8 | 302 |
| boss crane_yard | 10 | B | 0/4 | 56 | 13.7 | 26 | 27.2 | 56 | 10% | 4.2 | 361 |
| boss crane_yard | 10 | C | 0/4 | 45 | 9.8 | 46 | 19.0 | 46 | 8% | 1.2 | 448 |
| boss crane_yard | 10 | D | 0/4 | 40 | 9.1 | 62 | 16.4 | 45 | 10% | 0.2 | 565 |
| boss production_line | 0 | A | 3/4 | 47 | 13.1 | 28 | 23.0 | 49 | 6% | 3.0 | 370 |
| boss production_line | 0 | B | 0/4 | 42 | 8.6 | 50 | 21.9 | 40 | 4% | 2.5 | 420 |
| boss production_line | 0 | C | 0/4 | 35 | 4.4 | 110 | 12.5 | 18 | 2% | 0.0 | 473 |
| boss production_line | 0 | D | 0/4 | 32 | 2.5 | 229 | 7.6 | 12 | 2% | 0.0 | 565 |
| boss production_line | 10 | A | 0/4 | 60 | 11.3 | 33 | 22.8 | 49 | 6% | 3.2 | 370 |
| boss production_line | 10 | B | 0/4 | 42 | 8.6 | 50 | 21.9 | 40 | 4% | 1.0 | 420 |
| boss production_line | 10 | C | 0/4 | 35 | 4.4 | 110 | 12.5 | 18 | 2% | 0.0 | 473 |
| boss production_line | 10 | D | 0/4 | 32 | 2.5 | 229 | 7.6 | 12 | 2% | 0.0 | 565 |
| boss factory_drains | 0 | A | 4/4 | 36 | 18.1 | 22 | 32.8 | 78 | 8% | 3.0 | 400 |
| boss factory_drains | 0 | B | 3/4 | 42 | 15.9 | 29 | 33.5 | 72 | 12% | 3.0 | 450 |
| boss factory_drains | 0 | C | 0/4 | 48 | 7.8 | 72 | 22.6 | 63 | 10% | 1.8 | 563 |
| boss factory_drains | 0 | D | 0/4 | 47 | 6.8 | 108 | 18.6 | 57 | 10% | 0.0 | 735 |
| boss factory_drains | 10 | A | 0/4 | 81 | 17.2 | 24 | 35.2 | 78 | 10% | 8.2 | 400 |
| boss factory_drains | 10 | B | 0/4 | 67 | 14.7 | 31 | 35.1 | 72 | 12% | 5.5 | 450 |
| boss factory_drains | 10 | C | 0/4 | 47 | 7.3 | 78 | 22.7 | 63 | 10% | 0.5 | 563 |
| boss factory_drains | 10 | D | 0/4 | 47 | 6.8 | 108 | 18.6 | 57 | 10% | 0.0 | 735 |
| boss sak_tower | 0 | A | 4/4 | 34 | 24.5 | 21 | 30.8 | 91 | 14% | 3.2 | 495 |
| boss sak_tower | 0 | B | 1/4 | 54 | 12.2 | 48 | 22.6 | 86 | 10% | 3.2 | 575 |
| boss sak_tower | 0 | C | 0/4 | 40 | 9.3 | 82 | 19.6 | 77 | 8% | 0.8 | 708 |
| boss sak_tower | 0 | D | 0/4 | 37 | 5.2 | 170 | 13.1 | 63 | 6% | 0.0 | 875 |
| boss sak_tower | 10 | A | 0/4 | 79 | 18.4 | 26 | 29.8 | 91 | 11% | 8.5 | 495 |
| boss sak_tower | 10 | B | 0/4 | 62 | 12.8 | 45 | 22.9 | 86 | 10% | 3.0 | 575 |
| boss sak_tower | 10 | C | 0/4 | 40 | 9.2 | 83 | 19.9 | 77 | 6% | 0.2 | 708 |
| boss sak_tower | 10 | D | 0/4 | 37 | 5.2 | 170 | 13.1 | 63 | 6% | 0.0 | 875 |
| boss test_labs | 0 | A | 4/4 | 46 | 19.4 | 30 | 37.6 | 84 | 10% | 3.0 | 535 |
| boss test_labs | 0 | B | 0/4 | 54 | 8.9 | 72 | 25.4 | 74 | 4% | 1.8 | 630 |
| boss test_labs | 0 | C | 0/4 | 44 | 6.0 | 132 | 14.1 | 62 | 6% | 0.0 | 785 |
| boss test_labs | 0 | D | 0/4 | 36 | 3.4 | 268 | 11.0 | 57 | 4% | 0.0 | 895 |
| boss test_labs | 10 | A | 0/4 | 70 | 15.9 | 36 | 37.2 | 85 | 8% | 6.2 | 535 |
| boss test_labs | 10 | B | 0/4 | 50 | 9.3 | 68 | 26.0 | 74 | 4% | 0.8 | 630 |
| boss test_labs | 10 | C | 0/4 | 44 | 6.0 | 132 | 14.1 | 62 | 6% | 0.0 | 785 |
| boss test_labs | 10 | D | 0/4 | 36 | 3.4 | 268 | 11.0 | 57 | 4% | 0.0 | 895 |
| boss control_room | 0 | A | 4/4 | 30 | 33.0 | 18 | 44.2 | 107 | 14% | 3.0 | 600 |
| boss control_room | 0 | B | 3/4 | 44 | 22.5 | 30 | 30.5 | 104 | 11% | 3.2 | 670 |
| boss control_room | 0 | C | 0/4 | 45 | 8.1 | 102 | 19.5 | 85 | 6% | 0.0 | 825 |
| boss control_room | 0 | D | 0/4 | 40 | 7.9 | 119 | 18.3 | 77 | 9% | 0.0 | 935 |
| boss control_room | 10 | A | 0/4 | 73 | 21.7 | 28 | 43.0 | 109 | 9% | 5.0 | 605 |
| boss control_room | 10 | B | 0/4 | 62 | 18.1 | 37 | 31.1 | 101 | 8% | 3.2 | 670 |
| boss control_room | 10 | C | 0/4 | 45 | 8.1 | 102 | 19.5 | 85 | 6% | 0.0 | 825 |
| boss control_room | 10 | D | 0/4 | 40 | 7.9 | 119 | 18.3 | 77 | 9% | 0.0 | 935 |
| boss core_chamber | 0 | A | 4/4 | 74 | 12.3 | 58 | 40.5 | 156 | 10% | 3.0 | 705 |
| boss core_chamber | 0 | B | 0/4 | 64 | 10.6 | 88 | 35.4 | 148 | 10% | 2.2 | 885 |
| boss core_chamber | 0 | C | 0/4 | 47 | 7.6 | 170 | 32.8 | 137 | 8% | 0.0 | 1059 |
| boss core_chamber | 0 | D | 0/4 | 41 | 6.0 | 234 | 19.1 | 105 | 12% | 0.0 | 1375 |
| boss core_chamber | 10 | A | 0/4 | 80 | 19.1 | 37 | 47.7 | 156 | 10% | 5.0 | 705 |
| boss core_chamber | 10 | B | 0/4 | 62 | 10.1 | 90 | 35.1 | 148 | 9% | 1.0 | 885 |
| boss core_chamber | 10 | C | 0/4 | 47 | 7.6 | 170 | 32.8 | 137 | 8% | 0.0 | 1059 |
| boss core_chamber | 10 | D | 0/4 | 41 | 6.0 | 234 | 19.1 | 105 | 12% | 0.0 | 1375 |
| street rusted_corner | 0 | A | 0/2 | 68 | 0.4 | 772 | 2.9 | 4 | 0% | 0.0 | 160 |
| street rusted_corner | 0 | B | 0/2 | 68 | 0.3 | 810 | 1.8 | 4 | 0% | 0.0 | 205 |
| street rusted_corner | 0 | C | 0/2 | 64 | 0.2 | 1690 | 1.1 | 2 | 0% | 0.0 | 235 |
| street rusted_corner | 0 | D | 0/2 | 56 | 0.1 | 1954 | 1.0 | 1 | 0% | 0.0 | 229 |
| street rusted_corner | 10 | A | 0/2 | 68 | 0.4 | 772 | 2.9 | 4 | 0% | 0.0 | 160 |
| street rusted_corner | 10 | B | 0/2 | 68 | 0.3 | 810 | 1.8 | 4 | 0% | 0.0 | 205 |
| street rusted_corner | 10 | C | 0/2 | 64 | 0.2 | 1690 | 1.1 | 2 | 0% | 0.0 | 235 |
| street rusted_corner | 10 | D | 0/2 | 56 | 0.1 | 1954 | 1.0 | 1 | 0% | 0.0 | 229 |
| street container_yard | 0 | A | 0/2 | 122 | 3.2 | 91 | 12.2 | 36 | 4% | 3.5 | 281 |
| street container_yard | 0 | B | 0/2 | 97 | 1.9 | 192 | 9.1 | 27 | 2% | 0.0 | 351 |
| street container_yard | 0 | C | 0/2 | 88 | 1.6 | 286 | 8.4 | 26 | 3% | 0.0 | 438 |
| street container_yard | 0 | D | 0/2 | 84 | 0.7 | 886 | 4.6 | 14 | 4% | 0.0 | 555 |
| street container_yard | 10 | A | 0/2 | 122 | 3.2 | 91 | 12.2 | 36 | 4% | 1.5 | 281 |
| street container_yard | 10 | B | 0/2 | 97 | 1.9 | 192 | 9.1 | 27 | 2% | 0.0 | 351 |
| street container_yard | 10 | C | 0/2 | 88 | 1.6 | 286 | 8.4 | 26 | 3% | 0.0 | 438 |
| street container_yard | 10 | D | 0/2 | 84 | 0.7 | 886 | 4.6 | 14 | 4% | 0.0 | 555 |
| street waste_pools | 0 | A | 0/2 | 142 | 4.0 | 105 | 19.9 | 48 | 4% | 4.5 | 390 |
| street waste_pools | 0 | B | 0/2 | 116 | 2.5 | 182 | 20.0 | 42 | 4% | 0.5 | 440 |
| street waste_pools | 0 | C | 0/2 | 104 | 1.8 | 312 | 13.6 | 35 | 4% | 0.0 | 553 |
| street waste_pools | 0 | D | 0/2 | 89 | 0.2 | 4480 | 3.2 | 11 | 1% | 0.0 | 725 |
| street waste_pools | 10 | A | 0/2 | 141 | 3.8 | 108 | 20.4 | 48 | 4% | 2.5 | 390 |
| street waste_pools | 10 | B | 0/2 | 116 | 2.5 | 182 | 20.0 | 42 | 4% | 0.5 | 440 |
| street waste_pools | 10 | C | 0/2 | 104 | 1.8 | 312 | 13.6 | 35 | 4% | 0.0 | 553 |
| street waste_pools | 10 | D | 0/2 | 89 | 0.2 | 4480 | 3.2 | 11 | 1% | 0.0 | 725 |
| street counting_house | 0 | A | 0/2 | 88 | 6.0 | 82 | 18.0 | 58 | 4% | 4.0 | 475 |
| street counting_house | 0 | B | 0/2 | 67 | 3.3 | 200 | 12.1 | 53 | 3% | 0.0 | 555 |
| street counting_house | 0 | C | 0/2 | 58 | 2.4 | 276 | 8.4 | 44 | 4% | 0.0 | 651 |
| street counting_house | 0 | D | 0/2 | 54 | 0.9 | 3464 | 8.4 | 18 | 4% | 0.0 | 805 |
| street counting_house | 10 | A | 0/2 | 88 | 6.1 | 80 | 18.4 | 58 | 4% | 2.0 | 475 |
| street counting_house | 10 | B | 0/2 | 67 | 3.3 | 200 | 12.1 | 53 | 3% | 0.0 | 555 |
| street counting_house | 10 | C | 0/2 | 58 | 2.4 | 276 | 8.4 | 44 | 4% | 0.0 | 651 |
| street counting_house | 10 | D | 0/2 | 54 | 0.9 | 3464 | 8.4 | 18 | 4% | 0.0 | 805 |
| street machine_hall | 0 | A | 0/2 | 109 | 5.5 | 108 | 22.1 | 71 | 4% | 2.0 | 580 |
| street machine_hall | 0 | B | 0/2 | 98 | 5.5 | 124 | 19.2 | 63 | 6% | 2.0 | 650 |
| street machine_hall | 0 | C | 0/2 | 72 | 2.1 | 474 | 10.0 | 48 | 6% | 0.0 | 805 |
| street machine_hall | 0 | D | 0/2 | 60 | 1.2 | 4712 | 4.8 | 22 | 4% | 0.0 | 915 |
| street machine_hall | 10 | A | 0/2 | 112 | 5.4 | 110 | 21.7 | 71 | 4% | 2.0 | 580 |
| street machine_hall | 10 | B | 0/2 | 97 | 6.2 | 116 | 19.2 | 63 | 7% | 1.0 | 650 |
| street machine_hall | 10 | C | 0/2 | 72 | 2.1 | 474 | 10.0 | 48 | 6% | 0.0 | 805 |
| street machine_hall | 10 | D | 0/2 | 60 | 1.2 | 4712 | 4.8 | 22 | 4% | 0.0 | 915 |
| street reactor_walkway | 0 | A | 2/2 | 57 | 15.2 | 45 | 36.2 | 143 | 11% | 3.0 | 685 |
| street reactor_walkway | 0 | B | 2/2 | 74 | 14.2 | 56 | 40.7 | 135 | 10% | 3.0 | 780 |
| street reactor_walkway | 0 | C | 0/2 | 78 | 9.2 | 105 | 35.8 | 119 | 7% | 1.5 | 966 |
| street reactor_walkway | 0 | D | 0/2 | 66 | 6.5 | 199 | 70.6 | 110 | 8% | 0.0 | 1185 |
| street reactor_walkway | 10 | A | 0/2 | 128 | 16.4 | 44 | 49.6 | 143 | 11% | 7.5 | 695 |
| street reactor_walkway | 10 | B | 0/2 | 102 | 14.8 | 54 | 52.4 | 135 | 12% | 5.0 | 790 |
| street reactor_walkway | 10 | C | 0/2 | 78 | 7.8 | 126 | 32.6 | 119 | 7% | 1.0 | 966 |
| street reactor_walkway | 10 | D | 0/2 | 66 | 6.5 | 199 | 70.6 | 110 | 8% | 0.0 | 1185 |

**Main** (deployed, with PR #73) [MEASURED], same setup:

| Encounter | Food | Profile | KO | Fight time s (TTK) | Damage in /s | TTD s | Avg hit taken | Max hit | Invulnerable share | Foods eaten | Hero HP |
|---|---|---|---|---|---|---|---|---|---|---|---|
| boss gang_hq | 0 | A | 4/4 | 26 | 18.4 | 12 | 24.2 | 46 | 5% | 3.0 | 220 |
| boss gang_hq | 0 | B | 4/4 | 28 | 18.4 | 14 | 23.0 | 57 | 10% | 3.0 | 264 |
| boss gang_hq | 0 | C | 1/4 | 36 | 12.7 | 28 | 20.9 | 54 | 8% | 2.5 | 319 |
| boss gang_hq | 0 | D | 0/4 | 36 | 7.0 | 60 | 15.6 | 41 | 5% | 0.8 | 417 |
| boss gang_hq | 10 | A | 2/4 | 42 | 15.9 | 14 | 26.5 | 56 | 6% | 6.8 | 220 |
| boss gang_hq | 10 | B | 1/4 | 45 | 13.8 | 20 | 24.4 | 57 | 8% | 5.8 | 264 |
| boss gang_hq | 10 | C | 0/4 | 41 | 11.1 | 30 | 21.1 | 54 | 6% | 1.5 | 319 |
| boss gang_hq | 10 | D | 0/4 | 36 | 7.0 | 60 | 15.6 | 41 | 5% | 0.2 | 417 |
| boss production_line | 0 | A | 3/4 | 47 | 13.1 | 28 | 23.0 | 49 | 6% | 3.0 | 370 |
| boss production_line | 0 | B | 0/4 | 42 | 8.6 | 50 | 21.9 | 40 | 4% | 2.5 | 420 |
| boss production_line | 0 | C | 0/4 | 35 | 4.4 | 110 | 12.5 | 18 | 2% | 0.0 | 473 |
| boss production_line | 0 | D | 0/4 | 32 | 2.5 | 229 | 7.6 | 12 | 2% | 0.0 | 565 |
| boss production_line | 10 | A | 0/4 | 60 | 11.3 | 33 | 22.8 | 49 | 6% | 3.2 | 370 |
| boss production_line | 10 | B | 0/4 | 42 | 8.6 | 50 | 21.9 | 40 | 4% | 1.0 | 420 |
| boss production_line | 10 | C | 0/4 | 35 | 4.4 | 110 | 12.5 | 18 | 2% | 0.0 | 473 |
| boss production_line | 10 | D | 0/4 | 32 | 2.5 | 229 | 7.6 | 12 | 2% | 0.0 | 565 |
| boss test_labs | 0 | A | 4/4 | 29 | 33.6 | 16 | 59.5 | 132 | 11% | 3.0 | 535 |
| boss test_labs | 0 | B | 1/4 | 46 | 15.9 | 40 | 44.4 | 122 | 4% | 3.5 | 630 |
| boss test_labs | 0 | C | 0/4 | 44 | 13.8 | 56 | 32.9 | 112 | 6% | 2.5 | 785 |
| boss test_labs | 0 | D | 0/4 | 36 | 10.3 | 88 | 33.8 | 106 | 4% | 0.8 | 895 |
| boss test_labs | 10 | A | 2/4 | 56 | 27.8 | 22 | 59.4 | 132 | 8% | 6.2 | 535 |
| boss test_labs | 10 | B | 0/4 | 52 | 17.3 | 36 | 47.0 | 122 | 4% | 2.5 | 630 |
| boss test_labs | 10 | C | 0/4 | 46 | 13.9 | 56 | 36.2 | 112 | 7% | 1.0 | 785 |
| boss test_labs | 10 | D | 0/4 | 37 | 10.1 | 90 | 34.6 | 106 | 4% | 0.2 | 895 |
| boss control_room | 0 | A | 4/4 | 30 | 33.0 | 18 | 44.2 | 107 | 14% | 3.0 | 600 |
| boss control_room | 0 | B | 3/4 | 44 | 22.5 | 30 | 30.5 | 104 | 11% | 3.2 | 670 |
| boss control_room | 0 | C | 0/4 | 45 | 8.1 | 102 | 19.5 | 85 | 6% | 0.0 | 825 |
| boss control_room | 0 | D | 0/4 | 40 | 7.9 | 119 | 18.3 | 77 | 9% | 0.0 | 935 |
| boss control_room | 10 | A | 0/4 | 73 | 21.7 | 28 | 43.0 | 109 | 9% | 5.0 | 605 |
| boss control_room | 10 | B | 0/4 | 62 | 18.1 | 37 | 31.1 | 101 | 8% | 3.2 | 670 |
| boss control_room | 10 | C | 0/4 | 45 | 8.1 | 102 | 19.5 | 85 | 6% | 0.0 | 825 |
| boss control_room | 10 | D | 0/4 | 40 | 7.9 | 119 | 18.3 | 77 | 9% | 0.0 | 935 |
| boss core_chamber | 0 | A | 4/4 | 30 | 43.0 | 18 | 80.1 | 267 | 8% | 3.0 | 705 |
| boss core_chamber | 0 | B | 3/4 | 50 | 22.0 | 42 | 78.2 | 259 | 8% | 3.0 | 885 |
| boss core_chamber | 0 | C | 2/4 | 46 | 21.6 | 56 | 99.7 | 340 | 8% | 2.2 | 1059 |
| boss core_chamber | 0 | D | 0/4 | 41 | 25.4 | 54 | 80.7 | 308 | 12% | 2.0 | 1375 |
| boss core_chamber | 10 | A | 4/4 | 73 | 32.2 | 22 | 102.5 | 359 | 10% | 6.0 | 705 |
| boss core_chamber | 10 | B | 1/4 | 58 | 39.9 | 22 | 105.8 | 351 | 10% | 6.2 | 885 |
| boss core_chamber | 10 | C | 0/4 | 44 | 19.6 | 58 | 100.5 | 340 | 8% | 1.2 | 1059 |
| boss core_chamber | 10 | D | 0/4 | 39 | 23.5 | 58 | 88.1 | 308 | 12% | 0.8 | 1375 |

**What PR #73 did:**
- The Director's ×2.2 power made the finale dangerous for everyone, D included: D's time to die fell from 234 s to 54 s, and C lost 2 of 4 without food.
- The 6-food cap made A lose the finale 4/4 even with food.
- But the boss's danger for D grew as much as for A. That is the global-multiplier shape Principle 6 warns against.
- The owner has since asked to drop the food cap and the tries limit, and neither is a root fix.

## 13. Ordinary Monster Balance Analysis

[MEASURED, street rows above]
- **A dies to ordinary monsters nowhere before the final chapter.** Even there (Reactor Walkway) A survives once it carries food.
- **Damage taken per second:**

  | Area | B | D |
  |---|---|---|
  | Rusted Corner | 0.3 | 0.1 |
  | Container Yard | 1.9 | 0.7 |
  | Waste Pools | 2.5 | 0.2 |
  | Counting House | 3.3 | 0.9 |
  | Machine Hall | 5.5 | 1.2 |
  | Reactor Walkway | 14.2 | 6.5 |

- **Clear time:** D clears 13–39% faster than B in the streets. Gear changes farming speed a little and survival a lot, but survival was never at risk.
- **Causes:** flat defense against small hits, `MAX_ATTACKERS = 2`, and cooldowns of 28–59 ticks. Ordinary monsters cannot pressure a hero until the last chapter.

## 14. Mini-Boss and Stage-Boss Balance Analysis

- **Mini-bosses:** none exist [VERIFIED].
- **Elites** are tougher kinds placed in waves. Their heavy hits drive most of the damage taken in the street fights (max hits 36–143) [MEASURED].
- **Stage bosses** (pre-#73, no food) [MEASURED]:
  - **A loses every one.**
  - **B** loses the Foreman, Baron, Chen, K-7 and Arthit 3–4 times in 4, Big Sak 1 in 4, and never loses to the Security Chief, Subject Twelve or the Director.
  - **C and D** never lose, except C against the Foreman (2/4) and the Baron (1/4).
  - The difficulty order is therefore Baron > K-7 ≈ Chen ≈ Arthit > Foreman > Big Sak > Director ≈ Subject Twelve > Security Chief. It is not the story order.
- **With food**, every profile wins every boss (A at Gang HQ 3 of 4). So food, not gear, decides story bosses.
- **TTK spread** (pre-#73): A 26–80 s, D 32–47 s. D kills about 1–2× faster than A; the late game is where it is closer to 2×.

## 15. World Boss Balance Analysis

**Data** [VERIFIED, world_boss.json; pool = HP × pool × players, `WorldBossRules.pool`]:

| World boss | Lv | HP per bar | Round pool | Built for | Power | DEF | Light / heavy hit | Window |
|---|---|---|---|---|---|---|---|---|
| tunnel_mother | 32 | 2574 | 108108 | 3 players | 3.48 | 8 | 45 / 90 | open 60 min every 180 |
| iron_colossus | 52 | 4060 | 284200 | 5 players | 5.59 | 12 | 84 / 168 | open 60 min every 360 |
| subject_zero | 55 | 4664 | 652960 | 10 players | 6.38 | 11 | 89 / 192 | open 60 min every 1440 |

**One attempt per profile, pre-#73** [MEASURED, `WorldBossRun`, the hero at the boss's level, unlimited tries]:

| World boss | Food | Profile | Hero | Attempt lasted | Damage dealt | Damage out /s | Damage in /s | Hero HP | Solo minutes of hitting to empty the pool |
|---|---|---|---|---|---|---|---|---|---|
| tunnel_mother (L32) | 0 | A | oren | 31s (down) | 1149 | 36.9 | 19.1 | 520 | 49 |
| tunnel_mother (L32) | 0 | A | mika | 34s (down) | 1397 | 40.8 | 16.5 | 490 | 44 |
| tunnel_mother (L32) | 0 | B | oren | 48s (down) | 2097 | 43.8 | 14.6 | 600 | 41 |
| tunnel_mother (L32) | 0 | B | mika | 43s (down) | 2085 | 48.2 | 15.5 | 570 | 37 |
| tunnel_mother (L32) | 0 | C | oren | 54s (down) | 2963 | 55.3 | 15.1 | 733 | 33 |
| tunnel_mother (L32) | 0 | C | mika | 68s (down) | 4720 | 69.3 | 11.8 | 703 | 26 |
| tunnel_mother (L32) | 0 | D | oren | 181s (down) | 13731 | 76.0 | 6.2 | 900 | 24 |
| tunnel_mother (L32) | 0 | D | mika | 174s (down) | 16720 | 96.2 | 6.2 | 870 | 19 |
| tunnel_mother (L32) | 10 | A | oren | 90s (down) | 3638 | 40.6 | 20.1 | 520 | 44 |
| tunnel_mother (L32) | 10 | A | mika | 94s (down) | 3444 | 36.8 | 18.9 | 490 | 49 |
| tunnel_mother (L32) | 10 | B | oren | 144s (down) | 7129 | 49.4 | 20.3 | 600 | 36 |
| tunnel_mother (L32) | 10 | B | mika | 173s (down) | 10307 | 59.5 | 16.9 | 570 | 30 |
| tunnel_mother (L32) | 10 | C | oren | 222s (down) | 16136 | 72.7 | 13.9 | 733 | 25 |
| tunnel_mother (L32) | 10 | C | mika | 204s (down) | 17214 | 84.4 | 14.9 | 703 | 21 |
| tunnel_mother (L32) | 10 | D | oren | 513s (down) | 45859 | 89.5 | 6.7 | 900 | 20 |
| tunnel_mother (L32) | 10 | D | mika | 447s (down) | 45224 | 101.3 | 7.4 | 870 | 18 |
| iron_colossus (L50) | 0 | A | oren | 24s (down) | 1289 | 54.3 | 34.3 | 740 | 87 |
| iron_colossus (L50) | 0 | A | mika | 20s (down) | 1259 | 63.8 | 39.8 | 710 | 74 |
| iron_colossus (L50) | 0 | B | oren | 35s (down) | 2297 | 65.2 | 28.2 | 920 | 73 |
| iron_colossus (L50) | 0 | B | mika | 24s (down) | 1949 | 79.6 | 39.4 | 890 | 60 |
| iron_colossus (L50) | 0 | C | oren | 40s (down) | 3187 | 80.0 | 29.3 | 1094 | 59 |
| iron_colossus (L50) | 0 | C | mika | 38s (down) | 2522 | 66.9 | 30.2 | 1064 | 71 |
| iron_colossus (L50) | 0 | D | oren | 151s (down) | 14790 | 97.7 | 12.7 | 1490 | 48 |
| iron_colossus (L50) | 0 | D | mika | 144s (down) | 19241 | 133.9 | 11.5 | 1460 | 35 |
| iron_colossus (L50) | 10 | A | oren | 71s (down) | 4504 | 63.5 | 42.5 | 740 | 75 |
| iron_colossus (L50) | 10 | A | mika | 61s (down) | 2554 | 41.8 | 48.0 | 710 | 113 |
| iron_colossus (L50) | 10 | B | oren | 91s (down) | 5399 | 59.3 | 36.4 | 920 | 80 |
| iron_colossus (L50) | 10 | B | mika | 77s (down) | 6110 | 79.3 | 41.1 | 890 | 60 |
| iron_colossus (L50) | 10 | C | oren | 108s (down) | 8924 | 82.4 | 31.1 | 1094 | 58 |
| iron_colossus (L50) | 10 | C | mika | 89s (down) | 8632 | 96.9 | 38.8 | 1064 | 49 |
| iron_colossus (L50) | 10 | D | oren | 380s (down) | 42324 | 111.5 | 12.4 | 1490 | 42 |
| iron_colossus (L50) | 10 | D | mika | 280s (down) | 37648 | 134.2 | 14.2 | 1460 | 35 |
| subject_zero (L50) | 0 | A | oren | 21s (down) | 576 | 26.8 | 37.9 | 740 | 406 |
| subject_zero (L50) | 0 | A | mika | 21s (down) | 602 | 28.2 | 36.7 | 710 | 387 |
| subject_zero (L50) | 0 | B | oren | 24s (down) | 1316 | 55.6 | 42.0 | 920 | 196 |
| subject_zero (L50) | 0 | B | mika | 23s (down) | 1670 | 71.5 | 41.3 | 890 | 152 |
| subject_zero (L50) | 0 | C | oren | 38s (down) | 2870 | 74.9 | 30.5 | 1094 | 145 |
| subject_zero (L50) | 0 | C | mika | 27s (down) | 2080 | 78.2 | 42.8 | 1064 | 139 |
| subject_zero (L50) | 0 | D | oren | 107s (down) | 13682 | 127.5 | 17.9 | 1490 | 85 |
| subject_zero (L50) | 0 | D | mika | 73s (down) | 7251 | 99.0 | 24.2 | 1460 | 110 |
| subject_zero (L50) | 10 | A | oren | 62s (down) | 1889 | 30.4 | 48.5 | 740 | 358 |
| subject_zero (L50) | 10 | A | mika | 62s (down) | 3331 | 53.3 | 47.8 | 710 | 204 |
| subject_zero (L50) | 10 | B | oren | 70s (down) | 3336 | 48.0 | 47.7 | 920 | 227 |
| subject_zero (L50) | 10 | B | mika | 63s (down) | 4550 | 72.5 | 52.3 | 890 | 150 |
| subject_zero (L50) | 10 | C | oren | 88s (down) | 5935 | 67.4 | 41.0 | 1094 | 162 |
| subject_zero (L50) | 10 | C | mika | 77s (down) | 6885 | 89.1 | 44.8 | 1064 | 122 |
| subject_zero (L50) | 10 | D | oren | 273s (down) | 27372 | 100.3 | 16.9 | 1490 | 108 |
| subject_zero (L50) | 10 | D | mika | 194s (down) | 20706 | 106.7 | 21.7 | 1460 | 102 |

**Findings** [MEASURED]:
- **World bosses do kill every profile.**
  - Without food: A within 20–34 s, D within 107–181 s.
  - With 10 foods: A within 61–94 s, D within 194–513 s.
  - So the "survives indefinitely" observation is not reproduced by auto battle. A human who dodges well could do better [UNKNOWN: needs a recorded human session or an input-replay test].
- **The real gap is the cost of falling.**
  - **Tries:** the round keeps all damage and allows unlimited attempts (pre-#73; main allows 3).
  - **Cost of a fall:** 10% of coins and the ride fare.
  - **Damage-rate gap:** A deals 27–64 per second, about 25–60% of D's 76–134.
  - **Result:** a solo A hero would empty the Tunnel Mother's pool, built for 3, in about 44–49 minutes of hitting, inside the 60-minute window. The 5- and 10-player bosses need 74–406 minutes alone, so they cannot fall to one player, as designed.
- **Telegraphs and pressure:**
  - Hazards (warned volleys), phases and a shield exist [VERIFIED].
  - There is no enrage: the boss's pressure does not grow with time [VERIFIED by search].
  - There is no respawn cooldown for re-entry; the taxi fare is the only gate [VERIFIED].
- **Multiplayer:** not implemented [VERIFIED]. Single-player today, "the pool is the hero's own" (`WorldBossRules` header). Server-authoritative damage, player-count scaling, contribution tracking across players, AFK handling and server performance are all [UNKNOWN] until IL-7 exists.
- **Rewards** [VERIFIED, `WorldBossRules.award`]:
  - Only a kill pays. Then each fighter gets the personal tiers their damage reached (shares of one player's part) and the kill reward.
  - Falling before the kill keeps the damage for the round.
  - No minimum contribution is required for the kill reward beyond being in the round's record. An AFK presence deals 0 and reaches no tier, but the code has no player-presence model yet [UNKNOWN for online].

## 16. TTK and TTD Comparison

Summary at the four representative bosses (pre-#73, no food, averaged over Oren and Mika) [MEASURED]:

| Boss | A TTK / TTD | B | C | D | D÷A TTD |
|---|---|---|---|---|---|
| Furnace Baron (Lv 12) | dies at 26 s / 12 s | dies 28 / 14 | 36 / 28 | 36 / 60 | 5.0× |
| Unit K-7 (Lv 26) | dies 36 / 22 | mostly dies 42 / 29 | 48 / 72 | 47 / 108 | 4.9× |
| Commander Arthit (Lv 41) | dies 30 / 18 | mostly dies 44 / 30 | 45 / 102 | 40 / 119 | 6.6× |
| Director Wiroj (Lv 50) | dies 74 / 58 | wins 64 / 88 | 47 / 170 | 41 / 234 | 4.0× |

**Reading it:**
- **Survival without food:** gear separates A from D strongly, 4–7× the time to die.
- **Kill speed:** gear separates them only 1.1–1.8×.
- **With food:** the survival gap disappears for bosses, because A out-eats the damage. Problem D is therefore a food problem first and a damage-output problem second.
- **Hits to kill the hero:** the matrix gives static hits-to-die; the measured average hit and max hit per fight are in section 12.
- **Damage over time:** the only damage over time is hazard areas, part of hazard damage [VERIFIED].

## 17. Root Cause Analysis

1. **Instant, unlimited, fast healing** (`ZoneSim.use_item`, `skills.json item_cooldown = 120`, `FoodRules`) [VERIFIED / MEASURED].
   - Food heals 110 HP/s at most, against boss damage of 10–40 per second.
   - It is cheap and bought in any amount, so health is a currency, not a risk.
   - This alone turns A's 4/4 losses into wins.
2. **Flat defense with a 1-damage floor** (`CombatRules.damage_for`) [VERIFIED / MEASURED].
   - Ordinary enemies' small hits are erased early; very high defense makes late content nearly free (D takes 1 per light hit at level 48).
   - The same 10 points matter enormously in the middle.
   - Defense also has no level growth on the hero, so its value depends entirely on how hard the enemies of that level hit.
3. **Mismatched growth curves and per-boss base stats** (`progression.json per_level`, `LevelRules.HP_PER_LEVEL/POWER_PER_LEVEL`, enemies.json base power) [VERIFIED / MEASURED].
   - Hero HP gains +10 a level plus gear HP: ×5.5 for B and ×7.0 for D from level 1 to 48. Enemy power gains only ×4.9 over levels 1–50, and enemy HP ×3.9 against hero power ×4.4 to ×6.0.
   - Late bosses have base power 1.0 against early bosses' 1.15–1.3, so the threat per hit falls through the story.
   - Hero power gains +0.05 a level for everyone, so level supplies most of a late hero's damage and gear only 30–60%.
4. **Cheap failure** (`Game._recover`, `EconomyRules.defeat_loss`, `WorldBossRules`) [VERIFIED].
   - A knock-out costs 10% of carried coins, and the hero restarts at full HP at the boss.
   - A world boss round keeps every attempt's damage, with no limit on attempts.
   - Persistence can replace preparation everywhere.
5. **Crowd damage cap** (`ZoneSim.MAX_ATTACKERS = 2`, AI cooldowns) [VERIFIED]. Good for readability, but it removes most of the pressure from ordinary fights. Elites carry all the danger.

**The three most important:** 1 (healing), 2 (flat defense), 3 (growth curves and per-boss base stats).

## 18. Recommended Balance Targets

[PROPOSED]
- **Measurement standard:**
  - AutoPilot, no food, against the stage boss at the area's own level.
  - TTD = time to die if never healing.
  - TTK = boss kill time.
  - A healthy design keeps TTD/TTK above 1 for the intended profile, so food and dodging are tools, not crutches.

| Phase | Chapters | Intended profile | TTD target (no food) | TTK target | A (undergeared) should… | D should… |
|---|---|---|---|---|---|---|
| Early | 1 | B | 35–50 s | 30–45 s | win with food and care; lose without | win easily, still take hits |
| Mid | 2–3 | B with some +3 or boss pieces | 30–45 s | 35–50 s | usually lose | win in about 60% of B's time |
| Late | 4–5 | C (+5, boss weapon and charm) | 30–45 s | 35–50 s | lose even with food | TTD about 2.5× C's, never immune |
| Endgame | 6 and world bosses | C to D | 25–40 s (C) | 40–60 s; world boss pool by group | not be able to contribute meaningfully | must still dodge telegraphs: no hit below 15% of its raw damage |

**Ordinary streets:** profile B takes 3–8% of max HP per second while fighting by chapter 3. Elites 2–3× that.

**Gear impact at endgame:** D vs B, about 2× kill speed and about 3× time to die, not more, so +10 is a clear advantage but not a wall (Principle 4).

## 19. Proposed Formula Adjustments

All [PROPOSED]; none built.

1. **Defense as a curve, not a flat cut.**
   - `damage = raw × K / (K + defense_eff)`, with K set per enemy level: for example `K = 20 + 4 × enemy_level`. Then 23 defense against a level-50 boss cuts about 10%, and 66 about 25%.
   - Keep a floor of `max(1, 0.15 × raw)` so no gear makes a hero immune (Principle 3).
   - Raise gear defense values in items.json so a full set's reduction lands at the targets; `ItemRules` budget weights would be re-derived, not hand-edited.
   - Shared change: touches every hit (`CombatRules.damage_for`, `thrown_hit`). Highest-impact single fix.
2. **Healing that does not out-pace bosses, without a count cap** (as the owner asked).
   - Turn food into a heal over 3 s, with a per-food cooldown that grows with the heal: bun 3 s, tea 4 s, rice 6 s, tonic 9 s.
   - Food then restores about 15–25 HP/s at best: a top-up, not invulnerability.
   - Shared change: `ZoneSim.use_item`, `FoodRules`, the hotbar's cooldown display, `AutoPilot` thresholds.
3. **Separate hero growth by source.**
   - Lower `per_level.power` (0.05 → about 0.03) and move that share into gear power budgets, so gear is 50–70% of a late hero's damage instead of 30–60%.
   - Leave `per_level.max_hp` at 10, but let defense come only from gear, as it does now.
4. **Enemy damage curve by role**, not one multiplier.
   - Keep `POWER_PER_LEVEL` and set each boss's base power on a curve by chapter, re-basing the soft bosses: Security Chief, Subject Twelve, Director Wiroj. Main's ×2.2 on the Director should be revisited together with change 1, since with curved defense the multiplier over-punishes D.
   - Give elites a +X% damage role multiplier instead of hand-tuned kinds.
5. **Set bonuses**, if wanted.
   - Add an optional `set` id to items and a `sets` table (2-piece and 4-piece bonuses), scored within the `ItemRules` budget so a set never breaks the grade tolerance.
   - New scope; only after 1–4.
6. **Cost of failure** (story).
   - Keep the knock-out cheap early.
   - From chapter 3, a boss loss could restore the boss's health to full (it already does), and leave the hero at a "Weakened" penalty (−20% HP for 2 minutes) instead of full HP. Requires approval: it is a policy change.

## 20. Proposed Monster and Boss Scaling

[PROPOSED]
- **Stage bosses:** set base power so a boss's light hit against the intended profile's defense meets the TTD target.
  - Concretely: re-base `security_chief` up (about ×2), and recheck `subject_twelve` and `director_wiroj` against the curved defense.
  - Hold the Baron, the chapter 1 finale, as the early peak but bring it to the chapter 1 band.
  - All via enemies.json; measured with `tools`/harness before and after.
- **Elites:** a data field `role_power` (for example 1.2 in chapters 1–2, rising to 1.4 in chapter 6).
- **Ordinary monsters:** shorten AI cooldown scaling a little in chapters 3–6, so the hit rate rises: `quicker` reaches 0.5 at level 40 instead of 42.
- **World bosses** (section 8 of the brief):
  - **Offensive threat:** keep telegraphed hazards; add one heavy area attack per phase that deals 35–50% of a C profile's HP, so it must be dodged.
  - **Enrage:** after 40 minutes of the 60-minute round, boss attack frequency +25% and hazard volley +1, announced on the boss bar 60 s ahead. Fair (warned), and it ends long fights.
  - **Defensive challenge:** with changes 1 and 2, profile A's damage-in to TTD falls to about 10–15 s with food. Contribution needs C or better.
  - **Multiplayer** (IL-7):
    - One shared pool, server-side damage (the sim is already pure and seeded).
    - Pool scaling by the round's peak participants, with diminishing returns (for example pool × participants^0.8).
    - Contribution tracked as damage dealt plus time alive.
    - A 15-s respawn cooldown after a fall.
    - A minimum contribution (for example 0.5% of one player's part) for the kill reward.
    - Do not scale damage with player count.
    - [UNKNOWN] server load: needs a load test of the zone server once it exists.
  - **Rewards:** keep "only the kill pays" and personal tiers. Adding a minimum contribution is a policy change and needs the owner's approval.

## 21. Risk Assessment

| Change | Risk | Why |
|---|---|---|
| Defense curve (19.1) | High | Touches every hit; every boss, street and the farm income tuning shift; all harness baselines move. |
| Healing over time (19.2) | Medium | Changes feel and auto battle; early-game frustration if too slow. |
| Growth split (19.3) | Medium | Saves keep their gear; heroes become weaker until they re-gear; needs a migration message, no save change. |
| Boss re-basing (20) | Low–medium | Data only; local to each boss. |
| Set bonuses (19.5) | Medium | New system; budget validation must include sets. |
| World boss enrage and contribution (20) | Medium | Policy and online behaviour; best designed with IL-7. |

**Already present:**
- PR #73's blunt changes are live (food cap, tries, Director ×2.2).
- Branch commit `15fbb0f` (unmerged) adds a gear-score check that **fails 2 tests**:
  - `test_gear_check.gd` does not parse (`Hud` has no `class_name`).
  - `test_story_auto` fails: a new hero in the starter kit cannot beat the first boss, because the first boss's requirement exceeds a starter score of 14. That breaks Principle 4 at the very start.
- It should not be merged as is.

## 22. Compatibility Assessment

- **Saves:** none of the proposals change the save format, except set bonuses (an optional item field, read with a default) [PROPOSED].
- **Server:** every proposal stays in `client/sim/` and data, so the IL-7 server reuses it unchanged. Healing over time needs a per-fighter timer in the sim (seeded, deterministic).
- **Content validation:** `ContentDB` checks on load must grow with each new field: defense K, role_power, food cooldowns, sets.
- **ZoneSim and Game.gd** sit at the gdlint 1000-line limit [VERIFIED]. New logic must live in helpers: `FoodRules`, `CombatRules`, a new `DefenseRules`.

## 23. Testing and Validation Plan

**Existing tests and how to run them** [VERIFIED]:
- `godot --headless --path client --script res://tests/TestRunner.gd`, about 550 tests.
- Includes `test_harness.gd` (`ProgressionHarness`), `test_food.gd`, `test_world_boss.gd`, `test_zone_sim.gd`, `test_farming_*`.
- CI runs them in GitHub Actions.

**New tests to add with each phase** [PROPOSED]:
- **Damage:**
  - `damage_for` against defense 0, the K threshold and very high defense: floor ≥ 15% of raw.
  - Crit ×1.5, counter ×1.5 and guard ×0.2 ordering preserved.
- **Defense scaling:** reduction at levels 5, 25 and 50 equals the table in section 18 within 2%.
- **HP scaling:** hero HP per level; profiles A–D HP at representative levels within the target bands.
- **Grades:** each grade's budget ratio holds (existing `ItemRules.problems`); D/B damage ratio at level 48 within 1.8–2.2×.
- **Enhancement +0 to +10:** bonus equals 10% × level of each positive stat; cost and pity table unchanged; a +10 item's score is 2× its +0 score.
- **Set bonuses** (if built): 2-piece and 4-piece activation, removal on unequip, budget validation.
- **Healing:** heal-over-time totals equal the food's heal; cooldown per food; AutoPilot eats at the new threshold; no healing while KO.
- **Boss damage:** each stage boss's no-food TTD for the intended profile within the section 18 band (harness assertions, 2 seeds × 2 heroes).
- **Monster scaling across chapters:** hits-to-die for B falls monotonically by chapter (no Security-Chief-style dips).
- **World boss:** contribution per attempt by profile; enrage starts at its time, announced; the round's pool and payout rules (existing tests) unchanged.
- **Multiplayer boss scaling, death and respawn, reward eligibility:** when IL-7 exists; today [UNKNOWN].
- **Regression:**
  - `test_story_auto` (auto plays the story from a new game).
  - Farm income bands (`test_farming_loop`).
  - The tutorial.
  - Full suite green in CI.

## 24. Recommended Implementation Roadmap

[PROPOSED, each phase a separate PR, each measured before and after with the harness]

| Phase | Work | Files | Depends on | Risk | Expected result | Tests | Rollback |
|---|---|---|---|---|---|---|---|
| 0 | Decide on PR #73's live changes and the unmerged branch commit; restore the agreed baseline | enemies.json, progression.json, world_boss.json, FoodRules, ZoneSim | owner | low | A clean baseline to measure from | full suite | revert commits |
| 1 | Defense curve with a floor | CombatRules (`damage_for`, `thrown_hit`), new DefenseRules, progression.json, ContentDB | 0 | high | Defense matters at every level; nobody immune | damage and defense tests; harness bands | data switch `defense_model: "flat"` kept for one release |
| 2 | Healing over time and per-food cooldown; growth split (power per level) | FoodRules, ZoneSim.use_item, Hotbar, AutoPilot, progression.json | 1 | medium | Food tops up; gear supplies most of a late hero's damage | healing tests; AutoPilot; story auto | data values |
| 3 | Gear values re-derived for the new defense and power split | items.json, ItemRules weights | 1, 2 | medium | Grades and +5/+10 produce the section 18 ratios | grade and enhance tests | data revert |
| 4 | Set bonuses (optional) | items.json, ItemRules, PlayerProfile.gear_stats, ContentDB | 3 | medium | Completing a set is worth it | set tests | feature off by data |
| 5 | Re-measure all 30 areas; fix dips and spikes | areas.json waves, enemies.json | 1–3 | low | Monotonic chapter curve | chapter monotonic test | data revert |
| 6 | Stage bosses re-based by curve (Security Chief, Subject Twelve, Director) | enemies.json | 5 | low | Bosses rise with the story | per-boss TTD bands | data revert |
| 7 | World boss threat: dodge-or-die attack, enrage, minimum contribution | BossMechanics, WorldBossRules, world_boss.json; server parts in IL-7 | 1, 2 | medium | World bosses test gear and execution | world boss tests; IL-7 load test | data off |
| 8 | Automated balance validation | tests/harness, new test_balance_bands.gd | all | low | Future content cannot drift | itself | none |

## Missing data needed for reliable decisions

- **Human play:** recorded sessions or input replays of real players at a few bosses. AutoPilot may over- or under-state damage taken compared with humans.
- **The owner's intended targets:** TTD and TTK per chapter, and how much +10 should matter. Section 18 is a proposal.
- **Gear actually owned:** the gear real players own at each chapter (live save statistics from the backend) to set the "expected profile" per chapter.
- **The other 18 areas:** encounter duration and survival (the script is ready).
- **Rare-gear sources** beyond drops, item by item.
- **Online world boss behaviour:** participant counts, contribution distribution and server performance. Needs IL-7.

## Audit change control

- **Gameplay code, data, assets and configuration:** none was changed by this audit.
- **Files written:** only this report.
- **Scripts:** the audit scripts ran in temporary worktrees outside the repository, and were removed afterwards.
