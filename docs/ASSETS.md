# Asset pipeline

Character art is built or imported in the cloud (GitHub Actions or a Claude Code
cloud session). Nothing needs installing on your computer.

```
art/lpc/characters.json ──lpc_build.py──┐
                                        ├─> client/assets/characters/<id>/sheet.png
art/unitforge/<id>/ ──unitforge_import──┘   client/assets/characters/<id>/credits.json
                                            client/assets/manifest.json
                     make_spriteframes.py ─> client/assets/characters/<id>/<id>.tres
                     validate.py        ─> fails CI on any broken or unlicensed asset
```

| Piece | What it does |
|---|---|
| `client/assets/manifest.json` | One entry per asset: source, role, sheet, frame size, origin (feet), animations (row, frame count, fps, loop, source animation), licences, credits file, status |
| `tools/assets/lpc_build.py` | Builds characters from the Universal LPC generator's open asset library at a **pinned commit**: same layer paths, frame cycles, z-order and palette recolouring as the website. Selects frames; never invents them |
| `tools/assets/unitforge_import.py` | Imports UnitForge "Godot 4" exports you upload; repacks frames unchanged (never resized) |
| `tools/assets/make_spriteframes.py` | Writes a Godot `SpriteFrames` resource per asset (deterministic, so CI checks it is current) |
| `tools/assets/validate.py` | PNG format, transparency, grid size, no empty frames, rows in range, required animations per role, sane fps/origin, credits present, licences allowed, `.tres` up to date |
| `tools/assets/test_pipeline.py` | Unit tests for all of the above (CI job "Asset manifest…") |
| `client/scenes/tools/Gallery.tscn` | Title → **Characters**: every asset, every animation, playing |
| Title → **Credits** | Built from the credits files; required by the attribution licences |

In game, `FighterView` plays the art with `AnimatedSprite2D` (nearest-neighbour
filtering, flipped for left-facing). Attack and hit animations are stepped by
simulation ticks, so a swing's frames match its startup/active/recovery exactly.
Which art a thing uses is data: `enemies.json` `sprite`, `areas.json` NPC `sprite`,
`progression.json` hero `sprite`, and `items.json` `hero_sprite` (armour that
changes the hero's look). `ContentDB` fails if any of these names a missing asset.

## Imported so far (all actually built and committed)

| Asset | Role | Built from (LPC parts) | Licences used |
|---|---|---|---|
| hero_mika | playable hero | female body, human head, high ponytail, t-shirt, pants, shoes | OGA-BY 3.0 |
| hero_mika_armoured | hero, alternative equipment (Work Jacket) | as above + leather armour, boots | OGA-BY 3.0 |
| npc_ama | NPC, vendor | female body, bob, long sleeves, skirt, apron | CC0, OGA-BY 3.0 |
| npc_odo | NPC, quest giver | male body, elderly head, beard, tabard | OGA-BY 3.0 |
| smogling | enemy | zombie body, goblin head (zombie green) | OGA-BY 3.0 |
| tar_hound ("Tar Rat") | enemy | body and rat head in black fur | OGA-BY 3.0 |
| pipe_brute | enemy | green body, orc head, suspenders | OGA-BY 3.0(+) |
| smog_warden | elite | skeleton body, plate armour | OGA-BY 3.0 |
| sludge_foreman | boss | boarman head, suspenders | CC-BY 3.0, OGA-BY 3.0 |
| dock_thug | enemy | male body, bandana, trimmed beard, t-shirt, pants, boots | OGA-BY 3.0 |
| rail_bruiser | enemy | buzzcut, beard, sleeveless shirt, overalls | OGA-BY 3.0(+) |
| market_punk | enemy | pink spiked hair, long sleeves, open vest, cuffed pants | CC-BY 4.0, OGA-BY 3.0 |
| refinery_enforcer | elite | headband, legion armour, armoured legs | OGA-BY 3.0(+) |
| furnace_baron | boss | walrus moustache, balding, leather cap, trench coat | OGA-BY 3.0(+) |
| npc_kenji | NPC, night-market vendor | topknot, headband, long sleeves, apron | OGA-BY 3.0(+) |
| street_thrower | enemy (ranged) | bandana, plain hair, t-shirt, open vest, pants, white shoes | OGA-BY 3.0 |
| pit_champion | mini-boss | shirtless, buzzcut, thick headband, shorts | OGA-BY 3.0(+) |
| hero_kan | playable hero (Basketball) | sleeveless jersey, shorts, white shoes, thick headband | OGA-BY 3.0(+) |
| hero_dao | playable hero (Police) | female, high ponytail, khaki buttoned long sleeves, black pants, boots | OGA-BY 3.0 |
| hero_pong | playable hero (Soldier) | buzzcut, trimmed beard, green long sleeves and pants, rim boots | OGA-BY 3.0(+) |

The licence policy did its job on the heroes: a necktie for Dao and a vest for Pong
were refused by `lpc_build.py` because they are only offered as CC-BY-SA/GPL, so the
recipes use other pieces.

**Hand sockets.** For every character the builder also records, per animation frame,
where the weapon hand (always the same arm in every frame, the one that swings) is and at what
angle a held weapon points (`hands` in the
manifest: `[x, y, degrees]` per frame). Positions come from LPC's glove layer (hands
only, OGA-BY) for the character's body type, which is read but never shipped; the
angles are authored once per game animation in `weapon_pose` in the recipe file (for
the LPC source they were drawn against): a swing arc for `light`, straight ahead for
`stab`; in LPC's two-handed `slash` (the `heavy` blow) the other arm strikes, so its
pose says `"hand": "front"` and the weapon follows the striking arm (waiting where it
next shows while that arm is behind the body). The
game draws a held weapon at the socket of the frame on screen, so it follows every
swing, then draws the weapon hand again on top from `hands.png` (the sheet's pixels
under the near-hand glove mask, one per frame), so the fist closes around the handle.

