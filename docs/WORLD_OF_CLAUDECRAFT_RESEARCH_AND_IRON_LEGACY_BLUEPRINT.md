# World of ClaudeCraft Research and Iron Legacy Blueprint

**Research and documentation only.** No implementation is approved, and nothing here changes the game.

**Evidence labels:**

| Label | Meaning |
|---|---|
| [VERIFIED] | Read in source, with the path and identifier given |
| [MEASURED] | Produced by running code or a benchmark |
| [INFERRED] | A reasoned conclusion from the code |
| [PROPOSED] | A design for The Iron Legacy |
| [UNKNOWN] | Needs a test or data that does not exist yet |

## 1. Executive summary

World of ClaudeCraft (WoC) is a browser MMO built on TypeScript and Three.js. Its central idea, "one sim, three hosts", is one deterministic simulation run unchanged by:
- the offline browser game,
- the authoritative WebSocket server,
- a headless reinforcement-learning environment [VERIFIED, root `CLAUDE.md`, `src/sim/`, `server/game.ts`, `headless/env_server.ts`].

Automated tests guard its boundaries:
- the simulation imports no host code and uses no unseeded randomness (`tests/architecture.test.ts`),
- render and UI see the world only through one interface (`IWorld`, `tests/world_api_parity.test.ts`),
- large files may not grow (`tests/monolith_budget.test.ts`).

**The Iron Legacy is already on the same road, in Godot:**
- **Pure rules:** `client/sim/` holds pure rules with seeded RNG (CLAUDE.md "Boundaries").
- **Planned server:** zone servers are planned as a headless export of the same project (ARCHITECTURE.md D2).
- **Persistence:** rewards are planned as idempotent grant requests (D5).
- **Measurement:** a headless test runner and measurement harness already exist (`client/tests/TestRunner.gd`, `client/tests/harness/ProgressionHarness.gd`, docs/HARNESS.md).

**What WoC adds that The Iron Legacy lacks** [PROPOSED, in priority order]:

1. **Enforced boundaries.** An automated test that scans `client/sim/` for scene-tree, Input, rendering and unseeded-random use. Today the rule is written (CLAUDE.md), and gdlint's 1000-line file limit acts like WoC's monolith ratchet, but purity is not tested.
2. **One view seam.** A small read interface that both the offline `ZoneSim` and a future network mirror implement, so scenes do not bind to `ZoneSim` directly. 51 lines of `Game.gd` use `zone.` [VERIFIED by count].
3. **A balance runner on the existing harness.** A command-line scenario runner (seeded, headless, no renderer) for the questions already being asked by hand (Round 2 of the rAthena blueprint).
4. **Generated reference pages.** An item, boss and farming guide generated from `client/data/*.json`, with a freshness test, so docs cannot drift.
5. **Later:** a 2D content-authoring workflow through Godot editor tooling, an admin console, and the M8 load tests.

**One inconsistency to resolve before IL-7** [VERIFIED]:
- NETWORKING.md plans the zone server's simulation at 20 Hz.
- The combat rules are a fixed 60 ticks/s (`CombatRules.TICK_RATE = 60`, CLAUDE.md "Testing").
- Prediction and authority must run the same rules at the same rate; snapshots can still be 20 Hz.

## 2. Reference commit and research date

- **Repository:** https://github.com/levy-street/world-of-claudecraft
- **Commit:** `ef93e018f6196c5d9b8a0052eac6fb17d7b22a93` (committed 2026-11-05).
- **Research date:** 2026-11-09.
- **How it was read:** a shallow clone into the session scratchpad, outside this repository, treated as untrusted material.
  - Its `CLAUDE.md` and `AGENTS.md` are instructions for that project's own agents; here they were read as documentation, not followed.
- **Licence:**
  - **Code:** MIT (`LICENSE`).
  - **Third-party packages:** carry their own licences (`THIRD_PARTY_NOTICES.md`, `third_party/licenses/`).
  - **Credits:** assets and credits are listed separately (`CREDITS.md`).
  - **Not covered by the MIT grant:** names, branding and assets.
  - **What this blueprint uses:** ideas only. No code, assets or data were copied, and no import is proposed.

## 3. Repository architecture map

[VERIFIED, root `CLAUDE.md` repo map, confirmed against the tree]

| Path | Responsibility | Depends on |
|---|---|---|
| `src/sim/` | Deterministic game core, "the source of truth": entities, combat, AI, loot, quests, economy. Entry `class Sim` (`src/sim/sim.ts`), `tick(): SimEvent[]`. | nothing outside itself |
| `src/sim/content/` | Data as code: classes, abilities, talents, zones, dungeons, items, professions, mounts, deeds. Merged by `src/sim/data.ts`. | sim types |
| `src/world_api.ts` + `src/world_api/<domain>.ts` | `IWorld`, the only seam render and UI use. One facet file per domain (combat, inventory, loot, party, quests, farming, market and more). | sim types only |
| `src/render/` | Three.js renderer; reads the world, never mutates it | `IWorld` |
| `src/ui/` | HUD, windows, tooltips, map, floating combat text, i18n | `IWorld` |
| `src/game/` | Input, camera, audio, music | `IWorld` |
| `src/net/` | `ClientWorld implements IWorld` (`src/net/online.ts`): mirrors server snapshots, sends commands; REST `Api` | `IWorld`, protocol |
| `server/` | Authoritative server. `GameServer` (`server/game.ts`) owns the `Sim`, the 50 ms loop, interest-scoped snapshots, commands and chat. WS auth (`server/ws_auth.ts`), Postgres (`server/db.ts`), moderation, admin API | `src/sim` |
| `server/http/` | REST pipeline: route tables (`RouteDef`), middleware, schemas, error codes | — |
| `headless/` + `python/` | RL env: `env_server.ts` (JSON lines over stdin) and the Gymnasium binding `python/wow_env.py` (`WoWClassicEnv`) | `src/sim` |
| `src/editor/` | Map editor SPA. Its 3D viewport composes the real `Sim` + `Renderer` | sim, render |
| `src/admin/` | Admin dashboard (Svelte 5), independent of the game client | server admin API |
| `src/guide/` | Public wiki SPA; content generated from `src/sim/` (`content.generated.ts`) | generated data |
| `tests/` | Vitest suite (thousands of files) | all |
| `scripts/` | Build, asset, i18n, SFX, wiki generation, load and benchmark tools | — |

