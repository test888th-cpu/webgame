# City Hub and Farming Areas: Blueprint

> **Status:**
> - Phase 1 (this plan) was reviewed by the owner.
> - **Phase 2 is built: Iron City Central (`main_city`)**, a separate city map. See
>   §12.
> - The owner **rejected** §3's recommendation to grow Depot Yard into the hub.
>   Depot Yard (Story Area 1) stays exactly as it is on `main`, but for Win's line,
>   which the owner replaced (the taxi goes beyond South Street now).
> - **Phase 3 is built: the seven farming grounds** (`kind: "farm"` in `areas.json`).
>   §4.2's table was the proposal; the built line-ups, unlocks and measured rewards are
>   in CHANGELOG.md and STORY_BIBLE.md. Built since: repeat fights (§4.2's loop mode,
>   as a refill at the ground's west end, `StreetMemory.refill`) and auto battle in
>   an open ground. Open: final levels and line-ups.
> - **Story and hub kept apart (owner decision, 2026-11-03):** the farming grounds and
>   the world boss arenas are reached from Iron City Central only (Win's taxi there;
>   the story's taxis offer the city and the story areas) and lead back to it: walking
>   out west, a finished world boss attempt and auto battle's rest from a ground all
>   end in the city (`AreaRules.hub`). The story's way home stays Depot Yard. The Map
>   shows two sections, STORY and IRON CITY CENTRAL. This replaces §4's and §5's
>   "west exit to `depot_yard`".
>
> - **Living fields (2026-11-03):** each ground's fixed fights became a living field
>   (`"spawning"` in `areas.json`, `sim/FarmSpawner.gd`): up to 4 enemies standing,
>   one more after each loss, entrances away from the hero, a safe spot at the west
>   end, 1 in 20 an elite (×3 HP, ×3 XP and coins, gold name). Nothing walls the hero
>   in and nothing is saved. Respawn times are tuned per ground so income per minute
>   stays near the old loop's (CHANGELOG). The refill mechanism
>   (`StreetMemory.refill`) stays for any ground with fixed fights.
>
> - **Camps (2026-11-03, owner's request):** the field is now camps standing across
>   the ground, as in field-farming games. Each ground has 4 camps of 3
>   (`"camps"`, `"camp_size"`, `"aggro"` in `areas.json`).
>   - A camp waits at its spot until the hero comes within its aggro radius or strikes
>     one of it. Then the whole camp comes; the others stay put.
>   - A chase too far from home ends with the enemy walking back and healing there.
>   - A camp short of enemies gets one back each respawn time, only while the hero is
>     away from it.
>   - This replaces "up to 4 standing, one more after each loss" above. With several
>     players in one ground (IL-7), each pulls the camps near them.
>
> Sections 1 to 11 are the Phase 1 plan as written, kept for the record. Where §3, §6, §7,
> §10 or §11 talk about widening Depot Yard, §12 replaces them.
>
> Audited on 2026-11-02 at commit `f8bc743` (main after PR #53). Where this document
> and `client/data/*.json` disagree, the JSON is right. Story, names and places come
> only from [STORY_BIBLE.md](STORY_BIBLE.md); every name below marked *(working name)*
> needs a story-bible entry before it is used in the game.

**Labels used on every statement**

| Label | Meaning |
|---|---|
| **[V]** | Verified existing feature: read in the source or data, or seen in a test run |
| **[P]** | Proposed new feature: does not exist yet |
| **[?]** | Unknown, or needs more inspection or an owner decision |

---

## 1. Verified current state

### 1.1 Checks run in this session

| Check | Result |
|---|---|
| `tools/ci/install-godot.sh` | **[V]** Godot 4.7.2.stable.official.ed1daf0bf installed, SHA-512 verified |
| `godot --headless --path client --import` | **[V]** exit 0 |
| `godot --headless --path client --script res://tests/TestRunner.gd` | **[V]** **393 passed, 0 failed**, exit 0 |
| `tools/ci/check-repo.sh` | **[V]** exit 0 |
| GitHub Actions CI on `main` at `f8bc743` (run 146) | **[V]** success |
| `gdformat --check` / `gdlint` | **Not run.** gdtoolkit is not installed here and no GDScript changed. CI runs it. |
| Backend `npm run typecheck` / `npm test` | **Not run.** The tests need PostgreSQL 16, and this container has Node 22, not the pinned 24.22.1. CI ran them green on run 146. |
| Web export + browser smoke test | **Not run.** This needs the web templates and Chromium. CI ran them green on run 146. |

### 1.2 Scenes and how the game moves between places

- **[V]** Only four real scenes: `title/Title.tscn` → `create/CharacterCreate.tscn` →
  `game/Game.tscn`, plus `tools/Gallery.tscn`. **Each map is data, not a scene.**
  `Game.enter_area()` (`client/scenes/game/Game.gd:96`) builds a new `ZoneSim` (rules)
  and `ZoneView` (drawing) from an `areas.json` entry. So a new place means new data,
  not a new `.tscn`.
- **[V]** Exits support only `west` and `east` (`ContentDB.EXIT_SIDES`). An east exit can
  be gated (`requires: {defeat, count, hint}`). The way back west is always open.
- **[V]** "The street" is worked out by walking east from `start_area` (`depot_yard`)
  (`StreetMemory.street`). Districts start at the area named in `areas.json`
  `districts[].from` (`MapRules.districts`). An area that the east chain never reaches
  is "off the street", like the world-boss arenas.
- **[V]** Ways to travel: walking between neighbours; **Win's motorbike taxi**
  (`role: "travel"`, fare 10) to any area visited before
  (`StreetMemory.destinations`) or to an open world boss; **Recall** from the pause menu
  straight to `start_area`, which is refused during a fight (`ZoneSim.recall_problem`);
  getting back up after a knockout at the west end or just before the boss (`_recover`).

### 1.3 Story stages: target compared with the repository

| Design target (Phase 1 brief) | What the repository has | Label |
|---|---|---|
| 5 story chapters | **6 story districts/chapters**: South Street (Prologue + Ch 1), Port District (Ch 2), Industrial District (Ch 3), The Black Network (Ch 4), The Core Facility (Ch 5), Main Control Centre (Final). Quests are labelled the same way (`quests.json` `chapter`). | **[V]** mismatch |
| 10 sub-stages per chapter, 50 in total | **30 combat areas**: Ch 1 has 10, and Ch 2 to Final have **4 each** (5 × 4 = 20). Depot Yard (safe) and 3 world-boss arenas are extra. In total `areas.json` has 34 areas. | **[V]** mismatch |
| A miniboss and a stage boss in every stage | **11 story bosses in 30 areas.** By `MapRules.kind_of`, a boss in the last area of a district is a **stage boss** and any other boss is a **mini-boss**. Stage bosses (6): Furnace Baron, Harbourmaster Chen, Unit K-7, Big Sak, Commander Arthit, Director Wiroj. Mini-bosses (5): Sludge Foreman, Pit Champion, Security Chief Nattapong, The Ringmaster, Subject 12. There are also 7 elites (`elite: true`). 19 areas have no boss. | **[V]** mismatch |
| 3 world bosses | Tunnel Mother (Lv 32, 3 players, every 3 h), Iron Colossus (Lv 52, 5 players, every 6 h), Subject Zero (Lv 55, 10 players, daily 20:00 Thai time) in `world_boss.json`. Each has its own arena. They do not scale and have no entry level. | **[V]** matches |
| Max level 50 | `progression.json` `max_level: 50`. Area levels run 1 to 48, and Wiroj fights at 50. | **[V]** matches |

**[?] Owner decision Q1:** the 50-stage target conflicts with the approved story bible
(6 chapters, 30 areas) and with D11's level bands. This phase does **not** invent 20
more stages or 39 more bosses. See §9 for the options. The hub and farming plan below
works with either answer.

Area list **[V]** (level, `→` gate to pass east):

| District | Areas (level) |
|---|---|
| South Street | Depot Yard 1 (safe hub) · Saltmarket 2 → Smog Warden · Canal Works 3 (mini-boss Sludge Foreman) · Rusted Corner 4 · Parking Lot 5 · Rail Yards 6 · Night Market 7 (shop, taxi) · Fight Club 8 (mini-boss Pit Champion) · Refinery 9 · Rat Nest 10 · Gang HQ 10 (**Furnace Baron**) |
| Port District | Port Road 12 (quests, shop, taxi) · Freight Market 13 · Container Yard 15 · Crane Yard 16 (**Chen**) |
| Industrial District | Factory Gate 19 (quests, shop, taxi) · Production Line 21 (mini-boss Nattapong) · Waste Pools 23 · Factory Drains 24 (**K-7**) |
| The Black Network | Warehouse Row 26 (quests, shop, taxi) · Underground Ring 27 (mini-boss Ringmaster) · Counting House 29 · Rattanachai Tower 31 (**Big Sak**) |
| The Core Facility | Core Facility Gate 33 (quests, shop, taxi) · Test Labs 35 (mini-boss Subject 12) · Machine Hall 37 · Control Room 39 (**Arthit**) |
| Main Control Centre | Core Approach 42 (quests, shop, taxi) · Cooling Tunnels 44 · Reactor Walkway 46 · Core Chamber 48 (**Wiroj**, Lv 50) |
| Off the street | The Great Drain, The Old Scrapyard, The Sunken Reservoir (world bosses; you can only arrive by taxi, and the west exit leads to Depot Yard) |

### 1.4 Home base, NPCs, shops, quests, interaction

- **[V]** NPC roles are only `shop`, `quests` and `travel` (`ContentDB.NPC_ROLES`). You
  talk to an NPC with E (`Game.try_interact`). The world shows `$`, `!` and `>>` marks.
- **[V]** Depot Yard is the **only** area with `safe: true` and `heal_on_enter: true`.
  Walking in, taking the taxi or using Recall there **heals the hero and resets every
  street's fights** (`ZoneSim` → `StreetMemory.rest`). That reset is what lets players
  farm.
- **[V]** Depot Yard (width 960) holds Ama (shop `depot_stall`), Chief Odo (quests),
  Win (taxi) and a training dummy. It is also where the tutorial happens (save v4).
- **[V]** Each later district's first area has quests, a shop and a taxi, but is
  **not** safe. 7 shops are in `shops.json`.
- **[V]** 31 quests, **all `defeat` objectives**, one main chain per chapter (Odo, Chai,
  Pim, Kenji, Pim, Pim). There are no repeatable, daily or side quests. Rewards are
  money, XP and items. The 10 evidence items are `type: key`.
- **[V]** There is no workbench NPC or object. Upgrading is a button on the item card
  of worn gear, and it only works where `zone.area.safe` is true (`Game._upgrade`), so
  in practice only in Depot Yard.

### 1.5 Enemies, waves, bosses

- **[V]** 38 enemy kinds in `enemies.json`: 14 with `boss: true` (11 story bosses + 3
  world bosses), 7 `elite`, 3 `ranged`, 5 that `summon`, 6 with `hazard`s, and phases
  for every boss.
- **[V]** An area has `encounters[]`. Each encounter has a `trigger_x`, an `arena` that
  locks the camera, `max_alive` and `waves` (a list of lists of enemy ids). Enemies fight
  at the area's level (+1 for an elite, +2 for a boss; `LevelRules`). World bosses fight
  at the fixed level in `world_boss.json`.
- **[V]** Fights already won stay won until the hero rests (`StreetMemory.cleared`).
  If an east gate is still shut, all of that area's fights come back. In an area
  already passed, fights that came back after a rest hold no one in (fixed after
  Phase 3; `StreetMemory.passed`).
- **[V]** Only the training dummy respawns (`respawn_ticks`). No area has a looping or
  endless spawner.

### 1.6 Items, rarity, equipment, enhancement

- **[V]** 70 items: 54 equipment, 4 consumables, 2 materials (`scrap_metal`,
  `refined_alloy`) and 10 keys (evidence).
- **[V]** Rarities: common, uncommon, rare, epic and legendary. Equipment by rarity:
  5 / 5 / 26 / 6 / 12.
- **[V]** Six slots: head, body, hands, weapon, feet, charm (decision D7). The stats are
  `max_hp, power, defense, speed, crit, attack_speed`.
- **[V]** Enhancement +0 to +10: `EnhanceRules` + `progression.json` `enhance` (coins +
  materials, 100% down to 20% success, +5% pity per failure, +10% of the item's stats per
  level). An upgrade belongs to one copy of an item (save v10, `PlayerProfile.own_copy`).
- **[V]** Loot is decided **by enemy kind, not by area**: `enemies.json`
  `loot.money/drops[{item, chance}]`, rolled by `LootRules` with the zone's seeded RNG.
  Area level scales XP (+15%/level) and coins (+12%/level), not drops (`LevelRules`).
  Early enemies also appear in later chapters (for example Smog Warden up to Waste Pools,
  Lv 23), and they carry their early drop table there.
- **[V]** Every item has at least one source (checked with a script over enemy loot,
  shops, quest rewards, hero starter kits and world-boss tiers/rolls):
  - drops: 50 items;
  - shops: 38 items;
  - quests: the 10 keys, `brass_whistle` and others;
  - starter kits: `heroes.json` `starter`;
  - world-boss rewards only: `mothers_fang`, `mothers_heart`, `colossus_core`,
    `piston_gauntlets`, `zeros_mantle`, `iron_legacy`.
- **[V] Gap:** `ContentDB.sources()` (the item card's "WHERE TO GET") lists drops, shops
  and quests only. **The 6 world-boss legendaries show no source in the game**, and
  starter-kit items do not list it as a source.
- **[V]** Only one drop is far from its area's level: `iron_wraps` (rare, needs Lv 5)
  drops at 35% from Smog Warden, which first appears in Lv 2 Saltmarket.
  This is noted for the drop phase, not changed here.

### 1.7 Save/load and progression

- **[V]** `SaveStore` holds up to 4 characters per account (`max_characters`) in local
  `user://` storage, at `SAVE_VERSION = 10` with step-by-step migrations. It saves on
  entering an area, on hiding the tab, after trades and after upgrades.
- **[V]** `PlayerProfile` keeps hero, level, xp, money, hp, inventory, equipment,
  quests, `defeated` counts, area, tutorial, enhance/pity, hotbar, `cleared`,
  `visited` and `world_boss`.
- **[V]** XP curve: `progression.json` `xp`. Each level adds HP and power. A knockout
  costs 10% of the hero's money. Shops buy at 30% of the price.
- **[V]** Auto battle (D7/D12) works only in areas already beaten by hand
  (`AutoRules.is_beaten`). Its farm loop: clear the area or run low → Recall home →
  restock food at the home shop → pay the taxi back (`AutoBattle.gd`).

### 1.8 Online and backend

- **[V] Built:** `backend/` Fastify API with `/healthz` and `/readyz`, one migration
  (`0001_accounts.sql`: the `accounts` table), Docker image, CI.
- **[V] Not built:** auth, sessions, hero persistence on the server, zone servers,
  `client/net/`, parties, guilds, trading, mail. All of these are planned for IL-7
  (ROADMAP M3 to M6, decision D4). The world-boss pool belongs to one player today.
- **[V]** The game is single-player and saves are local. The client is not
  authoritative by design: rules live in `sim/`, and rewards come from `ZoneSim`.

### 1.9 Assets that can be reused for a city or farms

- **[V]** 37 painted environment sets in `client/assets/environment/*` (sky, far,
  buildings, ground). Every story area and arena has one.
- **[V]** The street kit (`art/kit/kit.json`) has 11 themes: market, depot, canal,
  junkyard, fight_club, carpark, tunnels, gang_hq, docks, plant, waste. Its pieces include
  convenience store, noodle shop, pharmacy, food cart, bus stop, guard booth, barrier
  booth, blank signs, motorbike row, plastic stools, potted plants and stray animals.
  That is enough to dress a city square without new art.
- **[V]** NPC sprites: Ama, Chai, Jum, Kenji, Lek, Noi, Odo, Pim, Thong, Win.
- **[V]** Obstacle kinds are data (`obstacles.json`) and solid (`Bodies`).

### 1.10 Documentation that no longer matches the code (found, not fixed here)

| Document | Says | Actually |
|---|---|---|
| README.md CI table | "225 unit/scene tests" | 393 |
| GAME_DESIGN.md | "eight areas", "15 items", Refinery has the Furnace Baron, area scaling "+20% HP… XP +25%" | 34 areas, 70 items, the Baron is in Gang HQ, `LevelRules` uses +6% HP / +15% XP / +12% coins |
| GAME_DESIGN.md "Upgrades" | "Depot workbench" | There is no workbench object. It is an item-card button in a safe area. |

---

## 2. Systems that must stay unchanged

These work and are covered by tests. Phase 2 extends them and must **not** rewrite them.

| System | Files | Why it matters for this plan |
|---|---|---|
| Combat, movement, bodies, AI, boss mechanics | `sim/CombatRules`, `Fighter`, `LaneMovement`, `Bodies`, `EnemyBrain`, `BossMechanics` | Farms reuse them as they are |
| Zone simulation, encounters, waves, gates | `sim/ZoneSim`, `areas.json` schema | Hub and farms are new `areas.json` entries |
| Street memory (cleared, visited, rest) | `sim/StreetMemory` | The reset on rest is the farm reset |
| Loot rolls, enemy loot tables, money ranges | `sim/LootRules`, `enemies.json` `loot` | **No drop changes in this phase or the next** |
| Items, equipment, rarity, starter kits | `items.json`, `heroes.json`, `PlayerProfile` | No new items |
| Enhancement +0 to +10 | `sim/EnhanceRules`, `progression.json` | The hub reuses it and adds no second upgrade system |
| Shops, economy | `sim/ShopRules`, `EconomyRules`, `shops.json` | The hub reuses the shop role |
| Quests and story | `sim/QuestRules`, `quests.json`, STORY_BIBLE | The hub only moves where quests are handed out, if the owner agrees |
| World bosses | `sim/WorldBossRules`, `WorldBossRun`, `world_boss.json` | The hub only adds a clearer way in |
| Auto battle | `sim/AutoPilot`, `AutoRules`, `scenes/game/AutoBattle` | Farms must be auto-capable, extending `is_beaten` only |
| Save format v10 + migrations | `scripts/core/SaveStore`, `PlayerProfile` | The plan aims for **no save version change** |
| Map / route HUD | `sim/MapRules`, `MapTab`, `MiniMap` | Extend it with a new row, like the World Bosses row |
| `window.ironboundProbe` | `tools/web-smoke/smoke.ts` | Stays read-only |
| Stable ids | everything | No id is renamed (old saves reference them) |

---

## 3. Main City Hub

### 3.1 Recommendation: grow Depot Yard into the hub, keeping its id **[P]**

Many things are tied to `start_area = depot_yard` **[V]**:

- healing and resetting the streets on entry;
- the only safe flag, which allows upgrades;
- the Recall target;
- the auto-battle loop's home;
- the west exit of every world-boss arena;
- the tutorial;
- where new characters start;
- the start of the east chain that defines the street and its districts.

A brand-new hub area would have to rewire each of these, or would end up inside the
South Street district. **Keeping the id `depot_yard` and widening that area keeps every
one of these working with no save change.**

Alternative (not recommended): a new safe area west of Depot Yard, reached by its
unused `west` exit. It would have to become `start_area`, and then `StreetMemory.street`
would count it as the first South Street area, which shifts the district numbers in the
HUD and the map. **[?]** If the owner wants a separate hub map anyway, decide this
before Phase 2.

The display name stays "Depot Yard" until STORY_BIBLE names the hub. **[?]**

### 3.2 Layout (one street, about 1,920 px, walked in under 10 s) **[P]**

The base viewport is 640 px wide **[V]**, so the hub is about 3 screens wide.

```
 x:  0        320        640        960        1280       1600       1920
     |  WEST: SOCIAL   |  SERVICES        |  TRAINING / UPGRADE |  DEPARTURES  |
     |  (reserved)     |                  |                     |              |
     | [blank signs]   | Ama: shop $      | training dummy      | Win: taxi >> |
     | [stools, plants]| Chief Odo: quests| WORKBENCH (upgrade) | DEPARTURE    |
     |  future guild / |   and main story | weapons rack        |  BOARD       |
     |  trade / mail   |                  |  (existing pool)    | east exit →  |
     |  NPC spots      |                  |                     | Saltmarket   |
     ^ west exit stays unused (keeps the street definition intact)
```

| Service | Where | How it works | Status |
|---|---|---|---|
| Shop | Services block | Ama, `role: shop`, `depot_stall` unchanged | **[V]** exists; **[P]** moved within the area |
| Quests / story | Services block | Chief Odo, `role: quests` | **[V]** exists |
| Equipment and enhancement | Training block | **Workbench** object: pressing E opens the Character screen's Equipment tab, which has the existing upgrade buttons. It calls the same `Game._upgrade` and `EnhanceRules`. Nothing about upgrading itself changes. | **[P]** a new interaction point, no new system |
| Training dummy and weapons | Training block | Existing `placed` dummy and `weapons` pool | **[V]** exists; **[P]** moved |
| Story entrance | Departures | Walk east, as today, or take the taxi to any area reached | **[V]** exists |
| Farming areas | Departures | Departure board / Win: "Farming" list (§4) | **[P]** |
| Boss rematches | Departures | Departure board / Win: "Bosses" list (§4.3) | **[P]** |
| World bosses | Departures | Win's world-boss rides, as today, under their own heading | **[V]** exists; **[P]** regrouped |
| Guild, trade, social | West block | **Only empty space and set dressing** (blank signs, stools). No NPC, role, data or UI until IL-7. | **[P]** reserved space only |

Navigation rule **[P]**: the hub is the home of every trip. Recall (exists) brings you
back from anywhere outside a fight, and one menu takes you to any story area, farm, boss
or world boss you have unlocked. Nobody has to walk the street to farm.

### 3.3 The departure menu: extend Win's taxi, do not add a second travel system **[P]**

`GameMenus.travel` already lists visited areas and world bosses **[V]**. Phase 2 groups
that one menu under headings: **Story** (existing `StreetMemory.destinations`),
**Farming**, **Bosses** and **World Bosses** (existing). The "Departure board" is a
second NPC/object in the hub with the same `role: travel`, so it opens the same menu.
Fares stay as they are in the data (Win's `fare`).

Should the other district taxis (Night Market, Port Road and the rest) show Farming and
Bosses too, or only the hub? **[?]** The recommendation is only the hub, so everything
starts from home.

---

## 4. Farming areas

### 4.1 How farming works today **[V]**

Players can already farm: rest at the Depot (fights come back) → taxi to a beaten area →
fight, or switch on Auto → Recall → repeat. This plan improves it in these ways:

- Story areas are long (1,500 to 2,600 px, 2 or 3 encounters) and mix in story beats.
- A rest refills every street at once, so farming one area means a round trip every
  time.
- The mini-bosses and stage bosses sit at the end of long areas.
- The map does not show where to farm a particular item.

### 4.2 Proposed ordinary farming grounds (one per level band) **[P]**

- **Data only:** each farming ground is a new `areas.json` entry. It is off the street,
  so it adds nothing to the east chain, just like the world-boss arenas.
- **Shape:** short (about 1,200 to 1,400 px), with 1 or 2 encounters.
- **Reuse:** each one uses an **existing environment set, kit theme and existing enemy
  kinds** from its chapter.
- **Exit:** its west exit goes to `depot_yard`.
- **Unlock:** when the matching story area has been visited (from `profile.visited`,
  so nothing new is saved).

| # | Working name *(needs a STORY_BIBLE entry)* | Reuses environment / kit | Enemies (existing) | Area level | Intended hero levels | Unlocks after visiting |
|---|---|---|---|---|---|---|
| F1 | Saltmarket Backlots | `saltmarket` / market | smogling, tar_hound, pipe_brute, street_thrower | 4 | 2–7 | Rusted Corner |
| F2 | Rail Sidings | `rail_yards` / carpark | dock_thug, rail_bruiser, market_punk | 9 | 7–12 | Refinery |
| F3 | Harbour Stacks | `container_yard` / docks | stevedore, port_guard, dock_slinger | 15 | 12–18 | Container Yard |
| F4 | Plant Outskirts | `waste_pools` / waste | plant_guard, hazmat_sprayer, patrol_unit | 22 | 18–25 | Waste Pools |
| F5 | Network Backrooms | `counting_house` / gang_hq | network_runner, network_enforcer, ring_fighter | 29 | 25–32 | Counting House |
| F6 | Facility Annex | `machine_hall` / plant | facility_trooper, riot_trooper, hybrid_worker | 37 | 32–40 | Machine Hall |
| F7 | Core Overflow | `cooling_tunnels` / tunnels | hybrid_brute, core_sentinel, facility_trooper | 46 | 40–50 | Reactor Walkway |

- Every level, environment and enemy above already exists in the data **[V]**. The
  levels follow the D11 chapter bands **[V]**. The groupings, the area levels and the
  unlock points are **[P]** and can be tuned.
- Seven grounds, not dozens: one shared template (width, two encounters, same obstacle
  pattern) is filled with seven sets of data.
- **Loop mode [P]:** a farm area re-arms its encounters once all of them are won, so the
  hero can farm one place without a round trip. This would be a new optional area flag
  read by `StreetMemory.pending`/`ZoneSim`, with a short breather between waves. It is
  the only new sim rule farming needs, and it gets unit tests. Without loop mode, farms
  still work through Recall and rest.
- **Elites [P]:** the last wave may hold the chapter's elite (it is already in the
  enemies list). Bosses never appear in ordinary farms.

### 4.3 Boss activities stay separate from ordinary farming **[P]**

| Activity | Content | How it works | Status |
|---|---|---|---|
| Ordinary farm | normal + elite enemies | §4.2 | **[P]** |
| Mini-boss rematch | Sludge Foreman, Pit Champion, Nattapong, Ringmaster, Subject 12 | A short arena per boss, reusing that boss's area environment, with one encounter: the boss and its usual escort. Unlocks when `profile.defeated[boss] > 0`, the same pattern as `world_boss.json` `unlock`. | **[P]** |
| Stage-boss rematch | Baron, Chen, K-7, Big Sak, Arthit, Wiroj | Same as the mini-boss rematch. Boss hazards (crane, steam vents, lasers) already belong to the enemy data **[V]**, so they come along. | **[P]** |
| World boss | Tunnel Mother, Iron Colossus, Subject Zero | **Unchanged** (clock, pool, tiers, no auto) | **[V]** |

- Rematches can also be written as data (`areas.json` entries like the world-boss
  arenas).
- Whether rematches allow auto battle is **[?]** Q3. Today auto may fight bosses in
  beaten areas **[V]**.
- Whether rematches give the boss's full loot every time is **[?]** Q4. Today you can
  already refight bosses after a rest, so this changes how fast loot comes, not the
  loot itself. It is decided in the drop phase, not here.

### 4.4 What farming will not do in Phase 2

- No new items, no drop-rate changes, no new enemy kinds, no new art.
- No per-area loot overrides. Loot stays per enemy (§5).
- No new currency or stamina limit.

---

## 5. Future unified drop table (planning only)

### 5.1 Where item sources live today **[V]**

| Source | File and field | Shown on the item card? |
|---|---|---|
| Enemy drops | `enemies.json` `loot.drops[{item, chance}]`, `loot.money` | Yes (`ContentDB.sources`) |
| Shops | `shops.json` `items[]` and `items.json` `price` | Yes |
| Quest rewards | `quests.json` `rewards.items` | Yes |
| Starter kits | `heroes.json` `starter.items/equipment` | **No** |
| World-boss tiers, kill, rolls | `world_boss.json` `tiers[].items/rolls`, `kill` | **No** (gap §1.6) |
| Street weapons | `areas.json` `weapons`, `weapons.json` | Not items (they cannot be picked up into the bag) |

### 5.2 What the drop phase needs **[P]**

1. **Generated source report.** A tool script, run in CI, produces one table: item →
   every source → area(s) and area level → required level → rarity → chance. It is built
   from the files above, like `ContentDB.sources`, so it can never disagree with them.
   Phase 2 adds only a **test** that every item has at least one source (true today).
2. **One source function.** Extend `ContentDB.sources()` with world-boss and starter
   entries, so the item card and the report share one function. This fixes the in-game
   gap and does not change any rate.
3. **Agreed dimensions** for the later table:
   - rarity by chapter band (rare = shop/elite, epic = mini-boss, legendary =
     stage/world boss, as the data mostly does now);
   - required level against the level of the area where it drops (`iron_wraps` is the
     only one outside ±2/−8);
   - slot coverage for each chapter;
   - the enhancement material flow: scrap and alloy per hour per farm, compared with
     the +0 to +10 costs in `progression.json`;
   - the hero's level against the enemy's level (`LevelRules.xp_scale` already cuts XP
     for weak enemies).
4. **[?] Q5:** should loot stay purely per enemy, or should areas (farms) be allowed a
   bonus table? A per-area table is a new system. Decide it in the drop phase.
5. **Online:** drop rolls must move to the zone server (ARCHITECTURE D5). Keeping every
   table as data in `sim/` rules keeps that possible.

---

## 6. Scene transitions and navigation

```
 Title ─► Character select / create ─► Game.tscn (one scene; areas are data)
                                         │
              ┌──────────────────────────┴───────────────────────────┐
              ▼                                                      │
        HUB (depot_yard, safe, heals + rests)  ◄──── Recall (pause menu, not mid-fight) [V]
         │ walk east [V]           │ Win / Departure board (one travel menu)
         ▼                         ├─ Story: any visited street area      [V]
   Saltmarket ► … ► Core Chamber   ├─ Farming: F1–F7 when unlocked       [P]
   (gated east exits) [V]          ├─ Bosses: rematch arenas when beaten [P]
                                   └─ World Bosses: open rounds          [V]
   Farms / rematch arenas / world-boss arenas: west exit ─► HUB [V for WB, P for others]
   Knockout: back up at the west end or before the boss, coins −10% [V]
```

- **[V]** Every transition goes through `Game.enter_area()`, which saves.
- **[P]** Rematch arenas (and farms, if the owner wants) are protected like world-boss
  arenas. A save that ends inside one loads back in the hub, so no area can be entered
  without its taxi rules.

---

## 7. Dependencies and implementation order

Each step is one small PR with tests, in this order:

| # | PR | Depends on | Touches |
|---|---|---|---|
| 0 | **STORY_BIBLE: name the hub zones, the 7 farms and the rematch arenas** (owner approves the names) | Q1, Q2 answers | docs only |
| 1 | Item sources: add world-boss and starter sources to `ContentDB.sources`, and a test that every item has a source | none | sim + test |
| 2 | Off-street area type ("activity" areas): validation, `MapRules` row, a guard so they can only be entered by taxi, `AutoRules.is_beaten` for areas with no exit east | none | sim + tests |
| 3 | Taxi menu headings (Story / Farming / Bosses / World Bosses) | 2 | scenes + test_ui |
| 4 | Hub: widen Depot Yard, move the NPCs, add the workbench and departure board, set dressing and reserved space | 0, 3 | data + small scene glue + tests (tutorial, ui, game) |
| 5 | Farms F1–F7 as data | 0, 2 | data + content/scene tests |
| 6 | Loop mode for farms | 5 | sim + unit tests |
| 7 | Mini-boss and stage-boss rematch arenas | 2, Q3, Q4 | data + tests |
| 8 | Documentation sync (GAME_DESIGN, README test count, UI.md, ROADMAP IL-6) | all | docs |

Steps 1 and 2 have no content dependency and could start right after approval.

---

## 8. Risks, performance and web export

| Risk | Mitigation |
|---|---|
| Changing `start_area` or Depot Yard's flags breaks heal/rest, Recall, auto, the tutorial or world-boss returns | Keep the id and flags. Move NPC x positions only after `test_tutorial`, `test_game`, `test_recall` and `test_auto_battle` pass |
| A wider hub moves the tutorial's NPC or dummy away from where its steps expect them | Keep the tutorial block (dummy, Odo) inside the first screen, or update the tutorial data with its tests |
| Off-street farms slip into `StreetMemory.street` and change district numbering | They have only a west exit to the hub, like WB arenas. A test checks the street is unchanged (30 + 1 areas) |
| `AutoRules.is_beaten` returns false for an area with no exit east and no boss, so auto never runs in farms | Step 2 adds an explicit rule and a test |
| Loop mode creates an XP/coin faucet | A breather between loops. Rates come from the existing loot/level data. Measure coins and materials per hour in a test with a scripted player, as `test_balance` and BLUEPRINT §9.5–9.6 do |
| Rematches multiply legendary chances per hour | Owner Q4 before step 7. Any limit lives in data and `sim/` |
| Save compatibility | Unlocks come from `visited`/`defeated`. **No new save field is planned.** If one turns out to be needed: save v11 + migration + tests |
| Web build size | **No new art planned.** Farms reuse existing environment PNGs, and data adds only KB. The current wasm is 10.1 MB gzip (PERFORMANCE.md), and the CI manifest records size on every PR |
| Web performance (single-threaded, SwiftShader in CI) | Keep `max_alive` ≤ 4 in farms (the same as today). A hub with more NPCs and props adds draw calls only. Measure the hub on real hardware (PERFORMANCE.md) |
| The client is trusted for rewards when online comes | Unchanged: all rewards decided in `sim/`; IL-7 moves them to the server |

---

## 9. Owner decisions needed before Phase 2

| # | Question | Recommendation |
|---|---|---|
| Q1 | 50 stages (5 × 10) with a mini-boss and boss in each, or the approved 6 chapters / 30 areas / 11 bosses? | Keep the 30 story areas. Treat farms and rematches as the "extra stages" for replay. If 50 is required, it is a separate story-content milestone with STORY_BIBLE updates first, not part of the hub/farm work. |
| Q2 | Hub = the widened Depot Yard (same id), or a separate hub map? | Widened Depot Yard (§3.1) |
| Q3 | Auto battle in boss rematches? | Allow it only after the boss has been beaten by hand, matching D12 |
| Q4 | Full boss loot on every rematch? | Decide in the drop phase. Until then rematches use the existing tables unchanged |
| Q5 | Per-area bonus loot for farms? | No for now (keep loot per enemy) |
| Q6 | Hub-only Farming/Bosses travel, or every district taxi? | Hub only |

---

## 10. Acceptance criteria for the next phases

**Hub (steps 3–4)**
- [ ] `depot_yard` stays `start_area`, safe and `heal_on_enter`. Save v10 loads unchanged.
- [ ] Shop, quests, workbench, training dummy and departures are all reachable within
      about 10 s of walking from the arrival point.
- [ ] Pressing E on the workbench opens the existing upgrade flow. `test_enhance` is
      unchanged and green.
- [ ] The travel menu shows Story / Farming / Bosses / World Bosses, and only what is
      unlocked.
- [ ] The tutorial, recall, auto-battle and world-boss tests pass unchanged.
- [ ] `test_ui` passes at 640x360. The smoke test reaches the hub.

**Farms (steps 5–6)**
- [ ] 7 farms exist as data only. The ContentDB validator accepts them, and the street
      and districts are unchanged.
- [ ] Each farm unlocks from `visited`, appears on the map, can be reached by taxi and
      leads back to the hub.
- [ ] Auto battle runs in an unlocked farm. Loop mode re-arms after a breather and is
      deterministic with a seed.
- [ ] No item, drop chance, money range or enemy stat changes (checked with a diff of
      `items.json`/`enemies.json` `loot`).

**Boss activities (step 7)**
- [ ] One rematch arena for each of the 11 story bosses. Each unlocks only after that
      boss has been defeated.
- [ ] World bosses are unchanged.

**Drop planning (step 1)**
- [ ] A test fails if any item has no source.
- [ ] The item card shows sources for world-boss rewards.

**Every PR:** CI green (lint, import, all tests, backend, web export, smoke), CHANGELOG
updated, docs updated.

---

## 11. Files that would change in Phase 2, and why

| File | Why | Step |
|---|---|---|
| `docs/STORY_BIBLE.md` | Names for the hub zones, farms and rematch arenas (the only allowed source of names) | 0 |
| `client/sim/ContentDB.gd` | `sources()` includes world-boss and starter sources; validates the new off-street area type, farm unlocks and the optional loop flag | 1, 2 |
| `client/sim/MapRules.gd` | Farming and Bosses rows on the map (like `arenas()`), `kind_of` for them | 2 |
| `client/sim/AutoRules.gd` | `is_beaten` for farms and rematch arenas (no exit east) | 2 |
| `client/sim/StreetMemory.gd` | Taxi destinations for activity areas; loop re-arming in `pending` | 2, 6 |
| `client/sim/ZoneSim.gd` | Loop mode breather between re-armed encounters (only if `pending` alone cannot do it) | 6 |
| `client/scenes/game/Game.gd` | `enter_area` guard extended to activity areas; workbench interaction opens the equipment screen | 2, 4 |
| `client/scenes/game/GameMenus.gd` | Travel menu headings | 3 |
| `client/scenes/world/ZoneView.gd` | Prompt and mark for the workbench and departure board | 4 |
| `client/data/areas.json` | Wider Depot Yard, new NPC and prop positions; 7 farm areas; 11 rematch arenas | 4, 5, 7 |
| `client/data/obstacles.json` | Only if the workbench or board needs a new prop kind (it reuses kit art) | 4 |
| `client/data/tutorial.json` | Only if the dummy or Odo move out of the first screen | 4 |
| `client/tests/unit/test_*.gd` | New: farms, hub, item sources, loop mode. Extended: map, auto battle, travel UI, tutorial, content | all |
| `tools/web-smoke/smoke.ts` | Hub positions, if the smoke test walks to an NPC | 4 |
| `docs/UI.md`, `GAME_DESIGN.md`, `README.md`, `docs/ROADMAP.md`, `CHANGELOG.md` | Keep the docs true | 8 |

Not touched: combat/AI/boss rules, `items.json`, `enemies.json` loot, `progression.json`,
`world_boss.json`, `SaveStore` (unless a v11 turns out to be needed), `backend/`.

---

## 12. Phase 2 record: Iron City Central (`main_city`)

### 12.1 Owner decisions (2026-11-02)

| # | Decision |
|---|---|
| City | A **separate area**, `main_city`, named **Iron City Central**. It is not Story Area 1 and not a farming area. |
| Walking link | **One-way gate east** from the city into Depot Yard's west end. **Depot Yard gets no west exit**, and its "no west exit" test stays. |
| Rest | **Option A:** arriving heals and refills the streets exactly like Depot Yard, using the existing `heal_on_enter`. No new rest system. |
| Home flows | The pause menu's return goes to the city (**Return to Iron City Central**, changed 2026-11-02 at the owner's request; it replaced Return to Depot Yard). Auto battle's trip home, a knock-out and the return after a world boss still go to Depot Yard. |
| Taxi | Every stand gets the grouped, scrollable list, with the same rides, fares and unlock rules, plus a ride to the city. |
| Keeper | **A self-service kiosk.** No new character, sprite or dialogue in this phase. |
| Save bug | **Approved fix:** a save made off the story street must not mark the whole street as reached. |

### 12.2 What was found and fixed in passing (verified)

`StreetMemory.load_into` marks every area west of the saved area as reached. That is
right for a save made on the street. For a save made **off** the street (a world-boss
arena, and now the city), the loop never met the saved area, so it marked **all 31
areas, up to the final chapter, as reached**. A level 1 hero who saved in the city
could have ridden Win's taxi to the Core Chamber.

- **Before the fix:** a probe showed a fresh profile saved in `great_drain` loading
  with 31 visited areas, including `core_chamber`.
- **After the fix:** off the street, loading adds only the start area (every hero
  begins there). Saves made on the street are unchanged.
- **Proof:** with the old file put back, the new save tests fail (a city save loads
  with 31 areas; all 3 world-boss arenas fail). With the fix, they pass.

### 12.3 The city (all **[V]**: built and covered by tests)

Iron City Central is 1,600 px long, under the skytrain. Hand-placed frontage built from
the owner's existing kit pieces (no new art). Signs over the shopfronts name each part.

| x | Place | What E does | Built on |
|---|---|---|---|
| 0–330 | **Taxi Rank** (arrival point, bus stop, parked songthaew) | Win (`taxi_win_city`, fare 10): every area reached, grouped by district, plus the world bosses that are unlocked | existing `role: travel` |
| 440 | **Notice Board** | Current job and where to report (`MapRules.goal`). World bosses are named and timed **only once unlocked**, like the map; locked ones read "???". Trading Post and Guild Hall are listed as **not open yet**; a Farming heading says to farm any cleared street. Its only button is Close. | `WorldBossRules`, `MapRules` |
| 700 | **Market**: Self-Service Kiosk | Shop: buy and sell | existing `role: shop`; shop `city_kiosk` has **exactly** `depot_stall`'s items, and prices come from `items.json` |
| 1,000 | **Workshop**: Workbench | Opens the Bag on worn gear; each card has *Upgrade +N* | existing `Game._upgrade` → `EnhanceRules`, which needs a safe area (the city is safe) |
| 1,150–1,340 | **Training Yard**: dummy and 2 practice weapons | Practise (the training dummy gives nothing) | existing dummy; `weapons.span` |
| 1,400 / 1,530 | **Trading Post: planned**, **Guild Hall: planned** | Nothing: signs only, with no prompt | `landmarks` |
| 1,600 | **Gate east** | Walk on to Depot Yard (west end) | existing exit, one way |

How you get there:
- Win's ride "Iron City Central" is first at **every** existing stand.
- The pause menu's return is **Return to Iron City Central** (one item; it replaced
  "Return to Depot Yard" and "Go to Iron City Central"). It is free, with Recall's
  checks (not in a fight, not while knocked down) plus one more: not during a
  world-boss attempt.
- The map has its own **City** row, known from the first night.

The city is off the story street, like the world-boss arenas. The street is still Depot
Yard plus the 30 story areas, the districts are unchanged, and no area walks into the
city.

### 12.4 Changes, by file

**Restored to `main`:** every Depot Yard change from the first attempt is reverted.
Depot Yard's `areas.json` entry, kit layout, generated scenery entry and its four
images are byte-identical to `main`; `test_main_city.gd` checks their SHA-256.

| File | Change |
|---|---|
| `client/data/areas.json` | **Additions only:** `"city_area": "main_city"` and the `main_city` area. No existing area changed. |
| `client/data/shops.json` | **Addition only:** `city_kiosk`, a copy of `depot_stall`'s item list |
| `art/kit/kit.json` | **Addition only:** `layouts.main_city` (hand-placed frontage and props) |
| `client/assets/manifest.json`, `client/assets/environment/main_city/*` | Generated by the pipeline. Only `main_city` entries were added. |
| `tools/assets/kit_import.py`, `tools/assets/test_pipeline.py` | Optional per-area hand-placed `layouts`, and a test for them |
| `client/sim/StreetMemory.gd` | The save-loading fix (§12.2) |
| `client/sim/ContentDB.gd` | `city_area`. Roles `workbench` and `board`, drawn as kit `piece`s. Validation: the city is safe, rests, has no fights, is not the start area, nothing walks into it and its only exit is east; a workbench needs a safe area; `landmarks`, `planned_services`, `farming_planned` and `weapons.span` are checked |
| `client/sim/ZoneSim.gd` | `weapons.span`. `leave_problem()` is split out of `recall_problem()`; Recall's behaviour is identical |
| `client/sim/MapRules.gd` | The city is always known; "Upgrades" and "Notices" are listed as services |
| `client/scenes/game/Game.gd` | E at a workbench or board; `city_problem()` and `_go_to_city()` |
| `client/scenes/game/GameMenus.gd` | Taxi list grouped by district, scrollable and sized to its rows; the city ride; the pause item; the notice board |
| `client/scenes/game/MapTab.gd` | The City row |
| `client/scenes/world/Scenery.gd`, `ZoneView.gd` | Things to use drawn as kit pieces, with their own prompt and mark; landmark signs |
| `client/tests/unit/test_main_city.gd` (new, 18 tests), `test_city_saves.gd` (new, 5 tests) | See §12.5 |
| `client/tests/unit/test_map.gd`, `test_south_street.gd` | Two counts: the map has one more row (the city), and the city is an area that is neither on the street nor a world-boss arena |

**Not changed:**
- Depot Yard and every story area, gate, boss and quest; the tutorial.
- Combat, AI and world-boss rules.
- Items, drops, prices and enhancement costs.
- Recall, the auto-battle loop and the return after a world boss.
- The save format (still v10, no new fields) and `backend/`.

### 12.5 Verification (2026-11-02, this session)

| Check | Result |
|---|---|
| `gdformat --check .` / `gdlint .` (gdtoolkit 4.5.0) | 133 files unchanged / no problems |
| `godot --headless --path client --import` (4.7.2) | exit 0 |
| Godot tests | **416 passed, 0 failed** (was 393 on `main`; 23 new) |
| Same suite with `main`'s `StreetMemory.gd` | 3 failures, as intended: the new save tests catch the bug |
| `python3 -m unittest tools/assets/test_pipeline.py` (Pillow 13.0.0) | 39 tests OK |
| `tools/assets/validate.py` | 56 checked, 0 problems |
| `tools/ci/check-repo.sh` | exit 0 |
| Web export (release, single-threaded) | exit 0. `index.pck` is 11,091,616 bytes against 11,047,904 for `main` built the same way (**+43.7 KB**); `index.wasm` unchanged (39,514,754) |
| Browser smoke test (`tools/web-smoke/smoke.ts`, headless Chromium) | Passed: boot, combat, skill, weapon, pause menu, Depot Yard → Saltmarket, street fight. Run with the preinstalled Playwright **1.63.0**, not the pinned 1.56.1; CI runs the pinned version. |
| Screenshots of the web build | Depot Yard's taxi offering the city, arrival at the Taxi Rank, Market, Workshop, Training Yard, the planned plots, and the gate back into an unchanged Depot Yard |
| Backend typecheck and tests | **Not run here.** No PostgreSQL, and Node 22 instead of 24. Nothing in `backend/` changed. |

### 12.6 Known limits

- **Not open yet:** the Trading Post and the Guild Hall are only listed on the board
  and signs. Farming grounds and boss rematches are not announced in the game.
- **No multiplayer:** no trading, guild or social system exists.
- **The HUD route card** is empty in the city, as in the world-boss arenas, because it
  shows a district's route and the city is off the street.
- **The workbench** is drawn with the kit's crates, and the notice board with a blank
  sign; there are no painted pieces for them.
- **Depot Yard's taxi line** still says "on South Street". The wording is old, and it
  is left as on `main` because Depot Yard is protected. The ride list itself always
  covered every district.
- **The tutorial card** follows the hero into the city. Its steps can be done there
  (the city has a dummy and weapons), except "talk to Chief Odo", who stays in Depot
  Yard.
