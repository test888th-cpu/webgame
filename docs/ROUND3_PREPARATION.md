# Round 3 Preparation and Architecture Approval

**Planning only.** This document changes no gameplay code, combat formulas, item data, scenes, assets or backend. Nothing is merged or deployed. Every item in §7 waits for the owner's approval.

**Evidence labels:**

| Label | Meaning |
|---|---|
| [VERIFIED] | Read in the repository |
| [MEASURED] | From runs reported in the audit and in Round 2 |
| [PREDICTED] | Calculated, not run |
| [PROPOSED] | A plan |

**Companion documents:**
- `docs/COMBAT_AND_PROGRESSION_BALANCE_AUDIT.md`
- `docs/RATHENA_RESEARCH_AND_IRON_LEGACY_BLUEPRINT.md` (including Design Validation Round 2)
- `docs/WORLD_OF_CLAUDECRAFT_RESEARCH_AND_IRON_LEGACY_BLUEPRINT.md`

## 1. Current branch and commit status

[VERIFIED, `git log`, 2026-11-09]

| Ref | Commit | Contents |
|---|---|---|
| `main` (deployed) | `1cd3bdb` | Merge of PR #73: food cap of 6 per boss fight, 3 world-boss tries per round, Director Wiroj ×2.2, Subject Twelve ×1.5, apt removed from the API image |
| `claude/festive-curie-v1u8j1` | 5 commits ahead of `main` | See below |

The 5 branch commits, oldest first:

| Commit | Kind | What it is |
|---|---|---|
| `15fbb0f` | **gameplay** | Gear-score check; also removes the food cap and the tries. Unmerged, no PR. **Fails 2 tests** (audit §21). Must stay out of `main`. |
| `e7a119e` | docs | Balance audit |
| `3d69e06` | docs | rAthena blueprint |
| `a05260b` | docs | Design Validation Round 2 |
| `7c870b9` | docs | World of ClaudeCraft blueprint |

**PR #73 is already merged** (into `main` at `1cd3bdb`, before the audit began). It cannot be held back; restoring the owner's rules needs a new change on top of `main` (§2.1).

**Keeping `15fbb0f` out of `main`** [PROPOSED]. Any PR opened from this branch would carry it. Two options, both needing approval:
- **(a)** Add a `git revert 15fbb0f` commit on this branch (no history rewrite; the docs commits stay). Recommended.
- **(b)** Open docs-only PRs from a branch that cherry-picks the four documentation commits onto `main`.

## 2. Proposed file changes

None of these is made yet.

### 2.1 Restore unlimited food and unlimited world-boss entries

Precise inverse of PR #73 items 1 and 2 (rAthena blueprint §V6). This is the same set of hunks that `15fbb0f` reverts, **without** its gear-check parts.

| File | Change |
|---|---|
| `client/data/progression.json` | Remove `"boss_fight_food": 6` |
| `client/sim/ContentDB.gd` | Remove the `boss_fight_food` validation line; remove `"attempts"` from the world-boss number fields |
| `client/sim/FoodRules.gd` | Remove `boss_food_left` and `why_not` |
| `client/sim/ZoneSim.gd` | Remove `var boss_food` and its counter line. `use_item` goes back to `if item_cooldown > 0 or hero.is_ko(): return false` with its two-line doc comment, keeping the file within its 1000-line limit |
| `client/sim/AutoPilot.gd` | `_pick_heal` goes back to `if zone.item_cooldown > 0 or share >= heal_below:` |
| `client/scenes/game/Game.gd` | Quick-heal and bag messages go back to `"Nothing to eat"` and `"No effect right now"` |
| `client/scenes/ui/Hotbar.gd` | The item slot's third `set_state` argument goes back to `false` |
| `client/data/world_boss.json` | Remove `"attempts": 3` from all three bosses |
| `client/sim/WorldBossRules.gd` | Remove `attempts_left`, `begin_attempt`, the "No tries left" branch in `problem`, the tries paragraph in the header comment, and `"attempts"` in `progress` |
| `client/sim/WorldBossRun.gd` | Remove the `begin_attempt` call |
| `client/sim/PlayerProfile.gd` | Remove the `"attempts"` field when loading world-boss state. Saves that carry it load fine: unknown fields are dropped |
| `client/scenes/game/GameMenus.gd` | Remove the "tries left" text from the world-boss list and Win's ride |
| `README.md` | "Eat (quick heal; 6 per boss fight)" → "Eat (quick heal)" |
| `client/tests/unit/test_food.gd` | Remove `test_a_boss_fight_allows_only_a_few_foods` and `test_food_cannot_stand_in_for_gear_against_the_final_boss` |
| `client/tests/unit/test_world_boss.gd` | Remove `test_a_round_allows_a_few_tries`; drop `"attempts"` from `test_the_round_is_saved` |
| **New guard tests** | `test_food.gd`: food is never limited per fight, the 2 s shared cooldown and heal amounts are unchanged. `test_world_boss.gd`: entries stay open all round after any number of falls, with no waiting between attempts |
| `CHANGELOG.md` | Entry for the restoration |

