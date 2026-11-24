# Specialisation display names: PROPOSAL (not active)

**Date:** 2026-11-17. **Status:** PROPOSED, for the owner's review.

- **Not active:** the game shows no specialisation names yet, and the registry keeps
  INTERIM names (`client/data/rpg_reference.json`).
- **Approval:** applying these names is a data change to each spec's `display_name`
  after approval. Ids, roles, primary stats, signature abilities and restrictions do
  not change.

## Theme

Every name comes from The Iron Legacy's city: its trades, metals, machines, docks,
weather and shifts (NAMING_FRAMEWORK.md §3).

- **Form:** one compound word (two at most), so all nine classes read alike.
- **Pattern:** healer specs end in *-mender*, *-keeper* or *-ward*; tanks name a wall,
  hide or gate; damage specs name a tool, element or method.
- **Mechanics fixed:** each name describes what the spec actually does in the
  reference. For example the mage's Arcane spec is a healer there, so it is
  "Clockmender".

## Checks done

- **Reference content:** every name searched, whole word, in all 190 files of the
  reference's `src/sim/content/` at `d2b91e08`. **0 matches.** "Ironhide" was replaced
  by "Slagbear" because it occurs there 4 times.
- **Our own data and Story Bible:** every name searched in `client/data/*.json` and
  `docs/STORY_BIBLE.md`. **0 matches.**
- **Unique:** all 27 names are different.
- **Not done:** a web or trademark search (NAMING_FRAMEWORK.md §5 asks for one before
  release).

## Mapping

The reference name is shown **for internal traceability only** and must never appear
in the game.

| Class | Spec id (stable) | Role | Reference name (internal only) | Proposed display name | Why |
|---|---|---|---|---|---|
| Warrior | `arms` | dps | Battlecraft | **Steelwright** | a master of one great weapon, the steelworker's craft |
| Warrior | `fury` | dps | Bloodrush | **Overheat** | a fighter who runs hot, two weapons, rising rage (keeps the old Berserker identity without the reference's word) |
| Warrior | `prot` | tank | Ironguard | **Gatehold** | holds the gate: the shield-bearing tank |
| Paladin | `holy` | healer | Sunmender | **Lanternkeeper** | keeps the light burning: a healer |
| Paladin | `protection` | tank | Faithwarden | **Bulkhead** | a ship's sealed wall that takes the flood: a tank |
| Paladin | `retribution` | dps | Dawnreaver | **Hammerlight** | strikes with a hammer and with light |
| Hunter | `beast_mastery` | dps | Packlord | **Dockhound** | fights beside a hound from the docks: the pet spec |
| Hunter | `marksmanship` | dps | Coldsight | **Longsight** | the long shot |
| Hunter | `survival` | dps | Fieldcraft | **Trapwright** | traps and close work |
| Rogue | `assassination` | dps | Knifework | **Venomhand** | poison |
| Rogue | `combat` | dps | Thuggery | **Alleyblade** | the blade of the back streets |
| Rogue | `subtlety` | dps | Skulduggery | **Nightshift** | works the night shift: stealth |
| Priest | `discipline` | healer | Doctrine | **Ironvow** | an iron vow that shields: the absorb healer |
| Priest | `holy` | healer | Benison | **Bellward** | the bell that wards the city: a healer |
| Priest | `shadow` | dps | Vespers | **Smokeseer** | reads the smoke: shadow damage |
| Shaman | `elemental` | dps | Thundercall | **Coilcaster** | casts lightning through the coils |
| Shaman | `enhancement` | dps | Warspirit | **Sparkfist** | strikes with charged fists |
| Shaman | `restoration` | healer | Spiritcall | **Tidemender** | mends like the tide: a healer |
| Mage | `arcane` | healer | Chronomancy | **Clockmender** | mends time like a clockmaker: the reference makes this spec a healer |
| Mage | `fire` | dps | Pyromancy | **Furnaceborn** | born of the furnace |
| Mage | `frost` | dps | Cryomancy | **Rimeworker** | works the cold |
| Warlock | `affliction` | dps | Hexcraft | **Blightwright** | the craft of slow ruin: damage over time |
| Warlock | `demonology` | dps | Necromancy | **Pactbinder** | binds pacts and their demons |
| Warlock | `destruction` | dps | Ruination | **Cinderwake** | leaves cinders behind |
| Druid | `balance` | dps | Moongrove | **Skylight** | the light through the smog, sun and moon: a caster |
| Druid | `feral` | tank | Wildfang | **Slagbear** | the bear of the slag heaps: the reference makes this spec a tank |
| Druid | `restoration` | healer | Groveheart | **Rootmender** | mends with roots: a healer |
