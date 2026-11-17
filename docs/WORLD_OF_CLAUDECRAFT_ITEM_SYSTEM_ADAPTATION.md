# Item quality system: adaptation from World of ClaudeCraft (Phase A)

**Status: Phase A (inspection, audit and design). Nothing implemented.**

- No gameplay data, item stat, loot table, rule or UI file was changed for this
  document.
- No code or asset was copied from the reference.
- Every proposal waits for the owner's approval (§20).

Labels used on findings:

- **VERIFIED:** read in source code, data or tests.
- **PROPOSED:** a recommendation, not built.
- **UNKNOWN:** could not be confirmed.

Reference repository:

- [levy-street/world-of-claudecraft](https://github.com/levy-street/world-of-claudecraft),
  commit `d2b91e08` (2026-11-16).
- It was cloned read-only into the session scratchpad, outside this repository,
  and read with `git show`. Nothing in it was built or run.
- It is a TypeScript / Three.js browser MMO with a server. Below it is called
  "the reference".

Related documents in this repository:

- `docs/ITEM_POWER_AUDIT.md`
- `docs/ITEM_POWER_BALANCE_PROPOSAL.md`
- `docs/ITEM_POWER_MR_VALIDATION.md`, the power numbers this design depends on
- `docs/ITEM_DROP_DATABASE.md`
- `docs/GODFORGED_IMPACT_REPORT.md`

## 1. Reference findings: what the reference actually does

### 1.1 Two different "quality" ideas

The reference uses the word quality for two separate things.

- **(a) Item rarity, "quality" on the item definition.** VERIFIED.
  - The grades are poor, common, uncommon, rare, epic and legendary. Each item
    definition carries one.
  - It is used by the stat budget (§1.2), the item level (§1.3), the colours
    (§1.4) and sorting (§1.5).
- **(b) Per-copy "loot quality".** VERIFIED (`docs/design/loot-quality.md`,
  `src/sim/loot/enemy_quality.ts`, `src/sim/loot/fresh_quality_grant.ts`).
  - The tiers are Ordinary (90%), Superior I (9%), Exceptional II (0.9%),
    Magnificent III (0.09%) and Transcendent IV (0.01%).
  - Each is a roll on a newly earned copy of uncommon-or-better gear, adding 0 to
    8 item levels of budget.
  - It is stored on the item instance and does not change the item's identity,
    art, rarity colour, required level or effects.
  - It is shown as a Roman-numeral badge, not a colour.
- **For The Iron Legacy:** our six Grades correspond to (a). Our per-copy +0 to +10
  enhancement plays the role (b) plays: a per-copy power layer that never
  changes the Grade. That is already true here (VERIFIED, §8).

### 1.2 Stat budget from level, rarity and slot

VERIFIED, from `src/sim/item_budget.ts`:

- **Budget:** `primaryStatBudget(level, quality, slot) = round(level ×
  QUALITY_STAT_MULT[quality] × SLOT_STAT_MULT[slot] × 0.7)`.
- **Rarity multipliers** (`QUALITY_STAT_MULT`): poor 0, common 0, uncommon 0.55,
  rare 0.8, epic 1.0, legendary 1.9.
  - White and grey items carry no primary stats, only armour.
  - The comment calls Legendary "a steep jump": flagship artifacts that should
    dwarf epics.
- **Slot multipliers** (`SLOT_STAT_MULT`): mainhand and chest 1.0, legs 0.9,
  helmet 0.85, offhand and shoulder 0.75, waist and gloves 0.7, feet and neck
  0.65, ring and trinket 0.6. Two-handers get ×1.3 stats and ×1.15 weapon damage.
- **Weapon damage follows item level, not rarity:** `weaponDpsBudget(level) =
  6.7 + 0.3 × level`. Rarity drives the stat budget only.
- **`normalizePrimaryStats`** scales an authored stat line to the exact budget and
  keeps its proportions. Content files call it; items are not hand-tuned off the
  curve.
- **Enforcement:** `tests/item_level.test.ts`. Examples: "every showcase item
  carries exactly its item-level stat budget", "items from the same place share
  one item level and one line budget", "every level-20 item is balanced to
  budget".

### 1.3 Item level from where the item comes from, plus a rarity bump

VERIFIED, from `src/sim/item_level.ts` and `QUALITY_ILVL_BONUS` in
`item_budget.ts`:

- **Item level** = the level of the content that drops it (the mob band, the
  quest's hardest objective, the raid tier) + a rarity bump: uncommon +1, rare +3,
  epic +6, legendary +10.
- So "a blue from a level-N pull outclasses a green from the same pull" is built
  into the item level itself.
- Heroic and raid variants read at higher source levels (22, 33, 37).

### 1.4 One source of truth for colours

VERIFIED:

- `QUALITY_COLOR` in `src/ui/icons.ts` defines the six colours.
- `src/styles/tokens.css` mirrors them as `--color-quality-*`. A test
  (`tests/ui_library.test.ts`, named in the tokens.css comment) pins the two equal.
- Item-name text uses separate, lifted text variants (`--mkt-name-*`), because the
  shipped hues fail WCAG AA 4.5:1 on the panel ground. The documented examples:
  rare #0070dd at 3.87:1, epic #a335ee at 3.82:1.
- Icon rims keep the shared palette.

### 1.5 Bags, bank, sorting and search

VERIFIED:

- **Slot rim:** a bag cell sets `--bag-slot-quality` from `QUALITY_COLOR`
  (`src/ui/bags_window.ts`, line 1113 onwards). The CSS draws a soft rim glow
  (`src/styles/components.css`, line 9573: a 5 px shadow at 45%). There is a
  default colour for items without a quality.
- **Corner glyphs** have a priority order (masterwork > quest seal > fine seal >
  enchanted/signed/bound), separate from the rim.
- **Sorting:** `qualityRank()` in `src/ui/bag_filter.ts` uses an explicit rank
  table (legendary 0 … poor 5) shared by the bags and the bank
  (`src/ui/bank_filter.ts`). Unknown ids sort after poor. Sorts are never by
  colour or name.
- **Bank search:** matches the displayed (localized or chosen) name.
- **The bank keeps the slot index** through filter and sort, so actions hit the
  real slot.

### 1.6 Comparison from real per-copy stats

VERIFIED (`src/ui/item_compare.ts`):

- A pure helper computes stat deltas, "candidate minus equipped; positive =
  upgrade", from each copy's active instance stats (`activeItemInstanceStats`)
  including its loot quality.
- It compares a copy with itself only when the two copies differ.
- It is tested by `tests/item_compare.test.ts` and `tests/item_compare_view.test.ts`.

### 1.7 Loot budgets per encounter

VERIFIED (`docs/design/instance-loot-budgets.md`):

- Raid bosses pay one equipment item per five intended players per kill.
- The budget uses the intended size, not the number of players present.
- Signature items keep fixed small chances (3% each) inside weighted partitions
  that sum to exactly 1.
- Trash and outdoor rares keep their own tables.

### 1.8 Licences

VERIFIED (`LICENSE`, `CREDITS.md`, `THIRD_PARTY_NOTICES.md`):

- **Source code:** MIT, © 2026 Levy Street.
- **Media is not covered by the MIT licence.** `CREDITS.md` is "the operative
  licence record for the project's media assets": unlisted media "are not licensed
  to you", and some (for example CraftPix class icons) must not be redistributed.
- **Wallet and marketplace dependencies** carry their own licences.
- The name, logos and branding are the project's.
- This adaptation copies **no code and no asset**. It reuses ideas only.

## 2. Exact reference files used

| Topic | File (at `d2b91e08`) |
|---|---|
| Per-copy loot quality | `docs/design/loot-quality.md`, `src/sim/loot/enemy_quality.ts`, `src/sim/loot/fresh_quality_grant.ts`, `tests/loot_quality*.test.ts` |
| Stat budget | `src/sim/item_budget.ts` (`QUALITY_STAT_MULT`, `SLOT_STAT_MULT`, `QUALITY_ILVL_BONUS`, `primaryStatBudget`, `normalizePrimaryStats`, `weaponDpsBudget`) |
| Item level | `src/sim/item_level.ts` (`itemLevel`, `expectedStatBudget`, `itemScore`), `tests/item_level.test.ts` |
| Colours | `src/ui/icons.ts` (`QUALITY_COLOR`), `src/styles/tokens.css` (`--color-quality-*`, `--mkt-name-*`) |
| Bags and bank | `src/ui/bags_window.ts`, `src/ui/bag_filter.ts` (`qualityRank`), `src/ui/bank_filter.ts`, `src/styles/components.css` |
| Comparison | `src/ui/item_compare.ts`, `tests/item_compare.test.ts` |
| Loot budgets | `docs/design/instance-loot-budgets.md` |
| Licences | `LICENSE`, `CREDITS.md`, `THIRD_PARTY_NOTICES.md` |

## 3. The Iron Legacy today: architecture

VERIFIED:

| Concern | Where |
|---|---|
| Grade ids and order | `client/sim/ContentDB.gd`: `RARITIES := ["common", "uncommon", "rare", "epic", "legendary", "godforged"]`; every item's `rarity` is checked against it on load |
| Item data | `client/data/items.json` (249 legacy items) and `client/data/item_catalog.json` (56 catalog items, loaded by `ItemCatalog`) |
| Stat budget (the item power rule) | `client/sim/ItemRules.gd`: score = Σ stat × `STAT_WEIGHTS`; budget = (10 + 2 × level) × `SLOT_WEIGHTS` × `GRADES`; ±15% enforced on load (`ItemRules.problems`, from `ContentDB`) |
| Hero stats and caps | `client/sim/PlayerProfile.gd` (`stats`, `gear_stats`; crit ≤ 0.5, attack speed 0.7–1.3) |
| Enhancement | `client/sim/EnhanceRules.gd` (+10% of each positive base stat per level, per copy, +0 to +10) |
| Drops and loot index | `client/sim/LootRules.gd`, `DropTables.gd`, `LootIndex.gd`, `ItemSources.gd` |
| Colours | `client/scenes/ui/ItemText.gd`: `RARITY_COLORS`, the only definition; `PlaceholderArt` reads it |
| Item cell | `client/scenes/ui/ItemSlot.gd` |
| Item card, tooltip and comparison | `client/scenes/ui/ItemCard.gd` |
| Bag | `client/scenes/game/CharacterTabs.gd` (`bag_order`, `_sort_key`) |
| Guide | `client/scenes/game/GuideScreen.gd`, `GuidePages.gd` |

## 4. Grades and their ids

VERIFIED:

| Order | Id | Name | Colour (`ItemText.RARITY_COLORS`) | Contrast on `UiTheme.PANEL` #161824 | `ItemRules.GRADES` |
|---:|---|---|---|---:|---:|
| 1 | `common` | Common | #d9d6cc (white) | 12.1:1 | 0.85 |
| 2 | `uncommon` | Uncommon | #7bd389 (green) | 9.7:1 | 1.00 |
| 3 | `rare` | Rare | #5fa8f0 (blue) | 7.0:1 | 1.15 |
| 4 | `epic` | Epic | #ffcf3d (gold) | 12.0:1 | 1.35 |
| 5 | `legendary` | Legendary | #ff4f4a (red) | 5.4:1 | 1.60 |
| 6 | `godforged` | Godforged | #a8f6ff (light blue) | 14.5:1 | 2.20 |

- All six pass WCAG AA (4.5:1) as text. Ratios computed with the WCAG formula.
- Two clashes:
  - Uncommon's green is **identical** to `UiTheme.GOOD` #7bd389, the colour of
    an improving stat in comparisons.
  - Legendary's red #ff4f4a is close to `UiTheme.DANGER` #e0524a, the colour of
    a worsening stat.
  - See §16.

## 5. Item counts and data sources

VERIFIED: 305 items in total.

- **249 legacy items** (`items.json`): 233 equipment, 10 key, 4 consumable and
  2 material.
- **56 catalog items** (`item_catalog.json`): 34 equipment (24 headgear, 5
  outfit, 5 weapon) and 22 non-equipment.

Equipment by grade (267):

| Grade | Count |
|---|---:|
| Common | 66 |
| Uncommon | 65 |
| Rare | 46 |
| Epic | 51 |
| Legendary | 14 |
| Godforged | 25 |

Six slots: head, body, hands, weapon, feet and charm. There are no weapon types
(`docs/ITEM_POWER_AUDIT.md` §7).

## 6. Base stats by grade

VERIFIED:

- Every equipment item's `ItemRules` score is within −11% to +12% of its budget.
  All 14 Legendaries are within ±1.5%.
- At the same level and slot, today's grades are therefore 50 / 59 / 68 / 79 / 94
  / 129, against Common = 50, by rule.
- Combat value, with caps applied, is compressed further, because crit and attack
  speed stop counting at their caps (`docs/ITEM_POWER_BALANCE_PROPOSAL.md` §2.3,
  §8).
- Full per-item tables: `docs/ITEM_POWER_AUDIT.md`, Appendix A.

## 7. Item levels

VERIFIED (`docs/ITEM_POWER_AUDIT.md` §3, §5):

| Grade | Level range |
|---|---|
| Common | 1–68 |
| Uncommon | 1–68 |
| Rare | 1–68 |
| Epic | 1–68 |
| Legendary | 9–48 (none at Lv 49–70, no feet) |
| Godforged | 30–70 |

Unlike the reference (§1.3), item level is authored per item and is not derived
from the source. Grade carries no level bump.

## 8. Enhancement

VERIFIED (`EnhanceRules.gd`, `progression.json`):

- Enhancement goes from +0 to +10, per copy. Each level adds 10% of each positive
  base stat (+10 doubles the stats). Penalties are never amplified.
- Success rates fall from 100% to 20%, with no pity.
- Costs grow above item Lv 51 and 61.
- Grade and item id never change. The bag cell shows "+N"
  (`ItemSlot.upgrade`), and the item card shows the copy's upgraded stats.
- Every grade scales the same way, so the ratios between grades hold at every
  level.

## 9. Inventory and bank presentation

VERIFIED:

- **Bag cell** (`ItemSlot.gd`):
  - A 1 px frame in the grade colour, with a soft grade-coloured glow rising from
    the bottom (16% alpha).
  - A gold "+N" corner badge for an upgraded copy.
  - A drop shadow behind the icon.
  - An empty cell uses `UiTheme.BORDER`.
  - The green upgrade arrow is decided by `ItemRules.is_upgrade` (score with
    upgrades).
- **Bag order** (`CharacterTabs._sort_key`): type group, then slot, then **grade
  by its place in `RARITIES`** (higher first), then name. Never by colour.
- **No search or filter in the bag.** VERIFIED (none in `CharacterTabs.gd`).
- **No bank.** VERIFIED: no bank or storage feature exists. "Bank" in `Game.gd` is
  a world boss attempt being "banked". Bank presentation is therefore a future
  feature, PROPOSED in §16.
- **Ground loot** (`LootView.gd`): a shadow, a glow and, for Epic and above, a
  light beam in the grade colour.

## 10. Tooltip and comparison

VERIFIED (`ItemCard.gd`, `ItemText.gd`):

- **The item card shows:**
  - The name in the grade colour, with "Grade Slot" (for example "Epic Weapon")
    under it.
  - The required level, in red when it is too high.
  - Stat lines.
  - Upgrade lines when worn, and the cost of the next level.
  - Sources (through `ItemSources` / `LootIndex`).
- **Comparison:**
  - `compare_lines(upgraded(candidate), upgraded(worn))` takes each copy's stats
    **with its enhancement** (`EnhanceRules.copy_bonus`). So a Rare +5 worn
    against a Legendary +0 candidate already compares real per-copy values.
  - It does **not** apply the caps. A candidate's extra crit past the 50% total
    shows as "+x% Crit" even when it would add nothing. That matches the reference
    neither way, since the reference's compare shows raw stat deltas too
    (`item_compare.ts`). It is noted as a gap (§13).

## 11. Loot and drop grades

VERIFIED:

- `docs/ITEM_DROP_DATABASE.md` holds 4,490 drop lines.
- `test_loot_index` enforces:
  - No Legendary or Godforged item from monsters or elites, and no `boss_only`
    item from them.
  - Godforged only as a world boss tier or kill reward.
- Stage-boss Legendaries are 6% pity drops:
  - +25% of the base chance per earlier kill while not owned, up to 50%.
  - Per character, saved.
  - No explicit reset: owning a copy returns the chance to its base.
- Catalog drops are marked as initial values.

## 12. Legendary and Godforged acquisition

VERIFIED:

- **Legendary:** stage bosses (the 10 legacy items, 6% pity) and catalog boss-only
  drops (4 items).
- **Godforged:** world boss tiers and kill rewards only. All 8 world bosses pay it,
  and the 3 raid bosses are labelled `"raid": true`.
- `docs/GODFORGED_IMPACT_REPORT.md` covers the "raid only" question, which is not
  approved.

## 13. Gaps between The Iron Legacy and the reference's principles

| # | Gap | Status |
|---:|---|---|
| G1 | Grade weights are compressed. Our Legendary is 1.19 × Epic; the reference's legendary is 1.9 × epic and calls it "a steep jump" | VERIFIED gap; the size of the fix is in the MR validation |
| G2 | No Legendary at Lv 49–70 and no Legendary feet | VERIFIED |
| G3 | Item level is not tied to source or grade (no rarity level bump) | VERIFIED; PROPOSED to keep authored levels (§14.2) |
| G4 | Stat weights price capped crit and attack speed as if they counted | VERIFIED (`docs/ITEM_POWER_BALANCE_PROPOSAL.md` §8) |
| G5 | Comparison shows raw deltas past the caps | VERIFIED |
| G6 | Colour clashes: Uncommon = GOOD, Legendary ≈ DANGER | VERIFIED |
| G7 | No bag search, filter or grade sort chip | VERIFIED |
| G8 | No bank | VERIFIED (out of scope until a bank is approved) |
| G9 | Grade is shown only as a word, with no non-colour cue on the cell | VERIFIED; the reference badges per-copy quality with a glyph, not a colour |
| G10 | Encounter loot budgets are written per boss, not from a rule (for example items per intended player) | VERIFIED; PROPOSED as a documented guideline only |

## 14. Target architecture (PROPOSED)

### 14.1 Separation of concerns

| Concern | Lives in | Changes |
|---|---|---|
| Item identity | `id`, name and description in `items.json` / `item_catalog.json` | none |
| Grade | `rarity` (one of `ContentDB.RARITIES`) | none to ids. The order is defined once in `ContentDB.RARITIES` |
| Level | `level` (authored) | none; new items follow §14.2 |
| Slot | `slot` | none |
| Base stats | `stats`, priced by `ItemRules` | grade weights per the chosen model; scaled through the content generator |
| Per-copy progression | `PlayerProfile.enhance` (+0 to +10) | none |
| Appearance | `appearance` / icon | none |
| Acquisition | drop tables → `LootIndex` | new Legendary sources only after approval |
| Presentation | `ItemText` (colours, names, ranks), `ItemSlot`, `ItemCard` | §16 |

### 14.2 Grade and level stay separate (PROPOSED)

- **Level** sets the scale: (10 + 2 × level).
- **Slot** sets the share: `SLOT_WEIGHTS`.
- **Grade** sets the multiplier: `GRADES`.
- This is the same separation the reference uses (§1.2), and our `ItemRules`
  already has it.
- **Recommendation:** keep authored levels. A reference-style rarity level bump
  would change the level requirements of all 305 items. Instead, place new
  higher-grade items at the level of the content that drops them, as the 12
  proposed Legendaries are (lair level).
- **A low-level Legendary stays below high-level gear.** With MR weights, a Lv 30
  Legendary's budget is 70 × 1.8 = 126, while a Lv 68 Rare's is 146 × 1.22 = 178.
- **At the same level the grade decides.** That is the owner's rule, and the
  budget formula guarantees it.

### 14.3 One definition of grade order and colour (PROPOSED)

- Grade order stays in `ContentDB.RARITIES`. The colour stays in
  `ItemText.RARITY_COLORS`, which is already the only definition.
- Add a test that every colour is defined for every grade and stays AA on
  `UiTheme.PANEL`. This mirrors the reference's pinned-equal colour test.
- Add a test that no scene file contains a grade colour literal.

## 15. Six-grade power progression (PROPOSED; numbers in the MR validation)

- **The owner's illustrative curve** is 50 / 80 / 120 / 170 / 250 with Godforged
  TBD. Against Common, that means grade weights 0.85 / 1.36 / 2.04 / 2.89 / 4.25.
  This is Model A's shape.
- **Godforged must stay above Legendary.** Today's Godforged weight 2.2 is index
  129, below that curve's Legendary 250. So that curve **requires** a Godforged
  raise. Model A's Godforged index of 350 is a weight of 5.95, ×2.70 today's.
- **The balance work so far** (`docs/ITEM_POWER_BALANCE_PROPOSAL.md`, validated in
  `docs/ITEM_POWER_MR_VALIDATION.md`) compared today, MR (Godforged frozen), Model
  B and Model A in simulation.
- The recommendation and the Godforged options (unchanged, re-mix, raise) are in
  the validation report. This document does not pick a final Godforged number.
- **The reference's legendary/epic gap is ×1.9.** That supports a larger
  Legendary step than today's ×1.19. It does not by itself say how far ours can
  go: our flat-defense and cap rules (§13 G4) make high budgets hit floors sooner
  than the reference's stat model does.

## 16. UI presentation changes (PROPOSED; restrained)

1. **Colour clashes:**
   - Move the comparison colours off the grade palette. For example, "better" in
     a teal-green that is not #7bd389, and "worse" in an orange-red away from
     Legendary.
   - Or add an arrow or "▲/▼" glyph to every delta, so comparisons never rely on
     colour alone. The glyph alone is enough.
2. **A non-colour grade cue:** a small grade letter or pip count on the bag cell
   (C/U/R/E/L/G, or 1–6 pips). It sits in the corner opposite "+N" and stays
   readable for colour-blind players. The reference badges its per-copy quality
   the same way.
3. **The item card:**
   - Keep the name in grade colour and "Grade Slot" under it.
   - Add "Lv N" and "+N" next to it.
   - Show a capped stat as "Crit 50% (cap)", with the excess greyed, both on the
     stat sheet and in comparisons.
4. **Bag:**
   - Add a search field (name) and a grade filter (All, or one grade and up).
   - Keep today's order (type → slot → grade → name) as the default.
   - Add a "Grade" sort that uses `RARITIES` order, never colour.
   - Mirror the reference's shared rank function: one `grade_rank` used by the
     bag, the Guide and any future bank.
5. **Bank (only if a bank is approved):**
   - The same `ItemSlot` cell, the same filter and sort code, and the slot index
     preserved through filter and sort (§1.5).
6. **Mobile:** the 1 px rim and the corner glyph must stay visible at the smallest
   cell size. To be checked with the UI audit (`res://tests/ui/UiAuditRun.gd`)
   at phone sizes.

## 17. Testing strategy (PROPOSED)

| Area | Test |
|---|---|
| Grade data | `RARITIES` has six ids in order; every item's grade is valid (exists: `test_item_grades`) |
| Colours | one colour per grade, AA on `UiTheme.PANEL`, no grade colour literals in scenes; the delta colours differ from every grade colour |
| Budget | `ItemRules.problems` clean (exists); with the chosen model, same-level, same-slot grade order is strict; the 12 Legendaries are on budget |
| Enhancement | grade unchanged by enhancement; ratios kept from +0 to +10 (exists in part in `test_level70_gear`) |
| Comparison | `ItemCard.details` deltas equal `PlayerProfile.stats` differences with caps (new) |
| Bag | `grade_rank` sort and filter; no colour-based sort |
| Loot | `test_loot_index` (exists): no Legendary or Godforged from monsters; the drop database regenerated |
| UI | UI audit with no new findings; screenshots of bag, card and Guide at desktop and phone sizes |
| Balance | the harness pass listed in `docs/ITEM_POWER_MR_VALIDATION.md` |

## 18. Risks and backward compatibility

- **Saves:** stats are read from data at load and enhancement is per copy, so a
  stat change needs no migration (VERIFIED, `PlayerProfile.gear_stats`). New items
  only add ids.
- **Stable ids:** no id changes are proposed.
- **Balance:** see the risks in the MR validation (enemy curve, arena tiers,
  world boss pools).
- **UI:** colour changes affect every screen that draws deltas. Screenshots must
  be compared.
- **Reference drift:** the reference changes daily. These findings are pinned to
  commit `d2b91e08`.

## 19. Licence and third-party assets

- Nothing from the reference is used.
  - Its MIT licence covers code only.
  - Its art, icons, audio and fonts follow `CREDITS.md`, and some must not be
    redistributed.
  - Its name and branding are its own.
- If any reference code is later adapted, keep the MIT notice ("Copyright (c) 2026
  Levy Street") with that portion and record it in a credits file. None is
  planned: every proposal here is an original Godot implementation of a general
  technique.
- The Iron Legacy's hat art stays the owner's temporary placeholder art (separate
  from the art pipeline, as before).

## 20. Phased implementation plan (each phase waits for approval)

| Phase | Scope | Kind |
|---:|---|---|
| 1 | Colour clash fix and delta glyphs; grade letter or pips on cells; colour tests | UI |
| 2 | Capped values shown on the stat sheet, item card and comparison | UI |
| 3 | Bag search, grade filter and grade sort through one `grade_rank` | UI |
| 4 | The chosen grade-weight model in `ItemRules`, rescaled through the content generator, docs regenerated | rules and data |
| 5 | The 12 Lv 55–70 Legendaries and their sources (needs Story Bible names) | content and drops |
| 6 | Cap-aware slot budgets (per-slot crit and attack-speed ceilings) | rules and data |
| 7 | Godforged option (none, re-mix or raise), separately approved | rules and data |
| 8 | Bank, only if approved as a feature | feature |

Phases 1–3 are independent of the balance decision and carry no gameplay risk.
