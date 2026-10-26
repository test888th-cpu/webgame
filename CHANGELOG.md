# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer.

## [Unreleased]

### Added — Street kit: all 22 pieces from the scene prompts (IL-4)
- Every piece in `docs/SCENE_PROMPTS.md`, painted by the owner and cut out by
  `kit_import.py`: Fight Club (warehouse wall, ring, crowd, work lamps, tyres, chairs),
  Rusted Corner (junk shop, fence, scrap, drums, car wreck), Parking Lot (car park,
  barrier booth, pickup, scooters), Rat Nest (tunnel wall, drain pipe, grate, the
  `tunnel_floor_tile` ground strip) and Gang HQ (facade, steel gate, guard booth).
- Crops drop what the paintings added outside the piece: the smear above the fence and
  the framed lamp section at the left of the crowd.
- Fight Club is now an underground ring: corrugated warehouse walls with work lamps
  strung overhead, the ring, the crowd, tyres, chairs and drums along the back. Rusted
  Corner is a junk-dealers' street: the junk shop and patched fences, scrap heaps, oil
  drums and a car wreck at the kerb. An area's `kit_theme` picks its own kit theme
  (the generated fallback scenery still follows `theme`), and themes can hang pieces
  overhead (`hanging`). Checked in a browser; one new pipeline test.
- The Parking Lot, Rat Nest and Gang HQ pieces are imported but wait for those areas.

### Added — Three more heroes: the Basketball Player, the Police Officer, the Soldier (IL-4)
- **Kan Srisuk, the Basketball Player**: the crowd controller. Crossover (a stunning
  change of direction), Elbow Clear (both sides), Post Up (breaks guard) and Slam Dunk,
  the widest hit in the crew. 110 HP, 105% speed and attack speed.
- **Dao Kittikun, the Police Officer**: defence and counters. Her parry window is 12
  ticks (everyone else 8), Wrist Lock holds a foe longest, Riot Shove floors a crowd.
  120 HP, 95% power. Hardest to play (3/3).
- **Pong Rattana, the Soldier**: once one of his skills starts, nothing interrupts it
  (Combat Elbow, Breach Kick, Shoulder Drive, Ground Pound). Toughest (140 HP, 3
  defense) and slowest (80%). Easiest to play.
- Each hero's edge is data (`heroes.json` `parry_window`, `skill_armor`) used by the
  existing rules, not new combat code paths. All six heroes pass the existing balance
  rules (same-slot skills within 15%, every skill 1.5x the heavy attack, the slot-5
  skill strongest); new tests check every class is in the roster, nobody tops health,
  power and speed together, the Soldier is slowest and toughest, Kan reaches widest,
  Dao parries where others only block, and Pong's skills cannot be interrupted.
- Measured with the same scripted player against the Smog Warden at level 5: Kan
  5.0 s, Dao 5.1 s, Pong 6.1 s (the first three heroes 3.8–4.9 s); all win 20/20.
- Sprites built with the LPC pipeline from licence-cleared layers; twelve new 24 px
  skill icons. Hero creation switches to compact cards when there are more than four
  heroes, so all six fit above the name bar (checked in a browser).
- `docs/SCENE_PROMPTS.md`: painting prompts and rules for the next street-kit pieces
  (Fight Club ring, Rusted Corner junk yard, and the planned Parking Lot, Rat Nest and
  Gang HQ). 5 new tests (225 total).

### Added — South Street grows: Rusted Corner, Fight Club, ranged enemies, a mini-boss (IL-4)
- **Rusted Corner** (level 3, between Canal Works and the Rail Yards) introduces the
  first ranged enemy, the **Bottle Thrower**: it hangs back 80–150 px, lines up in your
  lane, winds up (telegraphed) and lobs a bottle that stuns but never floors and
  shatters where it lands; caught up close it jabs. Its exit opens after 6 throwers.
- **Fight Club** (level 7, between the Night Market and the Refinery) ends in the
  **Pit Champion**, a mini-boss: a jab-cross chain, a telegraphed guard-breaking
  overhand, and below half HP a charging rush. Poise 70. Drops scrap and alloy always
  and the new **Champion's Wraps** (epic hands: attack, crit, attack speed) 25% of the
  time. His exit opens the back door to the Refinery.
