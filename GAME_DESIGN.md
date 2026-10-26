# Game design (draft)

Everything here is original. No names, characters, maps, music or mechanics-specific
content is taken from River City Ransom, Kunio-kun or any other game. The genre conventions
used (side-scrolling street brawling with depth lanes, RPG progression, shops) are not
owned by anyone.

**Implemented so far:** everything marked **[built]** below (six areas, three heroes,
two bosses, street weapons, equipment, quests, local saves). Everything else is design
intent.

> **Direction approved 2026-10-26:** the game becomes *The Iron Legacy*: Iron City and
> The Core (Port Verrin is its harbour district, the Murk its toxic smog), six classes and
> single player first. The story, names and places now live only in
> [docs/STORY_BIBLE.md](docs/STORY_BIBLE.md); plan and decisions in
> [docs/BLUEPRINT.md](docs/BLUEPRINT.md). Sections below describe mechanics as built; the
> Premise and crew sections are superseded by the story bible and are being migrated.

## Premise

**Port Verrin** is a harbour city whose old drainage tunnels have started venting *the
Murk*, a living smog that takes shape as creatures. Street crews, couriers and dock workers
fight it block by block. The player leads a five-person crew from a run-down depot in the
harbour district, which becomes their home base.

## The crew (roster of six)

| Hero | Archetype | Feel | Signature |
|---|---|---|---|
| Mika Tanabe **[built]** | Footballer (female) | Damage and mobility: 100 HP, 110% power, 110% speed, long combo strings | Rising Uppercut, Whirlwind Kick, Shoulder Rush, Furnace Slam |
| Oren Vale **[built]** | Street Brawler (male) | Slow, tough, controls crowds: 130 HP, 100% power, 2 defense, 85% speed | Headbutt, Clothesline, Shoulder Charge, Earthshaker |
| Riku Sato **[built]** | Boxer (male) | The all-rounder: 115 HP, 105% power, 1 defense, 100% speed; jab and cross from a tight guard | Liver Shot, One-Two, Dempsey Roll, Knockout Blow |
| Sela Ruiz | Striker | Fast kicks, dodge-cancels | Spinning heel through a crowd |
| Juno Okafor | Tinkerer | Mid-range gadgets, traps | Deployable shock coil |
| Ivy Marlow | Medic | Support, buffs, sustain | Adrenaline field for the party |

**[built]** New game opens hero creation: pick a hero (portrait cards, a large animated
preview, bio, play style, difficulty, stats compared across the roster, skills) and
name them (2–16 letters of any script, including Thai). Heroes are data
(`client/data/heroes.json`); each brings its own base stats, sprites (and armoured
look) and four skills to the hotbar. The save stores the hero and the name.

The player picks a main hero and develops all six. Persistent data (level, skills,
equipment) is stored per hero. Temporary combat state is never persisted.

## Combat pillars

- Movement along the street (x) and in depth (y). Depth is slower, a deliberate genre feel.
- **[built] Solid bodies** (`client/sim/Bodies.gd`): fighters, NPCs and street furniture
  (lamp posts and power poles at the kerb, bins, cones and crates in the road; kinds in
  `client/data/obstacles.json`, placed per area in `areas.json` "obstacles") cannot be
  walked through. A step at an angle slides along what it hits; walking straight into
  something stops you, so the player steps up or down the lane to get round. Enemies
  step round furniture and each other by themselves; nobody walks through the hero.
  Fighters reeling from a hit or knocked down do not block, and knockback is stopped
  only by furniture. Dropped loot, weapons, spawns and arrivals are moved clear of
  furniture so they can always be reached.
  **[built]**
