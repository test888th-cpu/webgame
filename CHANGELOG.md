# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer.

## [Unreleased]

### Changed — Weapons sized to the hand
- Held weapons are redrawn at the characters' scale (knife blade ~9 px, bottle ~12 px,
  plank and pipe ~23 px, folding chair ~20 px) with slim, unoutlined handles so the fist
  still shows around the grip. Before, they were nearly half a character tall.

### Added — Three new areas, street weapons and smarter enemies
- The street goes on past the Sludge Foreman: **Rail Yards** (level 4), **Night Market**
  (level 6, with Kenji's Night Stall) and **Smokestack Refinery** (level 8, boss: the
  Furnace Baron). Every area has a level; enemies scale with it (HP, damage, defense,
  speed, XP, coins) and get smarter: faster reactions, guarding against wind-ups (from
  level 3), hopping back and grabbing weapons (from level 5). Enemy level shows over
  their heads and the area level on the HUD. New enemies with their own outfits: Dock
  Thug, Rail Bruiser, Market Punk, Refinery Enforcer (elite), Furnace Baron (boss).
- **Street weapons**: knife, bottle, wooden plank, steel pipe, machete and folding chair
  lie around (random by area and level; two in the Depot Yard to practise with). E picks
  one up or puts it down; it gives Z/X its own moves, wears out per landed blow (pips on
  the HUD), breaks with a sound, and is **drawn in the hand, following every frame of
  the swing**. Anyone knocked down drops their weapon and has to pick it up again.
  Wielding enemies may start armed.
- Quests Rail Yard Rumble, Market Lights and The Furnace Baron; six new items (rare to
  legendary, levels 5-8) with their own icons.
- Sprite builder: per-frame hand sockets from LPC's glove layer; weapon sprites and
  sounds (grab, drop, glass/wood/metal break) generated like the other assets.
- Smoke test picks up a weapon in the yard. 17 new tests (134 total), 2 pipeline tests.

### Changed — Skills worth their cooldown
- The heavy attack (X/K) has no cooldown, so it no longer rivals skills: 13 damage
  (was 18) and 20 energy (was 15). Skills hit harder: Mika 26/22/28/45, Oren
  28/24/30/50 (base). `test_balance.gd` now requires every skill to hit at least 1.5x
  the heavy attack.

### Added — Readable loot
- Items on the street show their own icon (at 2x, sharp) with a shadow, a glow and, for
  uncommon and better, a light beam in the rarity colour (taller for rarer items); epic
  and legendary items sparkle. Each shows its name in its rarity colour; coins spin and
  show their amount. Drops pop out of the enemy in an arc and fly off when collected.
- The bag and worn slots show icons at 2x in larger cells.
- The Characters gallery shows every item as it looks on the ground.
- 1 new test (117 total).

### Changed — Hero balance
- Clear roles: Mika is damage and mobility (power 110%, speed 110%, 100 HP); Oren is
  toughness and control (power 100%, speed 85%, 130 HP, 2 defense, wider skills).
- Skill damage retuned so every skill out-damages the free heavy attack, each hero's
  slot-5 skill is their strongest, and same-slot skills of both heroes land within 15%
  of each other: Mika 20/18/22/38, Oren 22/20/24/42 (base, before power).
- `test_balance.gd` keeps these rules (4 tests, 116 total).

### Fixed — Attack buttons felt unresponsive
- Input buffer: a light/heavy attack or skill pressed in the last 12 ticks (0.2 s) of a
  missed swing now starts as soon as that swing ends; before, the press was dropped,
  so Z/X (and J/K) seemed not to work when mashed.
- A heavy attack or dodge without enough energy now plays a refusal sound and blinks the
  energy bar instead of silently doing nothing. 3 new tests (112 total).
- The attack slot (1) lights up when Z/J is pressed and is labelled "1 Z", so it is
  clear Z is the same basic attack (no cooldown); the key hint shows X for heavy.

### Added — Hero portrait on the HUD
- The hero card shows the hero's face (cut from the current sprite, so armour shows) on
  a backdrop in the hero's colour, with the level in a gold badge on its corner, the
  player's name and the hero's role. The portrait flashes red when the hero is hit and
  its frame pulses red below 25% HP. 1 new test (109 total).

### Added — Character status, equipment and items
- Status tab: the hero (sprite, level, role, HP/energy/XP), read-only attributes (Max HP,
  Attack, Defense, Speed) as total + gear bonus with a line of help each, what the next
  level brings (stats and skills), and a record.
- Equipment tab: six worn slots around the hero (head, body, hands, weapon, feet, charm,
  with empty-slot silhouettes and a turnable preview), a stats summary, and the bag as a
  grid with stack counts and rarity frames.
