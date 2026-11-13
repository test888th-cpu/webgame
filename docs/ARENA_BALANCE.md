# Arena balance: measured results (2026-11-13)

Simulated data from `client/tests/harness/ArenaBalance.gd` (`ArenaSim`). **Both sides
are the arena's AI** (`ArenaBrain`). These numbers compare configurations; they do not
prove how real players fare. Nothing here changed a game rule.

How to reproduce:

```bash
godot --headless --path client --script res://tests/harness/ArenaBalance.gd -- --seeds=200
```

- **Matches:** 200 per comparison, seeds 1000 + n × 7919. Sides are swapped every
  other match.
- **Fighters:** built by `ArenaLoadout.resolve`, PvP kit, health ×2, 90 s clock, draw
  within 2 points.
- **Default side:** the Boxer (`job_order[0]`) at level 70, AI 0.7. Its personality is
  the one tier 5 assigns to its base rank, the same on both sides.
- **Brain settings:** the final ones (`ANTICIPATE_SHARE` 0.1).
- **Columns:** "A/B/draw" are win rates. Damage is the mean dealt per match, skills and
  guards are the mean per match, power is `ArenaRules.power`.

## Gear, at equal AI (0.7)

| A vs B | A win | B win | Draw | Mean s | Damage A / B | Power A / B |
|---|---|---|---|---|---|---|
| Godforged +0 vs Common +0 | 100% | 0% | 0% | 32.4 | 2,310 / 646 | 6,399 / 2,286 |
| Godforged +3 vs Godforged +0 | 99% | 0.5% | 0.5% | 56.5 | 3,284 / 1,944 | 9,548 / 6,399 |
| Godforged +7 vs Godforged +0 | 100% | 0% | 0% | 40.6 | 3,303 / 924 | 15,287 / 6,399 |
| Godforged +10 vs Godforged +0 | 100% | 0% | 0% | 32.5 | 3,323 / 509 | 20,940 / 6,399 |

At equal skill, any upgrade edge decides an AI-against-AI match: +3 already wins 99%.
What changes with the size of the edge is how lopsided the fight is: the +0 side
deals 1,944 damage against +3 but only 509 against +10.

## AI skill, at equal gear (Godforged +0)

| A vs B | A win | B win | Draw | Mean s | Guards A / B | Skills A / B |
|---|---|---|---|---|---|---|
| AI 0.9 vs 0.3 | 62.5% | 36.5% | 1% | 73.5 | 19.7 / 4.1 | 40.9 / 41.0 |
| AI 0.7 vs 0.5 | 59.5% | 39% | 1.5% | 76.1 | 13.9 / 7.9 | 41.4 / 40.8 |
| AI 1.0 vs 0.0 | 54% | 44.5% | 1.5% | 68.2 | 25.6 / 0.0 | 35.6 / 40.7 |
| +0 at AI 1.0 vs +7 at AI 0.3 | 0% | 100% | 0% | 44.3 | 11.5 / 2.4 | 24.9 / 25.8 |

- **Skill matters, but less than gear:** the best AI wins 54–62% at equal gear and
  cannot overcome +7 at all.
- **Tuning found and applied:** with anticipatory guarding at 20% of decisions, AI 1.0
  *lost* to AI 0.0 (45.5% against 53.5%). It guarded 50 times a match and attacked
  less. At 10% (shipped) the order is right. At 0% it is 54% to 44%, but the best AI
  never guards, so 10% was kept. Experiment: 100 matches per value.
- **Why the skill edge is small:** human reaction limits mean 177 of the 316 damaging
  moves are too fast to answer on sight. Better AI would need better decisions (spacing,
  baiting, whiff punishing), not faster reactions.

## Personalities, at equal gear and AI

| A vs B | A win | B win | Draw |
|---|---|---|---|
| Counter vs Aggressive | 47% | 53% | 0% |
| Tactical vs Balanced | 46.5% | 52.5% | 1% |
| Defensive vs Aggressive | 43% | 56.5% | 0.5% |

Personalities change how a fight looks: an aggressive rival presses more skills and a
defensive one guards more (`test_personalities_play_differently`). The effect on
results is small, with aggressive ahead by 3–7 points.

## Builds (presets)

Heavy, balanced, fast, critical and defensive all chose **the same items** for an Epic
Boxer at level 40, and every preset row read 49% / 50.5%. The real item list has only
2–4 Epic items per slot at that level, and one of them is better under every weighting.
So presets cannot create build variety where the item data has none. Build identity
today comes from naming items per slot (`slots.<slot>.item`, as `sovereign_full` does),
or from item data with real trade-offs (a content decision for the owner).

## Jobs, at equal gear (Godforged +0) and AI

