# client/data/: game content

JSON is the source of truth for content: areas, enemies, items, moves, skills, quests,
shops, heroes, weapons, obstacles, boss effects, the world bosses, progression and the
tutorial.

- **Validated on load.** `ContentDB.load_all` checks every file; rule classes add their own
  checks (for example `ItemRules.problems` for gear budgets, `FarmSpawner.problems` for
  farming grounds). Invalid content fails the tests, so fix the data, not the check.
- **Adding content needs no code.** A new move, monster, item or area is a data change
  (CLAUDE.md "Boundaries"). If it seems to need code, the rule belongs in `client/sim/`.
- **Keep the existing format.** Two-space JSON as the files already use; never rename or
  remove a field other code or saves read without a migration.
- **Content obligations.** New items and enemies need their art and icons through the asset
  pipeline (`docs/ASSETS.md`); story names and places come only from
  `docs/STORY_BIBLE.md`.
- **Balance values** (power, HP, drop chances, food, world-boss rules) change only with the
  owner's approval and a measurement (`docs/HARNESS.md`). The owner's rules: food usage is
  unlimited and world-boss entries are unlimited, with no per-fight or per-round caps.