- **[built]** Light, light, light combo (jab → cross → body hook; each link opens only
  after the previous hit connects); heavy haymaker from neutral or as a finisher, which
  breaks guard and costs energy; dodge with invulnerability frames (ticks 2–13 of 20)
  that costs energy; guard that blocks from the front only, takes 20% chip damage,
  drains energy and breaks when energy runs out; knockdown with invulnerable get-up.
  Simultaneous hits trade. **[built]** Stun-lock protection: hitstun the hero takes
  fills a meter that drains while they are in control; a hit that would push it past 40
  ticks knocks them down instead, and getting up gives 36 ticks of grace (the hero
  blinks; attacking ends it). A crowd can hold the hero helpless for at most 1.5 s.
  Enemies have no such protection, so hero combos still chain. **[built]** Perfect
  guard: guard raised at most 8 ticks before a hit from the front parries it (no
  damage, energy back, even against guard breakers); the attacker reels for 30 ticks
  and the first hit on them is a counter (1.5x damage). Letting go of guard closes the
  window for 24 ticks. Only the hero parries. **[built]** A 12-tick input buffer keeps presses made just
  before a swing ends.
- **[built]** Skills on a seven-slot hotbar (`client/data/skills.json`): 1 attack, 2–5
  skills, 6–7 consumables. Each skill is a move with an energy cost and a cooldown, and
  unlocks at a level. A skill can cancel an attack that has landed, so combos end in
  skills. Consumables share a 2-second cooldown so healing cannot be spammed.

  | Slot | Skill | Energy | Cooldown | Unlock | Role |
  |---|---|---|---|---|---|
  | 2 | Rising Uppercut | 10 | 4 s | Lv 1 | 26 damage; fast single-target knockdown; combo ender |
  | 3 | Whirlwind Kick | 20 | 7 s | Lv 1 | 22 damage; hits both sides; escape when surrounded |
  | 4 | Shoulder Rush | 15 | 6 s | Lv 2 | 28 damage; 90 px charge through a line; breaks guard |
  | 5 | Furnace Slam | 40 | 20 s | Lv 3 | 45 damage; big area knockdown; breaks guard |

  Balance (Mika / Oren): Mika is damage and mobility (power 110%, speed 110%, 100 HP,
  0 defense, shorter cooldowns, faster skills); Oren is toughness and control (power
  100%, speed 85%, 130 HP, 2 defense, wider skills and longer stuns, slower start-up).
  Oren's skills carry more base damage (28/24/30/50) so that with his lower power each
  slot lands within 15% of Mika's. The heavy attack (X/K) has no cooldown, so it is the
  weaker, energy-hungry option (13 damage, 20 energy) and every skill hits at least 1.5x
  as hard; the slot-5 skill is each hero's strongest. `tests/unit/test_balance.gd` enforces
  these rules.

  Energy (which also pays for dodges, guard and the haymaker) is the shared budget,
  which is why slot 7 holds Ginger Tea (restores energy). Skills and cooldowns are
  simulation state, so the zone server enforces them.
- **[built]** All timings, damage, reach and knockback are data in
  `client/data/moves.json`, validated on load.
- **[built]** Feedback: hit sparks (light, heavy, blocked), impact flash and a short
  pose freeze on hits, dust on knockdowns and dodges, an effect per skill, camera shake
  on heavy blows, a red vignette when the hero is hurt, a level-up light and banner, and
  sound for every action. All presentation only.
- **[built] Fair-fight rules** (`tests/unit/test_fairness.gd`): every enemy attack that
  opens a fight and floors the hero or breaks guard is telegraphed with at least 16
  ticks of warning; every telegraphed attack leaves at least 20 ticks to punish; every
  boss phase adds an attack, not only bigger numbers.
- Hits have hit stun, knockback and recovery. Elites telegraph their attacks. Only a few
  enemies attack at the same time (attack tokens) so crowds stay readable.
- All rules live in `client/sim/` as data plus pure functions, so the server can be the
  authority.

