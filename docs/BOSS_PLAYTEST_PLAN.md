# Boss Playtest Plan

Reproducible scenarios for the 24 boss Ultimates (`docs/BOSS_SKILL_QUALITY_AUDIT.md`).
There are two kinds:

- **Scripted simulation, done.** A scripted hero in the real rules (`client/sim/`),
  headless. It shows what the rules allow. It cannot show how a person sees, reads or
  feels a fight.
- **Human playtesting, NOT done.** Nobody has played these fights for this work. The
  checklist below is for people to run in a browser build. Until then, nothing here is a
  claim about how the fights play for players.

Multiplayer is not covered at all. The game is single-player until milestone IL-7, and
nothing here validates several heroes, latency between clients, or server authority.

## How to rerun the scripted scenarios

```
godot --headless --path client --script res://tests/harness/BossPlaytestScenarios.gd
BOSSES=crucible_king,founders_engine PARTS=move godot --headless --path client \
  --script res://tests/harness/BossPlaytestScenarios.gd
```

Switches:
- `HERO=` plays one hero, and so one job: its own health, defence and walking speed.
- `VARIANTS=` runs only some movement variants.

Jobs against bosses under auto battle:
```
godot --headless --path client --script res://tests/harness/BossJobMatrix.gd
```
It takes `BOSSES=`, `HEROES=`, `SEEDS=`, `KIT=`, `PLUS=`, `FOOD=`, and `NO_SKILLS=1` for
the control. Results are in the audit's "Integration with the five jobs".

After the owner-approved P-3, the Grappler walks out of every Ultimate in the scripted
runs. The per-boss tables above predate P-3 for Subject Zero, Founder's Engine and
Floodgate Marshal; the current figures are in the audit's "Ultimates per job".