Animations: `idle`, `walk`, `light` (LPC half-slash), `heavy` (slash), `hurt`,
`down`, `dodge` (jump) for the hero. Bodies LPC did not draw an animation for use
another real LPC animation (see `animation_overrides` in the recipe file), e.g. the
zombie body has no idle, so its idle is walk frame 0 (its standing pose).

### Known limitations of the LPC source
- **No punch or kick animation exists in LPC.** Light attacks use the one-handed
  half-slash and heavy attacks the slash. Unarmed, these read as punches.
- **Hurt and knock-down are drawn facing the camera only.** In side view, being
  hit briefly shows the front of the character.
- No jump for zombie/skeleton bodies, so those enemies have no dodge animation
  (they never dodge).
- Free alternatives for missing animations: commission or draw them in the
  same 64×64 LPC style (e.g. with LibreSprite or Piskel, both free), or use
  ElizaWy's "LPC Revised" sets, which add more combat poses.

## Licensing (read before shipping)

- Default policy (`art/lpc/characters.json` → `license_policy.allowed`):
  **CC0, OGA-BY, CC-BY only.** No share-alike and no GPL art, so the game can ship
  anywhere (including DRM platforms) with credits.
- LPC parts are often offered under several licences ("OGA-BY 3.0, CC-BY-SA 3.0,
  GPL 3.0"). We take that as a choice between them, as the generator's README
  does, and record the most permissive one we can use per file.
- The build **refuses** parts only offered under share-alike/copyleft. This
  happened for the muscular body type and for the wolf and zombie heads, so they
  were replaced. To allow CC-BY-SA you must accept that the derived sprite sheets
  are then CC-BY-SA too. That's a decision for the owner, not the pipeline.
- Credits: each asset's `credits.json` (file, authors, licence chosen, licences
  offered, source URLs). The in-game Credits screen lists all authors and licences.
- The pipeline's own code is MIT. The LPC generator's *code* (GPL-3.0) is **not**
  used or copied. Only its asset files and data definitions are read, at
  build time.

