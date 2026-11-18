# Item system: catalog, drops, appearance, test merchant

How the item ecosystem added in November 2026 is built and configured. It sits
on top of the existing items (`client/data/items.json`, 249 items, unchanged)
and reuses the existing inventory, equipment, shop, enhancement and save
systems. Nothing here changes combat, progression, boss mechanics or the
universal animation library.

## 1. Audit summary (what was reused, what was added)

| Area | Existing (reused) | Added |
|---|---|---|
| Item definitions | `items.json` via `ContentDB.items`; grades `ContentDB.RARITIES` (6, by order) | `item_catalog.json`, merged by `ItemCatalog` (never over an existing id) |
| Grades and colours | 6 grade ids, budgets `ItemRules` | Colours: Epic gold, Legendary red, Godforged light blue (`ItemText.RARITY_COLORS`) |
| Loot | Per-enemy tables `LootRules` (unchanged), pity | `drop_tables.json` + `DropTables` (separate roll, separate RNG) |
| Inventory and saves | `PlayerProfile.inventory/equipment`, `SaveStore` | Nothing new is saved: new items are plain item ids |
| Equipment | 6 slots, `equip`/`unequip`, level gate | `Fighter.appearance` from `EquipmentLooks` |
| Appearance | Whole-sheet body `look` (2 items), hand sockets for street weapons | `EquipmentLayers` (head, outfit, fist gear) |
| Enhancement | Workbench costs in `progression.json`, `EnhanceRules` | Stand-in materials (`counts_as`), paying only |
| Shops | `ShopRules`, `TradeCart` cart, `ShopScreen` | Shop `price_each`, category picker, try-on |
| Icons | Generated UI sheet (`manifest.json` "ui") | Runtime placeholder icons (`PlaceholderArt`) |
| Multiplayer | Not built yet (M3/M4) | Appearance kept on `Fighter` (simulation state), ready to replicate |

## 2. Separate names

| Concept | Where | Example |
|---|---|---|
| Item ID (permanent) | `item_catalog.json` key | `crimson_warlord_helm` |
| Icon asset | item `"icon"` → UI sheet, else `placeholder_art.json` "icons" | `ph_crimson_warlord_helm` |
| Appearance ID (permanent) | item `"appearance"` | `look_head_crown` |
| Appearance asset | `appearances.json` "asset" → `placeholder_art.json` "appearance_assets" | `ph_look_head_crown` |
| Equipment slot | item `"slot"` | `head` |
| Item stats | item `"stats"` (checked against `ItemRules` budgets on load) | `{"defense": 10, "max_hp": 64}` |

Replacing art changes only the asset or icon entries: item ids, inventories,
saves, drop tables and upgrade levels stay as they are. An icon id present in
the UI sheet wins over a placeholder of the same id.

## 3. New items (37)

| Category | Items (grade) |
|---|---|
| Enhancement materials | `enhance_stone_basic` (Common, counts as 1 Scrap Metal), `enhance_stone_refined` (Uncommon, 3 Scrap Metal), `enhance_stone_advanced` (Rare, 1 Refined Alloy), `enhance_catalyst_rare` (Epic, 3 Refined Alloy), `enhance_catalyst_special` (Legendary, 8 Refined Alloy, bosses only) |
| Ores and minerals | `ore_iron`, `ore_copper` (Common), `ore_refined`, `mineral_rare` (Uncommon), `mineral_azure` (Rare), `mineral_gilded` (Epic), `mineral_crimson` (Legendary, bosses only) |
| Consumables (energy) | `focus_gum` (Common), `energy_drink_ironworks` (Uncommon), `adrenal_shot` (Rare), `second_wind_tonic` (Epic) |
| Headgear | `patched_street_cap` (Common, Lv 4), `reinforced_bandana` (Uncommon, Lv 9), `riveted_work_helmet` (Rare, Lv 15), `gilded_brawler_helm` (Epic, Lv 22), `crimson_warlord_helm` (Legendary, Lv 30) |
| Outfits | `canvas_work_shirt`, `padded_street_jacket`, `riveted_dock_coat`, `gilded_fight_robe`, `crimson_warlord_mantle` (same grades and levels) |
| Weapons (fist gear) | `wrapped_iron_knuckles`, `copper_plated_knuckles`, `azure_steel_knuckles`, `gilded_crusher_gauntlets`, `crimson_warlord_fists` (same grades and levels) |
| Boss materials | `wiroj_protocol_chip` (Director Wiroj), `baron_furnace_core` (Furnace Baron), `chen_anchor_link` (Harbourmaster Chen), `k7_reactor_cell` (Unit K-7) |
| Special items | `iron_legacy_relic` (Epic), `founders_crimson_sigil` (Legendary) |