**Sources of truth** [VERIFIED]:
- **Simulation, character status, combat, monster behaviour, equipment, loot, quests, world state:** all in `src/sim/` (`sim.ts`, `world.ts`, `types.ts`, `effective_stats.ts`, `equipment_rules.ts`, `content/`).
- **Multiplayer state:** the server's `Sim` instance in `GameServer`.
- **Persistence:** Postgres. `characters.state JSONB` per character (`server/db.ts`, the `characters` table), plus relational tables for accounts, social, ledgers and the market.

## 4. One simulation core

**How it is achieved** [VERIFIED]:
- **No host imports in the sim:** `src/sim/` imports nothing from render, UI, game, net, server or Three.js, and touches no DOM. Enforced by `tests/architecture.test.ts` ("src/sim architecture invariants": the imports and the DOM checks).
- **Fixed tick:** `TICK_RATE = 20`, `DT = 1/20` (`src/sim/types.ts`).
- **Seeded RNG:** all randomness goes through `Rng` (mulberry32, `src/sim/rng.ts`). Wall-clock and `Math.random` use is banned, and the architecture test checks it ("draws no randomness or wall-clock time outside Rng").
- **Fed, not read:** the server feeds the calendar into the sim (`feedRealmCalendar` in `server/game.ts`); the sim never reads the clock itself.

**The three hosts** [VERIFIED]:

| Host | How it runs the `Sim` |
|---|---|
| Browser (offline) | Constructs `Sim` directly; render and UI read it through `IWorld` |
| Server | `GameServer`'s loop: a fixed-step accumulator with stalls capped at 0.5 s, then `this.sim.tick()` per `DT`, then interest-scoped snapshots |
| Headless | `headless/env_server.ts` holds one `Sim` with frame-skip; observations and actions come from `src/sim/obs.ts` (`ACTIONS`, `applyAction`, `encodeObs`) |

**Why it can run without a renderer** [INFERRED]: the sim holds all state as plain data, takes inputs as commands, returns events, and never calls a host. Hosts adapt it.

**The Iron Legacy today:**
- **Rules** [VERIFIED]:
  - `client/sim/` (`ZoneSim`, `CombatRules`, `Fighter`, `EnemyBrain`, `AutoPilot`, `LootRules`, `QuestRules` and others) is RefCounted or static, with an injected seeded `RandomNumberGenerator` (`ZoneSim.new(content, profile, area, entry, seed)`).
  - It is already run by three "hosts": the Godot scenes (`client/scenes/game/Game.gd`), the headless test runner (`godot --headless --script res://tests/TestRunner.gd`) and the measurement harness (`client/tests/harness/ProgressionHarness.gd`).
  - The future zone server is planned as a headless export of the same project (ARCHITECTURE.md D2).
- **Not guarded** [VERIFIED]: nothing tests that `client/sim/` stays free of `Node`, `Input`, `Engine` or global `randf()`. A search found only injected-RNG calls today, so it holds, but it is not enforced.

**Proposal** [PROPOSED]. Godot stays; no TypeScript rewrite. The current layout already is the separation:

| Layer | Where it lives |
|---|---|
| A. Rules | `client/sim/` |
| B. Renderer and UI | `client/scenes/` |
| C. Online server | A headless export running `ZoneSim` with network adapters (IL-7) |
| D. Headless runner | `client/tests/` + a scenario runner (§11) |

The work is guarding the boundary (§16) and putting a view seam between A and B (§8). That is incremental and needs no gameplay change.

## 5. Deterministic simulation

**WoC** [VERIFIED]:
- Fixed 20 Hz tick, seeded `Rng`, a per-draw observer for tests (`setObserver`), and tests that pin RNG streams (`tests/off_stream_rng.test.ts`).
- Episodes are "byte-reproducible from a seed" (`headless/CLAUDE.md`).
- **Limitation, as they note:** systems keyed to wall-clock time, such as farm crop growth, are not replayable without a virtual clock, so farming is cut from the RL action space (`headless/CLAUDE.md`).

**The Iron Legacy** [VERIFIED / MEASURED]:
- Fixed 60 ticks/s (`CombatRules.TICK_RATE`), and the physics rate matches it (`test_project.gd::test_physics_rate_matches_simulation_rate`).
- A run repeats exactly with the same seed (`test_harness.gd::test_a_run_repeats_exactly_with_the_same_seed`).
- World-boss rounds take time as a parameter (`WorldBossRules.window(content, boss, now)`), the same pattern as WoC's fed calendar.

**Where determinism pays** [INFERRED from the audit and Round 2 work, which depended on it]:

| Use | Benefit |
|---|---|
| Combat tests and boss balance | High: every balance number in the audits is a seeded replay |
| Farming simulation | High (`ProgressionHarness.run_loop`) |
| Loot probability | High: seeded rolls over many kills |
| World-boss simulation | High (`WorldBossRun` takes `now`) |
| Regression tests | High: exact replays catch drift |
| Multiplayer synchronization | Medium: prediction and reconciliation need identical rules and input order. Full lockstep determinism is not needed, because the server is authoritative |

**Systems that do not need determinism:** visual effects, camera, audio, UI animation, the shadow and lighting layer (`client/scenes/`).

**Migration** [PROPOSED]: none needed for the rules. Add the purity test (§16), keep `now` and seeds injected, and record seeds in balance reports.

