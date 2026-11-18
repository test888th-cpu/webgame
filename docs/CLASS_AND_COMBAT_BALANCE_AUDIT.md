# Class and combat balance audit

**Date:** 2026-11-17. **Status:** cannot be completed yet; this file records why, and
what has been measured.

## What can be measured now

**Nine-class character sheets.** Values are computed by `RpgStats.sheet` from the
reference data and pinned by `test_all_nine_class_sheets_at_levels_1_and_20`. They are
VERIFIED against values worked from the reference formulas.

| Class | Lv 1 HP | Lv 1 resource | Lv 1 armour | Lv 1 AP | Lv 20 HP | Lv 20 resource | Lv 20 armour | Lv 20 AP |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Warrior (rage) | 90 | 100 | 90 | 46 | 812 | 100 | 356 | 122 |
| Paladin (mana) | 95 | 93 | 79 | 44 | 798 | 660 | 345 | 120 |
| Hunter (focus) | 69 | 100 | 95 | 39 | 725 | 100 | 361 | 115 |
| Rogue (energy) | 62 | 100 | 90 | 42 | 700 | 100 | 356 | 118 |
| Priest (mana) | 51 | 160 | 42 | 10 | 653 | 1,224 | 118 | 10 |
| Shaman (mana) | 68 | 108 | 72 | 36 | 733 | 1,068 | 300 | 74 |
| Mage (mana) | 54 | 180 | 49 | 10 | 665 | 1,491 | 125 | 10 |
| Warlock (mana) | 57 | 140 | 46 | 11 | 677 | 1,470 | 122 | 11 |
| Druid (mana) | 62 | 114 | 60 | 30 | 662 | 1,088 | 212 | 68 |

These are base sheets, with no gear, talents or abilities. **They are not a balance
verdict:** casters' power comes from spells, which are not implemented.

## What cannot be measured yet, and why

- **Damage, healing, sustain, crowd control and mobility per class and spec:** the
  abilities, specs and talents are not implemented (SKILL_DATABASE_CATALOG.md: 0 of
  327 kit abilities). Any number now would be invented.
- **Encounters for all nine classes:** the game's enemies and areas still run the
  legacy combat rules, and the nine classes are not playable.
- **Itemisation against class power:** items are still legacy (CONTENT_COMPLETENESS_AUDIT.md).

## Legacy game (current): existing measurements

- The five legacy heroes are measured by the existing harness: `client/tests/harness/`
  and `docs/HARNESS.md`, with boss and arena balance reports.
- These stay valid for the current build. They do not carry over to the reference
  classes.

## Plan (Phase D, after the class system exists)

1. Deterministic, seeded fights: each of the nine classes, and each spec, against the
   same normal, elite and boss enemies at levels 5, 10, 15 and 20, with reference item
   budgets for gear.
2. Report damage per second, time to kill, damage taken, resource over time, and
   deaths, with seeds recorded (docs/HARNESS.md conventions).
3. Each imbalance gets: the scenario, expected and actual results, the root cause, a
   proposed fix and a regression test. **No reference value changes without the
   owner's approval.**
