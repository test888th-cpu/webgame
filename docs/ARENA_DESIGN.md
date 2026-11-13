# The Pit Arena: design, rules and configuration guide

The arena ladder: the player fights AI-controlled heroes one against one and climbs a
positional ranking to rank 1. First built 2026-11-13 (owner's request); extended
2026-11-13 with configurable rival equipment, personalities, human reaction limits,
spread opponent selection and hardened results. Story and names:
[STORY_BIBLE.md](STORY_BIBLE.md) §5.5.1. Balance measurements:
[ARENA_BALANCE.md](ARENA_BALANCE.md). Values awaiting the owner's approval are listed
at the end.

## Player flow

1. Iron City Central, talk to **Khru Sombat** (E). Open from level 10.
2. **Arena Ladder**: portrait, name, rank, best rank, power; wins, losses, draws, win
   rate and the current champion. Five rival cards: rank, portrait, name, job, level,
   gear grade and highest upgrade, AI level, power and a difficulty label (Easy, Even,
   Hard, Very Hard). **New rivals** (free, unlimited) and **Not now**.
3. **Fight** on a card opens the rival's **details**: every slot's item, grade and
   upgrade, style (personality), AI level and reaction time, power against yours, what a
   win or loss does. **Challenge** starts the match; **Back** returns to the ladder.
4. The arena: 3 s countdown (nobody moves), "FIGHT!", 90 s.
5. Result: VICTORY, DEFEAT or DRAW; how (knock-out or time, with health left), how long,
   the rank change, any reward. **Back to the ladder**, **Rematch** (when the rival is
   still offered) or **Leave the arena**.

No entry cost, no attempt limit, no cooldown.

## Ranking rules (positional swap, not Elo)

- Ranks 1 (champion) to 50 are rivals; a new player starts at #51, below them all.
- **Win against a rival ranked above:** the two swap places. Nobody else moves.
- **Loss, draw, or a win against a rival at or below your rank:** nobody moves. As
  champion such a win is a **title defense** (defenses and streak are counted; a loss
  ends the streak).
- Every result is kept in the history (last 20: match id, rival, result, reason, ranks,
  seconds, configuration version).
- Best-rank rewards are paid once each (`rewards` in `client/data/arena.json`).

### Integrity

- Every match has an id (`ArenaRules.begin`, a counter in the save). A result is applied
  only if its id is newer than the last recorded one, so a result cannot move a rank,
  pay or enter the history twice (`ArenaRules.record` returns `"duplicate"`).
- The match runs through fixed phases (`ArenaMatch.Phase`): PREPARING, COUNTDOWN,
  ACTIVE, VICTORY / DEFEAT / DRAW, RESULT_PROCESSING, RESULT_DISPLAY, RETURN. A phase
  never goes back; the result is processed once.
- **Forfeit:** when the countdown ends, the match is saved as *pending*. If the game
  closes during the fight, the next start records it as a loss by forfeit (no rank
  change), once. Leaving during the countdown costs nothing. Rank and history change in
  the same save that clears the pending match, so a failed save never pays twice.
- **Damaged save:** a broken ladder is repaired, not reset. Duplicates and unknown ids
  are dropped, a missing rival goes back at its starting rank, and the player keeps
  their position.
- The player's own health and ultimate gauge are snapshotted on entry and restored on
  exit (`ArenaMatch.snapshot`, `restore`). The arena's doubled health and its gauge
  never reach the city. Energy, statuses and stances belong to the arena fighter and end
  with it. Food, gear and inventory are never touched.

### Timeout and draw

At the clock, each side's **share** of its own maximum health is compared (never raw
health, so different maximums compare fairly). Shares within **2 percentage points**
(`draw_margin` 0.02) are a draw, otherwise the larger share wins. Both knocked out on
the same tick is a draw. Examples: 52% vs 31% wins; 46% vs 44.8% is a draw.

## Opponent selection (five cards)

`ArenaRules.choices`:

1. A window above the player: 16% of the player's rank, at least 5 and at most 40
   ranks (`selection`). It stretches past any rival that cannot be offered.
2. The nearest valid rival, then for each `selection.targets` ratio (0.75, 1.0, 1.25,
   1.6) the rival in the window whose difficulty ratio is closest. The cards run from
   easy to much stronger even where the ladder's power jumps between tiers.
3. **New rivals** moves the targets by up to ±15% (seeded by rank and refresh count, so
   the same state always shows the same five); the nearest card stays.
