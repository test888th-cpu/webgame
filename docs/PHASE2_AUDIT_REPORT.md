# Phase 2 Completion & Endgame Farming Audit

Branch `claude/level70`. Every number below was measured on this branch with the
headless harness (`docs/HARNESS.md`): auto battle (`AutoPilot`) stands in for a player,
so a person may be faster or slower. Seeds and gear are given with each result.
Gear profiles:

- **S:** no gear at all.
- **B:** best shop gear, +0.
- **C:** best boss gear, +5.
- **D:** best boss gear, +10.

The story ends at level 50. Levels 50-70 are a farming endgame with no story quests, by
design; nothing below treats that as missing.

## A. Repository status

- **Branch:** `claude/level70`.
- **Base:** `main` at `1cd3bdb`, unchanged: it was not modified, merged, deployed or force-pushed.
- **Stack:** the branch carries the approved restore (`b634166`), the sim-purity work
  (`7ebd093`), the levelling harness (`a634156`, `ba02bac`) and Phase 2.
- **Audit start state:** HEAD `cdda038`, clean working tree, identical to the remote.
- **Commits from this audit:**
  - `00d4989` Show world boss prizes, field elites and field monsters as item sources
  - `483ec35` Give the 50-70 grounds three monster roles each, tinted, and recalibrate
  - `027655a` Add the test_endgame_monsters uid
  - `915a1ee` Raise the Spillway Chief's health to x2.5 its story boss
  - `7f55508` Measure farming, bosses and world bosses in depth; test enhancement and auto battle
  - plus this report, the CHANGELOG and the equipment report refresh (see the push).
- **Files added in this audit:**
  - `client/sim/ItemSources.gd`;
  - `client/tests/harness/WorldBossCheck.gd`;
  - `client/tests/unit/test_item_sources.gd`, `test_endgame_monsters.gd`;
  - their `.uid` files;
  - `docs/PHASE2_AUDIT_REPORT.md`.
- **Files modified in this audit:**
  - Data and generator: `client/data/areas.json`, `enemies.json`, `tools/content/level70_content.py`.
  - Code: `client/sim/ContentDB.gd`, `client/scenes/fighter/FighterView.gd`, `flash.gdshader`.
  - Harness: `LevelingSim.gd`, `FarmCheck.gd`, `EnrageCompare.gd`.
  - Tests: `test_farming_grounds.gd`, `test_lairs.gd`, `test_level70_gear.gd`, `test_scenery_light.gd`.
  - Docs: `CHANGELOG.md`, `GAME_DESIGN.md`, `docs/STORY_BIBLE.md`, `docs/HARNESS.md`,
    `docs/EQUIPMENT_AND_ENHANCEMENT_REPORT.md`.
- **Files removed:** none. Against `main`, the whole branch adds 136 files, modifies 51 and removes none.
- **Data checked against `main`:**
  - Items, areas, `boss_fx` and the asset manifest only gain entries; no existing asset was
    changed or regenerated.
  - Existing data changed only where approved before: Wiroj and Twelve power reverts,
    removed attempt limits and food cap (restore branch), the level cap, Core Overflow's
    purpose text, and new market stock entries.

## B. Progression audit

The XP curve is unchanged: `progression.json` `xp.levels`, configurable. Measured with
`LevelingRun` (2 seeds per level point, all grounds at hero levels around them) after
this audit's changes:

| Band | Target | B (shop +0) | C (boss +5) |
|---|---|---|---|
| 1-50, story then farm | about 2-4 h | 2.48 h | 2.36 h |
| 1-50, farming only | | 4.58 h | 4.52 h |
| 50-60 | 25 h | 24.8 h | 28.9 h |
| 60-65 | 25 h | 22.1 h | 24.9 h |
| 65-70 | 40 h | 42.7 h | 35.6 h |
| **50-70** | **about 90 h** | **89.6 h** | **89.4 h** |

The story pass reaches level 45 in 0.73 h with no knock-outs. The band splits move about
±15% between profiles with 2 seeds. The stronger evidence is the 20-seed XP per hour at
each ground's level (section C), which is within 3% of the rates that met the targets
before the rosters changed. So the curve was not touched.

**XP per hour at the ground's level, 20 seeds, shop gear:**

| Ground (level) | XP per hour |
|---|---|
| Core Spillway (43) | 150k |
| Core Overflow (50, 12 seeds) | 204k |
| Coolant Vaults (53) | 158k |
| Reactor Underworks (58) | 167k |
| Foundry Depths (63) | 182k |
| Iron Heart (68) | 216k |