## Interface icons (original, generated)

`tools/assets/gen_ui.py` draws the 16x16 item and interface icons (food, gear,
coin, quest marks) into `client/assets/ui/icons.png` and records their regions in
the manifest's `ui` section. Each item in `items.json` names its `icon`. The
validator regenerates the sheet in memory and fails when it is stale or an item
names an unknown icon. See [UI.md](UI.md).

The same sheet holds the street weapons as sprites in 16x32 cells (a painting may ask
for a bigger `cell`, as the film-sized chair does; its grip is then in `weapon_grips`),
upright at the characters' scale with the grip at `weapon_grip` (8, 24), so the game can turn them
about the hand; `weapons.json` names each one's `sprite` and the validator checks it
exists. The weapons are the project owner's paintings (knife, bottle, plank, steel
pipe, machete, folding chair, frying pan, pipe wrench, baseball bat), listed in
`art/weapons/weapons.json` with their sources in `art/weapons/src/` (scaled to at most
480 px): keyed from the green backdrop like the street kit (`keep_green` for the green
bottle), shrunk to `length` pixels tall with hard edges and the characters' outline,
the handle centred on the grip, which sits `handle` of the way up from the
handle's end (default 0.15), so the fist closes around the middle of the handle and
its end shows below the fist (`turn` rotates a painting first). Weapons
without a painting fall back to the code painters in `gen_ui.py`. The chair is held
upside down by the top of its back, the way one swings a folding chair. Paint new
weapons upright with the handle at the bottom.

## Fonts

`client/assets/fonts/NotoSansThai-SemiBold.ttf` (Noto Sans Thai 2.002, SIL Open Font
License 1.1, licence beside it) is added at startup as a fallback to the engine's
default font, so Thai names and text render. The manifest's `fonts` section pins its
source URL and SHA-256; `validate.py` checks both and that the licence file is present.

## Recorded sounds

