# Item power audit: grade progression at +0 and with enhancement

**Status: analysis only. No item stat, formula, level requirement, drop,
reward or world boss table was changed for this report.** Every proposal in
§12 and §13 waits for the owner's approval (§15).

Generated from `client/data/items.json` (249 legacy items) and
`client/data/item_catalog.json` (56 catalog items) as they stand in the working
tree, using the formulas in `client/sim/PlayerProfile.gd` (`stats`,
`gear_stats`), `client/sim/EnhanceRules.gd` (`bonus_at`),
`client/sim/CombatRules.gd` and `client/sim/LevelRules.gd`. The analysis
scripts lived in the session scratchpad and are not part of the repository;
every number below can be recomputed from the formulas quoted in §2.

## 0. Corrections (added with docs/ITEM_POWER_BALANCE_PROPOSAL.md)

Two statements in this audit were wrong. They are corrected here; the rest of the
report stands as written.

1. **The game already has an item power rule.** This audit did not mention it.
   - `client/sim/ItemRules.gd` gives every equipment item a score, which is the
     sum of its stats × `STAT_WEIGHTS`.
   - It also gives a budget: `(10 + 2 × level) × slot weight × grade weight`, with
     grade weights Common 0.85, Uncommon 1.0, Rare 1.15, Epic 1.35, Legendary 1.6
     and Godforged 2.2.
   - `ContentDB` rejects any item more than 15% off its budget. Today every item is
     within −11% to +12%.
   - So the compressed grade index in §3 (about 50 / 59 / 68 / 79 / 94 / 129 in
     score terms) is the rule working as designed, not drift.
   - The items listed as under target in §13 H1–H3 are on budget. Their low
     *combat* value comes from the stat weights (crit is priced above its worth
     once the 50% cap is near) and from the grade weights themselves.
   - The balance proposal works from `ItemRules`.
2. **§13 L3 is wrong.** A price of 0 does not stop a sale: `ItemRules.value` prices
   equipment without a price from its budget (× 11 coins per point).

## 1. Executive summary

1. **305 items: 267 are equipment** (233 legacy, 34 catalog) **and 38 are not**
   (keys, consumables, ores, enhancement materials, boss materials and specials;
   Appendix B). Grade comparisons below cover only the 267 equipment items.
2. **The root cause of "Legendary feels like Rare": grade is not tied to level.**
   Common, Uncommon, Rare and Epic each run from about Lv 1 to Lv 68, and item
   stats grow mainly with the required level. Legendary runs only from **Lv 9 to
   Lv 48** (14 items, all stage-boss and story prizes, none for feet and none above
   Lv 48). So by the late game, many Rare and Epic items have **higher raw stats
   than every Legendary** (§8). For example, `director_crown` (Legendary, Lv 48)
   and `heart_rare_head` (Rare, Lv 68) are both worth 35% to a Lv 70 hero, and
   `heart_epic_head` (Epic, Lv 68) is worth 41%.
3. **Within the same slot and level band, grades do rise, but too little.**
   Indexed to Common = 50, today's medians are about **50 / 60 / 70 / 85 / 100–137 /
   136–198**. The reference is 50 / 80 / 120 / 170 / 250 / 350 (§3, §4).
   - Common to Epic is only about +70%; the reference is +240%.
   - Legendary is only 1.06–1.67 × the Epic of its own band.
4. **11 strict inversions:** a lower-grade item at the same or a lower level is
   worth as much as, or more than, a higher-grade one (§4.3). Most are early-game
   footwear.
5. **No item has a special effect.** Equipment carries only six numeric stats:
   `max_hp`, `power`, `defense`, `crit`, `attack_speed` and `speed`. There are no
   weapon types, set bonuses or on-hit effects. Passives belong to skills and jobs,
   not to items (§7).
6. **Enhancement treats every grade the same:** +10% of each positive base stat per
   level, so +10 is ×2.0 (§6).
   - The ratio between grades never changes with enhancement; the absolute gap
     doubles.
   - The problems at high enhancement come from the **caps and flat defense**, not
     from the grades:
     - Total crit is capped at 50%, and an endgame Uncommon set already reaches it.
     - Attack speed is capped at 1.3.
     - In PvE, defense is subtracted flat from each hit, so at +7 a Godforged set's
       defense (119) exceeds the reference monster hit at Lv 70 (85).
7. **Recommendation (§12): Model B.** It spaces the grades geometrically and keeps
   today's Godforged as the top anchor: 50 / 65 / 85 / 110 / 145 / 190 against a
   Common of the same slot and level.
   - It fixes the grade identity with modest stat changes, mostly to Epic and
     Legendary.
   - Model A, the full reference curve, is also costed. It would raise the gear
     share of a hero's power by up to 2×, which the level curve and the enemies were
     not tuned for.
   - Separately, **Legendary needs level coverage from Lv 49 to 70 and a feet item**.
     That is new content and needs approval.

## 2. Method

### 2.1 What the game actually computes

- **Hero stats** (`PlayerProfile.stats`):
  - `max_hp = hero base + 10 × (level − 1) + gear`
  - `power = hero base + 0.05 × (level − 1) + gear`
  - `defense = hero base + gear`
  - `crit = clamp(hero base + gear, 0, 0.5)`
  - `attack_speed = clamp(hero base + gear, 0.7, 1.3)`
  - `speed = max(0.3, hero base + gear)` (movement; no upper cap)
- **Gear** (`gear_stats`): the sum over the six slots (head, body, hands, weapon,
  feet, charm) of each item's `stats`, plus `EnhanceRules.bonus_at`.
- **Enhancement** (`bonus_at`): `stat × bonus_per_level (0.1) × level` for each
  **positive** stat. Negative stats (three items with a `speed` penalty) are never
  amplified. HP and defense are rounded. The maximum is +10. The success rates
  are 100/95/90/80/70/60/50/40/30/20%, so about 20.3 attempts are expected to reach +10.
  The cost bands double or triple above item Lv 51 and 61. Grade plays no part in
  any of this.
- **Damage dealt** (`CombatRules`): `move damage × attacker power`. Crits deal
  ×1.5 (`CRIT_DAMAGE`). Attack speed scales how fast moves play.
- **Damage taken:**
  - PvE: `max(1, raw − defense)` (flat).
  - PvP: defense takes a share `defense / (defense + 90)` (`PVP_DEFENSE_K`). The
    arena also doubles HP (`arena.json` `hp_scale` 2.0).
- **Enemies** (`LevelRules.enemy_stats`): power ×(1 + 0.08 per level), HP
  ×(1 + 0.06 per level), defense + 1 per 8 levels.

### 2.2 Displayed versus effective

The item card shows the raw `stats`, and that is what the game adds. What a stat
is *worth* depends on the hero's level, because power, crit and attack speed
multiply and HP and defense depend on how hard enemies hit. It also depends on
the caps: crit above 50% and attack speed above 1.3 do nothing. So this audit
values items as follows, and keeps the raw stats beside every value.

### 2.3 Item value (the comparison metric)

For an item of required level L, against a bare reference hero of level L
(power 1 + 0.05(L−1), HP 115 + 10(L−1), crit 0.05):

- **Offense** = (1 + Δpower / hero power) × (1 + 0.5 × Δcrit) × (1 + Δattack_speed) − 1
- **Defense** = (1 + ΔHP / hero HP) × H / (H − Δdefense) − 1
  - H is the **reference monster hit** at level L: the median base hit of
    ordinary monsters' moves (13, from `enemies.json` and `moves.json`) ×
    (1 + 0.08(L−1)).
  - So H is 13 at Lv 1, 43 at Lv 30 and 85 at Lv 70.
- **Value** = (1 + offense) × (1 + defense) − 1: the share of combat strength the
  item adds to a bare hero of its level.
- `speed` (movement) is listed but not valued. It changes positioning, not damage.
  So `canvas_sneakers` (speed only) shows 0%.

Limitations, stated plainly:

- The reference hit is a median. Bosses hit harder, so defense matters less
  against them.
- Enemy flat defense (1–13) makes power slightly more valuable than shown.
- Crit is valued linearly up to the item level, but the 50% cap applies to the
  whole set (§6.3).

The metric ranks items consistently with the game's formulas. It is not a
time-to-kill simulation, so §9 recommends confirming changes with the progression
harness.

"Value at Lv 70" uses the same formula against a Lv 70 hero. It compares items as
an endgame player sees them.

## 3. Grade-by-grade distribution

| Grade | Equipment | weapon | head | body | hands | feet | charm | Lv range | Lv 1-15 | 16-35 | 36-55 | 56-70 |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| Common | 66 | 12 | 15 | 13 | 10 | 12 | 4 | 1–68 | 22 | 15 | 11 | 18 |
| Uncommon | 65 | 12 | 16 | 12 | 9 | 11 | 5 | 3–68 | 21 | 15 | 11 | 18 |
| Rare | 46 | 6 | 13 | 7 | 8 | 6 | 6 | 1–68 | 15 | 5 | 8 | 18 |
| Epic | 51 | 8 | 14 | 9 | 6 | 8 | 6 | 3–68 | 8 | 15 | 10 | 18 |
| Legendary | 14 | 4 | 4 | 1 | 1 | 0 | 4 | 9–48 | 2 | 8 | 4 | 0 |
| Godforged | 25 | 6 | 3 | 4 | 4 | 2 | 6 | 30–70 | 0 | 2 | 4 | 19 |

Two facts drive most of what follows:

- Grades 1–4 cover the whole level range.
- Legendary stops at Lv 48 and Godforged starts at Lv 30.

Today, grade means "how good for its level", not "how far along the game".

**Today's index, against Common = 50 in the same slot and level band** (median
value; from §4):

| Slot | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---:|---:|---:|---:|
| weapon | 59–76 | 67–96 | 76–99 | 100–137 | 140–198 |
| head | 58–72 | 66–95 | 82–85 | 101–114 | 153 |
| body | 60–62 | 73–84 | 84–91 | 106 | 171–181 |
| hands | 57–87 | 63–71 | 63–85 | 125 | 136–197 |
| feet | 55–63 | 64–85 | 77–94 | none | 139 |
| charm | 59–60 | 69 | 84–85 | 106 | 180–181 |
| **reference** | **80** | **120** | **170** | **250** | **350** |

## 4. Equipment-slot comparisons at +0

### 4.1 Per slot, per level band, per grade


### Weapon

Value = the item's combat value against a bare hero of the item's own required level (§2.3). Raw stats are the medians of the group.

| Level band | Grade | n | Median value | Min–max value | Median raw stats | Index (Common = 50) | Step vs grade below |
|---|---|---:|---:|---|---|---:|---:|
| early 1-15 | Common | 4 | 17% | 13%–22% | crit 0.015, power 0.19 | 50 | – |
| early 1-15 | Uncommon | 4 | 25% | 19%–26% | crit 0.02, power 0.325, speed 0 | 76 | +52% |
| early 1-15 | Rare | 1 | 32% | 32%–32% | crit 0.06, power 0.48 | 96 | +26% |
| early 1-15 | Epic | 1 | 33% | 33%–33% | max_hp 9, power 0.31 | 99 | +3% |
| early 1-15 | Legendary | 2 | 46% | 41%–51% | crit 0.075, max_hp 20.5, power 0.455 | 137 | +39% |
| mid 16-35 | Common | 3 | 29% | 27%–32% | crit 0.07, power 0.57 | 50 | – |
| mid 16-35 | Uncommon | 3 | 35% | 31%–38% | crit 0.08, power 0.68 | 60 | +19% |
| mid 16-35 | Epic | 3 | 44% | 44%–48% | crit 0.095, defense 1, power 0.76 | 76 | +27% |
| mid 16-35 | Legendary | 1 | 58% | 58%–58% | crit 0.146, power 1.16 | 100 | +31% |
| mid 16-35 | Godforged | 1 | 82% | 82%–82% | crit 0.23, power 1.54 | 140 | +40% |
| late 36-55 | Common | 2 | 35% | 34%–37% | crit 0.1, power 0.98 | 50 | – |
| late 36-55 | Uncommon | 2 | 42% | 41%–43% | crit 0.12, power 1.155 | 60 | +19% |
| late 36-55 | Rare | 2 | 47% | 45%–50% | crit 0.14, power 1.225 | 67 | +12% |
| late 36-55 | Epic | 1 | 62% | 62%–62% | crit 0.2, defense 2, power 1.55 | 88 | +31% |
| late 36-55 | Legendary | 1 | 76% | 76%–76% | attack_speed 0.12, crit 0.15, power 1.35 | 108 | +23% |
| late 36-55 | Godforged | 1 | 126% | 126%–126% | attack_speed 0.19, crit 0.27, power 2.32 | 178 | +65% |
| end 56-70 | Common | 3 | 39% | 38%–40% | crit 0.13, power 1.24 | 50 | – |
| end 56-70 | Uncommon | 3 | 46% | 45%–47% | crit 0.15, power 1.46 | 59 | +18% |
| end 56-70 | Rare | 3 | 54% | 52%–55% | crit 0.19, power 1.65 | 69 | +17% |
| end 56-70 | Epic | 3 | 65% | 64%–67% | crit 0.23, defense 2, power 1.81 | 84 | +21% |
| end 56-70 | Godforged | 4 | 153% | 142%–157% | attack_speed 0.27, crit 0.335, power 3.035 | 198 | +135% |

### Head

Value = the item's combat value against a bare hero of the item's own required level (§2.3). Raw stats are the medians of the group.

| Level band | Grade | n | Median value | Min–max value | Median raw stats | Index (Common = 50) | Step vs grade below |
|---|---|---:|---:|---|---|---:|---:|
| early 1-15 | Common | 7 | 15% | 13%–21% | defense 1, max_hp 12 | 50 | – |
| early 1-15 | Uncommon | 8 | 22% | 18%–22% | defense 2, max_hp 21 | 72 | +44% |
| early 1-15 | Rare | 8 | 29% | 29%–30% | defense 4, max_hp 27 | 95 | +32% |
| early 1-15 | Epic | 2 | 25% | 19%–31% | crit 0.03, defense 1.5, max_hp 35 | 82 | -14% |
| mid 16-35 | Common | 3 | 22% | 21%–23% | defense 3, max_hp 43 | 50 | – |
| mid 16-35 | Uncommon | 3 | 27% | 25%–28% | defense 4, max_hp 50 | 60 | +20% |
| mid 16-35 | Rare | 1 | 30% | 30%–30% | crit 0.04, defense 5, max_hp 50 | 66 | +11% |
| mid 16-35 | Epic | 7 | 38% | 38%–38% | defense 6, max_hp 46 | 85 | +28% |
| mid 16-35 | Legendary | 3 | 51% | 40%–51% | crit 0, defense 10, max_hp 64 | 114 | +34% |
| late 36-55 | Common | 2 | 24% | 23%–24% | defense 5.5, max_hp 72.5 | 50 | – |
| late 36-55 | Uncommon | 2 | 29% | 28%–30% | defense 7, max_hp 84.5 | 62 | +24% |
| late 36-55 | Rare | 1 | 33% | 33%–33% | crit 0.07, defense 8, max_hp 84 | 70 | +13% |
| late 36-55 | Epic | 2 | 40% | 38%–41% | crit 0.055, defense 8, max_hp 106 | 84 | +20% |
| late 36-55 | Legendary | 1 | 48% | 48%–48% | crit 0.11, defense 9, max_hp 115 | 101 | +20% |
| end 56-70 | Common | 3 | 25% | 25%–26% | defense 8, max_hp 94 | 50 | – |
| end 56-70 | Uncommon | 3 | 29% | 29%–30% | defense 9, max_hp 110 | 58 | +17% |
| end 56-70 | Rare | 3 | 35% | 34%–36% | crit 0.08, defense 10, max_hp 98 | 71 | +21% |
| end 56-70 | Epic | 3 | 42% | 41%–42% | crit 0.07, defense 10, max_hp 137 | 84 | +18% |
| end 56-70 | Godforged | 3 | 77% | 72%–77% | crit 0.21, defense 17, max_hp 223 | 153 | +83% |

### Body

Value = the item's combat value against a bare hero of the item's own required level (§2.3). Raw stats are the medians of the group.

