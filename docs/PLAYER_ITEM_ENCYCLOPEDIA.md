# Player item encyclopedia: the Guide

An in-game farming guide (`client/scenes/game/GuideScreen.gd`,
`GuidePages.gd`). It answers "what is this item, who drops it, where do they
fight, and what else can I farm there?". It reads the same data the game pays
drops from (`client/sim/LootIndex.gd`), so it cannot disagree with the game;
nothing in it is typed in by hand.

## Navigation

- **Opening it**: press **N** (gamepad: the share/capture button), or choose
  **Guide** in the Esc menu.
- **Tabs**: **Items**, **Monsters**, **Bosses** and **Maps**. Q/E switch
  tabs.
- **Each tab**: a search box, a filter and a sort order above a list on the
  left; the chosen entry's page on the right.
- **Links**: every name on a page links to its own page. You can go item →
  the monster or boss that drops it → the map it fights on → what else drops
  there. **< Back** returns along the way.
- **Search box**: while you type in it, letters are text, not hotkeys
  (`Game._physics_process`).

## Pages

| Page | Shows |
|---|---|
| Item | The item card: icon (placeholder art where final art is not in yet), name, grade colour, kind, required level, attributes, the comparison with what is worn, the description. Category, whether it can be upgraded (+0 to +10) or how far it stacks, what a material counts as at the workbench. **Where to obtain**: every source with its chance per kill, quantity, how (own drops, drop table, boss prize, ground prize, field elite, personal tier, kill reward) and where, each a link; shops with their price, quest rewards. An item with no source reads "Not currently obtainable". |
| Monster / boss | Portrait, name, kind (monster, elite, mini-boss, stage boss, world boss, raid world boss), levels and health, where it fights (links), and its drops or rewards: coins, then every item with chance, quantity, how and where, and the conditions of a field elite or a world boss tier. World bosses say their rewards are paid only if they fall within their round, to everyone who fought. |
| Map | Name, kind (story street, town, farming ground, lair, world boss arena), level and place on the road, the monsters and bosses there (links), and every item that can be farmed there with its best chance per kill (links). |

## Search, filters and sorting

| Tab | Search | Filter | Sort |
|---|---|---|---|
| Items | name or id | category (Weapons, Headgear, Outfits, Accessories, Enhancement Materials, Ores & Minerals, Consumables, Boss Materials, Special Items) or grade | grade, level, name |
| Monsters | name, or a map it fights on | elites, ordinary, or one map | level, name |
| Bosses | name, or a map | mini-boss, stage boss, world boss, raid world boss | level, name |
| Maps | name | story streets, towns, farming grounds, lairs, world boss arenas | level, name |

## Drop rates

- **Chances shown**: always the **actual chance per kill**, worked out from
  the rules (LootIndex), or "guaranteed".
- **Weights**: a selection weight (a catalog table's category or grade
  share) is never shown as a chance. Those shares are in
  `docs/ITEM_DROP_DATABASE.md` §G.
- **Visibility**: `client/data/progression.json` `"show_drop_rates"`
  (default `true`) shows the exact rates. Set to `false`, the Guide shows a
  word worked out from the same chance instead (`LootIndex.rarity`):
  guaranteed (100%), common (≥25%), uncommon (≥5%), rare (≥1%), very rare
  (≥0.1%), extremely rare.
- **Not yet balanced**: the catalog's drop values are initial balance values
  and need playtesting.

## How each drop line reads

Each line gives the chance per kill (or "guaranteed"), the quantity range,
its type, and where it comes from.

| Mark | Means |
|---|---|
| guaranteed | Always, on every kill. |
| random | An independent roll with the chance shown. |
| conditional | Paid only on a condition, written under the line: when the monster comes as a field elite (with that share of spawns), or a world boss's personal tier ("dealing N% of one player's share of its health") and kill reward ("paid only if the boss falls within its round"). |
| (rises) | Pity: the base chance shown rises after each kill without one, up to the cap written under the line (LootRules). |
| `*` | An initial balance value (the item catalog's drop tables), not yet playtested. A note under the list says so. |
| everything else | Confirmed: the game's own values. |

## Data sources

| Shown | Comes from |
|---|---|
| Items, stats, grades | `items.json` and `item_catalog.json` through `ContentDB`; the item card (`ItemCard.details`) |
| Monster and boss kinds | `LootIndex.kind_of`: enemies.json flags, lairs' `mini_boss`, `world_boss.json` (with `"raid": true`) |
| Where each fights | `LootIndex.places`: areas' placed enemies, fights, farming ground pools, lairs, world boss arenas |
| Levels, health | `LevelRules.enemy_level` / `enemy_stats` from the area's level |
| Drops and rewards | `LootIndex.drops`: own loot tables, the catalog's drop tables, farming grounds and field elites, world boss tiers and kills |
| Where to obtain | `LootIndex.sources`: the same, inverted, plus shops and quests |
| Maps | `LootIndex.area_info`, `MapRules.locate` |

## Indexed now

- 305 items (249 legacy, 56 from the catalog).
- 39 monsters (11 of them elites).
- 24 bosses (5 mini-bosses, 11 stage bosses, 5 world bosses, 3 raid world
  bosses).
- 57 maps (the PvP arena is left out: it is not a place to farm).

## Record status (from LootIndex)

- **Drop lines**: 4,490 in all.
  - 1,955 confirmed (the game's existing values) and 2,535 initial (the
    catalog's, not yet playtested).
  - 3,902 random, 553 conditional, 35 guaranteed.
- **Items**: 0 without a source.
- **Locations**: 0 enemies without a known place. Every location shown is
  confirmed from the area data, and none is inferred.

## Performance

Measured headless on the CI machine type, by `test_guide.gd`:
- **Every page**: all 425 pages open in 11.2 s, about 26 ms a page. That
  includes rebuilding a list of up to 305 rows on each navigation.
- **Search**: answers in well under half a second.
- **Index**: LootIndex builds every enemy's drops once per content and reuses
  them for sources and map pages.

## Godforged

The open question (all eight world bosses pay Godforged, while the rule says
raids only) is analysed, not changed, in `docs/GODFORGED_IMPACT_REPORT.md`,
generated from the data. In short:
- 15 Godforged items come from the five non-raid world bosses, and none has
  another source.
- The first Godforged is at Lv 32 today; with raids only it would be at
  Lv 56.

## Known gaps

- Every enemy has a known place: none is shown as unknown. An enemy a boss
  only calls in would read "Called in by …", and one with no place at all
  "Location unknown".
- Story and chapter: a map shows its place on the road (district and number,
  from `MapRules`), not quest or chapter names.
- Shops show their price, not the shop keeper's map.
- The Guide uses the landscape layout (640x360 canvas), like the other game
  screens, until their portrait designs (U1-B).

## Tests

- `client/tests/unit/test_guide.gd`:
  - every item, monster, boss and map is found by search, with no doubles;
  - an item lists every source, linked, and the link and Back work;
  - monster, boss and map pages list exactly the rules' drops and enemies;
  - exact rates or words;
  - a data change shows at once;
  - typing in search is not hotkeys;
  - nothing is made up for a missing place.
- `client/tests/unit/test_loot_index.gd`: the numbers themselves.
