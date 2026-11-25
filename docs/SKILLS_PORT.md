# Skills port

The class skills of the reference (World of ClaudeCraft, pinned `d2b91e08`) run in the
existing combat engine (`client/sim/RpgEncounter.gd` and its helpers). There is no
second combat system.

## How a status is decided

`tools/content/build_runtime_pack.py` classifies every ability into the runtime pack
(`client/data/rpg/runtime_pack.json`). It uses the evidence register
`tools/content/skills_port.py`:

- `EFFECT_FIELDS`: the effect arms the engine runs, and the fields each arm reads.
- `AURA_KINDS`: the aura kinds whose every consumer is ported.
- `DEF_KEYS`: the definition fields the cast rules read.
- `PORTED[(ability, file)]`: where the GDScript port of a reference branch lives.
- `NOT_BEHAVIOUR[(ability, file)]`: mentions audited as not changing a fight (UI
  lists, type unions, set bonuses no item grants, same-word ids).
- `EFFECTLESS_PORTED`, `PASSIVE_EVIDENCE`, `REQUIRED_AURA_PRODUCERS`, `NEEDS_GROUP`.

An ability is `IMPLEMENTED_*` only when everything it touches is covered. Otherwise it
is `BLOCKED`, with the missing piece named in its `reason`. `RpgCast` refuses any
ability that is not implemented.

## Adaptations (ADAPTED)

- The street is one axis. Radii, cones, "in front" and pulls are measured along `x`.
- Solo play: the only ally is the caster. Party effects reach the caster, and threat
  orders nothing because every monster fights the one player.
- Knockbacks move a monster along the axis at once instead of flying it on an arc.

## Open work

- Hunter and warlock: pets, demons and the trap, pack and affliction engines (about
  6,000 reference lines, including `src/sim/pet/`).
- Mage chronomancy and arcane, conjured items, Water Elemental. Priest Tithefiend and
  Spirit Bomb (both guardians).
- Resurrection spells need a dead group member, which the street does not have.
