# Asset pipeline policy: temporary art, licences, provenance and replacement

**Status:** working draft for the owner's review, written 2026-11-17. Not committed.
This is a record of what the repository holds and how it is checked. It is not legal
advice, and nothing here guarantees that a licence record is correct.

The owner's decision: temporary art is used now so that gameplay is not blocked:

- **LPC** for characters;
- **free assets with verified rights** for items;
- **AI-generated art** only with a documented history.

All of it is to be replaced by original art later. Gameplay data must never depend on a
temporary image file.

## 0. The files

| File | What it is | Made by |
|---|---|---|
| [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) | Master inventory: one record per asset or source contribution | `tools/assets/provenance.py build` |
| [ASSET_CREDITS.md](ASSET_CREDITS.md) | Every third-party credit and licence notice | same |
| [ASSET_REPLACEMENT_MAP.md](ASSET_REPLACEMENT_MAP.md) | Every temporary asset and the id its replacement takes | same |
| [`data/asset_provenance.json`](../data/asset_provenance.json) | Machine-readable inventory | same |
| [asset_provenance.csv](asset_provenance.csv) | Spreadsheet export | same |
| `art/provenance/generation_records.json` | **Filled in by the owner:** how each AI-generated group was made | by hand |
| `art/provenance/licence_checks.json` | **Filled in by a person:** licences confirmed at the original page (non-LPC assets) | by hand |
| `art/provenance/lpc_source_review.json` | Each LPC part checked at its original pages and download credits, with quotes | checked 2026-11-17 |
| [LPC_LICENCE_VERIFICATION.md](LPC_LICENCE_VERIFICATION.md) | Part-by-part LPC result | `provenance.py build` |
| [ASSET_PROVENANCE_GAPS.md](ASSET_PROVENANCE_GAPS.md) | What the owner must supply (AI records, hats) | same |
| [FREE_ITEM_ART_RESEARCH.md](FREE_ITEM_ART_RESEARCH.md) | Free item and icon packs researched (none imported) | by hand |
| [PIXELFX_VFX.md](PIXELFX_VFX.md) | PixelFX effects: source check, selection, integration, performance | by hand |
| `client/data/class_visuals.json` | Class → stable visual id → sprite | by hand |

**How the generated files are built:**

- They are generated from records the repository already keeps: `client/assets/manifest.json`,
  each character's `credits.json`, `art/*/` recipes and `client/data/placeholder_art.json`.
  Nothing is typed twice.
- The older register [credits/ASSET_CREDITS.csv](credits/ASSET_CREDITS.csv), made by
  `credit_register.py`, stays. It keeps one row per character and part, for the monster-art
  audit. The new inventory keeps **one record per source contribution** and lists every
  character that uses it.

**What CI checks** (the `assets` job runs `test_provenance.py` and `provenance.py check`).
The check fails when:

- an output is stale;
- an id is duplicated;
- a recorded file is missing;
- a manifest asset has no record;
- an LPC or external asset has no licence;
- an AI-generated asset has no generation record;
- a part's recorded licence is share-alike (RESTRICTED findings from the source review
  are reported, not failed: they are the owner's decision);
- gameplay data names an image file.

## 1. Record format and the rules for filling it

Every record has the directive's fields:

- Asset ID
- Display Name
- Category
- File Path (`files`)
- Asset Type
- Creator
- Source URL
- License
- Commercial Use
- Attribution
- Modification
- Generation (prompt and the rest)
- Reference Files
- Replacement Target
- Status

It also carries `licence_verification`, `licence_class`, `release_ready`, `share_alike`,
`components` and `used_in`.