| Level band | Grade | n | Median value | Min–max value | Median raw stats | Index (Common = 50) | Step vs grade below |
|---|---|---:|---:|---|---|---:|---:|
| early 1-15 | Common | 5 | 22% | 18%–28% | defense 2, max_hp 15 | 50 | – |
| early 1-15 | Uncommon | 4 | 26% | 24%–31% | defense 2, max_hp 24.5 | 60 | +19% |
| early 1-15 | Rare | 2 | 37% | 35%–39% | defense 3.5, max_hp 36 | 84 | +40% |
| early 1-15 | Epic | 1 | 40% | 40%–40% | defense 3, max_hp 40 | 91 | +9% |
| mid 16-35 | Common | 3 | 29% | 27%–32% | defense 5, max_hp 46 | 50 | – |
| mid 16-35 | Uncommon | 3 | 36% | 35%–38% | defense 6, max_hp 55 | 62 | +23% |
| mid 16-35 | Rare | 1 | 43% | 43%–43% | defense 7, max_hp 55 | 74 | +20% |
| mid 16-35 | Epic | 2 | 49% | 48%–50% | defense 6.5, max_hp 72 | 84 | +14% |
| mid 16-35 | Legendary | 1 | 62% | 62%–62% | defense 9, max_hp 113 | 106 | +25% |
| late 36-55 | Common | 2 | 32% | 32%–33% | defense 8.5, max_hp 79.5 | 50 | – |
| late 36-55 | Uncommon | 2 | 39% | 39%–39% | defense 10, max_hp 94.5 | 61 | +21% |
| late 36-55 | Rare | 1 | 48% | 48%–48% | defense 14, max_hp 108 | 75 | +23% |
| late 36-55 | Epic | 3 | 56% | 54%–57% | defense 14, max_hp 125 | 88 | +18% |
| late 36-55 | Godforged | 1 | 109% | 109%–109% | defense 22, max_hp 226 | 171 | +94% |
| end 56-70 | Common | 3 | 33% | 32%–34% | defense 11, max_hp 103 | 50 | – |
| end 56-70 | Uncommon | 3 | 40% | 40%–40% | defense 13, max_hp 122 | 61 | +22% |
| end 56-70 | Rare | 3 | 48% | 48%–48% | defense 16, max_hp 127 | 73 | +19% |
| end 56-70 | Epic | 3 | 58% | 58%–59% | defense 18, max_hp 159 | 89 | +22% |
| end 56-70 | Godforged | 3 | 119% | 115%–119% | defense 32, max_hp 292 | 181 | +103% |

### Hands

Value = the item's combat value against a bare hero of the item's own required level (§2.3). Raw stats are the medians of the group.

| Level band | Grade | n | Median value | Min–max value | Median raw stats | Index (Common = 50) | Step vs grade below |
|---|---|---:|---:|---|---|---:|---:|
| early 1-15 | Common | 2 | 10% | 5%–15% | attack_speed 0.03, defense 0.5, power 0.065 | 50 | – |
| early 1-15 | Uncommon | 1 | 17% | 17%–17% | attack_speed 0.04, defense 1, power 0.13 | 87 | +74% |
| early 1-15 | Rare | 2 | 12% | 12%–13% | crit 0.02, defense 1, power 0.05 | 63 | -27% |
| early 1-15 | Epic | 1 | 12% | 12%–12% | attack_speed 0.03, crit 0.04, power 0.09 | 63 | -0% |
| mid 16-35 | Common | 3 | 15% | 14%–17% | crit 0.05, defense 1, power 0.21 | 50 | – |
| mid 16-35 | Uncommon | 3 | 17% | 16%–20% | crit 0.06, defense 1, power 0.25 | 58 | +16% |
| mid 16-35 | Rare | 1 | 20% | 20%–20% | crit 0.06, defense 2, power 0.18 | 67 | +16% |
| mid 16-35 | Epic | 1 | 22% | 22%–22% | crit 0.07, defense 2, power 0.22 | 75 | +12% |
| mid 16-35 | Legendary | 1 | 37% | 37%–37% | attack_speed 0.07, crit 0.11, defense 3, power 0.37 | 125 | +67% |
| late 36-55 | Common | 2 | 19% | 18%–19% | crit 0.075, defense 2, power 0.36 | 50 | – |
| late 36-55 | Uncommon | 2 | 21% | 21%–21% | crit 0.085, defense 2, power 0.425 | 57 | +14% |
| late 36-55 | Rare | 2 | 25% | 25%–25% | crit 0.095, defense 3, power 0.465 | 68 | +19% |
| late 36-55 | Epic | 1 | 30% | 30%–30% | crit 0.16, defense 4, power 0.49 | 82 | +21% |
| late 36-55 | Godforged | 1 | 51% | 51%–51% | crit 0.16, defense 5, power 0.88 | 136 | +66% |
| end 56-70 | Common | 3 | 19% | 19%–21% | crit 0.09, defense 2, power 0.46 | 50 | – |
| end 56-70 | Uncommon | 3 | 24% | 24%–25% | crit 0.11, defense 3, power 0.54 | 63 | +25% |
| end 56-70 | Rare | 3 | 28% | 27%–28% | crit 0.12, defense 4, power 0.58 | 71 | +14% |
| end 56-70 | Epic | 3 | 33% | 33%–36% | crit 0.18, defense 5, power 0.58 | 85 | +20% |
| end 56-70 | Godforged | 3 | 76% | 74%–80% | attack_speed 0.17, crit 0.26, defense 7, power 0.88 | 197 | +130% |

### Feet

Value = the item's combat value against a bare hero of the item's own required level (§2.3). Raw stats are the medians of the group.

| Level band | Grade | n | Median value | Min–max value | Median raw stats | Index (Common = 50) | Step vs grade below |
|---|---|---:|---:|---|---|---:|---:|
| early 1-15 | Common | 4 | 9% | 0%–15% | attack_speed 0, defense 1, max_hp 6, speed 0.045 | 50 | – |
| early 1-15 | Uncommon | 3 | 11% | 8%–17% | attack_speed 0, defense 1, max_hp 14, speed 0.04 | 63 | +26% |
| early 1-15 | Rare | 1 | 12% | 12%–12% | defense 3, speed 0.13 | 69 | +9% |
| early 1-15 | Epic | 2 | 14% | 13%–16% | defense 1.5, max_hp 13.5, speed 0.065 | 81 | +18% |
| mid 16-35 | Common | 3 | 11% | 11%–14% | attack_speed 0.05, defense 2, speed 0.14 | 50 | – |
| mid 16-35 | Uncommon | 3 | 12% | 12%–15% | attack_speed 0.06, defense 2, speed 0.16 | 55 | +10% |
| mid 16-35 | Rare | 1 | 18% | 18%–18% | attack_speed 0.08, defense 4, speed 0.17 | 85 | +55% |
| mid 16-35 | Epic | 1 | 20% | 20%–20% | attack_speed 0.09, defense 4, speed 0.2 | 94 | +10% |
| late 36-55 | Common | 2 | 15% | 14%–17% | attack_speed 0.09, defense 3.5, speed 0.175 | 50 | – |
| late 36-55 | Uncommon | 2 | 20% | 18%–21% | attack_speed 0.11, defense 4.5, speed 0.205 | 63 | +27% |
| late 36-55 | Rare | 1 | 23% | 23%–23% | attack_speed 0.12, defense 6, speed 0.25 | 74 | +17% |
| late 36-55 | Epic | 2 | 25% | 23%–27% | attack_speed 0.125, defense 6, speed 0.28 | 81 | +9% |
| end 56-70 | Common | 3 | 20% | 18%–20% | attack_speed 0.12, defense 5, speed 0.22 | 50 | – |
| end 56-70 | Uncommon | 3 | 24% | 21%–24% | attack_speed 0.14, defense 6, speed 0.26 | 60 | +19% |
| end 56-70 | Rare | 3 | 25% | 25%–27% | attack_speed 0.14, defense 7, speed 0.3 | 64 | +7% |
| end 56-70 | Epic | 3 | 30% | 28%–31% | attack_speed 0.17, defense 8, speed 0.37 | 77 | +20% |
| end 56-70 | Godforged | 2 | 55% | 52%–58% | attack_speed 0.31, defense 12, speed 0.58 | 139 | +81% |

### Charm

Value = the item's combat value against a bare hero of the item's own required level (§2.3). Raw stats are the medians of the group.

| Level band | Grade | n | Median value | Min–max value | Median raw stats | Index (Common = 50) | Step vs grade below |
|---|---|---:|---:|---|---|---:|---:|
| early 1-15 | Uncommon | 1 | 9% | 9%–9% | crit 0.03, max_hp 9, power 0.01 | – | – |
| early 1-15 | Rare | 1 | 17% | 17%–17% | max_hp 20 | – | +88% |
| early 1-15 | Epic | 1 | 25% | 25%–25% | attack_speed 0.06, max_hp 25, power 0.05 | – | +42% |
| mid 16-35 | Rare | 1 | 25% | 25%–25% | crit 0.07, max_hp 55, power 0.11 | – | – |
| mid 16-35 | Epic | 1 | 35% | 35%–35% | crit 0.08, defense 3, max_hp 100 | – | +41% |
| mid 16-35 | Legendary | 2 | 41% | 38%–45% | attack_speed 0.065, crit 0.055, max_hp 77.5, power 0.17 | – | +17% |
| mid 16-35 | Godforged | 1 | 69% | 69%–69% | attack_speed 0.15, max_hp 144, power 0.21 | – | +67% |
| late 36-55 | Common | 1 | 23% | 23%–23% | crit 0.1, max_hp 77, power 0.15 | 50 | – |
| late 36-55 | Uncommon | 1 | 27% | 27%–27% | crit 0.12, max_hp 91, power 0.18 | 60 | +20% |
| late 36-55 | Rare | 1 | 31% | 31%–31% | crit 0.13, max_hp 105, power 0.21 | 69 | +15% |
| late 36-55 | Epic | 1 | 38% | 38%–38% | crit 0.12, defense 4, max_hp 145 | 85 | +23% |
| late 36-55 | Legendary | 2 | 48% | 44%–51% | attack_speed 0.045, crit 0.11, max_hp 147.5, power 0.24 | 106 | +24% |
| late 36-55 | Godforged | 1 | 82% | 82%–82% | attack_speed 0.21, max_hp 207, power 0.3 | 180 | +71% |
| end 56-70 | Common | 3 | 24% | 24%–25% | crit 0.12, max_hp 91, power 0.18 | 50 | – |
| end 56-70 | Uncommon | 3 | 29% | 28%–30% | crit 0.14, max_hp 107, power 0.21 | 59 | +18% |
| end 56-70 | Rare | 3 | 34% | 32%–34% | crit 0.16, max_hp 123, power 0.25 | 69 | +17% |
| end 56-70 | Epic | 3 | 41% | 41%–41% | crit 0.14, defense 5, max_hp 170 | 84 | +21% |
| end 56-70 | Godforged | 4 | 88% | 83%–91% | attack_speed 0.17, crit 0.17, max_hp 265, power 0.455 | 181 | +116% |

### 4.2 Best item of each grade, as a Lv 70 hero sees it

| Slot | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---|---|---|---|---|---|
| weapon | 39% `used_heart_uncommon_weapon` (Lv 68) | 46% `heart_uncommon_weapon` (Lv 68) | 54% `heart_rare_weapon` (Lv 68) | 65% `heart_epic_weapon` (Lv 68) | 57% `arthit_baton` (Lv 39) | 157% `sovereign_fists` (Lv 70) |
| head | 24% `used_heart_uncommon_head` (Lv 68) | 28% `heart_uncommon_head` (Lv 68) | 35% `heart_rare_head` (Lv 68) | 41% `heart_epic_head` (Lv 68) | 35% `director_crown` (Lv 48) | 77% `sovereign_crown` (Lv 70) |
| body | 33% `used_heart_uncommon_body` (Lv 68) | 39% `heart_uncommon_body` (Lv 68) | 46% `heart_rare_body` (Lv 68) | 56% `heart_epic_body` (Lv 68) | 28% `crimson_warlord_mantle` (Lv 30) | 119% `sovereign_mantle` (Lv 70) |
| hands | 21% `used_heart_uncommon_hands` (Lv 68) | 24% `heart_uncommon_hands` (Lv 68) | 28% `heart_rare_hands` (Lv 68) | 35% `heart_epic_hands` (Lv 68) | 27% `subject_grips` (Lv 35) | 80% `sovereign_grips` (Lv 70) |
| feet | 20% `used_heart_uncommon_feet` (Lv 68) | 24% `heart_uncommon_feet` (Lv 68) | 27% `heart_rare_feet` (Lv 68) | 30% `heart_epic_feet` (Lv 68) | none | 58% `sovereign_treads` (Lv 70) |
| charm | 24% `used_heart_uncommon_charm` (Lv 68) | 29% `heart_uncommon_charm` (Lv 68) | 34% `heart_rare_charm` (Lv 68) | 40% `heart_epic_charm` (Lv 68) | 41% `heart_of_iron_city` (Lv 48) | 91% `sovereign_seal` (Lv 70) |

In every slot except charm, the best Epic beats the best Legendary.

- Head: the best Rare equals the best Legendary (35% each).
- Hands and body: the best Rare beats it.
- Weapon: `arthit_baton` (57%) stays just ahead of the best Rare (54%).
- Charm: `heart_of_iron_city` is the only Legendary ahead of every Epic of its slot
  (41% versus 40%).

### 4.3 Strict inversions

These are cases where a lower-grade item, at the same or a lower required level,
is worth at least as much as a higher-grade one in the same slot:

| Slot | Lower grade item | Grade, Lv | Stats | Value | ≥ | Higher grade item | Grade, Lv | Stats | Value |
|---|---|---|---|---:|---|---|---|---|---:|
| feet | `steel_toe_boots` | uncommon, 4 | defense 1, max_hp 14, speed -0.02 | 17% | ≥ | `chais_deck_shoes` | rare, 15 | speed 0.13, defense 3 | 12% |
| feet | `used_steel_toe_boots` | common, 4 | defense 1, max_hp 12, speed -0.02 | 15% | ≥ | `chais_deck_shoes` | rare, 15 | speed 0.13, defense 3 | 12% |
| feet | `used_steel_toe_boots` | common, 4 | defense 1, max_hp 12, speed -0.02 | 15% | ≥ | `deck_boots` | uncommon, 13 | speed 0.07, defense 1, max_hp 16 | 11% |
| feet | `steel_toe_boots` | uncommon, 4 | defense 1, max_hp 14, speed -0.02 | 17% | ≥ | `dockmaster_boots` | epic, 15 | speed 0.1, defense 2, max_hp 20 | 16% |
| feet | `used_steel_toe_boots` | common, 4 | defense 1, max_hp 12, speed -0.02 | 15% | ≥ | `facility_boots` | uncommon, 35 | speed 0.17, defense 3, attack_speed 0.08 | 15% |
| feet | `used_steel_toe_boots` | common, 4 | defense 1, max_hp 12, speed -0.02 | 15% | ≥ | `lab_boots` | uncommon, 21 | speed 0.11, defense 2, attack_speed 0.05 | 12% |
| feet | `used_steel_toe_boots` | common, 4 | defense 1, max_hp 12, speed -0.02 | 15% | ≥ | `runner_sneakers` | uncommon, 27 | speed 0.16, defense 2, attack_speed 0.06 | 12% |
| feet | `used_steel_toe_boots` | common, 4 | defense 1, max_hp 12, speed -0.02 | 15% | ≥ | `street_runners` | uncommon, 6 | speed 0.04, defense 1, attack_speed 0.02 | 8% |
| feet | `used_street_runners` | common, 6 | speed 0.03, defense 1, attack_speed 0.02 | 8% | ≥ | `street_runners` | uncommon, 6 | speed 0.04, defense 1, attack_speed 0.02 | 8% |
| hands | `iron_wraps` | rare, 5 | power 0.06, defense 1, crit 0.02 | 13% | ≥ | `champion_wraps` | epic, 7 | power 0.09, crit 0.04, attack_speed 0.03 | 12% |
| head | `iron_helm` | uncommon, 7 | defense 2, max_hp 13 | 20% | ≥ | `champion_headband` | epic, 7 | max_hp 30, crit 0.04 | 19% |

11 inversions. Most involve `used_steel_toe_boots` and `steel_toe_boots`: their
flat defense is worth a lot at Lv 4, where the reference hit is about 17.
`iron_helm` against `champion_headband` (Lv 7) and `iron_wraps` against
`champion_wraps` (Lv 5–7) are genuine same-level inversions. The rest compare an
early item with a later one of a higher grade that is weaker *for its own level*.

## 5. Level progression analysis

**Early game (Lv 1–15):** all four common grades and 2 Legendaries
(`baron_knuckledusters` Lv 9 and `harbour_hook` Lv 15). Grade steps are the
widest here, because flat defense and small HP numbers matter most at low levels.
Feet show inversions (§4.3).

**Mid game (Lv 16–35):** 8 Legendaries (stage bosses Lv 23–35, plus the catalog
`crimson_warlord_*` set and `lion_king_crown` at Lv 30) and the first 2
Godforged (`mothers_fang` and `mothers_heart`, Lv 30, from the Tunnel Mother).
No Rare weapon exists in this band.

**Late game (Lv 36–55):** 4 Legendaries, the last at Lv 48. 4 Godforged
(Lv 45–55).

**Endgame (Lv 56–70):** **no Legendary at all.** 18 items each of Common to Epic
(the three-district `*_heart_*` / `*_foundry_*` sets) and 19 Godforged.

**Findings:**