- Gear stats come from the existing budget formula (`ItemRules`), so each
  grade is the same step up as in the rest of the game.
- Legendary gear and Legendary materials are `boss_only`. No new item is
  Godforged, which stays a world boss reward.
- The new consumables restore energy only. Your rule that "every HP food is
  sold at Ama's" and the unlimited HP food rule are untouched.
- Ores have no crafting use yet (no crafting system exists). They sell, and
  wait for one.

## 4. Drops

`drop_tables.json`, rolled by `DropTables` after an enemy's own loot table
(which is unchanged). Each roll goes through these steps:

1. **Chance**: per roll, with `rolls` rolls per kill.
2. **Category**: weighted.
3. **Grade**: the source's grade weights, limited to the grades the category
   has. These weights are shares of a successful drop, not chances per kill.
4. **Item**: chosen evenly among the eligible items of that grade.
5. **Quantity**: per category.

Each named boss also rolls its own list (`bosses`).

| Grade weights | Ordinary monster | Boss |
|---|---:|---:|
| Common | 75 | 40 |
| Uncommon | 20 | 35 |
| Rare | 4.5 | 20 |
| Epic | 0.5 | 4.8 |
| Legendary | 0 (enforced) | 0.2 |
| Godforged | 0 (enforced) | 0 (enforced) |

| Table | Who | Chance x rolls | Categories |
|---|---|---|---|
| `street` | every ordinary monster | 8% x 1 | enhancement 35, ore 40, consumable 15, headgear/outfit/weapon 10 |
| `boss` | every story boss and mini-boss | 100% x 2 | enhancement 30, ore 30, consumable 10, headgear/outfit/weapon 30 |

