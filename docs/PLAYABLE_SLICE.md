# The playable reference slice

**Status: PARTIAL.** A real, saved, single-player loop played by World of ClaudeCraft's
rules (`levy-street/world-of-claudecraft` at `d2b91e0884cb269422c28d0b42d2a30a01de130a`),
reached from the title screen as **Reference trial**. It is not the full game: most
classes cannot fight yet, most abilities do not run yet, and no area holds these mobs.
Every gap is listed below and shown in the game. Nothing here is invented: where the
runtime cannot reproduce a rule, it refuses the action and says why.

## 1. The loop, step by step

| Step | Status | How |
|---|---|---|
| Launch → title → Reference trial | DONE | `scenes/title/Title.gd` → `scenes/reference/ReferenceTrial.tscn` |
| Character: choose a class | DONE (9 classes) | `RpgCharacter.create`: level 1 wearing the class kit (`sim.ts:2795`) |
| Spec | DONE, modifiers not applied | `RpgCharacter.choose_spec` from `SPEC_UNLOCK_LEVEL` (5). The spec gates the spellbook exactly (the reference's `abilitiesKnownAt`), but its mastery and baseline modifiers are **not** applied (see §3) |
| Area | NOT IMPLEMENTED | No placement is approved (the matrix is PROPOSED). The trial is a list of reference world mobs (§2), not a map |
| Enemies | DONE (20 mobs) | Reference `MOBS` records that fight with their swing only (§2) |
| Real combat | DONE for warrior, paladin, rogue, shaman | `RpgEncounter`, `RpgSwing` (§4) |
| Auto-combat by default | DONE | `RpgEncounter.auto_mode`, on by default; it sends the same commands a player does |
| Manual commands | DONE | Attack, Stop, Auto on/off, cast. Every action goes through `RpgEncounter.command()` |
| Bosses | NOT IMPLEMENTED | Boss mechanics are not modelled; no boss is offered |
| Rewards | DONE | Kill XP (`damage.ts:1969`), corpse loot (`RpgLootRoll`, parity-tested), copper |
| Inventory | DONE | Bags, Take loot, Sell for `sellValue`. Loot left on a corpse is not saved: leaving the screen or reloading loses it |
| Equip / unequip | DONE | `RpgGear`: `canEquipItem`, `canEquipItemInSlot`, `resolveEquipSlot`, `displacedSlotForEquip` |
| Progression | DONE to level 20 | `RpgProgression` XP table; the stat sheet grows by class per level |
| Upgrades | NOT IMPLEMENTED | Trial loot is junk and the starter kit (the reference's world-mob tables in this set drop no gear); no upgrade system runs |
| Quests | NOT IMPLEMENTED | No reference quest runs; quest-gated loot rows draw nothing (no active quest), as the reference does |
| Save, exit, reload | DONE | `RpgSave` in `user://reference_slice.json` (temp file, read back, `.bak`); hero saves untouched |

## 2. Trial opponents

The monster selection matrix stays **PROPOSED** (owner decision F4), so no mob is placed
in an area. The trial offers the reference's own world mobs that this runtime can fight
faithfully (`tools/content/build_runtime_pack.py` `TRIAL_RULES`):

- a base-world `MOBS` record (`context: world`) of classification `normal`;
- not of a family that flees at low health (`mob/flee_rules.ts FLEEING_FAMILIES`; flight
  is not modelled);
- no mechanic and no special field (dummy, practice target, muster, idle, immunity);
- loot rows that use only chance, copper, item and roll group.

That leaves **20** mobs, levels 1–20 (`trial_monsters` in the pack; the 18 excluded world
normals and why are in `trial_excluded`). The player picks any whose level band reaches
within two levels of their own. The level of each fight is drawn `int(min, max)` with
the fight's generator (ADAPTED: there is no spawner). Display names are interim ids.

## 3. What a spec does not do yet

`computeTalentModifiers` (evaluated from the source) gives every spec stat and combat
modifiers, for example Arms `global.masteryTwoHandDmgPct` and Protection `stats.armorPct`.
The runtime applies **none** of them, nor talents, set bonuses or auras. The pack lists
them per class and spec (`spec_modifiers_not_applied`), and the character panel shows
them. A character with no spec has no modifiers (`[]` for every class), so a no-spec
character's fight is the reference's. Ability effects are the reference's resolved
values, spec masteries included (`abilitiesKnownAt` bakes them in).

## 4. Combat model

| Rule | Source | Status |
|---|---|---|
| Player swing: table, weapon roll, crit, armor, block | `auto_attack.ts meleeSwing` | VERIFIED by 400 parity cases |
| Mob swing | `sim.ts mobSwing` (crit 0.05 drawn, `mobArmorReduction`) | implemented from source; not parity-tested |
| Swing timers from 0, reset to speed / (1 + haste); dual wield, off hand ×0.5, white miss +0.1 | `tryPlayerSwing` | implemented from source |
| Warrior Battle Trance (0.2) and Arms Sudden Death (0.1) draws | `maybeProcBattleTrance`, `maybeProcSuddenDeath` | draws kept, auras not modelled (nothing in the slice reads them) |
| Warrior parry; shield block 0.05 and block value | `warrior_hit_table.ts`, `entity.ts:667`, `shield_block.ts` | implemented |
| Rage from dealing (white) and taking; warrior Battle Stance ×1.1 | `damage.ts:1277-1320`, `types.ts rageGenAuraMult` | implemented |
| Regen tick: energy +20, mana by Spirit (five-second rule), out-of-combat health, rage decay | `auras.ts updateRegen` | implemented |
| Cast gates and messages | `casting_lifecycle.ts castAbility` | implemented for the gates the slice can meet; a dead caster, a passive and the GCD refuse silently, as in the source |
| Abilities | `effect_dispatch.ts` weaponStrike general path | **1 of 424** runs (Stormstrike, enhancement shaman). Each of the 1,840 resolved entries carries EXECUTABLE or NOT_EXECUTABLE with its reason |
| Ranged auto attack (wands, auto shot) | `rangedSwing` | NOT IMPLEMENTED: hunter, mage, priest, warlock and druid cannot fight yet |
| Kill XP | `damage.ts:1851-1969` | implemented (elite ×2, `xpMult`, solo bonus 1) |
| Corpse loot | `loot_roll.ts rollLoot`, `enemy_quality.ts` | VERIFIED by 720 parity cases (incl. 79 minted qualities) |
| RNG | `rng.ts Rng` (mulberry32) | VERIFIED bit for bit, 5 seeds |

ADAPTED (register: PLAYABLE-*): fights start in melee contact with no movement; timers
count whole 60 Hz ticks (the reference steps 20 Hz in floating point); within a tick the
player acts before the mob; the regen tick starts with the fight; a defeated character
recovers by resting (no corpse run); a fresh character starts with full health, full mana
and energy and no rage.

## 5. Platforms and the desktop companion

- **Browser:** the slice is part of the web build (Godot web export).
- **Always on top:** a browser page cannot keep itself above other windows. Nothing in
  the web build claims to.
- **Desktop companion: BLOCKED.** It needs a desktop export preset and Godot's desktop
  export templates. Neither is in this repository or this environment (only the web
  templates are installed). A desktop build could then offer always-on-top through
  Godot's window flag. That is a later, separately approved task.

## 6. Data and evidence

- `client/data/rpg/runtime_pack.json`. Generated by `tools/content/build_runtime_pack.py
  --ref <checkout> [--check]` from the pinned source (static evaluation, never executed)
  and the committed registries. It holds:
  - the known abilities for each class, spec and level 1–20;
  - the resolved entries with their status;
  - the spec gaps;
  - the trial mobs and their loot;
  - the 11 items they and the kits use, with `requiredLevelFor`;
  - the swing constants.
- `client/tests/fixtures/rpg_runtime_parity.json`. Generated by
  `tools/content/runtime_parity_fixtures.py --ref <checkout> [--check]`. It runs the
  reference's own `Rng`, `rollLoot` and `meleeSwing` on scripted draws. Draws are stored
  as integers `k / 2^32`, so no JSON parser can change them.
- Tests: `test_rpg_runtime.gd` (parity, loop, gates, gear, XP, save) and
  `test_reference_trial.gd` (the screen: create, fight, loot, save, reload).

## 7. Online play

There is none. The backend has `/healthz`, `/readyz` and the accounts migration only: no
gameplay authority, no server-side progression, no trading, guilds or PvP. The slice is
single-player and local. No claim is made about concurrent users; none has been measured.
