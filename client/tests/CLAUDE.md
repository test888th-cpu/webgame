# client/tests/: tests and measurement

- **Unit and scene tests** live in `unit/test_*.gd`, extend `TestCase` and are discovered
  by `TestRunner.gd`:
  `godot --headless --path client --script res://tests/TestRunner.gd`.
  Any engine or script error during a test fails it.
- **Determinism.** Tests that use randomness seed it (`seed(n)`, or a `ZoneSim` seed), so a
  failure replays exactly.
- **The harness** (`harness/ProgressionHarness.gd`, `docs/HARNESS.md`) runs whole fights and
  farming loops with auto battle. Use it for balance numbers; record hero, level, gear,
  food and seeds with every result.
- **Guard tests** for architecture (`unit/test_sim_purity.gd`) and for the owner's rules
  (unlimited food, unlimited world-boss entries, approved heal values) must stay green.
  Change them only with approval.
- **Report honestly.** Never claim a test passed unless it ran and passed.
