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
| HUD | `client/scenes/ui/Hud.gd`, `HeroPortrait.gd` | Hero card (portrait in the hero's colour with a level badge, hit flash and low-HP pulse; name and role), coins, area, route card (`MiniMap.gd`, top right, drawn from `MapRules.route`): the district and the area with its level, then one node per area west to east with the map icons (`tools/assets/map_icons.py`): a small orange marker over the hero's area, a teal dot for a town, a horned orange skull for a mini-boss, a round red skull marked BOSS where the district ends (both grey with a green tick once beaten; shown before they are reached, their names only after), a gold flag on the goal, plain areas as rings filled once reached, a red bar just east of the hero while the way on is shut, "GOAL" with an arrow when the goal is in another district, and under each node its number in the district. The map screen marks the same bosses with the same icons. Hovering a node names it; a tap opens the map, tracked quest, boss bar, notifications, key hints, touch controls. Bottom right, a menu bar of five 20x20 icon buttons (Character, Bag, Quests, Map, Settings; the key is in the tooltip). Left, under the weapon, the AUTO switch: a round icon button with a small AUTO caption; while auto battle runs it fills with the accent, glows and its arrows turn, and the run's tally is in its tooltip. It fades where auto cannot start, and pressing it then says why in a toast. No status text on the HUD. Reads state only. |
| Game screens | `client/scenes/game/GameMenus.gd` | One window per job, each with its icon, name, key and a × close button (`UiKit.screen`): Character (C), Bag (B), Quests (O), Map (M), Settings (Game, Auto battle, Controls). A screen's key or menu-bar button toggles it, and one screen replaces another. Esc opens the pause menu: Resume, every screen, return home, save, save and quit (and skip tutorial). Also the shop, NPC conversation, knock-out screen. Shows the profile and calls back into `Game.gd`, which owns every change and rebuilds the screen afterwards. |
| Character tabs | `client/scenes/game/CharacterTabs.gd` | Status: hero card (sprite, HP/energy/XP), attributes as total + gear bonus with a line of help each, next level, record. Equipment: six worn slots around the hero (turnable), stats summary, bag grid. Click opens the item card. Drag gear from the bag onto its slot or onto the hero to wear it, and drag worn gear onto the bag to take it off; while dragging, the slots it can go to light up (only gear the hero can wear now). Right click wears gear, eats food, or takes worn gear off. Keyboard and gamepad use the card. |
| Shop | `client/scenes/game/ShopScreen.gd`, `client/sim/ShopRules.gd` | Buy and Sell tabs (Q/E). The wares, or what the bag holds that the shop will take, on the left; the item card on the right scrolls above a deal bar pinned to the bottom of the window (amount picker for food and materials, total, Buy/Sell), so the button is always on screen. Left/Right change the amount, Enter trades one. Shops pay `sell_rate` (progression.json) of the price, never buy evidence or worn gear, and rare gear or an upgraded item asks "Sure?" before it is sold. |
| Map | `client/scenes/game/MapTab.gd`, `client/scenes/ui/MapNode.gd`, `client/sim/MapRules.gd` | Where the hero is (area, level, district and place in it) and the goal (the tracked quest's area, its giver once done, or the next quest's giver). One row per district, one box per area: level in its threat colour, orange where the hero stands, teal frame for a town, red corner for a boss (green when beaten), gold dot for the goal. Only areas reached and the next one east are named; the rest show `???`. Walking the boxes shows what is known of each area (services, boss, why its gate is shut). M (right stick press) opens and closes it. Read-only: travel stays with the taxi. |
| Items | `client/scenes/ui/ItemText.gd`, `ItemSlot.gd`, `ItemCard.gd` | Rarity colours and player-facing stat text; the bag/worn cell; the item card (icon, name, rarity and slot, level requirement, effects, comparison with what is worn, story, Equip/Unequip/Use/Discard with confirmation). The shop shows the same details. |
| Hotbar | `client/scenes/ui/Hotbar.gd`, `HotbarSlot.gd` | Seven slots from `data/skills.json` (attack, four skills, two consumables): icon, key, cooldown sweep with seconds, blue tint without energy, lock with unlock level, item count, tooltips. Keys 1–7; gamepad RT + X/Y/A/B (skills) and RT + RB (slot 7); click or tap. |
| Feedback | `client/scenes/game/GameFeedback.gd`, `client/scenes/fx/Fx.gd`, `client/scripts/core/Sfx.gd` | Turns zone events into effects, impact flashes, shake, the hurt vignette, the level-up banner and sounds. Presentation only. |
| Title | `client/scenes/title/Title.gd` | Live street backdrop, logo, menu, a card for the character played last (portrait, name, role, level, area), the roster on the street, Gallery, Credits. With saved characters: Continue (the one played last), Characters; without: New game. |
| Characters | `client/scenes/title/CharacterSelect.gd`, `client/sim/RosterRules.gd` | One card per slot (four per account, `max_characters` in progression.json): the character as they look now, name, hero, level, area and when last played, last played first. Enter or click plays; an empty slot makes a new character (its name must differ from the account's others). Delete asks again by name; the file is moved aside, never erased. |
| Gallery | `client/scenes/tools/Gallery.gd` | Two tabs. Characters: the roster grouped into heroes, people, enemies and bosses, each by name; the chosen one large on a stage with a button per animation, and its source, licences and artists. Items: every item as slots grouped by rarity; the chosen one's card (`ItemCard.details` without the comparison) and how it lies on the street (`LootView`). Arrows move, Q/E switch tabs, Esc goes back; the lists scroll with the focus. |
| Hero creation | `client/scenes/create/CharacterCreate.gd` | Roster cards, animated spotlight, about/play style/difficulty/stats/skills panel, name field with validation and Random. Up/Down picks, Enter goes to the name, Enter starts, Esc steps back. Built from `heroes.json`, so new heroes need no UI changes. |
| Loot | `client/scenes/world/LootView.gd` | Dropped items: icon at 2x, shadow, rarity glow and beam, sparkles for epic+, name or coin amount, pop-out arc and collect animation. |
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
  (and the d-pad) move focus, Enter/A selects, Esc/Start closes, C/B/O/M toggle their
  screens, Q/E (LB/RB) switch the Settings tabs. On a gamepad Start opens the pause menu,
  which reaches every screen. Lists act on Enter, so the cursor never has to leave them.
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
has no width, nothing has focus, a screen is missing its own window or close button, the HUD menu bar is not small icons, or the talk
prompt shows away from an NPC. `tools/web-smoke/shots.ts` captures screenshots
of a web export for visual review:

```bash
node tools/web-smoke/shots.ts build/web shots shot:title key:Enter wait:1500 \
  walk:410:262 key:KeyE wait:400 shot:shop
```