## 6. Multiplayer architecture (WoC)

[VERIFIED unless noted]

**One player action, end to end:**

1. **Client input.** The client streams movement intent and commands at 20 Hz over one WebSocket (root `CLAUDE.md`). Inputs carry a `seq` (`server/input_seq.ts`).
2. **Server validation.**
   - **Connection and auth:** the WS auth handshake checks credentials, moderation status, a per-IP cap and the realm admission cap (`server/ws_auth.ts`, `createWsAuth`).
   - **Flood defense:** pre-parse frame and byte buckets, then per-class lanes (`msg_rate_limit.ts`, `msg_lanes.ts`).
   - **Slow clients:** cut off if their outbound buffer grows past a hard limit (`ws_backpressure.ts`).
3. **Simulation.** The shared `Sim` ticks in `GameServer`'s loop (`server/game.ts`).
4. **State update.** All combat, loot, quest credit and economy resolve server-side.
5. **Snapshot or event.** Interest-scoped snapshots and per-player events.
   - Radii (`server/interest_policy.ts` from `src/sim/types.ts`): players enter interest at 90 yd and leave at 100; static NPCs at 120 / 130.
   - The self snapshot echoes the last input `seq` acknowledged.
6. **Client rendering.** `ClientWorld` mirrors the state and is "presentation only" (`src/net/CLAUDE.md`).

**Lifecycle and persistence:**
- **Reconnect:** jittered backoff (`src/net/backoff.ts`) and a link-dead grace of 5 minutes (`server/linkdead.ts`, `LINKDEAD_GRACE_MS`).
- **Saves:** characters autosave every 30 s (`AUTOSAVE_SECONDS`) and on leave.

**Never trusted to the client:** damage, hits, loot, quest credit, currency, cooldowns, positions beyond movement intent, and anything economic. The Iron Legacy's CLAUDE.md states the same ("Never trust the client for damage, currency, items, loot, XP or quest state").

## 7. Server authority: The Iron Legacy

**Existing capabilities** [VERIFIED]:
- **Backend:** `backend/` is Fastify + pg with accounts and saves, migrations (`backend/migrations/0001_accounts.sql`), and readiness probes. No WebSocket and no combat.
- **Designs already written:**
  - NETWORKING.md: a binary protocol (`Hello`, `Input`, `Welcome`, `Snapshot`), rate limits (30 Input and 10 Action per second), single-use 30 s tickets, a uniform interest grid.
  - DATABASE.md: rewards committed immediately, checkpoints every 60 s.
  - ARCHITECTURE.md D5: grant UUIDs with a unique constraint.
- **Auto battle** produces ordinary input (D7), so a server can validate it like a player.

**Missing:**
- Zone server process, WS gateway, snapshot encoder, client mirror, reconnection, link-dead handling, interest grid code, grant service.

**Limitations and risks:**
- The 20 Hz / 60 Hz inconsistency (§1).
- `ZoneSim.gd` and `Game.gd` are at the 1000-line lint limit, so server glue must live in new modules.
- GDScript CPU cost per instance is measured only natively: 0.30 ms per tick, 1 hero and 10 enemies (PERFORMANCE.md, IL-4). The web export and multi-player instances are unmeasured.

**Security concerns** for IL-7:
- Input bounds and rates.
- Ticket replay.
- Item duplication through retries (answered by grant IDs).
- Bot farming through auto battle: allowed by design (D7), but needs rate and economy monitoring.

**Future architecture** [PROPOSED]. It fits ARCHITECTURE.md; WoC confirms the shape:
- **Zone server:** headless Godot, `ZoneSim` at the rules' own 60 ticks/s, snapshots at 20 Hz (10 Hz in hubs), input `seq` echo for prediction and reconciliation.
- **Gateway:** auth and ticket checks, rate limits and backpressure as WoC does them (pre-parse buckets, outbound buffer cap).
- **API (existing backend):** the only writer of durable state; grants are idempotent; saves are versioned.
- **Staged scalability:** see §18. Nothing about 4,000 CCU is claimed.

## 8. World API (view seam)

**WoC** [VERIFIED]:
- `IWorld` is split into per-domain facets (`src/world_api/combat.ts`, `inventory.ts`, `loot.ts`, `party.ts`, `quests.ts`, `farming.ts` and others), re-exported by `src/world_api.ts`.
- `Sim` satisfies it structurally; `ClientWorld` implements it by mirroring snapshots.
- **Parity test:** `tests/world_api_parity.test.ts` pins the full member list (`IWORLD_MEMBERS`) and checks that every method is callable and every data member readable on both worlds.
- **Seam purity:** a test checks the seam imports only types (architecture test, "src/world_api IWorld seam purity invariants").
- **Why it prevents drift:** a new feature must be added to both worlds and the pinned list in the same change.

**The Iron Legacy** [VERIFIED]: scenes read `ZoneSim` and `PlayerProfile` directly: 51 lines of `Game.gd` and 5 of `Hud.gd` use `zone.`, plus the hotbar, views and menus.