- **Legendary does not justify itself past Lv 48.** A Lv 50+ player's upgrade path
  goes Epic → Godforged directly. Every Legendary is overtaken by same-slot Epic
  items from Lv 53 onwards (§8).
- **No Legendary feet exist.** No Legendary body or hands item exists past Lv 35
  (`subject_grips`, Lv 35, is the only Legendary hands item; the only Legendary
  body item is the catalog `crimson_warlord_mantle`, Lv 30).
- **Godforged starts at Lv 30** through the non-raid world bosses (see
  `docs/GODFORGED_IMPACT_REPORT.md`). At its own level, a Lv 30 Godforged is
  1.4 × the Legendary of that band (weapon 82% versus 58%).
- **Lower grades are not too strong late.** At Lv 56–70 the grade order is clean
  (index 50 / 59 / 69 / 84 / – / 198 for weapons). The problem is the spacing, not
  the order.
- **Gaps:** charms below Lv 36 have no Common (noted in `arena.json`). Mid-band
  Rare weapons do not exist.

**Recommended grade × level matrix** (where each grade should be available;
**bold** marks cells with no item today):

| Band | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---|---|---|---|---|---|
| Lv 1–15 | shops, monsters | monsters | elites, early bosses | stage bosses | first stage bosses (exists) | — |
| Lv 16–35 | shops, monsters | monsters | elites (**no weapon**) | stage bosses | stage bosses (exists) | world boss Lv 30+ (exists) |
| Lv 36–55 | monsters | monsters | elites | stage bosses | stage bosses to Lv 48 (**none Lv 49–55**) | world bosses |
| Lv 56–70 | monsters | monsters | elites | district bosses | **none: needs new items** | world and raid bosses |

## 6. Enhancement +0 to +10

### 6.1 The rule

`bonus_at` adds 10% of each positive base stat per level, the same for every
grade, slot and stat:

- +1 is ×1.1, +3 ×1.3, +5 ×1.5, +7 ×1.7 and +10 ×2.0.
- The ratio between two items is the same at every enhancement level, so
  enhancement **cannot create a grade inversion that does not already exist at +0**.
- It doubles every absolute gap: a grade gap of 20% at +0 is 40 points at +10.

### 6.2 Worked examples, valued for a Lv 70 hero


**Weapon** (value against a Lv 70 hero; the Legendary is the best one that exists for the slot)

| Item | Grade | Lv | +0 stats | +0 | +1 | +3 | +5 | +7 | +10 | +10 stats |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| `heart_uncommon_weapon` | uncommon | 68 | power 1.57, crit 0.16 | 46% | 51% | 61% | 71% | 82% | 98% | power 3.14, crit 0.32 |
| `heart_rare_weapon` | rare | 68 | power 1.77, crit 0.2 | 54% | 60% | 71% | 84% | 96% | 115% | power 3.54, crit 0.4 |
| `heart_epic_weapon` | epic | 68 | power 1.94, defense 2, crit 0.25 | 65% | 73% | 88% | 104% | 120% | 141% | power 3.88, defense 4, crit 0.5 |
| `arthit_baton` | legendary | 39 | power 1.35, crit 0.15, attack_speed 0.12 | 57% | 63% | 77% | 91% | 106% | 129% | power 2.7, crit 0.3, attack_speed 0.24 |
| `sovereign_fists` | godforged | 70 | power 3.16, crit 0.35, attack_speed 0.28 | 157% | 178% | 221% | 259% | 299% | 363% | power 6.32, crit 0.7, attack_speed 0.56 |

**Body** (value against a Lv 70 hero; the Legendary is the best one that exists for the slot)

| Item | Grade | Lv | +0 stats | +0 | +1 | +3 | +5 | +7 | +10 | +10 stats |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| `heart_uncommon_body` | uncommon | 68 | defense 14, max_hp 130 | 39% | 44% | 54% | 65% | 77% | 98% | defense 28, max_hp 260 |
| `heart_rare_body` | rare | 68 | defense 17, max_hp 136 | 46% | 52% | 65% | 79% | 95% | 123% | defense 34, max_hp 272 |
| `heart_epic_body` | epic | 68 | defense 19, max_hp 171 | 56% | 64% | 80% | 99% | 120% | 158% | defense 38, max_hp 342 |
| `crimson_warlord_mantle` | legendary | 30 | max_hp 113, defense 9 | 28% | 31% | 37% | 44% | 51% | 63% | max_hp 226, defense 18 |
| `sovereign_mantle` | godforged | 70 | defense 32, max_hp 292 | 119% | 139% | 189% | 256% | 351% | 604% | defense 64, max_hp 584 |

**Head** (value against a Lv 70 hero; the Legendary is the best one that exists for the slot)

| Item | Grade | Lv | +0 stats | +0 | +1 | +3 | +5 | +7 | +10 | +10 stats |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| `heart_uncommon_head` | uncommon | 68 | defense 9, max_hp 118 | 28% | 31% | 38% | 45% | 52% | 64% | defense 18, max_hp 236 |
| `heart_rare_head` | rare | 68 | defense 11, max_hp 106, crit 0.08 | 35% | 39% | 48% | 58% | 68% | 84% | defense 22, max_hp 212, crit 0.16 |
| `heart_epic_head` | epic | 68 | defense 11, max_hp 148, crit 0.07 | 41% | 46% | 56% | 67% | 78% | 98% | defense 22, max_hp 296, crit 0.14 |
| `director_crown` | legendary | 48 | defense 9, max_hp 115, crit 0.11 | 35% | 39% | 47% | 56% | 66% | 81% | defense 18, max_hp 230, crit 0.22 |
| `sovereign_crown` | godforged | 70 | defense 17, max_hp 223, crit 0.21 | 77% | 87% | 109% | 134% | 163% | 214% | defense 34, max_hp 446, crit 0.42 |

**Charm** (value against a Lv 70 hero; the Legendary is the best one that exists for the slot)

| Item | Grade | Lv | +0 stats | +0 | +1 | +3 | +5 | +7 | +10 | +10 stats |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| `heart_uncommon_charm` | uncommon | 68 | max_hp 115, power 0.23, crit 0.15 | 29% | 32% | 39% | 46% | 52% | 63% | max_hp 230, power 0.46, crit 0.3 |
| `heart_rare_charm` | rare | 68 | max_hp 132, power 0.26, crit 0.17 | 34% | 37% | 45% | 53% | 61% | 74% | max_hp 264, power 0.52, crit 0.34 |
| `heart_epic_charm` | epic | 68 | max_hp 182, defense 5, crit 0.15 | 40% | 45% | 54% | 63% | 73% | 89% | max_hp 364, defense 10, crit 0.3 |
| `heart_of_iron_city` | legendary | 48 | max_hp 140, power 0.24, crit 0.09, attack_speed 0.09 | 41% | 46% | 55% | 65% | 76% | 92% | max_hp 280, power 0.48, crit 0.18, attack_speed 0.18 |
| `sovereign_seal` | godforged | 70 | max_hp 276, power 0.47, crit 0.18, attack_speed 0.18 | 91% | 102% | 127% | 153% | 181% | 228% | max_hp 552, power 0.94, crit 0.36, attack_speed 0.36 |

What this shows:

- **Rare +10 against Legendary +0.**
  - `heart_rare_weapon` +10 (115%) is twice `arthit_baton` +0 (57%), the best
    Legendary weapon.
  - `heart_rare_weapon` +0 (54%) is already within 3 points of it.
  - Under today's spacing a Rare passes the best Legendary at about **+1**.
  - Under Model B (§12), with Legendary at 1.7 × Rare in the same band, a Rare
    would need about +7 to match Legendary +0.
  - Under the reference curve (2.1 ×), it would need +10 or more.
- **Legendary +10 against Rare +10:** the same ratio as at +0 (§6.1). Legendary
  +10 is meaningfully better only if Legendary +0 is.
- **Grade inversions from enhancement:** none of its own (§6.1). The existing +0
  inversions double in size.
- **Categories:** all slots scale by the same factor, so enhancement favours none.
  In *value*, though, items heavy in defense or crit gain differently, because of
  the flat defense and the caps (§6.3).

### 6.3 Caps and flat defense at high enhancement (verified from the formulas)

- **Crit cap 50% total.**
  - Full Lv 68 sets at +0 carry crit 0.43 (Uncommon), 0.58 (Rare) and 0.67 (Epic).
  - With a hero base of 0.05–0.08, an endgame Uncommon set already reaches the
    cap, and Rare and Epic sets waste 0.11–0.25 of crit.
  - The Sovereign set carries 1.02 at +0 and 2.04 at +10.
  - So at the endgame, **crit on Rare and higher gear and on every enhancement level
    is dead value**. Item cards still show it.
- **Attack-speed cap 1.3.** The Sovereign set gives +0.98 at +0 (+1.96 at +10);
  only +0.3 counts.
- **Movement speed has no upper cap.** The Sovereign set gives +0.64 at +0 and
  +1.28 at +10, so the hero moves at 1.6–2.3 ×. That is a positioning advantage
  in PvP, not a stat issue at +0.
- **Flat defense in PvE.**
  - The reference monster hit at Lv 70 is 85.
  - The Sovereign set's defense is 70 at +0, 119 at +7 and 140 at +10, so an
    average monster blow drops to 15 at +0 and to the 1-damage floor at +7.
  - The Epic Lv 68 set (51 → 102 at +10) does the same at +10.
  - Boss blows are larger (`wiroj_palm` 26 base × boss power), so bosses still
    hurt. Ordinary monster damage, though, stops mattering for heavily enhanced
    endgame gear.
  - This comes from flat defense combined with enhancement, not from grades. Any
    grade change that raises defense makes it come sooner (§9, §14).

## 7. Special effects and actual combat value

- **Item stats that exist:** `max_hp`, `power`, `defense`, `crit`,
  `attack_speed` and `speed`. That is the whole list (`PlayerProfile.STAT_KEYS`).
- **No item has** accuracy, evasion, damage reduction %, recovery, lifesteal,
  set bonuses, on-hit effects or weapon-type rules. None of these exists in the
  game.
  - Damage reduction % and other modifiers exist only as **skill passives**
    (`PassiveRules`: damage, crit, attack_speed, resist, hold, parry_window).
    These come from jobs and skills, not equipment.
- **Weapon type:** the `weapon` slot has no subtype field. A weapon's identity is
  its stat mix (power, crit, and sometimes attack_speed or HP).
  - Weapons picked up in the street (pipes, knives) are area props with uses, not
    items.
- **Non-stat item fields:**
  - `look: "armoured"` on `work_jacket` and `riveted_jacket` is cosmetic.
  - `unique: true` on `heart_of_iron_city` limits copies, not power.
  - Catalog `appearance` is cosmetic.
  - Three items carry a `speed` penalty: `rebar_pipe` −0.06, `steel_toe_boots`
    −0.02 and `used_steel_toe_boots` −0.02. Enhancement never amplifies it.
- **Items worth more or less than their raw stats suggest:**
  - **Crit-heavy endgame items are worth less than shown**, because of the cap
    (§6.3).
  - **Attack-speed items stack into a cap of +0.3.** `sovereign_treads` alone
    (+0.34) exceeds it.
  - **Flat-defense items are worth more early** (§4.3), and much more on
    enhanced endgame sets (§6.3).

## 8. Legendary versus Rare (the reported problem)

| Legendary | Slot | Lv | Stats | Value at own Lv | Value at Lv 70 | Best Rare at Lv 70 (id, Lv, value) | Best Epic at Lv 70 (id, Lv, value) | Same-band Rare median | Same-band Epic median | Legendary ÷ band Epic |
|---|---|---:|---|---:|---:|---|---|---:|---:|---:|
| `baron_knuckledusters` | weapon | 9 | power 0.36, max_hp 16, crit 0.07 | 41% | 14% | `heart_rare_weapon` Lv 68, 54% | `heart_epic_weapon` Lv 68, 65% | 32% | 33% | 1.23× |
| `harbour_hook` | weapon | 15 | power 0.55, max_hp 25, crit 0.08 | 51% | 20% | `heart_rare_weapon` Lv 68, 54% | `heart_epic_weapon` Lv 68, 65% | 32% | 33% | 1.54× |
| `k7_core_plate` | charm | 23 | max_hp 65, power 0.15, attack_speed 0.13 | 45% | 26% | `heart_rare_charm` Lv 68, 34% | `heart_epic_charm` Lv 68, 40% | 25% | 35% | 1.26× |
| `ringmaster_topper` | head | 27 | defense 5, max_hp 70, crit 0.07 | 40% | 20% | `heart_rare_head` Lv 68, 35% | `heart_epic_head` Lv 68, 41% | 30% | 38% | 1.06× |
| `crimson_warlord_fists` | weapon | 30 | power 1.16, crit 0.146 | 58% | 35% | `heart_rare_weapon` Lv 68, 54% | `heart_epic_weapon` Lv 68, 65% | none | 44% | 1.31× |
| `crimson_warlord_helm` | head | 30 | defense 10, max_hp 64 | 51% | 22% | `heart_rare_head` Lv 68, 35% | `heart_epic_head` Lv 68, 41% | 30% | 38% | 1.34× |
| `crimson_warlord_mantle` | body | 30 | max_hp 113, defense 9 | 62% | 28% | `heart_rare_body` Lv 68, 46% | `heart_epic_body` Lv 68, 56% | 43% | 49% | 1.25× |
| `lion_king_crown` | head | 30 | defense 10, max_hp 64 | 51% | 22% | `heart_rare_head` Lv 68, 35% | `heart_epic_head` Lv 68, 41% | 30% | 38% | 1.34× |
| `sak_signet` | charm | 31 | max_hp 90, power 0.19, crit 0.11 | 38% | 22% | `heart_rare_charm` Lv 68, 34% | `heart_epic_charm` Lv 68, 40% | 25% | 35% | 1.08× |
| `subject_grips` | hands | 35 | power 0.37, defense 3, crit 0.11, attack_speed 0.07 | 37% | 27% | `heart_rare_hands` Lv 68, 28% | `heart_epic_hands` Lv 68, 35% | 20% | 22% | 1.67× |
| `arthit_baton` | weapon | 39 | power 1.35, crit 0.15, attack_speed 0.12 | 76% | 57% | `heart_rare_weapon` Lv 68, 54% | `heart_epic_weapon` Lv 68, 65% | 47% | 62% | 1.23× |
| `director_crown` | head | 48 | defense 9, max_hp 115, crit 0.11 | 48% | 35% | `heart_rare_head` Lv 68, 35% | `heart_epic_head` Lv 68, 41% | 33% | 40% | 1.20× |
| `director_signet` | charm | 48 | max_hp 155, power 0.24, crit 0.13 | 44% | 34% | `heart_rare_charm` Lv 68, 34% | `heart_epic_charm` Lv 68, 40% | 31% | 38% | 1.15× |
| `heart_of_iron_city` | charm | 48 | max_hp 140, power 0.24, crit 0.09, attack_speed 0.09 | 51% | 41% | `heart_rare_charm` Lv 68, 34% | `heart_epic_charm` Lv 68, 40% | 31% | 38% | 1.33× |

Verified:

- **Against same-band Epics:**
  - Every Legendary is better than the median Epic *of its own level band*, by
    1.06× to 1.67×.
  - `ringmaster_topper` (Lv 27, 1.06× the band Epic) and `sak_signet` (Lv 31)
    are the weakest.
- **Against Rare and Epic at the endgame:**
  - At Lv 70, every Legendary except `heart_of_iron_city` is beaten by a Lv 68
    Epic of its slot.
  - The best Legendary head and hands items are matched by Lv 68 Rares (35%
    against 35%, and 27% against 28%).
  - The single Legendary body item, `crimson_warlord_mantle` (Lv 30; 28% at Lv 70),
    is beaten by every Lv 53+ Uncommon body (30–39%).
  - Legendary was made as story-boss loot for Lv 9–48, so a Lv 70 player
    comparing it with Lv 68 drops sees Legendary ≈ Rare.

## 9. Godforged versus Legendary

- **Base stats:**
  - At its own band, Godforged is 1.4× Legendary (mid weapon 82% versus 58%), 1.66×
    (late weapon 126% versus 76%) and 1.7× (late charm 82% versus a 48% median).
  - Against the best Legendary as a Lv 70 hero sees it: weapon 157% versus 57%,
    head 77% versus 35%, body 119% versus 28%.
- **Enhancement:** identical rule (§6), so the ratio holds from +0 to +10.
- **Special effects:** none on either grade.
- **Slot coverage:** Godforged covers all six slots, but feet only through
  `sovereign_treads` and one raid item. Legendary has no feet.
- **Endgame:** Godforged is the only top grade above Lv 48, and the raid twins
  (`founders_*` = `sovereign_*`) have identical stats.
- **Verdict:** Godforged is clearly ahead of Legendary. The gap is too large,
  because Legendary is too low, not because Godforged is too high.
