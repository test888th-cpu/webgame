# Item power balance proposal

**Status: design and simulation only.** No item stat, combat or enhancement
formula, item ID, drop rate, reward, world boss or raid table was changed. No
production item was created. Every ID below marked PROPOSAL is a design name
only. Every change listed waits for the owner's approval (§13).

Inputs:

- `client/data/items.json` and `item_catalog.json` as they stand in the working
  tree.
- `client/sim/ItemRules.gd` (the game's item power rule).
- `client/sim/PlayerProfile.gd` (stats and caps), `EnhanceRules.gd`,
  `CombatRules.gd` and `LevelRules.gd`.
- `docs/ITEM_POWER_AUDIT.md`.

Two kinds of result appear below, always labelled:

- **[Modeled]**: arithmetic with the game's formulas (stat totals, caps, damage
  taken per hit). Exact for what it covers. It is not a fight.
- **[Simulated]**: the game's real rules played automatically.
  - `ZoneSim` is played by `AutoPilot` for farming and boss fights.
  - `WorldBossRun` is used for world and raid bosses.
  - `ArenaSim` is played by `ArenaBrain` for PvP.
  - A temporary runner loaded each model's item stats **into memory only** and was
    deleted afterwards.
  - Seeds are fixed. Sample sizes are small (2–12 runs per cell), so treat
    differences under about 10% as noise.
  - Simulation is not play: `AutoPilot` and `ArenaBrain` stand in for players
    (see `docs/HARNESS.md`, "Limits").

## 1. The rule the game already uses, and what the audit got wrong

Every equipment item already has a power score and a budget (`ItemRules`):

- **Score** = Σ stat × weight. The weights are power 100, max_hp 0.5, defense 5,
  crit 200, attack_speed 150 and speed 100.
- **Budget** = (10 + 2 × level) × slot weight × grade weight.
  - Slot weights: weapon 1.3, body 0.92, charm 0.75, head 0.73, hands 0.66 and
    feet 0.55.
  - Grade weights: Common 0.85, Uncommon 1.0, Rare 1.15, Epic 1.35, Legendary 1.6
    and Godforged 2.2.
- `ContentDB` refuses any item more than 15% off its budget.
- Today all 267 equipment items are within −11% to +12%. All 14 Legendaries are
  within ±1.5%.

So the audit's "underpowered" items are **on budget**. Their weak *combat* value
has three causes:

1. **The grade weights.** They define today's 50 / 59 / 68 / 79 / 94 / 129 index.
2. **The stat weights.** Crit costs 200 per 1.0 but stops counting at a 50% total
   (§7). Movement speed costs 100 per 1.0 but adds nothing to damage or survival.
3. **Level coverage.** Legendary stops at Lv 48 (audit §5).

`docs/ITEM_POWER_AUDIT.md` now carries a correction section (§0) saying so. This
proposal therefore uses the game's own formula:

- **Power** means `ItemRules.score`.
- **Target** means `ItemRules.budget`.
- A model is a set of grade weights.
- The audit's combat-value metric is kept as a second view, labelled "value".

## 2. Model A and Model B compared

### 2.1 The models

- **M0:** today.
- **M0L:** today's weights plus the proposed Lv 55–70 Legendaries (§5). It shows
  what the coverage fix alone does.
- **MR:** the recommended starting point (§3).
- **MB and MA:** your Model B and Model A, anchored at Common (Common keeps its
  stats).

| Model | What it is | Common | Uncommon | Rare | Epic | Legendary | Godforged | Godforged change needed | Legendary below Godforged? |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| M0 | Today | 0.850 (50) | 1.000 (59) | 1.150 (68) | 1.350 (79) | 1.600 (94) | 2.200 (129) | none | yes |
| M0L | Today + Legendary Lv 55-70 | 0.850 (50) | 1.000 (59) | 1.150 (68) | 1.350 (79) | 1.600 (94) | 2.200 (129) | none | yes |
| MR | Recommended (Godforged frozen) | 0.850 (50) | 1.000 (59) | 1.220 (72) | 1.480 (87) | 1.800 (106) | 2.200 (129) | none | yes |
| MB | Model B (full) | 0.850 (50) | 1.105 (65) | 1.445 (85) | 1.870 (110) | 2.465 (145) | 3.230 (190) | ×1.47 (not approved; simulated in memory only) | yes |
| MA | Model A (full) | 0.850 (50) | 1.360 (80) | 2.040 (120) | 2.890 (170) | 4.250 (250) | 5.950 (350) | ×2.70 (not approved; simulated in memory only) | yes |

The number in brackets is the index against Common = 50.

| Model | Uncommon step | Rare step | Epic step | Legendary step | Godforged step | Common → Godforged |
|---|---:|---:|---:|---:|---:|---:|
| M0 | +18% | +15% | +17% | +19% | +38% | ×2.59 |
| MR | +18% | +22% | +21% | +22% | +22% | ×2.59 |
| MB | +30% | +31% | +29% | +32% | +31% | ×3.80 |
| MA | +60% | +50% | +42% | +47% | +40% | ×7.00 |

### 2.2 The constraint: Godforged is frozen

Godforged must keep its stats, and it must stay the top grade. With Common
anchored, Godforged sits at 2.2 / 0.85 = ×2.59 Common. That fixes the room for the
other four steps:

- Model B needs ×3.80 and Model A ×7.00.
- With Godforged frozen, both put Legendary **above** Godforged when anchored at
  Common (bold below).
- Anchored at Godforged instead, they cut Common to Epic by 13–41% (Model B) or
  20–49% (Model A). That is a nerf to almost every item players hold, and to the
  shop and starter gear the enemy curve was tuned for.

| Shape kept with Common = 0.85 and Godforged frozen at 2.2 | Uncommon | Rare | Epic | Legendary | Godforged |
|---|---:|---:|---:|---:|---:|
| Model B shape, Common-anchored | 1.10 | 1.45 | 1.87 | **2.46** | 2.2 (frozen) |
| Model B shape, Godforged-anchored | 0.75 | 0.98 | 1.27 | 1.68 | 2.2 |
| Model A shape, Common-anchored | 1.36 | 2.04 | 2.89 | **4.25** | 2.2 (frozen) |
| Model A shape, Godforged-anchored | 0.50 | 0.75 | 1.07 | 1.57 | 2.2 |


So Model B and Model A as written are possible only with Godforged raised: ×1.47
for B and ×2.70 for A. That breaks your preservation rule, so it is **listed for
approval only** (§10).

The simulations run B and A that way, in memory, so you can see what the curves
would do. Neither is applied.

### 2.3 Lv 70 full kits per model [Modeled]

- Hero: `riku` (the default hero) at Lv 70.
- Kit: the best item per slot of the grade at or below Lv 70.
- "Legendary" uses the best Legendary of each slot and falls back to Epic where
  none exists. Under M0 that means today's Lv 30–48 Legendaries plus Epic feet.
- Damage index = power × (1 + 0.5 × counted crit) × counted attack speed.
- EHP vs monsters = HP × 85 / max(1, 85 − defense). 85 is the median ordinary
  monster hit at Lv 70.