Never:
- World bosses (their rewards stay `world_boss.json`'s) and anything in a
  world boss arena.
- The training dummy.
- Arena (PvP) rivals.

Eligibility is enforced in code and in content validation:
- An ordinary monster never rolls Legendary, Godforged or `boss_only` items.
- An item with `sources` comes only from those bosses' own lists.

### Expected outcomes (from the configured numbers, `DropTables.chances`)

| Per ordinary monster kill | Chance | About |
|---|---:|---|
| Any new item | 8% | 1 per 12.5 kills |
| A Rare item | 0.36% | 1 per 278 kills |
| An Epic item | 0.04% | 1 per 2,500 kills |
| A specific Epic gear piece (e.g. Gilded Brawler Helm) | 0.0014% | 1 per 73,500 kills |
| Legendary or Godforged | 0 | never |

| Per story boss kill | Chance | About |
|---|---:|---|
| A Rare item | 39% | 1 per 3 kills |
| An Epic item | 9.6% | 1 per 10 kills |
| Any Legendary item | 0.36% | 1 per 278 kills |
| A specific Legendary gear piece (generic table) | 0.04% | 1 per 2,500 kills |
| Wiroj / Baron / Arthit signature Legendary (own list, 0.5%) | ~0.54% | 1 per 185 kills of that boss |
| Wiroj Protocol Chip (own list) | 25% | 1 per 4 kills |

These are first configuration values and are not yet balance-tested. Tune
`drop_tables.json` after playtesting; nothing in code needs changing.

### Bosses' own lists

| Boss | Own drops |
|---|---|
| Director Wiroj | Protocol Chip 25%, Crimson Warlord Helm 0.5%, Iron Legacy Relic 3% |
| Furnace Baron | Furnace Core 25%, Crimson Warlord Fists 0.5%, Iron Legacy Relic 3% |
| Commander Arthit | Crimson Warlord Mantle 0.5%, Gilded Mineral 10%, Iron Legacy Relic 3% |
| Harbourmaster Chen | Anchor Link 30%, Azure Mineral 15% (1-2) |
| Unit K-7 | Reactor Cell 25%, Gilded Mineral 10% |
| Big Sak | Azure Mineral 15% |
| The Ringmaster | Azure Mineral 15%, Advanced Enhancement Stone 20% |
| Subject Twelve | Crimson Special Mineral 1%, Special Enhancement Catalyst 1%, Founder's Crimson Sigil 0.2% |

## 5. Enhancement

The workbench's costs, odds, levels and limits are unchanged. An item with
`"counts_as": {"scrap_metal": 3}` can pay that much of a material
(`EnhanceRules.available` / `_pay`):
- The material itself is used first, then stand-ins, the smallest first.
- A stand-in worth more than what is still owed is used whole: there is no
  change given.
- The item card's cost line counts stand-ins.

## 6. Equipment appearance (temporary)

- **Data**: `EquipmentLooks` works out `{slot: appearance id}` from what is
  worn whenever the hero is refreshed (equip, unequip, load), and keeps it on
  `Fighter.appearance`. It is never saved separately, so it can't drift.
- **Drawing** (owner's decision, November 2026): only headgear is drawn.
  `EquipmentLayers` puts the hat **in place of** whatever the character's own
  art has on its head (hair, a cap):
  - Each frame, the top COVER_DEPTH (9) drawn rows of the head are measured
    from the frame's own pixels (cached per frame).
  - The hat's crown is stretched over all of them, so the old headwear is
    hidden. It never shows next to or under the new hat.
  - Equipping a second hat swaps it: the old one goes back to the bag, and
    one hat is drawn.
  - It follows every move and both facings, for every job, with no
    job-specific animation.
  - Outfits and weapons keep the character's own look. Their appearance ids
    stay on the fighter for later art, and nothing is drawn for them.
- **Placeholders**: `PlaceholderArt` draws the art at runtime from
  `placeholder_art.json`. There are no image files and nothing goes through
  the asset or licence pipeline.
  - Icons are 16x16, a silhouette per kind in the grade colour, with a
    black and white check in the bottom right corner meaning "temporary".

Known limitations:
- The hat is an overlay stretched over the head's top rows. It does not tilt
  with the head, and long hair below those rows still shows.
- Only the player's hero shows gear: enemies and arena rivals have no
  appearance data.
- No multiplayer exists yet. The appearance lives on the simulation's
  `Fighter`, so a server can send it with the rest of the fighter's state.
- Hat art from the owner: see section 9.
- Final art from the Blender 5.2 pipeline goes in under the same asset ids.
  For that, `EquipmentLayers` will need per-frame attachment data or
  pre-rendered layers matched to the body's frames. That is a planned change
  to `EquipmentLayers` only: items, saves and drop tables stay as they are.

## 7. Item Testing Merchant

**Where**: Iron City Central, x 1140, beside the arena master.

**What it sells**: every enabled catalog item, in 8 sections: Enhancement
Materials, Ores & Minerals, Consumables, Headgear, Outfits, Weapons, Boss
Materials, Special Items.

**How it works**: it uses the ordinary cart (`TradeCart`): quantities, a
total, confirmation, coins taken and the bag filled. Equipment you own can be
tried on and taken off from the item card, and shows on the hero at once.

**Price**: the token price (`price_each`, 1 coin), but never below what a
shop pays back for the item plus one coin. Buying to sell back can never make
coins, and nothing is free.

**Switch**: `TEST_VENDOR_ENABLED`. The environment variable of that name
(`1`/`0`) wins; otherwise the project setting
`iron_legacy/test_vendor_enabled` in `client/project.godot` decides.
- It is **on** now, in every build including the web export, so it can be
  tested in the browser.
- Set it to `false` before any production release. The item data stays; only
  the merchant goes.
- Content loaded without the game (tests, a future server) never has the
  merchant.

## 8. Files

- **Data**:
  - `client/data/item_catalog.json`
  - `client/data/drop_tables.json`
  - `client/data/appearances.json`
  - `client/data/placeholder_art.json`
  - `client/data/test_vendor.json`
- **Rules**:
  - `client/sim/ItemCatalog.gd`
  - `client/sim/DropTables.gd`
  - `client/sim/EquipmentLooks.gd`
  - edits in `ContentDB` (load and validate), `ZoneSim` (drop roll, appearance),
    `Fighter` (`appearance`), `EnhanceRules` (stand-ins), `ShopRules`
    (`buy_price`), `TradeCart`, `ItemSources` (the new drops in "Where to get"),
    `ArenaLoadout` (rivals keep the arena's own gear)
- **Presentation**:
  - `client/scenes/ui/PlaceholderArt.gd`
  - `client/scenes/fighter/EquipmentLayers.gd`
  - edits in `FighterView`, `UiKit.icon`, `ShopScreen` (categories, try-on),
    `ItemCard` (stand-ins), `ZoneView`/`Game` (the merchant's role),
    `GameSession` (the switch)
- **Tests**:
  - `client/tests/unit/test_item_catalog.gd`
  - `client/tests/unit/test_item_testing_merchant.gd`
  - `client/tests/unit/test_grade_standard.gd`

## 9. The owner's hats: TEMPORARY / PLACEHOLDER (24 sprites)

**Status**: these hats are temporary placeholder art. They exist to build and
test the equipment appearance system and are not production art.
- Their look, style and resolution are not final.
- No production licensing or approval is sought for them.
- Every entry is marked `"status": "placeholder"` in `placeholder_art.json`,
  and content validation requires a status on every piece of art.
- Final hats come later from the owner's own Blender 5.2 pipeline, which is
  separate from this tool.

**How art is replaced**: an appearance id (`look_head_*`, stable) names an
asset entry. The asset entry holds the art and how it is worn (image, fit,
anchor, opening, row). Replacing a hat means changing that entry, or pointing
the appearance at a new entry with `"status": "final"`.
- Item ids, appearance ids, equipment slots, saves, drop tables and upgrade
  levels never change.
- Saves keep only item ids. The appearance is worked out from what is worn.
- Nothing in the rules or the presentation names a placeholder file. Only the
  asset entries do.
- Tested by `test_art_is_swapped_by_its_asset_entry_alone`.

**Count, verified on the source sheets**: 24 hats, six per sheet on all
four. Each sheet is laid out two rows of three, and every box is a single hat
of 27,000 to 73,000 pixels. Halos, sparkles and petals are joined to their
own hat, and no stray piece is counted. The first brief said 23: the sheets
hold 24, and the owner may remove any one of them (a data change only).

**Source**: `art/placeholder/hats/sheet_1.jpg` to `sheet_4.jpg` (uploads
5.jpg to 8.jpg). Upload 9.jpg was not used, by the owner's decision: three of
its hats face left.

**Processing**: `python3 tools/assets/import_placeholder_hats.py`.
1. Finds each hat by its outline against the sheet's own background colour:
   connected pixels, with halos and sparkles joined to their hat. The sheet
   is never cut into equal cells, and each sheet must give exactly 6 hats or
   the import stops.
2. Removes the background with hard pixel-art edges.
3. Makes a hood's opening see-through by growing a region from a point
   inside it, so the face shows.
4. Scales each hat down to the width it is worn at (26 to 34 px).
5. Writes `client/assets/placeholder/hats/<id>.png`, a 16x16 `<id>_icon.png` and
   `hats.json` with each hat's sheet, place, box, fit, size, anchor and
   opening.

**Worn** (`EquipmentLayers`), measured each frame from the frame's own
pixels. The head's top is the first row of at least 3 pixels; the rows below
it count only the head's longest run of pixels, so stray pixels and fists are
ignored.

| Fit | Hats | How |
|---|---|---|
| cover | wizard hats, caps, crowns, helms, straw hat, feathered hats, tiger hood, bandana | The body stops drawing the head's top 10 rows (shader `hide_rect`): the hair or a cap the character's own art wears. The hat's base rests on the brow, centred on its centre of mass. |
| hood | frost fur hood, dragonscale hood | The same rows hidden. The hood's see-through opening sits on the face, which shows inside it. |
| band | crystal tiara, phoenix tiara, rising sun headband, cyber visor | Over the hair, which is kept. A tiara sits on the crown (row 7), the headband on the brow (row 9), the visor on the eyes (row 12). |

Each hat mirrors with the body. Wearing another hat swaps the one shown, and
taking it off draws the head whole again.

| Sheet | Hats, left to right, top row first |
|---|---|
| sheet_1 | arcane_wizard_hat, golden_lion_helm, sakura_wizard_hat, frost_fur_hood, dragonscale_hood, starlight_wizard_hat |
| sheet_2 | lion_king_crown, crystal_tiara, sakura_straw_hat, midnight_wizard_hat, glacier_crown, emerald_feather_hat |
| sheet_3 | horned_crown, ice_crown, officer_cap, phoenix_feather_hat, obsidian_crown, crested_knight_helm |
| sheet_4 | rising_sun_headband, jewelled_crown, dragon_bandana, tiger_hood, phoenix_tiara, cyber_visor |

**Appearance ids**: `look_head_<hat id>` → asset `hat_<hat id>`. The drawn
head placeholders are gone; outfits and weapons keep theirs, which are not
drawn.

**Items**: the five existing headgear items keep their ids and now wear:

| Item | Hat |
|---|---|
| `patched_street_cap` | officer_cap |
| `reinforced_bandana` | dragon_bandana |
| `riveted_work_helmet` | crested_knight_helm |
| `gilded_brawler_helm` | golden_lion_helm |
| `crimson_warlord_helm` | horned_crown |

The other 19 hats are new items with the hat id as item id:

| Grade | Hats |
|---|---|
| Common | sakura_straw_hat, rising_sun_headband |
| Uncommon | emerald_feather_hat, midnight_wizard_hat, tiger_hood, frost_fur_hood |
| Rare | arcane_wizard_hat, sakura_wizard_hat, starlight_wizard_hat, crystal_tiara, cyber_visor, ice_crown |
| Epic | dragonscale_hood, phoenix_feather_hat, phoenix_tiara, glacier_crown, jewelled_crown, obsidian_crown |
| Legendary | lion_king_crown (bosses only) |

All 19 are sold by the Item Testing Merchant and drop through the headgear
category of the drop tables.

**Known limits**:
- A band leaves the head's own art. Riku's cap is part of his base art, so a
  band sits over it.
- Long hair below the brow shows under a covering hat, as it would.
- The hats are flat sprites: they do not tilt with the head.

## 10. The drop database and LootIndex

`client/sim/LootIndex.gd` is the single place that answers "what can this
enemy drop?" and "where can I get this item?". It is built from the rules
that pay the drops, and nothing is kept by hand.

- **Sources covered**:
  - an enemy's own loot table (`LootRules`);
  - the catalog's drop tables (`DropTables`, including each boss's own list);
  - farming grounds (`FarmSpawner`: loot at the ground's `reward_scale`, the
    ground's own prizes, and an elite's `ELITE_REWARD` rolls plus its prize
    roll);
  - world bosses (personal tiers and the kill, paid when the boss falls in
    its round);
  - shops and quests.
- **Chances** are the real chance per kill, worked out in closed form. For a
  catalog drop, `steps` gives each conditional share separately: roll chance,
  rolls, category share, grade share, item share.
- **Enemy kinds**: monster, elite, mini-boss (a lair's), stage boss, world
  boss, and raid world boss. Raid world bosses are marked `"raid": true` in
  `world_boss.json`: Floodgate Marshal, Crucible King and Founder's Engine.
- **The report**: `docs/ITEM_DROP_DATABASE.md` is generated from LootIndex
  by `client/tests/harness/DropReportRun.gd`. It has the item catalog, the
  monster, mini-boss, stage boss, world boss and raid world boss matrices,
  the probability steps, and the acquisition index.
  `test_loot_index.gd` fails when the committed report is out of date.

**Open decision (owner)**: the owner's rule says Godforged comes from **Raid**
world bosses only, but the existing data gives Godforged prizes to all eight
world bosses (as designed earlier: "every world boss prize is Godforged").
Nothing was changed. Moving the five non-raid world bosses' prizes to another
grade is a balance and progression change that needs the owner's approval.
The tests check that Godforged comes from world boss rewards only.

## 11. The Guide (player-facing)

The in-game Guide (N) shows items, monsters, bosses and maps from the same
LootIndex, so the player sees the rules' own numbers. See
`docs/PLAYER_ITEM_ENCYCLOPEDIA.md`.
