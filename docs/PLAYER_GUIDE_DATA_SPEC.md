# Player Guide: data specification (one source of truth)

**Date:** 2026-11-17.

- **Status today:** the in-game Guide exists. It opens with N, the share button on a
  pad, or the Esc menu, and has Items, Monsters, Bosses and Maps tabs. It is built on
  `LootIndex`, the same rules that pay the drops.
- **This spec:** how it grows to the reference systems without a second database.

## Principles

1. **The Guide reads the game's own registries and rules,** never a copy:
   - `ContentDB` for items, enemies, areas, shops and quests;
   - `LootIndex` for sources and per-kill chances;
   - `EnhanceRules`, or the reference upgrade if adopted, for upgrade costs and
     rates;
   - `RpgStats` and `RpgProgression` for class stats and XP;
   - the ability and talent registries once they exist.
2. **Chances are worked out, not typed.** LootIndex gives each drop's real chance per
   kill, with the conditional steps for selected drops. The Guide shows its text
   (`LootIndex.percent_text`). Unknown values show "Unknown / not verified", never a
   number.
3. **Availability is explicit:**
   - **Available now:** a source the player can reach.
   - **Not yet implemented:** a reference record not adopted.
   - **Unavailable:** for example a disabled catalog item.
   - **Unknown:** not verified.

   Content a player cannot reach is never advertised.
4. **Display names come from data.** Reference names never show
   (NAMING_FRAMEWORK.md).
5. **Spoilers.** The reference's Guide hides loot and balance numbers. Ours shows
   exact drop rates by the owner's request: an ADAPTED choice.

## Sections and their data

| Section | Data | Exists |
|---|---|---|
| Items | ContentDB items, LootIndex.sources, shops, quests, upgrade preview | yes |
| Monsters | ContentDB enemies, LootIndex.drops and places | yes |
| Bosses | the same, plus boss skills (`boss_skills.json`) | yes |
| Zones and farming | ContentDB areas, LootIndex.area_info | yes ("Maps") |
| Enhancement | EnhanceRules and progression.json, or the reference upgrade | partly (the item preview) |
| Classes, specs, talents | `rpg_reference.json`, plus the ability and talent registries | no (Phase 3–4) |
| Skills | ability registry; tooltips generated from the same fields | no |
| Equipment slots and grades | slot and rarity registries | no |
| Progression | RpgProgression (XP, cap, post-cap, prestige) | no (not connected yet) |
| Crafting and economy | not in the game | no |

## Validation that must exist (build-time, failing the tests)

Already enforced:

- every item has a source (content audit);
- drops name existing items;
- chances within 0..1;
- icons present (asset validator).

**To add as each registry lands:**

- Every Guide entry resolves to a registry object.
- Every player-facing item, skill, monster, boss and zone has a Guide entry.
- A shown drop chance equals `LootIndex` for that item and source: the Guide calls
  it, so a test spawns the Guide view and compares.
- A skill tooltip's numbers equal the ability record's fields.
- An upgrade preview equals the upgrade rules' cost and rate for that level.
