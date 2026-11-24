# Non-negotiable rule: World of ClaudeCraft gameplay fidelity

**Set by the owner on 2026-11-17. A permanent project invariant.** It takes priority over
any conflicting instruction or proposal unless the owner explicitly changes it.

**Reference:** <https://github.com/levy-street/world-of-claudecraft>, at the commit
pinned in the registries: `d2b91e0884cb269422c28d0b42d2a30a01de130a`. Changing the pin
needs the owner's approval and a recorded version change.

## Scope

World of ClaudeCraft is the authoritative gameplay and systems reference for The Iron
Legacy. The rule covers every phase and system:

- classes, specialisations, talents and abilities;
- combat formulas and mechanics;
- player stats and progression;
- monsters, bosses, their AI and encounter mechanics;
- items, equipment and restrictions;
- rarity and per-copy quality;
- loot and drop probabilities;
- XP and levels;
- dungeons, elites, raids and world bosses;
- the Rift and endgame;
- professions and crafting;
- economy and rewards;
- PvP and PvE rules;
- quests and achievements;
- the player Guide and documentation.

## 1. Fidelity

- **Read the pinned source** before implementing or changing any gameplay rule.
- **Use source-backed values and mechanics,** never invented approximations.
- **No arbitrary values:** stats, multipliers, drop rates, item requirements, monster
  levels, damage formulas, cooldowns, ability effects, progression requirements,
  rewards or difficulty scaling.
- **A value that cannot be verified is UNKNOWN.** Stop short of inventing a
  replacement.

## 2. Adaptation

Adaptations are allowed only to fit The Iron Legacy's world, presentation or technical
architecture. Each one documents:

- the reference id;
- the reference value or behaviour;
- the adapted value or behaviour;
- the reason;
- the expected gameplay impact;
- validation and test evidence.

**Labels:**

| Label | Meaning |
|---|---|
| VERIFIED | matches the pinned reference |
| ADAPTED | differs on purpose, with the justification above; **never labelled VERIFIED** |
| PROPOSED | awaiting the owner's approval |
| UNKNOWN | not verified |

## 3. Relationships

Systems are never inspected in isolation. These links keep one authoritative data
source:

- class → specialisation → talent → ability;
- level → XP → progression;
- monster level → stats → AI → abilities;
- area → encounter → monster selection;
- monster → loot table → item → drop probability;
- slot → class restriction → item stats;
- quality → item level → progression;
- gameplay data → player Guide.

## 4. Identity

- **Keep The Iron Legacy's world,** scenes, maps, presentation and look.
- **Original display names** may replace reference names. Internal ids, reference
  mechanics and data stay, with an auditable name mapping.
- **No reference branding,** and no suggestion that The Iron Legacy is the original
  game.
- **Do not port the reference runtime** or rewrite the Godot project to imitate it.
  Adapt the architecture only as far as equivalent behaviour needs.

## 5. No silent deviations

If the reference does not fit:

1. document the conflict, with the exact source evidence;
2. present the smallest necessary adaptation and its consequences;
3. wait for the owner's approval when it changes gameplay rules or progression.

Content is never silently omitted, and mechanics are never substituted.

## 6. Validation, for every implemented system

- compare it with the pinned source;
- record the commit and the input hashes;
- add parity tests;
- test the dependent systems;
- check existing saves and legacy compatibility;
- confirm no unrelated rule changed.

The current evidence lives in
[REFERENCE_TRACEABILITY_MATRIX.md](REFERENCE_TRACEABILITY_MATRIX.md) and the
`data/registry/` and `client/data/rpg/` registries, built by
`tools/content/build_reference_registries.py`.
