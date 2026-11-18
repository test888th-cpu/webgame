# Original naming framework (proposal for approval)

**Rule:** gameplay mechanics and numbers come from World of ClaudeCraft (`d2b91e08`).
Every player-facing **name, description and piece of lore is original**
(ORIGINAL-CONTENT).

- Renaming never changes damage, cooldowns, costs, ranks, budgets or drop rates.
- Nothing has been renamed yet; this file defines how renaming will be done.

## 1. Identity versus display

| Layer | Example | Rules |
|---|---|---|
| **Internal id** | `heroic_strike`, `sovereign_fists`, `smogling` | Stable, snake_case, never shown to players. Existing ids stay (saves and loot tables use them) |
| **Reference link** | `"source": "woc:d2b91e08:heroic_strike#r2"` | Every adopted rule records its reference id, file and commit (traceability) |
| **Display name** | an original name | Lives in a display field (`name`) or a localisation table; changing it never touches the id or mechanics |
| **Description** | original text | Describes the real effect, with numbers filled from data (no hand-typed numbers) |

- **Adopted reference abilities get our own internal ids.** For example
  `il_warrior_strike` carries `source: heroic_strike`. Our ids never collide with
  reference ids and are never reused for bosses.
- **Boss and mini-boss skills keep their own `boss_skills.json` ids.**
- **A display name or id change for existing content** is listed in a mapping table
  (old → new) with a save migration.

## 2. Do not reuse reference names

Reference display names are World of ClaudeCraft content, and the brand and art are
restricted (`CREDITS.md`, `LICENSE` covers code only). Never ship any of these as
names:

- Its ability names, for example "Reaver Strike" for `heroic_strike`, or
  "Iron Bellow", "Onrush", "Direhowl".
- Its spec names, for example "Battlecraft", "Bloodrush", "Ironguard",
  "Knifework", "Pyromancy", "Chronomancy".
- Its item, monster, boss, zone or NPC names, for example "Pitted Shortsword",
  "Bogoak Staff", "Gilded Stag", "Balgath", "Eastbrook Vale".

Before naming anything:

- Check each new name against the reference's content files (a simple text search
  of `src/sim/content/`).
- Check it against a web search for existing games, as done for titles.

## 3. Tone and world

The world, scenes and atmosphere stay: an industrial port city, workshops, foundries,
docks, rail yards, markets, reactors, a city of iron and steam with Thai street life.

**Names should come from that world:** metals, tools, trades, machines, weather,
fire and water, streets and districts.

**Avoid:**

- generic fantasy compounds that sound like other MMOs;
- real company or brand names;
- real people's names;
- anything sacred or offensive.

**Magic (for the Mage class and its spells):**

- Lore to be written, for example as a learned discipline of the city (arc, ember,
  frost).
- The old Story Bible's "no magic" rule is superseded by this direction.
- The new lore needs a revised Story Bible section (decision N2).

## 4. Patterns per category

| Category | Pattern | Examples (proposals only) |
|---|---|---|
| Class display names | one plain word | Warrior, Assassin, Ranger, Mage, Paladin → for example "Steelward", Priest → for example "Chaplain" |
| Specialisations | an evocative noun or compound tied to the trade, not to reference names | Warrior: "Foundry-born", "Overheat" (the fury spec, which carries the old Berserker identity), "Gatehold"; Assassin: "Venomhand", "Alleyblade", "Nightshift" |
| Skills | verb + object, or a short noun phrase; at most 3 words | "Rivet Drive", "Slag Cleave", "Gutter Feint", "Ember Lance" |
| Talents | adjective + noun | "Tempered Grip", "Quick Fuse" |
| Weapons | material or trade + form | "Dockhand's Cutlass", "Smelter Axe", "Coil-wound Staff", "Gantry Longbow" |
| Armor | material + garment | "Riveted Vest", "Soot Hood" |
| Accessories | small object + quality word | "Brass Token", "Gearwheel Band" |
| Consumables | street food or workshop goods | "Rice Box" (kept), "Ginger Tonic" |
| Monsters | trade or place + creature or role | "Drainrat", "Kiln Hound" |
| Elites | title + monster | "Foreman Drainrat" |
| Mini-bosses | a person or machine with an epithet | "Old Ratchet, the Unwound" |
| Stage bosses | a named story figure (from the revised Story Bible) | |
| World bosses | a city-scale threat | "The Furnace That Walks" |
| NPCs | local first names with a trade | "Auntie Noi, Noodle Stall" |
| Locations | existing district names kept unless they conflict | |

## 4.1 Collision check of the examples

Every example above was searched in the reference's `src/sim/content/` at `d2b91e08`.

- **First drafts that collided, and were replaced:** "Bulwark", "Shade", "Warden"
  and "Berserker" all appear in reference content names.
- **Still in reference content:** "Chaplain" appears once in a mention (not as a
  display name) and needs review in the naming batch.
- **The display word "Berserker" for the fury spec is avoided,** because the
  reference uses "berserker" names (`berserker_stance`, `berserker_rage`).
- **The rest showed no match.**

## 5. Process

1. **Approve this framework**, and the lore decision for the Mage (N2).
2. **Inventory every display string with its id:** items, skills, enemies, bosses,
   NPCs, areas and quests. This can be generated from the data files.
3. **Name in batches by category.** Each batch is checked against:
   - the reference content files (no reuse);
   - a web search for conflicts;
   - the existing names, so there are no duplicates.
4. **Store the old → new display mapping**, for the changelog and support. Ids do
   not change unless a mapping and migration are approved.
5. **Revise `docs/STORY_BIBLE.md`.** It remains the single source of names; old names
   are kept in an appendix.
