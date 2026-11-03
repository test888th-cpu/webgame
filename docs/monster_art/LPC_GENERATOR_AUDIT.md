# Universal LPC Generator: assets and licences (monster art, Phase D)

What the Universal LPC Spritesheet Character Generator offers this project, how
its licence filter works, and what was and was not verified. Audited on
2026-11-03 against the generator's source repository at the commit the project
already pins in `art/lpc/characters.json`:
`9bf06be193b053db256b2536824af426de046aa2` (2026-10-14), read from
<https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator>.
The generator's code was read as data only; none of it is used or copied (it is
GPL-3.0, see [docs/ASSETS.md](../ASSETS.md)).

## What could not be reached

From the build environment used for this audit, **opengameart.org** and the
generator website **liberatedpixelcup.github.io** are blocked by its network
policy (HTTP 403 from the proxy). GitHub is reachable. So:

- the original asset pages on OpenGameArt were **not** checked;
- no configuration, Credits TXT or Credits CSV was exported from the website.

Nothing below stands in for those: where a fact needs the original page or a
website export, it is marked as missing. The owner can allow both hosts in the
cloud environment's network settings
(<https://code.claude.com/docs/en/cloud-environments#network-access>), or export
from the website in a browser.

## How the generator's licence filter works (and why it is not proof)

From `sources/state/constants.ts` (`LICENSE_CONFIG`) and
`sources/state/filters.ts` (`isItemLicenseCompatible`) at the pinned commit:

| Filter family | Licence versions it admits |
|---|---|
| CC0 | CC0 |
| CC-BY-SA | CC-BY-SA 3.0, 4.0 |
| CC-BY | CC-BY 3.0+, 3.0, 4.0, CC-BY |
| OGA-BY | OGA-BY 3.0, 3.0+, **4.0** |
| GPL | GPL 2.0, 3.0 |

1. **Family, not version:** ticking OGA-BY also admits OGA-BY 4.0; the project's
   selection is OGA-BY 3.0 (3.0+ includes 3.0).
2. **Any one credit is enough:** an item made of several credited files is
   "compatible" if one of its files offers an allowed licence, even when another
   does not.
3. **No information counts as compatible:** an item with no credits, or whose
   data has not loaded, passes.
4. **"Remove incompatible items"** removes only what (1) to (3) flag.

The project's own build (`tools/assets/lpc_build.py`) is stricter: every file it
draws must match a credit entry, and that entry must offer an allowed licence,
or the build fails. That is the check this audit relies on, with the allowed list
narrowed to CC0 and OGA-BY 3.0/3.0+ (see Phase E).

## Licences are per file, not per item

A generator item (one definition in `sheet_definitions/`) usually has a file
per body type, and the files can carry different licences. Examples at the
pinned commit:

| Item | File | Offered |
|---|---|---|
| `body/body.json` | `body/bodies/male`, `female`, `teen`, `child` | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| | `body/bodies/muscular`, `pregnant` | CC-BY-SA 3.0, GPL 3.0 only |
| `torso_aprons_apron_full` | female file only | (no male file exists) |

So an item can be usable for one body type and not another; checks must be per
file actually used.

## The asset library at the pinned commit

657 credited item definitions. Counted per item (every credit entry of the item
must offer CC0 or OGA-BY 3.0/3.0+), 498 pass; per file, more pass (see above).

| Category | Items passing (all entries) / items |
|---|---|
| arms | 11 / 11 |
| body | 16 / 31 |
| feet | 14 / 17 |
| hair | 81 / 122 |
| head | 66 / 92 |
| headwear | 124 / 155 |
| legs | 19 / 22 |
| tools | 3 / 8 |
| torso | 80 / 102 |
| weapons | 84 / 97 |

Checked file by file for the male body (and the female files the specifications
use), eligible: t-shirt, v-neck t-shirt, polos, buttoned / long-sleeved /
sleeveless shirts, overalls, apron, suspenders, pants, pants2, cuffed pants,
shorts, basic and rimmed boots, basic shoes, bandana, bandana2, thick and tied
headbands, cloth hood, plain glasses, plain face mask, gloves, bracers,
epaulets, jacket pocket trim, leather armour, Xeon helmet, human / elderly /
gaunt / female human heads, buzzcut, plain, curly short, short dreadlocks (CC0),
half-messy and high-ponytail hair, trimmed / medium beards, walrus moustache.

**Not eligible** (offered only under CC-BY-SA, GPL or OGA-SA for those files):
open and closed vests, trench coat, bowler, sunglasses, shades, round glasses,
necktie, scarf; the boarman, minotaur, wolf, troll and zombie heads; spiked
hairstyles are CC-BY 4.0 (outside CC0/OGA-BY).

**Not in the library at all:** modern caps, hard hats, beanies, hi-vis or
tactical vests, riot armour, gas masks, robots, large creatures.

## The project's current LPC enemies, checked

- 33 enemies are built from the generator; their `credits.json` files hold 224
  LPC credit rows. **All 224 are identical** (file, authors, licences offered,
  URLs) to the credit entries in the generator's own definitions at the pinned
  commit.
- 220 of them were recorded under OGA-BY 3.0 (209) or OGA-BY 3.0+ (11). **4 rows** (the spiked
  hair of Night Market Punk, Ring Fighter, Hybrid Brute and Subject Zero) are
  offered only under **CC-BY 4.0**: allowed by the project's current policy
  (CC0, OGA-BY, CC-BY) but outside the CC0/OGA-BY selection for this work.
- Three recipe parts are never drawn (open vest, trench coat, tabard; see
  [ENEMY_INVENTORY.md](ENEMY_INVENTORY.md)). They are not credited because they
  are not in the sheets, and they would not be allowed if they were.
- Verification status of every LPC row: **UNVERIFIED**. They match the
  generator's records, but the original OpenGameArt pages could not be reached,
  so the licences are not confirmed at the source. This is what the brief means
  by "a filter is not proof".

## Website exports versus the project's build

The brief asks for each monster's Generator configuration, Credits TXT and
Credits CSV as exported from the website. The project has built LPC characters
another way since 2026-10-23 (PR #4): `lpc_build.py` composes them from the generator's own
asset files at a pinned commit, from recipes in `art/lpc/characters.json`, and
writes credits from the generator's definitions. Differences that matter:

| | Website export | Project build |
|---|---|---|
| Reproducible | a URL hash / JSON of selections, at whatever version the site runs | recipe + pinned commit: rebuilt identically in CI |
| Sheet layout | the generator's universal sheet (every LPC animation, 64×64) | one row per game animation, with borrowed frames and a `hands.png` of fist positions the game needs for held weapons |
| Credits | Credits TXT/CSV for the selected items | `credits.json` per character from the same definitions, per file drawn |
| Godot | needs conversion to the game's rows and hands sheet | used as is (`make_spriteframes.py`) |

A website sheet cannot give the game's `hands.png` or borrowed frames, so it
would still have to be rebuilt by the project's tools. Owner decision (Phase F):
keep the project build as the production path and store the website exports
beside it as provenance, or require website exports and convert them.