**Superseded:** the combo weights changed after this run (2026-11-13), which moved several
matchups a lot. Current numbers: [SKILL_FLOW_REPORT.md](SKILL_FLOW_REPORT.md) §4.

| A vs B | A win | B win | Draw |
|---|---|---|---|
| Boxer vs Brawler | 10% | 86.5% | 3.5% |
| Boxer vs Grappler | 0.5% | 99.5% | 0% |
| Boxer vs Counter Fighter | 8% | 92% | 0% |
| Boxer vs Street Striker | 69.5% | 30.5% | 0% |
| Brawler vs Grappler | 1% | 99% | 0% |
| Brawler vs Counter Fighter | 17.5% | 82.5% | 0% |
| Brawler vs Street Striker | 12% | 83.5% | 4.5% |
| Grappler vs Street Striker | 100% | 0% | 0% |
| Counter Fighter vs Grappler | 11.5% | 88.5% | 0% |
| Counter Fighter vs Street Striker | 76% | 24% | 0% |

The AI-played Grappler beats every job (88.5–100%). This matches the earlier 1-against-1
measurement (`docs/GRAPPLER_AND_PVP_REPORT.md`, Oren 85–92% with this brain) and is
bot-dependent: the bot grabs at once and throws at once. The Grappler PvP compensation
is still the owner's open decision. Because rival jobs cycle by rank, the ladder's
Grappler rivals are harder than others of the same tier.

## The ladder, as configured

A player stand-in at AI 0.55 (balanced) in Godforged +0 at level 70, against the rival
in the middle of each tier:

| Rival | Tier | Stand-in win | Rival power |
|---|---|---|---|
| #48 | t1 | 100% | 109 |
| #43 | t2 | 100% | 261 |
| #38 | t3 | 100% | 569 |
| #33 | t4 | 100% | 875 |
| #25 | t5 | 100% | 3,951 |
| #18 | t6 (+1/+2) | 1.5% | 8,112 |
| #13 | t7 (+3/+4) | 0% | 10,386 |
| #8 | t8 (+5/+6) | 0% | 13,117 |
| #3 | t9 (+7) | 0% | 15,288 |

An unupgraded top-gear player clears the ladder up to rank ~21 and then stops: past
tier 5, a player needs upgrades at least close to the rival's. That is the intended
progression (upgrades unlock the top 20), but the step at #20 is sharp. A level-10
stand-in (AI 0.7) beat #50 in 10 of 10 matches after tier 1 moved to levels 3–10.

## Gear-cap experiment (not a game rule)

Each side's power, defense and health held to at most 1 + cap times the other's,
before the fight:

| A vs B | Cap | A win | B win | Damage B dealt |
|---|---|---|---|---|
| Godforged +7 vs +0 | none | 100% | 0% | 924 |
| Godforged +7 vs +0 | 30% | 100% | 0% | 1,573 |
| Godforged +7 vs +0 | 15% | 96.5% | 2.5% | 2,239 |
| Godforged +10 vs +0 | 30% | 100% | 0% | 1,541 |
| Godforged +10 vs +0 | 15% | 98% | 1.5% | 2,200 |

A stat cap like World of ClaudeCraft's 30% does not change the winner in this combat
model. It lengthens fights and halves the damage gap, but a capped edge in power,
defense and health still compounds (1.3³ ≈ 2.2× effective). Even a 15% cap leaves the
upgraded side at 96–98%.

## Recommendations (none applied; owner's decision)

1. **Keep the ladder's gear progression as it is.** The data shows upgrades are the
   gate past rank 20, and tier 6 begins at +1/+2. If the step at #20 is too sharp,
   soften it with data: lower tier 6's AI, or start it at +1 only. This needs no code.
2. **Do not add a PvP stat cap yet.** It does not do what a cap is meant to do here. If
   the owner wants skill to beat gear more often, the levers are in the combat rules
   (PvP damage scale, the value of a perfect guard or counter), and they need real-player
   tests: AI-against-AI equal skill makes any edge decisive.
3. **Keep health ×2** for now (unchanged, as asked). Matches last 32–83 s, so most end
   before the 90 s clock.
4. **Grappler:** decide the compensation in `docs/GRAPPLER_AND_PVP_REPORT.md`. Until
   then, the arena's Grappler rivals are its hardest.
5. **Build variety** needs item data with trade-offs, or named items per slot. Presets
   alone cannot create it from the current items.

## Limits

- Both sides are AI. A person reads, baits and adapts; these rates are not player
  win rates.
- The default side was the Boxer, one of the weaker jobs here.
- The ladder rows use one stand-in profile; they show where the gear gate is, not how
  every player experiences it.
