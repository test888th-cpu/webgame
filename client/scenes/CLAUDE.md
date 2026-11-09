# client/scenes/: presentation

Scenes read input, draw, play sound and call `client/sim/`. They never re-implement a rule.

- **Read the rules, do not repeat them.**
  - Show what `ZoneSim`, `PlayerProfile` and the rule classes decide.
  - If a scene needs a calculation (a damage preview, a cost), add it to `sim/` and call it.
- **Commands go through the sim's own entry points** (`FighterInput`, `ZoneSim.use_item`,
  the rule classes). A scene never edits fighter HP, inventory or quest state directly.
- **Gameplay-neutral settings.** A graphics or performance option may drop cosmetic detail,
  never information a player acts on (enemy positions, telegraphs, HP, cooldowns).
- **Layout and UI** follow `docs/UI.md`, `docs/RESPONSIVE_LAYOUT.md` and
  `docs/UI_TESTING.md`. The browser probe (`window.ironboundProbe`) stays read-only.
- **Size.** `scenes/game/Game.gd` is at the 1000-line lint limit; extract helpers (as
  `QuestFlow`, `GameMenus`, `GameFeedback`) rather than growing it.
- **Tests.** New scenes get a scene test in `client/tests/unit/`.
