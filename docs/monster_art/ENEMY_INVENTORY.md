# Enemy inventory (monster art audit, Phase A and B)

Audit of every enemy in the game as the repository has it on 2026-11-03 (working
tree, uncommitted). Nothing in the game was changed for this audit. The factual
tables are generated from `client/data/enemies.json`, `client/data/areas.json`,
`client/data/world_boss.json`, `client/assets/manifest.json`,
`art/lpc/characters.json` and each enemy's `credits.json`; nothing in them is
typed by hand. The classification and its reasons below the tables are the
audit's judgement, made from the sprites themselves (contact sheet of every
idle frame at its in-game scale) and from [STORY_BIBLE.md](../STORY_BIBLE.md).

## How an enemy is put together (applies to all 38)

- **No scene per enemy.** Every fighter, hero or enemy, is drawn by
  `client/scenes/fighter/FighterView.gd` from its manifest entry: the sheet
  (`sheet.png`, one row per game animation), a Godot `SpriteFrames` resource
  (`<id>.tres`, made by `tools/assets/make_spriteframes.py`), the feet origin and,
  for held weapons, `hands.png` (the fist position per frame).
- **Collision and hitboxes do not come from the art.** Bodies and hurt boxes are
  the same for every fighter (`client/sim/Bodies.gd`, `CombatRules`), reach and
  timing come from each move in `client/data/moves.json` (the enemy's `moveset`).
  The `scale` in `enemies.json` is applied only by `FighterView` (drawing), so a
  new sprite changes neither combat nor collision.
- **Behaviour** is `ai` (and `ranged`, `summon`, `phases`, `hazard` for some)
  in `enemies.json`, read by `client/sim/EnemyBrain.gd` and `BossMechanics.gd`.
- **Sources:** `lpc` = built by `tools/assets/lpc_build.py` from the Universal
  LPC Spritesheet Character Generator's own asset files and definitions at the
  pinned commit `9bf06be193b053db256b2536824af426de046aa2` (recipes in
  `art/lpc/characters.json`); `custom` = painted by the project owner and imported
  by `tools/assets/custom_import.py` from `art/custom/<id>/`; `original` = drawn
  by the project's own code (`tools/assets/gen_dummy.py`).
- **Totals:** 38 enemies: 33 `lpc`, 4 `custom`, 1 `original`. 14 bosses (3 of them
  world bosses), 7 elites, 1 training dummy, 16 ordinary enemies. 28 are drawn
  scaled (27 by a fraction, 1 by exactly 2).

## Inventory

| Enemy ID | Name | Role | Districts | Where it fights | Source | Frame (px) | Scale | Animations (frames) | Credit rows: licences |
|---|---|---|---|---|---|---|---|---|---|
| `training_dummy` | Training Dummy | training | South Street | Depot Yard; Iron City Central (city) | original | 112×64 | 1.0 | down 5, hurt 4, idle 2, light 1, walk 2 | MIT ×1 |
| `smogling` | Smogling | enemy | South Street, Industrial District | Saltmarket Street; Canal Works; Rail Yards; Rat Nest; Waste Pools; Factory Drains; Saltmarket Backlots (farm) | custom | 80×80 | 1.0 | down 5, heavy 9, hurt 3, idle 10, light 9, stab 5, walk 8 | Proprietary (project owner) ×1 |
| `tar_hound` | Tar Rat | enemy | South Street | Saltmarket Street; Canal Works; Rusted Corner; Parking Lot; Rail Yards; Rat Nest; Saltmarket Backlots (farm); summoned by tunnel_mother | custom | 80×80 | 1.0 | down 4, heavy 6, hurt 3, idle 7, light 6, stab 5, walk 2 | Proprietary (project owner) ×1 |
| `pipe_brute` | Pipe Brute | enemy | South Street | Saltmarket Street; Canal Works; Rusted Corner; Parking Lot; Rat Nest; Saltmarket Backlots (farm) | lpc | 64×64 | 1.2 | down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×4, OGA-BY 3.0+ ×1 |
| `smog_warden` | Smog Warden | elite | South Street, Industrial District | Saltmarket Street; Canal Works; Rusted Corner; Night Market; Rat Nest; Waste Pools; Factory Drains; Saltmarket Backlots (farm) | custom | 80×80 | 1.25 | down 4, heavy 6, hurt 3, idle 8, light 5, stab 5, walk 10 | Proprietary (project owner) ×1 |
| `sludge_foreman` | The Sludge Foreman | boss | South Street | Canal Works | custom | 80×80 | 1.5 | down 5, heavy 6, hurt 3, idle 8, light 4, stab 3, walk 10 | Proprietary (project owner) ×1 |
| `dock_thug` | Dock Thug | enemy | South Street, Port District | Rusted Corner; Parking Lot; Rail Yards; Night Market; Smokestack Refinery; Gang Headquarters; Port Road; Rail Sidings (farm); Harbour Stacks (farm) | lpc | 64×64 | 1.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×8 |
| `rail_bruiser` | Rail Bruiser | enemy | South Street, Port District | Parking Lot; Rail Yards; Night Market; Fight Club; Smokestack Refinery; Gang Headquarters; Port Road; Rail Sidings (farm) | lpc | 64×64 | 1.15 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7, OGA-BY 3.0+ ×1 |
| `market_punk` | Night Market Punk | enemy | South Street, Port District | Night Market; Fight Club; Smokestack Refinery; Gang Headquarters; Freight Market; Rail Sidings (farm) | lpc | 64×64 | 1.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | CC-BY 4.0 ×1, OGA-BY 3.0 ×6 |
| `refinery_enforcer` | Refinery Enforcer | elite | South Street, Port District | Smokestack Refinery; Gang Headquarters; Freight Market; Rail Sidings (farm) | lpc | 64×64 | 1.15 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7, OGA-BY 3.0+ ×1 |
| `furnace_baron` | The Furnace Baron | boss | South Street | Gang Headquarters | lpc | 64×64 | 1.3 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7, OGA-BY 3.0+ ×1 |
| `street_thrower` | Bottle Thrower | enemy | South Street | Rusted Corner; Parking Lot; Fight Club; Saltmarket Backlots (farm) | lpc | 64×64 | 1.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `pit_champion` | The Pit Champion | boss | South Street | Fight Club | lpc | 64×64 | 1.3 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×5, OGA-BY 3.0+ ×1 |
| `stevedore` | Stevedore | enemy | Port District, Industrial District | Port Road; Freight Market; Container Yard; Crane Yard; Factory Gate; Production Line; Harbour Stacks (farm) | lpc | 64×64 | 1.2 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `port_guard` | Port Guard | elite | Port District, Industrial District | Port Road; Freight Market; Container Yard; Crane Yard; Factory Gate; Harbour Stacks (farm) | lpc | 64×64 | 1.1 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×6 |
| `dock_slinger` | Dock Slinger | enemy | Port District, The Black Network, The Core Facility, Main Control Centre | Port Road; Freight Market; Container Yard; Crane Yard; Warehouse Row; The Counting House; Core Facility Gate; Core Approach; Cooling Tunnels; Harbour Stacks (farm) | lpc | 64×64 | 1.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `harbourmaster_chen` | Harbourmaster Chen | boss | Port District | Crane Yard | lpc | 64×64 | 1.3 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `plant_guard` | Plant Guard | elite | Industrial District | Factory Gate; Production Line; Waste Pools; Plant Outskirts (farm) | lpc | 64×64 | 1.1 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×6 |
| `hazmat_sprayer` | Hazmat Sprayer | enemy | Industrial District, The Black Network, The Core Facility, Main Control Centre | Factory Gate; Production Line; Waste Pools; Factory Drains; Warehouse Row; The Counting House; Core Facility Gate; Test Labs; Machine Hall; Core Approach; Cooling Tunnels; Reactor Walkway; Plant Outskirts (farm); Facility Annex (farm) | lpc | 64×64 | 1.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×6 |
| `patrol_unit` | Patrol Unit | enemy | Industrial District, The Core Facility | Production Line; Waste Pools; Factory Drains; Core Facility Gate; Machine Hall; Plant Outskirts (farm); Facility Annex (farm); Core Overflow (farm) | lpc | 64×64 | 1.2 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×5 |
| `security_chief` | Security Chief Nattapong | boss | Industrial District | Production Line | lpc | 64×64 | 1.2 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `unit_k7` | Unit K-7 | boss | Industrial District | Factory Drains | lpc | 64×64 | 1.45 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×5 |
| `network_runner` | Network Runner | enemy | The Black Network | Warehouse Row; The Underground Ring; The Counting House; Rattanachai Tower; Network Backrooms (farm); summoned by big_sak | lpc | 64×64 | 1.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×8 |
| `network_enforcer` | Network Enforcer | enemy | The Black Network, The Core Facility | Warehouse Row; The Underground Ring; The Counting House; Rattanachai Tower; Core Facility Gate; Network Backrooms (farm) | lpc | 64×64 | 1.15 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `ring_fighter` | Ring Fighter | elite | The Black Network | The Underground Ring; The Counting House; Rattanachai Tower; Network Backrooms (farm) | lpc | 64×64 | 1.1 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | CC-BY 4.0 ×1, OGA-BY 3.0 ×5, OGA-BY 3.0+ ×1 |
| `ringmaster` | The Ringmaster | boss | The Black Network | The Underground Ring | lpc | 64×64 | 1.25 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7, OGA-BY 3.0+ ×1 |
| `big_sak` | Big Sak | boss | The Black Network | Rattanachai Tower | lpc | 64×64 | 1.45 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7, OGA-BY 3.0+ ×1 |
| `facility_trooper` | Facility Trooper | enemy | The Core Facility, Main Control Centre | Core Facility Gate; Test Labs; Machine Hall; Control Room; Core Approach; Cooling Tunnels; Reactor Walkway; The Core Chamber; Facility Annex (farm); Core Overflow (farm); summoned by commander_arthit | lpc | 64×64 | 1.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `riot_trooper` | Riot Trooper | elite | The Core Facility, Main Control Centre | Core Facility Gate; Machine Hall; Control Room; Core Approach; Reactor Walkway; The Core Chamber; Facility Annex (farm) | lpc | 64×64 | 1.15 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×6, OGA-BY 3.0+ ×1 |
| `hybrid_worker` | Hybrid Worker | enemy | The Core Facility, Main Control Centre | Test Labs; Machine Hall; Control Room; Core Approach; Cooling Tunnels; Reactor Walkway; The Core Chamber | lpc | 64×64 | 1.15 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×6 |
| `subject_twelve` | Subject 12 | boss | The Core Facility | Test Labs | lpc | 64×64 | 1.4 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `commander_arthit` | Commander Arthit | boss | The Core Facility | Control Room | lpc | 64×64 | 1.35 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×8, OGA-BY 3.0+ ×1 |
| `core_sentinel` | Core Sentinel | elite | Main Control Centre | Core Approach; Reactor Walkway; The Core Chamber; Core Overflow (farm); summoned by iron_colossus | lpc | 64×64 | 1.25 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×5 |
| `hybrid_brute` | Hybrid Brute | enemy | Main Control Centre | Cooling Tunnels; Reactor Walkway; summoned by subject_zero | lpc | 64×64 | 1.25 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | CC-BY 4.0 ×1, OGA-BY 3.0 ×5 |
| `director_wiroj` | Director Wiroj | boss | Main Control Centre | The Core Chamber | lpc | 64×64 | 1.3 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7, OGA-BY 3.0+ ×1 |
| `tunnel_mother` | The Tunnel Mother | boss | World boss | The Great Drain (world boss arena) | lpc | 64×64 | 2.0 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×7 |
| `iron_colossus` | The Iron Colossus | boss | World boss | The Old Scrapyard (world boss arena) | lpc | 64×64 | 2.2 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | OGA-BY 3.0 ×5 |
| `subject_zero` | Subject Zero | boss | World boss | The Sunken Reservoir (world boss arena) | lpc | 64×64 | 2.3 | dodge 5, down 6, heavy 8, hurt 3, idle 3, light 6, stab 5, swing 6, walk 8 | CC-BY 4.0 ×1, OGA-BY 3.0 ×5 |

## Files and behaviour references

| Enemy ID | Sheet | Credits file | Moveset | AI | Summons |
|---|---|---|---|---|---|
| `training_dummy` | `client/assets/characters/training_dummy/sheet.png` | `client/assets/characters/training_dummy/credits.json` | — | — | — |
| `smogling` | `client/assets/characters/smogling/sheet.png` | `client/assets/characters/smogling/credits.json` | light: smog_swipe | {'spacing': 56, 'reaction': 14, 'cooldown': 50, 'cooldown_jitter': 40, 'heavy_chance': 0} | — |
| `tar_hound` | `client/assets/characters/tar_hound/sheet.png` | `client/assets/characters/tar_hound/credits.json` | light: hound_lunge | {'spacing': 70, 'reaction': 8, 'cooldown': 40, 'cooldown_jitter': 30, 'heavy_chance': 0} | — |
| `pipe_brute` | `client/assets/characters/pipe_brute/sheet.png` | `client/assets/characters/pipe_brute/credits.json` | light: brute_jab, heavy: brute_slam | {'spacing': 64, 'reaction': 18, 'cooldown': 70, 'cooldown_jitter': 40, 'heavy_chance': 0.4, 'heavy_cooldown': 270} | — |
| `smog_warden` | `client/assets/characters/smog_warden/sheet.png` | `client/assets/characters/smog_warden/credits.json` | light: warden_rake, heavy: warden_crush | {'spacing': 60, 'reaction': 10, 'cooldown': 40, 'cooldown_jitter': 30, 'heavy_chance': 0.35, 'heavy_cooldown': 300} | — |
| `sludge_foreman` | `client/assets/characters/sludge_foreman/sheet.png` | `client/assets/characters/sludge_foreman/credits.json` | light: foreman_jab, heavy: foreman_wrench | {'spacing': 66, 'reaction': 12, 'cooldown': 37, 'cooldown_jitter': 30, 'heavy_chance': 0.35, 'heavy_cooldown': 300, 'grab': {'chance': 0.35, 'every': 300, 'range': 140}} | — |
| `dock_thug` | `client/assets/characters/dock_thug/sheet.png` | `client/assets/characters/dock_thug/credits.json` | light: thug_jab, heavy: thug_kick | {'spacing': 50, 'reaction': 12, 'cooldown': 50, 'cooldown_jitter': 30, 'heavy_chance': 0.25, 'heavy_cooldown': 270} | — |
| `rail_bruiser` | `client/assets/characters/rail_bruiser/sheet.png` | `client/assets/characters/rail_bruiser/credits.json` | light: brute_jab, heavy: brute_slam | {'spacing': 64, 'reaction': 16, 'cooldown': 64, 'cooldown_jitter': 36, 'heavy_chance': 0.4, 'heavy_cooldown': 300} | — |
| `market_punk` | `client/assets/characters/market_punk/sheet.png` | `client/assets/characters/market_punk/credits.json` | light: punk_flurry, heavy: thug_kick | {'spacing': 46, 'reaction': 8, 'cooldown': 40, 'cooldown_jitter': 30, 'heavy_chance': 0.2, 'heavy_cooldown': 270} | — |
| `refinery_enforcer` | `client/assets/characters/refinery_enforcer/sheet.png` | `client/assets/characters/refinery_enforcer/credits.json` | light: warden_rake, heavy: brute_slam | {'spacing': 56, 'reaction': 12, 'cooldown': 48, 'cooldown_jitter': 24, 'heavy_chance': 0.35, 'heavy_cooldown': 300} | — |
| `furnace_baron` | `client/assets/characters/furnace_baron/sheet.png` | `client/assets/characters/furnace_baron/credits.json` | light: baron_haymaker, heavy: baron_furnace | {'spacing': 60, 'reaction': 12, 'cooldown': 35, 'cooldown_jitter': 20, 'heavy_chance': 0.3, 'heavy_cooldown': 330, 'grab': {'chance': 0.4, 'every': 300, 'range': 160}} | — |
| `street_thrower` | `client/assets/characters/street_thrower/sheet.png` | `client/assets/characters/street_thrower/credits.json` | light: thug_jab, heavy: bottle_lob | {'spacing': 110, 'reaction': 14, 'cooldown': 70, 'cooldown_jitter': 30, 'heavy_chance': 1.0, 'heavy_cooldown': 120, 'ranged': {'min': 80, 'max': 150}} | — |
| `pit_champion` | `client/assets/characters/pit_champion/sheet.png` | `client/assets/characters/pit_champion/credits.json` | light: champ_jab, heavy: champ_overhand | {'spacing': 50, 'reaction': 8, 'cooldown': 27, 'cooldown_jitter': 18, 'heavy_chance': 0.3, 'heavy_cooldown': 300, 'grab': {'chance': 0.2, 'every': 360, 'range': 120}} | — |
| `stevedore` | `client/assets/characters/stevedore/sheet.png` | `client/assets/characters/stevedore/credits.json` | light: brute_jab, heavy: brute_slam | {'spacing': 64, 'reaction': 16, 'cooldown': 62, 'cooldown_jitter': 36, 'heavy_chance': 0.4, 'heavy_cooldown': 300} | — |
| `port_guard` | `client/assets/characters/port_guard/sheet.png` | `client/assets/characters/port_guard/credits.json` | light: warden_rake, heavy: thug_kick | {'spacing': 56, 'reaction': 10, 'cooldown': 46, 'cooldown_jitter': 24, 'heavy_chance': 0.3, 'heavy_cooldown': 300} | — |
| `dock_slinger` | `client/assets/characters/dock_slinger/sheet.png` | `client/assets/characters/dock_slinger/credits.json` | light: thug_jab, heavy: bottle_lob | {'spacing': 110, 'reaction': 12, 'cooldown': 64, 'cooldown_jitter': 30, 'heavy_chance': 1.0, 'heavy_cooldown': 120, 'ranged': {'min': 80, 'max': 150}} | — |
| `harbourmaster_chen` | `client/assets/characters/harbourmaster_chen/sheet.png` | `client/assets/characters/harbourmaster_chen/credits.json` | light: chen_jab, heavy: chen_hook | {'spacing': 62, 'reaction': 12, 'cooldown': 34, 'cooldown_jitter': 20, 'heavy_chance': 0.3, 'heavy_cooldown': 330, 'grab': {'chance': 0.3, 'every': 330, 'range': 140}} | — |
| `plant_guard` | `client/assets/characters/plant_guard/sheet.png` | `client/assets/characters/plant_guard/credits.json` | light: warden_rake, heavy: brute_slam | {'spacing': 56, 'reaction': 10, 'cooldown': 46, 'cooldown_jitter': 24, 'heavy_chance': 0.3, 'heavy_cooldown': 300} | — |
| `hazmat_sprayer` | `client/assets/characters/hazmat_sprayer/sheet.png` | `client/assets/characters/hazmat_sprayer/credits.json` | light: thug_jab, heavy: bottle_lob | {'spacing': 110, 'reaction': 12, 'cooldown': 60, 'cooldown_jitter': 30, 'heavy_chance': 1.0, 'heavy_cooldown': 120, 'ranged': {'min': 80, 'max': 150}} | — |
| `patrol_unit` | `client/assets/characters/patrol_unit/sheet.png` | `client/assets/characters/patrol_unit/credits.json` | light: k7_piston, heavy: brute_slam | {'spacing': 60, 'reaction': 18, 'cooldown': 66, 'cooldown_jitter': 30, 'heavy_chance': 0.4, 'heavy_cooldown': 300} | — |
| `security_chief` | `client/assets/characters/security_chief/sheet.png` | `client/assets/characters/security_chief/credits.json` | light: warden_rake, heavy: brute_slam | {'spacing': 56, 'reaction': 10, 'cooldown': 34, 'cooldown_jitter': 18, 'heavy_chance': 0.3, 'heavy_cooldown': 300, 'grab': {'chance': 0.35, 'every': 300, 'range': 150}} | — |
| `unit_k7` | `client/assets/characters/unit_k7/sheet.png` | `client/assets/characters/unit_k7/credits.json` | light: k7_piston, heavy: k7_press | {'spacing': 62, 'reaction': 14, 'cooldown': 38, 'cooldown_jitter': 20, 'heavy_chance': 0.3, 'heavy_cooldown': 330} | — |
| `network_runner` | `client/assets/characters/network_runner/sheet.png` | `client/assets/characters/network_runner/credits.json` | light: punk_flurry, heavy: thug_kick | {'spacing': 46, 'reaction': 8, 'cooldown': 40, 'cooldown_jitter': 26, 'heavy_chance': 0.25, 'heavy_cooldown': 270} | — |
| `network_enforcer` | `client/assets/characters/network_enforcer/sheet.png` | `client/assets/characters/network_enforcer/credits.json` | light: brute_jab, heavy: warden_crush | {'spacing': 60, 'reaction': 14, 'cooldown': 62, 'cooldown_jitter': 30, 'heavy_chance': 0.35, 'heavy_cooldown': 300} | — |
| `ring_fighter` | `client/assets/characters/ring_fighter/sheet.png` | `client/assets/characters/ring_fighter/credits.json` | light: champ_jab, heavy: champ_overhand | {'spacing': 50, 'reaction': 10, 'cooldown': 44, 'cooldown_jitter': 24, 'heavy_chance': 0.3, 'heavy_cooldown': 300} | — |
| `ringmaster` | `client/assets/characters/ringmaster/sheet.png` | `client/assets/characters/ringmaster/credits.json` | light: ring_jab, heavy: ring_spin | {'spacing': 52, 'reaction': 8, 'cooldown': 28, 'cooldown_jitter': 18, 'heavy_chance': 0.3, 'heavy_cooldown': 300, 'grab': {'chance': 0.4, 'every': 270, 'range': 170}} | — |
| `big_sak` | `client/assets/characters/big_sak/sheet.png` | `client/assets/characters/big_sak/credits.json` | light: sak_jab, heavy: sak_slam | {'spacing': 60, 'reaction': 12, 'cooldown': 40, 'cooldown_jitter': 20, 'heavy_chance': 0.3, 'heavy_cooldown': 330, 'grab': {'chance': 0.45, 'every': 270, 'range': 170}} | network_runner |
| `facility_trooper` | `client/assets/characters/facility_trooper/sheet.png` | `client/assets/characters/facility_trooper/credits.json` | light: warden_rake, heavy: thug_kick | {'spacing': 54, 'reaction': 10, 'cooldown': 50, 'cooldown_jitter': 26, 'heavy_chance': 0.3, 'heavy_cooldown': 300} | — |
| `riot_trooper` | `client/assets/characters/riot_trooper/sheet.png` | `client/assets/characters/riot_trooper/credits.json` | light: brute_jab, heavy: warden_crush | {'spacing': 58, 'reaction': 12, 'cooldown': 56, 'cooldown_jitter': 28, 'heavy_chance': 0.35, 'heavy_cooldown': 300} | — |
| `hybrid_worker` | `client/assets/characters/hybrid_worker/sheet.png` | `client/assets/characters/hybrid_worker/credits.json` | light: hybrid_maul, heavy: brute_slam | {'spacing': 56, 'reaction': 14, 'cooldown': 58, 'cooldown_jitter': 30, 'heavy_chance': 0.35, 'heavy_cooldown': 300} | — |
| `subject_twelve` | `client/assets/characters/subject_twelve/sheet.png` | `client/assets/characters/subject_twelve/credits.json` | light: hybrid_maul, heavy: subject_lunge | {'spacing': 56, 'reaction': 10, 'cooldown': 32, 'cooldown_jitter': 18, 'heavy_chance': 0.3, 'heavy_cooldown': 300} | — |
| `commander_arthit` | `client/assets/characters/commander_arthit/sheet.png` | `client/assets/characters/commander_arthit/credits.json` | light: arthit_baton, heavy: arthit_strike | {'spacing': 58, 'reaction': 10, 'cooldown': 38, 'cooldown_jitter': 20, 'heavy_chance': 0.3, 'heavy_cooldown': 330, 'grab': {'chance': 0.25, 'every': 360, 'range': 140}} | facility_trooper |
| `core_sentinel` | `client/assets/characters/core_sentinel/sheet.png` | `client/assets/characters/core_sentinel/credits.json` | light: k7_piston, heavy: k7_press | {'spacing': 62, 'reaction': 16, 'cooldown': 64, 'cooldown_jitter': 30, 'heavy_chance': 0.35, 'heavy_cooldown': 330} | — |
| `hybrid_brute` | `client/assets/characters/hybrid_brute/sheet.png` | `client/assets/characters/hybrid_brute/credits.json` | light: hybrid_maul, heavy: brute_slam | {'spacing': 56, 'reaction': 12, 'cooldown': 60, 'cooldown_jitter': 28, 'heavy_chance': 0.3, 'heavy_cooldown': 300} | — |
| `director_wiroj` | `client/assets/characters/director_wiroj/sheet.png` | `client/assets/characters/director_wiroj/credits.json` | light: wiroj_jab, heavy: wiroj_palm | {'spacing': 58, 'reaction': 10, 'cooldown': 36, 'cooldown_jitter': 20, 'heavy_chance': 0.3, 'heavy_cooldown': 330, 'grab': {'chance': 0.2, 'every': 390, 'range': 130}} | — |
| `tunnel_mother` | `client/assets/characters/tunnel_mother/sheet.png` | `client/assets/characters/tunnel_mother/credits.json` | light: mother_swipe, heavy: mother_slam | {'spacing': 70, 'reaction': 14, 'cooldown': 44, 'cooldown_jitter': 24, 'heavy_chance': 0.3, 'heavy_cooldown': 330} | tar_hound |
| `iron_colossus` | `client/assets/characters/iron_colossus/sheet.png` | `client/assets/characters/iron_colossus/credits.json` | light: colossus_piston, heavy: colossus_stomp | {'spacing': 80, 'reaction': 14, 'cooldown': 46, 'cooldown_jitter': 24, 'heavy_chance': 0.3, 'heavy_cooldown': 330} | core_sentinel |
| `subject_zero` | `client/assets/characters/subject_zero/sheet.png` | `client/assets/characters/subject_zero/credits.json` | light: zero_claw, heavy: zero_slam | {'spacing': 76, 'reaction': 10, 'cooldown': 40, 'cooldown_jitter': 22, 'heavy_chance': 0.3, 'heavy_cooldown': 330} | hybrid_brute |


## Classification (Phase B)

KEEP: already matches its area. REWORK: keep the enemy's identity, change some
parts. REPLACE: the current art cannot show what the enemy is. INVESTIGATE: the
source or licence needs the owner's decision before anything else.

| Enemy ID | Current Name | Area | Current Visual Theme | Problem | Proposed Direction | Class |
|---|---|---|---|---|---|---|
| `training_dummy` | Training Dummy | Depot Yard, city yard | straw dummy on a post | none (a prop, not a faction member); its credit is the project's own code (MIT), outside the CC0/OGA-BY selection but not third-party | keep | KEEP |
| `smogling` | Smogling | South Street, Industrial | painted: vagrant, yellow raincoat, bottle gas mask | painted, high-colour style beside the LPC pixel characters; credited "Proprietary (project owner)", made with the owner's AI tools: outside CC0/OGA-BY, provenance needs the owner's statement | owner decides: keep the painted set (and restyle the rest to match) or redo in LPC style | INVESTIGATE |
| `tar_hound` | Tar Rat | South Street | painted: hooded teen in a rubber rat mask | as Smogling | as Smogling | INVESTIGATE |
| `pipe_brute` | Pipe Brute | South Street | LPC: green skin, orc head, suspenders | fantasy orc head and green skin on an alley heavy (Story Bible: "นักเลงคุมซอย") | human heavy, work clothes, South Street gang colours | REWORK |
| `smog_warden` | Smog Warden | South Street, Industrial | painted: grey hazmat suit with skeleton print, twin-filter mask | as Smogling | as Smogling | INVESTIGATE |
| `sludge_foreman` | The Sludge Foreman | South Street (boss) | painted: big man, boar mask, suspenders | as Smogling | as Smogling | INVESTIGATE |
| `dock_thug` | Dock Thug | South Street, Port | LPC: bandana, beard, grey t-shirt | none | keep | KEEP |
| `rail_bruiser` | Rail Bruiser | South Street | LPC: buzzcut, beard, navy overalls | none | keep | KEEP |
| `market_punk` | Night Market Punk | South Street | LPC: pink spiked hair, open vest | the spiked hair layer is offered only under CC-BY 4.0, outside CC0/OGA-BY | same look with a CC0/OGA-BY hair | REWORK |
| `refinery_enforcer` | Refinery Enforcer | South Street (elite) | LPC: Roman legion armour, armoured legs, headband | Roman/medieval armour in a modern refinery | work-wear protective gear (vest, gloves) in the Baron's colours | REWORK |
| `furnace_baron` | The Furnace Baron | South Street (boss) | LPC: walrus moustache, maroon shirt, `cap_leather` (reads as a plumed fantasy cap); the recipe's trench coat is not drawn | fantasy cap; set apart only by size; the coat meant to mark him never renders (and is not licence-eligible) | modern boss: same coat and moustache, a modern cap or none, a boss-only accent colour | REWORK |
| `street_thrower` | Bottle Thrower | South Street | LPC: red bandana, open vest | none | keep | KEEP |
| `pit_champion` | The Pit Champion | South Street (mini-boss) | LPC: shirtless, buzzcut, thick headband, shorts | none | keep | KEEP |
| `stevedore` | Stevedore | Port | LPC: orange sleeveless shirt, beard | none | keep | KEEP |
| `port_guard` | Port Guard | Port (elite) | LPC: navy buttoned shirt, plain hair | reads as a civilian; nothing says guard or elite | port-security uniform markers (cap, vest) in the port palette | REWORK |
| `dock_slinger` | Dock Slinger | Port | LPC (female): teal t-shirt, ponytail | none | keep | KEEP |
| `harbourmaster_chen` | Harbourmaster Chen | Port (boss) | LPC: white polo, grey hair and beard | barely set apart from the crew | officer's coat or vest, boss accent colour | REWORK |
| `plant_guard` | Plant Guard | Industrial (elite) | LPC: slate buttoned shirt, buzzcut | generic; no plant-security identity, nothing elite | plant security uniform (cap, hi-vis) | REWORK |
| `hazmat_sprayer` | Hazmat Sprayer | Industrial, Core Facility | LPC: yellow suit, Xeon helmet | none | keep | KEEP |
| `patrol_unit` | Patrol Unit | Industrial, Core Facility | LPC: human body (black fur), plate armour, Xeon helmet | the Story Bible says machine (first of the Machines group); drawn as a person in medieval plate | a machine; LPC cannot make one (needs other art) | REPLACE |
| `security_chief` | Security Chief Nattapong | Industrial (boss) | LPC: black buttoned shirt, beard | boss barely set apart; reads as plant guard's colleague without rank | security chief's uniform, rank accent | REWORK |
| `unit_k7` | Unit K-7 | Industrial (boss) | LPC: same parts as Patrol Unit, larger | machine boss drawn as a person in plate | a machine boss; needs other art | REPLACE |
| `network_runner` | Network Runner | Black Network | LPC: purple t-shirt, `cap_leather` (plumed) | fantasy cap on a money courier | modern courier (cap or hood), network colours | REWORK |
| `network_enforcer` | Network Enforcer | Black Network | LPC: white shirt, open black vest, walrus moustache | none | keep | KEEP |
| `ring_fighter` | Ring Fighter | Black Network (elite) | LPC: shorts, red headband, spiked hair | spiked hair is CC-BY 4.0 only, outside CC0/OGA-BY | same look with a CC0/OGA-BY hair | REWORK |
| `ringmaster` | The Ringmaster | Black Network (boss) | LPC: red buttoned shirt, beard (the recipe also names a tabard, which is not drawn) | barely set apart from the network's men; a recipe part that never renders | modern ringmaster with a boss-only accent from eligible parts | REWORK |
| `big_sak` | Big Sak | Black Network (boss) | LPC: maroon long-sleeved shirt, beard, glasses (the recipe's trench coat is not drawn) | none visible; the recipe names a part that never renders | keep the look; drop the dead trench layer from the recipe when it is next built | KEEP |
| `facility_trooper` | Facility Trooper | Core Facility | LPC: slate uniform, leather armour, Xeon helmet | none serious (leather armour is generic) | keep | KEEP |
| `riot_trooper` | Riot Trooper | Core Facility (elite) | LPC: medieval plate armour and armoured legs, Xeon helmet | medieval plate on modern riot police | riot gear look: padded vest, helmet, shield colours of the facility | REWORK |
| `hybrid_worker` | Hybrid Worker | Core Facility | LPC: green skin, orc head, overalls | fantasy orc head reads as a monster; Hybrids are victims (sick workers) | a human worker with visible exposure (pallor, discoloured patches), overalls kept | REWORK |
| `subject_twelve` | Subject 12 | Core Facility (boss) | LPC: orc head, white sleeveless shirt | as Hybrid Worker | as Hybrid Worker, plus boss distinction | REWORK |
| `commander_arthit` | Commander Arthit | Core Facility (boss) | LPC: forest uniform, Roman legion armour | Roman armour on a modern commander | officer's uniform and body armour, facility colours | REWORK |
| `core_sentinel` | Core Sentinel | Main Control Centre (elite) | LPC: human body (black fur), legion armour, Xeon helmet | the Story Bible says a robot Wiroj built; drawn as a person | a robot; needs other art | REPLACE |
| `hybrid_brute` | Hybrid Brute | Main Control Centre | LPC: green skin, orc head, spiked hair | orc head (victim, see Hybrid Worker); spiked hair is CC-BY 4.0 only | as Hybrid Worker, heavier build | REWORK |
| `director_wiroj` | Director Wiroj | Main Control Centre (final boss) | LPC: elderly head, glasses, white buttoned shirt (the recipe's trench coat is not drawn) | none visible; a dead recipe layer | keep the look; drop the dead layer when next built | KEEP |
| `tunnel_mother` | The Tunnel Mother | The Great Drain (world boss) | LPC: orc-headed worker in overalls, drawn ×2 | the Story Bible says a huge mutant creature; drawn as a person | a creature; needs other art | REPLACE |
| `iron_colossus` | The Iron Colossus | The Old Scrapyard (world boss) | LPC: Patrol Unit parts, drawn ×2.2 | a prototype walking security robot; drawn as a person in plate | a robot; needs other art | REPLACE |
| `subject_zero` | Subject Zero | The Sunken Reservoir (world boss) | LPC: green skin, orc head, white spiked hair, drawn ×2.3 | orc head (victim); spiked hair is CC-BY 4.0 only | the first Hybrid, human in origin, world-boss presence | REWORK |

**Counts:** KEEP 12, REWORK 17, REPLACE 5, INVESTIGATE 4 (38).

**Notes**
- `hybrid_worker` is already an ordinary enemy in story areas (Test Labs and the
  rest of the Core Facility). The brief says not to introduce it as a normal enemy;
  it was not introduced here, and it stays out of the farming grounds. Whether it
  should stay an ordinary story enemy is a story decision for the owner, not an
  art one.
- `docs/ASSETS.md`'s parts table still describes Smogling, Tar Rat, Smog Warden and
  Sludge Foreman as LPC-built; they have been the owner's painted art since. That
  table is out of date (not changed in this audit).
- **Recipe parts that are not drawn.** Three parts named in enemy recipes never
  reach the sheet: the open vest (Night Market Punk, Bottle Thrower, Network
  Enforcer), the trench coat (Furnace Baron, Big Sak, Director Wiroj) and the tabard
  (Ringmaster). The generator ships these only as colour-named files
  (`male/walk/gray.png`); the recipes ask for a recolour instead of a variant, so
  `tools/assets/lpc_build.py` looks for a file that does not exist and skips the
  layer silently (the skip is meant for parts with no frames for an animation).
  Nothing unlicensed shipped: the credits list only what was drawn, and these
  parts are offered only under CC-BY-SA 3.0 / GPL 3.0, so the build would have
  refused them. The visual result is that the bosses' signature coats never show.
- Enemies that fight in several districts are listed by every district they
  fight in; the design direction follows the district where they first appear.
