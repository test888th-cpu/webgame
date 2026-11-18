# Game migration register: the existing game onto the reference rules

**Owner orders (2026-11-18):**

- **"Complete existing game overhaul"**: replace the legacy gameplay of the production game with the World of ClaudeCraft rules (`d2b91e0884cb269422c28d0b42d2a30a01de130a`).
  - Reuse the existing maps, presentation, HUD, hotbar and save flow.
  - Reorder the map progression.
  - Place reference monsters on the existing maps.
  - Rebuild the loot.
- **"Complete player data reset"**: the existing characters are test data. No legacy save migration is needed.

**Status of this document: Stage 1 (inventory and classification) is complete. Stages 2 to 9 are NOT complete.**

- **What is done:** the reference combat engine that the migration will run on exists and is tested. It is currently driven by the Reference Trial (a test tool).
- **What is not done:**
  - Nothing in the production game (Title → New game → `Game.tscn` → `ZoneSim`) uses it yet.
  - No legacy production system has been replaced or removed.
  - No player data has been reset.

The register below is the plan for each system and its real current state.

## 1. What the existing game is (inventory, from the repository)

- **Engine and genre.**
  - A side-scrolling beat 'em up: one street per area, three depth lanes and hit boxes.
  - It runs at 60 ticks per second (`CombatRules.TICK_RATE`).
  - Its runtime is `client/sim/ZoneSim.gd`, at the 1000-line limit, with `Fighter`, `CombatRules`, `LaneMovement`, `EnemyBrain`, `AutoPilot`, `BossMechanics`, `BossSkills`, `FarmSpawner` and `LootRules`.
  - It is presented by `client/scenes/game/Game.gd` (957 lines), `GameMenus`, `GameFeedback`, `AutoBattle`, `SkillPress` and the fighter views.
- **Areas ("maps").** 59 entries in `client/data/areas.json`; they are data, not separate scenes. The street is generated from each entry's theme, kit theme, width, obstacles and blocks. The breakdown:
  - 33 story or district areas, legacy levels 1 to 48;
  - 2 safe hubs (`depot_yard`, `main_city`);
  - 12 farming grounds (`kind: farm`, levels 4 to 68);
  - 5 lairs (levels 45 to 70);
  - 8 world-boss arenas (levels 26 to 68);
  - 1 PvP arena (`pvp_arena`).
- **Themes.** `depot`, `market` and `canal`, with kit themes `junkyard`, `carpark`, `fight_club`, `tunnels`, `gang_hq`, `docks`, `plant`, `waste` and `arena`. The setting is urban and industrial, with no forest, field or open countryside.
- **Player.**
  - 5 heroes (`mika`, `oren`, `riku`, `kan`, `dao`) and 5 jobs (`boxer`, `brawler`, `grappler`, `counter`, `striker`).
  - Progression and items: legacy max level 70 (`progression.json`), 249 items (`items.json`) plus the catalog, 12 quests.
  - Systems: an enhancement workbench (`EnhanceRules`), shops, food, an ultimate gauge, combos, counters, passives, and grab and throw.
- **Enemies.** 64 legacy enemies (`enemies.json`), legacy bosses and boss skills (`boss_skills.json`), and world bosses (`world_boss.json`).
- **Inputs** (`scripts/core/InputSetup.gd`):
  - movement: `move_*`;
  - combat: `attack_light`, `attack_heavy`, `dodge`, `guard`, `grab`, `ultimate`, `skill_modifier`, `use_item`, `interact`, `auto_battle`;
  - menus: `bag`, `character`, `skills`, `map`, `quests`, `guide`, `pause`, `quest_action`, and the `menu_*` and `ui_*` actions.
- **Saves.** `SaveStore` (`user://characters/<id>.json`, `PlayerProfile` SAVE_VERSION 13) plus the trial's `user://reference_slice.json`. Saves live in each player's browser (IndexedDB) or desktop user folder. None are in the repository.

## 2. Classification

Production status: **NOT STARTED**, **PARTIAL** or **DONE**, always as of this document.