Kills of tougher monsters pay more (the existing threat scale), so 4 levels under, XP per
hour is higher (Iron Heart at 64: 247k).

The level cap is 70. XP keeps counting past 50, level 70 banks nothing, a level 65 save
loads (and a level 70 +10 item survives a save), and farming-only progression from 50 to 70 is measured above (`test_level_cap.gd`,
`test_levels.gd`). The grounds open on the existing boss-defeat chain, with no level gates
and no first-clear step, and every opened ground stays open.

## C. Farming grounds audit

Each session is 5 minutes of auto farming with food restocked on the way home, as auto
battle does. Food is unlimited and auto eats freely, so food per hour shows how much
healing the fights call for; it never limits play. Kill time is seconds per kill, walking
included.

| Ground | Lv | Field (roles) | Elite | XP/h | s/kill | Knock-outs at level (B, C) | 4 under (B, C) | Damage taken/h | Food/h | Coins/h |
|---|---|---|---|---|---|---|---|---|---|---|
| Core Spillway | 43 | Facility Trooper, Hazmat Sprayer (ranged) | Core Sentinel | 150k | 10.8 | 1/20, 1/20 | 3/20, 5/20 | 51-56k | 482-515 | 24-29k |
| Coolant Vaults | 53 | Vault Trooper, Vault Runner (fast), Coolant Drone (heavy) | Vault Warden | 158k | 9.0 | 0/20, 3/20 | 1/12, 0/12 | 52k | 289 | 48k |
| Reactor Underworks | 58 | Tank Crawler (fast), Underworks Brute (heavy), Reactor Tech (ranged) | Reactor Overseer | 167k | 6.5 | 1/20, 0/20 | 0/12, 0/12 | 47-50k | 274-287 | 51k |
| Foundry Depths | 63 | Foundry Hand, Slag Slinger (ranged), Furnace Hauler (heavy) | Foundry Boss | 182k | 9.6 | 2/20, 0/20 | 1/12, 0/12 | 51-59k | 289-324 | 62k |
| Iron Heart | 68 | Heart Guard (fast), Rivet Thrower (ranged), Iron Sentry (heavy) | Heart Keeper | 216k | 10.1 | 1/20, 1/20 | 3/12, 2/12 | 77k | 412-414 | 75k |
| *Core Overflow (existing)* | 50 | | | 204k | 9.4 | 1/12 (B) | | 55k | 309 | 36k |
| *Facility Annex (existing)* | 37 | | | 126k | 10.2 | 2/12 (B) | | 44k | 415 | 25k |

The C column at level for the four new grounds was measured before the XP and coin
recalibration. Fights are identical (same seeds, same combat), so the knock-outs stand.

**Knock-out causes, found and fixed.** Every knock-out on the old two-kind rosters was a
heavy single hit (Iron Sentry 214, Heart Keeper 216, Vault Warden 176) with 3-8 enemies
within reach. The Iron Heart had two heavies (Riot Trooper and Core Sentinel bases), so its
fights dragged (216-226 kills/h against 260-370 elsewhere) and crowds built up.

**The fix.** Each ground now fields three roles and one elite (`test_endgame_monsters.gd`):
- Iron Heart at its level: knock-outs 2/20 → 1/20 and kills/h 216 → 356.
- Per-tier XP and coin factors (in the generator, measured) restore XP/h and set coins/h
  to a smooth ladder after Core Overflow's 36k.
- Food was not touched.

**Not identical copies.** The new monsters reuse existing enemy behaviours, sprites and
movesets, which the existing systems support. Within a ground, no two kinds share sprite,
moveset and AI, and each ground's mix differs. Every 50-70 monster carries its tier's
`tint`, applied in the sprite shader, so it reads as its own kind.

**Drop sources per ground** (full table in `docs/EQUIPMENT_AND_ENHANCEMENT_REPORT.md` §10):
- Field monsters drop the tier's rares (2% each, two slots per kind), Scrap Metal (80%)
  and Refined Alloy (22-31%).
- The champion elite drops all six rares (4%), two epics (1%), Alloy (60%) and Scrap (100%).
- Field elites (5% of spawns) roll the tier's epic body (2%).
- The lair boss drops all six epics (15% each) and always Alloy.
- Measured gear drops: 6-18 pieces per hour.

**Remaining.** A hero 4 levels under the Iron Heart or Core Spillway is knocked out in
about 17-25% of 5-minute sessions, by crowds plus heavy hits. That's comparable to the
existing Facility Annex at its own level, and fair risk for being under-levelled on the
hardest ground. Left as is; watch in play.

