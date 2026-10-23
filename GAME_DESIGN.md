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
| Mika Tanabe | Brawler | Balanced, long combo strings | Rising elbow launcher |
| Oren Vale | Bruiser | Slow, heavy, best guard | Shoulder charge that breaks guard |
| Sela Ruiz | Striker | Fast kicks, dodge-cancels | Spinning heel through a crowd |
| Juno Okafor | Tinkerer | Mid-range gadgets, traps | Deployable shock coil |
| Ivy Marlow | Medic | Support, buffs, sustain | Adrenaline field for the party |

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
  Simultaneous hits trade. Specials (meter) are not built yet.
- **[built]** All timings, damage, reach and knockback are data in
  `client/data/moves.json`, validated on load.
- Hits have hit stun, knockback and recovery. Elites telegraph their attacks. Only a few
  enemies attack at the same time (attack tokens) so crowds stay readable.
- All rules live in `client/sim/` as data plus pure functions, so the server can be the
  authority.

## World structure

City hub (social, no combat) · harbour depot (personal housing) · open districts (light
combat, gathering) · Murk farms (repeatable spawns) · elite hunting grounds (scheduled
elites) · boss arenas (instanced, multi-phase) · tunnel dungeons (party) · raids (later).

## Progression

Levels and XP per hero · skill unlocks and upgrades · equipment slots (weapon, armour,
2 accessories) with rarity and affixes · enhancement and crafting from Murk residue and
salvage · daily and weekly contracts · account-bound and tradable items · currency sinks:
repairs, enhancement, housing, travel.

All tables (XP curve, drop tables, affixes, prices) are data files, so balancing never
requires code changes.