For human playtests, run every boss with each of the five jobs, starting with:
- the Grappler, the slowest walker (Subject Zero, Floodgate Marshal, Founder's Engine);
- the Counter Fighter, to see whether its stance answers telegraphed boss blows.

The harness is read-only and deterministic (fixed zone seed 5; no randomness in the
hero's script). A full run of all 24 bosses takes about 4 to 10 minutes on one core. It
prints one JSON line per result: `POWER`, `MOVE` and `LIFE`.

Loading it logs a harmless "Identifier not found: GameSession" error: a `--script`
harness has no autoloads, and `ProgressionHarness` pulls in `AutoBattle`. The existing
`BossSkillAudit` harness shows the same, and the run is unaffected.

## Scenario parameters (scripted)

| Parameter | Values | Notes |
|---|---|---|
| Start position | gap 50 px (lane -30 and +30), 150 px (lane 0), 250 px (lane -30 and +30) | Hero to boss along the street; lane is depth from the road line. The unit test `test_boss_ultimates` uses 9 starts (50, 150, 250 × -30, 0, +30). |
| Movement | the planner walks to the nearest ground clear of the next wave that it can reach in time, preferring ground clear of the wave after | Steps across the street every 12, 8 or 4 px. The best of the three counts, as a player can choose. |
| Hero speed | 1.0 (default hero, measured 2.32 px/tick along, 1.35 across), 0.8 (slowest hero), 0.64 (slowest hero with the slowest pickup weapon, the chair) | Set on the sim hero; the planner's pace scales with it. |
| Reaction | 15 ticks (0.25 s) after each wave is marked | The same as every fairness test. |
| Frame rate | 30, 60, 120 FPS | The sim runs at a fixed 60 ticks a second in `_physics_process`. At 30 FPS Godot runs two physics steps per frame on the same input, so input is held for two ticks and a press counts once. At 120 FPS the input is still read 60 times a second, so it is identical to 60 by construction; it is run anyway as a check. |
| Input latency | 0, 6 (100 ms), 12 (200 ms) ticks | Input queued that long before the sim sees it. The planner budgets for the delay, as a player used to their lag would. |
| Dodge | walk only; walk plus a timed roll | The roll is pressed so that its invulnerable ticks (2 to 13) cover the landing of a wave the hero still stands in. |
| Combined worst case | 0.8 speed, 30 FPS, 100 ms, roll; 0.64 speed with roll; 200 ms with roll | |

The lifecycle scenarios (`LIFE`), per boss:

- **Repeated Ultimates:** a 100-second fight with the boss held at 14% health, so every
  phase is reached, and the hero pacing. Records each cast, the shortest gap between two
  casts, any hazard *called* while one is channelled, and any earlier hazard still
  waiting beside a wave.
- **Hero death mid-Ultimate:** the hero at 1 HP stands in the first wave.
- **Boss death mid-Ultimate:** the hero's blows finish the boss just after the first
  wave is marked.
- **World boss escape mid-Ultimate** (the 8 world bosses): `WorldBossRun`'s hour runs
  out just after the first wave is marked.
- **Hazard overlap before:** a 3-tile hazard is called just before the cast. Its last
  drop must land before the Ultimate's first wave is marked.

## Results (scripted simulation, this round)

### Per boss

| # | Boss | Tier, level | Ultimate | Waves (kinds) | Scripted: base spare (ticks) | Scripted: walking fails in | Worst one wave, B0 kit (base → phase+enrage) | Human focus |
|---|---|---|---|---|---|---|---|---|
| 1 | The Sludge Foreman (`sludge_foreman`) | mini, 5 | Sludge Geyser Field (`MB_SLUDGE_FOREMAN_ULT_001`) | 1 (sludge) | 65 | none | 20% → 24% | general |
| 2 | The Furnace Baron (`furnace_baron`) | stage, 12 | Furnace Eruption (`SB_FURNACE_BARON_ULT_001`) | 1 (steam) | 73 | none | 26% → 29% | general |
| 3 | The Pit Champion (`pit_champion`) | mini, 10 | Ring Collapse (`MB_PIT_CHAMPION_ULT_001`) | 1 (quake) | 82 | lag200ms | 20% → 22% | roll under lag/slow kit |
| 4 | Harbourmaster Chen (`harbourmaster_chen`) | stage, 18 | Cargo Avalanche (`SB_HARBOURMASTER_CHEN_ULT_001`) | 2 (crane + crane) | 16 | none | 19% → 21% | tight walking margin |
| 5 | Security Chief Nattapong (`security_chief`) | mini, 23 | Lockdown (`MB_SECURITY_CHIEF_ULT_001`) | 3 (quake + quake + quake) | 17 | lag200ms | 12% → 13% | tight walking margin, roll under lag/slow kit |
| 6 | Unit K-7 (`unit_k7`) | stage, 26 | Overload Grid (`SB_UNIT_K7_ULT_001`) | 2 (shock + shock) | 42 | none | 19% → 21% | general |
| 7 | The Ringmaster (`ringmaster`) | mini, 29 | Grand Finale (`MB_RINGMASTER_ULT_001`) | 2 (crane + crane) | 52 | none | 16% → 18% | general |
| 8 | Big Sak (`big_sak`) | stage, 33 | Tower Collapse (`SB_BIG_SAK_ULT_001`) | 3 (quake + quake + quake) | 82 | lag200ms | 17% → 19% | roll under lag/slow kit |
| 9 | Subject 12 (`subject_twelve`) | mini, 37 | Feral Frenzy (`MB_SUBJECT_TWELVE_ULT_001`) | 3 (sludge + sludge + sludge) | 70 | none | 18% → 20% | general |
| 10 | Commander Arthit (`commander_arthit`) | stage, 41 | Total Suppression (`SB_COMMANDER_ARTHIT_ULT_001`) | 3 (shock + shock + rain) | 17 | slowest_kit | 18% → 20% | tight walking margin, roll under lag/slow kit |
| 11 | Director Wiroj (`director_wiroj`) | stage, 50 | Hostile Liquidation (`SB_DIRECTOR_WIROJ_ULT_001`) | 3 (shock + shock + quake) | 27 | none | 16% → 19% | general |
| 12 | The Tunnel Mother (`tunnel_mother`) | world, 32 | Brood Deluge (`WB_TUNNEL_MOTHER_ULT_001`) | 3 (sludge + sludge + quake) | 102 | none | 18% → 20% | general |
| 13 | The Iron Colossus (`iron_colossus`) | world, 52 | Scrapyard Cataclysm (`WB_IRON_COLOSSUS_ULT_001`) | 3 (quake + crane + crane) | 55 | none | 22% → 24% | general |
| 14 | Subject Zero (`subject_zero`) | world, 55 | Abyssal Tide (`WB_SUBJECT_ZERO_ULT_001`) | 3 (rain + rain + rain) | 29 | slowest_kit | 21% → 23% | roll under lag/slow kit |
| 15 | Commander Arthit, Reinstated (`arthit_reinstated`) | mini, 57 | Reinstatement Order (`MB_ARTHIT_REINSTATED_ULT_001`) | 3 (shock + shock + shock) | 18 | none | 16% → 28% | tight walking margin |
| 16 | Subject Twelve, Relapsed (`twelve_relapsed`) | mini, 62 | Relapse Bloom (`MB_TWELVE_RELAPSED_ULT_001`) | 3 (sludge + sludge + sludge) | 66 | none | 16% → 28% | general |
| 17 | Unit K-7, Overdriven (`k7_overdriven`) | mini, 67 | Critical Meltdown (`MB_K7_OVERDRIVEN_ULT_001`) | 3 (shock + shock + quake) | 15 | none | 18% → 31% | tight walking margin |
| 18 | The Slag Titan (`slag_titan`) | world, 60 | Molten Collapse (`WB_SLAG_TITAN_ULT_001`) | 4 (steam + steam + steam + quake) | 28 | none | 21% → 31% | general |
| 19 | The Iron Sovereign (`iron_sovereign`) | world, 70 | Iron Judgement (`WB_IRON_SOVEREIGN_ULT_001`) | 4 (rain + rain + quake + rain) | 47 | none | 22% → 31% | general |
| 20 | Spillway Chief (`spillway_chief`) | mini, 47 | Floodgate Burst (`MB_SPILLWAY_CHIEF_ULT_001`) | 3 (quake + quake + rain) | 28 | none | 11% → 19% | general |
| 21 | The Wiroj Protocol (`wiroj_protocol`) | mini, 72 | Final Protocol (`MB_WIROJ_PROTOCOL_ULT_001`) | 4 (shock + shock + shock + quake) | 17 | slowest_kit | 16% → 29% | tight walking margin, roll under lag/slow kit |
| 22 | The Floodgate Marshal (`floodgate_marshal`) | world, 56 | Martial Flood (`WB_FLOODGATE_MARSHAL_ULT_001`) | 4 (quake + quake + rain + quake) | 46 | slow_hero, slowest_kit, lag100ms, lag200ms | 26% → 37% | roll under lag/slow kit |
| 23 | The Crucible King (`crucible_king`) | world, 64 | Crucible Overflow (`WB_CRUCIBLE_KING_ULT_001`) | 4 (steam + steam + steam + steam) | 17 | slowest_kit | 33% → 48% | tight walking margin, roll under lag/slow kit, damage under enrage |
| 24 | The Founder's Engine (`founders_engine`) | world, 70 | Founder's Verdict (`WB_FOUNDERS_ENGINE_ULT_001`) | 4 (quake + shock + shock + rain) | 16 | slowest_kit, lag200ms | 33% → 49% (was 36% → 53%; P-1) | tight walking margin, roll under lag/slow kit, damage under enrage |

"Base spare" is the fewest ticks between the hero leaving a wave's tiles and that wave
landing, over the 5 starts. Every boss is escaped in the base case.

### Movement scenarios (all 24 bosses)

`ok N`: no damage from any of the 5 starts, with at least N ticks spare (0 means it took
a roll). `hit k/5`: k starts took damage.

| Boss | base | slow_hero | slowest_kit | fps30 | fps120 | lag100ms | lag200ms | roll | slow_lag_roll | slow_hero_roll | slowest_kit_roll | lag200ms_roll |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sludge_foreman | ok 65 | ok 57 | ok 48 | ok 65 | ok 65 | ok 57 | ok 50 | ok 65 | ok 50 | ok 57 | ok 48 | ok 50 |
| furnace_baron | ok 73 | ok 67 | ok 60 | ok 73 | ok 73 | ok 65 | ok 58 | ok 73 | ok 59 | ok 67 | ok 60 | ok 58 |
| pit_champion | ok 82 | ok 79 | ok 75 | ok 82 | ok 82 | ok 74 | **hit 1/5** | ok 82 | ok 71 | ok 79 | ok 75 | ok 0 |
| harbourmaster_chen | ok 16 | ok 22 | ok 17 | ok 6 | ok 16 | ok 19 | ok 14 | ok 16 | ok 18 | ok 22 | ok 17 | ok 0 |
| security_chief | ok 17 | ok 11 | ok 9 | ok 15 | ok 17 | ok 12 | **hit 1/5** | ok 17 | ok 20 | ok 10 | ok 10 | ok 0 |
| unit_k7 | ok 42 | ok 38 | ok 33 | ok 41 | ok 42 | ok 19 | ok 7 | ok 42 | ok 8 | ok 38 | ok 33 | ok 4 |
| ringmaster | ok 52 | ok 48 | ok 42 | ok 50 | ok 52 | ok 46 | ok 49 | ok 52 | ok 45 | ok 48 | ok 42 | ok 49 |
| big_sak | ok 82 | ok 81 | ok 79 | ok 82 | ok 82 | ok 22 | **hit 1/5** | ok 82 | ok 73 | ok 81 | ok 79 | ok 0 |
| subject_twelve | ok 70 | ok 65 | ok 60 | ok 70 | ok 70 | ok 62 | ok 56 | ok 70 | ok 58 | ok 65 | ok 60 | ok 56 |
| commander_arthit | ok 17 | ok 11 | **hit 1/5** | ok 17 | ok 17 | ok 18 | ok 17 | ok 17 | ok 9 | ok 10 | ok 0 | ok 12 |
| director_wiroj | ok 27 | ok 21 | ok 15 | ok 25 | ok 27 | ok 19 | ok 19 | ok 27 | ok 12 | ok 21 | ok 15 | ok 19 |
| tunnel_mother | ok 102 | ok 66 | ok 66 | ok 102 | ok 102 | ok 101 | ok 24 | ok 102 | ok 100 | ok 66 | ok 66 | ok 24 |
| iron_colossus | ok 55 | ok 51 | ok 45 | ok 52 | ok 55 | ok 49 | ok 48 | ok 55 | ok 45 | ok 51 | ok 45 | ok 48 |
| subject_zero | ok 29 | ok 9 | **hit 1/5** | ok 28 | ok 29 | ok 21 | ok 15 | ok 29 | ok 1 | ok 10 | ok 0 | ok 15 |
| arthit_reinstated | ok 18 | ok 16 | ok 28 | ok 17 | ok 18 | ok 19 | ok 25 | ok 18 | ok 12 | ok 16 | ok 28 | ok 19 |
| twelve_relapsed | ok 66 | ok 61 | ok 56 | ok 66 | ok 66 | ok 58 | ok 52 | ok 66 | ok 54 | ok 61 | ok 56 | ok 52 |
| k7_overdriven | ok 15 | ok 42 | ok 29 | ok 14 | ok 15 | ok 44 | ok 22 | ok 15 | ok 22 | ok 42 | ok 29 | ok 22 |
| slag_titan | ok 28 | ok 22 | ok 16 | ok 27 | ok 28 | ok 20 | ok 13 | ok 28 | ok 14 | ok 22 | ok 16 | ok 13 |
| iron_sovereign | ok 47 | ok 35 | ok 11 | ok 23 | ok 47 | ok 17 | ok 23 | ok 47 | ok 23 | ok 35 | ok 10 | ok 20 |
| spillway_chief | ok 28 | ok 23 | ok 16 | ok 27 | ok 28 | ok 20 | ok 19 | ok 28 | ok 14 | ok 23 | ok 16 | ok 19 |
| wiroj_protocol | ok 17 | ok 11 | **hit 1/5** | ok 17 | ok 17 | ok 18 | ok 17 | ok 17 | ok 9 | ok 10 | ok 0 | ok 17 |
| floodgate_marshal | ok 46 | **hit 1/5** | **hit 1/5** | ok 43 | ok 46 | **hit 1/5** | **hit 3/5** | ok 46 | ok 0 | ok 0 | ok 0 | ok 0 |
| crucible_king | ok 17 | ok 11 | **hit 1/5** | ok 17 | ok 17 | ok 18 | ok 20 | ok 17 | ok 9 | ok 10 | ok 0 | ok 20 |
| founders_engine | ok 16 | ok 9 | **hit 1/5** | ok 15 | ok 16 | ok 8 | **hit 2/5** | ok 16 | ok 0 | ok 9 | ok 0 | ok 0 |
| bosses hit | 0 | 1 | 6 | 0 | 0 | 1 | 5 | 0 | 0 | 0 | 0 | 0 |

What this shows:
- With a timed roll, every Ultimate is escaped from every start in every variant,
  including the combined worst cases (0.64 speed; 200 ms of lag; 0.8 speed with 30 FPS
  and 100 ms).
- Walking alone fails in these stress cases:
  - Floodgate Marshal from its centre start, at 0.8 speed or 100 ms;
  - 6 bosses at 0.64 speed;
  - 5 bosses at 200 ms.
- 30 and 120 FPS change nothing that matters: the sim is tick-based.

### Encounter edges

| Boss | casts in 100 s | first | min gap / cd | phase reached | called while channelled | earlier beside a wave | waiting at casts | hero falls: after / left | boss falls: after / left | escape |
|---|---|---|---|---|---|---|---|---|---|---|
| sludge_foreman | 4 | 565 | 1521 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 145) | 0+0 / 0 | - |
| furnace_baron | 4 | 642 | 1522 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 145) | 0+0 / 0 | - |
| pit_champion | 4 | 546 | 1558 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 145) | 0+0 / 0 | - |
| harbourmaster_chen | 4 | 825 | 1659 / 1500 | 1 | 0 | 0 | 3 | 0 / 0 (down 143) | 0+0 / 0 | - |
| security_chief | 4 | 657 | 1548 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 141) | 0+0 / 0 | - |
| unit_k7 | 4 | 636 | 1561 / 1500 | 1 | 0 | 0 | 4 | 0 / 0 (down 141) | 0+0 / 0 | - |
| ringmaster | 4 | 566 | 1580 / 1500 | 1 | 0 | 0 | 1 | 0 / 0 (down 141) | 0+0 / 0 | - |
| big_sak | 3 | 1111 | 1559 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 139) | 0+0 / 0 | - |
| subject_twelve | 4 | 545 | 1581 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 139) | 0+0 / 0 | - |
| commander_arthit | 4 | 698 | 1591 / 1500 | 1 | 0 | 0 | 12 | 0 / 0 (down 138) | 0+0 / 0 | - |
| director_wiroj | 4 | 552 | 1518 / 1500 | 2 | 0 | 0 | 0 | 0 / 0 (down 137) | 0+0 / 0 | - |
| tunnel_mother | 4 | 579 | 1532 / 1500 | 2 | 0 | 0 | 1 | 0 / 0 (down 139) | 0+0 / 0 | time, after 0, hits 0, left 0 |
| iron_colossus | 4 | 705 | 1609 / 1500 | 2 | 0 | 0 | 11 | 0 / 0 (down 135) | 0+0 / 0 | time, after 0, hits 0, left 0 |
| subject_zero | 3 | 1749 | 1535 / 1500 | 2 | 0 | 0 | 0 | 0 / 0 (down 135) | 0+0 / 0 | time, after 0, hits 0, left 0 |
| arthit_reinstated | 4 | 671 | 1508 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 135) | 0+0 / 0 | - |
| twelve_relapsed | 4 | 658 | 1552 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 135) | 0+0 / 0 | - |
| k7_overdriven | 4 | 625 | 1506 / 1500 | 1 | 0 | 0 | 1 | 0 / 0 (down 133) | 0+0 / 0 | - |
| slag_titan | 4 | 564 | 1547 / 1500 | 2 | 0 | 0 | 7 | 0 / 0 (down 135) | 0+0 / 0 | time, after 0, hits 0, left 0 |
| iron_sovereign | 2 | 1893 | 1895 / 1500 | 2 | 0 | 0 | 1 | 0 / 0 (down 133) | 0+0 / 0 | time, after 0, hits 0, left 0 |
| spillway_chief | 4 | 725 | 1521 / 1500 | 1 | 0 | 0 | 0 | 0 / 0 (down 137) | 0+0 / 0 | - |
| wiroj_protocol | 4 | 680 | 1528 / 1500 | 2 | 0 | 0 | 6 | 0 / 0 (down 133) | 0+0 / 0 | - |
| floodgate_marshal | 3 | 951 | 1601 / 1500 | 2 | 0 | 0 | 6 | 0 / 0 (down 135) | 0+0 / 0 | time, after 0, hits 0, left 0 |
| crucible_king | 2 | 1880 | 2391 / 1500 | 2 | 0 | 0 | 0 | 0 / 0 (down 133) | 0+0 / 0 | time, after 0, hits 0, left 0 |
| founders_engine | 3 | 844 | 1563 / 1500 | 3 | 0 | 0 | 6 | 0 / 0 (down 133) | 0+0 / 0 | time, after 0, hits 0, left 0 |