## D. Equipment audit

**Totals** (read from the data): 167 equipment items, 84 existing and 83 new.

| | Common | Uncommon | Rare | Epic | Legendary | Mythic | Total |
|---|---|---|---|---|---|---|---|
| All | 5 | 58 | 37 | 42 | 19 | 6 | 167 |
| New | 0 | 24 | 24 | 26 | 3 | 6 | 83 |

| | Weapon | Body | Head | Hands | Feet | Charm |
|---|---|---|---|---|---|---|
| All | 31 | 28 | 28 | 28 | 27 | 25 |
| New | 14 | 14 | 14 | 14 | 13 | 14 |

**New items by level:**
- 42: 2 (Spillway Chief).
- 53, 58, 63 and 68: 18 each (uncommon, rare and epic in all six slots).
- 60: 3 legendaries (Slag Titan).
- 70: 6 mythics (Iron Sovereign).

No slot is missing, and no new slot was added.

**Stat budgets.** `ItemRules.problems` is empty: every item is within its budget for its
level, slot and grade (`test_item_grades`, `test_level70_gear`). Items reuse existing
icons, and every item has a source (`test_item_sources`).

**Step sizes.**
- Each tier's budget rises 7-9% over the last (from 10 + 2·level).
- A grade is a fixed step (uncommon 1.0, rare 1.15, epic 1.35, legendary 1.6, mythic 1.85).
- A level 53 epic (budget ×1.35) is slightly below the level 48 legendaries (×1.6), so story
  legendaries stay useful into the first tier.
- The mythic set is about 40% over a level 68 epic: the long-term chase.

**Gear gaps.** Highest item level available per slot at each hero level, any source / from
a boss:

| Hero Lv | Weapon | Body | Head | Hands | Feet | Charm |
|---|---|---|---|---|---|---|
| 20 | 15 / 15 | 19 / 9 | 19 / 15 | 20 / 7 | 15 / 15 | 8 / 8 |
| 30 | 30 / 30 | 26 / 23 | 30 / 27 | 27 / 21 | 27 / 15 | 30 / 30 |
| 40 | 39 / 39 | 33 / 23 | 33 / 27 | 35 / 35 | 39 / 39 | 35 / 35 |
| 45 | 44 / 39 | 42 / 42 | 42 / 42 | 45 / 45 | 44 / 39 | 45 / 45 |
| 50 | 50 / 50 | 50 / 50 | 48 / 48 | 45 / 45 | 44 / 39 | 48 / 48 |
| 55 | 53 / 53 | 53 / 53 | 53 / 53 | 53 / 53 | 53 / 53 | 53 / 53 |
| 60 | 60 / 60 | 58 / 58 | 58 / 58 | 60 / 60 | 58 / 58 | 60 / 60 |
| 65 | 63 / 63 | 63 / 63 | 63 / 63 | 63 / 63 | 63 / 63 | 63 / 63 |
| 70 | 70 / 70 | 70 / 70 | 70 / 70 | 70 / 70 | 70 / 70 | 70 / 70 |

- **Body and head gap: resolved.** Spillway Chief's level 42 epics close it: boss body gear
  goes 23 → 42 (19 levels) and head 27 → 42 (15), within the 20-level rule.
- **Levels 50-70:** every slot is even.
- **Remaining gaps, all in the original 1-50 items:**
  - charm: no charm of any source between levels 8 and 23;
  - feet: boss gear jumps from 15 to 31;
  - hands: boss gear jumps from 21 to 35;
  - hands and feet stay at 44-45 until 53.

## E. Enhancement audit

- **Cap and rules unchanged:**
  - +10 is the top (`EnhanceRules.max_level` is 10; `next_cost` at +10 is empty);
  - rates run from 100% down to 20%;
  - pity adds 5% per failure;
  - a failure keeps the item and its level, and nothing is destroyed;
  - the materials are still Scrap Metal and Refined Alloy only.
- **Cost bands, verified at the boundaries** (`test_level70_gear`):
  - item level 1-50: base cost;
  - 51-60: ×2 coins, ×1.5 materials;
  - 61-70: ×3 coins, ×2 materials.
  - Coins switch exactly at item levels 51 and 61, and the rate never moves.
  - Material counts round half up, minimum 1.
- **Expected cost of a full six-slot set, +0 to +10, with failures and pity:**
  - item level 61+: 168k coins, 934 Scrap, 283 Alloy;
  - with materials bought at the market: about 281k coins, roughly 4 hours of Iron Heart
    farming within a 40-hour band.