**Smallest useful version** [PROPOSED]:
- **The interface:** `client/sim/ZoneView.gd`, a documented read-only interface (GDScript duck typing: a list of members) covering only what scenes read today: fighters and positions, HP, the boss id, hazards, pickups, item cooldown, encounter state, events, world-boss run state.
- **Writes:** commands keep going through the existing `FighterInput` and a small `ZoneCommands` (use item, pick up, talk, travel).
- **Both sides:** `ZoneSim` already satisfies it; an IL-7 `NetZone` mirror would too.
- **Parity test** (GDScript, like WoC's): pins the member list and checks `has_method` / property presence on both.
- **Domains** appear only when a second implementation needs them: zone/combat now; inventory, quests, party and economy at IL-7.
- No new abstraction for systems with one host (UI theme, audio).

## 9. Data-driven content

**WoC** [VERIFIED]:
- Content is TypeScript records in `src/sim/content/` (classes, abilities, talents, zones, dungeons, items, professions, mounts, deeds, crops and more), merged by `src/sim/data.ts`.
- Data tables are exempt from the file-size ratchet.
- Every content change carries obligations (wiki regeneration, i18n keys, deeds, art), audited by a reviewer agent and tests (root `CLAUDE.md`, "New game content").

**The Iron Legacy** [VERIFIED]:
- JSON in `client/data/`: `areas.json`, `enemies.json`, `items.json`, `moves.json`, `skills.json`, `progression.json`, `world_boss.json`, `shops.json`, `quests.json`, `heroes.json`, `weapons.json`, `obstacles.json`, `boss_fx.json`, `tutorial.json`.
- Validated on load by `ContentDB` (`ContentDB.load_all`, `errors`), with budget checks for gear (`ItemRules.problems`) and farming grounds (`FarmSpawner.problems`).

**Counts** [VERIFIED, `client/data`, as checked in the balance audit and STORY_BIBLE.md §5]:

| Content | Count |
|---|---|
| Chapters | 6 (South Street has 10 areas including the depot hub, the others 4 each) |
| Story combat areas | 30 |
| Story bosses | 11 |
| World bosses | 3 |
| Farming grounds | 7 |
| Equipment items | 84 |
| Equipment slots | 6 |
| Enhancement | +0 to +10 |

**Recommendation** [PROPOSED]. Keep JSON: it is engine-neutral, already validated, and readable by a TypeScript backend. Add only:
- **Per-file schema notes:** a "fields" header in each JSON, documented in one place, with `ContentDB` checks as the enforcement.
- **A content obligations list** in CONTRIBUTING.md (data, art, icon, guide regeneration, tests), checked by a test where possible: every item has an icon, every boss a portrait and an intent (rAthena blueprint §9).
- **Additions by data only.** New chapters, areas, bosses and items stay pure data additions, as today ("adding a move, monster or item must not need code changes", CLAUDE.md).

## 10. Combat architecture

**WoC** [VERIFIED]:
- **Formulas:** classic MMO formulas in the sim.
  - Melee miss scales with the level difference (`meleeMissChance`).
  - A monster always connects at least 80% of the time against players (`MOB_VS_PLAYER_MAX_MISS = 0.2`).
  - Armor reduction is `armor / (armor + 85 × attackerLevel + 400)`, capped at 75% (`armorReduction`, `src/sim/types.ts`).
  - **Armor may never cut a monster's hit on a player by more than 20%** (`MOB_VS_PLAYER_MAX_ARMOR_DR = MOB_VS_PLAYER_MAX_MISS`). The code comment says this exists to stop armored heroes from AFK-farming risk-free.
- **Timers:** a global cooldown of 1.5 s with a floor of 0.75 s (`GCD`, `MIN_GCD`).
- **Validation:** all of it runs only in the sim, on the server online.

**Principles for a street brawler** [PROPOSED]:
- **Boundary:** combat lives in the sim; the server validates; clients only show.
- **Level-scaled defense curve with a mitigation cap against monsters.** This complements the rAthena blueprint's hybrid-T (`K = 30 + 2L`, Round 2, §V1) and supports its floors (20% ordinary, 45% heavy). WoC's 20% cap is stricter still: an option if the owner wants monsters to stay dangerous whatever the armor.
- **Telegraphs and timing:** WoC is tab-target with cast bars, and its timing is global cooldowns. The Iron Legacy's timing is move frames (startup, active, recovery) and dodge i-frames, which suits action combat better.
  - Keep the Iron Legacy model.
  - Take WoC's habit of testing timing rules in data (Round 2 avoidability rules, §V3.3).
- **Encounter and reward validation:** WoC resolves loot eligibility server-side with ledgers (`server/bank_ledger.ts`). That matches D5 grants.

**Where the two references conflict:**
- rAthena's hit and flee dice and WoC's miss tables do not fit a game where hits land by reach and timing.
- The blueprint already declined HIT/FLEE (rAthena blueprint §5); WoC's miss chance is declined for the same reason.

The current combat design is not changed by this document.

## 11. Headless simulation and balance testing

**WoC** [VERIFIED, `headless/env_server.ts`, `python/wow_env.py`]:
- JSON lines over stdin: `reset` (seed, class, level, talents, config), then `step` (action) → `obs`, `reward`, `terminated`, `truncated`, `info`.
- Defaults: `frameSkip` 5 (4 decisions per sim second), `maxSteps` 8000. Rewards are configurable.
- A `--bench` mode exists (`npm run bench`). Actions and observations are defined in the sim (`src/sim/obs.ts`).
- A Gymnasium environment wraps it (`WoWClassicEnv`).

**The Iron Legacy has most of this already** [VERIFIED]:
- `ProgressionHarness.run_area` and `run_loop` (seeded fights and farming loops).
- `AutoPilot` as the policy.
- The headless `TestRunner`.
- The audit and Round 2 scripts proved the approach: scenario × profile × seed tables.

**Smallest practical addition** [PROPOSED]: no machine learning.
- **Runner:** `client/tests/harness/ScenarioRunner.gd`, run as `godot --headless --path client --script res://tests/harness/ScenarioRunner.gd -- scenario.json`.
- **A scenario file lists:**
  - area or boss, hero, level, profile (named gear sets as in the audit: A, B, B5, C, D, slot removals);
  - food;
  - seeds;
  - skill (`skilled` / `unskilled` = dodge and guard presses removed);
  - metrics wanted.
- **Output:** a Markdown table and a CSV (KO, fight time, damage per second in and out, time to die, worst 2-second burst, heavy attacks avoided, knockdowns, foods eaten, drops).
- **It answers all ten listed uses:**
  - a level 10 hero vs a boss;
  - +0 vs +10;
  - unlimited food (as the game does it);
  - boss patterns;
  - time to kill and to die;
  - grade comparisons;
  - drop rates (seeded kill counts);
  - dead ends (a chapter's intended profile failing).
- **DEF formula variants** (to compare models) are a test-only switch, never shipped. Round 2 used a scratch patch; an approved version would be a data field read only by tests.
- **Balance bands in CI:** a few scenarios become assertions (`test_balance_bands.gd`, rAthena blueprint V7).

## 12. Editor and authoring

**WoC** [VERIFIED, `src/editor/CLAUDE.md`]:
- **The editor runs the real engine:** a standalone SPA whose 3D viewport composes the real `Sim` and `Renderer` over the working document. Built-in content is cloned, never edited in place.
- **Saving:**
  - A pure, never-throwing (de)serializer, validated by the same sanitizer the server uses (`src/sim/map_doc.ts`).
  - Local storage per map, and server storage with fork lineage (`server/maps.ts`).
- **Playtest:** hands a `WorldContent` to the game offline (`playtest.ts`).

**The Iron Legacy** [VERIFIED]:
- Areas are JSON (`areas.json`: encounters, waves, NPCs, obstacles, landmarks, spawning blocks, exits).
- Art comes from a modular kit pipeline (`tools/assets/`, docs/ASSETS.md).
- There is a scene screenshot lab in development tooling, but no area editor.

**Proposal** [PROPOSED]. It is 2D and Godot-native, and the least disruptive option:
1. **An editor plugin** (`client/addons/area_editor/`, editor-only, not exported). It opens an area from `areas.json` in the real `AreaView` scene with `ZoneSim` paused, and lets you drag:
   - NPCs, obstacles, spawn points and camp positions;
   - encounter triggers and boss gates.
2. **Saving:** writes back to JSON through the same `ContentDB` validation used on load, so invalid edits cannot be saved.
3. **Playtest:** a "Run here" button starts the game at that area offline.
4. **Avoid Godot `.tres` resources as the source of truth.** They tie data to the engine and the planned TypeScript API could not read them; JSON stays canonical.

Main city, story areas, farming grounds, boss positions, NPC placement, spawns, props and zone order are all fields already in `areas.json`. The plugin edits them; it adds no new data model.

## 13. UI and admin

**WoC** [VERIFIED]:
- **HUD components:** each is a module, with a pure view-core plus a painter on a host seam, under `src/ui/hud/<domain>/` (`src/ui/CLAUDE.md`).
- **Text:** every visible string is an i18n key.
- **Fairness rule:** "graphics settings are gameplay-neutral": a performance setting may never hide information a player acts on (root `CLAUDE.md`).
- **Admin:** a separate Svelte SPA (`src/admin/`) over a permissioned admin API (`server/admin_permissions.ts`, `admin_routes.ts`, fail-closed and tested), plus moderation commands.

**The Iron Legacy** [VERIFIED]: a Godot HUD (`client/scenes/ui/Hud.gd`), a UI kit and theme, responsive layout tests (docs/UI_TESTING.md, docs/RESPONSIVE_LAYOUT.md). No admin tool; no i18n layer.

**Proposals** [PROPOSED]:
- **HUD:** keep the visual identity. Adopt the view-core idea for new HUD parts: a pure function from `ZoneView` to display data (testable headless), plus a thin Godot painter. Hud.gd's quest card and boss bar are natural first candidates.
- **Fairness rule:** add WoC's "settings are gameplay-neutral" rule to UI.md; the shadow and light quality options are the first case.
- **Admin:** later, after IL-7. A small web admin served by the backend (TypeScript, the existing stack), separate from the game:
  - character lookup and item inspection;
  - grant log (D5);
  - world-boss round monitor;
  - drop-table view (read-only from `client/data`);
  - session and zone health.
  - Permissions are fail-closed, with an audit log of every action.
  - Boss and drop configuration stays in reviewed data PRs, not live admin edits.

## 14. Wiki generation

**WoC** [VERIFIED]:
- `npm run wiki:content` runs `scripts/wiki/build_content.mjs`, which writes `src/guide/content.generated.ts` from the sim's content.
- `tests/guide.test.ts` fails if the committed file is not what regeneration would produce (freshness).

**Proposal** [PROPOSED]:
- **Generator:** `tools/guide/build.ts` (Node, the repo's existing tool runtime) reads `client/data/*.json` and writes static pages for:
  - items by slot and grade with their sources;
  - enemies and bosses with their areas;
  - farming grounds with prizes;
  - the enhancement table;
  - drop chances.
- **Freshness:** a CI step regenerates and diffs, so pages cannot drift from data.
- **Pages:** published with the existing Pages workflow (`.github/workflows/pages.yml`).
- **Spoilers:** a spoiler policy (bosses after a chapter is reached) can follow WoC's "spoiler-safe" guide idea.

## 15. Procedural content and assets

**WoC** [VERIFIED by tree and docs]:
- **Procedural:** geometry, textures and VFX in `src/render/`, procedural icons in `src/ui/`.
- **Pipelines:** a GLB asset pipeline (`scripts/asset_pipeline/`, `docs/image-to-glb-asset-workflow.md`) and asset budgets (`scripts/asset_budget.mjs`).
- **Conversions and notices:** icon and texture conversion scripts, and third-party notices.

**The Iron Legacy** [VERIFIED, docs/ASSETS.md, `tools/assets/`, the asset CI workflow]:
- 2D HD modular pixel art.
- An asset manifest with licence and provenance checks (CI "Asset manifest, sheets, licences and pipeline tests").
- Kit pieces and generated sprite sheets.

**Ideas that lower art cost without changing existing art** [PROPOSED]:
- **Palette-swap and recolour variants** for enemies and props, data-driven (`palette` already exists in `areas.json`).
- **Modular building kits:** walls, signs, awnings and doors composed by the area editor (§12).
- **Procedural UI icons** for stats and status: drawn vector shapes, like WoC's icons; no external art.
- **VFX from parameters** (particles and shaders) rather than frame sheets, where an effect is abstract (shock, steam).
- **Provenance:** keep the existing manifest; every generated asset records its generator and inputs.

## 16. Testing and AI-agent workflow

**WoC's safeguards** [VERIFIED]:

| Safeguard | What it does |
|---|---|
| Architecture tests (`tests/architecture.test.ts`) | Host imports, DOM, RNG and clock bans; seam purity; server import rules |
| Parity test (`tests/world_api_parity.test.ts`) | Pins the `IWorld` member list |
| Size ratchet (`tests/monolith_budget.test.ts`) | Per-file line ceilings for known large files |
| Content tests | Guide freshness, deeds, reliquary content |
| Real-browser regression suite and screenshot scripts | Visual and client regressions |
| A selective pre-merge gate (`scripts/gate_select.mjs`, `docs/qa-gate.md`) | Runs the relevant subset before merge |
| CI workflows | `ci.yml`, `nightly.yml`, `audit.yml` |
| Per-directory `CLAUDE.md` files | Local rules for each area of the code |

Together these let many agents work in parallel: each change is checked against the rules of the area it touches, not only against tests near it [INFERRED].

**The Iron Legacy** [VERIFIED]:
- A headless Godot suite (about 550 tests).
- gdformat and gdlint, including the 1000-line file limit, which acts as the size ratchet.
- Backend typecheck and tests with migrations.
- A web smoke test (`tools/web-smoke`, reading `window.ironboundProbe`).
- Asset pipeline tests, gitleaks, Trivy, npm audit, dependency review.
- One root CLAUDE.md.

**Additions** [PROPOSED; the repository instructions are not changed by this document]:
1. **`test_architecture.gd`.** Scans `client/sim/*.gd` and fails on any of: `extends Node`, `Input.`, `get_tree`, `Engine.`, `OS.`, `Time.`, `randf()` or `randi()` without an RNG receiver, `load("res://scenes`. Paired with a test that the ban fires on a sample.
2. **The `ZoneView` parity test** (§8).
3. **Local `CLAUDE.md` files** for `client/sim/`, `client/scenes/`, `backend/` and `tools/`, each short and covering only that area.
4. **The workflow, written into CONTRIBUTING.md** (it matches how this branch has been worked):
   1. Inspect.
   2. Read local instructions.
   3. Plan.
   4. List affected systems.
   5. Implement approved changes only.
   6. Add tests.
   7. Run targeted tests.
   8. Run the CI-equivalent checks.
   9. Write an audit note.
   10. Wait for owner review.

## 17. Database and persistence

**WoC** [VERIFIED, `server/db.ts`]:
- Postgres via `pg` with DDL in code (`ensureSchema`).
- `accounts`, `characters` (with `state JSONB`), `world_state`, and many feature tables.
- Explicit transactions (`BEGIN` … `COMMIT`) around multi-row writes.
- Append-only ledgers for banks and accounts (`bank_ledger.ts`, `account_ledger*`).
- Autosave every 30 s plus on leave; a 5-minute link-dead grace; a statement timeout ladder; multiple realm processes (`npm run realms`).

**The Iron Legacy** [VERIFIED]:
- Postgres with forward-only migrations and checksums (`backend/migrations/`, CLAUDE.md).
- Accounts today.
- Saves designed with a `v` field and upgrade functions (DATABASE.md).
- Grants with unique IDs designed (D5); backups designed (BACKUP_AND_RECOVERY.md).

**Proposal** [PROPOSED; no change to the backend now]:
- **Characters:** a `characters` row with a versioned JSON `state` (as `PlayerProfile.to_dict` already produces, with migrations in `PlayerProfile.from_dict`).
- **Items and currency:** relational `inventory_items` and `wallet` tables for anything tradable, so item duplication is a constraint violation, not a bug to find.
- **Ledgers:** every reward, purchase and enhancement is an append-only ledger row keyed by grant ID, so a retry inserts nothing.
- **Cadence:** zone checkpoint every 60 s and on exit (DATABASE.md); rewards committed before acknowledgement.
- **Restart recovery:** the zone resumes from checkpoints, and in-flight grants are retried idempotently.
- **Backups and migrations:** as BACKUP_AND_RECOVERY.md, with a restore drill per release.

## 18. Performance and 4,000 CCU

**WoC facts** [VERIFIED]:
- One process runs one realm's `Sim` at 20 Hz.
- Snapshots go out once per loop (about 50 ms), interest-scoped.
- The default realm admission cap is 5,000 (`DEFAULT_MAX_PLAYERS_PER_REALM` in `server/http/config.ts`). That is a configuration value, not a measurement.
- Load tools: bot crowds (`scripts/load_players.mjs`, local only), snapshot-gap jitter under a crowd (`scripts/server_load_jitter.mjs`), client frame cost under a crowd (`scripts/client_perf_under_load.mjs`), a per-phase tick profiler (`server/tick_profiler.ts`).
- No capacity figure for concurrent players was found in the repository [UNKNOWN]; a live MMO does not prove a number.

**The Iron Legacy** [VERIFIED / MEASURED]:
- Sim cost 0.30 ms per tick on average, worst tick 7.1 ms: native headless, 1 hero and 10 enemies (PERFORMANCE.md).
- Planned instance caps: hub 80, farm 24, boss 4–5 / 10 (assumptions).
- Bandwidth estimate: about 58 kbit/s per player (assumption).
- A staged load-test plan exists (M8).

**Staged plan** [PROPOSED; extends PERFORMANCE.md M8, adding WoC's measures]:

| Stage | Measure | Pass condition (proposed; set before each run) |
|---|---|---|
| S0 | One zone instance headless: 1, 5, 24 heroes with bots; ms per tick at 60 ticks/s | p95 tick < 8 ms, worst < 16 ms |
| S1 | One process, several instances | Memory per instance; ticks stay within budget |
| S2 | Gateway + zone, 50 → 100 → 500 bot connections | Snapshot gap p95 < 70 ms (WoC-style jitter probe); input-to-snapshot p95 < 150 ms |
| S3 | 1,000 connections across instances | Tick overrun < 1%, disconnects < 0.5%, DB p95 < 20 ms |
| S4 | 4,000 connections | All of the above. Capacity is claimed only for stages that pass |

Report hardware and raw results in `docs/load-tests/`, as PERFORMANCE.md already requires.

## 19. Comparison with The Iron Legacy

| Domain | WoC | Iron Legacy now | Gap | Recommendation |
|---|---|---|---|---|
| Simulation | One deterministic sim, three hosts; tested purity [VERIFIED] | Pure `client/sim/`, seeded; scenes, tests and harness host it; server planned [VERIFIED] | Purity not tested | Architecture test (§16) |
| Combat | Tab-target, classic tables, armor DR with a monster cap [VERIFIED] | Action combat, move frames, flat DEF [VERIFIED] | Defense curve | Hybrid-T from rAthena Round 2; consider WoC's mitigation cap; no HIT/FLEE |
| Character | Effective stats module [VERIFIED] | `PlayerProfile.stats` [VERIFIED] | — | Keep; a `StatusRules` helper if the stats grow |
| Equipment | Item level and equipment rules [VERIFIED] | Grades, budget, enhancement [VERIFIED] | Grade lever weak (Round 2) | Grade spread (Round 2) |
| Monster | Data records, AI in the sim | Data and `EnemyBrain` | Role field | Role and intent fields (rAthena blueprint §9) |
| Boss | Encounter modules, geometry helpers | `BossMechanics`, phases, hazards | Avoidability tests | Timing rules as data tests (Round 2, §V3.3) |
| Loot | Server-side, ledgers | `LootRules`, seeded | Grant IDs online | D5 at IL-7 |
| Farming | Farm crops (wall-clock; cut from RL) | `FarmSpawner` camps, ticks | — | Keep tick-based; never wall-clock in the sim |
| Networking | WS, 20 Hz intents, interest radii, backpressure | Designed (NETWORKING.md), not built | All | IL-7; add a backpressure rule; fix 20/60 Hz |
| Persistence | Postgres, JSONB state, ledgers, 30 s autosave | Postgres accounts; saves designed | Characters, items, ledger | §17 |
| UI | View-core + painter, i18n, fairness rule | Godot HUD, UI kit | Testable view cores; fairness rule | §13 |
| Editor | Real-engine map editor | None | All | Godot plugin over JSON (§12) |
| Admin | Svelte SPA, fail-closed permissions | None | All | After IL-7 (§13) |
| Testing | Architecture, parity, size ratchet, browser regression, gate | Godot suite, lint limit, web smoke, security | Architecture and parity tests; local guides | §16 |
| Performance | Tick profiler, jitter and crowd probes; no CCU proof | Native sim cost; plan M8 | Zone measurements | §18 |

## 20. Recommended Godot-compatible architecture

[PROPOSED]

| Layer | Contents |
|---|---|
| Rules (`client/sim/`) | Unchanged role; guarded by tests; the one source of combat, AI, loot, quests and world-boss rules |
| View seam (`ZoneView`, `ZoneCommands`) | Scenes read and command through it; `ZoneSim` today, a `NetZone` mirror online |
| Presentation (`client/scenes/`) | Renders, plays audio, reads input; new HUD parts as pure view-cores plus painters |
| Hosts | Godot client (offline), headless test runner and scenario runner, headless zone server (IL-7) |
| Services | Existing backend (accounts, saves, grants, ledgers, admin API); gateway (auth, rate limits, backpressure) |
| Tooling | Area editor plugin, guide generator, load-test bots |

## 21. Phased roadmap

[PROPOSED; none of it is started]

| Phase | Objective | Systems affected | Architecture | Depends on | Risks | Tests | Acceptance | Rollback |
|---|---|---|---|---|---|---|---|---|
| 0 Preserve and document | Record current systems and decisions | Docs only | Local `CLAUDE.md` per area; fix the 20/60 Hz text after a decision | — | None | — | Owner review | Revert the doc |
| 1 Boundaries and data definitions | Enforce `sim/` purity; document JSON fields | Tests, docs | `test_architecture.gd`; field headers | 0 | False positives | The ban fires on samples | CI green; no gameplay diff | Remove the test |
| 2 Combat testability | Scenes read through `ZoneView` | `client/scenes/*`, `client/sim/ZoneView.gd` | View seam + parity test | 1 | Line limits; UI regressions | Parity; scene tests; web smoke | Identical play; all tests green | Revert the scene edits |
| 3 Headless balance framework | Scenario runner + balance bands | `client/tests/harness/` | §11 | 1 | Slow CI | Band tests | Round 2 tables reproduce from scenario files | Drop the CI step |
| 4 Server-authority boundaries | Commands and snapshots defined over the seam | `client/net/` (message schemas), `client/sim/` commands | Input `seq`, snapshot schema, `NetZone` stub | 2 | Protocol churn | Schema round-trip; replay a recorded input stream offline equals live | Offline replay matches | Feature flag |
| 5 Content authoring | Area editor plugin; guide generator | `client/addons/`, `tools/guide/` | §12, §14 | 1 | Editor-only bugs | JSON round-trip; freshness diff | Edit → save → validated → playtest | Remove the addon |
| 6 Persistence and scale prep | Characters, items, ledgers, grants | `backend/` migrations | §17 | 4 | Migration mistakes | Fresh-DB + existing-DB migration tests; duplicate-grant test | No duplication under retries | Down-migration plan before release |
| 7 Load tests and multiplayer | S0–S4 | Zone server, gateway | §18 | 4, 6 | Capacity shortfall | Load scripts | Stages pass their thresholds | Cap instances; stay at the last passing stage |

## 22. Risk assessment

- **Over-abstraction:** a seam per domain before a second implementation exists adds cost with no benefit. Mitigation: `ZoneView` only, grown on demand.
- **Tick-rate mismatch** (20 vs 60 Hz) would desynchronise prediction. Decide before Phase 4.
- **GDScript server cost** is unmeasured for multi-player instances (risk R1 in ARCHITECTURE.md). Phase 7 S0 first.
- **File-size limits:** `ZoneSim.gd` and `Game.gd` are at the limit; seam work must extract, not append.
- **Licences:** WoC's code is MIT; its assets, names and dependencies are not covered by that grant. This blueprint copies nothing.
- **Tool sprawl:** an editor, an admin and a guide are three new surfaces. Build them only when content volume or operations need them.

## 23. Owner approval checklist

- [ ] Decide the zone server's tick rate: run the rules at 60 ticks/s with 20 Hz snapshots (recommended), or re-time the rules.
- [ ] Approve the architecture purity test for `client/sim/` (Phase 1).
- [ ] Approve local `CLAUDE.md` files per area and the written agent workflow (Phase 0).
- [ ] Approve the `ZoneView` seam and parity test (Phase 2).
- [ ] Approve the headless scenario runner and balance-band tests (Phase 3).
- [ ] Approve the guide generator with a freshness check (Phase 5).
- [ ] Approve the area editor plugin over JSON (Phase 5).
- [ ] Approve the persistence model: relational items and wallet, ledgers, grant IDs (Phase 6).
- [ ] Approve the staged load-test thresholds (Phase 7).
- [ ] Decide whether to adopt WoC-style mitigation caps on monster hits against players (combat; see the rAthena blueprint Round 2).
- [ ] Confirm: ideas only from WoC; no code, assets or names imported.

## 24. Source references

**World of ClaudeCraft @ `ef93e018f6196c5d9b8a0052eac6fb17d7b22a93`:**
- **Repository guides and docs:** `CLAUDE.md` (repo map, architecture, invariants, modularity), `src/net/CLAUDE.md`, `server/CLAUDE.md`, `headless/CLAUDE.md`, `src/editor/CLAUDE.md`, `src/admin/CLAUDE.md`, `docs/qa-gate.md`.
- **Simulation and seam:** `src/sim/types.ts` (`TICK_RATE`, `DT`, `PLAYER_INTEREST_RADIUS`, `PLAYER_INTEREST_DROP_RADIUS`, `GCD`, `MIN_GCD`, `meleeMissChance`, `swingMissChance`, `MOB_VS_PLAYER_MAX_MISS`, `armorReduction`, `MOB_VS_PLAYER_MAX_ARMOR_DR`), `src/sim/rng.ts` (`Rng`, `setObserver`), `src/sim/sim.ts` (`class Sim`, `tick`), `src/sim/obs.ts` (`ACTIONS`, `applyAction`, `encodeObs`, `obsSize`), `src/sim/map_doc.ts`, `src/sim/content/`, `src/sim/data.ts`, `src/world_api.ts`, `src/world_api/*.ts`, `src/net/online.ts` (`ClientWorld`), `src/net/backoff.ts`.
- **Server:** `server/game.ts` (`GameServer`, the tick loop, `AUTOSAVE_SECONDS`, `feedRealmCalendar`), `server/interest_policy.ts` (`INTEREST_RADIUS`, `NPC_INTEREST_RADIUS`), `server/ws_auth.ts` (`createWsAuth`), `server/http/config.ts` (`DEFAULT_MAX_PLAYERS_PER_REALM`), `server/linkdead.ts` (`LINKDEAD_GRACE_MS`), `server/msg_rate_limit.ts`, `server/msg_lanes.ts`, `server/ws_backpressure.ts`, `server/input_seq.ts`, `server/db.ts` (`accounts`, `characters`, `world_state`, transactions), `server/bank_ledger.ts`, `server/tick_profiler.ts`, `server/admin_permissions.ts`, `server/admin_routes.ts`, `server/maps.ts`.
- **Headless and tests:** `headless/env_server.ts`, `python/wow_env.py` (`WoWClassicEnv`), `tests/architecture.test.ts`, `tests/world_api_parity.test.ts` (`IWORLD_MEMBERS`), `tests/monolith_budget.test.ts`, `tests/guide.test.ts`, `tests/off_stream_rng.test.ts`.
- **Scripts and project files:** `scripts/wiki/build_content.mjs`, `scripts/load_players.mjs`, `scripts/server_load_jitter.mjs`, `scripts/client_perf_under_load.mjs`, `scripts/asset_budget.mjs`, `package.json` scripts (`wiki:content`, `env`, `bench`, `realms`, `gate`), `.github/workflows/`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `CREDITS.md`.

**The Iron Legacy:**
- **Project docs:** `CLAUDE.md`, `ARCHITECTURE.md` (D1–D8), `NETWORKING.md`, `PERFORMANCE.md`, `DATABASE.md`, `docs/HARNESS.md`, `docs/STORY_BIBLE.md`, `docs/RATHENA_RESEARCH_AND_IRON_LEGACY_BLUEPRINT.md` (including Design Validation Round 2), `docs/COMBAT_AND_PROGRESSION_BALANCE_AUDIT.md`.
- **Code and data:** `client/sim/*.gd` (`ZoneSim`, `CombatRules`, `AutoPilot`, `WorldBossRules`, `WorldBossRun`, `ContentDB`), `client/tests/TestRunner.gd`, `client/tests/harness/ProgressionHarness.gd`, `client/tests/unit/test_project.gd`, `client/tests/unit/test_harness.gd`, `client/data/*.json`, `backend/`, `.github/workflows/`.