| Existing system | Decision | Replacement (reference) | Production status |
|---|---|---|---|
| Godot project, Title, scene navigation | KEEP | — | unchanged |
| Area renderer (street kits, palettes, obstacles), camera | KEEP | the same areas, with reference monsters | unchanged |
| Character and enemy sprites, animations, effects | KEEP (ADAPT: map reference ids to existing art through stable ids) | art by id, as `ASSET_REPLACEMENT_MAP.md` | NOT STARTED |
| HUD layout, hotbar layout (`HotbarRules` 7 slots), inventory and equipment screens | KEEP the layout, REPLACE the data | reference abilities in the slots; reference gear | NOT STARTED |
| Heroes and the 5 jobs (`JobRules`, `jobs.json`) | REPLACE | 9 classes, 27 specs (`RpgTalents`, `RpgUnit`) | NOT STARTED (works in the trial only) |
| Skills, combos, counters, passives, ultimate gauge (`SkillRules`, `ComboRules`, `CounterRules`, `PassiveRules`, `UltimateRules`) | REPLACE | reference abilities, talents and auras (`RpgCast`, `RpgEffects`, `RpgCombat`) | NOT STARTED |
| Light and heavy attack chains (`moves.json`, `MoveLibrary`) | REPLACE | the auto attack (melee, wand, auto shot) and abilities | NOT STARTED |
| Dodge and guard inputs | REMOVE (the reference has no player dodge or guard action; dodge and parry are passive hit-table outcomes) | `RpgSwing` hit table | NOT STARTED |
| Grab and throw (`GrabRules`, `grab` input) | REMOVE (no reference equivalent) | — | NOT STARTED |
| Street weapons: pickup and throw (`StreetWeapons`, weapon pools in `areas.json`) | REMOVE (no reference equivalent) | — | NOT STARTED |
| Combat formulas (`CombatRules`, `LevelRules`, `BalanceProfile`) | REPLACE | `RpgSwing`, `RpgCombat`, `RpgEffects` (the source formulas) | NOT STARTED |
| Lanes and hit boxes (`LaneMovement`, `Bodies`) | ADAPT | reference ranges in yards; the street's x axis as the distance, as the trial does | NOT STARTED |
| Enemy AI (`EnemyBrain`, `AttackTokens`) | REPLACE | mob pursuit, reach and swing (`RpgEncounter`, from `combat_profile.ts`) | NOT STARTED |
| Boss mechanics and skills (`BossMechanics`, `BossSkills`, `BossEnrage`, `BossBarrier`) | REPLACE | reference boss mechanics (`MOBS` mechanics fields): not implemented in any runtime yet | NOT STARTED, BLOCKED by the boss-mechanic engine |
| Encounters and farm spawning (`ZoneSim` encounters, `FarmSpawner`, `BlockRules`) | ADAPT | reference monsters at reference levels per area (§3) | NOT STARTED |
| Loot (`DropTables`, `LootRules`, `drop_tables.json`) | REPLACE | `RpgLootRoll` (corpse `rollLoot`, parity-tested) and the 8 reward-source models | NOT STARTED (trial only) |
| Items, grades, catalog (`items.json`, `ItemRules`, `ItemCatalog`) | REPLACE | the reference item registry (2,263 items) | NOT STARTED |
| Enhancement workbench (`EnhanceRules`) | REMOVE or REPLACE | the reference upgrades only Rift gear at the Rift Forge; no general workbench | NOT STARTED |
| Levels and XP (`progression.json` max 70) | REPLACE | `RpgProgression` (max 20, reference XP table, `mobXpValue`) | NOT STARTED (trial only) |
| Shops, food, economy (`ShopRules`, `FoodRules`, `EconomyRules`) | REPLACE where the reference defines vendors and food; otherwise REMOVE | reference vendors and `sellValue` | NOT STARTED |
| Quests (`QuestRules`, 12 quests) | REPLACE | reference quests: not extracted yet | NOT STARTED |
| World bosses, arena PvP (`WorldBossRules`, `ArenaRules`) | REMOVE from production or BLOCKED (world bosses use personal loot from contributor tracking; PvP needs a server) | — | NOT STARTED |
| Auto battle (`AutoPilot`, `StoryAuto`) | REPLACE | `RpgEncounter` auto mode (sends the same commands) | NOT STARTED |
| Saves (`PlayerProfile` v13, `SaveStore`) | REPLACE (owner reset: old saves rejected, no migration) | `RpgSave` (v2) as the one production format | NOT STARTED |
| Reference Trial | KEEP as a test tool | — | working (§4) |

## 3. Map progression and monster placement: the constraint found

There are two reasons the reference monsters cannot simply be dropped onto these areas:

- **Levels.** The existing areas span legacy levels 1 to 70, but the reference's player levels stop at 20 (heroic dungeon enemies reach 22).
- **Themes.** The 20 monsters the engine can currently fight faithfully are beasts, elementals, undead, a spider and a reptile, from woodland, barrow and coastal zones. The existing areas are all urban and industrial.

The theme rule in this order forbids forcing incompatible monsters into an area. So the placement must draw on the full reference roster, not just the 20 current trial monsters:

- the humanoid, mudfin, troll and burrower families (for street crews, docks and tunnels);
- the elementals and constructs (for the plant and the facility).

Most of those families need monster behaviour the engine does not run yet:

- fleeing at low health (humanoids, burrowers, mudfins, trolls);
- the `mechanics` fields (casting, mana burn, pack frenzy and others).

The order of work is therefore:

1. The flee and mechanics engine.
2. Placement across the existing areas, for the owner to see.
3. Loot by placement.

`docs/MONSTER_SELECTION_MATRIX.md` and `AREA_LEVEL_MAPPING_PROPOSAL.md` hold the earlier candidate analysis; their area and level bands are the starting point.

## 4. What exists now and works (the engine the migration will use)

Every item below is tested in `client/tests/unit/test_rpg_combat_engine.gd`, `test_rpg_talents.gd` and `test_rpg_runtime.gd`.

- **20 Hz world in the source's tick order**, with real positions, monster pursuit and reach, idle aggro radius, and projectiles that fly.
- **All nine classes fight with their own source attack:**
  - melee swings, with dual wield and shield block;
  - wand shots for mage, priest, warlock and druid;
  - auto shot for the hunter.
- **Stats.** A `recalcPlayerStats` port with gear, aura stat kinds, and spec and talent modifiers. Health and mana keep their fraction.
- **Specs and talents.** The `computeTalentModifiers`, `abilitiesKnownAt` and `applyTalentMods` ports, matched against the source on 216 random allocations. All 27 specs and every talent row are selectable, apply their modifiers and are saved.
- **Abilities.** All 424 are classified with evidence: 22 implemented, the rest BLOCKED, UNKNOWN or not for players, each with its reason (`runtime_pack.json` `abilities.*.status`). There are 14 general effect handlers, the aura lifecycle, damage and heal pipelines, cast bars, spell resists and pushback.
- **Death and revive.** Death, then `resurrectAtCorpse` (50% health and mana).
- **Corpse loot.** Corpse loot persists in the save until taken or decayed.
- **Saves.** The `RpgSave` v2 format with talents.

## 5. Production execution order (2026-11-18, second order): progress and exact blockers

### Done in this phase (in the one engine the production game will use)

- **Streets of monsters.** `RpgEncounter.start_zone` puts any number of reference monsters on a street axis, all driven by the same engine.
  - Each monster has its own pursuit, idle aggro, swing, corpse and kill credit.
  - Projectiles fly to their own target unit.
  - Tested in `test_a_street_of_monsters_is_one_engine`.
- **Player movement on the street axis** at the reference's `RUN_SPEED` (7 yd/s, `types.ts:65`). There is no movement while stunned or rooted.
- **Targeting.** The `target`, `target_nearest` and `attack` commands; attacking with no target gives the reference's "Invalid attack target.".
- **Auto.** It picks the nearest monster already fighting the player, else the nearest. It walks to its target through the same move command and attacks with the same commands as a player. The walking is an automation choice: ADAPTED, PROD-AUTO.
- **Corpses.** One corpse per kill. Corpses are saved, looted together and decay after `CORPSE_DURATION` (60 s) or the template's respawn time.
- **Player save cutover (owner reset order).** `RpgSave` version 3 is the single character format. Every earlier format is refused, never migrated: the trial's v1 and v2, and `PlayerProfile` hero saves.

### Done: the production entry point (owner orders 2026-11-18)

- **Old player data reset.** `SaveStore.reset_legacy_player_data` runs once per browser (marker `player_data_reset_v3`). It deletes:
  - the `characters/` roster;
  - `save.json` and its import, backup and unreadable copies;
  - `reference_slice.json`.

  Settings and all non-player data are kept.