- **[built] Street weapons** (`client/data/weapons.json`): knife, bottle, wooden
  plank, steel pipe, machete, folding chair, frying pan, pipe wrench and baseball bat
  lie on the street (each area's
  `weapons` block says how many and which, by weight; stronger ones only from a
  minimum area level). E picks up the weapon underfoot (dropping the one in hand);
  with nothing underfoot the hero **throws** the held one: a short wind-up, then it
  flies about 160 px along the street, hits the first foe in its path for its heavy
  blow's damage (knocks down; bosses are only stunned; a guard blocks it from the front)
  and lands at their feet, or breaks if that was its last use. Enemies put weapons down
  instead. A weapon replaces Z/X with its own moves, always in the same hand: the knife
  stabs straight ahead, everything else swings from behind the head forward and down
  (knife: quick stabs and a lunge; pipe: long swings and a guard-breaking slam; chair: every swing
  knocks down but slows you; frying pan: the heavy bonk dazes and breaks a guard;
  wrench: quick and sturdy; bat: long reach and a heavy swing that sends them flying), wears out with each blow that lands (a bottle breaks
  after two) and is drawn in the fighter's hand, following every swing. **Anyone
  knocked down drops their weapon** and must pick it up again. Skills and items work
  as usual while armed. Weapons belong to their street: leaving an area puts the
  weapon down there, and it is still lying there on return (for the session).
- **[built] Area levels** (`client/sim/LevelRules.gd`): each area has a level, and its
  enemies fight at it: +20% HP, +8% damage, +2% speed (capped at +30%) and +1 defense
  every 3 levels above 1, with XP +25% and coins +20% per level. They also think
  faster (shorter reactions and pauses), from level 3 may guard when they see a
  wind-up, from level 5 may hop back out of reach and walk over to grab weapons, and
  enemies that `wield` may start armed (more often at higher levels). Enemy level
  shows over their heads.

## World structure

**[built] The street so far**, east from the yard:

| Area | Level | Enemies | Boss |
|---|---|---|---|
| Depot Yard | 1 | training dummy (safe; two weapons to practise with) | |
| Saltmarket Street | 1 | Smoglings, Tar Rats, Pipe Brutes, Smog Warden (elite) | |
| Canal Works | 2 | the same, tougher | Sludge Foreman |
| Rail Yards | 4 | Dock Thugs, Rail Bruisers, Smoglings, Tar Rats | |
| Night Market | 6 | Market Punks (fast combos), Thugs, Bruisers, Smog Warden; Kenji's Night Stall | |
| Smokestack Refinery | 8 | Punks, Thugs, Bruisers, Refinery Enforcer (elite) | Furnace Baron (two phases: a wide furnace slam; below half HP a telegraphed 110 px charge that leaves him open for 40 ticks) |

**[built]** The way east is guarded: each exit opens once the hero has defeated the
enemy that holds it (Smog Warden, Sludge Foreman, 8 Dock Thugs, 10 Night Market Punks),
shown on the red exit sign with progress; the way back is always open.

Chief Odo's quest chain continues past the Foreman: Rail Yard Rumble, Market Lights,
then The Furnace Baron. Better gear (rare to legendary, levels 5 to 8) drops and is sold
further east.

Long term:

City hub (social, no combat) · harbour depot (personal housing) · open districts (light
combat, gathering) · Murk farms (repeatable spawns) · elite hunting grounds (scheduled
elites) · boss arenas (instanced, multi-phase) · tunnel dungeons (party) · raids (later).

## Progression

**[built]** Attributes (Max HP, Attack, Defense, Speed) are read-only: they come from
the hero, the level and the equipment, and the Status tab shows them as total plus the
gear bonus, with what the next level brings. **[built]** Six equipment slots (head, body,
hands, weapon, feet, charm). Items have a rarity (common, uncommon, rare, epic,
legendary), a required level, stat bonuses (penalties allowed, e.g. a heavy pipe slows
you) and a description; 15 items so far, sold by Ama or dropped by enemies, and each hero
starts with a small kit. Equipment changes stats at once and saves.

Levels and XP per hero · skill unlocks and upgrades · equipment with affixes (later) · enhancement and crafting from Murk residue and
salvage · daily and weekly contracts · account-bound and tradable items · currency sinks:
repairs, enhancement, housing, travel.

All tables (XP curve, drop tables, affixes, prices) are data files, so balancing never
requires code changes.
