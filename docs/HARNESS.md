# Measurement harness

Numbers for progression and economy decisions (farming grounds, loot, boss
rewards), taken from the game's own rules. It **measures only**: it changes no
game data, no save and no balance value.

| File | What it is |
|---|---|
| `client/tests/harness/ProgressionHarness.gd` | The measurements (pure functions over `ContentDB`, `LevelRules`, `ZoneSim`, `AutoPilot`) |
| `client/tests/harness/HarnessRun.gd` | Command-line run that writes a report |
| `client/tests/harness/harness_config.json` | Which heroes, seeds, gear and areas to run; the boss-model comparison parameters |
| `client/tests/unit/test_harness.gd` | Fast unit tests of the harness itself |

## Running it

```bash
godot --headless --path client --script res://tests/harness/HarnessRun.gd -- --out=/tmp/harness --quick
godot --headless --path client --script res://tests/harness/HarnessRun.gd -- --out=/tmp/harness
```

`--out` is required and must be outside the repository (the run refuses a
folder inside it). `--quick` runs two areas with one hero and one seed;
without it, every story area with every hero, three seeds and two gear
profiles, plus boss-only runs (several minutes). It writes `report.json` and
`report.md`.

## What it reports

- **Story XP model** (exact arithmetic, no simulation): every story fight once
  and every quest, levelling a real `PlayerProfile`; plus scenarios (no
  level-gap multipliers, each boss once more, every area twice).
- **Simulated areas**: `ZoneSim` played by `AutoPilot` from the west edge until
  the area is clear or the hero is down, at the area's level. Per area, gear
  profile and mode: runs, knock-outs, mean seconds, and XP, coins, Scrap Metal
  and Refined Alloy per minute.
- **Gear profiles**, chosen from the data: *shop* (best armour and weapon any
  shop sells at or below the level, best quest-reward charm) and *boss* (the
  same armour with the best boss-drop weapon and charm).
- **Boss-only runs**: other fights pre-cleared, as a stand-in for a rematch
  arena.
- **Boss reward comparison scenarios**: Model 1 (today), Model 2 (reduced
  repeat coins and no guaranteed Refined Alloy on repeats), Model 3 (story
  repeats without the unique roll; rematches paying fragments). The numbers
  in the config's `boss_models` are **comparison parameters, not approved
  game values**.

## Levelling time and enrage timers

- `tests/harness/LevelingRun.gd` (with `LevelingSim`) measures the story's clear time and
  XP per hour on every farming ground at hero levels around it, up to the level cap, and
  turns them into hours per level for the current curve and a proposal from target
  hours (`--out` must be outside the repository; `--part=K/N` splits the work across
  processes, `--merge` writes report.json and report.md).
- `tests/harness/EnrageCompare.gd` fights every boss lair with auto battle for each
  enrage timer in `--timers` (and none), with `--kits` gear (S no gear, B shop +0, C boss
  +5, D boss +10), `--seeds` seeds and the hero `--level_offset` levels from the lair's
  suggested level (`--lairs` narrows the list), and prints kill rate, knock-outs, median,
  90th-percentile and slowest kill time, damage taken, how often the enrage fired and food
  eaten.
- `tests/harness/FarmCheck.gd` runs farming sessions (`LevelingSim.farm_rate`) on the
  grounds in `--areas` at `--offsets` levels from each ground's own, with `--seeds` seeds per
  gear profile, and prints mean XP, coins, Scrap Metal and Refined Alloy per hour and the
  knock-outs, plus damage taken, food eaten, kills and gear drops per hour and what caused
  each knock-out (the last attacker, its hit, and how many enemies stood within reach);
  `--gears` picks B shop +0, C boss +5, D boss +10.
- `tests/harness/WorldBossCheck.gd` fights each world boss with one hero at its level and
  reports damage per minute and the minutes one hero needs to empty the round's pool,
  against the round's open minutes.
- `tests/harness/ItemBudgetQuery.gd` prints the `ItemRules` budget and score of the items
  in `--in=file.json`, so content tools price gear with the game's own rule.

All five only read the data; anything they change lives in memory for one run.

## Limits

- Simulation is not play: `AutoPilot` stands in for a player. A person may be
  faster or slower, and may be knocked out where the pilot is not.
- Time is the fight itself: walking between areas, resting and the taxi are
  not counted.
- The hero is at the area's level with unenhanced gear; food is carried.
- Drop rolls are random per seed: means over more seeds are steadier.
- The boss models adjust measured totals with data-derived boss values; they
  do not run modified rules.