4. If even the hardest pick is Easy, the window doubles (up to the top).
5. With fewer than five rivals above, all of them are offered plus the ranks just below
   (defend). The champion is offered the five below.
6. A rival whose configuration has an error is never offered.

**Difficulty ratio** = rival power ÷ player power × (0.85 + 0.3 × rival AI skill).
Labels come from `difficulty` in the data (Easy < 0.85 ≤ Even < 1.1 ≤ Hard < 1.4 ≤ Very
Hard). **Power** = effective health × damage output, the same formula for both sides
(`ArenaRules.power`). Nothing shown is invented: every number comes from the rival's
resolved configuration and `PlayerProfile.stats`.

Measured examples (level and rank → cards):

| Player | Cards (rank, label, ratio) |
|---|---|
| Level 10 at #51 | #50 Easy 0.34, #48 Easy 0.70, #46 Even 0.98, #45 Hard 1.24, #44 Very Hard 1.52 |
| Level 24 at #51 | #50 Easy 0.14, #43 Easy 0.73, #41 Even 0.97, #40 Hard 1.26, #38 Very Hard 1.65 |
| Level 70 (starting gear) at #41 | #40 Easy 0.37, #34 Easy 0.72, #31 Even 1.06, #30 Very Hard 1.49, #29 Very Hard 1.82 |
| Level 70 (starting gear) at #12 | all Very Hard (10 to 14): ranked far above what the gear supports |

## AI opponents are player characters

The rival is a `Fighter` built exactly like the player's hero: a real `PlayerProfile`
(level, items equipped, upgrades), `PlayerProfile.stats`, `JobRules.equip`, the PvP
skill and combo kit, the player's stun protection, parry window and grab escape, the
hero's sprites. Damage, cooldowns, energy and reach are the shared `CombatRules`. Only
the controller differs: `ArenaBrain` produces a `FighterInput`, as a player's keys do.
No hidden damage, defense, speed, cooldown or range bonus exists.

**Fixed on 2026-11-13:** the arena marks the rival as the zone's "boss" for the HUD
health bar, and the boss-skill system replaced its job skills with an empty boss table.
Until this fix rivals fought with punches only. `BossSkills` now leaves an arena rival's
skills alone (`test_a_rival_keeps_its_job_skills_in_the_arena`).

### Human timing (all from data, `timing`)

| AI skill | Sees a blow after | Decides every | Mashes free every |
|---|---|---|---|
| 0 (Beginner) | 400 ms (24 ticks) | 100 ms (6) | 133 ms (8) |
| 0.5 | 300 ms (18) | 75 ms (5) | 108 ms (7) |
| 1 (Master) | 200 ms (12) | 50 ms (3) | 83 ms (5) |

A blow is invisible to the AI until it has been under way for the reaction time; only
moves with a long wind-up can be answered (139 of the 316 damaging moves have a startup
of 13 ticks or more). `min_reaction_ms` (200) is enforced: a configuration asking for
less is an error and is clamped. Like a player, it may also **raise its guard in
anticipation** when the foe is idle, close and facing it (at most 10% of decisions ×
skill × defend tendency; 20% made the best AI over-defend and lose to beginners, see
ARENA_BALANCE.md). That is a prediction from what is visible, never a read of
the foe's input.

AI skill also sets how often a blow is misread (60% at 0 to 15% at 1), and from which
skill it chains combos (0.25), dodges (0.15) and takes counter stances (0.4).

### Personalities (`personalities`)

| Key | Meaning |
|---|---|
| `approach` | chance per decision to close in when not attacking (0..1) |
| `attack_rate` | chance per decision to attack when able (0..1) |
| `defend_bias` | chance to answer a blow it has read, and weight of anticipation (0..1) |
| `combo_bias` | multiplies the preference for a combo route's next skill |
| `grab_bias` | multiplies the preference for grab skills |
| `stance_bias` | chance to answer with a counter stance rather than a guard |
| `spacing` | distance (px) it backs off to when it holds back |
| `punish_whiff` | chance to strike at once into a missed blow's recovery |
| `low_hp` | below 30% health: `steady`, `press` (all in), `turtle` (defend) or `kite` (keep away) |

Shipped: balanced, aggressive, defensive, counter, combo, tactical. Each tier spreads
five of them across its ranks.

## Equipment configuration guide (no code changes)

Everything about a rival is in **`client/data/arena.json`**, validated whenever content
loads (`ArenaLoadout.problems`, part of `ContentDB`; CI runs it). A rival's id is
`r<rank it starts at>`, `r1` to `r50`.

### Layers and precedence