- Two new LPC characters built with the asset pipeline from layers already cleared by
  the licence policy (OGA-BY): the red-bandana thrower and the shirtless champion.
  Scenery for both areas is laid out from the owner's kit like every other street.
- Two quests join Chief Odo's chain, voiced like the rest: "Glass Rain" (after the
  Foreman) and "The Pit" (after Market Lights, before the Baron). The story bible maps
  both areas and gives the champion his reason to fight.
- Ranged attacks reuse the throwing system (`ZoneSim` projectiles) instead of a second
  one; the AI is `EnemyBrain._keep_range`; the data (`ranged` on the enemy and its
  `ai`) is validated on load.
- Measured the rules' cost with 10 enemies on screen: 0.30 ms per tick on average
  (PERFORMANCE.md), well inside a 60 fps frame.
- After a fight is cleared, a blinking **GO >>** points the way on (only where the
  street continues east).
- New tests keep the street one connected line with rising levels, every gate
  winnable in its own area, every quest target findable, and check the thrower keeps
  its distance and its bottles stun and shatter. 6 new tests (220 total).
- Measured with a scripted player (no gear, no healing, no parries): the champion is
  as hard as the existing Furnace Baron for that player (both unbeaten), the Sludge
  Foreman is beaten 30–80% of the time. Real tuning needs playtests; recorded in
  docs/BLUEPRINT.md.

### Added — Elites and bosses cannot be pinned by mashing (poise)
- Found while balancing the classes: replaying a fight against the Smog Warden (one
  scripted player per hero, 20 seeds) showed a hero who just mashed light attacks kept
  the elite helpless 60–77% of the fight and was never hit back, which made its
  telegraphed attacks meaningless.
- Elites and bosses now have **poise** (`enemies.json` `poise`: 60 for elites, 80 for
  bosses). Hitstun fills it; past it they shrug blows off for 1.5 s (still taking
  damage, with a warm sheen and steel-grey damage numbers), and they are unflinching
  while winding up a telegraphed attack, so the answer is to dodge, guard or parry.
  A parry still staggers them. Same replay: helpless 39–55%, and at level 5 the elite
  now lands hits. Heroes and ordinary enemies are unchanged.
- The same replay showed why Mika's kills are slowest at level 1: both her starting
  skills knock down, and a floored enemy cannot be hit for 50 ticks. That is the
  intended trade (knockdowns buy safety), recorded in the blueprint rather than
  re-tuned without playtesting. 6 new tests (214 total).

### Added — Gear upgrades at the workbench (IL-3)
- Every equipment slot can be upgraded from +0 to +10. Each level adds 10% of the worn
  item's own stats (penalties are never amplified). Upgrades belong to the **slot**, so
  changing gear never throws them away, and there is no per-item bookkeeping that a
  save could lose.
- Each attempt costs coins and materials (+1: 40 coins and 1 Scrap; +10: 1,100 coins,
  8 Scrap, 3 Alloy) and succeeds at the level's rate (100% down to 20%). **A failure
  keeps the item and the level**, spends only the cost, and adds +5% to the next try in
  that slot until one succeeds. Costs and rates are data (`progression.json`
  `enhance`), validated on load (costs in materials, rates never rising).
- From the worn item's card in a safe area (the Depot Yard): what the upgrades add
  now, the next level's chance and cost (red where you are short), and an "Upgrade
  +N (chance)" button. Success and failure each have a sound and a message; a second
  press within 0.4 s is ignored and every attempt is saved at once. Upgraded slots
  show a gold "+N".
- The rule is `sim/EnhanceRules.gd`: check, pay, roll, apply in one call, with the
  roll from the caller (the server, once online). **Save version 5** stores levels and
  pity; version 4 saves start at +0, values are clamped and unknown slots dropped.
- 9 new tests (208 total).

### Added — Critical hits and attack speed (IL-3, decision D8)
- Two new stats: **Crit** (chance of a 1.5x blow; every hero starts at 5%, Riku the
  Boxer at 8%; capped at 50%) and **Atk Speed** (cuts the recovery after each attack,
  never the wind-up, so combos stay readable; 70–130%). Crits come only from the zone's
  seeded generator, so a fight replays identically; enemies do not crit. No accuracy
  stat: hits are decided by where the blow lands.