- **Rewards untouched:**
  - All eight world boss reward rules and the three raid labels are unchanged.
  - Source changes are in `docs/GODFORGED_IMPACT_REPORT.md` and wait for approval.

## 10. PvE balance impact

- **Today:** gear is the hero's main lever beyond level. `LevelRules` assumes
  "gear and enhancing keep the hero ahead" of enemies that gain 8% power and 6% HP
  per level.
- **Model B:**
  - Per item, the median value has to rise ×1.19 for Rare, ×1.29 for Epic and
    ×1.28 for Legendary.
  - Common, Uncommon and Godforged medians stay roughly where they are (×1.00,
    ×1.07 and ×1.05).
  - At the endgame, Rare and Epic farming of normal and elite monsters becomes a
    little faster, and survivability rises.
  - Stage and mini-bosses (Lv 9–50) fall faster for players wearing that boss's
    Legendary. That is the point of the prize.
  - World and raid bosses: no Godforged change under Model B, so no impact on their
    tuning.
- **Model A:**
  - Per item, the median value has to rise ×1.32 for Uncommon, ×1.69 for Rare,
    ×2.0 for Epic, ×2.2 for Legendary and ×1.94 for Godforged.
  - Normal monsters at Lv 50+ would lose most of their threat (§6.3: flat defense
    reaches the reference hit sooner).
  - Stage bosses would need retuning.
  - The progression harness (`docs/HARNESS.md`) would have to re-measure
    time-to-kill and deaths for every band.
- **Farming efficiency:** faster kills mean more drops per hour. The drop
  database's per-kill rates are unchanged, but per-hour yield would rise in
  proportion to kill speed.

## 11. PvP balance impact

- **Arena gear** (`arena.json` tiers):
  - t1–t2: Common and Uncommon.
  - t3: Uncommon and Rare.
  - t4: Epic.
  - t5: Epic, Legendary and Godforged, Lv 44–70.
  - t6–t9: Godforged +1 to +7 at Lv 70.
  - `ArenaLoadout.best_item` picks the best item at or under the rival's level, so
    **any stat change changes the rivals automatically**.
- **Defense share:**
  - Epic Lv 68 set: 51 (36% taken off each blow).
  - Sovereign +0: 70 (44%).
  - Sovereign +7: 119 (57%).
  - Sovereign +10: 140 (61%).
  - Under Model A, an Epic set's defense would come close to Sovereign +0, which
    blurs tiers t4 and t5.
- **Stat gaps:**
  - At t9 (Godforged +7), power is +7.8 over the hero base and HP +1,345 (×2 in
    the arena).
  - Raising Epic and Legendary narrows the t4/t5 gap. That is fair if t5 rivals
    are rebuilt from the new data, and they are automatically.
- **Class balance:** `test_arena_integrity` and the class-balance tests measure
  win rates with real loadouts. Any stat change must keep them green.
- **Recommendation:** apply grade changes to PvE first and let the arena read them
  through `best_item`. Re-run the arena integrity tests and the seeded duel
  harness before shipping. Do not raise Godforged.

## 12. Recommended grade power target model

**Principle.** Grade sets the stat budget, as a multiple of a Common of the same
slot and level. Level sets the scale, through the existing level curve. The two
stay separate, so a Lv 30 Legendary and a Lv 68 Legendary are each 1.45 × the
Epic of their own level.

| Grade | Reference (Model A) | Recommended (Model B) | Step | Today (median of bands) |
|---|---:|---:|---:|---:|
| Common | 50 | 50 | – | 50 |
| Uncommon | 80 | 65 | +30% | 60 |
| Rare | 120 | 85 | +31% | 70 |
| Epic | 170 | 110 | +29% | 85 |
| Legendary | 250 | 145 | +32% | 100–137 |
| Godforged | 350 | 190 | +31% | 136–198 (kept) |

**Why Model B:**

- It keeps today's Godforged, so no world boss, raid or arena t6–t9 change is
  needed.
- It gives every step the same feel, about +30%.
- It moves Common and Uncommon little (early-game balance and shops).
- The largest change goes to Epic and Legendary, which is where the reported
  problem sits.

**Model A** (the 50/80/120/170/250/350 reference) is shown in brackets in the
tables below. It would also require raising Godforged by about 1.8 ×, which
§9–§11 advise against.

**Rules of the model:**

- **Variation within a grade:** ±15% of the target value. Wider only for a stated
  specialization, which is recorded as a `role` note in the data if approved.
- **Specialization:** the *value* (§2.3) meets the target; the stat *mix* may
  differ. A defensive Legendary may carry less power than an offensive Rare when
  its defense value makes up for it (as `heart_epic_charm` trades power for
  defense today).
- **Caps:** crit and attack speed above what a full set can use (§6.3) do not
  count towards the budget. Move the budget into power, HP or defense.
- **Godforged versus Legendary:** about 1.3× at the same level, plus slot
  coverage at Lv 56–70, where it is today the only top grade. No new mechanics.

### 12.1 Target value tables per slot

Each cell gives the Model B target, the Model A target in brackets, and today's
median value of that grade in the same band. Values are the share of combat
strength added to a bare hero of the item's level (§2.3).


### Weapon: target value by grade (Model B, recommended; Model A in brackets)

| Level band | Common median today | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---|---|---|---|---|---|
| early 1-15 | 17% | 17% [17%]; now 17% | 22% [27%]; now 25% | 28% [40%]; now 32% | 37% [57%]; now 33% | 49% [84%]; now 46% | 64% [117%]; none today |
| mid 16-35 | 29% | 29% [29%]; now 29% | 38% [47%]; now 35% | 50% [70%]; none today | 64% [99%]; now 44% | 85% [146%]; now 58% | 111% [204%]; now 82% |
| late 36-55 | 35% | 35% [35%]; now 35% | 46% [57%]; now 42% | 60% [85%]; now 47% | 78% [121%]; now 62% | 103% [177%]; now 76% | 135% [248%]; now 126% |
| end 56-70 | 39% | 39% [39%]; now 39% | 50% [62%]; now 46% | 66% [93%]; now 54% | 85% [132%]; now 65% | 112% [194%]; none today | 147% [271%]; now 153% |

### Head: target value by grade (Model B, recommended; Model A in brackets)

| Level band | Common median today | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---|---|---|---|---|---|
| early 1-15 | 15% | 15% [15%]; now 15% | 20% [25%]; now 22% | 26% [37%]; now 29% | 34% [52%]; now 25% | 45% [77%]; none today | 59% [108%]; none today |
| mid 16-35 | 22% | 22% [22%]; now 22% | 29% [36%]; now 27% | 38% [54%]; now 30% | 49% [76%]; now 38% | 65% [111%]; now 51% | 85% [156%]; none today |
| late 36-55 | 24% | 24% [24%]; now 24% | 31% [38%]; now 29% | 40% [57%]; now 33% | 52% [80%]; now 40% | 68% [118%]; now 48% | 90% [165%]; none today |
| end 56-70 | 25% | 25% [25%]; now 25% | 32% [40%]; now 29% | 42% [60%]; now 35% | 55% [85%]; now 42% | 72% [125%]; none today | 95% [175%]; now 77% |

### Body: target value by grade (Model B, recommended; Model A in brackets)

| Level band | Common median today | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---|---|---|---|---|---|
| early 1-15 | 22% | 22% [22%]; now 22% | 29% [35%]; now 26% | 38% [53%]; now 37% | 49% [75%]; now 40% | 64% [111%]; none today | 84% [155%]; none today |
| mid 16-35 | 29% | 29% [29%]; now 29% | 38% [47%]; now 36% | 50% [70%]; now 43% | 64% [99%]; now 49% | 85% [146%]; now 62% | 111% [204%]; none today |
| late 36-55 | 32% | 32% [32%]; now 32% | 42% [51%]; now 39% | 54% [77%]; now 48% | 70% [109%]; now 56% | 93% [160%]; none today | 122% [224%]; now 109% |
| end 56-70 | 33% | 33% [33%]; now 33% | 43% [53%]; now 40% | 56% [79%]; now 48% | 72% [112%]; now 58% | 95% [164%]; none today | 125% [230%]; now 119% |

### Hands: target value by grade (Model B, recommended; Model A in brackets)

| Level band | Common median today | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---|---|---|---|---|---|
| early 1-15 | 10% | 10% [10%]; now 10% | 13% [16%]; now 17% | 17% [24%]; now 12% | 22% [33%]; now 12% | 28% [49%]; none today | 37% [69%]; none today |
| mid 16-35 | 15% | 15% [15%]; now 15% | 19% [24%]; now 17% | 25% [35%]; now 20% | 32% [50%]; now 22% | 43% [74%]; now 37% | 56% [103%]; none today |
| late 36-55 | 19% | 19% [19%]; now 19% | 24% [30%]; now 21% | 32% [45%]; now 25% | 41% [63%]; now 30% | 54% [93%]; none today | 71% [130%]; now 51% |
| end 56-70 | 19% | 19% [19%]; now 19% | 25% [31%]; now 24% | 33% [46%]; now 28% | 42% [66%]; now 33% | 56% [97%]; none today | 73% [135%]; now 76% |

### Feet: target value by grade (Model B, recommended; Model A in brackets)

| Level band | Common median today | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---|---|---|---|---|---|
| early 1-15 | 9% | 9% [9%]; now 9% | 12% [14%]; now 11% | 15% [21%]; now 12% | 20% [30%]; now 14% | 26% [44%]; none today | 34% [62%]; none today |
| mid 16-35 | 11% | 11% [11%]; now 11% | 14% [17%]; now 12% | 18% [25%]; now 18% | 23% [36%]; now 20% | 31% [53%]; none today | 40% [74%]; none today |
| late 36-55 | 15% | 15% [15%]; now 15% | 20% [25%]; now 20% | 26% [37%]; now 23% | 34% [53%]; now 25% | 45% [77%]; none today | 59% [108%]; none today |
| end 56-70 | 20% | 20% [20%]; now 20% | 26% [32%]; now 24% | 34% [47%]; now 25% | 43% [67%]; now 30% | 57% [99%]; none today | 75% [138%]; now 55% |

### Charm: target value by grade (Model B, recommended; Model A in brackets)

| Level band | Common median today | Common | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---|---|---|---|---|---|
| early 1-15 | 7% (derived) | 7% [7%]; none today | 9% [11%]; now 9% | 12% [17%]; now 17% | 16% [24%]; now 25% | 21% [36%]; none today | 27% [50%]; none today |
| mid 16-35 | 15% (derived) | 15% [15%]; none today | 19% [23%]; none today | 25% [35%]; now 25% | 32% [50%]; now 35% | 43% [73%]; now 41% | 56% [103%]; now 69% |
| late 36-55 | 23% | 23% [23%]; now 23% | 29% [36%]; now 27% | 38% [54%]; now 31% | 50% [77%]; now 38% | 66% [113%]; now 48% | 86% [158%]; now 82% |
| end 56-70 | 24% | 24% [24%]; now 24% | 32% [39%]; now 29% | 41% [58%]; now 34% | 54% [83%]; now 41% | 71% [122%]; none today | 93% [170%]; now 88% |

Charms below Lv 36 have no Common, so their anchor is derived from the
Uncommon (or Rare) median. That is marked "(derived)".

## 13. Prioritized balance corrections (proposals; none applied)

### Critical

- **C1. Legendary has no items at Lv 49–70 and none for feet.**
  - Problem: at the endgame, every Legendary is matched by a Rare and beaten by an
    Epic (§8). That breaks the grade order players see.
  - Fix: add Legendary items for Lv 50–70 in all six slots (new IDs, stage or
    district boss prizes), valued at the Model B target. Keep the existing 14 as
    they are, as the story-boss Legendaries of their own level.
  - Impact: a clear Epic → Legendary → Godforged path.
  - Risk: new content, sources and drop-database entries. It needs the source
    decisions in `docs/GODFORGED_IMPACT_REPORT.md` to stay unchanged.

### High

- **H1. Legendary below the Model B target in its own band.**
  - These are below the target by more than 15% (value now against the target,
    and the ratio):
    - `ringmaster_topper`: 40% against 65% (0.62).
    - `director_signet`: 44% against 66% (0.68).
    - `crimson_warlord_fists`: 58% against 85% (0.69).
    - `director_crown`: 48% against 68% (0.70).
    - `crimson_warlord_mantle`: 62% against 85% (0.73).
    - `arthit_baton`: 76% against 103% (0.74).
    - `crimson_warlord_helm` and `lion_king_crown`: 51% against 65% (0.78).
    - `heart_of_iron_city`: 51% against 66% (0.78).
    - `baron_knuckledusters`: 41% against 49% (0.84).
  - Within 15%: `subject_grips` (0.86), `sak_signet` (0.90), `harbour_hook` (1.05)
    and `k7_core_plate` (1.05).
  - Fix: raise the 10 to their band target. For example,
    `ringmaster_topper` defense 5 → 7 and max_hp 70 → 118 reaches 65%.
  - Risk: those bosses' prizes get stronger. The stage-boss Legendaries are 6%
    pity drops, so few players hold them early. The four catalog Legendaries are
    boss-only catalog drops.
- **H2. Epic only 1.5–2.0× Common** (index 76–99 against a 110 target; 47 of
  51 Epics are more than 15% below it).
  - Fix: raise Epic to the target (median value ×1.29). For example,
    `heart_epic_weapon` power 1.94 → about 2.65 reaches the 85% target.
  - Risk: 51 items, including the arena t4 tier, and the enemy curve at Lv 50+.
    Harness re-measurement is required.
- **H3. Rare at index 63–96 against 85.**
  - Rare is mostly on target in the early game but low later.
  - Fix: raise the Rares to the target (median value ×1.19; 30 of 46 Rares are
    more than 15% below it).

### Medium

- **M1. 11 strict inversions** (§4.3). `iron_helm` against `champion_headband`,
  `iron_wraps` against `champion_wraps`, and the early steel-toe boots.
  - Fix: raise the higher-grade item (preferred) or lower the lower-grade one.
- **M2. Crit past the cap** (§6.3).
  - Problem: endgame Rare and Epic sets waste 0.11–0.25 crit, and the Sovereign
    set wastes 0.5 or more.
  - Fix: either move part of the endgame crit budget into power, HP or defense, or
    show "capped" on the stat sheet.
  - Risk: low for the stat sheet; medium for stats.
- **M3. Flat defense against enhancement** (§6.3).
  - Problem: endgame defense passes the average monster hit at +7.
  - Fix: not a grade change. Flag it for a separate decision (for example a
    damage floor as a share of the hit in PvE). This report changes nothing.
- **M4. The Epic Lv 68 set's total power (2.56) is below the Rare set's (2.66).**
  This is because `heart_epic_charm` trades power for defense. It is a
  specialization, not a bug, but it should be documented.

### Low

- **L1. Identical stat lines.**
  - The 24 catalog hats share five stat lines, one per grade.
  - The raid twins `founders_*` are identical to `sovereign_*`.
  - This is acceptable (hats are cosmetic placeholders; twins by design), but the
    data could note it.
- **L2. No Common charm below Lv 53**, and no mid-band Rare weapon. These are
  content gaps.
- **L3. Legendary `price` is 0 for all 11 legacy Legendaries**, so they cannot be
  sold. This looks deliberate; confirm it.
- **L4. Item cards show raw stats only.** An "item power" number built from §2.3
  could be added to cards (presentation only).

## 14. Risks and dependencies

- **Balance tests:**
  - `test_arena_integrity`, the class-balance and duel tests, the progression
    harness and the world boss tests all read item stats. Any stat change must
    re-run them, and must re-measure with seeds rather than guess
    (`client/tests/CLAUDE.md`).
- **Enemy tuning:**
  - `LevelRules` relies on gear keeping the hero ahead.
  - The per-item value rises are listed in §10.
  - The value metric is not used for whole sets: once set defense nears the
    reference hit, it grows without bound (§6.3). Set-level effects must be
    measured with the harness.
- **Arena:**
  - Rivals rebuild from data (`ArenaLoadout.best_item`), so they change
    automatically.
  - The rank tiers t4/t5 may need relabelling under Model A.
- **Economy:**
  - Shop prices and sell values (`ShopRules`, `EconomyRules`) are separate from
    stats. Raising stats without prices makes shop gear better value.
- **Saves:**
  - Stats are read from data at runtime, so no save migration is needed.
  - Enhancement levels stay per copy.
- **Generated docs:**
  - `docs/ITEM_DROP_DATABASE.md` and the Guide show item stats.
  - The drop-database test regenerates and compares the document, so a stat change
    must re-run `DropReportRun.gd`.
- **Catalog:** the 34 catalog equipment items follow their own grade table
  (`item_catalog.json`). Changing them is a separate data edit.

## 15. Items requiring the owner's approval

1. Model B or Model A, or neither (§12).
2. C1: new Legendary items for Lv 50–70 and feet. These are new IDs and new
   sources, and the sources need their own decision.
