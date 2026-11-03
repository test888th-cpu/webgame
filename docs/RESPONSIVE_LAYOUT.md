# Responsive layout (phase U1-A)

How the game uses the screen on desktop, phones held sideways and phones held
upright. Presentation only: combat, movement, collision, AI, spawns,
progression, economy and the save format are untouched.

## Why portrait looked broken before

At 360x640 the game showed its street as a thin band in the middle with large
grey areas above and below. Measured on the web build:

1. **One landscape canvas for every shape.** `project.godot` sets a 640x360
   canvas stretched with `canvas_items` / `expand`. A 360-wide window shows it
   at `min(360/640, 640/360) = 0.5625`, so the canvas becomes 640x1138 and
   everything is drawn at 56%: 9 px text became about 5 CSS px.
2. **The grey was Godot's default clear colour**, exactly (77, 77, 77), not
   letterboxing (that would need `aspect = keep`) and not scenery: nothing set
   `rendering/environment/defaults/default_clear_color`.
3. **The camera framed only world y 0 to 360** (`ZoneView`, `limit_top = 0`,
   `limit_bottom = 360`), so Godot centred the 360-tall street in the
   1138-tall view and the empty canvas showed above and below.
4. **Fixed coordinates.** The key hints sat at (8, 346), mid-screen on a tall
   canvas; touch buttons were TouchScreenButtons at fixed 640x360 points such
   as (560, 290), 30 to 34 px (17 to 19 CSS px in portrait).
5. **No safe area, orientation or input-device handling.**

## The layout model

`client/scenes/ui/ScreenLayout.gd` is the one place that knows about screen
shape. `ScreenLayout.compute(window, insets, device, portrait_ok,
screen_open)` returns the mode, the logical canvas, the scale, safe insets and
a rect for each part of the HUD. `GameSession` owns it: it recomputes on
resize or turn, when the input device changes, and when a game screen opens
or closes, applies the canvas size (`Window.content_scale_size`) and emits
`layout_changed`. The HUD, the street's camera and the touch controls only
read it.

| Mode | When | Canvas | Arrangement |
|---|---|---|---|
| Landscape, keyboard/mouse/gamepad | window wider than tall, or no portrait design for the screen | 640x360 | exactly as before |
| Landscape, touch | same, touch in use | 640x360 | touch clusters in the bottom corners, below the kerb where people stand (arrow keys as an inverted T on the left, combat buttons 3x2 on the right); the hotbar between them; a touch menu row at the top centre (pause, Bag, Map, Quests, Character); the boss bar under it |
| Portrait | window taller than wide while the street is played | 360 wide (360x640 and up) | a HUD band on top (64 to 120 px, taller on tall phones so the quest and route cards sit above the street), the street 360 tall under it, a control deck below: the hotbar over the controls, the movement cross lower left, combat buttons lower right, Bag, Map, AUTO and pause between them |

Rules:

- **Touch targets** are at least 44 CSS px (`MIN_TOUCH_CSS`), worked out from
  the live scale.
- **Key hints** show only while the keyboard is in use. **Touch controls**
  show only while touch is in use and no game screen is open (a screen is used
  by tapping it, and buttons under it would still take touches).
  `InputSetup` tracks the input in use. It ignores the click a browser sends
  after a tap, so a tap is never mistaken for a mouse.
- **Safe areas:** on the web, the page's CSS `env(safe-area-inset-*)`; on
  Android and iOS, the display's safe area. On desktop there are none.
- **The street's camera** frames the street where the layout puts it, and
  re-frames at once on a turn, even while a menu pauses the game.
- **No empty canvas:** the clear colour is the game's own ink colour, and the
  portrait HUD band and deck are drawn as panels.
- **Portrait is a 360-wide canvas** because every story arena is at least 320
  px wide, so each fight still fits across. At 360x640 the scale is 1.0, the
  same text size as a phone held sideways.

## Not yet (U1-B)

The game screens (Bag, Character, Map, Quests, Skills, Shop, dialogue, pause,
settings), the title and hero creation have no portrait designs yet. While
one is open the canvas goes back to 640x360, so it looks as it did before
U1-A (scaled down, on the game's dark background instead of grey). U1-B
replaces them with purpose-designed portrait layouts and removes that switch.

## Tests

- `client/tests/unit/test_responsive.gd`: the layout at desktop, landscape
  phone and portrait phone sizes (bands, no overlaps, 44 CSS px, safe areas,
  clusters below the kerb), and the real game: the street drawn where the
  layout puts it, touch and key hints by input, screens keeping the landscape
  canvas, and turning the phone mid-game and mid-screen.
- The UI audit and browser screenshots (docs/UI_TESTING.md) run at 1280x720,
  640x360, 360x640, 390x844 and 412x915. The browser run fails on any band of
  default grey.
