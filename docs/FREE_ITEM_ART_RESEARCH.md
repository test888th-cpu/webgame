# Free item and equipment art: research (nothing downloaded or imported)

**Status:** research only, 2026-11-17. No candidate was downloaded into the repository
or integrated. Licences were read on each pack's own page; those pages were fetched
directly, not taken from search summaries.

**Not legal advice.** A pack's page is the creator's statement. Where a pack collects
other people's work, the risk sits with each original source, and that is noted.

## What the game needs

- 16×16 item icons on `client/assets/ui/icons.png`, with some 16×32 and 32×48 weapon
  cells and 24×24 skill icons.
- 32×32 packs would need either a 32×32 icon cell (a UI change) or hand reduction.
  Automatic downscaling of pixel art loses detail, so it is not recommended.
- **Gameplay does not depend on the choice.** Items name an `icon` id, and only the
  manifest maps that id to pixels (ASSET_PIPELINE_POLICY.md §4). Changing packs later
  changes only the icon sheet.

## Candidates

| # | Pack | Creator | Page | Licence (as read) | Commercial | Attribution | Modify | Categories | Format | Style fit | Recommendation |
|---:|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Idylwild's Arsenal** | Idylwild | <https://opengameart.org/node/171012> | **CC0**; notice: "free to share, copy, redistribute, remix ... for any purpose, including commercial use" | yes | not required ("appreciated") | yes | 50 weapons: long swords, daggers, **axes**, maces, flail, hammers, club, bows, crossbows, **spears**, polearms, scythes, staves and wands, throwing weapons, arrows | 32×32 PNGs, sheet, .ase; 24-colour palette | clean pixel icons, one artist; close to the existing icons | **Recommended** (weapons) |
| 2 | **Idylwild's Armory** | Idylwild | <https://opengameart.org/node/171011> | **CC0**, same notice | yes | not required | yes | cloth, leather, studded, chain and plate sets (helmet, chest, pants, boots, gloves); 6 shields; 4 rings; 4 amulets; cloak; bracers | 32×32 PNGs, sheet, .ase; 30-colour palette | same artist and style as #1 | **Recommended** (armour, rings, necklaces) |
| 3 | **Idylwild's Inventory** | Idylwild | <https://opengameart.org/node/171013> | **CC0**, same notice | yes | not required | yes | ingots, tools, wood, leather, cloth, thread, food, herbs, containers, bone | 32×32 PNGs, sheet, .ase | same artist | **Recommended** (materials, food) |
| 4 | 496 pixel art icons for medieval/fantasy RPG | Henrique Lazarini (7Soul1); compiled by another user | <https://opengameart.org/node/39455> | **CC0** on the page | yes | not required | yes | weapons, armour, **potions**, food, spells | 32×32 (zip) | detailed, darker; differs from #1–3 | Possible for **consumables**. Caution: the page says icons "derivative works from copyrighted games" were removed; it was compiled by a third party; an earlier version was CC-BY 3.0. Check the artist's own release before use. |
| 5 | RPG Items | Buch | <https://opengameart.org/content/rpg-items> | **CC0** | yes | not required | yes | swords, wands, staffs, **potions**, rings | small PNG sheet | simple, bright | Possible for consumables |
| 6 | CC0 Jewelry Icons | AntumDeluge (collection) | <https://opengameart.org/content/cc0-jewelry-icons> | **CC0**, with sources listed: OpenClipart, 7Soul1, Buch, Dungeon Crawl, HomoHikka | yes | not required | yes | rings, necklaces, amulets | 16/24/32 px | mixed artists | Possible; mixed styles. Prefer #2 |
| 7 | CC0 Sword Icons | AntumDeluge (collection) | <https://opengameart.org/node/109523> | **CC0**; many listed sources; some rescaled by the collector | yes | not required | yes | swords, daggers | 16–64 px | mixed artists | Not needed if #1 is used |
| 8 | Super Epic Weapons Fantasy Pack FREE | babysamurai | <https://opengameart.org/content/super-epic-weapons-fantasy-pack-free> | **CC0**; "Credits are not required" | yes | not required | yes | 50 weapons | 32×32 single PNG | glowing "epic" look | Possible, for high-quality tiers only |
| 9 | Dungeon Crawl 32x32 tiles | many DCSS artists; Chris Hamons (maintainer) | <https://opengameart.org/content/dungeon-crawl-32x32-tiles> | **CC0**; "No attribution is required" | yes | not required | yes | items, monsters, armour, weapons (3000+ tiles) | 32×32, three-quarter view | painterly; different perspective | Monster or boss placeholders only, if ever needed |
| 10 | Generic Items | Kenney | <https://opengameart.org/content/generic-items> | **CC0**; crediting "Kenney.nl" not mandatory | yes | not required | yes | tools, medical, tech, transport | 160 px PNG and vector | flat vector; does not match | Not recommended (style) |
| 11 | OSARE weapon icons | Blarumyrran (commissioned for OSARE) | <https://opengameart.org/node/3267> | **CC0** | yes | not required | yes | weapons, shields, armour | zip | painted over 3D renders | Not recommended: "Drawn over 3d renders by pfunked". The rights in those renders are not stated. |
| 12 | Itemazing | Seikia | <https://opengameart.org/content/itemazing-a-free-items-pack> | **CC-BY-SA 4.0** | yes, under share-alike | **required** | yes, adaptations must be CC-BY-SA 4.0 | small fantasy items | tileset | — | **Restricted:** share-alike would cover the icon sheet built from it. Not recommended under the current policy |
| 13 | Pixel Art Icon Pack - RPG | Cainos | <https://cainos.itch.io/pixel-art-icon-pack-rpg> | custom: "can be used in both free and commercial projects. You can modify it ... Credit is not needed ... **You may not redistribute it or resell it.**" | yes | not required | yes | equipment, food, materials, potions, weapons (107) | 32×32 | good | **Not recommended:** this repository is public on GitHub, so committing the files would be redistribution |
| — | Dungeoneering EQ icon pack (search result) | jeevo | <https://jeevo.itch.io/dungeoneering-eq-icon-pack> | page returned 404 | — | — | — | — | — | — | Not usable (no source page) |

LPC weapon layers drawn on characters (swords, mace, staffs, bows, shields) are covered
in ASSET_PIPELINE_POLICY.md §6. LPC has **no** usable axes or spears; #1 has both.

## Recommendation

**Use the three Idylwild packs (#1–#3)** as the temporary item-icon source, plus #5 or
#4 for potions.

- They are CC0, with the commercial use stated in the creator's own notice.
- They are by one artist, in one palette and size.
- They are hand-made, by the creator's own statement: "No AI tools or automation are
  ever used".
- Together they cover:
  - swords, axes, spears, daggers, bows, staffs;
  - shields, helmets, chest armour, gloves, pants, boots;
  - rings and necklaces;
  - materials and food.

**Before import (needs the owner's go-ahead):**

1. Download each zip from its page.
2. Record its SHA-256 and the page text on that date in `art/provenance/licence_checks.json`.
3. Check the zip for a licence or readme file and third-party content.
4. Decide on a 32×32 icon cell, or hand reduction to 16×16.
5. Import through `gen_ui.py` with a provenance record per icon group.

## Not covered by any candidate

None of the candidates has icons for:

- shoulder, waist or trinket slots: Armory has bracers and a cloak, but no pauldrons or
  belt;
- the game's street and industrial items (pipes, wrenches, hard hats): these keep their
  current code-drawn or owner-painted icons.