3. H1: raising the 10 under-target Legendaries listed (stats only, IDs kept).
4. H2 and H3: raising Epic and the late Rares (about 70 items).
5. M1: fixing the 11 inversions, and in which direction.
6. M2: moving endgame crit past the cap into other stats, or showing "capped" on
   the stat sheet only.
7. M3: whether to address flat defense against enhancement at all. This is outside
   the grade question.
8. Whether item cards should show a computed item power (L4).

Nothing above is applied.

## Appendix A: Complete equipment inventory (267 items)

Every equipment item can be enhanced from +0 to +10 (`EnhanceRules`; grade does
not matter). "+10 stats" doubles every positive stat. Values are at the item's
own level (§2.3).

| # | Item ID | Name | Source | Grade | Slot | Req Lv | Base stats (+0) | +10 stats (positive stats ×2.0) | Enhance | Off. value | Def. value | Total value (own Lv) |
|---:|---|---|---|---|---|---:|---|---|---|---:|---:|---:|
| 1 | `taped_knuckles` | Taped Knuckles | legacy | common | weapon | 1 | power 0.13 | power 0.26 | +0 to +10 | 13% | 0% | 13% |
| 2 | `wrapped_iron_knuckles` | Wrapped Iron Knuckles | catalog | common | weapon | 4 | power 0.2 | power 0.4 | +0 to +10 | 17% | 0% | 17% |
| 3 | `used_brass_knuckles` | Used Brass Knuckles | legacy | common | weapon | 6 | power 0.18, crit 0.03 | power 0.36, crit 0.06 | +0 to +10 | 16% | 0% | 16% |
| 4 | `used_dock_hook` | Used Dock Hook | legacy | common | weapon | 13 | power 0.31, crit 0.04 | power 0.62, crit 0.08 | +0 to +10 | 22% | 0% | 22% |
| 5 | `used_shock_baton` | Used Shock Baton | legacy | common | weapon | 21 | power 0.46, crit 0.06 | power 0.92, crit 0.12 | +0 to +10 | 27% | 0% | 27% |
| 6 | `used_weighted_knuckles` | Used Weighted Knuckles | legacy | common | weapon | 27 | power 0.57, crit 0.07 | power 1.14, crit 0.14 | +0 to +10 | 29% | 0% | 29% |
| 7 | `used_riot_baton` | Used Riot Baton | legacy | common | weapon | 35 | power 0.71, crit 0.09 | power 1.42, crit 0.18 | +0 to +10 | 32% | 0% | 32% |
| 8 | `used_alloy_knuckles` | Used Alloy Knuckles | legacy | common | weapon | 44 | power 0.9, crit 0.09 | power 1.8, crit 0.18 | +0 to +10 | 34% | 0% | 34% |
| 9 | `used_coolant_uncommon_weapon` | Used Coolant Knuckles | legacy | common | weapon | 53 | power 1.06, crit 0.11 | power 2.12, crit 0.22 | +0 to +10 | 37% | 0% | 37% |
| 10 | `used_underworks_uncommon_weapon` | Used Underworks Knuckles | legacy | common | weapon | 58 | power 1.15, crit 0.12 | power 2.3, crit 0.24 | +0 to +10 | 38% | 0% | 38% |
| 11 | `used_foundry_uncommon_weapon` | Used Foundry Knuckles | legacy | common | weapon | 63 | power 1.24, crit 0.13 | power 2.48, crit 0.26 | +0 to +10 | 39% | 0% | 39% |
| 12 | `used_heart_uncommon_weapon` | Used Heartforged Knuckles | legacy | common | weapon | 68 | power 1.34, crit 0.14 | power 2.68, crit 0.28 | +0 to +10 | 40% | 0% | 40% |
| 13 | `rebar_pipe` | Rebar Pipe | legacy | uncommon | weapon | 4 | power 0.29, speed -0.06 | power 0.58, speed -0.06 | +0 to +10 | 25% | 0% | 25% |
| 14 | `brass_knuckles` | Brass Knuckles | legacy | uncommon | weapon | 6 | power 0.21, crit 0.04 | power 0.42, crit 0.08 | +0 to +10 | 19% | 0% | 19% |
| 15 | `copper_plated_knuckles` | Copper-Plated Knuckles | catalog | uncommon | weapon | 9 | power 0.36 | power 0.72 | +0 to +10 | 26% | 0% | 26% |
| 16 | `dock_hook` | Dock Hook | legacy | uncommon | weapon | 13 | power 0.37, crit 0.05 | power 0.74, crit 0.1 | +0 to +10 | 26% | 0% | 26% |
| 17 | `shock_baton` | Shock Baton | legacy | uncommon | weapon | 21 | power 0.54, crit 0.07 | power 1.08, crit 0.14 | +0 to +10 | 31% | 0% | 31% |
| 18 | `weighted_knuckles` | Weighted Knuckles | legacy | uncommon | weapon | 27 | power 0.68, crit 0.08 | power 1.36, crit 0.16 | +0 to +10 | 35% | 0% | 35% |
| 19 | `riot_baton` | Riot Baton | legacy | uncommon | weapon | 35 | power 0.84, crit 0.1 | power 1.68, crit 0.2 | +0 to +10 | 38% | 0% | 38% |
| 20 | `alloy_knuckles` | Alloy Knuckles | legacy | uncommon | weapon | 44 | power 1.06, crit 0.11 | power 2.12, crit 0.22 | +0 to +10 | 41% | 0% | 41% |
| 21 | `coolant_uncommon_weapon` | Coolant Knuckles | legacy | uncommon | weapon | 53 | power 1.25, crit 0.13 | power 2.5, crit 0.26 | +0 to +10 | 43% | 0% | 43% |
| 22 | `underworks_uncommon_weapon` | Underworks Knuckles | legacy | uncommon | weapon | 58 | power 1.36, crit 0.14 | power 2.72, crit 0.28 | +0 to +10 | 45% | 0% | 45% |
| 23 | `foundry_uncommon_weapon` | Foundry Knuckles | legacy | uncommon | weapon | 63 | power 1.46, crit 0.15 | power 2.92, crit 0.3 | +0 to +10 | 46% | 0% | 46% |
| 24 | `heart_uncommon_weapon` | Heartforged Knuckles | legacy | uncommon | weapon | 68 | power 1.57, crit 0.16 | power 3.14, crit 0.32 | +0 to +10 | 47% | 0% | 47% |
| 25 | `azure_steel_knuckles` | Azure Steel Knuckles | catalog | rare | weapon | 15 | power 0.48, crit 0.06 | power 0.96, crit 0.12 | +0 to +10 | 32% | 0% | 32% |
| 26 | `night_shift_crowbar` | Night Shift Crowbar | legacy | rare | weapon | 38 | power 1.04, crit 0.12 | power 2.08, crit 0.24 | +0 to +10 | 45% | 0% | 45% |
| 27 | `coolant_rare_weapon` | Vault Guard Knuckles | legacy | rare | weapon | 53 | power 1.41, crit 0.16 | power 2.82, crit 0.32 | +0 to +10 | 50% | 0% | 50% |
| 28 | `underworks_rare_weapon` | Reactor Crew Knuckles | legacy | rare | weapon | 58 | power 1.53, crit 0.18 | power 3.06, crit 0.36 | +0 to +10 | 52% | 0% | 52% |
| 29 | `foundry_rare_weapon` | Slagworker Knuckles | legacy | rare | weapon | 63 | power 1.65, crit 0.19 | power 3.3, crit 0.38 | +0 to +10 | 54% | 0% | 54% |
| 30 | `heart_rare_weapon` | Heart Sentry Knuckles | legacy | rare | weapon | 68 | power 1.77, crit 0.2 | power 3.54, crit 0.4 | +0 to +10 | 55% | 0% | 55% |
| 31 | `foreman_wrench` | Foreman's Wrench | legacy | epic | weapon | 5 | power 0.31, max_hp 9 | power 0.62, max_hp 18 | +0 to +10 | 26% | 6% | 33% |
| 32 | `chiefs_baton` | Chief's Baton | legacy | epic | weapon | 21 | power 0.68, defense 1, crit 0.09 | power 1.36, defense 2, crit 0.18 | +0 to +10 | 40% | 3% | 44% |
| 33 | `gilded_crusher_gauntlets` | Gilded Crusher Gauntlets | catalog | epic | weapon | 22 | power 0.76, crit 0.095 | power 1.52, crit 0.19 | +0 to +10 | 44% | 0% | 44% |
| 34 | `ringmaster_wraps` | Ringmaster's Wraps | legacy | epic | weapon | 27 | power 0.85, defense 1, crit 0.11 | power 1.7, defense 2, crit 0.22 | +0 to +10 | 44% | 3% | 48% |
| 35 | `coolant_epic_weapon` | Reinstated Knuckles | legacy | epic | weapon | 53 | power 1.55, defense 2, crit 0.2 | power 3.1, defense 4, crit 0.4 | +0 to +10 | 57% | 3% | 62% |
| 36 | `underworks_epic_weapon` | Relapsed Knuckles | legacy | epic | weapon | 58 | power 1.68, defense 2, crit 0.22 | power 3.36, defense 4, crit 0.44 | +0 to +10 | 59% | 3% | 64% |
| 37 | `foundry_epic_weapon` | Overdriven Knuckles | legacy | epic | weapon | 63 | power 1.81, defense 2, crit 0.23 | power 3.62, defense 4, crit 0.46 | +0 to +10 | 61% | 3% | 65% |
| 38 | `heart_epic_weapon` | Protocol Knuckles | legacy | epic | weapon | 68 | power 1.94, defense 2, crit 0.25 | power 3.88, defense 4, crit 0.5 | +0 to +10 | 63% | 2% | 67% |
| 39 | `baron_knuckledusters` | Baron's Knuckledusters | legacy | legendary | weapon | 9 | power 0.36, max_hp 16, crit 0.07 | power 0.72, max_hp 32, crit 0.14 | +0 to +10 | 30% | 8% | 41% |
| 40 | `harbour_hook` | Harbourmaster's Hook | legacy | legendary | weapon | 15 | power 0.55, max_hp 25, crit 0.08 | power 1.1, max_hp 50, crit 0.16 | +0 to +10 | 38% | 10% | 51% |
| 41 | `crimson_warlord_fists` | Crimson Warlord Fists | catalog | legendary | weapon | 30 | power 1.16, crit 0.146 | power 2.32, crit 0.292 | +0 to +10 | 58% | 0% | 58% |
| 42 | `arthit_baton` | Commander's Baton | legacy | legendary | weapon | 39 | power 1.35, crit 0.15, attack_speed 0.12 | power 2.7, crit 0.3, attack_speed 0.24 | +0 to +10 | 76% | 0% | 76% |
| 43 | `mothers_fang` | Mother's Fang | legacy | godforged | weapon | 30 | power 1.54, crit 0.23 | power 3.08, crit 0.46 | +0 to +10 | 82% | 0% | 82% |
| 44 | `iron_legacy` | The Iron Legacy | legacy | godforged | weapon | 50 | power 2.32, crit 0.27, attack_speed 0.19 | power 4.64, crit 0.54, attack_speed 0.38 | +0 to +10 | 126% | 0% | 126% |
| 45 | `titan_slagfist` | Titan's Slagfist | legacy | godforged | weapon | 60 | power 2.74, crit 0.3, attack_speed 0.24 | power 5.48, crit 0.6, attack_speed 0.48 | +0 to +10 | 142% | 0% | 142% |
| 46 | `crucible_maul` | Crucible King's Maul | legacy | godforged | weapon | 64 | power 2.91, crit 0.32, attack_speed 0.26 | power 5.82, crit 0.64, attack_speed 0.52 | +0 to +10 | 149% | 0% | 149% |
| 47 | `founders_edge` | The Founder's Edge | legacy | godforged | weapon | 70 | power 3.16, crit 0.35, attack_speed 0.28 | power 6.32, crit 0.7, attack_speed 0.56 | +0 to +10 | 157% | 0% | 157% |
| 48 | `sovereign_fists` | Sovereign Fists | legacy | godforged | weapon | 70 | power 3.16, crit 0.35, attack_speed 0.28 | power 6.32, crit 0.7, attack_speed 0.56 | +0 to +10 | 157% | 0% | 157% |
| 49 | `dock_beanie` | Dock Beanie | legacy | common | head | 1 | max_hp 15 | max_hp 30 | +0 to +10 | 0% | 13% | 13% |
| 50 | `patched_street_cap` | Patched Street Cap | catalog | common | head | 4 | defense 1, max_hp 12 | defense 2, max_hp 24 | +0 to +10 | 0% | 15% | 15% |
| 51 | `rising_sun_headband` | Rising Sun Headband | catalog | common | head | 4 | defense 1, max_hp 12 | defense 2, max_hp 24 | +0 to +10 | 0% | 15% | 15% |
| 52 | `sakura_straw_hat` | Sakura Straw Hat | catalog | common | head | 4 | defense 1, max_hp 12 | defense 2, max_hp 24 | +0 to +10 | 0% | 15% | 15% |
| 53 | `used_hard_hat` | Used Hard Hat | legacy | common | head | 4 | max_hp 14, defense 1 | max_hp 28, defense 2 | +0 to +10 | 0% | 17% | 17% |
| 54 | `used_iron_helm` | Used Iron Helm | legacy | common | head | 7 | defense 2, max_hp 12 | defense 4, max_hp 24 | +0 to +10 | 0% | 19% | 19% |
| 55 | `used_dockers_cap` | Used Docker's Cap | legacy | common | head | 11 | defense 2, max_hp 22 | defense 4, max_hp 44 | +0 to +10 | 0% | 21% | 21% |
| 56 | `used_hazmat_hood` | Used Hazmat Hood | legacy | common | head | 19 | defense 3, max_hp 34 | defense 6, max_hp 68 | +0 to +10 | 0% | 23% | 23% |
| 57 | `used_watch_cap` | Used Night Watch Cap | legacy | common | head | 26 | defense 3, max_hp 43 | defense 6, max_hp 86 | +0 to +10 | 0% | 21% | 21% |
| 58 | `used_facility_helmet` | Used Facility Helmet | legacy | common | head | 33 | defense 4, max_hp 51 | defense 8, max_hp 102 | +0 to +10 | 0% | 22% | 22% |
| 59 | `used_core_guard_helm` | Used Core Guard Helm | legacy | common | head | 42 | defense 5, max_hp 65 | defense 10, max_hp 130 | +0 to +10 | 0% | 23% | 23% |
| 60 | `used_coolant_uncommon_head` | Used Coolant Helm | legacy | common | head | 53 | defense 6, max_hp 80 | defense 12, max_hp 160 | +0 to +10 | 0% | 24% | 24% |
| 61 | `used_underworks_uncommon_head` | Used Underworks Helm | legacy | common | head | 58 | defense 7, max_hp 87 | defense 14, max_hp 174 | +0 to +10 | 0% | 25% | 25% |
| 62 | `used_foundry_uncommon_head` | Used Foundry Helm | legacy | common | head | 63 | defense 8, max_hp 94 | defense 16, max_hp 188 | +0 to +10 | 0% | 26% | 26% |
| 63 | `used_heart_uncommon_head` | Used Heartforged Helm | legacy | common | head | 68 | defense 8, max_hp 101 | defense 16, max_hp 202 | +0 to +10 | 0% | 25% | 25% |
| 64 | `hard_hat` | Hard Hat | legacy | uncommon | head | 4 | max_hp 16, defense 1 | max_hp 32, defense 2 | +0 to +10 | 0% | 18% | 18% |
| 65 | `iron_helm` | Iron Helm | legacy | uncommon | head | 7 | defense 2, max_hp 13 | defense 4, max_hp 26 | +0 to +10 | 0% | 20% | 20% |
| 66 | `emerald_feather_hat` | Emerald Feather Hat | catalog | uncommon | head | 9 | defense 2, max_hp 21 | defense 4, max_hp 42 | +0 to +10 | 0% | 22% | 22% |
| 67 | `frost_fur_hood` | Frost Fur Hood | catalog | uncommon | head | 9 | defense 2, max_hp 21 | defense 4, max_hp 42 | +0 to +10 | 0% | 22% | 22% |
| 68 | `midnight_wizard_hat` | Midnight Wizard Hat | catalog | uncommon | head | 9 | defense 2, max_hp 21 | defense 4, max_hp 42 | +0 to +10 | 0% | 22% | 22% |
| 69 | `reinforced_bandana` | Reinforced Bandana | catalog | uncommon | head | 9 | defense 2, max_hp 21 | defense 4, max_hp 42 | +0 to +10 | 0% | 22% | 22% |
| 70 | `tiger_hood` | Tiger Hood | catalog | uncommon | head | 9 | defense 2, max_hp 21 | defense 4, max_hp 42 | +0 to +10 | 0% | 22% | 22% |
| 71 | `dockers_cap` | Docker's Cap | legacy | uncommon | head | 11 | defense 2, max_hp 25 | defense 4, max_hp 50 | +0 to +10 | 0% | 22% | 22% |
| 72 | `hazmat_hood` | Hazmat Hood | legacy | uncommon | head | 19 | defense 3, max_hp 40 | defense 6, max_hp 80 | +0 to +10 | 0% | 25% | 25% |
| 73 | `watch_cap` | Night Watch Cap | legacy | uncommon | head | 26 | defense 4, max_hp 50 | defense 8, max_hp 100 | +0 to +10 | 0% | 27% | 27% |
| 74 | `facility_helmet` | Facility Helmet | legacy | uncommon | head | 33 | defense 5, max_hp 60 | defense 10, max_hp 120 | +0 to +10 | 0% | 28% | 28% |
| 75 | `core_guard_helm` | Core Guard Helm | legacy | uncommon | head | 42 | defense 6, max_hp 75 | defense 12, max_hp 150 | +0 to +10 | 0% | 28% | 28% |
| 76 | `coolant_uncommon_head` | Coolant Helm | legacy | uncommon | head | 53 | defense 8, max_hp 94 | defense 16, max_hp 188 | +0 to +10 | 0% | 30% | 30% |
| 77 | `underworks_uncommon_head` | Underworks Helm | legacy | uncommon | head | 58 | defense 8, max_hp 102 | defense 16, max_hp 204 | +0 to +10 | 0% | 29% | 29% |
| 78 | `foundry_uncommon_head` | Foundry Helm | legacy | uncommon | head | 63 | defense 9, max_hp 110 | defense 18, max_hp 220 | +0 to +10 | 0% | 30% | 30% |
| 79 | `heart_uncommon_head` | Heartforged Helm | legacy | uncommon | head | 68 | defense 9, max_hp 118 | defense 18, max_hp 236 | +0 to +10 | 0% | 29% | 29% |
| 80 | `watchmans_cap` | Watchman's Cap | legacy | rare | head | 10 | defense 3, max_hp 25 | defense 6, max_hp 50 | +0 to +10 | 0% | 30% | 30% |
| 81 | `arcane_wizard_hat` | Arcane Wizard Hat | catalog | rare | head | 15 | defense 4, max_hp 27 | defense 8, max_hp 54 | +0 to +10 | 0% | 29% | 29% |
| 82 | `crystal_tiara` | Crystal Tiara | catalog | rare | head | 15 | defense 4, max_hp 27 | defense 8, max_hp 54 | +0 to +10 | 0% | 29% | 29% |
| 83 | `cyber_visor` | Cyber Visor | catalog | rare | head | 15 | defense 4, max_hp 27 | defense 8, max_hp 54 | +0 to +10 | 0% | 29% | 29% |
| 84 | `ice_crown` | Ice Crown | catalog | rare | head | 15 | defense 4, max_hp 27 | defense 8, max_hp 54 | +0 to +10 | 0% | 29% | 29% |
| 85 | `riveted_work_helmet` | Riveted Work Helmet | catalog | rare | head | 15 | defense 4, max_hp 27 | defense 8, max_hp 54 | +0 to +10 | 0% | 29% | 29% |
| 86 | `sakura_wizard_hat` | Sakura Wizard Hat | catalog | rare | head | 15 | defense 4, max_hp 27 | defense 8, max_hp 54 | +0 to +10 | 0% | 29% | 29% |
| 87 | `starlight_wizard_hat` | Starlight Wizard Hat | catalog | rare | head | 15 | defense 4, max_hp 27 | defense 8, max_hp 54 | +0 to +10 | 0% | 29% | 29% |
| 88 | `runners_cap` | Runner's Cap | legacy | rare | head | 30 | defense 5, max_hp 50, crit 0.04 | defense 10, max_hp 100, crit 0.08 | +0 to +10 | 2% | 27% | 30% |
| 89 | `coolant_rare_head` | Vault Guard Helm | legacy | rare | head | 53 | defense 8, max_hp 84, crit 0.07 | defense 16, max_hp 168, crit 0.14 | +0 to +10 | 3% | 29% | 33% |
| 90 | `underworks_rare_head` | Reactor Crew Helm | legacy | rare | head | 58 | defense 9, max_hp 91, crit 0.07 | defense 18, max_hp 182, crit 0.14 | +0 to +10 | 3% | 29% | 34% |
| 91 | `foundry_rare_head` | Slagworker Helm | legacy | rare | head | 63 | defense 10, max_hp 98, crit 0.08 | defense 20, max_hp 196, crit 0.16 | +0 to +10 | 4% | 30% | 35% |
| 92 | `heart_rare_head` | Heart Sentry Helm | legacy | rare | head | 68 | defense 11, max_hp 106, crit 0.08 | defense 22, max_hp 212, crit 0.16 | +0 to +10 | 4% | 31% | 36% |
| 93 | `champion_headband` | Champion's Headband | legacy | epic | head | 7 | max_hp 30, crit 0.04 | max_hp 60, crit 0.08 | +0 to +10 | 2% | 17% | 19% |
| 94 | `harbourmaster_cap` | Harbourmaster's Cap | legacy | epic | head | 15 | defense 3, max_hp 40, crit 0.02 | defense 6, max_hp 80, crit 0.04 | +0 to +10 | 1% | 30% | 31% |
| 95 | `dragonscale_hood` | Dragonscale Hood | catalog | epic | head | 22 | defense 6, max_hp 46 | defense 12, max_hp 92 | +0 to +10 | 0% | 38% | 38% |
| 96 | `gilded_brawler_helm` | Gilded Brawler Helm | catalog | epic | head | 22 | defense 6, max_hp 46 | defense 12, max_hp 92 | +0 to +10 | 0% | 38% | 38% |
| 97 | `glacier_crown` | Glacier Crown | catalog | epic | head | 22 | defense 6, max_hp 46 | defense 12, max_hp 92 | +0 to +10 | 0% | 38% | 38% |
| 98 | `jewelled_crown` | Jewelled Crown | catalog | epic | head | 22 | defense 6, max_hp 46 | defense 12, max_hp 92 | +0 to +10 | 0% | 38% | 38% |
| 99 | `obsidian_crown` | Obsidian Crown | catalog | epic | head | 22 | defense 6, max_hp 46 | defense 12, max_hp 92 | +0 to +10 | 0% | 38% | 38% |
| 100 | `phoenix_feather_hat` | Phoenix Feather Hat | catalog | epic | head | 22 | defense 6, max_hp 46 | defense 12, max_hp 92 | +0 to +10 | 0% | 38% | 38% |
| 101 | `phoenix_tiara` | Phoenix Tiara | catalog | epic | head | 22 | defense 6, max_hp 46 | defense 12, max_hp 92 | +0 to +10 | 0% | 38% | 38% |
| 102 | `spillway_epic_head` | Spillway Chief's Visor | legacy | epic | head | 42 | defense 7, max_hp 95, crit 0.05 | defense 14, max_hp 190, crit 0.1 | +0 to +10 | 2% | 35% | 38% |
| 103 | `coolant_epic_head` | Reinstated Helm | legacy | epic | head | 53 | defense 9, max_hp 117, crit 0.06 | defense 18, max_hp 234, crit 0.12 | +0 to +10 | 3% | 37% | 41% |
| 104 | `underworks_epic_head` | Relapsed Helm | legacy | epic | head | 58 | defense 10, max_hp 127, crit 0.06 | defense 20, max_hp 254, crit 0.12 | +0 to +10 | 3% | 38% | 42% |
| 105 | `foundry_epic_head` | Overdriven Helm | legacy | epic | head | 63 | defense 10, max_hp 137, crit 0.07 | defense 20, max_hp 274, crit 0.14 | +0 to +10 | 3% | 36% | 41% |
| 106 | `heart_epic_head` | Protocol Helm | legacy | epic | head | 68 | defense 11, max_hp 148, crit 0.07 | defense 22, max_hp 296, crit 0.14 | +0 to +10 | 3% | 37% | 42% |
| 107 | `ringmaster_topper` | Ringmaster's Topper | legacy | legendary | head | 27 | defense 5, max_hp 70, crit 0.07 | defense 10, max_hp 140, crit 0.14 | +0 to +10 | 3% | 36% | 40% |
| 108 | `crimson_warlord_helm` | Crimson Warlord Helm | catalog | legendary | head | 30 | defense 10, max_hp 64 | defense 20, max_hp 128 | +0 to +10 | 0% | 51% | 51% |
| 109 | `lion_king_crown` | Lion King's Crown | catalog | legendary | head | 30 | defense 10, max_hp 64 | defense 20, max_hp 128 | +0 to +10 | 0% | 51% | 51% |
| 110 | `director_crown` | Director's Crown | legacy | legendary | head | 48 | defense 9, max_hp 115, crit 0.11 | defense 18, max_hp 230, crit 0.22 | +0 to +10 | 5% | 40% | 48% |
| 111 | `marshal_visor` | Marshal's Floodlight Visor | legacy | godforged | head | 56 | defense 14, max_hp 181, crit 0.17 | defense 28, max_hp 362, crit 0.34 | +0 to +10 | 8% | 59% | 72% |
| 112 | `founders_halo` | Founder's Halo | legacy | godforged | head | 70 | defense 17, max_hp 223, crit 0.21 | defense 34, max_hp 446, crit 0.42 | +0 to +10 | 10% | 60% | 77% |
| 113 | `sovereign_crown` | Sovereign Crown | legacy | godforged | head | 70 | defense 17, max_hp 223, crit 0.21 | defense 34, max_hp 446, crit 0.42 | +0 to +10 | 10% | 60% | 77% |
| 114 | `padded_vest` | Padded Vest | legacy | common | body | 1 | defense 2 | defense 4 | +0 to +10 | 0% | 18% | 18% |
| 115 | `used_work_jacket` | Used Work Jacket | legacy | common | body | 3 | defense 2, max_hp 8 | defense 4, max_hp 16 | +0 to +10 | 0% | 22% | 22% |
| 116 | `canvas_work_shirt` | Canvas Work Shirt | catalog | common | body | 4 | max_hp 15, defense 1 | max_hp 30, defense 2 | +0 to +10 | 0% | 18% | 18% |
| 117 | `used_riveted_jacket` | Used Riveted Jacket | legacy | common | body | 6 | defense 2, max_hp 18 | defense 4, max_hp 36 | +0 to +10 | 0% | 25% | 25% |
| 118 | `used_port_jacket` | Used Port Authority Jacket | legacy | common | body | 11 | defense 3, max_hp 25 | defense 6, max_hp 50 | +0 to +10 | 0% | 28% | 28% |
| 119 | `used_plant_vest` | Used Plant Security Vest | legacy | common | body | 19 | defense 4, max_hp 33 | defense 8, max_hp 66 | +0 to +10 | 0% | 27% | 27% |
| 120 | `used_kevlar_jacket` | Used Kevlar Jacket | legacy | common | body | 26 | defense 5, max_hp 46 | defense 10, max_hp 92 | +0 to +10 | 0% | 29% | 29% |
| 121 | `used_trooper_vest` | Used Trooper Vest | legacy | common | body | 33 | defense 7, max_hp 51 | defense 14, max_hp 102 | +0 to +10 | 0% | 32% | 32% |
| 122 | `used_reactor_plate` | Used Reactor Plate | legacy | common | body | 42 | defense 8, max_hp 71 | defense 16, max_hp 142 | +0 to +10 | 0% | 33% | 33% |
| 123 | `used_coolant_uncommon_body` | Used Coolant Plate | legacy | common | body | 53 | defense 9, max_hp 88 | defense 18, max_hp 176 | +0 to +10 | 0% | 32% | 32% |
| 124 | `used_underworks_uncommon_body` | Used Underworks Plate | legacy | common | body | 58 | defense 10, max_hp 96 | defense 20, max_hp 192 | +0 to +10 | 0% | 32% | 32% |
| 125 | `used_foundry_uncommon_body` | Used Foundry Plate | legacy | common | body | 63 | defense 11, max_hp 103 | defense 22, max_hp 206 | +0 to +10 | 0% | 33% | 33% |
| 126 | `used_heart_uncommon_body` | Used Heartforged Plate | legacy | common | body | 68 | defense 12, max_hp 111 | defense 24, max_hp 222 | +0 to +10 | 0% | 34% | 34% |
| 127 | `work_jacket` | Work Jacket | legacy | uncommon | body | 3 | defense 2, max_hp 10 | defense 4, max_hp 20 | +0 to +10 | 0% | 24% | 24% |
| 128 | `riveted_jacket` | Riveted Jacket | legacy | uncommon | body | 6 | defense 2, max_hp 21 | defense 4, max_hp 42 | +0 to +10 | 0% | 27% | 27% |
| 129 | `padded_street_jacket` | Padded Street Jacket | catalog | uncommon | body | 9 | max_hp 28, defense 2 | max_hp 56, defense 4 | +0 to +10 | 0% | 26% | 26% |
| 130 | `port_jacket` | Port Authority Jacket | legacy | uncommon | body | 11 | defense 3, max_hp 30 | defense 6, max_hp 60 | +0 to +10 | 0% | 31% | 31% |
| 131 | `plant_vest` | Plant Security Vest | legacy | uncommon | body | 19 | defense 5, max_hp 40 | defense 10, max_hp 80 | +0 to +10 | 0% | 35% | 35% |
| 132 | `kevlar_jacket` | Kevlar Jacket | legacy | uncommon | body | 26 | defense 6, max_hp 55 | defense 12, max_hp 110 | +0 to +10 | 0% | 36% | 36% |
| 133 | `trooper_vest` | Trooper Vest | legacy | uncommon | body | 33 | defense 8, max_hp 60 | defense 16, max_hp 120 | +0 to +10 | 0% | 38% | 38% |
| 134 | `reactor_plate` | Reactor Plate | legacy | uncommon | body | 42 | defense 9, max_hp 85 | defense 18, max_hp 170 | +0 to +10 | 0% | 39% | 39% |
| 135 | `coolant_uncommon_body` | Coolant Plate | legacy | uncommon | body | 53 | defense 11, max_hp 104 | defense 22, max_hp 208 | +0 to +10 | 0% | 39% | 39% |
| 136 | `underworks_uncommon_body` | Underworks Plate | legacy | uncommon | body | 58 | defense 12, max_hp 113 | defense 24, max_hp 226 | +0 to +10 | 0% | 40% | 40% |
| 137 | `foundry_uncommon_body` | Foundry Plate | legacy | uncommon | body | 63 | defense 13, max_hp 122 | defense 26, max_hp 244 | +0 to +10 | 0% | 40% | 40% |
| 138 | `heart_uncommon_body` | Heartforged Plate | legacy | uncommon | body | 68 | defense 14, max_hp 130 | defense 28, max_hp 260 | +0 to +10 | 0% | 40% | 40% |
| 139 | `night_market_jacket` | Night Market Jacket | legacy | rare | body | 7 | defense 3, max_hp 25 | defense 6, max_hp 50 | +0 to +10 | 0% | 35% | 35% |
| 140 | `riveted_dock_coat` | Riveted Dock Coat | catalog | rare | body | 15 | max_hp 47, defense 4 | max_hp 94, defense 8 | +0 to +10 | 0% | 39% | 39% |
| 141 | `pims_field_vest` | Pim's Field Vest | legacy | rare | body | 24 | defense 7, max_hp 55 | defense 14, max_hp 110 | +0 to +10 | 0% | 43% | 43% |
| 142 | `coolant_rare_body` | Vault Guard Plate | legacy | rare | body | 53 | defense 14, max_hp 108 | defense 28, max_hp 216 | +0 to +10 | 0% | 48% | 48% |
| 143 | `underworks_rare_body` | Reactor Crew Plate | legacy | rare | body | 58 | defense 15, max_hp 117 | defense 30, max_hp 234 | +0 to +10 | 0% | 48% | 48% |
| 144 | `foundry_rare_body` | Slagworker Plate | legacy | rare | body | 63 | defense 16, max_hp 127 | defense 32, max_hp 254 | +0 to +10 | 0% | 48% | 48% |
| 145 | `heart_rare_body` | Heart Sentry Plate | legacy | rare | body | 68 | defense 17, max_hp 136 | defense 34, max_hp 272 | +0 to +10 | 0% | 48% | 48% |
| 146 | `smelter_apron` | Smelter's Apron | legacy | epic | body | 9 | defense 3, max_hp 40 | defense 6, max_hp 80 | +0 to +10 | 0% | 40% | 40% |
| 147 | `gilded_fight_robe` | Gilded Fight Robe | catalog | epic | body | 22 | max_hp 74, defense 6 | max_hp 148, defense 12 | +0 to +10 | 0% | 48% | 48% |
| 148 | `k7_plating` | K7 Plating | legacy | epic | body | 23 | defense 7, max_hp 70 | defense 14, max_hp 140 | +0 to +10 | 0% | 50% | 50% |
| 149 | `spillway_epic_body` | Spillway Chief's Coat | legacy | epic | body | 42 | defense 12, max_hp 110 | defense 24, max_hp 220 | +0 to +10 | 0% | 54% | 54% |
| 150 | `director_coat` | Director's Coat | legacy | epic | body | 48 | defense 14, max_hp 125 | defense 28, max_hp 250 | +0 to +10 | 0% | 57% | 57% |
| 151 | `coolant_epic_body` | Reinstated Plate | legacy | epic | body | 53 | defense 15, max_hp 136 | defense 30, max_hp 272 | +0 to +10 | 0% | 56% | 56% |
| 152 | `underworks_epic_body` | Relapsed Plate | legacy | epic | body | 58 | defense 17, max_hp 148 | defense 34, max_hp 296 | +0 to +10 | 0% | 59% | 59% |
| 153 | `foundry_epic_body` | Overdriven Plate | legacy | epic | body | 63 | defense 18, max_hp 159 | defense 36, max_hp 318 | +0 to +10 | 0% | 58% | 58% |
| 154 | `heart_epic_body` | Protocol Plate | legacy | epic | body | 68 | defense 19, max_hp 171 | defense 38, max_hp 342 | +0 to +10 | 0% | 58% | 58% |
| 155 | `crimson_warlord_mantle` | Crimson Warlord Mantle | catalog | legendary | body | 30 | max_hp 113, defense 9 | max_hp 226, defense 18 | +0 to +10 | 0% | 62% | 62% |
| 156 | `zeros_mantle` | Zero's Mantle | legacy | godforged | body | 50 | defense 22, max_hp 226 | defense 44, max_hp 452 | +0 to +10 | 0% | 109% | 109% |
| 157 | `marshal_greatcoat` | Marshal's Greatcoat | legacy | godforged | body | 56 | defense 26, max_hp 237 | defense 52, max_hp 474 | +0 to +10 | 0% | 115% | 115% |
| 158 | `founders_plate` | Founder's Plate | legacy | godforged | body | 70 | defense 32, max_hp 292 | defense 64, max_hp 584 | +0 to +10 | 0% | 119% | 119% |
| 159 | `sovereign_mantle` | Sovereign Mantle | legacy | godforged | body | 70 | defense 32, max_hp 292 | defense 64, max_hp 584 | +0 to +10 | 0% | 119% | 119% |
| 160 | `fingerless_gloves` | Fingerless Gloves | legacy | common | hands | 1 | power 0.02, attack_speed 0.03 | power 0.04, attack_speed 0.06 | +0 to +10 | 5% | 0% | 5% |
| 161 | `used_cargo_gloves` | Used Cargo Gloves | legacy | common | hands | 13 | power 0.11, defense 1, attack_speed 0.03 | power 0.22, defense 2, attack_speed 0.06 | +0 to +10 | 10% | 4% | 15% |
| 162 | `used_insulated_gloves` | Used Insulated Gloves | legacy | common | hands | 21 | power 0.16, defense 1, crit 0.04 | power 0.32, defense 2, crit 0.08 | +0 to +10 | 10% | 3% | 14% |
| 163 | `used_fight_gloves` | Used Taped Fight Gloves | legacy | common | hands | 27 | power 0.21, defense 1, crit 0.05 | power 0.42, defense 2, crit 0.1 | +0 to +10 | 12% | 3% | 15% |
| 164 | `used_grip_gloves` | Used Lab Grip Gloves | legacy | common | hands | 35 | power 0.26, defense 2, crit 0.05 | power 0.52, defense 4, crit 0.1 | +0 to +10 | 12% | 4% | 17% |
| 165 | `used_insulated_gauntlets` | Used Insulated Gauntlets | legacy | common | hands | 44 | power 0.33, defense 2, crit 0.07 | power 0.66, defense 4, crit 0.14 | +0 to +10 | 14% | 4% | 18% |
| 166 | `used_coolant_uncommon_hands` | Used Coolant Gloves | legacy | common | hands | 53 | power 0.39, defense 2, crit 0.08 | power 0.78, defense 4, crit 0.16 | +0 to +10 | 15% | 3% | 19% |
| 167 | `used_underworks_uncommon_hands` | Used Underworks Gloves | legacy | common | hands | 58 | power 0.42, defense 2, crit 0.09 | power 0.84, defense 4, crit 0.18 | +0 to +10 | 16% | 3% | 19% |
| 168 | `used_foundry_uncommon_hands` | Used Foundry Gloves | legacy | common | hands | 63 | power 0.46, defense 2, crit 0.09 | power 0.92, defense 4, crit 0.18 | +0 to +10 | 16% | 3% | 19% |
| 169 | `used_heart_uncommon_hands` | Used Heartforged Gloves | legacy | common | hands | 68 | power 0.49, defense 3, crit 0.1 | power 0.98, defense 6, crit 0.2 | +0 to +10 | 17% | 4% | 21% |
| 170 | `cargo_gloves` | Cargo Gloves | legacy | uncommon | hands | 13 | power 0.13, defense 1, attack_speed 0.04 | power 0.26, defense 2, attack_speed 0.08 | +0 to +10 | 12% | 4% | 17% |
| 171 | `insulated_gloves` | Insulated Gloves | legacy | uncommon | hands | 21 | power 0.19, defense 1, crit 0.05 | power 0.38, defense 2, crit 0.1 | +0 to +10 | 12% | 3% | 16% |
| 172 | `fight_gloves` | Taped Fight Gloves | legacy | uncommon | hands | 27 | power 0.25, defense 1, crit 0.06 | power 0.5, defense 2, crit 0.12 | +0 to +10 | 14% | 3% | 17% |
| 173 | `grip_gloves` | Lab Grip Gloves | legacy | uncommon | hands | 35 | power 0.31, defense 2, crit 0.06 | power 0.62, defense 4, crit 0.12 | +0 to +10 | 15% | 4% | 20% |
| 174 | `insulated_gauntlets` | Insulated Gauntlets | legacy | uncommon | hands | 44 | power 0.39, defense 2, crit 0.08 | power 0.78, defense 4, crit 0.16 | +0 to +10 | 17% | 4% | 21% |
| 175 | `coolant_uncommon_hands` | Coolant Gloves | legacy | uncommon | hands | 53 | power 0.46, defense 2, crit 0.09 | power 0.92, defense 4, crit 0.18 | +0 to +10 | 18% | 3% | 21% |
| 176 | `underworks_uncommon_hands` | Underworks Gloves | legacy | uncommon | hands | 58 | power 0.5, defense 3, crit 0.1 | power 1, defense 6, crit 0.2 | +0 to +10 | 19% | 4% | 24% |
| 177 | `foundry_uncommon_hands` | Foundry Gloves | legacy | uncommon | hands | 63 | power 0.54, defense 3, crit 0.11 | power 1.08, defense 6, crit 0.22 | +0 to +10 | 19% | 4% | 24% |
| 178 | `heart_uncommon_hands` | Heartforged Gloves | legacy | uncommon | hands | 68 | power 0.58, defense 3, crit 0.12 | power 1.16, defense 6, crit 0.24 | +0 to +10 | 20% | 4% | 25% |
| 179 | `odos_old_gloves` | Odo's Old Gloves | legacy | rare | hands | 3 | power 0.04, defense 1, crit 0.02 | power 0.08, defense 2, crit 0.04 | +0 to +10 | 5% | 7% | 12% |
| 180 | `iron_wraps` | Iron Wraps | legacy | rare | hands | 5 | power 0.06, defense 1, crit 0.02 | power 0.12, defense 2, crit 0.04 | +0 to +10 | 6% | 6% | 13% |
| 181 | `inspectors_gloves` | Inspector's Gloves | legacy | rare | hands | 20 | power 0.18, defense 2, crit 0.06 | power 0.36, defense 4, crit 0.12 | +0 to +10 | 13% | 7% | 20% |
| 182 | `sentinel_gauntlets` | Sentinel Gauntlets | legacy | rare | hands | 44 | power 0.43, defense 3, crit 0.09 | power 0.86, defense 6, crit 0.18 | +0 to +10 | 19% | 5% | 25% |
| 183 | `coolant_rare_hands` | Vault Guard Gloves | legacy | rare | hands | 53 | power 0.5, defense 3, crit 0.1 | power 1, defense 6, crit 0.2 | +0 to +10 | 20% | 5% | 25% |
| 184 | `underworks_rare_hands` | Reactor Crew Gloves | legacy | rare | hands | 58 | power 0.54, defense 4, crit 0.11 | power 1.08, defense 8, crit 0.22 | +0 to +10 | 20% | 6% | 27% |
| 185 | `foundry_rare_hands` | Slagworker Gloves | legacy | rare | hands | 63 | power 0.58, defense 4, crit 0.12 | power 1.16, defense 8, crit 0.24 | +0 to +10 | 21% | 5% | 28% |
| 186 | `heart_rare_hands` | Heart Sentry Gloves | legacy | rare | hands | 68 | power 0.63, defense 4, crit 0.13 | power 1.26, defense 8, crit 0.26 | +0 to +10 | 22% | 5% | 28% |
| 187 | `champion_wraps` | Champion's Wraps | legacy | epic | hands | 7 | power 0.09, crit 0.04, attack_speed 0.03 | power 0.18, crit 0.08, attack_speed 0.06 | +0 to +10 | 12% | 0% | 12% |
| 188 | `chiefs_gloves` | Chief's Gloves | legacy | epic | hands | 21 | power 0.22, defense 2, crit 0.07 | power 0.44, defense 4, crit 0.14 | +0 to +10 | 15% | 6% | 22% |
| 189 | `coolant_epic_hands` | Reinstated Gloves | legacy | epic | hands | 53 | power 0.49, defense 4, crit 0.16 | power 0.98, defense 8, crit 0.32 | +0 to +10 | 23% | 6% | 30% |
| 190 | `underworks_epic_hands` | Relapsed Gloves | legacy | epic | hands | 58 | power 0.54, defense 5, crit 0.17 | power 1.08, defense 10, crit 0.34 | +0 to +10 | 24% | 7% | 33% |
| 191 | `foundry_epic_hands` | Overdriven Gloves | legacy | epic | hands | 63 | power 0.58, defense 5, crit 0.18 | power 1.16, defense 10, crit 0.36 | +0 to +10 | 24% | 7% | 33% |
| 192 | `heart_epic_hands` | Protocol Gloves | legacy | epic | hands | 68 | power 0.62, defense 6, crit 0.2 | power 1.24, defense 12, crit 0.4 | +0 to +10 | 26% | 8% | 36% |
| 193 | `subject_grips` | Subject Grips | legacy | legendary | hands | 35 | power 0.37, defense 3, crit 0.11, attack_speed 0.07 | power 0.74, defense 6, crit 0.22, attack_speed 0.14 | +0 to +10 | 28% | 7% | 37% |
| 194 | `piston_gauntlets` | Piston Gauntlets | legacy | godforged | hands | 45 | power 0.88, defense 5, crit 0.16 | power 1.76, defense 10, crit 0.32 | +0 to +10 | 38% | 9% | 51% |
| 195 | `titan_grip` | Titan's Grip | legacy | godforged | hands | 60 | power 0.83, defense 7, crit 0.25, attack_speed 0.16 | power 1.66, defense 14, crit 0.5, attack_speed 0.32 | +0 to +10 | 58% | 10% | 74% |
| 196 | `crucible_gauntlets` | Crucible Gauntlets | legacy | godforged | hands | 64 | power 0.88, defense 7, crit 0.26, attack_speed 0.17 | power 1.76, defense 14, crit 0.52, attack_speed 0.34 | +0 to +10 | 60% | 10% | 76% |
| 197 | `sovereign_grips` | Sovereign Grips | legacy | godforged | hands | 70 | power 0.95, defense 8, crit 0.28, attack_speed 0.18 | power 1.9, defense 16, crit 0.56, attack_speed 0.36 | +0 to +10 | 63% | 10% | 80% |
| 198 | `canvas_sneakers` | Canvas Sneakers | legacy | common | feet | 1 | speed 0.06 | speed 0.12 | +0 to +10 | 0% | 0% | 0% |
| 199 | `used_steel_toe_boots` | Used Steel-toe Boots | legacy | common | feet | 4 | defense 1, max_hp 12, speed -0.02 | defense 2, max_hp 24, speed -0.02 | +0 to +10 | 0% | 15% | 15% |
| 200 | `used_street_runners` | Used Street Runners | legacy | common | feet | 6 | speed 0.03, defense 1, attack_speed 0.02 | speed 0.06, defense 2, attack_speed 0.04 | +0 to +10 | 2% | 6% | 8% |
| 201 | `used_deck_boots` | Used Deck Boots | legacy | common | feet | 13 | speed 0.06, defense 1, max_hp 13 | speed 0.12, defense 2, max_hp 26 | +0 to +10 | 0% | 10% | 10% |
| 202 | `used_lab_boots` | Used Lab Boots | legacy | common | feet | 21 | speed 0.09, defense 2, attack_speed 0.04 | speed 0.18, defense 4, attack_speed 0.08 | +0 to +10 | 4% | 6% | 11% |
| 203 | `used_runner_sneakers` | Used Runner Sneakers | legacy | common | feet | 27 | speed 0.14, defense 2, attack_speed 0.05 | speed 0.28, defense 4, attack_speed 0.1 | +0 to +10 | 5% | 5% | 11% |
| 204 | `used_facility_boots` | Used Facility Boots | legacy | common | feet | 35 | speed 0.14, defense 3, attack_speed 0.07 | speed 0.28, defense 6, attack_speed 0.14 | +0 to +10 | 7% | 7% | 14% |
| 205 | `used_walkway_boots` | Used Walkway Boots | legacy | common | feet | 44 | speed 0.16, defense 3, attack_speed 0.08 | speed 0.32, defense 6, attack_speed 0.16 | +0 to +10 | 8% | 5% | 14% |
| 206 | `used_coolant_uncommon_feet` | Used Coolant Boots | legacy | common | feet | 53 | speed 0.19, defense 4, attack_speed 0.1 | speed 0.38, defense 8, attack_speed 0.2 | +0 to +10 | 10% | 6% | 17% |
| 207 | `used_underworks_uncommon_feet` | Used Underworks Boots | legacy | common | feet | 58 | speed 0.21, defense 4, attack_speed 0.11 | speed 0.42, defense 8, attack_speed 0.22 | +0 to +10 | 11% | 6% | 18% |
| 208 | `used_foundry_uncommon_feet` | Used Foundry Boots | legacy | common | feet | 63 | speed 0.22, defense 5, attack_speed 0.12 | speed 0.44, defense 10, attack_speed 0.24 | +0 to +10 | 12% | 7% | 20% |
| 209 | `used_heart_uncommon_feet` | Used Heartforged Boots | legacy | common | feet | 68 | speed 0.24, defense 5, attack_speed 0.13 | speed 0.48, defense 10, attack_speed 0.26 | +0 to +10 | 13% | 6% | 20% |
| 210 | `steel_toe_boots` | Steel-toe Boots | legacy | uncommon | feet | 4 | defense 1, max_hp 14, speed -0.02 | defense 2, max_hp 28, speed -0.02 | +0 to +10 | 0% | 17% | 17% |
| 211 | `street_runners` | Street Runners | legacy | uncommon | feet | 6 | speed 0.04, defense 1, attack_speed 0.02 | speed 0.08, defense 2, attack_speed 0.04 | +0 to +10 | 2% | 6% | 8% |
| 212 | `deck_boots` | Deck Boots | legacy | uncommon | feet | 13 | speed 0.07, defense 1, max_hp 16 | speed 0.14, defense 2, max_hp 32 | +0 to +10 | 0% | 11% | 11% |
| 213 | `lab_boots` | Lab Boots | legacy | uncommon | feet | 21 | speed 0.11, defense 2, attack_speed 0.05 | speed 0.22, defense 4, attack_speed 0.1 | +0 to +10 | 5% | 6% | 12% |
| 214 | `runner_sneakers` | Runner Sneakers | legacy | uncommon | feet | 27 | speed 0.16, defense 2, attack_speed 0.06 | speed 0.32, defense 4, attack_speed 0.12 | +0 to +10 | 6% | 5% | 12% |
| 215 | `facility_boots` | Facility Boots | legacy | uncommon | feet | 35 | speed 0.17, defense 3, attack_speed 0.08 | speed 0.34, defense 6, attack_speed 0.16 | +0 to +10 | 8% | 7% | 15% |
| 216 | `walkway_boots` | Walkway Boots | legacy | uncommon | feet | 44 | speed 0.19, defense 4, attack_speed 0.1 | speed 0.38, defense 8, attack_speed 0.2 | +0 to +10 | 10% | 7% | 18% |
| 217 | `coolant_uncommon_feet` | Coolant Boots | legacy | uncommon | feet | 53 | speed 0.22, defense 5, attack_speed 0.12 | speed 0.44, defense 10, attack_speed 0.24 | +0 to +10 | 12% | 8% | 21% |
| 218 | `underworks_uncommon_feet` | Underworks Boots | legacy | uncommon | feet | 58 | speed 0.24, defense 5, attack_speed 0.13 | speed 0.48, defense 10, attack_speed 0.26 | +0 to +10 | 13% | 7% | 21% |
| 219 | `foundry_uncommon_feet` | Foundry Boots | legacy | uncommon | feet | 63 | speed 0.26, defense 6, attack_speed 0.14 | speed 0.52, defense 12, attack_speed 0.28 | +0 to +10 | 14% | 8% | 24% |
| 220 | `heart_uncommon_feet` | Heartforged Boots | legacy | uncommon | feet | 68 | speed 0.28, defense 6, attack_speed 0.15 | speed 0.56, defense 12, attack_speed 0.3 | +0 to +10 | 15% | 8% | 24% |
| 221 | `chais_deck_shoes` | Chai's Deck Shoes | legacy | rare | feet | 15 | speed 0.13, defense 3 | speed 0.26, defense 6 | +0 to +10 | 0% | 12% | 12% |
| 222 | `leks_lab_boots` | Lek's Lab Boots | legacy | rare | feet | 34 | speed 0.17, defense 4, attack_speed 0.08 | speed 0.34, defense 8, attack_speed 0.16 | +0 to +10 | 8% | 9% | 18% |
| 223 | `coolant_rare_feet` | Vault Guard Boots | legacy | rare | feet | 53 | speed 0.25, defense 6, attack_speed 0.12 | speed 0.5, defense 12, attack_speed 0.24 | +0 to +10 | 12% | 10% | 23% |
| 224 | `underworks_rare_feet` | Reactor Crew Boots | legacy | rare | feet | 58 | speed 0.28, defense 7, attack_speed 0.13 | speed 0.56, defense 14, attack_speed 0.26 | +0 to +10 | 13% | 11% | 25% |
| 225 | `foundry_rare_feet` | Slagworker Boots | legacy | rare | feet | 63 | speed 0.3, defense 7, attack_speed 0.14 | speed 0.6, defense 14, attack_speed 0.28 | +0 to +10 | 14% | 10% | 25% |
| 226 | `heart_rare_feet` | Heart Sentry Boots | legacy | rare | feet | 68 | speed 0.32, defense 8, attack_speed 0.15 | speed 0.64, defense 16, attack_speed 0.3 | +0 to +10 | 15% | 11% | 27% |
| 227 | `foreman_boots` | Foreman's Boots | legacy | epic | feet | 3 | defense 1, max_hp 7, speed 0.03 | defense 2, max_hp 14, speed 0.06 | +0 to +10 | 0% | 13% | 13% |
| 228 | `dockmaster_boots` | Dockmaster's Boots | legacy | epic | feet | 15 | speed 0.1, defense 2, max_hp 20 | speed 0.2, defense 4, max_hp 40 | +0 to +10 | 0% | 16% | 16% |
| 229 | `sak_loafers` | Sak's Loafers | legacy | epic | feet | 31 | speed 0.2, defense 4, attack_speed 0.09 | speed 0.4, defense 8, attack_speed 0.18 | +0 to +10 | 9% | 10% | 20% |
| 230 | `commander_greaves` | Commander's Greaves | legacy | epic | feet | 39 | speed 0.24, defense 5, attack_speed 0.11 | speed 0.48, defense 10, attack_speed 0.22 | +0 to +10 | 11% | 11% | 23% |
| 231 | `coolant_epic_feet` | Reinstated Boots | legacy | epic | feet | 53 | speed 0.32, defense 7, attack_speed 0.14 | speed 0.64, defense 14, attack_speed 0.28 | +0 to +10 | 14% | 12% | 27% |
| 232 | `underworks_epic_feet` | Relapsed Boots | legacy | epic | feet | 58 | speed 0.34, defense 7, attack_speed 0.16 | speed 0.68, defense 14, attack_speed 0.32 | +0 to +10 | 16% | 11% | 28% |
| 233 | `foundry_epic_feet` | Overdriven Boots | legacy | epic | feet | 63 | speed 0.37, defense 8, attack_speed 0.17 | speed 0.74, defense 16, attack_speed 0.34 | +0 to +10 | 17% | 12% | 30% |
| 234 | `heart_epic_feet` | Protocol Boots | legacy | epic | feet | 68 | speed 0.4, defense 8, attack_speed 0.18 | speed 0.8, defense 16, attack_speed 0.36 | +0 to +10 | 18% | 11% | 31% |
| 235 | `marshal_sabatons` | Marshal's Sabatons | legacy | godforged | feet | 56 | speed 0.52, defense 11, attack_speed 0.28 | speed 1.04, defense 22, attack_speed 0.56 | +0 to +10 | 28% | 19% | 52% |
| 236 | `sovereign_treads` | Sovereign Treads | legacy | godforged | feet | 70 | speed 0.64, defense 13, attack_speed 0.34 | speed 1.28, defense 26, attack_speed 0.68 | +0 to +10 | 34% | 18% | 58% |
| 237 | `used_coolant_uncommon_charm` | Used Coolant Charm | legacy | common | charm | 53 | max_hp 77, power 0.15, crit 0.1 | max_hp 154, power 0.3, crit 0.2 | +0 to +10 | 9% | 12% | 23% |
| 238 | `used_underworks_uncommon_charm` | Used Underworks Charm | legacy | common | charm | 58 | max_hp 84, power 0.17, crit 0.11 | max_hp 168, power 0.34, crit 0.22 | +0 to +10 | 10% | 12% | 24% |
| 239 | `used_foundry_uncommon_charm` | Used Foundry Charm | legacy | common | charm | 63 | max_hp 91, power 0.18, crit 0.12 | max_hp 182, power 0.36, crit 0.24 | +0 to +10 | 11% | 12% | 24% |
| 240 | `used_heart_uncommon_charm` | Used Heartforged Charm | legacy | common | charm | 68 | max_hp 98, power 0.2, crit 0.12 | max_hp 196, power 0.4, crit 0.24 | +0 to +10 | 11% | 12% | 25% |
| 241 | `lucky_coin` | Lucky Coin | legacy | uncommon | charm | 3 | max_hp 9, power 0.01, crit 0.03 | max_hp 18, power 0.02, crit 0.06 | +0 to +10 | 2% | 7% | 9% |
| 242 | `coolant_uncommon_charm` | Coolant Charm | legacy | uncommon | charm | 53 | max_hp 91, power 0.18, crit 0.12 | max_hp 182, power 0.36, crit 0.24 | +0 to +10 | 11% | 14% | 27% |
| 243 | `underworks_uncommon_charm` | Underworks Charm | legacy | uncommon | charm | 58 | max_hp 99, power 0.2, crit 0.13 | max_hp 198, power 0.4, crit 0.26 | +0 to +10 | 12% | 14% | 28% |
| 244 | `foundry_uncommon_charm` | Foundry Charm | legacy | uncommon | charm | 63 | max_hp 107, power 0.21, crit 0.14 | max_hp 214, power 0.42, crit 0.28 | +0 to +10 | 12% | 15% | 29% |
| 245 | `heart_uncommon_charm` | Heartforged Charm | legacy | uncommon | charm | 68 | max_hp 115, power 0.23, crit 0.15 | max_hp 230, power 0.46, crit 0.3 | +0 to +10 | 13% | 15% | 30% |
| 246 | `brass_whistle` | Brass Whistle | legacy | rare | charm | 1 | max_hp 20 | max_hp 40 | +0 to +10 | 0% | 17% | 17% |
| 247 | `kenjis_lucky_charm` | Kenji's Lucky Charm | legacy | rare | charm | 26 | max_hp 55, power 0.11, crit 0.07 | max_hp 110, power 0.22, crit 0.14 | +0 to +10 | 9% | 15% | 25% |
| 248 | `coolant_rare_charm` | Vault Guard Charm | legacy | rare | charm | 53 | max_hp 105, power 0.21, crit 0.13 | max_hp 210, power 0.42, crit 0.26 | +0 to +10 | 13% | 17% | 31% |
| 249 | `underworks_rare_charm` | Reactor Crew Charm | legacy | rare | charm | 58 | max_hp 114, power 0.23, crit 0.14 | max_hp 228, power 0.46, crit 0.28 | +0 to +10 | 13% | 17% | 32% |
| 250 | `foundry_rare_charm` | Slagworker Charm | legacy | rare | charm | 63 | max_hp 123, power 0.25, crit 0.16 | max_hp 246, power 0.5, crit 0.32 | +0 to +10 | 15% | 17% | 34% |
| 251 | `heart_rare_charm` | Heart Sentry Charm | legacy | rare | charm | 68 | max_hp 132, power 0.26, crit 0.17 | max_hp 264, power 0.52, crit 0.34 | +0 to +10 | 15% | 17% | 34% |
| 252 | `jade_charm` | Jade Charm | legacy | epic | charm | 8 | max_hp 25, power 0.05, attack_speed 0.06 | max_hp 50, power 0.1, attack_speed 0.12 | +0 to +10 | 10% | 14% | 25% |
| 253 | `subject_band` | Subject 12's Band | legacy | epic | charm | 35 | max_hp 100, defense 3, crit 0.08 | max_hp 200, defense 6, crit 0.16 | +0 to +10 | 4% | 30% | 35% |
| 254 | `coolant_epic_charm` | Reinstated Charm | legacy | epic | charm | 53 | max_hp 145, defense 4, crit 0.12 | max_hp 290, defense 8, crit 0.24 | +0 to +10 | 6% | 31% | 38% |
| 255 | `underworks_epic_charm` | Relapsed Charm | legacy | epic | charm | 58 | max_hp 158, defense 5, crit 0.13 | max_hp 316, defense 10, crit 0.26 | +0 to +10 | 6% | 32% | 41% |
| 256 | `foundry_epic_charm` | Overdriven Charm | legacy | epic | charm | 63 | max_hp 170, defense 5, crit 0.14 | max_hp 340, defense 10, crit 0.28 | +0 to +10 | 7% | 32% | 41% |
| 257 | `heart_epic_charm` | Protocol Charm | legacy | epic | charm | 68 | max_hp 182, defense 5, crit 0.15 | max_hp 364, defense 10, crit 0.3 | +0 to +10 | 7% | 31% | 41% |
| 258 | `k7_core_plate` | K-7 Core Plate | legacy | legendary | charm | 23 | max_hp 65, power 0.15, attack_speed 0.13 | max_hp 130, power 0.3, attack_speed 0.26 | +0 to +10 | 21% | 19% | 45% |
| 259 | `sak_signet` | Sak's Signet | legacy | legendary | charm | 31 | max_hp 90, power 0.19, crit 0.11 | max_hp 180, power 0.38, crit 0.22 | +0 to +10 | 14% | 22% | 38% |
| 260 | `director_signet` | Director's Signet | legacy | legendary | charm | 48 | max_hp 155, power 0.24, crit 0.13 | max_hp 310, power 0.48, crit 0.26 | +0 to +10 | 14% | 26% | 44% |
| 261 | `heart_of_iron_city` | Heart of Iron City | legacy | legendary | charm | 48 | max_hp 140, power 0.24, crit 0.09, attack_speed 0.09 | max_hp 280, power 0.48, crit 0.18, attack_speed 0.18 | +0 to +10 | 22% | 24% | 51% |
| 262 | `mothers_heart` | Mother's Heart | legacy | godforged | charm | 30 | max_hp 144, power 0.21, attack_speed 0.15 | max_hp 288, power 0.42, attack_speed 0.3 | +0 to +10 | 25% | 36% | 69% |
| 263 | `colossus_core` | Colossus Core | legacy | godforged | charm | 45 | max_hp 207, power 0.3, attack_speed 0.21 | max_hp 414, power 0.6, attack_speed 0.42 | +0 to +10 | 32% | 37% | 82% |
| 264 | `titan_core` | Titan's Ember Core | legacy | godforged | charm | 60 | max_hp 239, power 0.41, crit 0.15, attack_speed 0.15 | max_hp 478, power 0.82, crit 0.3, attack_speed 0.3 | +0 to +10 | 36% | 34% | 83% |
| 265 | `crucible_heart` | Heart of the Crucible | legacy | godforged | charm | 64 | max_hp 254, power 0.44, crit 0.16, attack_speed 0.16 | max_hp 508, power 0.88, crit 0.32, attack_speed 0.32 | +0 to +10 | 39% | 34% | 86% |
| 266 | `founders_engine_core` | Engine Heart | legacy | godforged | charm | 70 | max_hp 276, power 0.47, crit 0.18, attack_speed 0.18 | max_hp 552, power 0.94, crit 0.36, attack_speed 0.36 | +0 to +10 | 42% | 34% | 91% |
| 267 | `sovereign_seal` | Sovereign Seal | legacy | godforged | charm | 70 | max_hp 276, power 0.47, crit 0.18, attack_speed 0.18 | max_hp 552, power 0.94, crit 0.36, attack_speed 0.36 | +0 to +10 | 42% | 34% | 91% |