- Item card on any item: icon, name in its rarity colour, rarity and slot, required
  level, effects in player terms, comparison with what is worn, description, and
  Equip / Unequip / Use / Discard (asks first). The shop shows the same details.
- Items: rarity, required level, `stats` bonuses (penalties allowed), descriptions.
  15 items with new icons; Ama sells ten, enemies drop the rest. Each hero starts with a
  small kit (worn gear, buns, coins).
- Saves (version 3) map the old `armor`/`accessory` slots to `body`/`charm`.
- 3 new tests (108 total).

### Added — Hero creation and a second hero
- Hero creation screen after New game: roster cards with portraits, a large animated
  preview, bio, play style, difficulty, stats compared across heroes, the hero's four
  skills, and a name field (2–16 characters, any script including Thai; Random
  suggestions). Keyboard, gamepad, mouse and touch.
- Oren Vale, a male bruiser (LPC, OGA-BY): 130 HP, 115% power, 2 defense, 85% speed,
  with Headbutt, Clothesline, Shoulder Charge and Earthshaker (new moves and icons) and
  an armoured look.
- Heroes are data (`data/heroes.json`): stats, sprites and looks, skills. The hotbar
  template fills its skill slots from the hero. Items change looks by name (`look`).
- Saves (version 2) store the hero and the player's name; version 1 saves become Mika.
- The title shows the saved hero (card and line-up). Credits now include the Godot
  licence and the bundled font.
- Noto Sans Thai (OFL) as a font fallback, pinned by SHA-256 and validated in CI.
- 8 new tests (105 total); the smoke test picks Oren and types a name.

### Changed
- `progression.json` no longer holds hero stats; they live with each hero.

### Added — Skills, combat feedback and sound
- Skill hotbar (`data/skills.json`): slot 1 attack, slots 2–5 Rising Uppercut, Whirlwind
  Kick, Shoulder Rush and Furnace Slam, slots 6–7 Steamed Bun and Ginger Tea. Skills
  cost energy, have cooldowns, unlock at levels 1/1/2/3 and can cancel a landed attack.
  Cooldowns, unlocks and a shared 2 s consumable cooldown are simulation rules
  (`SkillRules`, `CombatRules.start_skill`, `ZoneSim.use_item`). New move fields:
  `advance` (lunges). Knockback now pushes away from the attacker.
- Hotbar UI: icons, key numbers, cooldown sweep and seconds, energy and lock states, item
  counts, tooltips, click/tap; keys 1–7 and gamepad RT combinations.
- Combat feedback: hit sparks, impact flash and freeze, dust, per-skill effects, camera
  shake, hurt vignette, level-up light and banner naming unlocked skills.
- Sound: 25 original synthesised effects and a sound-volume option.
- Training dummy: an original wooden sparring post that rocks when hit and tips over.
- Generators `gen_fx.py`, `gen_sfx.py`, `gen_dummy.py` and skill icons in `gen_ui.py`, all
  validated in CI. 15 new tests (97 total); the smoke test casts a skill.

### Added — Interface overhaul
- One visual language (`UiTheme`: palette, type scale, control styles) applied to
  every screen through the project theme, and a kit of building blocks (`UiKit`).
  See `docs/UI.md`.
- Title screen: live street backdrop, logo, Continue first when a save exists,
  confirmation before a new game replaces a save, key hints.
- HUD: hero card with level badge and HP/energy/XP bars (damage trail), coins
  with icon, area name, tracked quest card, boss bar, notification banner, key
  hints; touch controls on touch devices only.
- Pause window with tabs (Status, Bag, Quests, Controls, Game) switched with Q/E or
  LB/RB; bag and shop list items with icons and a detail panel; quest cards with
  progress and rewards; options for screen shake and a frame-rate counter
  (`user://settings.json`).
- NPC conversations in a dialog box with a portrait; "[E] Talk/Shop" prompt over
  the NPC in reach; knock-out screen; outlined names and damage numbers; camera
  shake on heavy hits.
- Generated item and interface icons (`tools/assets/gen_ui.py`), validated in CI.
- `test_ui.gd`: screens fit the 640x360 base view, wrapping text has a width,
  focus is set, tabs switch, prompts appear only near NPCs (82 tests total).
- `tools/web-smoke/shots.ts` for screenshots of a web build.

### Fixed
- The title text wrapped one word per line (an autowrapping label without a width).

### Added — Character art pipeline and first art pack
- `tools/assets/`: LPC character builder (pinned generator commit, licence policy,
  recolouring, credits), UnitForge "Godot 4" export importer, SpriteFrames
  generator, asset validator and 14 pipeline unit tests; `Assets` workflow to
  build/import in the cloud; CI job validating every asset. See `docs/ASSETS.md`.