- Gear that fits: Lucky Coin, Iron Wraps, Brass Knuckles and the Baron Knuckledusters
  add crit; Fingerless Gloves, Street Runners and the Jade Charm add attack speed.
  Status and item cards show both. Crits show "CRIT" and shake the camera.
- 4 new tests (199 total); Riku's all-rounder test now covers the core stats and
  requires him to crit most often.

### Added — Upgrade materials and "where to get" (IL-3)
- Two materials (new item type `material`): **Scrap Metal** (common; dropped by street
  enemies 15–30%, elites 80%, sold by Ama and Kenji for 30) and **Refined Alloy**
  (rare; elites 25–30%, Kenji for 300). Every boss now guarantees both, so a boss kill
  always pays even when the signature gear does not drop. New icons; materials sort
  between gear and evidence in the bag and can be discarded.
- Item cards show **WHERE TO GET**: who drops it (chance, where they fight), who sells
  it and for how much, which quest gives it. Worked out from the loot tables, shops and
  quests (`ContentDB.sources`), so it can never disagree with them.
- Fixed a test that only passed by luck: it expected the Sludge Foreman's wrench every
  time, which stopped being true when boss loot became farmable. 5 new tests (195 total).

### Added — A tutorial that teaches by doing (IL-2)
- New heroes are walked through the basics in the Depot Yard, one step at a time in
  the quest card's spot: move, punch the dummy (3 hits), heavy blow, a skill, dodge,
  guard (and how to parry), pick up a weapon, throw it, talk to Chief Odo. Each step
  finishes when the player does it, with a chime; the last says the street is open.
- Skippable from the menu (Game tab, "Skip tutorial"). Steps are data
  (`client/data/tutorial.json`, validated on load) and the rule lives in
  `sim/TutorialRules.gd`.
- **Save version 4** stores tutorial progress. Version 3 saves migrate with the
  tutorial marked finished, since those players already know the game; values are
  clamped on load. 7 new tests (190 total).

### Added — Prologue and Chapter 1 told through the quests (IL-2)
- Chief Odo's six quests are rewritten from `docs/STORY_BIBLE.md` as the Prologue
  ("First Night") and Chapter 1 ("South Street"): a shakedown at Ama's stall, a crate
  the crew came back for, masked guards at the canal, forged freight papers, Kenji's
  tip and the Furnace Baron's ledger, which points to the port.
- Quest givers speak: each quest has an offer, a nudge while it is under way and a
  closing line on hand-in (`quests.json` `dialogue`, one or two sentences). Below the
  speech the dialog always spells out the chapter, quest, **Goal** and reward, so
  skipping the words never leaves anyone lost.
- **Evidence** (new item type `key`): the Torn Shipping Label, Forged Delivery Note and
  the Baron's Ledger are handed over on completion ("New evidence: ..."), sorted at the
  end of the bag, readable from the item card and never sold, used or discarded (a
  sim rule, not only the UI). They are not listed as rewards, to keep the surprise. New
  16 px icons drawn by `gen_ui.py`.
- Handing in "The Furnace Baron" shows a **Chapter 1 complete** card naming where the
  trail leads next.
- Tests keep every quest in a chapter with all three lines, keep The Core unnamed in
  quests and items (story bible §7), and reject priced evidence. 6 new tests (183 total).

### Added — The street opens as the story moves on (IL-2)
- Exits east are now guarded: Saltmarket → Canal Works opens once the Smog Warden is
  down, Canal Works → Rail Yards after the Sludge Foreman, Rail Yards → Night Market
  after 8 Dock Thugs, Night Market → Refinery after 10 Night Market Punks (the same
  goals as Chief Odo's quests, counted whether or not the quest is active, so nobody
  has to fight a guard twice). Before, a new hero could walk straight to the level 8
  Refinery. The way back is always open.
- A locked exit's sign turns red and shows progress ("Locked 0/1 Canal Works >");
  pushing on it plays a refusal and says what opens it, once per push.
- Gates are data (`areas.json` `exits.*.requires`: enemy, count, hint), validated on
  load. 5 new tests (177 total).