- **New character system.** The flow is Title → New game → name and class (`ReferenceTrial.tscn`, now creation and the character sheet) → the street. Continue opens the street.
- **The street** (`scenes/street/Street.tscn`, `UnitSprite`; the game's own HUD, hotbar and touch controls through `Hud.attach_rpg`).
  - It draws the existing areas with `Scenery.build` and the existing LPC sprites.
  - The engine is the one `RpgEncounter`, in zone mode with respawn.
  - Controls: walk (arrows or A/D); J to target and attack; 1-7 for the known abilities the engine runs; T for Auto; E to loot; C for the character screen; Esc for the title.
  - Walking off an end with an exit enters the next area. The area is saved with the character.
- **Placement** (`tools/content/build_placement.py`, `data/rpg/placement.json`, PROPOSED).
  - Monsters are spread over 56 areas in the old level order: old level L maps to reference level `round(1 + (L-2)*19/46)`, from 1 to 20.
  - Each area keeps its old enemy count and positions, its camps (farming grounds) and the old enemies' sprites.
  - Boss and mini-boss slots are recorded on their own maps as BLOCKED.
- **Respawn and corpse decay** in world time, at the reference's delays (PROD-RESPAWN).
- **The roster.** 34 reference monsters can fight, up from 20: monsters whose only extra was a quest-gated loot row now qualify, because without quests that row never drops.

### Not done (exact blockers)

1. **Bosses and mini-bosses.** The slots are kept on their maps, but the reference boss and elite engine is not ported. Legacy boss scripts are not used.
2. **Fleeing and mechanics.** 18 humanoid, burrower, mudfin and troll monsters flee at low health (`mob/flee_rules.ts`), and others have `mechanics`. They are not placed until those behaviours run.
3. **Abilities.** 227 player-learnable active abilities need bespoke class-engine code. The hotbar shows only the ones the engine runs.
4. **Legacy code.** `Game.tscn`, `ZoneSim`, `Fighter`, `CharacterCreate` and `PlayerProfile` are no longer reachable from the title. Deleting them, and their tests, is a separate, reviewable change.
5. **Not ported from the old game yet.** NPCs, shops, quests, the map screen and the arena. Their reference counterparts (vendors, quests) are not in the engine yet.
6. **Level mapping.** Areas above old level 48 all hold level-20 monsters, because the reference's cap is 20.

The text below records the state before this change.

### Not done: the cutover of the production scenes

The production scenes still run the legacy game: Title → `CharacterCreate` → `Game.tscn` → `ZoneSim`. These are the concrete pieces of the remaining work.

1. **`Game.gd`, `GameFeedback`, `AutoBattle`, `SkillPress`, `GameMenus`, `CharacterTabs`, `ShopScreen`, `MapTab` and `Hud.gd`.**
   - These are typed against `ZoneSim`, `Fighter`, `FighterInput` and `PlayerProfile`: about 120 references, listed by `grep -o "zone\.[a-z_]*" scenes/game/*.gd`.
   - The cutover replaces `zone: ZoneSim` with the street engine.
   - It feeds `FighterView` with presentation records built from engine units (position from `x`, facing, HP), so the existing sprites and animations stay.
   - It rebinds the HUD to the unit's health and resource, the boss bar to the targeted monster, and the hotbar to known abilities.
   - Then it removes the legacy inputs: `attack_heavy`, `dodge`, `guard`, `grab`, `ultimate` and weapon pickup through `interact`.
2. **`CharacterCreate` and `Title`.** Class choice (9) instead of hero and job, with appearance kept. `SaveStore` gets a v3 character store and refuses `PlayerProfile` files.
3. **Placement on the existing areas.** Every existing area is urban or industrial (themes `depot`, `market`, `canal`). The reference monsters that fit those themes (humanoid crews, burrowers, mudfins, trolls, constructs) need two behaviours the engine does not run yet:
   - fleeing at low health (`mob/flee_rules.ts`, `sim.ts maybeFlee`);
   - their `mechanics` fields (casters, mana burn, pack frenzy and others).

   Placing the 20 monsters the engine can fight today (beasts, elementals, undead) on streets would break the theme rule, so placement waits for those two engines.
4. **Abilities.** 227 player-learnable active abilities need bespoke class-engine code ported from `src/sim/combat/*`. The pack records each one with the files that special-case it.
5. **Bosses.** Boss and elite mechanics are not in the engine. The legacy boss scripts must not stay as a second combat implementation, so boss areas need the reference boss engine first.

None of these is reported as done.
