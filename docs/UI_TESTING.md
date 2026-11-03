# UI testing (phase U0)

Automated checks for the interface at three window sizes and with the input
each is used with. Phase U0 adds the checks only: it changes no game code,
data, art or save format. See the UI blueprint for phases U1 to U5.

## What runs, and where

| Check | File | Runs in CI | Fails when |
|---|---|---|---|
| UI audit | `client/tests/ui/UiAuditRun.gd` (with `UiAuditSession.gd` and the detectors in `UiAudit.gd`) | `godot-tests` job, step "UI audit"; report uploaded as the **ui-audit** artifact | a problem appears that is not in `client/tests/ui/baseline.json`, a listed problem is gone, or the engine logs an error |
| Detector self-tests and real input | `client/tests/unit/test_ui_audit.gd` | `godot-tests` job, "Unit tests" | a detector misses its fixture's fault or reports a clean fixture; a mouse click, key or touch does not open its screen |
| Browser screenshots and input | `tools/web-smoke/ui-shots.ts` | `web-export` job, step "UI screenshots"; uploaded as the **ui-shots** artifact | a page error; a key, mouse click or touch that does not reach the game; the NPC conversation or turning the screen failing; or a band of Godot's default grey (77, 77, 77) in any screenshot |

To find the results: open the CI run on GitHub, scroll to **Artifacts**, and
download **ui-audit** (`report.md`, `report.json`) or **ui-shots** (one folder
per window size, plus `summary.json`).

## Window sizes and input

| Size | Stands for | Input checked |
|---|---|---|
| 1280x720 | desktop | mouse and keyboard |
| 640x360 | phone held sideways | touch, keyboard for menus |
| 360x640 | phone held upright | touch, keyboard for menus |
| 390x844 | taller phone held upright | touch, keyboard for menus |
| 412x915 | tall phone held upright | touch, keyboard for menus |

The audit sets the input in use (`InputSetup.set_device`) the way a player's
first touch or key would, and the game's screen layout (ScreenLayout, see
docs/RESPONSIVE_LAYOUT.md) decides what is shown: touch controls for touch,
key hints for the keyboard. The browser run turns each screen round (play,
then with the Bag open) and back.

The game's base viewport is 640x360, stretched with `canvas_items` and
`expand`, so a window is shown at `min(width / 640, height / 360)` CSS px per
game px. Sizes for people (touch targets, text) are measured in CSS px.

## Screens and variants

The audit opens, one fresh game at a time: the title, hero creation, the HUD
in Depot Yard, the pause menu, Character, Bag, Skills, Quests, Map, Settings,
an item card over the Bag, Ama's shop, Chief Odo's conversation, Win's taxi
and the knock-out panel. Each runs three times:

- **base**: as the game is;
- **text150**: every label and button's text 150% larger;
- **strings140**: every label and button's text 40% longer (accented filler
  added, the way a longer translation would be).

## Detectors

| Check | Means | Where it runs |
|---|---|---|
| `offscreen` | a visible panel, button, label or scroll box reaches outside the window (rows clipped by a scroll box are skipped) | every screen and variant |
| `text_truncated` | a single-line label cut off (clipped or ended with "…") | every screen and variant |
| `text_outside_panel` | a label sticks out of the panel around it | every screen and variant |
| `text_too_small` | text below 10 CSS px (one line per screen, with the count) | base, all sizes |
| `no_keyboard_focus` | a screen with focusable controls opens with none of them focused | base menus |
| `control_covered` | a button's centre is under another control that takes the click | base menus |
| `touch_target_small` | a touch button or tappable control below 44 CSS px | base, touch sizes |
| `touch_covers_control` | a touch button over a control the player taps (also under open menus: touch buttons still take the touch) | base, touch sizes |
| `touch_covers_npc` / `touch_covers_lane` | a touch button over a person in the street, or over the lane the hero fights in | base HUD, touch sizes |
| `touch_floating` | a touch button out of thumb reach: its bottom above the window's lower 45% | base HUD, touch sizes |
| `keyboard_hint_on_touch` | the keyboard hint bar shown on a touch device | base HUD, touch sizes |
| `world_band` | the street fills less than 60% of the window's height | base HUD, touch sizes |
| `mouse_only_button` | a button no key can focus (usually a shortcut with a keyboard path elsewhere, such as the window's ×) | **information only**: in the report, not in the baseline |

## The baseline

`client/tests/ui/baseline.json` lists every problem the audit finds today,
one line each: `check | size/variant/screen | node`. It is a ratchet:

- a new problem fails CI: fix it, or (only with a recorded decision) add it;
- a fixed problem also fails CI until its line is removed, so the baseline
  never lists problems that are gone and never hides a regression behind
  them.

Node paths are stable across runs (auto-named nodes are written as their
class and place among their siblings). Two runs on the same build give the
same findings.

To write the baseline after an approved change:

```bash
godot --headless --path client --script res://tests/ui/UiAuditRun.gd -- --out=../build/ui-audit --update-baseline
```

## Known problems recorded

The baseline was first written on 2026-11-02 in U0 (232 lines) and updated
by U1-A, responsive gameplay (252 lines):

- **81 lines removed as fixed:** every keyboard hint on touch (4), all 11
  floating touch buttons at 360x640, 43 undersized touch targets, all 14
  touch buttons under open menus (touch controls are now hidden while a
  screen is open) and the touch button over an NPC at 640x360.
- **98 lines added for the two new sizes** (390x844, 412x915), mostly the
  game screens that keep the landscape canvas until U1-B.
- **3 lines added at 640x360:** `touch_covers_lane` for Guard, USE and EAT.
  To keep clear of the kerb where people stand, both touch clusters now sit
  wholly in the bottom corners, so all 10 cluster buttons overlap the lane's
  edge (before U1-A: 7 of 11, plus one over an NPC). A known landscape
  trade-off, recorded for review.

Still listed, by design or for later work:

| Check | Where | Why |
|---|---|---|
| `world_band` | 360x640, 390x844, 412x915 HUD | the street is 360 px of a 640, 779 or 800 px canvas (56%, 46%, 45%); the rest is the HUD band and control deck, not empty canvas |
| `touch_target_small` | 640x360 hotbar | 43 CSS px: at exactly 640 wide the hotbar shrinks to fit between the clusters; wider phones get 44+ |
| `touch_floating` | 640x360 pause | the pause button heads the touch menu row at the top |
| `text_too_small` | phone sizes | the game's 7-9 px text; text size is later work (U1-B and a text-size setting) |
| everything on game screens at phone sizes | | the screens keep the landscape canvas until their portrait designs (U1-B) |

## Limits

- The Godot audit lays out the real screens headless. It measures geometry
  (rects, font sizes, focus); it does not see colours, contrast or how art
  looks. The screenshots are for those, reviewed by a person.
- Touch is checked by geometry and by pushing real touch events at the
  game's own touch buttons; feel on a real phone still needs a device test.
- Text scaling is simulated by enlarging fonts on the built screens; the game
  has no text-size setting yet.
- The baseline was written with the pending Iron City Central changes in the
  working tree (the pause menu's "Go to Iron City Central" row is among the
  screens audited). If those changes are not merged, write it again with the
  command above.
- The browser screenshots run in headless Chromium with software rendering:
  layout is faithful, frame rate is not.
- The browser input checks locate the Bag and pause buttons from the HUD's
  layout rules (`bagAt` and `pauseAt` in `tools/web-smoke/ui-shots.ts`
  mirror ScreenLayout.gd); if the layout moves them, update those with it.