**Kept:** `ProgressionHarness.gear(..., "starter")` (test tooling only) and the Dockerfile apt fix.

### 2.2 Director Wiroj ×2.2 and Subject Twelve ×1.5, evaluated separately

[MEASURED, audit §12 and §16; main includes the food cap, so the "with food" numbers on main are confounded]

**No food, average over Oren and Mika.** "Time to die" is HP ÷ damage taken per second, in seconds.

| Boss | Version | A: KO / time to die | B | C | D |
|---|---|---|---|---|---|
| Director Wiroj | before #73 | 4/4 / 58 | 0/4 / 88 | 0/4 / 170 | 0/4 / 234 |
| Director Wiroj | main (×2.2) | 4/4 / 18 | 3/4 / 42 | 2/4 / 56 | 0/4 / 54 |
| Subject Twelve | before #73 | 4/4 / 30 | 0/4 / 72 | 0/4 / 132 | 0/4 / 268 |
| Subject Twelve | main (×1.5) | 4/4 / 16 | 1/4 / 40 | 0/4 / 56 | 0/4 / 88 |

**Director ×2.2:**
- Its strongest effect is on the best-geared hero: D's time to die falls 4.3×, B's 2.1×. Gear matters less, the opposite of the goal.
- It is the global-multiplier shape the owner has not approved.
- **Recommendation:** revert it, and replace it with hybrid-T plus the per-attack heavy re-base (Round 2 §V3.3) after Round 3 measures them.

