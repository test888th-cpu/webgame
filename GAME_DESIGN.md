# Game design (draft)

Everything here is original. No names, characters, maps, music or mechanics-specific
content is taken from River City Ransom, Kunio-kun or any other game. The genre conventions
used (side-scrolling street brawling with depth lanes, RPG progression, shops) are not
owned by anyone.

**Implemented so far:** everything marked **[built]** below (eight areas, five heroes,
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

## The crew (roster of five)

> **Approved 2026-11-10:** five heroes, one job each (BLUEPRINT D15). Pong the Soldier left
> the roster (his saves continue as Kan). Plan, decisions and measurements:
> [docs/JOB_SKILL_PLAN.md](docs/JOB_SKILL_PLAN.md).

| Hero | Job | Feel | Ultimate |
|---|---|---|---|
| Riku Sato **[built]** | Boxer (male) | Precision and burst: 115 HP, 105% power, 1 defense; the hardest hits on one target, critical hits, a counter punch | Knockout Devastation |
| Kan Srisuk **[built]** | Brawler (male) | Pressure and area: 110 HP, 100% power, 1 defense, 105% speed; wide swings and ground blows that floor a crowd | Street Carnage |
| Oren Vale **[built]** | Grappler (male) | Grab, throw and control: 130 HP, 2 defense, 85% speed; every skill seizes a foe | Titan Destruction |
| Dao Kittikun **[built]** | Counter Fighter (female) | Defence and punishment: 120 HP, 95% power, 2 defense; **parries from 12 ticks out** (others 8); skills that catch a blow and answer it | Absolute Retribution |
| Mika Tanabe **[built]** | Street Striker (female) | Speed and combos: 100 HP, 110% power, 110% speed; four-punch combination, many light blows | Million Fist Onslaught |

**[built]** New game opens hero creation: pick a hero (portrait cards, a large animated
preview, bio, play style, difficulty, stats compared across the roster, skills) and
name them (2–16 letters of any script, including Thai). Heroes are data
(`client/data/heroes.json`); each brings its own base stats, sprites (and armoured
look) and its job; the job (`client/data/jobs.json`) brings the punches, the grab and nine skills. The save stores the hero and the name.

The player picks a main hero and develops all five. Persistent data (level, skills,
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
- **[built]** Each job has its own punch combination on the attack button
  (`client/data/jobs.json` `moveset`): Boxer jab, straight, heavy (longest reach; the last
  blow staggers); Brawler left, right, swing (wider, shoves hard); Grappler short, heavy,
  push; Counter Fighter quick, counter, heavy (lighter); Street Striker jab, cross, rapid
  jab, finisher (four fast, light punches). The heavy attack is shared.
- **[built]** Grab and throw: G (or E / USE / B with empty hands and nothing to pick up)
  seizes the foe in front; any attack throws them, and the thrown body knocks down others
  it meets. Holds end by themselves, a hit on the holder frees the foe. Only ordinary
  monsters and players are ever held: bosses and mini-bosses are shoved instead. Each job grabs its own way
  (`client/data/jobs.json` `grab`); the Grappler's is the longest and hardest.
- **[built]** Job skills (`client/data/skills.json`, kits in `client/data/jobs.json`): each
  job has six active skills, two passives and one ultimate. Active skills unlock at levels
  1, 2, 3, 5, 15 and 30, passives at 10 and 25, the ultimate at 50. The seven-slot hotbar
  starts as 1 attack, 2–5 the first four skills, 6–7 consumables; the Skills screen (V)
  shows all nine and puts any active skill or the ultimate on any slot. An active skill
  costs energy and has a cooldown (regular ones at most 4.25 s; up to two slower "big"
  ones per job); it can cancel an attack that has landed, so combos end in skills.
  Consumables share a 2-second cooldown so healing cannot be spammed.
  - **Skills of several blows** play their stages by themselves; each stage hits a foe
    once; being hit ends the skill.
  - **Counter stances** (Boxer's Counter Punch, most of the Counter Fighter's kit) catch a
    blow from the front and answer it; with nobody attacking they do nothing and leave an
    opening. Guard breakers, blows from behind and grabs go through.
  - **Skill grabs** (the Grappler's kit) seize a foe and throw by themselves; a boss is
    struck instead of held.
  - **Passives** are standing bonuses earned by how the hero fights (stacks from landed
    blows or parries, lost by missing or by time).
  - **Ultimates** need a full gauge (the gold bar under XP): it fills a little with every
    blow landed and with every share of health lost, so the losing side builds it too. R
    fires it, or a hotbar slot. Each is 2 to 3 times the job's strongest skill on one
    target, warns before it strikes, and has an answer: the Boxer's must be aimed, the
    Brawler's is spread over an area, the Grappler's cannot lift a boss, the Counter
    Fighter's does nothing unless attacked, the Striker's is lost on a foe who gets away.
  - **PvE and PvP are tuned apart**: every job skill carries two profiles of multipliers
    (`BalanceProfile`); PvP ones are placeholders until online play exists.
  `tests/unit/test_balance.gd`, `test_skill_pacing.gd` and `test_ultimate.gd` enforce these
  rules. The full kit tables are in `docs/JOB_SKILL_PLAN.md`.

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

**[built] Tutorial**: first-time steps in the Depot Yard (move, punch, heavy, skill,
dodge, guard and parry, pick up, throw, talk to Odo), each finished by doing it, shown
in the quest card's place, skippable from the menu; progress is saved (save v4).

## World structure

**[built] Iron City Central** (`main_city`) is the city hub, separate from the story
street. It is safe, and arriving heals the hero and refills the streets, as Depot Yard
does. It has:
- Win's taxi rank;
- a notice board with the current job, the world bosses unlocked, and planned services;
- a self-service kiosk with Ama's stock;
- a workbench for upgrades;
- a training yard.

The Trading Post and Guild Hall are planned and marked as such. You reach the city by
taxi from any stand or with the pause menu's **Return to Iron City Central** (from
any area, outside a fight), and a gate leads east to Depot Yard, the street's first area, which walks back west
into the city the same way, so the street is walked both ways from the city. Auto battle's
trip home, a knock-out and the return after a world boss still go to Depot Yard. See
[docs/CITY_AND_FARMING_BLUEPRINT.md](docs/CITY_AND_FARMING_BLUEPRINT.md) §12.

**[built] Area kinds (F0)**: every area is `street`, `city`, `world_boss`, `farm` or
`lair` (`client/sim/AreaRules.gd`). Existing areas carry no new fields: the city comes from
`city_area`, a world boss arena from its `world_boss` flag, the rest is the street,
and a street area's region is its district. A farming ground states `"kind": "farm"`,
its `region`, its `purpose` and its `unlock` rule: `{"reached": a story area}` or
`{"defeated": a boss}`, read from what the save already keeps. It is reached only by
Win's taxi (a Farming heading, shown once a ground is open), for the usual fare; its
one way out on foot is west to Depot Yard, and Recall and the pause menu's city ride
work there.

**[built] Farming grounds**: twelve optional areas; the first seven are one per chapter band, each with its
district's enemies, one elite and no boss (levels and line-ups provisional):
Saltmarket Backlots (4, after Rusted Corner), Rail Sidings (9, after the Refinery),
Harbour Stacks (15, after Container Yard), Plant Outskirts (22, after Waste Pools),
Network Backrooms (29, after the Counting House), Facility Annex (37, after Machine
Hall) and Core Overflow (50, after Director Wiroj). The level is a **suggested** level
for the fights there ("suggested Lv" on the taxi and map), never a requirement to
enter: a ground opens on its unlock rule alone. Core Overflow is for endgame materials
and coins and is the bridge from the story into levels 50 and beyond (the cap is 70; see
"Levels 50-70"). Core Spillway (43, after Commander Arthit) fills the levels 41-45 gap
before the final chapter, and four more grounds carry the hero from 50 to 70.

Fights repeat: once every fight in a ground is won, they all come back as soon as the
hero is back at its west end (walking back, arriving by taxi or loading a save there),
and a rest brings them back too. Auto battle farms an open ground round after round
the same way, without leaving it. Each pays less per minute than the best story area
of its district open at that point (measured with the harness at several hero levels).
No Hybrids appear in them.

**[built] The street so far**, east from the yard:

| Area | Level | Enemies | Boss |
|---|---|---|---|
| Depot Yard | 1 | training dummy (safe; two weapons to practise with) | |
| Saltmarket Street | 1 | Smoglings, Tar Rats, Pipe Brutes, Smog Warden (elite) | |
| Canal Works | 2 | the same, tougher | Sludge Foreman |
| Rusted Corner | 3 | Bottle Throwers (ranged: hang back and lob), Dock Thugs, Tar Rats, Smog Warden | |
| Rail Yards | 4 | Dock Thugs, Rail Bruisers, Smoglings, Tar Rats | |
| Night Market | 6 | Market Punks (fast combos), Thugs, Bruisers, Smog Warden; Kenji's Night Stall | |
| Fight Club | 7 | Punks, Rail Bruisers, a Bottle Thrower | The Pit Champion (mini-boss; charges below half HP) |
| Smokestack Refinery | 8 | Punks, Thugs, Bruisers, Refinery Enforcer (elite) | Furnace Baron (two phases: a wide furnace slam; below half HP a telegraphed 110 px charge that leaves him open for 40 ticks) |

**[built]** The way east is guarded: each exit opens once the hero has defeated the
enemy that holds it (Smog Warden, Sludge Foreman, 8 Dock Thugs, 10 Night Market Punks),
shown on the red exit sign with progress; the way back is always open. Resting brings every
won fight back for farming, but in an area already passed those fights hold no one in:
fight them, or walk on or back.

Chief Odo's quest chain continues past the Foreman: Rail Yard Rumble, Market Lights,
then The Furnace Baron. Better gear (rare to legendary, levels 5 to 8) drops and is sold
further east.

Long term:

City hub (social, no combat) · harbour depot (personal housing) · open districts (light
combat, gathering) · Murk farms (repeatable spawns) · elite hunting grounds (scheduled
elites) · boss arenas (instanced, multi-phase) · tunnel dungeons (party) · raids (later).

**[built] Levels 50-70** (`tools/content/level70_content.py` generates the data; every
value is a first pass, tuned there and re-run):

| Ground (Lv) | Monsters (elite) | Lair (Lv): boss | Opens after |
|---|---|---|---|
| Core Spillway (43) | Facility Troopers, Hazmat Sprayers (Core Sentinel) | Spillway Gatehouse (45): Spillway Chief | Commander Arthit |
| Coolant Vaults (53) | Vault Troopers, Vault Runners (fast), Coolant Drones (heavy) (Vault Warden) | Coolant Control Room (55): Commander Arthit, Reinstated | Director Wiroj |
| Reactor Underworks (58) | Tank Crawlers (fast), Underworks Brutes (heavy), Reactor Techs (ranged) (Reactor Overseer) | Tank Hall (60): Subject Twelve, Relapsed | Arthit, Reinstated |
| Foundry Depths (63) | Foundry Hands, Slag Slingers (ranged), Furnace Haulers (heavy) (Foundry Boss) | The Crucible (65): Unit K-7, Overdriven | Twelve, Relapsed |
| The Iron Heart (68) | Heart Guards (fast), Rivet Throwers (ranged), Iron Sentries (heavy) (Heart Keeper) | Heart Core Chamber (70): The Wiroj Protocol | K-7, Overdriven |

- A **boss lair** (`"kind": "lair"`) is a short arena off the street with one boss fight. It
  opens with its ground (the same unlock rule), is reached by Uncle Thong's truck
  ("Rematches"), is left west to the city, walls the hero in like any boss fight, and
  comes back after every rest, so its boss can be farmed. Farming grounds stay living
  fields with no fixed fight.
- Ground and lair open in a chain: each pair when the lair before falls. Levels stay
  suggestions; nothing is gated by level.
- New monsters appear only in the grounds past the story; the story's grounds still hold
  only enemies the story has already shown. Each 50-70 ground mixes three roles (a common
  fighter, a heavy hitter and a fast or ranged one) and a champion elite, all tinted in
  the tier's colour (enemies.json `tint`), so a monster that shares a sprite with a story
  enemy still reads as its own kind.
- The story ends at level 50: levels 50-70 are a farming endgame (grounds, lairs, world
  bosses, gear and upgrades), with no story quests by design.
- **Raid world bosses** (one per band past the story, each stronger and built for more
  players): The Floodgate Marshal (Lv 56, 15 players), The Crucible King (Lv 64, 20) and
  The Founder's Engine (Lv 70, 30), with their own arenas, moves and the new "quake" and
  "rain" skills. Every world boss fights armed (boss weapons last 2.5 times longer), pays
  **Godforged** prizes (the top grade, world bosses only) and escapes at the end of its hour.
  A boss defeated this round is down until its next round. See `docs/WORLD_BOSS_DESIGN.md`.
- The field truck lists every ground, lair and world boss in order of level, the closed ones
  greyed out with what opens them.
- **World bosses**: The Slag Titan (Lv 60, 5 players, every 6 hours, after Twelve,
  Relapsed; legendary Slagfist, Grip and Ember Core) and The Iron Sovereign (Lv 70, 10
  players, daily, after the Wiroj Protocol; the mythic Sovereign set). Like every world
  boss: unlimited entries and attempts, no daily limit, no wait, a shared pool per round.
- **Enrage** (`BossEnrage`, configurable in data): a lair boss enrages after 75 seconds,
  warned 10 seconds before (x1.5 damage, hazards and summons 30% quicker); a 50-70 world
  boss enrages for the last 20 minutes of its hour (x1.3, 20% quicker). Enrage only raises
  the pressure: it never ends a fight, takes an entry or limits food. 75 seconds was
  chosen over 60 and 90 with `tests/harness/EnrageCompare.gd` (see CHANGELOG). Lair bosses
  have twice the health of the story boss they come from (the Wiroj Protocol 1.3 times), so
  an on-level fight takes about 30-65 seconds and the enrage only catches slow fights.

## Progression

**[built]** Attributes (Max HP, Attack, Defense, Speed) are read-only: they come from
the hero, the level and the equipment, and the Status tab shows them as total plus the
gear bonus, with what the next level brings. **[built]** Six equipment slots (head, body,
hands, weapon, feet, charm). Items have a rarity (common, uncommon, rare, epic,
legendary), a required level, stat bonuses (penalties allowed, e.g. a heavy pipe slows
you) and a description; 15 items so far, sold by Ama or dropped by enemies, and each hero
starts with a small kit. Equipment changes stats at once and saves.

**[built] Grades up to mythic**: common, uncommon, rare, epic, legendary and mythic
(budget x1.85, only the Iron Sovereign's set). From level 53 each 50-70 tier has an
uncommon piece for every slot (the market, opened by the previous lair boss), rares (the
ground's monsters) and epics (the lair boss; the ground's elites rarely).

**[built] Upgrades**: each equipment slot goes from +0 to +10 at the Depot workbench
(10% more of the worn item's stats per level, kept by the slot when gear changes);
coins and Scrap Metal/Refined Alloy per attempt, 100% down to 20% success, failures
keep the item and its level; the odds never build up over failures (each try is at its
level's rate). The cost grows with the item's level
(`enhance.item_level_costs`: x2 coins and x1.5 materials from item level 51, x3 and x2
from 61), the success rates do not, and the workbench card shows what the next level adds. **[built] Materials** drop from enemies
(bosses always) and item cards say where every item comes from. **[built] Crit**
(5% base, Riku 8%) and **attack speed** (recovery only) come from gear.

Levels and XP per hero · skill unlocks and upgrades · equipment with affixes (later) · enhancement and crafting from Murk residue and
salvage · daily and weekly contracts · account-bound and tradable items · currency sinks:
repairs, enhancement, housing, travel.

All tables (XP curve, drop tables, affixes, prices) are data files, so balancing never
requires code changes.