`tools/assets/import_sounds.py` imports recorded effects listed in
`art/sounds/sounds.json`: each names its WAV in `art/sounds/`, title, authors,
licence (from the policy's allowed list) and source page, and the cut to keep
(`start`, `length`). The tool mixes to mono, fades in and out, normalises to -1 dBFS
and writes `client/assets/audio/<id>.wav`; the manifest lists the credits under
`audio.recorded` and the in-game credits show them. So far: `punch_hit`, "Punch 5" by
jakeeaton (Freesound, CC-BY 4.0), and `punch_hit_2`..`punch_hit_6`, five punches cut
from "multi punch" by Shikamarunara74 (Freesound, CC-BY 3.0); one of the six plays at
random when a fist or kick lands. Cuts start just before the impact so the sound is
not late. `punch_hit_7`..`punch_hit_10` are cut from "Punches.mp3" by mrrap4food (Freesound,
CC0 as listed there).

**Replace before any paid feature:** that MP3's own tags read "the hollywood edge" and
"copyright 1999 hollywood edg", a commercial sound library, so the uploader may not
have held the rights they released as CC0. The project owner chose to keep it while the
game is free; it is marked `replace_before_paid` in `art/sounds/sounds.json`, and
`validate.py` prints a "REPLACE BEFORE PAID FEATURES" line for it on every run. Before
in-game purchases open, replace those four with the project's own recordings or
synthesised sounds. Avoid such files for anything new.

## Effects, sounds and the training dummy (original, generated)

All MIT, drawn or synthesised by code, checked for freshness by `validate.py` and
regenerated by the **Assets** workflow:

| Generator | Output | Contents |
|---|---|---|
| `gen_fx.py` | `client/assets/fx/fx.png`, manifest `fx` | Hit sparks (light, heavy, blocked), dust, skill effects (uppercut arc, whirlwind rings, rush streaks, slam shockwave), level-up light, heal sparkles |
| `gen_sfx.py` | `client/assets/audio/*.wav`, manifest `audio` | 25 retro sounds from oscillators and filtered noise: swings, hits, block, guard break, hurt, knockdown, KO, dodge, four skills, level up, coin, pickup, heal, quest, UI move/select/back/denied, boss roar, arena lock |
| `gen_dummy.py` | `client/assets/characters/training_dummy/` | A wooden sparring post with straw padding and a target: idle, hurt (rocks and sheds straw), down (tips over) |

Effects use integer maths only, so they are byte-identical everywhere; sounds use
floating-point sine, so the validator allows a difference of a few 16-bit steps.

## Scenery (original, generated)

Areas laid out from the street kit (below) use only the generated `sky.png`; the
other generated layers remain the fallback for an area without a kit layout.

`tools/assets/gen_environment.py` draws every area's scenery in code: original pixel
art, MIT-licensed with the rest of the project, so no attribution is needed. Each
area in `client/data/areas.json` has a `theme` (`depot`, `market`, `canal`) and a
palette. The generator writes `client/assets/environment/<area>/`:

| Layer | In game |
|---|---|
| `sky.png` (gradient, stars, moon) | `Parallax2D`, fixed to the screen |
| `far.png` (distant skyline; a crane at the depot) | `Parallax2D` at 30% scroll |
| `buildings.png` (facades: brick or stucco shophouses with windows, fire escapes, awnings, signs and water towers; corrugated warehouses and containers at the depot; pipes, smokestacks and a polluted canal at Canal Works) | world layer |
| `ground.png` (sidewalk slabs, kerb, asphalt, cracks, lane marks, manholes, drains, puddles) | world layer |
| `props.png` + placements (lamps with additive glow, crates, barrels, bins, hydrants, market stalls, lantern strings, cones, valves, benches) | sprites along the sidewalk |

Output depends only on the area data (seeded by area id). `validate.py` regenerates
it in memory and fails if the committed images differ. A new area gets scenery
just by adding it to `areas.json` and re-running the generator, or the **Assets**
workflow, which runs it every time.

## Street kit (HD-2D, painted by the project owner)

The streets are assembled from separately painted pieces, in the HD-2D style
(Octopath-like: painted scenery, pixel-art characters). The owner paints each piece
on a flat green backdrop with a dark outline, from the prompts in this project's
history. Rules for new pieces: **no real brands or logos; signs blank** (Thai text is
drawn in-engine); **no Buddha images** (a spirit house shows a deity, e.g. Nang Kwak).

`art/kit/src/` holds the sources (scaled to at most 1400 px) and `art/kit/kit.json`
the recipe. Each piece has its game height in pixels; options are `crop` (fractions
of the image, to drop a corner glow), `haze` (also key out the warm glow some
backdrops have in a corner; never for pieces lit warm all over, whose edges would
leak), `keep_green` (green enclosed by the piece is paint, not backdrop: the pharmacy
cross), `hole_margin` (key enclosed greens more eagerly), `despill` (pull green
out of the whole piece: the bus stop glass), `edges` (the piece may touch the image
border), `mirror`, `tile` (ground strips, cropped not keyed), and `glow` (where a lamp
gets additive light, as fractions of the piece).

`tools/assets/kit_import.py` keys out green connected to the image border, drops
specks and blobs at the border that are not the piece, removes the green fringe,
trims, and scales to `hd` = 2 texture pixels per game pixel; the game draws them at
half size with linear filtering, sharp at any window size. Ground tiles are mirrored
so they repeat without a seam. Then each area is laid out from its theme in
`kit.json` (seeded by area id): skyline, condo towers and the skytrain behind the
street scrolling slower, a row of shops and shophouses, sidewalk tiles, props,
animals and stalls on the sidewalk between the street furniture, and foliage in front of the fighters
scrolling faster, all recorded in the manifest's `kit` section. Street furniture
is not laid out by the kit but placed in `areas.json` `obstacles` (kinds in
`obstacles.json`), because the simulation needs it: lamp posts, power poles, bins
and cones stand on the sidewalk, out of the fighters' lane; crates, oil drums and
parked vehicles stand solid at the kerb (vehicles block as rectangles, `"box"`).
The kerb (`Scenery.ROAD_TOP` = 244) is above the lane (`ZoneSim.LANE_TOP` = 250),
so fighters never stand on the sidewalk. Pieces are sized to the characters, who
stand about 50 game pixels tall: doors are taller than a person, so shophouses are
280 and shops 170 tall and may rise past the top of the view. An area's
`kit_theme` (areas.json) picks a kit theme of its own, such as `fight_club` and
`junkyard`, while its `theme` still drives the generated fallback scenery. A theme's
`hanging` pieces (the Fight Club work lamps) are strung across the front buildings,
their top `hanging_top` game pixels below the top of the view, `hanging_gap` apart. Pieces are only
re-cut when their source or recipe changes (`--force` re-cuts everything).
`validate.py` checks every piece against its source digest, its texture size, and
that the layouts are what the importer produces now. Licence: the owner's own art
(`Proprietary (project owner)`), credited in game.

Imported pieces not yet placed: the Parking Lot, Rat Nest and Gang HQ pieces (waiting
for those areas), the hanging and standing blank signs (waiting for
in-engine Thai text), the railing, and the train-on-track picture (its beam is cut
out as the `skytrain_track` strip, which runs unbroken across the layer with trains
standing on it).

## Art from the project owner (custom sheets)

`tools/assets/custom_import.py` imports character sheets drawn outside LPC, placed in
`art/custom/<asset_id>/` with an `import.json` (see `hero_riku`, the Boxer, drawn by
the project owner). The file lists the source sheets (a grid of cells, frames read left
to right), a scale per sheet that brings it to the game's size (sheets drawn at
different sizes get different scales so the character matches), and which frames make
each game animation. Frames are scaled with premultiplied alpha and a hard alpha cut,
so edges stay crisp, and get the same dark 1 px outline as the LPC characters. An
animation the art lacks can be derived from one frame by tilting it about the feet
(`from`/`tilt`): that is how Riku's hurt and knock-down are made. The importer also
finds the front fist per frame (the most forward pixel at arm height) for held weapons,
with angles from `weapon_pose`, and a head-and-shoulders portrait crop. Credits name
the project owner under "Proprietary (project owner)", which the validator accepts
only for `custom` sources. The Assets workflow re-runs the import, and a pipeline test
checks the committed output matches a fresh import.