**Subject Twelve ×1.5:**
- It did fix a real soft spot: B's time to die went from 72 s, well outside the 30–45 s band of neighbouring bosses, to 40 s.
- But it also cut D's from 268 s to 88 s, and it is the same multiplier shape.
- **Options:**
  - **(a)** Revert with the Director, accepting the soft spot until the re-base (recommended, consistent with the owner's rule).
  - **(b)** Keep it temporarily, documented as provisional, and replace it in Round 3.

The values in `client/data/enemies.json` on `main`:

| Boss | Base power | Phase power |
|---|---|---|
| `subject_twelve` | 1.5 (was 1.0) | 1.65 (was 1.1) |
| `director_wiroj` | 2.2 (was 1.0) | 2.31 and 2.53 (were 1.05 and 1.15) |

### 2.3 Phase 1: sim purity and local guides

Exact files, no gameplay change.

| File | Status | Content |
|---|---|---|
| `client/tests/unit/test_sim_purity.gd` | new | Scans every `client/sim/*.gd` (comments ignored) and fails on: `extends Node`/`Control`/`CanvasItem`/`Node2D`; the `Input` singleton (word-bounded, so `FighterInput` passes); `get_tree`, `get_node`; `Engine.`, `OS.`, `Time.`, `DisplayServer`, `RenderingServer`; `res://scenes` (load or preload); scene autoloads (`GameSession`, `Sfx`, `UiKit`, `UiTheme`); `randomize()`; global `randf()`/`randi()`/`randf_range()`/`randi_range()` (not called on an RNG object); `RandomNumberGenerator.new()` in a file that never sets `.seed`; `FileAccess`/`DirAccess`/`ResourceLoader`/`HTTPRequest`/`JavaScriptBridge` outside an explicit allowlist. A second test feeds each rule a forbidden sample, so the ban provably fires. |
| `client/sim/CLAUDE.md` | new | The rules above; determinism (60 ticks/s, injected seeds, time passed in); state stays plain data; the 1000-line limit means extract, not append; tests for every rule |
| `client/scenes/CLAUDE.md` | new | Presentation reads the zone and profile and calls `sim/`, never re-implements rules; HUD parts as pure view-cores where practical; the gameplay-neutral settings rule |
| `client/data/CLAUDE.md` | new | JSON is canonical; `ContentDB` validates on load; content obligations (icon, art, intent, tests) |
| `client/tests/CLAUDE.md` | new | Test layout; seeds; the harness and scenario conventions; "report only what ran" |
| `backend/CLAUDE.md` | new | The only writer of durable state; parameterised SQL; migrations never edited; grant IDs and transactions |
| `tools/CLAUDE.md` | new | Asset pipeline, provenance, web smoke probe kept read-only |

**Allowlist** (the only current exceptions, VERIFIED by scanning all 38 `client/sim/*.gd`):

| File | Allowed use |
|---|---|
| `client/sim/ContentDB.gd` | `FileAccess` (line 981, loading data JSON) |
| `client/sim/MoveLibrary.gd` | `FileAccess` (line 27, loading moves JSON) |
| `client/sim/ZoneSim.gd` | `RandomNumberGenerator.new()` (line 49), seeded at line 119 |

No other match exists today, so the test passes on the current code.

**CI compatibility** [VERIFIED]:
- `client/tests/TestRunner.gd` discovers `tests/unit/test_*.gd` automatically, so no workflow change is needed.
- The new `.gd` file must pass gdformat and gdlint (line length 100). `CLAUDE.md` files are not linted.
- **Root `CLAUDE.md` is not edited in Phase 1.** Pointing it to the local guides is a repository-instruction change, listed separately in §7.

## 3. Architecture risks

| Risk | Detail | Mitigation |
|---|---|---|
| Tick rate | Rules at 60 ticks/s, snapshots at 20 Hz: the server runs 3 sim ticks per snapshot. CPU is 3× a 20 Hz server for the same rules | Measure first (§3.1); the rules' cost is 0.30 ms per tick natively for 1 hero and 10 enemies (PERFORMANCE.md) |
| File-size limits | `ZoneSim.gd` (999) and `Game.gd` (999) at the lint limit | All new logic in helpers |
| Purity-test false positives | A rule could flag legitimate code later | Allowlist by exact file, reviewed in PRs; the self-test keeps rules honest |
| Seam drift (Phase 2) | Scenes read `ZoneSim` directly today | `ZoneView` and a parity test, later and with approval |
| Level 51–70 | No content exists past level 50 (§4.1) | Owner decision before content work |

### 3.1 Networking decision under evaluation

[PROPOSED; nothing implemented]

**Rules:**
- **Simulation:** `client/sim/` at 60 ticks/s on the server and in client prediction, identical code. Deterministic given inputs, seeds and the injected time (`now`). Never reads the renderer, the wall clock or a global RNG (enforced by Phase 1).
- **Snapshots:** 20 Hz in combat zones, 10 Hz in hubs (NETWORKING.md). Each carries the server tick and the last processed input `seq`.

**Inputs:**
- The client samples input every tick (60/s) and sends a packet every 3 ticks (20/s) holding those 3 inputs.
- Each packet also carries the previous packet's inputs, so a single lost packet costs nothing.
- The server applies each input at its tick; inputs arriving late are applied on the next tick, never retroactively.

**Local hero:** reconciliation.
- The client predicts with the same rules.
- On each snapshot it resets the hero to the authoritative state at `last processed seq`, then replays the unacknowledged inputs.
- Small corrections are smoothed over about 100 ms; large ones snap.

**Remote entities:** interpolation.
- Drawn about 100 ms (2 snapshots) behind, between the two snapshots that bracket the render time.
- Extrapolation is capped at 1 snapshot when a packet is late.

**Server-authoritative:**
- Hits, damage, KO, loot, XP, quest credit, coins, food use, cooldowns, world-boss pool and damage, enhancement results.
- Clients play attack animations immediately as cosmetic prediction but never show a hit result before the server confirms it (NETWORKING.md: no lag-compensated rewind for PvE).

**Server responsibilities:**
- **Input:** validation (rate, bounds, state), the 60 Hz loop, interest management (grid), snapshot encoding.
- **Persistence:** grant requests to the API (unique ID, one transaction), checkpointing every 60 s and on exit.
- **Robustness:** backpressure, so a slow client is cut off before it stalls the loop.

**Measure before committing:** server CPU per instance at 60 ticks/s with 1, 5 and 24 heroes (PERFORMANCE.md S0); snapshot size at 20 Hz.

## 4. Level 1–70 simulation test plan

[PROPOSED]

### 4.1 What exists

[VERIFIED]
- **Level cap:** 50 (`progression.json` `max_level`).
- **Content stops before 70:** areas run to level 48, world bosses to 52 and 55, and items to level 50.
- **The code itself has no 50 limit:** `LevelRules.enemy_stats` and `PlayerProfile.stats` accept any level. So levels 51–70 can be simulated, but only with **synthetic** enemies (existing kinds scaled by `LevelRules`) and **synthetic** gear (test fixtures built from the `ItemRules` budget at levels 51–70).
- **Synthetic results are extrapolations, not the game.** They become real only if the owner raises the cap and adds content.

**What happens past 50 without new gear** [PREDICTED from `LevelRules` and `progression.json`]:

| From level 50 to 70 | Change |
|---|---|
| Enemy power (×(1+0.08·steps)) | 4.92 → 6.68 (+36%) |
| Enemy HP (×(1+0.06·steps)) | 3.94 → 5.26 (+34%) |
| Hero HP from levels only | +200, about +15% for profile D |
| Hero power from levels only | +1.0, about +13% for D |

So a level 51–70 bracket on level-50 gear gets about 20% harder every 10 levels. The finding to carry into the design: **a level 70 cap needs gear tiers for 51–70**, or the curve breaks.

### 4.2 Matrix

| Axis | Values |
|---|---|
| Level brackets | 1–10, 11–20, 21–30, 31–40, 41–50 (real content); 51–60, 61–70 (synthetic) |
| Defense models | current (baseline), hybrid-T (K = 30 + 2L, floors 20% / 45%, flat 0.1) |
| Profiles | A (undergeared), B (shop +0), B5, B10, C (boss weapon and charm +5), D (best +10); plus single-slot removal and upgrade at one level per bracket |
| Encounters per bracket | The bracket's stage bosses (all 11 are in brackets 1–5), one street with elites; brackets 6–7 use synthetic encounters built from existing kinds at the bracket's level |
| World bosses | All three at their levels; for 51–70, the Colossus and Subject Zero re-levelled (synthetic) |
| Skill | Skilled (auto battle as shipped), unskilled (dodge and guard presses removed) |
| Food | None; 10 (the auto restock); 99 (unlimited stock). Eaten exactly as the game does (below 50% HP, 2 s shared cooldown, heal amounts unchanged) |
| Heavy-attack scale | 1.0 and the proposed 1.6 on late bosses' heavy moves (test-only switch) |
| Seeds | 4 per cell in the first pass; 8 for any cell within 20% of a target |

**Owner-rule guards**, run as assertions before every batch:
- Food heal amounts and the 120-tick cooldown equal the shipped data.
- No per-fight food limit exists.
- World-boss entries are accepted after any number of falls in a round, with no waiting time.
- No food-effectiveness modifier exists in the damage pipeline.

**World-boss unlimited-entry runs:** repeated attempts within one round until the pool falls or the 60 minutes end. Ride-back time is counted as the taxi gives it, with no extra cooldown. Reported: attempts, minutes to kill solo, damage share per profile.

**Metrics:**
- Per fight: KO; fight time (TTK); damage taken and dealt per second; time to die; worst 2-second burst against half HP.
- Heavy attacks started and landed; dodges; knockdowns; time stunned; foods eaten; drops.
- Per bracket: power, HP and DEF decomposition (level, base gear, grade, enhancement, slot).

**Heavy-attack dodgeability** (data check, no run needed):
- Every heavy move needs a wind-up of at least 24 ticks, an active window of at most 12 ticks (or a reach the dodge clears) and recovery of at least 30.
- Hazard warnings must be at least 50 ticks.
- The four moves failing today are listed (Round 2 §V3.1).

### 4.3 How it runs

- **Where:** a scratch worktree of the agreed baseline (main with §2.1 applied). The test-only switches are a patch kept out of the repository, as in Round 2 §V11.
- **Runtime estimate** [PREDICTED from Round 2: about 500 fights in 25 minutes on 4 cores]: about 4,000 fights in the first pass, so roughly 3–4 hours. Borderline cells add about 1–2 hours.
- **Output:** tables like Round 2, appended to the rAthena blueprint as "Design Validation Round 3".
- **Balance values are not finalised until the level 70 brackets are done.**

## 5. Combat balance findings so far

[MEASURED unless marked]
1. **Food (as shipped, unlimited) carries undergeared heroes** through every story boss. No defense formula changes that alone (Round 2 §V1.3).
2. **Flat defense makes heavily geared heroes immune to ordinary hits** (1 damage); hybrid-T removes the immunity at every stage.
3. **Shop gear needs upgrading against the final boss:** with hybrid-T and no food, shop +0 loses there and +5 wins.
4. **Grade is the weakest gear lever** (7% of a level-48 hero's power); level gives 30% and enhancement 28%. Every slot matters in a boss fight.
5. **Bosses' bursts do not beat the food timing today:** an undergeared hero's worst 2 s at the Director is 0.45–0.67 of half HP.
   - Making that matter needs late bosses' heavy attacks about 1.6× stronger [PREDICTED], together with dodgeability rules.
6. **Auto-battle-level skill is worth about one gear tier.** Raising the attacker cap to 3 adds little and mostly punishes unskilled play.
7. **World bosses already kill every profile per attempt.** Unlimited entries let persistence win the 3-player boss solo in about 45 minutes; the enrage (Round 2 §V5) keeps entries unlimited and adds risk over time.
8. **Past level 50 the curve breaks without new gear** [PREDICTED, §4.1].

## 6. CI and regression test plan

**Existing CI** (`.github/workflows/ci.yml`, `assets.yml`, `security.yml`, `pages.yml`):
- gdformat and gdlint.
- Godot import and the headless suite (about 550 tests).
- Backend typecheck, tests and migrations.
- Asset pipeline, gitleaks, Trivy, npm audit, dependency review, web smoke.

**Per change:**

| Change | Tests | Gates |
|---|---|---|
| §2.1 restore rules | Remove the 3 tests encoding the caps; add the 2 owner-rule guards; full suite | gdformat, gdlint, suite green, CI green |
| §2.2 multipliers | `test_harness` and `test_story_auto` re-run; no new caps | same |
| §2.3 Phase 1 | `test_sim_purity.gd` passes on today's code and fails on its samples; full suite | same, with no other diff |
| Round 3 sims | Not in CI (hours long). Optional later: a manual `workflow_dispatch` job (needs approval) | — |

**Regression watch list:**
- Story auto from a new game (`test_story_auto`).
- Farm income bands (`test_farming_loop`).
- The world-boss round and save (`test_world_boss`).
- Food choice (`test_food`).
- Seed replay (`test_harness`).
- The web smoke probe.

## 7. Changes requiring further approval

Nothing below is started.

1. **Restore unlimited food and world-boss entries on `main`** (§2.1). A new PR from a branch based on `main`.
2. **Director Wiroj ×2.2:** revert (recommended) or keep (§2.2).
3. **Subject Twelve ×1.5:** revert now (recommended) or keep provisionally (§2.2).
4. **Keep `15fbb0f` out of `main`:** option (a) revert it on this branch (recommended) or (b) docs-only cherry-pick branch (§1).
5. **Phase 1:** the files in §2.3 exactly.
6. **Root `CLAUDE.md`:** a pointer to the local guides (repository instructions).
7. **Run the level 1–70 plan** (§4). Then a decision on whether the level cap goes to 70, which requires gear tiers and content for 51–70.
8. **Networking decision** (§3.1): approve 60 ticks/s rules with 20 Hz snapshots, before IL-7 work and before editing NETWORKING.md's "20 Hz simulation" line.
9. **Combat design** (hybrid-T, the power split, the grade spread, the heavy re-base, the enrage, keeping 2 attackers): only after Round 3 results.
