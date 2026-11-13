# Combat system: five classes (rebuild of 2026-11-13)

What each class fights with, the shared combo engine, the PvP-only rules, and how
distinctness and balance are checked. Built on the existing system: nothing that worked
was removed, and the approved Grappler PvE ×1.3 is kept. The owner's report with every
table (skills, ultimates, routes, animation coverage, matchups, PvE analysis):
[COMBAT_REBUILD_REPORT.md](COMBAT_REBUILD_REPORT.md).

## Completion matrix

✓ = implemented and covered by an automated test that ran and passed.

| Requirement | Boxer | Brawler | Grappler | Counter Fighter | Street Striker |
|---|---|---|---|---|---|
| Own light chain and light clip | ✓ base clip | ✓ wide stance, hook | ✓ thrust | ✓ short jab | ✓ fast jab |
| Own heavy attack | ✓ Overhand → Shovel Hook | ✓ Hammer Fist (armour) | ✓ Collar Tie | ✓ Check Hook (steps back) | ✓ Spinning Backfist |
| Active skills (6), own mechanics | ✓ step-in punches, energy drain, slip | ✓ armour, OTG pound, areas | ✓ grabs, throws, OTG wave | ✓ stances, catch-all parry | ✓ dashes, OTG chase |
| Area skill hitting several foes | ✓ Knockout Combo | ✓ Ground Pound, Wide Swing, Backhand Smash | ✓ Ground Slam, Crowd Toss | ✓ Reversal Strike | ✓ Dash Strike, Spinning Backfist |
| Combo routes (3) and finishers | ✓ | ✓ | ✓ | ✓ | ✓ |
| Skill → basic follow-ups | ✓ | ✓ | ✓ | ✓ | ✓ |
| Unique ultimate (own clip) | ✓ Knockout Devastation | ✓ Street Carnage | ✓ Titan Destruction | ✓ Absolute Retribution | ✓ Million Fist Onslaught |
| Identity passives (2) | ✓ Critical Focus, Combination Puncher | ✓ Pain Resistance, Crushing Momentum | ✓ Unbreakable Hold, Heavy Impact | ✓ Combat Awareness, Retaliation | ✓ Flow State, Slipstream |

Tests:
- `test_combat_rebuild.gd`: registry, heavies and clips, area attacks against two foes,
  ultimates, transitions, whiff, armour, PvP scaling, PvP throws, backstep;
- `test_class_mechanics.gd`: armour rules, grab immunity, catch-all parry, OTG, energy
  drain, passives, dodge cancel, refresh, every class move drawn, unique ultimates,
  PvP/PvE separation, arena matchup guard;
- `test_boss_combat_rules.gd`: every boss ungrabbable, no stance answers a boss's guard
  breaker, the auto battle holds no grab route against a boss;
- `test_combos.gd`: three routes per class, every route completed by a scripted
  player;
- also `test_skill_flow.gd`, `test_counter.gd`, `test_grab.gd`.

**Honest limits:**
- Animations are composed from the LPC base frames the characters are built from
  (`art/lpc/characters.json`: frames picked, reordered, borrowed from other moves and
  from the back and front views). They are not hand-drawn.
- Most skills play their class's own light or heavy clip. Signature moves have a clip of
  their own, and every class move that reaches behind the fighter plays a clip that turns,
  slams the ground or dashes through (`test_blows_all_around_play_a_turning_or_ground_clip`;
  checked on screen, `COMBAT_FINAL_REPORT.md`).

## Distinctness: the skill registry