### Changed — Boss loot is worth farming; heroes have their classes (IL-2)
- Bosses no longer hand out their best item every time: the Furnace Baron drops the
  Baron Knuckledusters (legendary) 12% of the time (was 100%) and the Jade Charm 20%
  (was 50%; his quest still gives one), the Sludge Foreman his Foreman Wrench (epic)
  30% (was 100%). Bosses respawn on re-entry, so they can be farmed. A test keeps every
  epic or legendary drop at 35% or less.
- Heroes carry their class (decision D3): Mika is **The Footballer** (new bio and
  tagline: sweeping kicks and line-breaking charges), Oren **The Street Brawler**,
  Riku stays **The Boxer**. Display text only; saves are unaffected. 1 new test (172 total).

### Changed — The game is now *The Iron Legacy* (IL-2, decision D1)
- Project name, browser tab, title logo ("THE / IRON / LEGACY") and credits. The title
  tagline promises only the street ("Take Iron City back, one street at a time"), since
  the story bible keeps The Core secret until chapter 3. The README is retitled.
- **Saves survive the rename.** Godot names the user data folder after the project, in
  the browser too (checked in Chromium: a save made by the old build was not seen by
  the renamed one). `SaveStore` now copies `save.json` and `settings.json` from the old
  "Ironbound Streets" folder on first start, never overwriting a newer file and never
  deleting the original. Verified in a real browser: a save made by the old build
  continues in the new one. 3 new tests (171 total).
- Internal names stay (`window.ironboundProbe`, the API image name), as renaming them
  changes nothing a player sees.

### Added — The Furnace Baron charges; fair-fight rules (IL-1)
- Below half HP the Furnace Baron no longer just hits harder: he charges (new
  `baron_rush`: 24 ticks of warning, carries him 110 px, breaks guard, knocks down) and
  is left open for 40 ticks after it. Enemy AI now starts lunging attacks from the range
  the lunge covers, so a charge is seen coming instead of starting point-blank.
- `tests/unit/test_fairness.gd` turns the blueprint's quality bar into rules every enemy
  must pass: openers that floor or break guard are telegraphed with at least 16 ticks of
  warning, telegraphed attacks leave at least 20 ticks to punish, and every boss phase
  adds a new attack. 4 new tests (168 total). This completes milestone IL-1.

### Added — Throw the weapon in hand (IL-1)
- With nothing underfoot to pick up, E now **throws** the held weapon instead of
  putting it down: a short wind-up, then it spins along the street (about 160 px), hits
  the first foe in its path for the weapon's heavy-blow damage at the hero's power and
  knocks them down, then lands at their feet with one use less, or breaks if that was
  its last. A guard blocks it from the front. Bosses are stunned, never floored, so a
  pile of pipes cannot trivialise them. A miss lands where it stops; it never leaves
  the area.
- Throws are simulation (`ZoneSim.thrown`, `CombatRules.thrown_hit`), drawn as a
  spinning weapon at chest height with a whoosh. The HUD hint reads "Grab / Throw /
  Talk". Enemies still only put weapons down.
- 6 new tests (164 total).

### Added — Perfect guard and counters (IL-1)
- Raise guard at most 8 ticks before a hit from the front and it is **parried**: no
  damage, no energy lost (15 energy back), guard breakers included. The attacker reels
  for 30 ticks and the first hit on them is a **counter** for 1.5x damage. Letting go
  of guard closes the parry window for 24 ticks, so it rewards timing, not tapping.
  Only the hero parries, so enemy guards never punish the player's combos.
- A parry flashes, clangs and freezes both fighters for a beat and shows "PARRY";
  counters show "COUNTER" and shake the camera. The Controls tab explains it.
- 6 new tests (158 total).

### Fixed — A crowd can no longer stun-lock the hero (IL-1)
- Hitstun the hero takes fills a stun meter that drains while they are in control. A hit
  that would push it past 40 ticks knocks the hero down instead of holding them, and
  getting up gives 36 ticks in which nothing can hit them (the hero blinks; attacking
  ends it). Measured worst case against three Night Market Punks with no input: 169 →
  68 ticks (2.8 s → 1.1 s); the cap is 90 ticks (1.5 s). Enemies are unchanged, so hero
  combos still chain.
