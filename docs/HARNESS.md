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

## Limits

- Simulation is not play: `AutoPilot` stands in for a player. A person may be
  faster or slower, and may be knocked out where the pilot is not.
- Time is the fight itself: walking between areas, resting and the taxi are
  not counted.
- The hero is at the area's level with unenhanced gear; food is carried.
- Drop rolls are random per seed: means over more seeds are steadier.
- The boss models adjust measured totals with data-derived boss values; they
  do not run modified rules.