- **The preview matches the result.** The workbench's "Next +N adds" comes from
  `EnhanceRules.bonus_at`, the same function the upgraded item's stats use. The test checks
  every step from +1 to +10.
- **Save and load:** a level 70 item at +10 survives a save, still worn and still at +10.
- **Existing items unchanged:** items at level 50 and below pay exactly the old table.

## F. Boss audit

EnrageCompare, 10 seeds per cell, auto battle, food unlimited. "Lv" is the lair's
suggested level. Times are median seconds to kill the boss.

| Lair boss | Lv | Shop at level / 5 under / 10 under | Boss +10 at level | No gear at level | Knock-outs with gear |
|---|---|---|---|---|---|
| Spillway Chief (×2.5) | 45 | 38 / n.m. / 52 | 25 | won 10/10, 64 s | 0 |
| Commander Arthit, Reinstated | 55 | 51 / 59 / 64 | 37 | won 7/10, 107 s | 0 |
| Subject Twelve, Relapsed | 60 | 46 / 49 / 55 | 31 | won 10/10, 83 s | 0 |
| Unit K-7, Overdriven | 65 | 59 / 58 / 67 | 37 | won 6/10, 107 s | 0 |
| The Wiroj Protocol (×1.3) | 70 | 65 / 70 / 74 | 45 | won 7/10, 106 s | 0 |

n.m. = not measured.

**Per-boss decisions.**
- **Spillway Chief:** fell in 31 s at ×2.0, and a hero with no gear always won. Raised to
  ×2.5: now 38 s at level and 52 s ten under.
- **Subject Twelve, Relapsed:** deals the least damage of the rematches (a gearless hero
  always wins). Raising its power is the kind of change the owner reverted on the story
  Twelve, so it's reported, not changed.
- **The other three:** fall in 46-65 s with shop gear and have readable, telegraphed
  mechanics from their story versions. Left as they are.

**Enrage: does 75 s do anything?** Each cell compares no enrage with 75 s.
- **On-level, geared:** never fires for a hero at level with shop or boss gear (slowest
  such fight 74 s).
- **Under-levelled, shop gear, the longest fights:**
  - Foundry ten under: 2/10;
  - Wiroj Protocol five under: 1/10;
  - Wiroj Protocol ten under: 3/10.
  - No knock-outs in any of these.
- **Stalled fights (no gear, 83-135 s):** fires in nearly every one, and turns slow wins
  into losses against Arthit (7/10 → 0/10), K-7 (6/10 → 1/10) and the Wiroj Protocol
  (7/10 → 3/10).
- **Why not 60 s:** it would fire for on-level shop-geared heroes (Foundry median 59 s,
  Heart 65 s).
- **Why not 90 s:** it would let 83-90 s stalls through.
- **So 75 s stays.** It's the earliest timer that never touches a hero at level in proper
  gear, and the one that pressures stalled fights.
- **Warning and effect:** it warns 10 s ahead (HUD toast), then raises damage ×1.5 and speeds
  hazards and summons 30%. It never ends a fight and never touches food or entries
  (`test_boss_enrage`).

**Lairs.**
- Reached only from the field truck's "Rematches" list; open with their ground on the same
  boss-defeat rule.
- One boss fight that walls the hero in and comes back after every rest.
- Saved state is the usual cleared list; there's no new save data (`test_lairs`).
- A lair is never a farming ground and has no field. Auto battle following the story only
  rides along the street, and its rest loop returns to the area the player started it in,
  so it never enters a lair by itself.
- **Rewards:** all six tier epics at 15% each, guaranteed Refined Alloy and tonic. The
  Spillway Chief drops body and head epics at 20%.

## G. World boss audit

**Shared HP: what exists today.** The game is single-player until the authoritative zone
servers (milestone IL-7) exist.
- A world boss's round has one pool, sized for its `players` (`WorldBossRules.pool`).
- The hero's damage is banked per round on the save, carries across attempts within the
  round, and only the kill pays.
- Several real players hitting one HP pool needs the server. It is not built here, and no
  concurrency or player-count (CCU) claim is made.

**Rules preserved** (guard tests `test_world_boss`, `test_boss_enrage`):
- unlimited entries and attempts;
- no daily limit;
- no wait between attempts;
- the same reward tiers and kill reward;
- the reward rules are unchanged.

**The two new bosses:**
- **The Slag Titan:** Lv 60, 5 players, every 6 h, opens after Twelve, Relapsed. Legendary
  prizes at 5% (full tier) and 15% (kill).