A rival's settings are merged from, weakest first:

1. `defaults`
2. its **preset** (named by the strongest layer that names one)
3. its **tier** (`tiers`: ranges `[weakest rank's, strongest rank's]` spread over its ranks)
4. every `rank_overrides` entry covering its rank (narrower ones listed later win)
5. `opponents["r<id>"]`

**Per-slot beats ladder-wide:** `slots.<slot>.item / grade / plus / empty` always beats
`grades` / `plus` / `weights`, whatever layer each is in. The details screen and every
rival's `sources` list show which layers applied.

### Fields

| Field | Where | Meaning |
|---|---|---|
| `level` | any (tier: `[lo, hi]`) | the rival's level, 1..70 |
| `ai` | any (tier: `[lo, hi]`) | AI skill 0..1 |
| `job` | any | `boxer`, `brawler`, `grappler`, `counter_fighter` or `street_striker` (default: cycles by rank) |
| `name` | any | overrides the ring name from `names` |
| `grades` | any | grades allowed for automatic picks (`common` … `godforged`) |
| `plus` | any (tier: `[lo, hi]`, mixed across slots) | upgrade for every slot, 0..+10 (the game's `EnhanceRules` maximum) |
| `weights` | any, usually a preset | stat weights for automatic picks (`power`, `max_hp`, `defense`, `crit`, `attack_speed`, `speed`) |
| `preset` | any | a named entry of `presets` |
| `personality` | any | a named entry of `personalities` |
| `reaction_ms` | any | overrides the reaction time (never under `min_reaction_ms`) |
| `slots.<slot>.item` | any | this exact item (a real id of `items.json`) |
| `slots.<slot>.grade` | any | the best item of this grade for this slot |
| `slots.<slot>.plus` | any | this slot's upgrade, 0..+10 |
| `slots.<slot>.weights` | any | stat weights for this slot only |
| `slots.<slot>.empty` | any | nothing worn in this slot |

Slots: `head`, `body`, `hands`, `weapon`, `feet`, `charm`. Automatic picks choose, per
slot, the item with the best weighted score at or under the rival's level among the
allowed grades, as a player who collected gear would have it.

### Examples

Change one opponent's weapon from Godforged +3 to +5 (rank 13):

```json
"opponents": {
  "r13": { "slots": { "weapon": { "plus": 5 } } }
}
```

Give rank 1 a fully custom loadout (shipped: the `sovereign_full` preset plus +7 per slot):

```json
"opponents": {
  "r1": {
    "preset": "sovereign_full", "personality": "tactical", "ai": 1.0,
    "slots": {
      "head": {"plus": 6}, "body": {"plus": 5}, "hands": {"plus": 7},
      "weapon": {"plus": 7}, "feet": {"plus": 6}, "charm": {"plus": 7}
    }
  }
}
```

Change ranks 6–10 as a group (all their upgrades +6, Godforged only, a counter style):

```json
"rank_overrides": [
  { "ranks": [10, 6], "plus": 6, "grades": ["godforged"], "personality": "counter" }
]
```

A whole tier (the shipped tier 6):

```json
{ "id": "t6", "label": "Godforged +1/+2", "ranks": [20, 16], "level": [70, 70],
  "grades": ["godforged"], "plus": [1, 2], "ai": [0.68, 0.76],
  "presets": ["balanced", "heavy", "fast", "defensive", "critical"],
  "personalities": ["combo", "tactical", "counter", "aggressive", "balanced"] }
```

Mixed grades by slot (an Epic weapon, a Rare head, the rest from the tier):

```json
"opponents": {
  "r25": { "slots": { "weapon": {"grade": "epic"}, "head": {"grade": "rare"} } }
}
```

A new preset:

```json
"presets": {
  "glass_cannon": { "weights": { "power": 3.0, "crit": 2.0, "max_hp": 0.5 } }
}
```

### Validation (an error is never fixed by substitution)

On load, every rival is resolved and checked. An error is listed in `ContentDB.errors`
(CI fails) and the rival is **never offered** in the game:

- unknown item id; an item that is not equipment; an item in the wrong slot;
- an item whose level is above the rival's; an item that is not the slot's named grade;
- an unknown grade; no item of the allowed grades at or under the rival's level for a
  slot (for example a full Legendary set: no Legendary body or feet exist);
- an upgrade outside +0..+10; an item worn twice;
- an unknown preset, personality, job, slot, slot field or setting (typos);
- a level outside 1..70 or AI outside 0..1; a reaction under 200 ms;
- stats that do not compute; tiers that overlap or leave a rank uncovered.

### Versioning, live changes and rollback

- `config_version` (2) identifies the configuration; every rival carries it, and every
  match records it in the history.
- A running match keeps the rival it started with (`ArenaMatch.loadout`, a copy); a
  changed configuration applies to the next match. The player's own gear and the
  global item data are never changed by the arena.
- Changes are reviewed and rolled back through Git: revert the commit that changed
  `arena.json`. Raise `config_version` with any balance change, so history entries tell
  which configuration a result was fought under.

## The nine tiers (shipped configuration, real items)

Checked against `items.json`: Legendary has no body or feet items, and no Common charm
exists below level 53. Godforged covers every slot from level 56, so it is the top grade.

| Tier | Ranks | Level | Grades | Upgrade | AI | Power (measured) |
|---|---|---|---|---|---|---|
| t1 Street | 50–46 | 3–10 | Common, no charm | +0 | 0.00–0.10 | 53–149 (#48: 109) |
| t2 Contender | 45–41 | 12–20 | Common/Uncommon | +0 | 0.12–0.22 | #43: 261 |
| t3 Rare | 40–36 | 24–32 | Uncommon/Rare | +0 | 0.25–0.35 | #38: 569 |
| t4 Epic | 35–31 | 34–42 | Epic | +0 | 0.37–0.47 | #33: 875 |
| t5 Top grade | 30–21 | 44–70 | Epic/Legendary/Godforged (Godforged by 70) | +0 | 0.50–0.66 | #25: 3,951; #21: 6,350 |
| t6 | 20–16 | 70 | Godforged | +1/+2 mixed | 0.68–0.76 | #18: 8,112 |
| t7 | 15–11 | 70 | Godforged | +3/+4 mixed | 0.78–0.84 | #13: 10,386 |
| t8 | 10–6 | 70 | Godforged | +5/+6 mixed | 0.86–0.92 | #8: 13,117 |
| t9 | 5–1 | 70 | Godforged | +7 | 0.94–1.00 | #3: 15,288 |

Tier 1 was moved from levels 6–12 to 3–10 after the skill fix: a level-6 rival with
working skills was an even fight for a fresh level-10 player. At 3–10 a level-10
stand-in (AI 0.7) won 10 of 10 against #50.

## Match rules (both sides the same)

PvP skill profile; health ×2 (`hp_scale`, kept unchanged while balance evidence is
gathered); ultimate gauge starts empty; full energy; no food; no auto battle; no
leaving mid-match except by closing the game (a forfeit).

## Architecture

| Part | File | Role |
|---|---|---|
| Data | `client/data/arena.json` | tiers, presets, personalities, overrides, timing, selection, names, rewards |
| Rival configuration | `client/sim/ArenaLoadout.gd` | layer merge, item picks, validation, brain settings |
| Ladder | `client/sim/ArenaRules.gd` | ranks, repair, selection, difficulty, record-once results, forfeits, history |
| Match | `client/sim/ArenaMatch.gd` | phases, countdown, clock, KO/time/draw, snapshot/restore |
| AI | `client/sim/ArenaBrain.gd` | inputs with human timing and personality |
| Screens | `client/scenes/game/ArenaFlow.gd`, `ArenaScreen.gd` | ladder, details, result, forfeit on start |
| Balance | `client/tests/harness/ArenaSim.gd`, `ArenaBalance.gd` | measured comparisons |

Rules live in `client/sim/`, shared with the future server. The ladder and rewards are
in the local save while the game is single-player. Online, recording results and paying
rewards must move to `backend/` (CLAUDE.md: never trust the client for currency).

Tests: `test_arena.gd`, `test_arena_config.gd`, `test_arena_integrity.gd`,
`test_arena_screens.gd`.

## Art

The arena uses the Fight Club kit pieces for now (`arena` theme in `art/kit/kit.json`).
Prompts for its own pieces: [SCENE_PROMPTS.md](SCENE_PROMPTS.md) §6.

## Awaiting the owner's approval

1. Health ×2 (`hp_scale`) and the 90 s clock.
2. Best-rank coin rewards (500 / 1,500 / 4,000 / 10,000 / 20,000 / 50,000).
3. Names: Khru Sombat, The Pit Arena, the 50 ring names.
4. Entry level 10.
5. Tier 1 levels 3–10 (was 6–12), and all tier values, presets and personalities.
   Anticipatory guarding at 10% of decisions (tuned from 20%, measured).
6. Any PvP gear normalisation (see ARENA_BALANCE.md: not applied).
