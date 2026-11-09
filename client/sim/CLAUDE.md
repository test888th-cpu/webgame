# client/sim/: the game rules

The rules for combat, movement, AI, loot, quests, farming, world bosses and progression.
They are shared with the planned zone servers (ARCHITECTURE.md D2) and the headless tests
and harness, so they must behave identically wherever they run.

## Rules for every file here
- **Pure code only.** Static functions or `RefCounted` classes; no `Node`, scene tree,
  `Input`, rendering, audio, autoloads (`GameSession`, `SaveStore`, `Sfx`, ...), host
  services (`OS`, `Engine`, `Time`, ...) or `res://scenes` paths.
  `tests/unit/test_sim_purity.gd` enforces this.
- **Determinism.**
  - Combat runs at a fixed 60 ticks/s (`CombatRules.TICK_RATE`); timings are in ticks.
  - Randomness only through an injected or seeded `RandomNumberGenerator`
    (`ZoneSim.rng`, seeded from the constructor); never global `randf()` or `randomize()`.
  - Time is passed in (for example `WorldBossRules.window(content, boss, now)`); never
    read the clock here.
- **File access** only in the data loaders (`ContentDB.gd`, `MoveLibrary.gd`), the
  allowlist in the purity test. A new exception is a reviewed change to that list.
- **Outcomes are decided here, never in scenes.** Damage, loot, XP, coins, quest state and
  food use resolve in these rules. Auto battle (`AutoPilot`) presses the same inputs a
  player does and never writes state directly (ARCHITECTURE.md D7).
- **Data, not code, for content.** New monsters, items, moves and areas go into
  `client/data/` (see `client/data/CLAUDE.md`).

## Size and structure
- gdlint caps a file at 1000 lines; `ZoneSim.gd` sits at the limit. New behaviour goes
  into a helper class beside it (as `BossMechanics`, `FarmSpawner`, `FoodRules`), never
  appended to the coordinator.

## Tests
- Every new rule gets a unit test in `client/tests/unit/` (see `client/tests/CLAUDE.md`).
- Balance claims are measured with `client/tests/harness/` and seeds, never guessed.