- 4 new tests (152 total with the solid-street tests), including a zone test with three punks over three seeds.

### Changed — Direction approved
- The owner approved every recommendation in `docs/BLUEPRINT.md` (D1–D9): *The Iron
  Legacy*, Iron City and The Core, heroes mapped to classes, single player first (online
  work moves to IL-7). CLAUDE.md, GAME_DESIGN and ROADMAP point to the blueprint and the
  story bible.

### Added — The Iron Legacy: audit and blueprint (IL-0)
- `docs/BLUEPRINT.md`: audit of what exists, works, is missing or risky (baseline 140/140
  tests passing on Godot 4.7.2), conflicts between code, docs and the owner's brief,
  decisions the owner needs to make, the system blueprint built on the existing code, a
  roadmap by risk (IL-0 to IL-7) and a test plan. Measured stun-lock: three Night Market
  Punks keep an idle hero out of control for up to 169 ticks (2.8 s).
- `docs/STORY_BIBLE.md`: the proposed single source for the story (Iron City, The Core,
  characters, chapters, bosses, how the current areas and enemies fit), pending approval.
- Corrected stale lines in README (test count), GAME_DESIGN ("implemented so far") and
  ARCHITECTURE (shared rules). No game code or data changed.

### Added — Solid street: no walking through things or people
- Lamp posts, power poles, bins, cones, crates, NPCs, the training dummy, the hero and
  enemies are now solid. You bump into them and must walk round (a step at an angle
  slides along); enemies step round furniture and each other to reach you. Fighters
  in hitstun or knocked down do not block.
- Street furniture is gameplay data: kinds and footprints in
  `client/data/obstacles.json`, positions per area in `areas.json`, validated on load
  and shared with the future server. The game draws it among the fighters, sorted by
  depth; the scenery kit no longer scatters lamp posts at random and keeps sidewalk
  props and parked vehicles clear of it.
- Loot, weapons, spawns and arrivals never land inside furniture. Tests cover
  blocking, sliding, walking round, enemies detouring, NPCs, fallen fighters and
  furniture placement; the browser smoke test now walks round obstacles.

### Added — Painted street weapons, and a frying pan, wrench and bat
- The street weapons now use the project owner's paintings, reduced to hand-sized
  pixel sprites with an outline like the characters (in hand, on the street and on
  the HUD badge). `gen_ui.py` keys them from their green backdrop and puts the
  handle's end under the grip; `art/weapons/weapons.json` lists them.
- Three new weapons: **frying pan** (from level 1; the heavy bonk dazes and breaks a
  guard), **pipe wrench** (from level 2; quick, sturdy), **baseball bat** (from level
  3; long reach, a heavy swing that sends them flying). Added to the area weapon
  pools.

### Changed — HD-2D Bangkok streets
- Every area is now built from a kit of painted pieces (Octopath-style HD-2D): shops
  (convenience store, noodle shop, massage shop, pharmacy, a shuttered shop),
  shophouses, condo towers and an unbroken elevated skytrain track with trains behind them, a skyline, sidewalk and road
  tiles, street lamps and power poles, food carts, umbrella stalls, stools, plants,
  bins, cones, crates, a vending machine and bus stop, spirit houses (with Nang Kwak), cats and dogs, and a tuk-tuk,
  taxi, songthaew or motorbike parked at the kerb. Layers scroll at different speeds
  for depth, and leaves in front of the fighters scroll faster. Pieces are painted at
  twice the game size and drawn smoothly, so they stay sharp at any window size while
  the characters stay pixel art. Lamps glow. Depot, market and canal areas each
  have their own mix and tint.
- `tools/assets/kit_import.py` keys the pieces out of their green backdrops (green
  inside the outline, like the pharmacy cross, stays), trims, scales and lays out
  every area deterministically; `art/kit/kit.json` holds the recipe. The validator
  checks pieces against their sources and that layouts are current. Art by the
  project owner, credited in game. The generated sky stays; the generated buildings
  remain as a fallback.

