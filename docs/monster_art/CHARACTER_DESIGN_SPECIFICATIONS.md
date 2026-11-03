# Character design specifications (monster art, Phase C)

One design per enemy, to approve **before** any sprite is generated. Each LPC
design names the generator's own definitions (paths under `sheet_definitions/`
at the pinned commit `9bf06be193b053db256b2536824af426de046aa2`, as
`art/lpc/characters.json` already uses them) and colours from the generator's
`ulpc` palettes. Every part named below was checked **for the male body's file**
at that commit and is offered under CC0 or OGA-BY 3.0/3.0+ (method:
[LPC_GENERATOR_AUDIT.md](LPC_GENERATOR_AUDIT.md)); female-body files are checked
again when built. The build (`tools/assets/lpc_build.py`) re-checks every file it
uses and refuses anything else. Faction rules: [FACTION_STYLE_GUIDE.md](FACTION_STYLE_GUIDE.md).

**Common to every LPC enemy**
- Body type `male` (Dock Slinger `female`), adult, LPC 64×64 frames, the
  generator's outline and shading, drawn with nearest filtering.
- Animations the game needs (manifest rows, built from LPC moves by the existing
  recipe file's `animations`): idle, walk, light, heavy, stab, swing, hurt, down,
  dodge. Required by `tools/assets/validate.py`: idle, walk, light, hurt, down
  (bosses also heavy). The frame layout stays the one `lpc_build.py` writes, so
  `FighterView` needs no change.
- `scale` (relative size) stays as in `client/data/enemies.json`; it is drawing
  only. Changing a scale is not part of this work.
- **Kept parts** are the current recipe's; only the parts listed under
  "Change" differ. "Dead layer" = a recipe part that is never drawn today (see
  [ENEMY_INVENTORY.md](ENEMY_INVENTORY.md)); it is dropped, which changes nothing
  on screen.

## South Street Gang (accent red; the Baron's people in maroon)

| Enemy (rank, scale) | Head, skin, hair | Clothing (part: colour) | Equipment | Silhouette and rank | Change |
|---|---|---|---|---|---|
| `dock_thug` (enemy, 1.0) | `heads_human_male`, light, trimmed beard dark_brown | tshirt: gray; pants2: brown; boots basic: black; bandana: red | street weapons only (game) | stocky, red bandana | none (KEEP) |
| `street_thrower` (enemy, 1.0) | human male, olive, plain hair black | tshirt: gray; pants: charcoal; shoes basic: white; bandana: red | throws bottles (game) | slim, red bandana | drop the dead open-vest layer (KEEP) |
| `market_punk` (enemy, 1.0) | human male, amber, **hair_halfmessy: pink** (was spiked, CC-BY 4.0) | longsleeve2: purple; cuffed: black; shoes basic: white | — | slim, pink hair | hair; drop the dead open-vest layer |
| `pipe_brute` (enemy, 1.2) | **human male, bronze, buzzcut black, medium beard black** (was orc head, green skin) | suspenders: brown; pants: walnut; boots rimmed: brown; **bandana: red** | pipe (game) | broad, bare arms, red bandana | head, skin, hair, beard, bandana |
| `rail_bruiser` (enemy, 1.15) | human male, bronze, buzzcut black, medium beard black | sleeveless2: white; overalls: navy; pants: charcoal; boots rimmed: black | — | heavy, overalls | none (KEEP) |
| `refinery_enforcer` (elite, 1.15) | human male, taupe, plain hair dark_brown, headband thick: **maroon** | longsleeve2: charcoal; **leather armour** (was legion armour); **gloves: black**; pants: charcoal (was armoured legs); boots basic: black | — | the Baron's maroon headband, work armour | armour, legs, gloves, headband colour |
| `pit_champion` (mini-boss, 1.3) | human male, brown, buzzcut black, headband thick: orange | shorts: charcoal | — | bare-chested fighter | none (KEEP) |
| `furnace_baron` (boss, 1.3) | human male, brown, balding gray, walrus moustache gray; **no hat** (was `cap_leather`) | longsleeve2 buttoned: maroon; **apron (`torso_aprons_apron`): leather** (smelter's apron; replaces the dead trench layer; the full apron exists only for the female body); pants: black; boots rimmed: brown; **gloves: black** | — | foundry boss: maroon shirt under a heavy leather apron, the only apron in the gang | hat removed, apron and gloves added, dead trench dropped |

Painted members (owner decision, see the style guide): `smogling`, `tar_hound`
(Tar Rat), `smog_warden` (elite), `sludge_foreman` (boss). **Option 1 (keep
painted):** no change; their current painted designs stand (Story Bible §6).
**Option 2 (LPC):** Smogling: human male gaunt head, olive skin, **hood cloth: yellow**,
plain face mask, longsleeve2: yellow, pants: charcoal; Tar Rat: human male, hood
cloth: black, plain face mask, tshirt: black, pants: slate (the rat mask cannot be
made in LPC; `heads_rat` is an animal head and is not used on people); Smog Warden:
human male, hood cloth: gray, plain face mask, longsleeve2: gray, pants: gray,
gloves: black (the skeleton print and twin-filter mask cannot be made in LPC);
Sludge Foreman: human male, bronze, buzzcut, medium beard, suspenders: brown,
pants: charcoal, boots rimmed, plain face mask (the boar mask cannot be made in
LPC: `heads_boarman` is not licence-eligible). Option 2 loses each one's mask,
which the story describes, so the audit recommends option 1.

## Port Dock Crew (accent orange)

| Enemy (rank, scale) | Head, skin, hair | Clothing (part: colour) | Equipment | Silhouette and rank | Change |
|---|---|---|---|---|---|
| `stevedore` (enemy, 1.2) | human male, bronze, buzzcut black, trimmed beard black | sleeveless2: orange; pants: navy; boots basic: black | — | broad, orange top | none (KEEP) |
| `dock_slinger` (enemy, 1.0) | `heads_human_female`, olive, high ponytail black | tshirt: teal; pants: slate; shoes basic: white | throws wrenches (game) | slim, teal | none (KEEP) |
| `dock_thug` | (South Street Gang, above) | | | | |
| `port_guard` (elite, 1.1) | human male, light, plain hair black, **bandana2: orange** | longsleeve2 buttoned: navy; pants: charcoal; boots basic: black; **gloves: black** | — | navy uniform shirt, orange bandana: the port's guard | bandana, gloves |
| `harbourmaster_chen` (boss, 1.3) | human male, light, plain hair gray, trimmed beard gray, **plain glasses** | **longsleeve2 buttoned: navy** (was white polo) with **jacket pockets trim** (`torso_jacket_pockets`); pants: black; boots basic: black | — | the only crew member in a navy officer's shirt with jacket pockets and glasses | shirt, glasses, jacket trim |

## Plant Security (accent yellow)

| Enemy (rank, scale) | Head, skin, hair | Clothing (part: colour) | Equipment | Silhouette and rank | Change |
|---|---|---|---|---|---|
| `plant_guard` (elite, 1.1) | human male, light, buzzcut black, **headband tied: yellow** | longsleeve2 buttoned: slate; pants: gray; boots basic: black; **gloves: black** | — | slate uniform, yellow band | headband, gloves |
| `hazmat_sprayer` (enemy, 1.0) | human male, olive, `hat_helmet_xeon` | longsleeve2: yellow; pants: yellow; boots basic: black | sprayer (game) | yellow suit, helmet | none (KEEP) |
| `security_chief` (boss, 1.2) | human male, bronze, plain hair black, trimmed beard black, **plain glasses** | longsleeve2 buttoned: black; **leather armour** over it; pants: charcoal; boots basic: black; gloves: black | — | black shirt and body armour: the plant's only officer | glasses, armour, gloves |

## The Black Network (accent purple)

| Enemy (rank, scale) | Head, skin, hair | Clothing (part: colour) | Equipment | Silhouette and rank | Change |
|---|---|---|---|---|---|
| `network_runner` (enemy, 1.0) | human male, light, plain hair black, **no hat** (was `cap_leather`), **hood cloth: purple** | tshirt: purple; pants2: black; shoes basic: white | — | hooded courier | hood replaces the fantasy cap |
| `network_enforcer` (enemy, 1.15) | human male, taupe, balding black, walrus moustache black | longsleeve2 buttoned: white; pants: charcoal; boots basic: black | — | heavy, white shirt | drop the dead open-vest layer (KEEP) |
| `ring_fighter` (elite, 1.1) | human male, brown, **curly short: black** (was spiked, CC-BY 4.0), headband thick: red | shorts: maroon; shoes basic: black | — | bare-chested ring fighter | hair |
| `ringmaster` (boss, 1.25) | human male, amber, plain hair black, trimmed beard black | longsleeve2 buttoned: red; **leather armour: black**; cuffed: black; boots rimmed: black; **gloves: black** | — | red shirt under black leather: the ring's owner | armour and gloves; dead tabard dropped |
| `big_sak` (boss, 1.45) | human male, olive, buzzcut black, medium beard black, glasses | longsleeve2: maroon; pants: black; boots rimmed: black | — | the network's boss | dead trench dropped (KEEP) |

## Facility Security (helmets; accent white)

| Enemy (rank, scale) | Head, skin, hair | Clothing (part: colour) | Equipment | Silhouette and rank | Change |
|---|---|---|---|---|---|
| `facility_trooper` (enemy, 1.0) | human male, light, `hat_helmet_xeon` | longsleeve2: slate; leather armour; pants: slate; boots basic: black | — | helmet, light armour | none (KEEP) |
| `riot_trooper` (elite, 1.15) | human male, bronze, `hat_helmet_xeon` | longsleeve2: charcoal; **leather armour** (was plate); **bracers** (`arms_bracers`; LPC's arm armour is medieval plate and is not used); pants: charcoal (was armoured legs); boots rimmed: black; gloves: black | — | heavier armour and bracers than the trooper | plate replaced; bracers, gloves |
| `commander_arthit` (boss, 1.35) | human male, taupe, plain hair gray, trimmed beard gray | longsleeve2 buttoned: **bluegray**; **leather armour** (was legion); **shoulders epaulets**; cuffed: bluegray; boots rimmed: black | — | officer: no helmet, epaulets | armour, epaulets, colour |

## Hybrids (victims)

People made ill by The Core. Pale skin and a gaunt face; their work clothes,
worn. No orc heads, no claws, no weapons drawn on them.

| Enemy (rank, scale) | Head, skin, hair | Clothing (part: colour) | Silhouette | Change |
|---|---|---|---|---|
| `hybrid_worker` (enemy, 1.15) | **`heads_human_male_gaunt`, skin `pale_green`**, balding gray | overalls: teal; pants: forest; boots basic: brown | a sick canal worker | head and skin (was orc, green) |
| `subject_twelve` (boss, 1.4) | gaunt head, `pale_green`, buzzcut gray | sleeveless2: white; pants2: white; boots basic: black | lab-issue whites, larger | head and skin |
| `hybrid_brute` (enemy, 1.25) | gaunt head, `pale_green`, **halfmessy: gray** (was spiked, CC-BY 4.0) | sleeveless2: red; pants: charcoal; boots basic: black | the longest exposed, heavier | head, skin, hair |
| `subject_zero` (world boss, 2.3) | gaunt head, `pale_green`, **halfmessy: white** (was spiked) | sleeveless2: white; pants2: white; bare feet | the first Hybrid, huge and alone | head, skin, hair |

Owner check: whether `pale_green` reads as "ill" rather than "monster" can only be
judged on the built sprites (Phase 8 comparison sheet).

## Machines (non-LPC art needed)

LPC has no robots. Each needs art from another source: drawn in LPC style (64×64
frames, the same outline, the same animation rows: idle, walk, light, heavy, stab,
swing, hurt, down, dodge), commissioned, or found under CC0/OGA-BY. Designs:

| Enemy (rank, scale) | Design |
|---|---|
| `patrol_unit` (enemy, 1.2) | waist-high tracked or two-legged patrol machine, steel gray with a yellow plant hazard stripe, one red sensor light; first Machine (Story Bible) |
| `unit_k7` (boss, 1.45) | the same family as the Patrol Unit, larger, with steam vents (it erupts the floor's steam vents); hazard yellow |
| `core_sentinel` (elite, 1.25) | humanoid security robot Wiroj built: facility white plates over black, a single horizontal visor light |
| `iron_colossus` (world boss, 2.2) | Kraisorn's prototype walking security robot, older than the Sentinel: rusted steel, heavy frame, the Sentinel's ancestor in shape |

## Creature (non-LPC art needed)

| Enemy (rank, scale) | Design |
|---|---|
| `tunnel_mother` (world boss, 2.0) | a huge mutant grown from The Core's waste in the drains: low, wide, tar-black with sludge-green glow, many limbs; summons Tar Rats. Not a person, so not LPC |

## Director

| Enemy (rank, scale) | Head, skin, hair | Clothing | Change |
|---|---|---|---|
| `director_wiroj` (final boss, 1.3) | `heads_human_male_elderly`, light, plain hair gray, glasses | longsleeve2 buttoned: white; cuffed: charcoal; boots rimmed: black | dead trench dropped (KEEP) |

## Training dummy

`training_dummy` (prop, 1.0): drawn by `tools/assets/gen_dummy.py`; not a faction
member. No change.