- Nine LPC-built characters (CC0/OGA-BY/CC-BY only): hero Mika and an armoured
  variant (shown when the Work Jacket is equipped), NPCs Ama and Chief Odo, and all
  five enemy types including the elite and the boss. `FighterView` plays them with
  `AnimatedSprite2D`, attack frames stepped by simulation ticks.
- Title screen: Characters (gallery) and Credits.
- Tar Hound renamed "Tar Rat" to match its art.
- Generated scenery for every area (`tools/assets/gen_environment.py`, original
  MIT art): sky and parallax skyline, themed facades (depot warehouses and
  containers, market shophouses and stalls, canal factories and water), detailed
  street, props and lamp glow. Validated for freshness in CI.

### Added — Milestone 2, part 2: playable single-player loop
- Title screen (New game / Continue), pause menu, inventory and equipment, shop,
  quest dialog and log, game over with a coin penalty, notifications, boss HP bar.
- Three areas from `data/areas.json`: Depot Yard (home: vendor, quest giver, training
  dummy, heals on entry), Saltmarket Street and Canal Works, joined by exits.
- Enemies from `data/enemies.json`: Smogling, Tar Hound, Pipe Brute, elite Smog Warden
  and a two-phase boss, the Sludge Foreman. `EnemyBrain` AI keeps spacing, lines up,
  reacts and swings; at most two attack at once (attack tokens); telegraphed heavies
  show a warning. Enemies push apart instead of stacking.
- Encounters with waves lock the arena until cleared and reset on re-entry (farming).
- Rewards decided by the zone simulation from a seeded generator: XP and levels,
  money and item drops from loot tables, quest progress. Items, shops, quests and
  progression are data (`items.json`, `shops.json`, `quests.json`, `progression.json`),
  validated together with cross-references by `ContentDB`.
- `PlayerProfile` with versioned, sanitising (de)serialisation; local save via
  `SaveStore` (atomic write; IndexedDB in browsers), autosave on area change, defeat,
  purchase and quest hand-in.
- 30 new tests (69 total); the test runner now ignores warnings but still fails on
  errors. The browser smoke test plays title -> new game -> dummy combo -> pause ->
  next area -> a real street fight.

### Added — Milestone 2, part 1: combat core
- Deterministic 60 Hz combat simulation in `client/sim/` (`CombatRules`, `Fighter`,
  `FighterInput`, `CombatEvent`): light combo jab → cross → body hook (chains only
  after a connected hit), guard-breaking haymaker, dodge with invulnerability frames,
  guard (front only, chip damage, energy drain, guard break), hit stun, knockback,
  knockdown, KO, simultaneous-hit trades.
- Attacks are data: `client/data/moves.json`, loaded and validated by `MoveLibrary`.
- Test zone: training dummy with HP bar and respawn, HUD HP/energy bars, floating
  damage numbers, keyboard/gamepad/touch bindings for light, heavy, dodge, guard.
- 23 new tests (39 total). Browser smoke test now lands a combo on the dummy.
- `pages.yml` plays the live HTTPS site after each deploy.

### Security
- Asset tools pin Pillow 13.0.0: dependency review flagged 20+ HIGH advisories in
  12.3.0 (PDF, TIFF, JPEG, GIF decoders). Rebuilt assets are byte-identical.

### Changed
- CI jobs have time limits. The smoke test installs only Chromium's headless shell
  (cached) instead of `--with-deps`, which spent 10+ minutes on a slow apt mirror.
- Light hits push less (jab 4 px, cross 6 px) so the combo stays in reach.

## [0.1.0] — 2026-10-23 (Milestone 1 / Task 001)

### Added — Milestone 1 / Task 001: cloud build pipeline
- Godot 4.7.2 client project (`client/`): test street, placeholder hero with lane movement
  (keyboard, gamepad, touch), bounded camera, HUD.
- Shared rules module `client/sim/LaneMovement.gd` with unit tests.
- Headless Godot test runner that fails tests on any engine or script error.
- Release web export preset (single-threaded, Compatibility renderer).
- Browser smoke test (Playwright + Chromium) that verifies boot and keyboard movement.
- API service skeleton (Node 24.22.1, Fastify): `/healthz`, `/readyz`, checksummed
  forward-only migration runner, migration `0001_accounts`.
- CI: repository policy, gdlint/gdformat, Godot tests, web export + smoke test + artifact
  with SHA-256 manifest, backend tests on PostgreSQL 16, image build + Trivy + SBOM.
  Security: gitleaks, npm audit, dependency review. Gated GitHub Pages deployment of the
  CI artifact.
- Documentation set and repository audit.

### Security
- Runtime image drops npm, npx and corepack (multi-stage build). Their bundled
  `brace-expansion` 5.0.9 and `undici` 6.28.0 had HIGH CVEs (CVE-2026-102276,
  CVE-2026-102278, CVE-2026-19534) reported by Trivy; the API never runs them.