### Added — A real punch sound
- Fists and kicks that land now sound like a punch, picked at random from six recorded
  hits so combos do not repeat one sound: "Punch 5" by jakeeaton (Freesound, CC-BY 4.0)
  and five punches cut from "multi punch" by Shikamarunara74 (Freesound, CC-BY 3.0),
  each trimmed so the impact plays within 20 ms. The in-game credits use each recording's attribution line
  as given, e.g. "multi punch.wav by Shikamarunara74 -- https://freesound.org/s/126317/
  -- License: Attribution 3.0".
- Four more punches from "Punches.mp3" by mrrap4food (Freesound, CC0 as listed), ten in
  all. That file's tags name a commercial library (Hollywood Edge), so it is kept only
  while the game is free: it is marked `replace_before_paid` and the validator reminds
  on every run (docs/ASSETS.md). Heavy blows play it lower with the old thump under
  it; weapon hits keep their own sounds. Credited in the in-game credits.
- `tools/assets/import_sounds.py` imports recorded sounds listed in
  `art/sounds/sounds.json` (cut, fade, normalise to -1 dBFS) with their authors,
  licence and source; the validator checks the licence against the policy and that the
  file matches a fresh import. The other supplied file (punches.mp3) was not used: its
  tags say "copyright 1999 Hollywood Edge", a commercial library.

### Changed — Riku at hero size
- Riku looked smaller than the NPCs: he was as tall as them in pixels, but his realistic
  proportions (small head, slim build) read smaller next to the big-headed LPC cast. He
  is now drawn 20% larger (about 60 px tall in his guard, in 80x80 frames), so he stands
  out as a hero. `FighterView` reads each art's frame size for the weapon hand and fist
  instead of assuming 64x64.

### Added — Riku Sato, the Boxer (third hero)
- A third playable hero with art by the project owner (walk and punch sheets in
  `art/custom/hero_riku/`): the all-rounder, between Mika and Oren on every stat
  (115 HP, 105% power, 1 defense, 100% speed). Jab on Z, cross on X, a guard-up idle.
  Skills: Liver Shot (fastest, long stun, breaks guard), One-Two (step-in knockdown),
  Dempsey Roll (weaving charge, breaks guard), Knockout Blow (big area finisher), each
  with its own icon. Starts with fingerless gloves, sneakers, buns and ginger tea.
- `tools/assets/custom_import.py` imports sheets drawn outside LPC: evens out sheets
  drawn at different sizes, scales to the game's size with crisp edges, adds the LPC-style
  dark outline, derives hurt and knock-down by tilting a frame about the feet (the art
  has no such frames), finds the fist for held weapons, and a portrait crop on the head.
  Credited to the project owner; the validator accepts owner art for `custom` sources.
- The "E Grab / Talk" hint moved right of the hotbar so it is not hidden at 1280x720.
- 1 new game test (139 total) and 2 pipeline tests.

### Fixed — Weapons stay in one hand and move like the weapon
- A held weapon now always sits in the same (near) hand, through idle, walk, swing, hit
  and dodge. Before, the socket followed whichever hand was closest, so the weapon
  jumped between hands.
- The fist closes around the handle: the weapon hand is drawn again over the weapon
  (a per-character `hands.png` cut from each frame with LPC's glove mask), so the
  handle sits inside the hand instead of lying across the back of it.
- Each weapon moves like itself: the knife **stabs** straight forward (new `stab`
  animation from LPC's one-handed slash, arm extended), while the bottle, plank, steel
  pipe, machete and chair **swing**: wound up behind the head, then brought forward and
  down in an arc. Before, every weapon pointed straight ahead and looked like a stab.
- Only enemies that can wield weapons go and fetch them; the Smog Warden (skeleton
  body, no one-handed swing in LPC) no longer wields. 3 new tests (138 total).

### Changed — Weapons sized to the hand
- Held weapons are redrawn at the characters' scale (knife blade ~9 px, bottle ~12 px,
  plank and pipe ~23 px, folding chair ~20 px) with slim, unoutlined handles so the fist
  still shows around the grip. Before, they were nearly half a character tall.

### Changed — Weapons stay on their street
- Walking into another area puts the held weapon down where the hero stood; it cannot be
  carried between areas. Each area keeps the weapons lying in it for the session, so a
  dropped weapon (with its wear) is still there on return. 2 new tests (136 total).

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
