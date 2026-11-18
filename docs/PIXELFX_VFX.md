# PixelFX visual effects: source, selection and integration

**Status:** imported locally, 2026-11-17. Not committed.

- **VERIFIED:** checked against the source, with evidence below.
- **PROPOSED:** suggested use; nothing in gameplay uses it yet.
- **UNKNOWN:** could not be checked.

The asset records are generated into [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) (ids
`fx.pixelfx.<id>`), [ASSET_CREDITS.md](ASSET_CREDITS.md),
[ASSET_REPLACEMENT_MAP.md](ASSET_REPLACEMENT_MAP.md), `data/asset_provenance.json` and
the CSV.

## 1. Source and licence (VERIFIED)

| Item | Finding |
|---|---|
| Repository | <https://github.com/patch-gg/pixelfx> (owner-approved source) |
| Pinned commit | `a84159688af3ca37a4be05a0d422b94451b2e24e` (pixelfx 0.3.0), the commit the game already used |
| Upstream HEAD on 2026-11-17 | `5294518ce7c72e48b6100a744596e0acf57f2826`. The two commits after the pin change only `README.md`, `package.json` (version), `skills/pixelfx/SKILL.md` and `.claude-plugin/plugin.json`; **no effect or renderer changed**, so the pin stays and no versions are mixed |
| `LICENSE` | MIT; "Copyright (c) 2026 Patch", "Copyright (c) 2026 Hugo Duprez". Copied unchanged to `client/assets/fx/pixelfx/LICENSE.txt`; the full text is also in the manifest and the in-game Credits, because the web export drops `.txt` files |
| `NOTICE.md` | Copied unchanged to `client/assets/fx/pixelfx/NOTICE.md`. It names: Hugo Duprez (Sprite Fusion pixel art VFX, MIT) for `src/core/sim.js` and the effects that say so in their own header; Hollow Crown by rehan-remade (MIT) for `src/core/act.js` |
| Excluded font | `gallery/fonts/PatchPixel-Regular.woff2`: "© 2026 Patch. All rights reserved. It is not covered by this repository's MIT license." **Not imported or used.** The renderer (`tools/render.mjs`, `tools/lib/fxlib.mjs`) does not read it, and no gallery file was taken |
| Per-file licences | No effect file carries a licence of its own beyond the "adapted from Sprite Fusion's open-source ... MIT" headers. 183 of 244 effects adapt Sprite Fusion. Each imported effect's authors are read from its own header (`import_pixelfx.py authors()`), and they match for all 62 |
| Hollow Crown | It applies to `act.js`, which animates PixelFX's stock actor. Every effect is rendered with `--no-actor`, but the attribution line keeps the credit, as before |

**Attribution, kept in the manifest, the credits and every record:** "Effects from
pixelfx by Patch (github.com/patch-gg/pixelfx), MIT licence; its particle simulation
adapts Sprite Fusion's pixel art VFX by Hugo Duprez (MIT) and its acting adapts Hollow
Crown by rehan-remade (MIT)."

## 2. How effects are exported (unchanged pipeline)

1. `art/pixelfx/effects.json` lists each game effect id, its PixelFX source, and
   optional trim (`start`/`end`), `stride`, `loop` and `palette`.
2. PixelFX's own renderer, at the pinned commit, writes transparent PNG sheets with JSON:
   `node tools/render.mjs <source> --sheet --no-actor --out <dir>`. `import_pixelfx.py
   --commands <dir>` prints every command.
3. `tools/assets/import_pixelfx.py <dir> <checkout>` crops, trims faded tail frames and
   packs each effect into `client/assets/fx/pixelfx/<id>.png`. The manifest section
   `fx_pixelfx` gets frames, fps, origin, size, columns, loop and authors.
   - New: it refuses a sheet taller than 4096 px, the WebGL texture limit, as it already
     limits width to 2048.
4. **Reproducibility check:** all 62 effects were re-rendered. The 25 effects already in
   the game came out **byte-identical** (sheets, manifest entries, LICENSE and NOTICE),
   so re-importing changed nothing that was there.

## 3. Selection

| Count | Meaning |
|---:|---|
| 244 | effects in PixelFX at the pin (inspected by their `meta` description, size and loop flag) |
| 25 | already in the game (hits, parry, block, slams, heal, level-up, boss effects, shield) and unchanged |
| 46 | rendered and reviewed for this task, at in-game scale next to an LPC class sprite |
| **37** | **selected and imported (PROPOSED uses below)** |
| 9 | rejected after rendering (§3.2) |
| 198 | not rendered: whole attacks with the stock actor (`moves`), screen-wide or non-combat effects (`weather`, `transitions`, `ui`, `pickups`, `critters`), and others not needed now |

### 3.1 Imported (PROPOSED: not wired to any skill yet)

Ids are stable and independent of the PixelFX file names. Gameplay will refer to the
ids only.