- The hero falls: nothing more is marked or lands (0 events after, 0 hazards left), and
  the channel ends.
- The boss falls: the same.
- A world boss escapes: the same. The attempt ends with `time`.
- Repeated Ultimates never come closer together than their 1500-tick cooldown.
- No hazard is called while one is channelled.
- No earlier hazard is still waiting when a wave is marked. "Waiting at casts" counts
  earlier drops on the ground at the cast; they all land before the first wave.
- The overlap-before check passes for all 24.

### Damage with phases and enrage (all 24)

Per kit: one wave / all waves as a % of the hero's health, at base power → at the
strongest phase × enrage. Kits at the boss's level:
- S0: starter;
- AP: the best of shop and boss drops, +0;
- B0: shop, +0;
- B5: shop, +5;
- D10: boss gear, +10.

| Boss | lvl | waves x dmg | x light | power base / strongest phase / enrage | S0 | AP | B0 | B5 | D10 |
|---|---|---|---|---|---|---|---|---|---|
| sludge_foreman | 5 | 1x25 | 2.78 | 1.716 / 1.98 (p1) / x1.0  | 28/28 → 32/32 | 19/19 → 23/23 | 20/20 → 24/24 | 16/16 → 20/20 | 13/13 → 16/16 |
| furnace_baron | 12 | 1x35 | 2.5 | 2.256 / 2.538 (p1) / x1.0  | 35/35 → 40/40 | 24/24 → 28/28 | 26/26 → 29/29 | 22/22 → 25/25 | 17/17 → 20/20 |
| pit_champion | 10 | 1x27 | 3.0 | 1.978 / 2.15 (p1) / x1.0  | 26/26 → 28/28 | 18/18 → 20/20 | 20/20 → 22/22 | 16/16 → 18/18 | 13/13 → 14/14 |
| harbourmaster_chen | 18 | 2x32 | 2.46 | 2.36 / 2.596 (p1) / x1.0  | 27/53 → 29/58 | 18/36 → 20/40 | 19/39 → 21/43 | 16/32 → 18/36 | 13/25 → 14/28 |
| security_chief | 23 | 3x21 | 3.0 | 2.76 / 3.036 (p1) / x1.0  | 17/52 → 19/57 | 10/31 → 12/35 | 12/35 → 13/39 | 9/28 → 10/31 | 6/18 → 7/22 |
| unit_k7 | 26 | 2x35 | 2.5 | 3.0 / 3.3 (p1) / x1.0  | 29/58 → 32/64 | 18/37 → 21/41 | 19/38 → 21/42 | 15/31 → 17/35 | 12/25 → 14/28 |
| ringmaster | 29 | 2x30 | 3.0 | 3.24 / 3.564 (p1) / x1.0  | 25/49 → 27/54 | 16/32 → 18/36 | 16/33 → 18/37 | 13/26 → 15/30 | 11/21 → 12/24 |
| big_sak | 33 | 3x32 | 2.91 | 3.56 / 3.916 (p1) / x1.0  | 26/79 → 29/86 | 16/48 → 18/54 | 17/52 → 19/58 | 14/42 → 16/47 | 10/31 → 12/35 |
| subject_twelve | 37 | 3x32 | 2.67 | 3.88 / 4.268 (p1) / x1.0  | 26/78 → 29/86 | 16/47 → 18/53 | 18/52 → 20/59 | 14/43 → 16/48 | 10/29 → 11/34 |
| commander_arthit | 41 | 3x32 | 2.67 | 4.2 / 4.62 (p1) / x1.0  | 26/78 → 29/86 | 16/49 → 18/55 | 18/54 → 20/60 | 15/44 → 17/50 | 11/32 → 12/36 |
| director_wiroj | 50 | 3x32 | 2.67 | 4.92 / 5.658 (p2) / x1.0  | 26/78 → 30/90 | 16/47 → 18/56 | 16/48 → 19/56 | 13/38 → 15/46 | 10/31 → 12/37 |
| tunnel_mother | 32 | 3x32 | 2.46 | 3.48 / 3.828 (p2) / x1.0  | 26/78 → 29/86 | 17/50 → 19/56 | 18/54 → 20/60 | 15/44 → 17/50 | 11/34 → 13/38 |
| iron_colossus | 52 | 3x38 | 2.53 | 5.588 / 6.096 (p2) / x1.0  | 34/102 → 37/111 | 22/65 → 24/71 | 22/66 → 24/72 | 18/54 → 20/60 | 15/44 → 16/49 |
| subject_zero | 55 | 3x35 | 2.5 | 6.384 / 6.916 (p2) / x1.0  | 34/102 → 37/111 | 21/62 → 23/68 | 21/64 → 23/70 | 17/52 → 19/57 | 13/40 → 15/44 |
| arthit_reinstated | 57 | 3x32 | 2.67 | 5.48 / 6.028 (p1) / x1.5 fight | 26/78 → 43/128 | 15/46 → 27/81 | 16/48 → 28/83 | 13/38 → 23/69 | 9/28 → 18/55 |
| twelve_relapsed | 62 | 3x32 | 2.67 | 5.88 / 6.468 (p1) / x1.5 fight | 26/78 → 43/128 | 15/45 → 27/80 | 16/48 → 28/83 | 13/38 → 23/69 | 9/28 → 18/54 |
| k7_overdriven | 67 | 3x35 | 2.5 | 6.28 / 6.908 (p1) / x1.5 fight | 28/85 → 47/140 | 17/50 → 29/88 | 18/53 → 31/92 | 14/43 → 26/76 | 10/31 → 20/60 |
| slag_titan | 60 | 4x38 | 2.53 | 6.292 / 6.864 (p2) / x1.3 round | 34/136 → 48/192 | 20/81 → 30/120 | 21/85 → 31/125 | 17/69 → 26/104 | 13/52 → 20/81 |
| iron_sovereign | 70 | 4x35 | 2.5 | 7.824 / 8.476 (p2) / x1.3 round | 34/136 → 48/192 | 20/81 → 30/119 | 22/86 → 31/125 | 18/70 → 26/104 | 13/52 → 20/80 |
| spillway_chief | 47 | 3x21 | 3.0 | 4.68 / 5.148 (p1) / x1.5 fight | 17/51 → 28/84 | 10/29 → 18/53 | 11/32 → 19/58 | 8/25 → 16/47 | 5/16 → 12/35 |
| wiroj_protocol | 72 | 4x32 | 2.67 | 6.68 / 7.682 (p2) / x1.5 fight | 26/104 → 45/179 | 15/60 → 28/111 | 16/64 → 29/117 | 13/51 → 24/97 | 9/36 → 19/75 |
| floodgate_marshal | 56 | 4x40 | 2.5 | 6.75 / 7.29 (p2) / x1.3 round | 41/162 → 57/228 | 25/101 → 37/146 | 26/104 → 37/150 | 21/86 → 31/125 | 17/68 → 26/102 |
| crucible_king | 64 | 4x48 | 2.53 | 7.852 / 8.577 (p2) / x1.3 round | 51/202 → 72/287 | 31/125 → 46/183 | 33/132 → 48/191 | 27/109 → 40/160 | 21/85 → 32/128 |
| founders_engine | 70 | 4x46 (P-1, was 4x50) | 2.3 | 8.802 / 9.78 (p3) / x1.3 round | 50/201 → 73/291 | 31/125 → 46/186 | 33/132 → 49/195 | 27/110 → 41/164 | 21/85 → 33/131 |