`client/sim/SkillRegistry.gd` runs on every content load (CI fails on a problem). It
rejects:
- a class move used by another class (the engine's shared grab is allowed);
- two moves of different classes that play the same (timing, damage, hitstun,
  knockback, hitbox, movement, effects, armour, animation);
- two skills with the same sequence of moves, or a skill listed by two classes;
- an ultimate without an animation of its own (not a plain light, heavy, grab, throw or
  stance clip), or two ultimates sharing one.

## The shared combo engine (CombatRules, ComboRules)

| Piece | How |
|---|---|
| Input buffer | A press up to 12 ticks before an attack ends starts at once |
| Hit-confirm cancels | After a blow lands: basic → basic (chains), basic → skill, skill → skill, skill → basic (`chains` on a skill's last move) |
| Whiff recovery | A missed blow cannot be cancelled: full recovery |
| Combo routes | 3 per class (window, finisher bonus, gauge). A link may be the class's own `light` or `heavy` punch; a route always ends on a skill |
| Defence → counter | Counter stances catch a blow from the front and answer. Perfect Parry (`catch_all`) also catches guard breakers, but never a boss's (bosses' guard breakers stay unanswerable by stances). The Boxer's Slip Counter evades and answers |
| Grab → throw → follow-up | Grab skills, throws, bodies crashing into others; Ground Slam's wave and a light chain after it |
| Knockdown → follow-up | `otg` moves (Ground Pound, Ground Slam wave, Chain Breaker) hit a foe on the ground, for damage only (no relaunch) |
| Interrupt and reset | Being hit ends a route; a stance nobody hits breaks it |
| Stun-lock protection | Heroes: at most 40 ticks of hitstun in a row, wake-up grace 36 ticks |
| Heavy armour | `armor` on a move: not knocked out of it during startup and active ticks, and it cannot be grabbed then. A guard breaker breaks it. Monsters never break it otherwise; in PvP the armour takes one hero blow per swing |
| Backstep / step-in | A negative `advance` steps back (Check Hook). A skill's mode profile may scale its step (`advance`) |
| Dodge cancel | With a `dodge_cost` passive (Slipstream), a landed blow can be cancelled into a dodge |

## PvP-only rules (hero on hero)

| Rule | Why |
|---|---|
| Combo scaling: after the 3rd blow on a reeling hero, each deals 10% less, down to 50% | No loop takes a whole health bar |
| A thrown hero is down 60 ticks (PvE 90) and cannot be grabbed again for 1.5 s after getting up | No throw loop |
| Defense takes a share, defense / (defense + 90), not a flat amount | Flat defense between geared heroes wiped out light punches and many-blow skills (a jab did 1), so fights were races of the biggest single hits |
| The Brawler's armour takes one blow per swing | The Brawler could walk through a whole chain |
| The Boxer's step-in skills step their full distance (PvE: 60%, skill profile) | The Boxer's footwork against longer reach, without changing PvE |

PvE (monsters, bosses) is untouched by all of these (`test_pvp_only_rules_leave_pve_alone`).

## Class identities

- **Boxer:** footwork and precision. Stepping Heavy Cross, Body Blow (drains 35 energy)
  and Uppercut, the Slip Counter that ducks a blow and answers, a guard-breaking Overhand.
  Combination Puncher: each landed route link takes 0.75 s off the other cooldowns.
- **Brawler:** slow, armoured, area blows. The Hammer Fist and Backhand Smash cannot be
  grabbed or jabbed out of. Ground Pound also hits a fallen foe. Crushing Momentum:
  each landed blow adds damage and guard drain.
- **Grappler:** grabs and throws. The Collar Tie's long hitstun sets up a grab. Ground
  Slam's wave hits everyone around, fallen foes too. In PvP, no throw loop.
- **Counter Fighter:** reads and answers. Stances catch blows from the front. Perfect
  Parry even catches guard breakers. The Check Hook steps back.
- **Street Striker:** speed and movement. Dash Strike runs through a crowd. Chain
  Breaker dives after a fallen foe. Slipstream: cheap dodges and a dodge cancel after
  any landed blow.

## Balance (measured)

PvP: mixed bots (AI skill 0.3/0.55/0.8 and six personalities drawn per match), 200
matches per pair, seeds 1000 + n × 7919. `ArenaBalance.gd --only=jobs_mixed`. Both
sides are AI, so these are not real-player win rates.

| A vs B | A | B | Draw |
|---|---|---|---|
| Boxer vs Brawler | 98 | 102 | 0 |
| Boxer vs Grappler | 88 | 112 | 0 |
| Boxer vs Counter Fighter | 99 | 101 | 0 |
| Boxer vs Street Striker | 105 | 95 | 0 |
| Brawler vs Grappler | 84 | 116 | 0 |
| Brawler vs Counter Fighter | 89 | 111 | 0 |
| Brawler vs Street Striker | 102 | 98 | 0 |
| Grappler vs Street Striker | 91 | 108 | 1 |
| Counter Fighter vs Grappler | 116 | 84 | 0 |
| Counter Fighter vs Street Striker | 83 | 117 | 0 |

| Class | Before the rebuild | Round 1 | Now |
|---|---|---|---|
| Street Striker | 32% | 50% | 52.2% |
| Counter Fighter | 69% | 48% | 51.4% |
| Grappler | 80% | 57% | 50.4% |
| Boxer | 49% | 51% | 48.8% |
| Brawler | 19% | 44% | 47.1% |
| Best minus worst | 61 points | 13 points | **5.1 points** |

Every pair is between 42% and 58%. The old hard counters:
- Brawler over Boxer: 94/6 → 51/49;
- Grappler over Brawler: 88/11 → 58/42;
- Boxer over Street Striker: 78/22 → 52/48.

Matches last 46–59 s on average (round one: 51–76 s; with defense as a share, blows
land harder), and 1999 of 2000 end in a knock-out.

PvP skill damage multipliers: Brawler 0.7, Street Striker 0.64, others 0.6 (the
Grappler is back to 0.6 from round one's 0.5 now that defense is a share), ultimates 0.5.

PvE kills (auto battle, 3 minutes × 3 seeds on the level 9, 29 and 50 grounds):

| Hero | Before the rebuild | Round 1 | Now |
|---|---|---|---|
| Riku (Boxer) | 284 | 282 | 284 |
| Mika (Street Striker) | 237 | 256 | 253 |
| Kan (Brawler) | 239 | 230 | 227 |
| Oren (Grappler) | 221 | 205 | 212 |
| Dao (Counter Fighter) | 201 | 199 | 196 |

Kan and Dao are below the old numbers because their class heavy now ends every light
chain where the shared Haymaker did (restoring Haymaker in a scratch copy: Kan 227 → 257,
Dao 196 → 207). Oren is below because the auto battle keeps Power Throw for its route
(Collar and Throw) instead of spending it alone, the setting that survives the hardest
ground. Analysis: `COMBAT_FINAL_REPORT.md`.

Arena health scale (scratch experiment, not applied): × 1.2 brings matches back to
55–72 s (median 61 s) with the same balance; see `COMBAT_FINAL_REPORT.md`.