- **Licence class** (owner's decision, 2026-11-17):
  - **VERIFIED:** permitted for the intended commercial use, confirmed at the source.
  - **RESTRICTED:** permitted only under conditions, such as CC-BY-SA or GPL.
  - **UNVERIFIED:** insufficient or conflicting evidence.
  - **NOT APPROVED:** incompatible.
  - A composite sheet takes the least clear class of its parts.
- **Release-ready:** the asset is VERIFIED, its type is known and, for AI-generated art,
  its generation record is complete. Only release-ready assets may go into a release
  package.

- **Asset Type:** `LPC`, `Free External`, `AI Generated`, `Original`, or **`UNKNOWN`**
  when the repository does not say how the asset was made.
- **UNKNOWN:** any fact the records do not hold is written as `UNKNOWN`. No creator,
  licence, URL or permission is inferred.
- **Commercial Use:**
  - `Allowed` only when the licence permits it **and** a person confirmed that licence
    on the original source page (`licence_checks.json`).
  - `Not Allowed` for NonCommercial licences.
  - Otherwise `Unverified`.
  - `Restricted` for RESTRICTED records.
  - LPC parts now take their class from the check at the original sources, not from the
    generator's records. Those records proved wrong for the bodies and heads (§2).
- **Status:** `Temporary`, `Approved`, `Rejected` or `Replace Later`.
  - Only the code-generated art and the Noto font are `Approved`, meaning no third-party
    rights are in doubt.
  - Everything else is `Temporary` until the owner approves it as final.
  - The four recorded punches whose MP3 names a commercial sound library are
    `Replace Later`.

**Current totals:** see the summary table at the top of
[ASSET_PROVENANCE.md](ASSET_PROVENANCE.md). It is generated, so it is always current.

## 2. LPC character parts

**Verification at the original sources (2026-11-17).** See
[LPC_LICENCE_VERIFICATION.md](LPC_LICENCE_VERIFICATION.md).

- Of 67 LPC parts: 43 VERIFIED, 18 RESTRICTED, 6 UNVERIFIED.
- **All 70 LPC character sheets are RESTRICTED.** The adult male and female bodies, and
  the human male and female heads, are granted only as **CC-BY-SA 3.0 / GPL 3.0** by
  their source.
  - The source is the page and download credits of "LPC Character Bases", for
    BenCreating's and bluecarrot16's contributions.
  - The LPC generator records them as OGA-BY 3.0, but its records cite that same source.
- The policy below ("refuse what is only offered as share-alike") was applied to the
  generator's records. The source check shows that this was not enough.

**Licence policy.**

- Every LPC part is checked **per contribution**, not per "LPC". `lpc_build.py` reads
  each file's own credits (authors, licences offered, source pages) from the Universal
  LPC Spritesheet Character Generator's data at the pinned commit `9bf06be1…`.
- A part is used only if **every** credited file offers CC0, OGA-BY or CC-BY.
- That policy is the owner's, already in `art/lpc/characters.json` `license_policy`: no
  share-alike and no GPL art without the owner's approval.

**Obligations of the licences in use** (texts and details:
[credits/LICENSE_REGISTER.md](credits/LICENSE_REGISTER.md)):

| Licence | Commercial | Modify | Redistribute | Attribution | Share-alike | Other |
|---|---|---|---|---|---|---|
| CC0 1.0 | yes | yes | yes | not required (recorded anyway) | no | — |
| OGA-BY 3.0 | yes | yes | yes | **required**: creators, title, link, licence, note changes | no | DRM clause removed |
| CC-BY 3.0 / 4.0 | yes | yes | yes | **required**, as above | no | forbids technical restrictions on recipients (matters only for DRM platforms) |
| CC-BY-SA / GPL | yes | yes | yes | required | **yes**: derived sheets would inherit it | not used; needs the owner's approval |

**Refused for share-alike or GPL licences, so substitutes were used:**

- the robe;
- the wizard and large magic hats;
- the horned helmet;
- the scarf, necktie and plain necklace;
- several glasses;
- the polearms, the flail and the war axe;
- the great and recurve bows;
- the kite shield.

**Creator-specific conditions:**

- None found beyond the licence text.
- The notes field of each part keeps the creators' own notes, for example "original by
  wulax, recolor by bigbeargames…".

## 3. AI-generated art (records needed from the owner)

**Labelled AI-generated, from the repository's own words:**

- the street kit (59 pieces);
- the nine weapon paintings;
- the four painted enemies (Smogling, Tar Rat, Smog Warden, Sludge Foreman).

Their records say "painted by the project owner with their own AI tools". They were
previously listed only as "Proprietary (project owner)". They are **not** labelled
hand-drawn.

**What is missing for each group:**

- tool or platform;
- model and version;
- date;
- prompt or brief;
- reference images (and the rights to them);
- what was edited by hand.

The prompts in [ENEMY_PROMPTS.md](ENEMY_PROMPTS.md) may be the briefs for the enemies,
but the repository does not say which tool or model used them. They are therefore not
copied in as the prompt.

**Owner action:** fill `art/provenance/generation_records.json` (keys `kit`, `weapons`,
`custom.<id>`) and run `provenance.py build`. Until then these show UNKNOWN, and
Commercial Use stays Unverified. The rights to AI output depend on the tool's terms, so
those terms need recording too.

**Placeholder hats (24, Asset Type UNKNOWN).**

- The owner supplied them for testing the equipment-appearance system. Their
  `credits.json` says no production licensing was sought.
- How they were made is not recorded. They are **development-only** and must not ship in
  a release until recorded or replaced.

**Code-generated art** (icons, scenery fallback, effects, sounds, the training dummy):

- It is drawn by project code, with no image model and no third-party source.
- The code was written in AI-assisted sessions. It is typed `Original`, and the notes say
  how it was made.

## 4. Stable ids: gameplay never names a file

What already holds in the repository, and is now enforced:

| Gameplay data | Names | Mapped to files only in |
|---|---|---|
| `enemies.json` `sprite`, `heroes.json` `sprite` | a manifest asset id | `client/assets/manifest.json` |
| `items.json` `icon` | an icon id | manifest `ui.icons` |
| `weapons.json` `sprite` | a weapon sprite id | manifest `ui.icons` |
| `items.json` → `appearances.json` `asset` | an appearance asset id | `placeholder_art.json` |
| class (new) → `class_visuals.json` | `character.<class>.<male\|female>` → sprite id | manifest |

**How this is enforced:**

- `provenance.py check` fails if any gameplay data file names an image path (`.png`,
  `.jpg`, `.tres`, `res://assets`).
- `test_class_visuals.gd` requires `class_visuals.json` to carry only `visual_id`,
  `sprite` and `status`, so a swap there cannot carry a rule.
- Provenance ids follow the directive's dotted convention:
  - `character.<id>`
  - `weapon.<id>`
  - `kit.<piece>`
  - `appearance.<id>`
  - `icon.<id>`
  - `sound.<id>`
  - `fx.pixelfx.<id>`
  - `lpc.<part path>`

**Folder layout: decided (owner, 2026-11-17): keep `client/assets/`.** No files are
moved. The directive sketched a top-level `assets/`
tree (`characters/`, `weapons/`, `armor/`, `items/`, `animations/`, `generated/`).

- Godot can load only files inside the project (`client/`).
- The existing tree is already split by kind: `client/assets/characters/`, `ui/`
  (icons and weapon sprites), `kit/`, `environment/`, `fx/`, `audio/` and `placeholder/`.
- Moving 75 sheets and every manifest path would churn saves-adjacent references for no
  gain. So the layout is **mapped, not moved**:

| Directive folder | Existing location |
|---|---|
| `characters/` | `client/assets/characters/` |
| `weapons/` | `client/assets/ui/` |
| `armor/` | `client/assets/placeholder/` and the appearance system |
| `items/` | `client/assets/ui/` |
| `animations/` | each sheet plus its `.tres` |
| `generated/` | `environment/`, `fx/` and `ui/`, made by code |

`data/asset_provenance.json` is at the repository root as asked.

## 5. Replacement workflow

When original art arrives:

1. **Keep the id.** That is the manifest asset id, icon id, appearance asset id or
   `class_visuals.json` sprite.
2. **Find the record** in ASSET_REPLACEMENT_MAP.md.
3. **Import the new art** with the existing tool: `custom_import.py` for sheets,
   `kit_import.py`, or `gen_ui.py` for icons. Credit it as `Original` or
   `AI Generated`, with its generation record.
4. **Point the mapping at it.** Either import it under the same asset id, or change only
   `sprite` in `class_visuals.json`, the `asset` in `appearances.json`, or the manifest
   entry.
5. **Run `validate.py`.** It checks frame size, animations, frame counts, hand sockets,
   contact frames and SpriteFrames freshness.
6. **Check the look** in the Gallery (Title → Characters) and the equipment preview.
7. **Run all tests:** Godot tests, `test_pipeline.py`, `test_provenance.py`.
8. **Rebuild the documents:** `provenance.py build` and `credit_register.py build`.
9. **Delete the temporary files** only after nothing references them (the check fails on
   a missing file) and the owner approves.

Item ids, stats, drop tables and saves are never touched by these steps.

## 6. The nine class placeholders (built, not yet used by gameplay)

**What was built:**

- 18 LPC sheets, one male and one female for each class: `class_<class>_m` and
  `class_<class>_f`.
- They use the same 64×64 frame grid, bodies and outline as every other character.
- They are built by `lpc_build.py` from `art/lpc/characters.json` and listed in
  `client/data/class_visuals.json` as `character.<class>.<male|female>`.

**Status:**

- Temporary.
- Not shown in game yet: the classes are not wired into gameplay until Phase 6 of the
  reference adoption.
- They do play in the Gallery.

| Class | Look (all parts licence-checked by the build) | Licences |
|---|---|---|
| Warrior | steel plate, armoured legs, nasal helmet | OGA-BY 3.0, 3.0+ |
| Paladin | gold plate, white cape, white boots | OGA-BY 3.0, 3.0+ |
| Hunter | leather armour, green hood, leggings | OGA-BY 3.0, 3.0+ |
| Rogue | black leather, black bandana | OGA-BY 3.0 |
| Priest | white longsleeve and long skirt, brass star amulet | CC0, OGA-BY 3.0 |
| Shaman | chainmail, teal mantle and rune headband | OGA-BY 3.0, 3.0+ |
| Mage | navy robe-like longsleeve and skirt, blue cape, celestial hat | CC-BY 3.0, OGA-BY 3.0 |
| Warlock | black hood and top, maroon skirt and cape | OGA-BY 3.0 |
| Druid | green leather, forest mantle, natural gem | CC0, OGA-BY 3.0, 3.0+ |

**Animation note.** Leather armour, chainmail, the mantle, skirts and capes have no LPC
`combat` or `1h_halfslash` frames. A layer without an animation simply vanishes in it,
which was checked on a preview.

- So these sheets use LPC `idle` for standing.
- They use `thrust` for `light`, `heavy`, `stab` and `swing`, with the spellcast raise
  borrowed for the wind-up.
- They use walk frames for `dodge`.
- Every layer has those animations. The pipeline's hand-socket and contact-frame tests
  pass on them.
- This is a placeholder compromise. Final class art should draw proper combat poses.

**Weapons on class sprites:**

- Not added. Held weapons are drawn by the game at the hand socket, from weapon sprites,
  so they swap with the equipped item rather than being baked into the body sheet.
- LPC weapon layers usable under the policy:
  - swords: arming, dagger, longsword, rapier, scimitar, katana, glowsword;
  - club and mace;
  - seven magic staffs and wands;
  - bow, crossbow, slingshot and boomerang;
  - round, heater, scutum and spartan shields.
- **Not usable** (share-alike or GPL only): **every polearm and spear, the war axe and
  flail, the great and recurve bows, the kite shield**.
- Axes and spears therefore need another source.

## 7. Free item and icon assets: candidates, nothing imported

**Research done:** [FREE_ITEM_ART_RESEARCH.md](FREE_ITEM_ART_RESEARCH.md) covers 13
packs, read on their own pages. The recommendation is the three CC0 Idylwild packs.
Nothing is imported until the owner approves.

Original plan, kept for reference. **No external item art was imported in this pass.** The directive requires each licence
to be read at its source before import, and that research is not done.

**Plan:**

1. Prefer CC0, then OGA-BY or CC-BY, packs with one identifiable author. 16×16 or 32×32
   pixel icons match `icons.png`.
2. For each candidate, record the page, the licence text read on that day, the author,
   any third-party parts, and whether commercial use, modification and redistribution
   are stated. Do this in `licence_checks.json` and a short review list.
3. Present the list for the owner's approval, then import through `gen_ui.py`'s icon
   sheet (a new `import_icons` step) with records.

**Gaps to fill first:**

- **axe and spear sprites** (no allowed LPC source);
- **rings and necklaces as icons**;
- **material icons**;
- **icons for the 13 reference equipment slots** that the current icons do not cover:
  shoulder, waist, legs, neck, ring and trinket.

## 8. Owner decisions needed

1. **LPC share-alike (the main decision).** All LPC character sheets are RESTRICTED. The
   choices are:
   - (a) accept CC-BY-SA 3.0 for LPC sheets, with their obligations;
   - (b) ask the contributors to confirm OGA-BY, and record each answer;
   - (c) replace the bodies and heads with ElizaWy's OGA-BY "LPC Revised" set, which
     needs animation re-mapping;
   - (d) commission original character art.

   Until one is chosen, no LPC sheet is release-ready.
2. **Generation records** for the kit, weapons and four enemies
   ([ASSET_PROVENANCE_GAPS.md](ASSET_PROVENANCE_GAPS.md)).
3. **Placeholder hats:** keep them development-only (as now), or switch the 24 items to
   the prepared code-drawn fallback.
4. **Item icons:** approve importing the Idylwild packs, and choose the 32×32 cell or
   hand reduction.
5. **Recorded sounds and the font:** their licences have not yet been checked at
   source. That is the next verification step if wanted.
6. **Pillow version:** with the pinned 13.0.0 all pipeline tests pass. The container's
   12.3 fails two freshness tests, also at HEAD. CI uses the pin.