| Group | Effect ids (PixelFX source) | Proposed use |
|---|---|---|
| Weapon | `melee_sword_slash` (melee/sword-slash), `melee_double_slash`, `melee_dagger_flurry`, `melee_thrust`, `melee_spear_sweep`, `melee_claw_swipe`, `melee_hammer_smash` | weapon basic attacks and skills: sword or axe, two-hit, rogue daggers, spear, beast and feral, mace |
| Projectile | `proj_arrow`, `proj_magic_missile`, `proj_fireball` (fire/fireball), `proj_ice_lance` (ice/ice-lance) | hunter arrows, arcane, fire and frost bolts. The flying ones loop; moving them needs projectile code, which does not exist yet |
| Fire | `fire_ring`, `fire_pillar`, `fire_meteor` | fire areas; the pillar and meteor are boss-sized |
| Ice | `ice_frost_nova`, `ice_spikes`, `ice_shatter` | frost areas, a frozen target shattering |
| Lightning | `lightning_chain`, `lightning_strike`, `lightning_thunderclap` | shaman lightning, targeted strikes |
| Holy | `holy_smite`, `holy_shield` (loop), `holy_heal_area`, `holy_blessing` (loop) | priest and paladin |
| Shadow | `shadow_tendrils`, `shadow_explosion`, `shadow_drain` (loop) | warlock and boss shadow attacks |
| Nature | `nature_thorns`, `nature_root_snare`, `nature_healing_bloom`, `nature_earth_spike`, `nature_poison_cloud` (loop) | druid and shaman, poison ground |
| Arcane | `arcane_burst`, `arcane_circle` | arcane burst; the large cast circle for bosses |
| Status | `status_stunned`, `status_asleep` (loops over the head) | crowd-control markers |
| Spawn | `spawn_poof` | an enemy appearing or vanishing |

Every new sheet is at most 2048 px wide and 1100 px tall. Every non-looping effect plays
in 4 s or less: long ones are trimmed and kept at half frame rate.

### 3.2 Rejected after rendering

| PixelFX effect | Reason |
|---|---|
| shadow/curse, shadow/life-steal, spawn/respawn-beam, status/frozen, status/poisoned, status/haste, status/burning | Each draws a body silhouette: PixelFX's stock character or the target's outline, even with `--no-actor`. The LPC characters remain the only character art |
| melee/heavy-cleave | Its arc depends on the actor's wind-up; without it the effect does not read |
| explosions/small-explosion | 5.4 s of smoke; duplicates `boss_impact` and `boss_defeat` |

### 3.3 Readability notes (PROPOSED, for when they are wired)

- **`melee_spear_sweep` and `melee_hammer_smash`:** their dust outlasts the strike. When
  wired, trim them further (`end`) so the impact stays the readable part.
- **`arcane_circle`, `fire_pillar`, `lightning_strike` and `fire_meteor`:** they stand
  3–4 times a character's height. Keep them for bosses or large areas, so boss attacks
  stay distinct.
- **Looping effects** (`holy_shield`, `holy_blessing`, `shadow_drain`, the status
  markers, `nature_poison_cloud`, the flying projectiles) play until their holder frees
  them, as the boss shield dome already does.

## 4. Godot integration

- **No JavaScript in the game.** Node runs only offline, to render the sheets. The game
  plays PNG sheets through `AnimatedSprite2D` (`scenes/fx/Fx.gd`), with nearest
  filtering, mirroring around the origin and scaling, as before.
- **On-demand loading (changed in `Fx.gd`, reviewed against its only caller,
  `Fx.spawn`).** The effect library used to build every effect, and load every sheet,
  the first time any effect played.
  - With 62 PixelFX sheets that would be **131.5 MB of texture memory** at the first
    hit.
  - Now `Fx._ensure` adds an effect when it first plays. In typical play only
    **15.3 MB** is loaded.
  - Callers are unchanged. `test_effects.gd` keeps all its checks and builds each effect
    through `_ensure`.
- **Visual data stays separate.** Effects live only in the manifest's `fx_pixelfx`
  section and `art/pixelfx/effects.json`. No skill, move, item, enemy or job file names
  a proposed effect, and removing one leaves the content valid
  (`test_pixelfx_library.gd`).

## 5. Tests and measurements

| Check | Result |
|---|---|
| `test_pixelfx_library.gd`, part 1 | Every sheet loads, fits 4096 px, has alpha, and every frame is mostly transparent |
| `test_pixelfx_library.gd`, part 2 | Every non-loop effect plays in ≤ 4 s |
| `test_pixelfx_library.gd`, part 3 | 8 players × 62 effects spawn and play together |
| `test_pixelfx_library.gd`, part 4 | The library is visual only |
| `test_effects.gd` | Existing PixelFX and credits tests still pass |
| Provenance | `provenance.py check` 0 problems; all 62 PixelFX records VERIFIED and release-ready (MIT, notices shipped) |
| Asset pipeline (pinned Pillow 13.0.0) | `validate.py`: 75 assets, 0 problems |
| Web export | Godot 4.7.2 "Web" preset exports |
| Browser | `tools/web-smoke/smoke.ts` passes in Chromium (WebGL 2 via SwiftShader): boot 2.3 s, combat with hit effects, skill, weapon, pause, travel, street fight |
| **Download size** | **`index.pck` 18.2 MB at HEAD → 29.4 MB now (+11.1 MB, +61%).** The 37 new sheets are 10.3 MB of PNG, which the browser downloads although nothing uses them yet |
| CPU per frame (headless) | 6.79 ms idle and 6.79 ms with 340 effects active: no measurable CPU cost. GPU fill cost was not measurable headless (UNKNOWN) |
| First play of a new effect | about 7 ms each (266 ms for all 37), a possible one-time hitch. Preload per class or area when they are wired |

**Not tested (UNKNOWN):**

- GPU frame time and memory on real devices;
- many online players (the game is single-player until milestone IL-7).

## 6. Owner decisions

1. **Download size:** keep all 37 in the web build now (+11.1 MB), or exclude the
   proposed ones from the "Web" export preset until a skill uses them. They stay in the
   repository and tests either way.
2. **Wiring:** map class skills to these ids once the class skill system exists (Phase 6
   of the reference adoption). That is a visual mapping only; no gameplay value changes.
