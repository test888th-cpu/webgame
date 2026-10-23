# Game design (draft)

Everything here is original. No names, characters, maps, music or mechanics-specific
content is taken from River City Ransom, Kunio-kun or any other game. The genre conventions
used (side-scrolling street brawling with depth lanes, RPG progression, shops) are not
owned by anyone.

**Implemented so far:** one test street with a placeholder hero and a training dummy,
and the combat core below marked **[built]**. Everything else is design intent.

## Premise

**Port Verrin** is a harbour city whose old drainage tunnels have started venting *the
Murk*, a living smog that takes shape as creatures. Street crews, couriers and dock workers
fight it block by block. The player leads a five-person crew from a run-down depot in the
harbour district, which becomes their home base.

## The crew (roster of five)

| Hero | Archetype | Feel | Signature |
|---|---|---|---|
| Mika Tanabe **[built]** | Brawler (female) | Damage and mobility: 100 HP, 110% power, 110% speed, long combo strings | Rising Uppercut, Whirlwind Kick, Shoulder Rush, Furnace Slam |
| Oren Vale **[built]** | Bruiser (male) | Slow, tough, controls crowds: 130 HP, 100% power, 2 defense, 85% speed | Headbutt, Clothesline, Shoulder Charge, Earthshaker |
| Sela Ruiz | Striker | Fast kicks, dodge-cancels | Spinning heel through a crowd |
| Juno Okafor | Tinkerer | Mid-range gadgets, traps | Deployable shock coil |
| Ivy Marlow | Medic | Support, buffs, sustain | Adrenaline field for the party |

**[built]** New game opens hero creation: pick a hero (portrait cards, a large animated
preview, bio, play style, difficulty, stats compared across the roster, skills) and
name them (2–16 letters of any script, including Thai). Heroes are data
(`client/data/heroes.json`); each brings its own base stats, sprites (and armoured
look) and four skills to the hotbar. The save stores the hero and the name.

The player picks a main hero and develops all five. Persistent data (level, skills,
equipment) is stored per hero. Temporary combat state is never persisted.

## Combat pillars

- Movement along the street (x) and in depth (y). Depth is slower, a deliberate genre feel.
  **[built]**
- **[built]** Light, light, light combo (jab → cross → body hook; each link opens only
  after the previous hit connects); heavy haymaker from neutral or as a finisher, which
  breaks guard and costs energy; dodge with invulnerability frames (ticks 2–13 of 20)
  that costs energy; guard that blocks from the front only, takes 20% chip damage,
  drains energy and breaks when energy runs out; knockdown with invulnerable get-up.
  Simultaneous hits trade. **[built]** A 12-tick input buffer keeps presses made just
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
- Hits have hit stun, knockback and recovery. Elites telegraph their attacks. Only a few
  enemies attack at the same time (attack tokens) so crowds stay readable.
- All rules live in `client/sim/` as data plus pure functions, so the server can be the
  authority.

## World structure

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