## Adding or changing characters

**LPC (fully automatic):**
1. On github.com, edit `art/lpc/characters.json`: add a character with its layers
   (definition paths come from the generator repo's `sheet_definitions/`).
2. Actions → **Assets** → Run workflow → task `lpc-build` (optionally only some ids).
   It builds, regenerates SpriteFrames, validates, and commits to the branch.

**UnitForge (export is manual: the site has no API, and the build environment
cannot reach it):**
1. Open <https://www.unitforge.net/character>, design the character, and use its
   **Godot 4** export. Keep the export's PNG and `.tres`.
2. On github.com: **Add file → Upload files** into
   `art/unitforge/<asset_id>/` (e.g. `art/unitforge/slime_green/`).
3. In the same folder create `import.json`:
   ```json
   {
     "license": "<licence stated by UnitForge for your export>",
     "attribution": "<who to credit, as UnitForge requires>",
     "role": "enemy",
     "animation_map": { "idle": "idle", "walk": "move", "light": "attack",
                        "hurt": "damaged", "down": "death" }
   }
   ```
   The right-hand names must match the animation names inside the export.
4. Actions → **Assets** → Run workflow → task `unitforge-import`.
   Anything the importer cannot read is reported, not imported.
5. Point content at it, e.g. `"sprite": "slime_green"` in `enemies.json`.

UnitForge note: the importer follows Godot 4's documented SpriteFrames format but
has **not yet been run on a real UnitForge export**. Its terms of use and licence
for exported art were not readable from here. Check them before uploading, and
put what they say into `import.json`.
