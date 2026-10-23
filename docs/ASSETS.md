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

## Fonts

`client/assets/fonts/NotoSansThai-SemiBold.ttf` (Noto Sans Thai 2.002, SIL Open Font
License 1.1, licence beside it) is added at startup as a fallback to the engine's
default font, so Thai names and text render. The manifest's `fonts` section pins its
source URL and SHA-256; `validate.py` checks both and that the licence file is present.

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