- A phase sets the boss's power to the phase's own value (`LevelRules.phase_stats`).
- An enrage multiplies the current power (`BossEnrage.apply`):
  - stage bosses: ×1.5 after 75 s;
  - the five level 56-70 world bosses: ×1.3 in the round's last 20 minutes.
- The "phase+enrage" column is an upper bound. A phase change after the enrage sets the
  power back to the phase's value and drops the enrage multiplier. That is the existing
  rule in `ZoneSim._check_phases` and is unchanged here.

## Human playtest checklist (NOT YET RUN)

For each of the 24 bosses, in a browser build (the Pages deploy or a local Web export),
on a desktop at 60 FPS and at least once on a phone. Record for each run:
- boss, hero, level, kit, enhancement and FPS;
- the browser and device;
- the start position;
- what happened, and whether the warning was understood.

1. **Read the warning.** Stand still at about 150 px. Is the Ultimate's banner,
   sound and first marked wave clear before anything lands? Do waves 2 to 4 read as new
   waves?
2. **Walk out:**
   - from close (about 50 px, top and bottom lane);
   - from the middle;
   - from far (about 250 px).
3. **Roll out.** Survive using a timed roll through a wave you cannot walk out of.
4. **Slow hero.** The slowest hero, ideally holding a chair. Pay attention to Floodgate
   Marshal, Founder's Engine, Crucible King, Wiroj Protocol, Subject Zero and Commander
   Arthit (scripted walking fails there).
5. **Lag.** On a throttled connection or a slow phone. Note any wave that hits after the
   marking had visibly been left.
6. **Low frame rate.** At 30 FPS (browser throttling or a weak device). Do warnings
   stay readable, and does input feel late?
7. **Repeated Ultimates.** A long fight that sees two or more Ultimates. Do they feel
   too frequent alongside the boss's other skills?
8. **Hero death mid-Ultimate.** Let a wave finish the hero. The result screen is
   correct and no wave lands after.
9. **Boss death mid-Ultimate.** Finish the boss while its waves are marked. Nothing
   lands afterwards, and the loot and result are correct.
10. **World boss escape.** For the 8 world bosses: let the hour end mid-Ultimate
    (Floodgate Marshal, Crucible King and Founder's Engine are the priority).
11. **Overlap.** Is the screen readable when the boss's own hazards were already on the
    ground at the cast?
12. **Damage.** At the appropriate kit (shop or boss gear +0 at the boss's level), how
    much of the health bar one wave and all waves take. For the five level 56-70 world
    bosses, also during the last 20 minutes of the hour (enrage) and in the last phase.

Flag any Ultimate where a tester was hit without understanding why, or where one wave
took more than half of an appropriately geared hero.