- Boss hit = 1.65 × that, the median boss move.
- PvP EHP = HP × 2 (the arena's `hp_scale`) × (1 + defense / 90).

| Model | Kit (best per slot, Lv 70) | + | Power | Max HP | Defense | Crit (worn → counted) | Attack speed (worn → counted) | Damage index | Monster hit taken (85 raw) | Boss hit taken (140 raw) | PvE EHP vs monsters | PvP EHP |
|---|---|---:|---:|---:|---:|---|---|---:|---:|---:|---:|---:|
| M0 | rare | 0 | 7.16 | 1179 | 41 | 0.66 → 0.50 | 1.15 → 1.15 | 10.29 | 44 | 99 | 2,284 | 3,432 |
| M0 | epic | 0 | 7.06 | 1306 | 52 | 0.75 → 0.50 | 1.18 → 1.18 | 10.41 | 33 | 88 | 3,379 | 4,121 |
| M0 | legendary | 0 | 6.46 | 1188 | 30 | 0.58 → 0.50 | 1.37 → 1.30 | 10.50 | 55 | 110 | 1,839 | 3,168 |
| M0 | godforged | 0 | 9.08 | 1596 | 71 | 1.10 → 0.50 | 1.98 → 1.30 | 14.76 | 14 | 69 | 9,831 | 5,710 |
| M0L | rare | 0 | 7.16 | 1179 | 41 | 0.66 → 0.50 | 1.15 → 1.15 | 10.29 | 44 | 99 | 2,284 | 3,432 |
| M0L | epic | 0 | 7.06 | 1306 | 52 | 0.75 → 0.50 | 1.18 → 1.18 | 10.41 | 33 | 88 | 3,379 | 4,121 |
| M0L | legendary | 0 | 7.45 | 1419 | 61 | 0.86 → 0.50 | 1.20 → 1.20 | 11.20 | 24 | 79 | 5,062 | 4,762 |
| M0L | godforged | 0 | 9.08 | 1596 | 71 | 1.10 → 0.50 | 1.98 → 1.30 | 14.76 | 14 | 69 | 9,831 | 5,710 |
| MR | rare | 0 | 7.32 | 1201 | 43 | 0.69 → 0.50 | 1.16 → 1.16 | 10.61 | 42 | 97 | 2,438 | 3,550 |
| MR | epic | 0 | 7.31 | 1354 | 57 | 0.81 → 0.50 | 1.20 → 1.20 | 10.93 | 28 | 83 | 4,134 | 4,423 |
| MR | legendary | 0 | 7.81 | 1496 | 70 | 0.95 → 0.50 | 1.23 → 1.23 | 12.01 | 15 | 70 | 8,591 | 5,319 |
| MR | godforged | 0 | 9.08 | 1596 | 71 | 1.10 → 0.50 | 1.98 → 1.30 | 14.76 | 14 | 69 | 9,831 | 5,710 |
| MB | rare | 0 | 7.84 | 1275 | 51 | 0.81 → 0.50 | 1.19 → 1.19 | 11.65 | 34 | 89 | 3,201 | 3,995 |
| MB | epic | 0 | 8.05 | 1499 | 71 | 1.01 → 0.50 | 1.25 → 1.25 | 12.56 | 14 | 69 | 9,234 | 5,363 |
| MB | legendary | 0 | 9.04 | 1752 | 96 | 1.28 → 0.50 | 1.31 → 1.30 | 14.68 | 1 | 44 | 148,500 | 7,242 |
| MB | godforged | 0 | 11.22 | 1966 | 104 | 1.58 → 0.50 | 2.44 → 1.30 | 18.24 | 1 | 36 | 166,638 | 8,476 |
| MA | rare | 0 | 9.22 | 1468 | 72 | 1.11 → 0.50 | 1.27 → 1.27 | 14.59 | 13 | 68 | 9,751 | 5,285 |
| MA | epic | 0 | 9.98 | 1878 | 111 | 1.51 → 0.50 | 1.39 → 1.30 | 16.22 | 1 | 29 | 159,179 | 8,388 |
| MA | legendary | 0 | 12.32 | 2439 | 164 | 2.14 → 0.50 | 1.54 → 1.30 | 20.02 | 1 | 1 | 206,730 | 13,767 |
| MA | godforged | 0 | 16.89 | 2944 | 191 | 2.84 → 0.50 | 3.65 → 1.30 | 27.44 | 1 | 1 | 249,533 | 18,384 |

What this shows:

- **Today (M0), the Lv 70 "Legendary" kit is not better than the Epic kit.**
  - Its damage is about equal (10.50 against 10.41), with less HP and defense.
  - That is the reported problem, measured.
- **Offence barely separates the grades in any model**, because crit and attack
  speed are capped.
  - Every Rare-or-better Lv 70 kit already reaches the 50% crit cap.
  - The power stat is the only offence that keeps scaling (§7).
- **Under MB, Legendary +0 already reaches the 1-damage floor against an average
  monster.** Under MA, Epic does. Past that point, extra defense is worthless
  against monsters and decisive in nothing else (§7).

## 3. Recommended target progression (a starting point; you choose)

**MR: Common 0.85, Uncommon 1.00, Rare 1.22, Epic 1.48, Legendary 1.80,
Godforged 2.20** (index 50 / 59 / 72 / 87 / 106 / 129).

Why MR:

- **Godforged frozen.** No reward, item or raid change.
- **Common and Uncommon unchanged.** The starter, shop, market and the enemy curve
  stay as tuned.
- **Even steps:** about +21% from Uncommon to Godforged, against today's uneven
  +15 / +17 / +19 / +38%.
- **Legendary rises from 94 to 106** and becomes a clear step over Epic (+22%).
  Godforged stays +22% over Legendary.
- **Implementation:**
  - Three numbers in `ItemRules.GRADES`.
  - A proportional rescale of every Rare, Epic and Legendary item: ×1.061, ×1.096
    and ×1.125 on positive stats.
  - Every item stays inside the 15% tolerance by construction.

What MR does not do: it cannot reach Model B's +30% steps. That needs Godforged
raised (§2.2).

**Middle path, for your call:**

- Raise Godforged ×1.2 (to 2.64) and use B-like steps of about +25% below it.
- Every Godforged and its world boss tuning would move.
- So it is listed as an option, not recommended.

## 4. Per-slot target stat budgets (MR)

`ItemRules.budget` points. One point = 0.01 power, 2 max_hp, 0.2 defense, 0.005
crit, 0.0067 attack_speed or 0.01 speed.

The example stat line keeps the stat mix of today's Lv 68 Epic of that slot. The
measured mix of all items is:

| Slot | Power | Max HP | Defense | Crit | Attack speed | Speed |
|---|---:|---:|---:|---:|---:|---:|
| weapon | 81% | – | – | 17% | 1% | – |
| head | – | 50% | 46% | 4% | – | – |
| body | – | 47% | 53% | – | – | – |
| hands | 53% | – | 18% | 24% | 5% | – |
| feet | – | 7% | 38% | – | 21% | 34% |
| charm | 16% | 56% | 3% | 20% | 5% | – |

Rules proposed with the budgets:

1. An item's score stays within ±15% of its budget. This is the existing rule.
2. Crit lives only in weapon, hands and charm (plus at most 5% in head). The sum of
   crit across a top-grade set stays under what can count (§7, option D).
3. Movement speed is a footwear specialisation. Combat value is not expected of it
   (§6.4).
4. From Lv 50, defense should take no more than about 50% of an item's budget. HP
   takes the rest, because flat defense reaches the 1-damage floor (§7).


**weapon** (slot weight 1.3)

| Grade | Lv 10 | Lv 30 | Lv 50 | Lv 70 | Example at Lv 70, MR (today's stat mix of the slot) |
|---|---:|---:|---:|---:|---|
| common | 33 | 77 | 122 | 166 | power 1.266, defense 1, crit 0.163 |
| uncommon | 39 | 91 | 143 | 195 | power 1.489, defense 2, crit 0.192 |
| rare | 48 | 111 | 174 | 238 | power 1.817, defense 2, crit 0.234 |
| epic | 58 | 135 | 212 | 289 | power 2.204, defense 2, crit 0.284 |
| legendary | 70 | 164 | 257 | 351 | power 2.681, defense 3, crit 0.345 |
| godforged | 86 | 200 | 315 | 429 | power 3.277, defense 3, crit 0.422 |

**head** (slot weight 0.73)

| Grade | Lv 10 | Lv 30 | Lv 50 | Lv 70 | Example at Lv 70, MR (today's stat mix of the slot) |
|---|---:|---:|---:|---:|---|
| common | 19 | 43 | 68 | 93 | defense 7, max_hp 96, crit 0.046 |
| uncommon | 22 | 51 | 80 | 110 | defense 8, max_hp 113, crit 0.054 |
| rare | 27 | 62 | 98 | 134 | defense 10, max_hp 138, crit 0.065 |
| epic | 32 | 76 | 119 | 162 | defense 12, max_hp 168, crit 0.079 |
| legendary | 39 | 92 | 145 | 197 | defense 15, max_hp 204, crit 0.096 |
| godforged | 48 | 112 | 177 | 241 | defense 19, max_hp 249, crit 0.118 |

**body** (slot weight 0.92)

| Grade | Lv 10 | Lv 30 | Lv 50 | Lv 70 | Example at Lv 70, MR (today's stat mix of the slot) |
|---|---:|---:|---:|---:|---|
| common | 23 | 55 | 86 | 117 | defense 12, max_hp 111 |
| uncommon | 28 | 64 | 101 | 138 | defense 15, max_hp 131 |
| rare | 34 | 79 | 123 | 168 | defense 18, max_hp 159 |
| epic | 41 | 95 | 150 | 204 | defense 21, max_hp 193 |
| legendary | 50 | 116 | 182 | 248 | defense 26, max_hp 235 |
| godforged | 61 | 142 | 223 | 304 | defense 32, max_hp 288 |

**hands** (slot weight 0.66)

| Grade | Lv 10 | Lv 30 | Lv 50 | Lv 70 | Example at Lv 70, MR (today's stat mix of the slot) |
|---|---:|---:|---:|---:|---|
| common | 17 | 39 | 62 | 84 | power 0.395, defense 4, crit 0.128 |
| uncommon | 20 | 46 | 73 | 99 | power 0.465, defense 4, crit 0.15 |
| rare | 24 | 56 | 89 | 121 | power 0.567, defense 5, crit 0.183 |
| epic | 29 | 68 | 107 | 147 | power 0.688, defense 7, crit 0.222 |
| legendary | 36 | 83 | 131 | 178 | power 0.837, defense 8, crit 0.27 |
| godforged | 44 | 102 | 160 | 218 | power 1.023, defense 10, crit 0.33 |

**feet** (slot weight 0.55)

| Grade | Lv 10 | Lv 30 | Lv 50 | Lv 70 | Example at Lv 70, MR (today's stat mix of the slot) |
|---|---:|---:|---:|---:|---|
| common | 14 | 33 | 51 | 70 | speed 0.262, defense 5, attack_speed 0.118 |
| uncommon | 16 | 38 | 61 | 82 | speed 0.308, defense 6, attack_speed 0.139 |
| rare | 20 | 47 | 74 | 101 | speed 0.376, defense 8, attack_speed 0.169 |
| epic | 24 | 57 | 90 | 122 | speed 0.456, defense 9, attack_speed 0.205 |
| legendary | 30 | 69 | 109 | 148 | speed 0.555, defense 11, attack_speed 0.25 |
| godforged | 36 | 85 | 133 | 182 | speed 0.679, defense 14, attack_speed 0.305 |

**charm** (slot weight 0.75)

| Grade | Lv 10 | Lv 30 | Lv 50 | Lv 70 | Example at Lv 70, MR (today's stat mix of the slot) |
|---|---:|---:|---:|---:|---|
| common | 19 | 45 | 70 | 96 | max_hp 119, defense 3, crit 0.098 |
| uncommon | 22 | 52 | 82 | 112 | max_hp 140, defense 4, crit 0.116 |
| rare | 27 | 64 | 101 | 137 | max_hp 171, defense 5, crit 0.141 |
| epic | 33 | 78 | 122 | 166 | max_hp 208, defense 6, crit 0.171 |
| legendary | 40 | 94 | 148 | 202 | max_hp 252, defense 7, crit 0.208 |
| godforged | 50 | 116 | 182 | 248 | max_hp 309, defense 8, crit 0.254 |

## 5. Legendary Lv 49–70 progression plan (PROPOSALS)

### 5.1 The items

Today the four Lv 55–70 lairs each have one mini-boss dropping its tier's six
Epics at 15%. Those are `arthit_reinstated`, `twelve_relapsed`, `k7_overdriven`
and `wiroj_protocol`.

The proposal adds **12 Legendary pieces**: three per lair mini-boss, at the lair's
level. The slots alternate, so every slot gets a Legendary at least every 10
levels from Lv 55 to 70:

- Lv 55 and 65: weapon, hands and feet.
- Lv 60 and 70: head, body and charm.
- Feet, which has no Legendary today, gets one at Lv 55 and one at Lv 65.

How the items are built:

- **Stats:** the item's budget (MR) with the stat mix of the same tier's Epic.
  This is how `tools/content/level70_content.py` prices gear.
- **Names:** to be written from `docs/STORY_BIBLE.md` (story names are not
  invented here).
- **Proposed source:** a 6% pity drop like the story-boss Legendaries. That is a
  drop change, so it needs its own approval.
- **The IDs are proposals only.** No item exists.

| Proposed ID (PROPOSAL) | Lv | Slot | Proposed source (needs approval) | Stats, MR | Score MR | Same-tier Epic (MR) | Epic score MR | Leg ÷ Epic | Godforged same slot (Lv 70) | Leg ÷ Godforged | Value at own Lv: Epic → Legendary (MR) | Stats under M0L / MB / MA |
|---|---:|---|---|---|---:|---|---:|---:|---|---:|---|---|
| `coolant_legendary_weapon` | 55 | weapon | `arthit_reinstated` (lair Lv 55), pity drop like the story Legendaries | power 2.123, defense 3, crit 0.274 | 282 | `coolant_epic_weapon` (Lv 53): power 1.699, defense 2, crit 0.219 | 224 | 1.26 | `sovereign_fists`: power 3.16, crit 0.35, attack_speed 0.28 | 0.66 | 68% → 87% | power 1.887, defense 2, crit 0.244 / power 2.907, defense 4, crit 0.375 / power 5.013, defense 6, crit 0.647 |
| `coolant_legendary_hands` | 55 | hands | `arthit_reinstated` (lair Lv 55), pity drop like the story Legendaries | power 0.692, defense 6, crit 0.226 | 144 | `coolant_epic_hands` (Lv 53): power 0.537, defense 4, crit 0.175 | 109 | 1.33 | `sovereign_grips`: power 0.95, defense 8, crit 0.28, attack_speed 0.18 | 0.66 | 33% → 45% | power 0.615, defense 5, crit 0.201 / power 0.947, defense 8, crit 0.309 / power 1.633, defense 13, crit 0.533 |
| `coolant_legendary_feet` | 55 | feet | `arthit_reinstated` (lair Lv 55), pity drop like the story Legendaries | speed 0.432, defense 9, attack_speed 0.189 | 117 | `coolant_epic_feet` (Lv 53): speed 0.351, defense 8, attack_speed 0.153 | 98 | 1.19 | `sovereign_treads`: speed 0.64, defense 13, attack_speed 0.34 | 0.65 | 31% → 37% | speed 0.384, defense 8, attack_speed 0.168 / speed 0.592, defense 13, attack_speed 0.259 / speed 1.02, defense 22, attack_speed 0.446 |
| `underworks_legendary_head` | 60 | head | `twelve_relapsed` (lair Lv 60), pity drop like the story Legendaries | defense 14, max_hp 173, crit 0.082 | 173 | `underworks_epic_head` (Lv 58): defense 11, max_hp 139, crit 0.066 | 138 | 1.26 | `sovereign_crown`: defense 17, max_hp 223, crit 0.21 | 0.72 | 47% → 60% | defense 12, max_hp 154, crit 0.073 / defense 19, max_hp 237, crit 0.112 / defense 32, max_hp 408, crit 0.193 |
| `underworks_legendary_body` | 60 | body | `twelve_relapsed` (lair Lv 60), pity drop like the story Legendaries | defense 23, max_hp 200 | 215 | `underworks_epic_body` (Lv 58): defense 19, max_hp 162 | 176 | 1.22 | `sovereign_mantle`: defense 32, max_hp 292 | 0.70 | 68% → 86% | defense 20, max_hp 178 / defense 32, max_hp 274 / defense 54, max_hp 473 |
| `underworks_legendary_charm` | 60 | charm | `twelve_relapsed` (lair Lv 60), pity drop like the story Legendaries | max_hp 213, defense 7, crit 0.176 | 177 | `underworks_epic_charm` (Lv 58): max_hp 173, defense 5, crit 0.143 | 140 | 1.26 | `sovereign_seal`: max_hp 276, power 0.47, crit 0.18, attack_speed 0.18 | 0.71 | 44% → 56% | max_hp 190, defense 6, crit 0.156 / max_hp 292, defense 9, crit 0.24 / max_hp 504, defense 16, crit 0.414 |
| `foundry_legendary_weapon` | 65 | weapon | `k7_overdriven` (lair Lv 65), pity drop like the story Legendaries | power 2.502, defense 3, crit 0.318 | 329 | `foundry_epic_weapon` (Lv 63): power 1.984, defense 2, crit 0.252 | 259 | 1.27 | `sovereign_fists`: power 3.16, crit 0.35, attack_speed 0.28 | 0.77 | 72% → 92% | power 2.224, defense 2, crit 0.283 / power 3.426, defense 4, crit 0.435 / power 5.907, defense 7, crit 0.751 |
| `foundry_legendary_hands` | 65 | hands | `k7_overdriven` (lair Lv 65), pity drop like the story Legendaries | power 0.811, defense 7, crit 0.252 | 166 | `foundry_epic_hands` (Lv 63): power 0.636, defense 5, crit 0.197 | 128 | 1.30 | `sovereign_grips`: power 0.95, defense 8, crit 0.28, attack_speed 0.18 | 0.76 | 36% → 47% | power 0.721, defense 6, crit 0.224 / power 1.11, defense 10, crit 0.345 / power 1.914, defense 16, crit 0.594 |
| `foundry_legendary_feet` | 65 | feet | `k7_overdriven` (lair Lv 65), pity drop like the story Legendaries | speed 0.5, defense 11, attack_speed 0.23 | 140 | `foundry_epic_feet` (Lv 63): speed 0.406, defense 9, attack_speed 0.186 | 114 | 1.23 | `sovereign_treads`: speed 0.64, defense 13, attack_speed 0.34 | 0.78 | 34% → 43% | speed 0.445, defense 10, attack_speed 0.204 / speed 0.685, defense 15, attack_speed 0.315 / speed 1.181, defense 26, attack_speed 0.543 |
| `heart_legendary_head` | 70 | head | `wiroj_protocol` (lair Lv 70), pity drop like the story Legendaries | defense 15, max_hp 204, crit 0.096 | 196 | `heart_epic_head` (Lv 68): defense 12, max_hp 162, crit 0.077 | 156 | 1.25 | `sovereign_crown`: defense 17, max_hp 223, crit 0.21 | 0.82 | 47% → 60% | defense 13, max_hp 181, crit 0.086 / defense 21, max_hp 279, crit 0.132 / defense 36, max_hp 482, crit 0.228 |
| `heart_legendary_body` | 70 | body | `wiroj_protocol` (lair Lv 70), pity drop like the story Legendaries | defense 26, max_hp 235 | 248 | `heart_epic_body` (Lv 68): defense 21, max_hp 187 | 198 | 1.25 | `sovereign_mantle`: defense 32, max_hp 292 | 0.81 | 66% → 86% | defense 23, max_hp 209 / defense 36, max_hp 322 / defense 62, max_hp 556 |
| `heart_legendary_charm` | 70 | charm | `wiroj_protocol` (lair Lv 70), pity drop like the story Legendaries | max_hp 252, defense 7, crit 0.208 | 203 | `heart_epic_charm` (Lv 68): max_hp 200, defense 5, crit 0.164 | 158 | 1.28 | `sovereign_seal`: max_hp 276, power 0.47, crit 0.18, attack_speed 0.18 | 0.82 | 45% → 58% | max_hp 224, defense 6, crit 0.185 / max_hp 346, defense 9, crit 0.285 / max_hp 596, defense 16, crit 0.491 |

### 5.2 Footwear

- `coolant_legendary_feet` (Lv 55) and `foundry_legendary_feet` (Lv 65) follow the
  Epic feet mix: speed, defense and attack speed.
- Two cautions:
  - Attack speed: the feet alone carry 0.19–0.23. With weapon, hands and charm
    the set passes the +0.3 cap (§7).
  - Movement speed is not combat value.
- Alternative mix for approval (option F2): the same budget as defense 40%, HP
  30% and attack speed 30%, with no movement speed. That suits the "tank boots"
  role the audit found valuable early.
- An earlier Legendary feet item (Lv 40, `commander_arthit`) is possible but adds
  a source to a story boss. Not proposed by default.

### 5.3 Upgrade paths after the proposal (MR)

**Bold** = proposed.

| Slot | Upgrade path at Lv 40–70 after the proposal (grade, Lv) |
|---|---|
| weapon | God 50 → Epi 53 → **Leg 55** → Epi 58 → God 60 → Epi 63 → God 64 → **Leg 65** → Epi 68 → God 70 → God 70 |
| head | Epi 42 → Leg 48 → Epi 53 → God 56 → Epi 58 → **Leg 60** → Epi 63 → Epi 68 → **Leg 70** → God 70 → God 70 |
| body | Epi 42 → Epi 48 → God 50 → Epi 53 → God 56 → Epi 58 → **Leg 60** → Epi 63 → Epi 68 → **Leg 70** → God 70 → God 70 |
| hands | God 45 → Epi 53 → **Leg 55** → Epi 58 → God 60 → Epi 63 → God 64 → **Leg 65** → Epi 68 → God 70 |
| feet | Epi 53 → **Leg 55** → God 56 → Epi 58 → Epi 63 → **Leg 65** → Epi 68 → God 70 |
| charm | God 45 → Leg 48 → Leg 48 → Epi 53 → Epi 58 → **Leg 60** → God 60 → Epi 63 → God 64 → Epi 68 → **Leg 70** → God 70 → God 70 |

Remaining gap: Legendary body runs Lv 30 → 60. An optional Lv 45 body from
`spillway_chief` would close it. It is not included; it needs approval.

## 6. Corrections to existing equipment (MR; no data changed)

"Value" is the combat value from the audit (§2.3 there), at the item's own level.
"Score" is `ItemRules.score`. The proposed stats are the current stats × the grade
ratio (MR ÷ today), so each item keeps its stat mix and its place within the 15%
tolerance.

### 6.1 The 10 Legendaries the audit flagged (plus the other 4)

Scaling alone (×1.125) raises these by 12.5% in score. The audit's targets
(Model B, combat value) are not all met, for two reasons:

- Part of each item's budget is crit. At its level, crit is worth less than the
  power, HP or defense it could have been.
- Model B's targets assumed Godforged could rise.

Option L-R ("re-mix", for approval): move crit beyond 0.05 per item into power
(weapon and hands) or HP (head and charm) at `ItemRules` prices. That lifts combat
value without changing the score.

| Item ID | Slot | Lv | Current stats | Proposed stats (MR) | Score now → MR | Budget now → MR | Value now → MR | Same-band median of the grade below, MR | Same-band median of the grade above, MR |
|---|---|---:|---|---|---|---|---|---:|---:|
| `baron_knuckledusters` | weapon | 9 | power 0.36, max_hp 16, crit 0.07 | power 0.405, max_hp 18, crit 0.079 | 58.0 → 65.3 | 58.2 → 65.5 | 41% → 46% | 37% | – |
| `harbour_hook` | weapon | 15 | power 0.55, max_hp 25, crit 0.08 | power 0.619, max_hp 28, crit 0.09 | 83.5 → 93.9 | 83.2 → 93.6 | 51% → 58% | 37% | – |
| `crimson_warlord_fists` | weapon | 30 | power 1.16, crit 0.146 | power 1.305, crit 0.164 | 145.2 → 163.3 | 145.6 → 163.8 | 58% → 66% | 48% | 82% |
| `arthit_baton` | weapon | 39 | power 1.35, crit 0.15, attack_speed 0.12 | power 1.519, crit 0.169, attack_speed 0.135 | 183.0 → 205.9 | 183.0 → 205.9 | 76% → 88% | 68% | 126% |
| `ringmaster_topper` | head | 27 | defense 5, max_hp 70, crit 0.07 | defense 6, max_hp 79, crit 0.079 | 74.0 → 85.3 | 74.8 → 84.1 | 40% → 48% | 44% | – |
| `crimson_warlord_helm` | head | 30 | defense 10, max_hp 64 | defense 11, max_hp 72 | 82.0 → 91.0 | 81.8 → 92.0 | 51% → 58% | 44% | – |
| `lion_king_crown` | head | 30 | defense 10, max_hp 64 | defense 11, max_hp 72 | 82.0 → 91.0 | 81.8 → 92.0 | 51% → 58% | 44% | – |
| `director_crown` | head | 48 | defense 9, max_hp 115, crit 0.11 | defense 10, max_hp 129, crit 0.124 | 124.5 → 139.3 | 123.8 → 139.3 | 48% → 55% | 45% | – |
| `crimson_warlord_mantle` | body | 30 | max_hp 113, defense 9 | max_hp 127, defense 10 | 101.5 → 113.5 | 103.0 → 115.9 | 62% → 71% | 57% | – |
| `subject_grips` | hands | 35 | power 0.37, defense 3, crit 0.11, attack_speed 0.07 | power 0.416, defense 3, crit 0.124, attack_speed 0.079 | 84.5 → 93.2 | 84.5 → 95.0 | 37% → 41% | 24% | – |
| `k7_core_plate` | charm | 23 | max_hp 65, power 0.15, attack_speed 0.13 | max_hp 73, power 0.169, attack_speed 0.146 | 67.0 → 75.3 | 67.2 → 75.6 | 45% → 51% | 38% | 69% |
| `sak_signet` | charm | 31 | max_hp 90, power 0.19, crit 0.11 | max_hp 101, power 0.214, crit 0.124 | 86.0 → 96.7 | 86.4 → 97.2 | 38% → 43% | 38% | 69% |
| `director_signet` | charm | 48 | max_hp 155, power 0.24, crit 0.13 | max_hp 174, power 0.27, crit 0.146 | 127.5 → 143.2 | 127.2 → 143.1 | 44% → 50% | 42% | 82% |
| `heart_of_iron_city` | charm | 48 | max_hp 140, power 0.24, crit 0.09, attack_speed 0.09 | max_hp 158, power 0.27, crit 0.101, attack_speed 0.101 | 125.5 → 141.3 | 127.2 → 143.1 | 51% → 59% | 42% | 82% |

### 6.2 Epic (all 51; MR ×1.096)

| Item ID | Slot | Lv | Current stats | Proposed stats (MR) | Score now → MR | Budget now → MR | Value now → MR | Same-band median of the grade below, MR | Same-band median of the grade above, MR |
|---|---|---:|---|---|---|---|---|---:|---:|
| `foreman_wrench` | weapon | 5 | power 0.31, max_hp 9 | power 0.34, max_hp 10 | 35.5 → 39.0 | 35.1 → 38.5 | 33% → 37% | 34% | 52% |
| `chiefs_baton` | weapon | 21 | power 0.68, defense 1, crit 0.09 | power 0.745, defense 1, crit 0.099 | 91.0 → 99.3 | 91.3 → 100.0 | 44% → 48% | – | 66% |
| `gilded_crusher_gauntlets` | weapon | 22 | power 0.76, crit 0.095 | power 0.833, crit 0.104 | 95.0 → 104.1 | 94.8 → 103.9 | 44% → 48% | – | 66% |
| `ringmaster_wraps` | weapon | 27 | power 0.85, defense 1, crit 0.11 | power 0.932, defense 1, crit 0.121 | 112.0 → 122.4 | 112.3 → 123.1 | 48% → 53% | – | 66% |
| `coolant_epic_weapon` | weapon | 53 | power 1.55, defense 2, crit 0.2 | power 1.699, defense 2, crit 0.219 | 205.0 → 223.7 | 203.6 → 223.2 | 62% → 68% | 51% | 88% |
| `underworks_epic_weapon` | weapon | 58 | power 1.68, defense 2, crit 0.22 | power 1.842, defense 2, crit 0.241 | 222.0 → 242.4 | 221.1 → 242.4 | 64% → 70% | 57% | – |
| `foundry_epic_weapon` | weapon | 63 | power 1.81, defense 2, crit 0.23 | power 1.984, defense 2, crit 0.252 | 237.0 → 258.8 | 238.7 → 261.7 | 65% → 72% | 57% | – |
| `heart_epic_weapon` | weapon | 68 | power 1.94, defense 2, crit 0.25 | power 2.127, defense 2, crit 0.274 | 254.0 → 277.5 | 256.2 → 280.9 | 67% → 73% | 57% | – |
| `champion_headband` | head | 7 | max_hp 30, crit 0.04 | max_hp 33, crit 0.044 | 23.0 → 25.3 | 23.7 → 25.9 | 19% → 21% | 30% | – |
| `harbourmaster_cap` | head | 15 | defense 3, max_hp 40, crit 0.02 | defense 3, max_hp 44, crit 0.022 | 39.0 → 41.4 | 39.4 → 43.2 | 31% → 33% | 30% | – |
| `dragonscale_hood` | head | 22 | defense 6, max_hp 46 | defense 7, max_hp 50 | 53.0 → 60.0 | 53.2 → 58.3 | 38% → 44% | 31% | 58% |
| `gilded_brawler_helm` | head | 22 | defense 6, max_hp 46 | defense 7, max_hp 50 | 53.0 → 60.0 | 53.2 → 58.3 | 38% → 44% | 31% | 58% |
| `glacier_crown` | head | 22 | defense 6, max_hp 46 | defense 7, max_hp 50 | 53.0 → 60.0 | 53.2 → 58.3 | 38% → 44% | 31% | 58% |
| `jewelled_crown` | head | 22 | defense 6, max_hp 46 | defense 7, max_hp 50 | 53.0 → 60.0 | 53.2 → 58.3 | 38% → 44% | 31% | 58% |
| `obsidian_crown` | head | 22 | defense 6, max_hp 46 | defense 7, max_hp 50 | 53.0 → 60.0 | 53.2 → 58.3 | 38% → 44% | 31% | 58% |
| `phoenix_feather_hat` | head | 22 | defense 6, max_hp 46 | defense 7, max_hp 50 | 53.0 → 60.0 | 53.2 → 58.3 | 38% → 44% | 31% | 58% |
| `phoenix_tiara` | head | 22 | defense 6, max_hp 46 | defense 7, max_hp 50 | 53.0 → 60.0 | 53.2 → 58.3 | 38% → 44% | 31% | 58% |
| `spillway_epic_head` | head | 42 | defense 7, max_hp 95, crit 0.05 | defense 8, max_hp 104, crit 0.055 | 92.5 → 103.0 | 92.6 → 101.6 | 38% → 44% | 34% | 55% |
| `coolant_epic_head` | head | 53 | defense 9, max_hp 117, crit 0.06 | defense 10, max_hp 128, crit 0.066 | 115.5 → 127.2 | 114.3 → 125.3 | 41% → 46% | 34% | 55% |
| `underworks_epic_head` | head | 58 | defense 10, max_hp 127, crit 0.06 | defense 11, max_hp 139, crit 0.066 | 125.5 → 137.7 | 124.2 → 136.1 | 42% → 47% | 39% | – |
| `foundry_epic_head` | head | 63 | defense 10, max_hp 137, crit 0.07 | defense 11, max_hp 150, crit 0.077 | 132.5 → 145.4 | 134.0 → 146.9 | 41% → 46% | 39% | – |
| `heart_epic_head` | head | 68 | defense 11, max_hp 148, crit 0.07 | defense 12, max_hp 162, crit 0.077 | 143.0 → 156.4 | 143.9 → 157.7 | 42% → 47% | 39% | – |
| `smelter_apron` | body | 9 | defense 3, max_hp 40 | defense 3, max_hp 44 | 35.0 → 37.0 | 34.8 → 38.1 | 40% → 43% | 38% | – |
| `gilded_fight_robe` | body | 22 | max_hp 74, defense 6 | max_hp 81, defense 7 | 67.0 → 75.5 | 67.1 → 73.5 | 48% → 56% | 44% | 71% |
| `k7_plating` | body | 23 | defense 7, max_hp 70 | defense 8, max_hp 77 | 70.0 → 78.5 | 69.6 → 76.2 | 50% → 58% | 44% | 71% |
| `spillway_epic_body` | body | 42 | defense 12, max_hp 110 | defense 13, max_hp 121 | 115.0 → 125.5 | 116.7 → 128.0 | 54% → 61% | 52% | – |
| `director_coat` | body | 48 | defense 14, max_hp 125 | defense 15, max_hp 137 | 132.5 → 143.5 | 131.7 → 144.3 | 57% → 63% | 52% | – |
| `coolant_epic_body` | body | 53 | defense 15, max_hp 136 | defense 16, max_hp 149 | 143.0 → 154.5 | 144.1 → 157.9 | 56% → 62% | 52% | – |
| `underworks_epic_body` | body | 58 | defense 17, max_hp 148 | defense 19, max_hp 162 | 159.0 → 176.0 | 156.5 → 171.6 | 59% → 68% | 52% | – |
| `foundry_epic_body` | body | 63 | defense 18, max_hp 159 | defense 20, max_hp 174 | 169.5 → 187.0 | 168.9 → 185.2 | 58% → 67% | 52% | – |
| `heart_epic_body` | body | 68 | defense 19, max_hp 171 | defense 21, max_hp 187 | 180.5 → 198.5 | 181.3 → 198.8 | 58% → 66% | 52% | – |
| `champion_wraps` | hands | 7 | power 0.09, crit 0.04, attack_speed 0.03 | power 0.099, crit 0.044, attack_speed 0.033 | 21.5 → 23.6 | 21.4 → 23.4 | 12% → 14% | 13% | – |
| `chiefs_gloves` | hands | 21 | power 0.22, defense 2, crit 0.07 | power 0.241, defense 2, crit 0.077 | 46.0 → 49.5 | 46.3 → 50.8 | 22% → 24% | 21% | 41% |
| `coolant_epic_hands` | hands | 53 | power 0.49, defense 4, crit 0.16 | power 0.537, defense 4, crit 0.175 | 101.0 → 108.7 | 103.4 → 113.3 | 30% → 33% | 26% | – |
| `underworks_epic_hands` | hands | 58 | power 0.54, defense 5, crit 0.17 | power 0.592, defense 5, crit 0.186 | 113.0 → 121.4 | 112.3 → 123.1 | 33% → 35% | 29% | – |
| `foundry_epic_hands` | hands | 63 | power 0.58, defense 5, crit 0.18 | power 0.636, defense 5, crit 0.197 | 119.0 → 128.0 | 121.2 → 132.8 | 33% → 36% | 29% | – |
| `heart_epic_hands` | hands | 68 | power 0.62, defense 6, crit 0.2 | power 0.68, defense 7, crit 0.219 | 132.0 → 146.8 | 130.1 → 142.6 | 36% → 40% | 29% | – |
| `foreman_boots` | feet | 3 | defense 1, max_hp 7, speed 0.03 | defense 1, max_hp 8, speed 0.033 | 11.5 → 12.3 | 11.9 → 13.0 | 13% → 13% | 12% | – |
| `dockmaster_boots` | feet | 15 | speed 0.1, defense 2, max_hp 20 | speed 0.11, defense 2, max_hp 22 | 30.0 → 32.0 | 29.7 → 32.6 | 16% → 17% | 12% | – |
| `sak_loafers` | feet | 31 | speed 0.2, defense 4, attack_speed 0.09 | speed 0.219, defense 4, attack_speed 0.099 | 53.5 → 56.8 | 53.5 → 58.6 | 20% → 21% | 19% | – |
| `commander_greaves` | feet | 39 | speed 0.24, defense 5, attack_speed 0.11 | speed 0.263, defense 5, attack_speed 0.121 | 65.5 → 69.5 | 65.3 → 71.6 | 23% → 24% | 24% | – |
| `coolant_epic_feet` | feet | 53 | speed 0.32, defense 7, attack_speed 0.14 | speed 0.351, defense 8, attack_speed 0.153 | 88.0 → 98.0 | 86.1 → 94.4 | 27% → 31% | 24% | – |
| `underworks_epic_feet` | feet | 58 | speed 0.34, defense 7, attack_speed 0.16 | speed 0.373, defense 8, attack_speed 0.175 | 93.0 → 103.5 | 93.6 → 102.6 | 28% → 32% | 26% | – |
| `foundry_epic_feet` | feet | 63 | speed 0.37, defense 8, attack_speed 0.17 | speed 0.406, defense 9, attack_speed 0.186 | 102.5 → 113.5 | 101.0 → 110.7 | 30% → 34% | 26% | – |
| `heart_epic_feet` | feet | 68 | speed 0.4, defense 8, attack_speed 0.18 | speed 0.439, defense 9, attack_speed 0.197 | 107.0 → 118.5 | 108.4 → 118.8 | 31% → 34% | 26% | – |
| `jade_charm` | charm | 8 | max_hp 25, power 0.05, attack_speed 0.06 | max_hp 27, power 0.055, attack_speed 0.066 | 26.5 → 28.9 | 26.3 → 28.9 | 25% → 27% | 18% | – |
| `subject_band` | charm | 35 | max_hp 100, defense 3, crit 0.08 | max_hp 110, defense 3, crit 0.088 | 81.0 → 87.6 | 81.0 → 88.8 | 35% → 38% | 26% | 47% |
| `coolant_epic_charm` | charm | 53 | max_hp 145, defense 4, crit 0.12 | max_hp 159, defense 4, crit 0.132 | 116.5 → 125.9 | 117.5 → 128.8 | 38% → 42% | 33% | 55% |
| `underworks_epic_charm` | charm | 58 | max_hp 158, defense 5, crit 0.13 | max_hp 173, defense 5, crit 0.143 | 130.0 → 140.1 | 127.6 → 139.9 | 41% → 44% | 36% | – |
| `foundry_epic_charm` | charm | 63 | max_hp 170, defense 5, crit 0.14 | max_hp 186, defense 5, crit 0.153 | 138.0 → 148.6 | 137.7 → 151.0 | 41% → 44% | 36% | – |
| `heart_epic_charm` | charm | 68 | max_hp 182, defense 5, crit 0.15 | max_hp 200, defense 5, crit 0.164 | 146.0 → 157.8 | 147.8 → 162.1 | 41% → 45% | 36% | – |

### 6.3 Rare (all 46; MR ×1.061)

| Item ID | Slot | Lv | Current stats | Proposed stats (MR) | Score now → MR | Budget now → MR | Value now → MR | Same-band median of the grade below, MR | Same-band median of the grade above, MR |
|---|---|---:|---|---|---|---|---|---:|---:|
| `azure_steel_knuckles` | weapon | 15 | power 0.48, crit 0.06 | power 0.509, crit 0.064 | 60.0 → 63.7 | 59.8 → 63.4 | 32% → 34% | 25% | 37% |
| `night_shift_crowbar` | weapon | 38 | power 1.04, crit 0.12 | power 1.103, crit 0.127 | 128.0 → 135.7 | 128.6 → 136.4 | 45% → 48% | 42% | 68% |
| `coolant_rare_weapon` | weapon | 53 | power 1.41, crit 0.16 | power 1.496, crit 0.17 | 173.0 → 183.6 | 173.4 → 184.0 | 50% → 54% | 42% | 68% |
| `underworks_rare_weapon` | weapon | 58 | power 1.53, crit 0.18 | power 1.623, crit 0.191 | 189.0 → 200.5 | 188.4 → 199.8 | 52% → 56% | 46% | 72% |
| `foundry_rare_weapon` | weapon | 63 | power 1.65, crit 0.19 | power 1.75, crit 0.202 | 203.0 → 215.4 | 203.3 → 215.7 | 54% → 57% | 46% | 72% |
| `heart_rare_weapon` | weapon | 68 | power 1.77, crit 0.2 | power 1.878, crit 0.212 | 217.0 → 230.2 | 218.3 → 231.6 | 55% → 58% | 46% | 72% |
| `watchmans_cap` | head | 10 | defense 3, max_hp 25 | defense 3, max_hp 27 | 27.5 → 28.5 | 25.2 → 26.7 | 30% → 31% | 22% | 27% |
| `arcane_wizard_hat` | head | 15 | defense 4, max_hp 27 | defense 4, max_hp 29 | 33.5 → 34.5 | 33.6 → 35.6 | 29% → 30% | 22% | 27% |
| `crystal_tiara` | head | 15 | defense 4, max_hp 27 | defense 4, max_hp 29 | 33.5 → 34.5 | 33.6 → 35.6 | 29% → 30% | 22% | 27% |
| `cyber_visor` | head | 15 | defense 4, max_hp 27 | defense 4, max_hp 29 | 33.5 → 34.5 | 33.6 → 35.6 | 29% → 30% | 22% | 27% |
| `ice_crown` | head | 15 | defense 4, max_hp 27 | defense 4, max_hp 29 | 33.5 → 34.5 | 33.6 → 35.6 | 29% → 30% | 22% | 27% |
| `riveted_work_helmet` | head | 15 | defense 4, max_hp 27 | defense 4, max_hp 29 | 33.5 → 34.5 | 33.6 → 35.6 | 29% → 30% | 22% | 27% |
| `sakura_wizard_hat` | head | 15 | defense 4, max_hp 27 | defense 4, max_hp 29 | 33.5 → 34.5 | 33.6 → 35.6 | 29% → 30% | 22% | 27% |
| `starlight_wizard_hat` | head | 15 | defense 4, max_hp 27 | defense 4, max_hp 29 | 33.5 → 34.5 | 33.6 → 35.6 | 29% → 30% | 22% | 27% |
| `runners_cap` | head | 30 | defense 5, max_hp 50, crit 0.04 | defense 5, max_hp 53, crit 0.042 | 58.0 → 59.9 | 58.8 → 62.3 | 30% → 31% | 27% | 44% |
| `coolant_rare_head` | head | 53 | defense 8, max_hp 84, crit 0.07 | defense 8, max_hp 89, crit 0.074 | 96.0 → 99.3 | 97.4 → 103.3 | 33% → 34% | 29% | 45% |
| `underworks_rare_head` | head | 58 | defense 9, max_hp 91, crit 0.07 | defense 10, max_hp 97, crit 0.074 | 104.5 → 113.3 | 105.8 → 112.2 | 34% → 37% | 29% | 47% |
| `foundry_rare_head` | head | 63 | defense 10, max_hp 98, crit 0.08 | defense 11, max_hp 104, crit 0.085 | 115.0 → 124.0 | 114.2 → 121.1 | 35% → 39% | 29% | 47% |
| `heart_rare_head` | head | 68 | defense 11, max_hp 106, crit 0.08 | defense 12, max_hp 112, crit 0.085 | 124.0 → 133.0 | 122.6 → 130.0 | 36% → 39% | 29% | 47% |
| `night_market_jacket` | body | 7 | defense 3, max_hp 25 | defense 3, max_hp 27 | 27.5 → 28.5 | 25.4 → 26.9 | 35% → 37% | 26% | 43% |
| `riveted_dock_coat` | body | 15 | max_hp 47, defense 4 | max_hp 50, defense 4 | 43.5 → 45.0 | 42.3 → 44.9 | 39% → 40% | 26% | 43% |
| `pims_field_vest` | body | 24 | defense 7, max_hp 55 | defense 7, max_hp 58 | 62.5 → 64.0 | 61.4 → 65.1 | 43% → 44% | 36% | 57% |
| `coolant_rare_body` | body | 53 | defense 14, max_hp 108 | defense 15, max_hp 115 | 124.0 → 132.5 | 122.7 → 130.2 | 48% → 52% | 39% | 62% |
| `underworks_rare_body` | body | 58 | defense 15, max_hp 117 | defense 16, max_hp 124 | 133.5 → 142.0 | 133.3 → 141.4 | 48% → 52% | 40% | 67% |
| `foundry_rare_body` | body | 63 | defense 16, max_hp 127 | defense 17, max_hp 135 | 143.5 → 152.5 | 143.9 → 152.6 | 48% → 52% | 40% | 67% |
| `heart_rare_body` | body | 68 | defense 17, max_hp 136 | defense 18, max_hp 144 | 153.0 → 162.0 | 154.5 → 163.9 | 48% → 51% | 40% | 67% |
| `odos_old_gloves` | hands | 3 | power 0.04, defense 1, crit 0.02 | power 0.042, defense 1, crit 0.021 | 13.0 → 13.4 | 12.1 → 12.9 | 12% → 12% | 17% | 14% |
| `iron_wraps` | hands | 5 | power 0.06, defense 1, crit 0.02 | power 0.064, defense 1, crit 0.021 | 15.0 → 15.6 | 15.2 → 16.1 | 13% → 13% | 17% | 14% |
| `inspectors_gloves` | hands | 20 | power 0.18, defense 2, crit 0.06 | power 0.191, defense 2, crit 0.064 | 40.0 → 41.9 | 37.9 → 40.3 | 20% → 21% | 17% | 24% |
| `sentinel_gauntlets` | hands | 44 | power 0.43, defense 3, crit 0.09 | power 0.456, defense 3, crit 0.095 | 76.0 → 79.6 | 74.4 → 78.9 | 25% → 26% | 21% | 33% |
| `coolant_rare_hands` | hands | 53 | power 0.5, defense 3, crit 0.1 | power 0.53, defense 3, crit 0.106 | 85.0 → 89.2 | 88.0 → 93.4 | 25% → 26% | 21% | 33% |
| `underworks_rare_hands` | hands | 58 | power 0.54, defense 4, crit 0.11 | power 0.573, defense 4, crit 0.117 | 96.0 → 100.7 | 95.6 → 101.5 | 27% → 29% | 24% | 36% |
| `foundry_rare_hands` | hands | 63 | power 0.58, defense 4, crit 0.12 | power 0.615, defense 4, crit 0.127 | 102.0 → 106.9 | 103.2 → 109.5 | 28% → 29% | 24% | 36% |
| `heart_rare_hands` | hands | 68 | power 0.63, defense 4, crit 0.13 | power 0.668, defense 4, crit 0.138 | 109.0 → 114.4 | 110.8 → 117.6 | 28% → 30% | 24% | 36% |
| `chais_deck_shoes` | feet | 15 | speed 0.13, defense 3 | speed 0.138, defense 3 | 28.0 → 28.8 | 25.3 → 26.8 | 12% → 12% | 11% | 15% |
| `leks_lab_boots` | feet | 34 | speed 0.17, defense 4, attack_speed 0.08 | speed 0.18, defense 4, attack_speed 0.085 | 49.0 → 50.8 | 49.3 → 52.3 | 18% → 19% | 12% | 21% |
| `coolant_rare_feet` | feet | 53 | speed 0.25, defense 6, attack_speed 0.12 | speed 0.265, defense 6, attack_speed 0.127 | 73.0 → 75.5 | 73.4 → 77.8 | 23% → 24% | 20% | 27% |
| `underworks_rare_feet` | feet | 58 | speed 0.28, defense 7, attack_speed 0.13 | speed 0.297, defense 7, attack_speed 0.138 | 82.5 → 85.4 | 79.7 → 84.5 | 25% → 26% | 24% | 34% |
| `foundry_rare_feet` | feet | 63 | speed 0.3, defense 7, attack_speed 0.14 | speed 0.318, defense 7, attack_speed 0.149 | 86.0 → 89.2 | 86.0 → 91.3 | 25% → 26% | 24% | 34% |
| `heart_rare_feet` | feet | 68 | speed 0.32, defense 8, attack_speed 0.15 | speed 0.339, defense 8, attack_speed 0.159 | 94.5 → 97.8 | 92.3 → 98.0 | 27% → 28% | 24% | 34% |
| `brass_whistle` | charm | 1 | max_hp 20 | max_hp 21 | 10.0 → 10.5 | 10.3 → 11.0 | 17% → 18% | 9% | 27% |
| `kenjis_lucky_charm` | charm | 26 | max_hp 55, power 0.11, crit 0.07 | max_hp 58, power 0.117, crit 0.074 | 52.5 → 55.5 | 53.5 → 56.7 | 25% → 26% | – | 38% |
| `coolant_rare_charm` | charm | 53 | max_hp 105, power 0.21, crit 0.13 | max_hp 111, power 0.223, crit 0.138 | 99.5 → 105.4 | 100.0 → 106.1 | 31% → 33% | 27% | 42% |
| `underworks_rare_charm` | charm | 58 | max_hp 114, power 0.23, crit 0.14 | max_hp 121, power 0.244, crit 0.149 | 108.0 → 114.7 | 108.7 → 115.3 | 32% → 34% | 29% | 44% |
| `foundry_rare_charm` | charm | 63 | max_hp 123, power 0.25, crit 0.16 | max_hp 130, power 0.265, crit 0.17 | 118.5 → 125.5 | 117.3 → 124.4 | 34% → 36% | 29% | 44% |
| `heart_rare_charm` | charm | 68 | max_hp 132, power 0.26, crit 0.17 | max_hp 140, power 0.276, crit 0.18 | 126.0 → 133.6 | 125.9 → 133.6 | 34% → 37% | 29% | 44% |

### 6.4 The 11 grade inversions

The re-mix shown moves movement speed into max HP at `ItemRules` prices (0.01 speed
= 2 HP), so the score is unchanged. Recommended handling:

- **3 pairs:** fixed by MR alone.
- **1 pair** (`used_street_runners`): a one-stat trim.
- **7 pairs** (the speed boots against the slow steel-toe boots): record as
  intentional speed specialisations, in an allowlist test with the reason.
  - The steel-toe boots are on budget. Their flat defense is worth a lot at Lv 4,
    where a monster hit is about 15, and they pay for it with −0.02 movement
    speed.
  - Trimming them would put them below budget.

| # | Lower-grade item | Higher-grade item | Values today (lower / higher) | Values under MR | Fixed by MR? | Proposed stats for the higher item (if a re-mix is chosen) | Value after re-mix | Recommendation |
|---:|---|---|---|---|---|---|---|---|
| 1 | `used_steel_toe_boots` (common, Lv 4): defense 1, max_hp 12, speed -0.02 | `street_runners` (uncommon, Lv 6): speed 0.04, defense 1, attack_speed 0.02 | 15% / 8% | 15% / 8% | no | defense 1, attack_speed 0.02, max_hp 8 | 13% | Speed specialisation: record it as intentional (movement speed is valued 0 in the combat-value metric). The re-mix is the alternative. |
| 2 | `used_steel_toe_boots` (common, Lv 4): defense 1, max_hp 12, speed -0.02 | `deck_boots` (uncommon, Lv 13): speed 0.07, defense 1, max_hp 16 | 15% / 11% | 15% / 11% | no | speed 0.01, defense 1, max_hp 28 | 16% | Speed specialisation: record it as intentional (movement speed is valued 0 in the combat-value metric). The re-mix is the alternative. |
| 3 | `used_steel_toe_boots` (common, Lv 4): defense 1, max_hp 12, speed -0.02 | `lab_boots` (uncommon, Lv 21): speed 0.11, defense 2, attack_speed 0.05 | 15% / 12% | 15% / 12% | no | speed 0.04, defense 2, attack_speed 0.05, max_hp 14 | 17% | Speed specialisation: record it as intentional (movement speed is valued 0 in the combat-value metric). The re-mix is the alternative. |
| 4 | `used_steel_toe_boots` (common, Lv 4): defense 1, max_hp 12, speed -0.02 | `runner_sneakers` (uncommon, Lv 27): speed 0.16, defense 2, attack_speed 0.06 | 15% / 12% | 15% / 12% | no | speed 0.08, defense 2, attack_speed 0.06, max_hp 16 | 16% | Speed specialisation: record it as intentional (movement speed is valued 0 in the combat-value metric). The re-mix is the alternative. |
| 5 | `used_steel_toe_boots` (common, Lv 4): defense 1, max_hp 12, speed -0.02 | `facility_boots` (uncommon, Lv 35): speed 0.17, defense 3, attack_speed 0.08 | 15% / 15% | 15% / 15% | no | speed 0.14, defense 3, attack_speed 0.08, max_hp 6 | 17% | Speed specialisation: record it as intentional (movement speed is valued 0 in the combat-value metric). The re-mix is the alternative. |
| 6 | `used_steel_toe_boots` (common, Lv 4): defense 1, max_hp 12, speed -0.02 | `chais_deck_shoes` (rare, Lv 15): speed 0.13, defense 3 | 15% / 12% | 15% / 12% | no | speed 0.068, defense 3, max_hp 14 | 18% | Speed specialisation: record it as intentional (movement speed is valued 0 in the combat-value metric). The re-mix is the alternative. |
| 7 | `steel_toe_boots` (uncommon, Lv 4): defense 1, max_hp 14, speed -0.02 | `chais_deck_shoes` (rare, Lv 15): speed 0.13, defense 3 | 17% / 12% | 17% / 12% | no | speed 0.068, defense 3, max_hp 14 | 18% | Speed specialisation: record it as intentional (movement speed is valued 0 in the combat-value metric). The re-mix is the alternative. |
| 8 | `used_street_runners` (common, Lv 6): speed 0.03, defense 1, attack_speed 0.02 | `street_runners` (uncommon, Lv 6): speed 0.04, defense 1, attack_speed 0.02 | 8% / 8% | 8% / 8% | no | defense 1, attack_speed 0.02, max_hp 8 | 13% | `used_street_runners` attack_speed 0.02 → 0.01 (score 9.5 against a 10.3 budget, within tolerance); the Uncommon then leads. |
| 9 | `iron_wraps` (rare, Lv 5): power 0.06, defense 1, crit 0.02 | `champion_wraps` (epic, Lv 7): power 0.09, crit 0.04, attack_speed 0.03 | 13% / 12% | 13% / 14% | yes | – | – | Fixed by the grade change; nothing more. |
| 10 | `steel_toe_boots` (uncommon, Lv 4): defense 1, max_hp 14, speed -0.02 | `dockmaster_boots` (epic, Lv 15): speed 0.1, defense 2, max_hp 20 | 17% / 16% | 17% / 17% | yes | – | – | Fixed by the grade change; nothing more. |
| 11 | `iron_helm` (uncommon, Lv 7): defense 2, max_hp 13 | `champion_headband` (epic, Lv 7): max_hp 30, crit 0.04 | 20% / 19% | 20% / 21% | yes | – | – | Fixed by the grade change; nothing more. |

## 7. Enhancement +0 to +10

The formula is unchanged: +10% of each positive base stat per level, for every
grade.

### 7.1 Damage index / PvE EHP vs monsters, Lv 70 kits [Modeled]


**M0: Today** (Lv 70 kits)

| Kit | +0 dmg / EHP | +1 dmg / EHP | +3 dmg / EHP | +5 dmg / EHP | +7 dmg / EHP | +10 dmg / EHP |
|---|---|---|---|---|---|---|
| rare | 10.3 / 2,284 | 10.8 / 2,593 | 11.9 / 3,446 | 13.0 / 4,873 | 14.2 / 7,749 | 16.0 / 35,009 |
| epic | 10.4 / 3,379 | 11.0 / 4,156 | 12.1 / 7,070 | 13.2 / 18,172 | 14.4 / 140,422 | 15.6 / 153,161 |
| legendary | 10.5 / 1,839 | 10.8 / 2,004 | 11.5 / 2,398 | 12.1 / 2,904 | 12.7 / 3,582 | 13.7 / 5,169 |
| godforged | 14.8 / 9,831 | 15.5 / 21,003 | 17.0 / 155,391 | 18.5 / 168,800 | 20.0 / 182,209 | 22.2 / 202,322 |

**MR: Recommended (Godforged frozen)** (Lv 70 kits)

| Kit | +0 dmg / EHP | +1 dmg / EHP | +3 dmg / EHP | +5 dmg / EHP | +7 dmg / EHP | +10 dmg / EHP |
|---|---|---|---|---|---|---|
| rare | 10.6 / 2,438 | 11.2 / 2,800 | 12.3 / 3,836 | 13.5 / 5,712 | 14.8 / 10,137 | 16.5 / 135,362 |
| epic | 10.9 / 4,134 | 11.5 / 5,389 | 12.8 / 11,745 | 14.1 / 138,032 | 15.1 / 147,338 | 16.4 / 161,298 |
| legendary | 12.0 / 8,591 | 12.8 / 16,878 | 14.3 / 144,372 | 15.4 / 156,086 | 16.5 / 167,799 | 18.1 / 185,370 |
| godforged | 14.8 / 9,831 | 15.5 / 21,003 | 17.0 / 155,391 | 18.5 / 168,800 | 20.0 / 182,209 | 22.2 / 202,322 |

**MB: Model B (full)** (Lv 70 kits)

| Kit | +0 dmg / EHP | +1 dmg / EHP | +3 dmg / EHP | +5 dmg / EHP | +7 dmg / EHP | +10 dmg / EHP |
|---|---|---|---|---|---|---|
| rare | 11.6 / 3,201 | 12.3 / 3,896 | 13.8 / 6,398 | 15.2 / 14,610 | 16.5 / 135,955 | 18.2 / 147,906 |
| epic | 12.6 / 9,234 | 13.4 / 19,665 | 14.8 / 144,702 | 16.0 / 156,467 | 17.1 / 168,232 | 18.8 / 185,879 |
| legendary | 14.7 / 148,500 | 15.4 / 156,526 | 16.9 / 172,580 | 18.4 / 188,633 | 19.8 / 204,687 | 22.1 / 228,767 |
| godforged | 18.2 / 166,638 | 19.3 / 176,479 | 21.5 / 196,160 | 23.7 / 215,841 | 25.9 / 235,523 | 29.2 / 265,045 |

**MA: Model A (full)** (Lv 70 kits)

| Kit | +0 dmg / EHP | +1 dmg / EHP | +3 dmg / EHP | +5 dmg / EHP | +7 dmg / EHP | +10 dmg / EHP |
|---|---|---|---|---|---|---|
| rare | 14.6 / 9,751 | 15.7 / 22,977 | 17.3 / 141,286 | 18.8 / 152,526 | 20.3 / 163,765 | 22.6 / 180,624 |
| epic | 16.2 / 159,179 | 17.1 / 168,274 | 18.9 / 186,464 | 20.7 / 204,653 | 22.5 / 222,843 | 25.1 / 250,127 |
| legendary | 20.0 / 206,730 | 21.3 / 220,579 | 23.8 / 248,279 | 26.4 / 275,979 | 28.9 / 303,678 | 32.7 / 345,227 |
| godforged | 27.4 / 249,533 | 29.5 / 267,664 | 33.5 / 303,924 | 37.5 / 340,184 | 41.5 / 376,445 | 47.6 / 430,835 |

### 7.2 How far a lower grade must be enhanced to match the next grade at +0 [Modeled]

| Model | Lower grade | Higher grade (+0) | Lowest + matching higher +0 damage | Lowest + matching higher +0 PvP EHP | Lowest + matching higher +0 PvE EHP |
|---|---|---|---|---|---|
| M0 | rare | epic | +1 | +4 | +3 |
| M0 | epic | legendary | +1 | +0 | +0 |
| M0 | legendary | godforged | never (+10 short) | never (+10 short) | never (+10 short) |
| M0 | rare | legendary | +1 | +0 | +0 |
| MR | rare | epic | +1 | +4 | +4 |
| MR | epic | legendary | +2 | +3 | +3 |
| MR | legendary | godforged | +4 | +1 | +1 |
| MR | rare | legendary | +3 | +7 | +7 |
| MB | rare | epic | +2 | +5 | +5 |
| MB | epic | legendary | +3 | +4 | +4 |
| MB | legendary | godforged | +5 | +2 | +3 |
| MB | rare | legendary | +5 | +10 | never (+10 short) |
| MA | rare | epic | +2 | +6 | +7 |
| MA | epic | legendary | +5 | +6 | +6 |
| MA | legendary | godforged | +6 | +3 | +4 |
| MA | rare | legendary | +7 | never (+10 short) | never (+10 short) |

What this shows:

- **Today:**
  - Epic +1 out-damages today's Lv 70 "Legendary" kit, and Epic +0 already has
    its PvE and PvP EHP.
  - Godforged is out of reach at any enhancement.
  - Legendary is not a step.
- **MR:**
  - Each step needs about +1 to +4 of the grade below.
  - Rare needs +3 (damage) to +7 (survival) to match Legendary +0.
  - That is a meaningful progression at every enhancement level, with no
    inversion created by enhancement (the rule is proportional).
- **MB and MA:** the gaps widen to +5 to +10 or "never". At that point the lower
  grades stop being viable gear, and enhancing them stops paying.

## 8. Caps: crit 50%, attack speed +0.3, defense and the 1-damage floor

### 8.1 Where the caps bite today [Modeled]

| Grade kit (M0) | Lv where worn crit first reaches 0.50 | Crit worn at Lv 70 (+0 / +10) | Attack speed worn at Lv 70 (+0 / +10) | Defense at Lv 70 (+0 / +10) against an 85 monster hit |
|---|---|---|---|---|
| common | never | 0.44 / 0.80 | 1.13 / 1.26 | 29 / 57 |
| uncommon | Lv 68 | 0.51 / 0.94 | 1.15 / 1.30 | 33 / 65 |
| rare | Lv 53 | 0.66 / 1.24 | 1.15 / 1.30 | 41 / 81 |
| epic | Lv 53 | 0.75 / 1.42 | 1.18 / 1.36 | 52 / 103 |
| legendary | Lv 48 | 0.58 / 1.08 | 1.37 / 1.74 | 30 / 59 |
| godforged | Lv 50 | 1.10 / 2.12 | 1.98 / 2.96 | 71 / 141 |

- **Crit:**
  - Worn crit reaches 0.50 from Lv 48–53 for Rare and better.
  - At Lv 70 a Rare kit carries 0.66 (1.24 at +10) and Godforged 1.10 (2.12).
  - Everything above about 0.42 of gear crit (0.50 minus the hero's 0.05–0.08
    base) is paid for in `ItemRules` score and counts for nothing.
- **Attack speed:** Godforged carries +0.98 (+1.96 at +10). Only +0.30 counts.
- **Defense:**
  - Against an 85 monster hit, defense ≥ 84 leaves the 1-damage floor.
  - Godforged reaches it at +2. Epic reaches it at +7 under MR, and at +0 under MA.

### 8.2 Approaches for crit and attack speed

| Approach | What changes | Formula change? | Data change? | Lv 70 Epic kit, MR: damage index | Notes |
|---|---|---|---|---:|---|
| Today | crit 0.81 worn, 0.50 counted | – | – | 10.93 | 0.31 crit (63 score points) does nothing |
| A. Replace excess | Move crit past the set's reachable cap into power, HP or defense at ItemRules prices | no | yes (items) | 11.87 (excess into power) | Keeps the cap. Needs a per-slot crit ceiling (D) to stay fixed |
| B. Diminishing returns | Counted crit = base + (0.65 − base)·(1 − e^(−gear/0.45)), replacing the 0.50 wall | yes (PlayerProfile.stats) | no | 11.10 (counted crit 0.54) | Every point keeps some value. The PvP crit rate rises; DuelCheck needs re-measuring |
| C. Show capped values | The stat sheet and item cards show "50% (cap)" and grey out the excess | no | no | 10.93 | UI only; wasted stats stay wasted |
| D. Slot budgets | Crit allowed only in weapon, hands and charm, with ceilings summing to about 0.40 at Lv 70 for Legendary | no | yes (items and ItemRules check) | 11.87 (same as A once applied) | Prevents the problem coming back; a content check |

**Recommendation (for approval): C now, then D with A.**

- **C:** show the capped value and grey out the excess. UI only; no balance risk.
- **D:** per-slot crit and attack-speed ceilings in the `ItemRules` content
  check, so the set total stays reachable.
- **A:** when items are rescaled, move each item's crit beyond its slot ceiling
  into power (weapon and hands) or HP (head and charm) at `ItemRules` prices. This
  is data only and adds no formula.
- **B (diminishing returns)** changes a combat formula, moves PvP crit rates and
  needs the duel and arena harnesses re-run. Not recommended first.

### 8.3 Approaches for defense [Modeled]

Damage taken from one 85-point monster hit at Lv 70:

- D1: a PvE floor of 10% of the raw hit (formula).
- D2: PvE defense as a share like PvP, with K growing with level (formula).
- D3: defense limited to about 40–50% of an item's budget from Lv 50, with the
  rest in HP (data). Modelled here as 60% of today's defense plus 10.

| Lv 70 kit | Model | + | Defense | Taken per 85 monster hit today | 10% floor (D1) | Share like PvP, K = 90 + 3·Lv (D2) | Defense budget ≤ 40% of the slot from Lv 50 (D3) |
|---|---|---:|---:|---:|---:|---:|---:|
| epic | M0 | 0 | 52 | 33 | 33 | 72 | 44 |
| epic | M0 | 7 | 88 | 1 | 8 | 66 | 22 |
| epic | M0 | 10 | 103 | 1 | 8 | 63 | 13 |
| legendary | M0 | 0 | 30 | 55 | 55 | 77 | 57 |
| legendary | M0 | 7 | 50 | 35 | 35 | 73 | 45 |
| legendary | M0 | 10 | 59 | 26 | 26 | 71 | 40 |
| godforged | M0 | 0 | 71 | 14 | 14 | 69 | 32 |
| godforged | M0 | 7 | 120 | 1 | 8 | 61 | 3 |
| godforged | M0 | 10 | 141 | 1 | 8 | 58 | 1 |
| epic | MR | 0 | 57 | 28 | 28 | 71 | 41 |
| epic | MR | 7 | 96 | 1 | 8 | 64 | 17 |
| epic | MR | 10 | 113 | 1 | 8 | 62 | 7 |
| legendary | MR | 0 | 70 | 15 | 15 | 69 | 33 |
| legendary | MR | 7 | 118 | 1 | 8 | 61 | 4 |
| legendary | MR | 10 | 139 | 1 | 8 | 58 | 1 |
| godforged | MR | 0 | 71 | 14 | 14 | 69 | 32 |
| godforged | MR | 7 | 120 | 1 | 8 | 61 | 3 |
| godforged | MR | 10 | 141 | 1 | 8 | 58 | 1 |
| epic | MB | 0 | 71 | 14 | 14 | 69 | 32 |
| epic | MB | 7 | 120 | 1 | 8 | 61 | 3 |
| epic | MB | 10 | 141 | 1 | 8 | 58 | 1 |
| legendary | MB | 0 | 96 | 1 | 8 | 64 | 17 |
| legendary | MB | 7 | 163 | 1 | 8 | 55 | 1 |
| legendary | MB | 10 | 191 | 1 | 8 | 52 | 1 |
| godforged | MB | 0 | 104 | 1 | 8 | 63 | 13 |
| godforged | MB | 7 | 176 | 1 | 8 | 54 | 1 |
| godforged | MB | 10 | 207 | 1 | 8 | 50 | 1 |

**Recommendation (for approval): D3 with the rescale, and decide D1 separately.**

- **D3** is data only. It keeps flat defense meaningful but delays the floor.
- **D1** is the smallest formula change that keeps monsters relevant against
  enhanced endgame gear. It needs its own decision and harness pass.
- **D2** changes how every PvE hit feels and is not recommended.

## 9. Combat simulation results [Simulated unless marked]

These are real game rules. Hero `riku` (default), at the area or boss level, with
the kit of the named grade and the named enhancement. Food: 20 rice boxes and 10
tonics.

### 9.1 Farming (normal and elite monsters; 3-minute sessions, 3 seeds)

Farming grounds spawn their own elites (`elite_chance`), so elite fights are
inside these numbers and are not reported separately. `farm_iron_heart` at Lv 70
is the endgame farming case.

Cell: kills per hour / damage taken per hour / knock-outs out of 3.

| Ground | Lv | Kit | M0 | M0L | MR | MB | MA |
|---|---|---|---|---|---|---|---|
| farm_harbour_stacks | 15 | rare+0 | 933 / 10,940 / 0 | 933 / 10,940 / 0 | 860 / 6,940 / 0 | 980 / 9,353 / 0 | 1120 / 3,953 / 0 |
| farm_harbour_stacks | 15 | epic+0 | 867 / 8,567 / 0 | 867 / 8,567 / 0 | 853 / 10,327 / 0 | 1000 / 11,187 / 0 | 1313 / 4,120 / 0 |
| farm_harbour_stacks | 15 | legendary+0 | 1040 / 8,180 / 0 | 1040 / 8,180 / 0 | 1033 / 10,247 / 0 | 1167 / 7,020 / 0 | 1507 / 3,240 / 0 |
| farm_network_backrooms | 29 | rare+0 | 740 / 22,020 / 0 | 740 / 22,020 / 0 | 733 / 21,033 / 0 | 767 / 13,827 / 0 | 920 / 10,627 / 0 |
| farm_network_backrooms | 29 | epic+0 | 800 / 17,520 / 0 | 800 / 17,520 / 0 | 847 / 14,007 / 0 | 927 / 12,367 / 0 | 1240 / 6,600 / 0 |
| farm_network_backrooms | 29 | legendary+0 | 827 / 14,353 / 0 | 827 / 14,353 / 0 | 813 / 19,707 / 0 | 967 / 8,787 / 0 | 1213 / 4,613 / 0 |
| farm_facility_annex | 37 | rare+0 | 647 / 25,300 / 0 | 647 / 25,300 / 0 | 647 / 27,980 / 0 | 780 / 23,787 / 0 | 907 / 12,773 / 0 |
| farm_facility_annex | 37 | epic+0 | 760 / 17,287 / 0 | 760 / 17,287 / 0 | 873 / 13,707 / 0 | 933 / 10,667 / 0 | 1240 / 4,773 / 0 |
| farm_facility_annex | 37 | legendary+0 | 940 / 18,213 / 0 | 940 / 18,213 / 0 | 1167 / 12,947 / 0 | 1360 / 6,160 / 0 | 1453 / 1,373 / 0 |
| farm_coolant_vaults | 53 | rare+0 | 953 / 29,080 / 0 | 953 / 29,080 / 0 | 1007 / 25,193 / 0 | 1153 / 20,500 / 0 | 1247 / 9,720 / 0 |
| farm_coolant_vaults | 53 | epic+0 | 993 / 22,927 / 0 | 993 / 22,927 / 0 | 947 / 16,580 / 0 | 1113 / 13,687 / 0 | 1373 / 3,287 / 0 |
| farm_coolant_vaults | 53 | legendary+0 | 913 / 39,540 / 0 | 913 / 39,540 / 0 | 1020 / 26,947 / 0 | 1133 / 14,813 / 0 | 1413 / 13,153 / 0 |
| farm_foundry_depths | 63 | rare+0 | 1093 / 22,520 / 0 | 1093 / 22,520 / 0 | 1187 / 17,287 / 0 | 1233 / 15,927 / 0 | 1360 / 7,793 / 0 |
| farm_foundry_depths | 63 | epic+0 | 1093 / 13,367 / 0 | 1093 / 13,367 / 0 | 1160 / 15,713 / 0 | 1227 / 7,847 / 0 | 1480 / 1,253 / 0 |
| farm_foundry_depths | 63 | legendary+0 | 1060 / 25,433 / 0 | 1113 / 10,360 / 0 | 1093 / 7,553 / 0 | 1407 / 5,147 / 0 | 1793 / 627 / 0 |
| farm_iron_heart | 70 | rare+0 | 920 / 63,033 / 0 | 920 / 63,033 / 0 | 1007 / 51,120 / 0 | 1213 / 33,513 / 0 | 1267 / 29,247 / 0 |
| farm_iron_heart | 70 | epic+0 | 927 / 48,060 / 0 | 927 / 48,060 / 0 | 1047 / 29,087 / 0 | 1180 / 29,880 / 0 | 1347 / 13,427 / 0 |
| farm_iron_heart | 70 | legendary+0 | 1027 / 51,187 / 0 | 1053 / 30,813 / 0 | 1153 / 28,520 / 0 | 1347 / 18,920 / 0 | 1773 / 5,393 / 0 |
| farm_iron_heart | 70 | epic+7 | 1360 / 14,580 / 0 | 1360 / 14,580 / 0 | 1400 / 14,907 / 0 | 1660 / 11,727 / 0 | 1880 / 2,420 / 0 |
| farm_iron_heart | 70 | legendary+7 | 1287 / 38,680 / 0 | 1420 / 13,660 / 0 | 1373 / 11,813 / 0 | 1747 / 4,580 / 0 | 2287 / 460 / 0 |
| farm_iron_heart | 70 | godforged+0 | 1327 / 22,253 / 0 | 1327 / 22,253 / 0 | 1327 / 22,253 / 0 | 1607 / 11,507 / 0 | 2133 / 3,673 / 0 |
| farm_iron_heart | 70 | rare+10 | 1553 / 20,473 / 0 | 1553 / 20,473 / 0 | 1467 / 19,147 / 0 | 1687 / 15,693 / 0 | 1880 / 6,687 / 0 |

What farming shows [Simulated]:

- **No knock-out in any model, ground or kit.** Farming difficulty is not at risk
  in either direction. The differences are speed and damage taken.
- **Today's problem, measured.** At `farm_iron_heart` (Lv 70) the M0 "Legendary"
  kit (today's Lv 30–48 Legendaries) takes 51,187 damage per hour, more than the
  Epic kit's 48,060.
  - With the proposed Lv 55–70 Legendaries (M0L, today's weights) that falls to
    30,813.
  - Kills per hour: 1,027 → 1,053.
- **MR at Lv 70:**
  - Each grade step cuts damage taken (Rare 51,120 → Epic 29,087 → Legendary
    28,520 per hour).
  - Kills rise about 4–10% per step (1,007 → 1,047 → 1,153).
  - At Lv 63 the Legendary kit takes half the Epic kit's damage.
- **MB and MA:**
  - Under MB, Lv 70 kills per hour are 13–20% above MR.
  - Under MA, kills per hour rise 25–55% and damage taken collapses (627–13,427
    per hour for Epic and Legendary kits at Lv 63–70). Monsters stop being a
    threat. This is the 1-damage floor of §8 seen in play.
- **Enhancement:** Epic +7 (1,400 kills) and Rare +10 (1,467) out-farm the MR
  Legendary +0 kit (1,153). As in §7, enhancement matters more to farming speed
  than one grade step.
- **Noise:** with 3 seeds of 3 minutes, early-ground rows move ±15% between
  models whose items did not change (for example, M0 against MR at Lv 15).
  Read the Lv 53–70 rows as the signal.


### 9.2 Stage bosses (story, other fights cleared) and mini-bosses (lair bosses, fought alone)

Cell: median kill seconds / damage taken per fight / wins out of 3 / downs.

| Fight | Target | Hero Lv | Kit | M0 | M0L | MR | MB | MA |
|---|---|---|---|---|---|---|---|---|
| stage boss | gang_hq | 10 | rare+0 | 66s / 517 / 3 / 0 | 66s / 517 / 3 / 0 | 66s / 517 / 3 / 0 | 61s / 363 / 3 / 0 | 63s / 471 / 3 / 0 |
| stage boss | gang_hq | 10 | epic+0 | 47s / 491 / 3 / 0 | 47s / 491 / 3 / 0 | 44s / 541 / 3 / 0 | 48s / 319 / 3 / 0 | 30s / 206 / 3 / 0 |
| stage boss | gang_hq | 10 | legendary+0 | 43s / 309 / 3 / 0 | 43s / 309 / 3 / 0 | 38s / 380 / 3 / 0 | 41s / 352 / 3 / 0 | 28s / 219 / 3 / 0 |
| stage boss | underground_ring | 27 | rare+0 | 48s / 767 / 3 / 0 | 48s / 767 / 3 / 0 | 46s / 705 / 3 / 0 | 47s / 484 / 3 / 0 | 42s / 336 / 3 / 0 |
| stage boss | underground_ring | 27 | epic+0 | 42s / 935 / 3 / 0 | 42s / 935 / 3 / 0 | 41s / 771 / 3 / 0 | 36s / 267 / 3 / 0 | 27s / 99 / 3 / 0 |
| stage boss | underground_ring | 27 | legendary+0 | 53s / 513 / 3 / 0 | 53s / 513 / 3 / 0 | 44s / 645 / 3 / 0 | 42s / 405 / 3 / 0 | 29s / 286 / 3 / 0 |
| stage boss | test_labs | 35 | rare+0 | 50s / 512 / 3 / 0 | 50s / 512 / 3 / 0 | 52s / 504 / 3 / 0 | 48s / 644 / 3 / 0 | 41s / 491 / 3 / 0 |
| stage boss | test_labs | 35 | epic+0 | 43s / 364 / 3 / 0 | 43s / 364 / 3 / 0 | 45s / 327 / 3 / 0 | 42s / 309 / 3 / 0 | 30s / 46 / 3 / 0 |
| stage boss | test_labs | 35 | legendary+0 | 37s / 372 / 3 / 0 | 37s / 372 / 3 / 0 | 35s / 403 / 3 / 0 | 33s / 160 / 3 / 0 | 26s / 52 / 3 / 0 |
| stage boss | control_room | 39 | rare+0 | 34s / 730 / 3 / 0 | 34s / 730 / 3 / 0 | 44s / 816 / 3 / 0 | 38s / 669 / 3 / 0 | 38s / 490 / 3 / 0 |
| stage boss | control_room | 39 | epic+0 | 53s / 562 / 3 / 0 | 53s / 562 / 3 / 0 | 38s / 543 / 3 / 0 | 36s / 383 / 3 / 0 | 31s / 191 / 3 / 0 |
| stage boss | control_room | 39 | legendary+0 | 55s / 536 / 3 / 0 | 55s / 536 / 3 / 0 | 32s / 350 / 3 / 0 | 30s / 293 / 3 / 0 | 22s / 65 / 3 / 0 |
| stage boss | core_chamber | 48 | rare+0 | 61s / 790 / 3 / 0 | 61s / 790 / 3 / 0 | 44s / 605 / 3 / 0 | 52s / 389 / 3 / 0 | 52s / 520 / 3 / 0 |
| stage boss | core_chamber | 48 | epic+0 | 82s / 707 / 3 / 0 | 82s / 707 / 3 / 0 | 58s / 589 / 3 / 0 | 54s / 583 / 3 / 0 | 47s / 291 / 3 / 0 |
| stage boss | core_chamber | 48 | legendary+0 | 48s / 358 / 3 / 0 | 48s / 358 / 3 / 0 | 52s / 406 / 3 / 0 | 41s / 211 / 3 / 0 | 26s / 21 / 3 / 0 |
| mini-boss | spillway_chief | 45 | rare+0 | 41s / 766 / 3 / 0 | 41s / 766 / 3 / 0 | 36s / 477 / 3 / 0 | 30s / 675 / 3 / 0 | 27s / 519 / 3 / 0 |
| mini-boss | spillway_chief | 45 | epic+0 | 37s / 764 / 3 / 0 | 37s / 764 / 3 / 0 | 42s / 800 / 3 / 0 | 37s / 486 / 3 / 0 | 36s / 383 / 3 / 0 |
| mini-boss | spillway_chief | 45 | legendary+0 | 37s / 627 / 3 / 0 | 37s / 627 / 3 / 0 | 35s / 678 / 3 / 0 | 26s / 222 / 3 / 0 | 18s / 104 / 3 / 0 |
| mini-boss | arthit_reinstated | 55 | rare+0 | 41s / 992 / 3 / 0 | 41s / 992 / 3 / 0 | 49s / 1,195 / 3 / 0 | 40s / 950 / 3 / 0 | 35s / 639 / 3 / 0 |
| mini-boss | arthit_reinstated | 55 | epic+0 | 48s / 950 / 3 / 0 | 48s / 950 / 3 / 0 | 48s / 1,008 / 3 / 0 | 46s / 785 / 3 / 0 | 41s / 358 / 3 / 0 |
| mini-boss | arthit_reinstated | 55 | legendary+0 | 49s / 1,408 / 3 / 0 | 38s / 1,059 / 3 / 0 | 36s / 897 / 3 / 0 | 37s / 653 / 3 / 0 | 24s / 186 / 3 / 0 |
| mini-boss | k7_overdriven | 65 | rare+0 | 43s / 1,415 / 3 / 0 | 43s / 1,415 / 3 / 0 | 39s / 1,204 / 3 / 0 | 42s / 1,450 / 3 / 0 | 39s / 589 / 3 / 0 |
| mini-boss | k7_overdriven | 65 | epic+0 | 54s / 1,211 / 3 / 0 | 54s / 1,211 / 3 / 0 | 45s / 947 / 3 / 0 | 49s / 909 / 3 / 0 | 42s / 287 / 3 / 0 |
| mini-boss | k7_overdriven | 65 | legendary+0 | 44s / 1,374 / 3 / 0 | 42s / 1,098 / 3 / 0 | 39s / 659 / 3 / 0 | 35s / 486 / 3 / 0 | 20s / 125 / 3 / 0 |
| mini-boss | wiroj_protocol | 70 | rare+0 | 46s / 928 / 3 / 0 | 46s / 928 / 3 / 0 | 51s / 1,066 / 3 / 0 | 54s / 744 / 3 / 0 | 30s / 183 / 3 / 0 |
| mini-boss | wiroj_protocol | 70 | epic+0 | 62s / 686 / 3 / 0 | 62s / 686 / 3 / 0 | 45s / 646 / 3 / 0 | 49s / 443 / 3 / 0 | 29s / 194 / 3 / 0 |
| mini-boss | wiroj_protocol | 70 | legendary+0 | 53s / 994 / 3 / 0 | 58s / 852 / 3 / 0 | 50s / 634 / 3 / 0 | 38s / 277 / 3 / 0 | 27s / 22 / 3 / 0 |

What stage and mini-boss fights show [Simulated]:

- Every fight was won, with no downs, in every model and kit. Hero at the boss
  area's level.
- **MR:**
  - Kill times stay within the noise of today at Lv 10–35.
  - They fall at Lv 39–70 for Epic and Legendary kits. For example,
    `commander_arthit` with a Legendary kit: 55 s → 32 s.
  - Damage taken mostly falls at Lv 48–70, by up to about 50%. One cell rises,
    within the noise: `director_wiroj` with a Legendary kit, 358 → 406.
  - The MR kit with the proposed Lv 55–70 Legendaries, against today's Legendary
    kit:
    - `arthit_reinstated`: 27% faster, with 36% less damage taken.
    - `k7_overdriven`: 11% faster, with 52% less damage taken.
    - At today's weights (M0L) the gains are 22% and 25%, and 5% and 20%.
- **MA** roughly halves kill times and cuts damage taken by 60–98%. For example,
  `director_wiroj` with a Legendary kit takes 21 damage in 26 s. The stage bosses
  would need re-tuning.
- **Noise:** with 3 seeds, single cells move ±20%. Today's Lv 10 rows differ
  between M0 and MR only by random wander, because Lv 10 kits changed little.


### 9.3 World bosses and raid world bosses (one hero, 3 minutes, 2 seeds)

Cell: damage per minute / share of the round's pool per minute / downs. Raid bosses are sized for 15–30
players, so one hero's share is small by design.

| Boss | Raid | Lv | Kit | M0 | M0L | MR | MB | MA |
|---|---|---|---|---|---|---|---|---|
| tunnel_mother |  | 32 | epic+0 | 4,390 / 4.06% / 0 | 4,390 / 4.06% / 0 | 3,989 / 3.69% / 0 | 4,839 / 4.48% / 0 | 6,304 / 5.83% / 0 |
| tunnel_mother |  | 32 | legendary+0 | 4,963 / 4.59% / 0 | 4,963 / 4.59% / 0 | 4,916 / 4.55% / 0 | 6,242 / 5.77% / 0 | 8,629 / 7.98% / 0 |
| tunnel_mother |  | 32 | godforged+0 | 5,253 / 4.86% / 0 | 5,253 / 4.86% / 0 | 5,253 / 4.86% / 0 | 6,869 / 6.35% / 0 | 10,176 / 9.41% / 0 |
| tunnel_mother |  | 32 | epic+7 | 5,744 / 5.31% / 0 | 5,744 / 5.31% / 0 | 5,697 / 5.27% / 0 | 7,470 / 6.91% / 0 | 8,420 / 7.79% / 0 |
| tunnel_mother |  | 32 | legendary+7 | 6,922 / 6.40% / 0 | 6,922 / 6.40% / 0 | 6,730 / 6.22% / 0 | 8,166 / 7.55% / 0 | 11,679 / 10.80% / 0 |
| iron_colossus |  | 52 | epic+0 | 4,504 / 1.58% / 1 | 4,504 / 1.58% / 1 | 5,002 / 1.76% / 2 | 4,523 / 1.59% / 0 | 6,646 / 2.34% / 0 |
| iron_colossus |  | 52 | legendary+0 | 4,945 / 1.74% / 1 | 4,945 / 1.74% / 1 | 4,914 / 1.73% / 0 | 7,315 / 2.57% / 0 | 10,876 / 3.83% / 0 |
| iron_colossus |  | 52 | godforged+0 | 8,282 / 2.91% / 1 | 8,282 / 2.91% / 1 | 8,282 / 2.91% / 1 | 10,712 / 3.77% / 0 | 17,561 / 6.18% / 0 |
| iron_colossus |  | 52 | epic+7 | 5,399 / 1.90% / 0 | 5,399 / 1.90% / 0 | 5,612 / 1.97% / 0 | 6,006 / 2.11% / 0 | 8,829 / 3.11% / 0 |
| iron_colossus |  | 52 | legendary+7 | 6,821 / 2.40% / 0 | 6,821 / 2.40% / 0 | 7,900 / 2.78% / 0 | 9,048 / 3.18% / 0 | 15,462 / 5.44% / 0 |
| subject_zero |  | 55 | epic+0 | 4,103 / 0.63% / 0 | 4,103 / 0.63% / 0 | 5,330 / 0.82% / 0 | 6,052 / 0.93% / 0 | 7,625 / 1.17% / 0 |
| subject_zero |  | 55 | legendary+0 | 5,139 / 0.79% / 2 | 5,085 / 0.78% / 1 | 5,964 / 0.91% / 1 | 7,947 / 1.22% / 0 | 11,928 / 1.83% / 0 |
| subject_zero |  | 55 | godforged+0 | 6,515 / 1.00% / 2 | 6,515 / 1.00% / 2 | 6,515 / 1.00% / 2 | 7,244 / 1.11% / 0 | 13,966 / 2.14% / 0 |
| subject_zero |  | 55 | epic+7 | 6,173 / 0.95% / 0 | 6,173 / 0.95% / 0 | 6,711 / 1.03% / 0 | 8,770 / 1.34% / 0 | 11,321 / 1.73% / 0 |
| subject_zero |  | 55 | legendary+7 | 5,429 / 0.83% / 0 | 8,292 / 1.27% / 0 | 8,530 / 1.31% / 0 | 9,412 / 1.44% / 0 | 15,731 / 2.41% / 0 |
| slag_titan |  | 60 | epic+0 | 5,107 / 1.61% / 0 | 5,107 / 1.61% / 0 | 4,681 / 1.47% / 0 | 6,917 / 2.18% / 0 | 9,617 / 3.03% / 0 |
| slag_titan |  | 60 | legendary+0 | 4,908 / 1.54% / 2 | 5,302 / 1.67% / 0 | 5,865 / 1.85% / 0 | 7,181 / 2.26% / 0 | 10,882 / 3.42% / 0 |
| slag_titan |  | 60 | godforged+0 | 7,035 / 2.21% / 0 | 7,035 / 2.21% / 0 | 7,035 / 2.21% / 0 | 9,498 / 2.99% / 0 | 15,778 / 4.96% / 0 |
| slag_titan |  | 60 | epic+7 | 7,748 / 2.44% / 0 | 7,748 / 2.44% / 0 | 8,804 / 2.77% / 0 | 10,219 / 3.22% / 0 | 11,120 / 3.50% / 0 |
| slag_titan |  | 60 | legendary+7 | 6,202 / 1.95% / 0 | 9,767 / 3.07% / 0 | 8,607 / 2.71% / 0 | 10,636 / 3.35% / 0 | 17,012 / 5.35% / 0 |
| iron_sovereign |  | 70 | epic+0 | 5,276 / 0.67% / 2 | 5,276 / 0.67% / 2 | 5,845 / 0.74% / 2 | 7,897 / 1.00% / 1 | 8,103 / 1.02% / 0 |
| iron_sovereign |  | 70 | legendary+0 | 4,119 / 0.52% / 2 | 6,175 / 0.78% / 1 | 7,174 / 0.91% / 0 | 8,425 / 1.06% / 0 | 10,476 / 1.32% / 0 |
| iron_sovereign |  | 70 | godforged+0 | 7,431 / 0.94% / 0 | 7,431 / 0.94% / 0 | 7,431 / 0.94% / 0 | 9,749 / 1.23% / 0 | 14,176 / 1.79% / 0 |
| iron_sovereign |  | 70 | epic+7 | 8,687 / 1.10% / 0 | 8,687 / 1.10% / 0 | 9,896 / 1.25% / 0 | 8,249 / 1.04% / 0 | 11,692 / 1.48% / 0 |
| iron_sovereign |  | 70 | legendary+7 | 5,538 / 0.70% / 0 | 8,377 / 1.06% / 0 | 8,769 / 1.11% / 0 | 11,557 / 1.46% / 0 | 20,080 / 2.54% / 0 |
| floodgate_marshal | raid | 56 | epic+0 | 4,413 / 0.39% / 1 | 4,413 / 0.39% / 1 | 4,420 / 0.39% / 0 | 5,315 / 0.47% / 0 | 6,786 / 0.60% / 0 |
| floodgate_marshal | raid | 56 | legendary+0 | 2,972 / 0.26% / 2 | 5,450 / 0.48% / 2 | 6,274 / 0.56% / 1 | 6,959 / 0.62% / 0 | 9,913 / 0.88% / 0 |
| floodgate_marshal | raid | 56 | godforged+0 | 6,568 / 0.58% / 0 | 6,568 / 0.58% / 0 | 6,568 / 0.58% / 0 | 7,168 / 0.63% / 0 | 13,770 / 1.22% / 0 |
| floodgate_marshal | raid | 56 | epic+7 | 6,681 / 0.59% / 0 | 6,681 / 0.59% / 0 | 6,913 / 0.61% / 0 | 8,243 / 0.73% / 0 | 10,120 / 0.90% / 0 |
| floodgate_marshal | raid | 56 | legendary+7 | 6,017 / 0.53% / 1 | 7,017 / 0.62% / 0 | 8,409 / 0.74% / 0 | 12,612 / 1.12% / 0 | 15,186 / 1.35% / 0 |
| crucible_king | raid | 64 | epic+0 | 6,227 / 0.34% / 1 | 6,227 / 0.34% / 1 | 6,127 / 0.34% / 2 | 6,630 / 0.37% / 0 | 8,819 / 0.49% / 0 |
| crucible_king | raid | 64 | legendary+0 | 6,563 / 0.36% / 2 | 4,659 / 0.26% / 0 | 5,729 / 0.32% / 0 | 7,495 / 0.41% / 0 | 9,262 / 0.51% / 0 |
| crucible_king | raid | 64 | godforged+0 | 7,446 / 0.41% / 0 | 7,446 / 0.41% / 0 | 7,446 / 0.41% / 0 | 9,286 / 0.51% / 0 | 13,747 / 0.76% / 0 |
| crucible_king | raid | 64 | epic+7 | 8,415 / 0.47% / 0 | 8,415 / 0.47% / 0 | 8,547 / 0.47% / 0 | 9,465 / 0.52% / 0 | 12,492 / 0.69% / 0 |
| crucible_king | raid | 64 | legendary+7 | 6,579 / 0.36% / 0 | 9,027 / 0.50% / 0 | 8,953 / 0.50% / 0 | 10,401 / 0.58% / 0 | 14,396 / 0.80% / 0 |
| founders_engine | raid | 70 | epic+0 | 5,419 / 0.17% / 2 | 5,419 / 0.17% / 2 | 5,881 / 0.18% / 2 | 6,354 / 0.20% / 2 | 8,213 / 0.25% / 0 |
| founders_engine | raid | 70 | legendary+0 | 5,333 / 0.16% / 2 | 4,838 / 0.15% / 2 | 7,217 / 0.22% / 2 | 6,964 / 0.22% / 2 | 10,894 / 0.34% / 0 |
| founders_engine | raid | 70 | godforged+0 | 7,331 / 0.23% / 2 | 7,331 / 0.23% / 2 | 7,331 / 0.23% / 2 | 7,786 / 0.24% / 0 | 13,516 / 0.42% / 0 |
| founders_engine | raid | 70 | epic+7 | 6,890 / 0.21% / 2 | 6,890 / 0.21% / 2 | 7,200 / 0.22% / 2 | 7,618 / 0.24% / 0 | 13,214 / 0.41% / 0 |
| founders_engine | raid | 70 | legendary+7 | 6,596 / 0.20% / 2 | 7,805 / 0.24% / 0 | 8,879 / 0.27% / 0 | 10,969 / 0.34% / 0 | 16,658 / 0.51% / 0 |

What world bosses show [Simulated]:

- **Godforged rows are identical in M0, M0L and MR**, as they should be: no
  Godforged stat changes. They differ only in MB and MA, where Godforged is
  raised in memory.
- **Today (M0):**
  - The Lv 70 "Legendary" kit does less damage than the Epic kit against
    `iron_sovereign` (4,119 against 5,276 per minute).
  - Against the raid boss `floodgate_marshal` it does 2,972 against 4,413, with
    more downs.
- **MR:**
  - Legendary sits between Epic and Godforged against most bosses. Examples:
    `iron_sovereign` 5,845 → 7,174 → 7,431 per minute, and `floodgate_marshal`
    4,420 → 6,274 → 6,568.
  - Downs fall (Lv 70 Legendary +0: 0 downs against `iron_sovereign`, against 2
    with Epic).
  - Close cells to note: `crucible_king` Legendary +0 (5,729) sits below Epic +0
    (6,127). `founders_engine` downs stay at 2 for every +0 kit, including
    Godforged. That raid is not soloable at +0 except under MA and with MB's raised
    Godforged, which is by design for a 30-player boss.
- **MA:**
  - One hero's share of a raid pool per minute roughly doubles. For example,
    `founders_engine` Legendary +7: 0.27% → 0.51%.
  - So raids sized for 15–30 players would empty about twice as fast. Pools and
    enrage would need re-tuning.


### 9.4 Arena / PvP (Lv 70, same job both sides, AI 0.8, 12 matches, sides swapped)

Cell: side-A wins out of 12 (draws), side A's mean HP share left.

| Job | Side A | Side B | M0 | M0L | MR | MB | MA |
|---|---|---|---|---|---|---|---|
| boxer | epic+0 | legendary+0 | 12 (0) / 0.31 | 2 (0) / 0.01 | 0 (0) / 0.00 | 0 (0) / 0.00 | 0 (0) / 0.00 |
| boxer | legendary+0 | godforged+0 | 0 (0) / 0.00 | 1 (0) / 0.00 | 2 (0) / 0.02 | 0 (0) / 0.00 | 0 (0) / 0.00 |
| boxer | rare+0 | epic+0 | 0 (1) / 0.00 | 0 (1) / 0.00 | 1 (0) / 0.00 | 2 (0) / 0.01 | 0 (0) / 0.00 |
| boxer | epic+10 | legendary+0 | 12 (0) / 0.74 | 12 (0) / 0.56 | 12 (0) / 0.51 | 12 (0) / 0.53 | 12 (0) / 0.44 |
| boxer | rare+10 | legendary+0 | 12 (0) / 0.59 | 12 (0) / 0.39 | 12 (0) / 0.34 | 10 (1) / 0.26 | 4 (0) / 0.05 |
| boxer | legendary+7 | godforged+0 | 0 (0) / 0.00 | 12 (0) / 0.27 | 12 (0) / 0.44 | 12 (0) / 0.40 | 12 (0) / 0.37 |
| boxer | legendary+10 | godforged+0 | 3 (0) / 0.03 | 12 (0) / 0.47 | 12 (0) / 0.54 | 12 (0) / 0.58 | 12 (0) / 0.60 |
| grappler | epic+0 | legendary+0 | 12 (0) / 0.34 | 0 (0) / 0.06 | 0 (1) / 0.08 | 0 (0) / 0.07 | 0 (0) / 0.13 |
| grappler | legendary+0 | godforged+0 | 0 (0) / 0.00 | 0 (1) / 0.03 | 0 (0) / 0.06 | 0 (0) / 0.05 | 0 (0) / 0.12 |
| grappler | rare+0 | epic+0 | 0 (1) / 0.01 | 0 (1) / 0.01 | 2 (0) / 0.02 | 1 (0) / 0.03 | 0 (0) / 0.02 |
| grappler | epic+10 | legendary+0 | 12 (0) / 0.75 | 12 (0) / 0.58 | 12 (0) / 0.59 | 12 (0) / 0.56 | 12 (0) / 0.66 |
| grappler | rare+10 | legendary+0 | 12 (0) / 0.67 | 11 (0) / 0.46 | 12 (0) / 0.45 | 8 (2) / 0.36 | 6 (0) / 0.35 |
| grappler | legendary+7 | godforged+0 | 0 (0) / 0.02 | 11 (1) / 0.36 | 12 (0) / 0.56 | 12 (0) / 0.54 | 12 (0) / 0.59 |
| grappler | legendary+10 | godforged+0 | 6 (0) / 0.11 | 12 (0) / 0.56 | 12 (0) / 0.59 | 12 (0) / 0.68 | 12 (0) / 0.67 |

What the arena shows [Simulated]:

- **The arena is extremely gear-sensitive.** With the same job and the same AI on
  both sides, the side with the stronger counted stats wins nearly every match.
  Win counts saturate at 12/12 or 0/12; the HP share left shows the margin.
- **Today (M0):**
  - Epic +0 beats the Lv 70 "Legendary" kit 12/12, the reported problem again.
  - Legendary +10 rarely beats Godforged +0 (3/12 and 6/12).
- **With the proposed Legendaries (M0L, MR, MB, MA):**
  - Legendary +0 beats Epic +0 12/12.
  - Epic +10 and Rare +10 still beat Legendary +0. In MR, Rare +10 wins 12/12 with
    0.34–0.45 HP left, against 0.59–0.67 today.
  - Under MA, Rare +10 mostly loses to Legendary +0 (4/12 and 6/12).
- **Legendary +7 beats Godforged +0 in every model with the new Legendaries.** In
  MR it wins 12/12 with 0.44–0.56 HP left.
  - Partly this is Godforged's 14% of budget in capped crit and attack speed
    (§10, G-R).
  - Partly it is enhancement's ×1.7 on every positive stat.
  - If Godforged should stay ahead of Legendary +7 in PvP, G-R or a raise is
    needed.


## 10. Godforged preservation

- **MR and M0L change nothing about Godforged.** That covers its stats, the eight
  world boss reward rules, the three raid tables and labels, and drop rates.
- **For approval, listed separately (not recommended):**
  - Model B as written needs every Godforged item ×1.47 (25 items).
  - Model A needs ×2.70.
  - Either would also need world boss pools, enrage and arena tiers t6–t9
    re-tuned.
  - The middle path (Godforged ×1.2) is the smallest raise that gives about +25%
    steps.
- **A lower-risk Godforged option (G-R, for approval, not part of MR):** re-mix
  without raising.
  - The Lv 70 Sovereign set spends 222 of its 1,618 score points (14%) on crit
    beyond the 50% cap and attack speed beyond +0.3. These do nothing.
  - Moving them into power (+1.11) and max HP (+222) at the same score would
    raise its damage index from 14.76 to 16.56. EHP vs monsters would go from
    9,831 to 11,199, and PvP EHP from 5,710 to 6,504 [Modeled].
  - That widens Godforged's lead over an MR Legendary kit (12.01 damage, 5,319
    PvP EHP) without changing its budget, rewards or sources.
  - It does change Godforged item stats, so it is listed separately.

## 11. PvE and PvP impact

### PvE

- **MR:**
  - Leaves Lv 1–35 essentially as today. The steps there change by 0–6%, inside
    the simulation noise.
  - Makes Lv 39–70 Epic and Legendary noticeably safer and a little faster.
  - Restores Legendary between Epic and Godforged against world and raid bosses.
  - No knock-out pattern changes, and no boss becomes trivial.
- **MB:**
  - Endgame farming 12–30% faster.
  - Damage taken roughly halved again.
  - Legendary +0 at the monster damage floor (modeled).
  - Raid shares up by about 15–50%.
  - Needs the Godforged raise and world boss re-tuning.
- **MA:**
  - Trivialises monsters and stage bosses from about Lv 37 (damage taken per
    fight 21–358 at Lv 48–70 with Epic and Legendary kits).
  - Doubles raid speed.
  - Would require a full PvE re-tune.
- **Progression difficulty:**
  - Nothing in any model makes progress harder, because Common and Uncommon are
    unchanged.
  - MB and MA make it much easier past Lv 35.

### PvP

- **Gear decides same-skill matches** in all models. The grade spacing matters
  less than the order: which kit has the stronger counted stats.
- **Enhancement dominates grade in PvP today and under MR.**
  - Epic +10 and Rare +10 beat Legendary +0.
  - Legendary +7 beats Godforged +0.
- **Arena tiers:**
  - t5 (Epic, Legendary and Godforged, Lv 44–70) will sit higher, because rivals
    pick the new Legendaries automatically.
  - t6–t9 (Godforged +1 to +7) keep their lead over t5 +0 rivals.
  - A t5 rival at Legendary +7 would beat a t6 Godforged +1 rival. Today t5
    rivals are +0 (`arena.json`), so that does not happen in the ladder.
- **Fairness:** a wider grade gap (MB, MA) makes PvP more pay-to-grind. MR keeps
  the gap closest to today while restoring the order.
- **Before any change ships:** re-run `ArenaBalance` (tiers) and `DuelCheck`
  (jobs) after it.


## 12. Risks and implementation dependencies

- **Tests that encode today's numbers:**
  - `test_level70_gear` (the Godforged/Legendary budget ratio, tiers and sources),
    `test_item_grades` (grades in order, every item on budget) and
    `test_item_catalog` (catalog budgets).
  - The arena integrity and class-balance tests.
  - The drop database and Guide documents (`DropReportRun.gd`).
  - All must be updated or re-run in the same change.
- **Content generator:** `tools/content/level70_content.py` prices the 50–70 gear
  from the budget. Rescaling should go through it, with the catalog's grade table
  (`item_catalog.json`), not by hand.
- **Enemy curve:**
  - `LevelRules` assumes gear keeps the hero ahead.
  - MR raises a Lv 70 Epic kit's power by +0.2 and HP by about +50 (§2.3). That
    is small.
  - MB and MA change the PvE difficulty curve (§9).
- **Arena:** rivals are rebuilt from data by `ArenaLoadout.best_item`, so they
  follow any change. Tiers t4/t5 sit closer to t6–t9 under MR.
- **Economy:**
  - Sell values follow the budget (`ItemRules.value`), so they rise with MR for
    Rare and above: +6% to +12.5%.
  - New Legendaries add sellable value.
- **Saves:** no migration. Stats are read from data, and enhancement stays per
  copy.
- **Sources:** the 12 Legendaries need drop entries. That is a reward change and a
  separate approval.
- **Sample size:** the simulations use 2–12 runs per cell. Confirm any change with
  the full harnesses before shipping (`FarmCheck`, `EnrageCompare`,
  `WorldBossCheck`, `ArenaBalance`, `DuelCheck`).

## 13. Prioritised implementation plan (nothing done; each step waits for approval)

| # | Step | Kind | Depends on | Effort | Risk |
|---:|---|---|---|---|---|
| 1 | Show capped crit and attack speed on the stat sheet and item cards (option C) | UI | – | small | none |
| 2 | Add the 12 Lv 55–70 Legendaries at today's weights (M0L), with sources from the lair mini-bosses | content and drops | approval of IDs, names (Story Bible) and sources | medium | low (new items only) |
| 3 | Choose the model (MR recommended) and change `ItemRules.GRADES` | rule | decision | small | medium |
| 4 | Rescale Rare, Epic and Legendary through the content generator; regenerate the drop database | data | 3 | medium | medium |
| 5 | Per-slot crit and attack-speed ceilings in the content check (D), and move the excess (A) | rule and data | 3, 4 | medium | medium |
| 6 | Inversions: the `used_street_runners` trim and the speed-specialisation allowlist test | data and test | 3 | small | low |
| 7 | Defense: the D3 budget share from Lv 50 (data); decide D1 (formula) separately | data / rule | 4 | medium | medium–high |
| 8 | Full harness pass (farming, lairs, world bosses, arena, duels) and update the balance docs | measurement | 2–7 | medium | – |
| – | Godforged raise (Model B or A, or the middle path) | rule and data | your decision | large | high |

## 14. Decisions for you

1. The model: MR, MB with a Godforged raise, MA with a Godforged raise, or the
   middle path.
2. The 12 Legendary items: IDs, Story Bible names, levels, slots and the lair
   mini-boss sources (6% pity).
3. The footwear mix: the Epic-style mix, or F2 (no movement speed).
4. The Legendary re-mix of crit into power or HP (L-R).
5. Cap handling: C, D and A, and whether to try B.
6. Defense: D3, and whether to change the PvE formula (D1).
7. The inversion handling (§6.4).
8. Godforged: no change (MR), the re-mix G-R, or a raise (§10).

