# Scene prompts for the street kit (IL-4)

Prompts for painting new street-kit pieces for The Iron Legacy. Paint each piece as
its **own image**. Upload the files to `art/kit/src/` (GitHub → Add file → Upload files)
using the file names below, then ask Claude to import them. `tools/assets/kit_import.py`
cuts them out and validates them, and they are placed in the areas listed here.
Technical rules: [ASSETS.md](ASSETS.md) "Street kit". Story and places:
[STORY_BIBLE.md](STORY_BIBLE.md).

## Rules for every piece (do not skip, or the importer cannot cut the piece out)

1. **Flat bright green backdrop** (#00FF00), with no gradient, shadow or floor on the
   backdrop. Leave at least 5% margin around the piece.
2. **Dark outline** around the whole piece, like the pieces already in the game.
3. **Straight-on front view** (facades, fences, walls), or a light 3/4 view for small
   props. Same lighting as the existing kit: a Bangkok night, warm lamp light from the
   upper left.
4. **No real brands, no logos, and no text of any kind** (signs stay blank; the game
   draws Thai text itself). No Buddha images.
5. **No people or animals** in the piece (characters are drawn by the game). The
   Fight Club crowd is the one exception, as dark silhouettes only.
6. File size up to 1400 px on the long side, saved as JPG or PNG.

## Shared style block (start every prompt with this)

```
HD-2D painted game asset, Octopath Traveler style environment piece, hand-painted
texture with visible brush detail, clean dark outline around the whole object,
single isolated object centered on a flat pure green (#00FF00) background, no ground
shadow, no other objects, straight-on front view, Bangkok at night, warm street-lamp
light from upper left, cool blue ambient fill, slightly worn and lived-in, no text,
no logos, no people
```

## 1. Fight Club: a ring in the alley behind the Night Market (`fight_club`, level 7)

Purpose: the area is still drawn as an ordinary street. These pieces turn it into an
underground fight ring with corrugated walls and work lamps.

| File | Height in game | Prompt (after the shared block) |
|---|---|---|
| `warehouse_wall.jpg` | 190 px | `wide back wall of an old Thai warehouse, rusted corrugated metal sheets on a concrete base, one rolled-up shutter door half open with darkness inside, exposed pipes and a fuse box, faded paint, water stains` |
| `ring_ropes.jpg` | 60 px | `side section of an improvised street boxing ring, three red and white ropes wrapped with tape, two padded corner posts, old tyres stacked at the posts, seen straight from the side` |
| `crowd_silhouettes.jpg` | 70 px | `row of standing spectators as dark silhouettes only, no faces or details, some with raised fists, back-lit by warm light, a long horizontal strip` |
| `work_lamp_string.jpg` | 40 px | `string of hanging bare-bulb work lamps on a sagging cable, warm yellow glow around each bulb, long horizontal strip` |
| `tyre_stack.jpg` | 34 px | `stack of four worn car tyres, slightly leaning` |
| `chair_pile.jpg` | 36 px | `pile of folding metal chairs and plastic stools, tangled together` |

## 2. Rusted Corner: a junk-dealers' corner (`rusted_corner`, level 3)

| File | Height in game | Prompt |
|---|---|---|
| `junk_shop.jpg` | 150 px | `front of a Thai scrap-dealer shophouse, two storeys, rolled-up rusty shutter, scrap metal, bicycle wheels and copper wire bundles piled at the entrance, hand-painted blank sign board, hanging bare bulb` |
| `rusted_fence.jpg` | 60 px | `long section of rusted corrugated metal fence with patches, holes and a chained gate, plants growing at the base` |
| `scrap_pile.jpg` | 38 px | `heap of scrap metal, bent pipes, old car door and oil drum parts` |
| `oil_drums.jpg` | 34 px | `three rusty oil drums, one tipped over` |
| `car_wreck.jpg` | 40 px | `rusted wreck of a small old Japanese sedan with no wheels, on blocks, side view` |

## 3. Parking Lot (planned, IL-4 part 2)

| File | Height in game | Prompt |
|---|---|---|
| `carpark_facade.jpg` | 190 px | `side of a five-storey concrete multi-storey car park, open decks with railings, a few parked car silhouettes inside, ramps, fluorescent tube lights, stained concrete` |
| `barrier_booth.jpg` | 60 px | `small car park ticket booth with a red and white barrier arm, glass window, blank sign` |
| `pickup_truck.jpg` | 40 px | `Thai-style pickup truck with a metal canopy on the back, side view` |
| `motorbike_row.jpg` | 32 px | `row of four parked scooters side by side, side view` |

## 4. Rat Nest: drainage tunnels (planned)

| File | Height in game | Prompt |
|---|---|---|
| `tunnel_wall.jpg` | 190 px | `wide wall of an old brick drainage tunnel, arched ceiling sections, moss and green-grey stains, dripping water, rusted ladder, a large round drain outlet in the middle` |
| `sewer_pipe.jpg` | 50 px | `big rusty drain pipe coming out of a wall with murky water trickling out` |
| `drain_grate.jpg` | 30 px | `rusted floor grate with dark water below, slight 3/4 view` |
| `tunnel_floor_tile.jpg` | tile | `seamless tile of wet concrete tunnel floor with a shallow water channel, top-down, tileable left to right` |

## 5. Gang Headquarters (planned, end of Chapter 1)

| File | Height in game | Prompt |
|---|---|---|
| `gang_hq_facade.jpg` | 200 px | `front of a run-down three-storey building turned into a gang headquarters, heavy steel gate, barred windows, a blank neon sign frame with no letters, CCTV cameras, guards' plastic chairs by the door` |
| `steel_gate.jpg` | 70 px | `heavy sliding steel gate with spikes on top, partly open` |
| `guard_booth.jpg` | 60 px | `small concrete guard booth with a window and a fan, blank sign` |

Status: all 22 pieces above are painted and imported. Fight Club and Rusted Corner use
them (kit themes `fight_club` and `junkyard`); the Parking Lot, Rat Nest and Gang HQ
pieces wait for those areas.

## After painting

1. Upload the files to `art/kit/src/` in a new PR, or send them to Claude in a cloud
   session.
2. Claude adds them to `art/kit/kit.json` (height and options, e.g. `haze` for warm
   glows), creates themes for `fight_club` and `rusted_corner` (with `kit_theme` in
   `areas.json`), runs `kit_import.py`, and checks a screenshot in the browser.
3. The validator checks the pieces in CI on every PR.