- **The Iron Sovereign:** Lv 70, 10 players, daily, opens after the Wiroj Protocol. Six
  mythics at 3% (full tier) and 9% (kill).
- Both carry a round enrage in the last 20 of the 60 minutes (×1.3 damage).

**Reach for one hero** (WorldBossCheck, 3 seeds, 3-minute samples). Minutes to empty the
pool alone:

| Boss | Players | Shop +0 | Boss +5 | Boss +10 | Round |
|---|---|---|---|---|---|
| Slag Titan | 5 | 57 | 43 | 41 | 60 |
| Iron Sovereign | 10 | 149 | 109 | 97 | 60 |
| Subject Zero (existing) | 10 | 166 | 119 | 99 | 60 |

- The Slag Titan is beatable solo within its round, so its legendaries can drop.
- **A 10-player boss cannot be emptied by one hero in its hour.** That is true of the
  existing Subject Zero and of the new Iron Sovereign, so in the single-player build the
  mythic set cannot drop yet. This comes from the existing world-boss design, not from
  Phase 2. Changing pool sizing or reward eligibility is the owner's decision (section I).
- **If one hero could complete the set:** with 9% per piece per daily kill, the expected
  time is about 27 days for all six pieces (each rolled independently; an approximation).

## H. Tests and CI

**Local, this branch, after every change** (Godot 4.7.2 headless):
- full suite: 603 tests, 603 passed, 0 failed (the runner has no skip state);
- `gdformat --check` and `gdlint`: clean (177 files);
- `tools/ci/check-repo.sh`: passed;
- `tools/assets/test_pipeline.py` (39 tests) and `tools/assets/validate.py`: passed (run
  after the earlier asset changes; this audit changed no assets).

**GitHub Actions:**
- run 196 on `fff63a7`: all 7 jobs green, including the web export and browser smoke test;
- run 197 on `cdda038`: was in progress at the start of this audit;
- the run for this audit's final commit is listed in the final message, kept separate from
  the local results above.

## I. Remaining issues

**High: needs your decision.**
- **Mythic set and other 10-player world-boss prizes can't drop solo.** One hero can't empty
  a 10-player pool within its 60 minutes (section G). This affects the existing Subject
  Zero too. The options all change approved world-boss rules, so I haven't applied any:
  1. Keep it as is until shared multiplayer (IL-7).
  2. While the game is single-player, size the pool for the players actually fighting.
  3. Lengthen the round for the 10-player bosses.
  4. Let full personal-tier damage pay its rolls without a kill.

**Medium:**
- Names and in-story reasons in STORY_BIBLE §5.6 await your approval.
- A hero 4 levels under the Iron Heart or Core Spillway is knocked out in about 17-25% of
  5-minute sessions. Judged fair for now; watch in play.
- The levelling bands use 2 seeds per level point (±15% between profiles). The 50-70 total
  is on target.
- Subject Twelve, Relapsed is the weakest rematch. Left as is because of the earlier
  revert; your call.

**Low:**
- Gaps in the original 1-50 items: no charm from 8 to 23, and feet and hands boss gear
  jumps (section D).
- The four 50-70 grounds share the street kit's `tunnels` theme with seven existing areas.
  They differ by generated palette and the monsters' tint, with no new painted art.

**Optional polish:**
- Unique sprites for the new monsters.
- A set-bonus system for the mythic set. None exists today, and adding one is an
  architecture change that needs your approval; the set works through each item's own
  stats.

**Art, as implemented:**
- All 12 new areas (5 grounds, 5 lairs, 2 arenas) have complete layers from the existing
  asset pipeline:
  - generated sky, far, buildings and ground (`gen_environment.py`);
  - generated props;
  - a street-kit layout made of existing painted pieces (`kit_import.py`).
- That's the same pipeline and quality as the existing areas. It is not new
  production-painted art.
- The manifest changes are purely additive.

Not an issue: no story quests for levels 51-70, by design.

## J. Final recommendation

**Ready for review, with one owner decision pending** (10-player world-boss prizes in the
single-player build).

- Correctness:
  - the 50-70 progression, grounds, unlock chain, items, drops, enhancement, lairs and
    enrage are verified by 603 passing tests and measured with 10-20 seeds per
    configuration;
  - the owner's food and world-boss rules are intact (guard tests).
- Balance:
  - the 50-70 total is 89-90 h against 90;
  - knock-outs at level are 0-3 in 20 sessions;
  - with gear, the lair bosses fall in 25-74 s with no knock-outs;
  - the enrage timer is justified by measurement.
- Merge and deployment wait for your review and approval.
