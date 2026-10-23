# Interface (UI/UX)

How the game's screens are built, and the rules every screen follows. The
interface is drawn by code (no hand-placed `.tscn` layouts), so it is reviewable
in diffs and checked by tests.

## Layers

| Piece | File | Role |
|---|---|---|
| Visual language | `client/scenes/ui/UiTheme.gd` | Palette, type scale, spacing, and the styles of every control type. Merged into the project theme at startup by `GameSession`, so every Control (also under CanvasLayers) uses it. |
| Building blocks | `client/scenes/ui/UiKit.gd` | `label`, `button`, `menu_button`, `window`, `dialog`, `section`, `row`, `key_hint`, `icon`/`icon_rect`, `portrait`, `focus_first`. Screens are assembled from these. |
| Bars | `client/scenes/ui/StatBar.gd` | HP/energy/XP/boss bars, drawn directly, with a damage trail. |
| HUD | `client/scenes/ui/Hud.gd` | Hero card, coins, area, tracked quest, boss bar, notifications, key hints, touch controls. Reads state only. |
| Game screens | `client/scenes/game/GameMenus.gd` | Pause window (Status, Bag, Quests, Controls, Game tabs), shop, NPC conversation, knock-out screen. Shows the profile and calls back into `Game.gd`, which owns every change and rebuilds the screen afterwards. |
| Hotbar | `client/scenes/ui/Hotbar.gd`, `HotbarSlot.gd` | Seven slots from `data/skills.json` (attack, four skills, two consumables): icon, key, cooldown sweep with seconds, blue tint without energy, lock with unlock level, item count, tooltips. Keys 1–7; gamepad RT + X/Y/A/B (skills) and RT + RB (slot 7); click or tap. |
| Feedback | `client/scenes/game/GameFeedback.gd`, `client/scenes/fx/Fx.gd`, `client/scripts/core/Sfx.gd` | Turns zone events into effects, impact flashes, shake, the hurt vignette, the level-up banner and sounds. Presentation only. |
| Title | `client/scenes/title/Title.gd` | Live street backdrop, logo, menu, a card for the saved hero (portrait, name, role, level, area), the roster on the street, Characters, Credits. |
| Hero creation | `client/scenes/create/CharacterCreate.gd` | Roster cards, animated spotlight, about/play style/difficulty/stats/skills panel, name field with validation and Random. Up/Down picks, Enter goes to the name, Enter starts, Esc steps back. Built from `heroes.json`, so new heroes need no UI changes. |
| World prompts | `client/scenes/world/ZoneView.gd` | `[E] Talk` / `[E] Shop` over the NPC in reach; `$` and `!` marks; camera shake. |
| Icons | `tools/assets/gen_ui.py` | Original 16x16 item and interface icons (`client/assets/ui/icons.png`). Items name theirs in `items.json`. |

## Rules

- **One source of style.** Colours and sizes come from `UiTheme` constants or
  theme types; screens do not invent new ones.
- **Designed for the 640x360 base viewport.** The project stretches with
  `canvas_items` / `expand`, so text stays sharp and wider screens get more room.
  Modal windows have a fixed size inside 640x360 and are centred.
- **Wrapping text always has a width.** An autowrapping label in an unsized
  container wraps every word onto its own line (the bug in the first title
  screen). `UiKit.label` only wraps when given `wrap_width`.
- **Keyboard and gamepad first.** Every screen focuses its first control. W/S
  (and the d-pad) move focus, Enter/A selects, Esc/Start closes, Q/E (LB/RB)
  switch pause tabs. Lists act on Enter, so the cursor never has to leave them.
- **Screens are rebuilt, not patched.** After buying, equipping or handing in,
  `Game` rebuilds the screen from the profile and restores the selection.
- **The world pauses** while any menu is open.
- **Readable over the game.** Text drawn over the world (names, damage numbers,
  HUD figures) has an outline.
- **Player preferences** (screen shake, frame-rate counter) live in
  `user://settings.json`, separate from the save.

## Tests

`client/tests/unit/test_ui.gd` opens the real screens at the 640x360 base size
and fails when a visible panel, button or label is off screen, a wrapping label
has no width, nothing has focus, the tab keys do not switch tabs, or the talk
prompt shows away from an NPC. `tools/web-smoke/shots.ts` captures screenshots
of a web export for visual review:

```bash
node tools/web-smoke/shots.ts build/web shots shot:title key:Enter wait:1500 \
  walk:410:262 key:KeyE wait:400 shot:shop
```