## Appendix B: Non-equipment items (38; excluded from power comparisons)

| # | Item ID | Name | Source | Type | Category | Grade |
|---:|---|---|---|---|---|---|
| 1 | `ginger_tea` | Ginger Tea | legacy | consumable | – | uncommon |
| 2 | `herbal_tonic` | Herbal Tonic | legacy | consumable | – | rare |
| 3 | `rice_box` | Rice Box | legacy | consumable | – | uncommon |
| 4 | `steamed_bun` | Steamed Bun | legacy | consumable | – | common |
| 5 | `adrenal_shot` | Adrenal Shot | catalog | consumable | consumable | rare |
| 6 | `energy_drink_ironworks` | Ironworks Energy Drink | catalog | consumable | consumable | uncommon |
| 7 | `focus_gum` | Focus Gum | catalog | consumable | consumable | common |
| 8 | `second_wind_tonic` | Second Wind Tonic | catalog | consumable | consumable | epic |
| 9 | `altered_manifest` | The Altered Manifest | legacy | key | – | epic |
| 10 | `baron_ledger` | The Baron's Ledger | legacy | key | – | epic |
| 11 | `core_source_data` | Core Source Data | legacy | key | – | legendary |
| 12 | `experiment_log` | Experiment Log | legacy | key | – | epic |
| 13 | `exposure_report` | Exposure Report | legacy | key | – | epic |
| 14 | `facility_pass` | Core Facility Pass | legacy | key | – | epic |
| 15 | `forged_note` | Forged Delivery Note | legacy | key | – | rare |
| 16 | `money_trail` | Money Trail | legacy | key | – | epic |
| 17 | `torn_label` | Torn Shipping Label | legacy | key | – | uncommon |
| 18 | `waste_sample` | Waste Sample | legacy | key | – | epic |
| 19 | `refined_alloy` | Refined Alloy | legacy | material | – | rare |
| 20 | `scrap_metal` | Scrap Metal | legacy | material | – | common |
| 21 | `baron_furnace_core` | Furnace Baron's Core | catalog | material | boss_material | epic |
| 22 | `chen_anchor_link` | Harbourmaster's Anchor Link | catalog | material | boss_material | rare |
| 23 | `k7_reactor_cell` | K-7 Reactor Cell | catalog | material | boss_material | epic |
| 24 | `wiroj_protocol_chip` | Wiroj Protocol Chip | catalog | material | boss_material | epic |
| 25 | `enhance_catalyst_rare` | Rare Enhancement Catalyst | catalog | material | enhancement_material | epic |
| 26 | `enhance_catalyst_special` | Special Enhancement Catalyst | catalog | material | enhancement_material | legendary |
| 27 | `enhance_stone_advanced` | Advanced Enhancement Stone | catalog | material | enhancement_material | rare |
| 28 | `enhance_stone_basic` | Basic Enhancement Stone | catalog | material | enhancement_material | common |
| 29 | `enhance_stone_refined` | Refined Enhancement Stone | catalog | material | enhancement_material | uncommon |
| 30 | `mineral_azure` | Azure Mineral | catalog | material | ore | rare |
| 31 | `mineral_crimson` | Crimson Special Mineral | catalog | material | ore | legendary |
| 32 | `mineral_gilded` | Gilded Mineral | catalog | material | ore | epic |
| 33 | `mineral_rare` | Rare Mineral | catalog | material | ore | uncommon |
| 34 | `ore_copper` | Copper Ore | catalog | material | ore | common |
| 35 | `ore_iron` | Iron Ore | catalog | material | ore | common |
| 36 | `ore_refined` | Refined Ore | catalog | material | ore | uncommon |
| 37 | `founders_crimson_sigil` | Founder's Crimson Sigil | catalog | material | special | legendary |
| 38 | `iron_legacy_relic` | Iron Legacy Relic | catalog | material | special | epic |
