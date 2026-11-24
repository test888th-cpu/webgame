# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer.

## [Unreleased]

### Added: the street's game screens on the new engine (2026-11-24, owner order)
- **Character, Equipment, Bag, Skills and Settings** are each their own screen, in the
  original game's windows (`UiKit.screen`), with a row to switch between them (Q / E),
  the original Esc menu (screens, Save game, Save and quit to title), and C / B / V.
  No fight input reaches the street while a screen is open.
  - Character: the live combat unit's sheet (`RpgCharacter.sheet_of`), XP, the
    specialization (from `spec_unlock_level`, through `choose_spec`) and the talents
    chosen.
  - Equipment: the reference's 13 slots. Take off and equip go through
    `RpgCharacter.unequip` / `equip`.
  - Bag: only the copies carried, with details, grade, stats and drop sources. Equip is
    allowed only when the engine allows it (`RpgCharacter.equip_problem`, the engine's
    own reason). No item in this build has a use effect, and there is no merchant, so
    there is no Use or Sell button.
  - Skills: the whole class spellbook (`RpgSpellbook.book`): usable, known but not in
    this build, or locked by level, specialization, talent or quest. Each ability shows
    its reference data. Only usable abilities can go on the hotbar
    (`RpgSpellbook.assign`), and the hotbar reads the same saved layout. A Talents tab
    chooses through `choose_talent`.
  - Settings: the original settings tabs (`GameMenus.settings_tabs`) with the switches
    that work on the street, the street's controls, and the third-party notices.
- **Gear keeps its copy.** Equip takes the chosen bag copy, and its loot quality stays
  with it while worn (`equipment_quality`) and when taken off. Saves keep it, and the
  hotbar layout.
- **Saves report completion.** `DurableSave` waits until the browser's IndexedDB store
  (Godot's IDBFS, `/userfs` / `FILE_DATA`) holds exactly the text written before a save
  counts as done. A newer save supersedes an older wait. Creating a character and Save
  and quit wait for it. Settings are confirmed the same way. The browser smoke test
  reloads right after a confirmed save, with no fixed wait.
- **Test merchant off for players.** `iron_legacy/test_vendor_enabled=false`, and a
  release export never enables it.
- **World of ClaudeCraft MIT notice.** `THIRD_PARTY_NOTICES.md`,
  `LICENSES/World-of-ClaudeCraft-MIT.txt` (the pinned `LICENSE`, unchanged) and, in the
  game, `data/legal/third_party_notices.json`, shown in Credits and Settings > Notices.
- **One set of screens.** The creation screen no longer has its own character sheet. A
  saved character goes straight to the street.

### Changed: the game now runs on the new system (2026-11-18, owner order)
- **Old player data reset.** On first start in each browser, every old hero save
  and roster file is deleted once (`SaveStore.reset_legacy_player_data`, marker
  `player_data_reset_v3`). Settings are kept. There is no migration: old saves never
  load (`RpgSave` version 3 only).
- **New character system.** Title → New game → name and one of the nine reference
  classes. Continue resumes the last character, in the area where it was saved.
  The character screen (C) holds spec, talents, gear and bags.
- **The street.** `scenes/street/Street.tscn` draws the existing city areas (their
  scenery, furniture and exits) and the existing LPC sprites. The street is run by
  the reference engine (`RpgEncounter` in zone mode). It has walking, targeting (J),
  the auto attack, the hotbar of known abilities (1-7), Auto (T), loot (E), death and
  resurrection, and travel at the street ends.
- **The game's own HUD on the street.** The street uses the existing hero card,
  bars, hotbar (slot icons and cooldown sweeps), touch controls, banners and the
  boss bar (here, the target's bar), fed by the engine (`Hud.attach_rpg`,
  `Hotbar.build_rpg`). The menus that are not ported yet (quests, map, settings)
  and the old gauge, weapon badge and route card stay hidden. Hotbar icons are
  temporary art chosen by each ability's first effect (`data/rpg/ability_icons.json`).
- **Monsters by level, in the old order.** `tools/content/build_placement.py` writes
  `data/rpg/placement.json` (PROPOSED). The old area levels 2-70 map onto the
  reference's 1-20 and keep their order. Each area gets its old enemy count, with the
  old enemies' sprites. Farming grounds keep their camps. Boss and mini-boss slots stay
  on their maps as BLOCKED (no boss engine yet).
- **Respawn.** A slain monster rises at its spawn point after the template's
  `respawnSeconds`, else `TRASH_RESPAWN_SECONDS` (60 s, `respawn_policy.ts`). Corpses
  decay in world time.
- **More monsters.** 14 more reference monsters can now fight (34 in all): their only
  extra was a quest-gated loot row. That row drops only for a player on the quest, and
  this build has no quests. The loot parity cases rose from 720 to 1,056.
- **Removed.** The old hero roster screen is no longer reachable from the title.

### Added: the reference combat engine (2026-11-18)
- **The trial world runs at the reference's 20 Hz** in `Sim.tick` order, with real
  distances, monster pursuit and reach, idle aggro, projectiles, cast bars and spell
  resists (`RpgEncounter`, `RpgCast`, `RpgEffects`, `RpgCombat`, `RpgUnit`).
- **All nine classes fight with their own source attack**: melee (dual wield, shield
  block), wands (mage, priest, warlock, druid) and auto shot (hunter).
- **Specs and talents.** `RpgTalents` ports `computeTalentModifiers`,
  `abilitiesKnownAt` and `applyTalentMods`. It matches the source on 216 random
  allocations (`rpg_talent_parity.json`). All 27 specs and every talent row apply to the
  runtime and save.
- **Abilities.** All 424 are classified with evidence in `runtime_pack.json`:
  - 22 implemented, through 14 general effect handlers and the aura lifecycle;
  - 365 BLOCKED, mostly by bespoke class-engine code in the reference, named per ability;
  - 24 UNKNOWN (no acquisition path);
  - 12 not for players.
- **Corrected adaptations.**
  - New characters start as the source does (rage, energy and focus at 0).
  - Death and resurrecting at the corpse follow `reviveAt`.
  - Corpse loot persists in the save (save v2).
- **Evaluator.** It gains `obj.fn?.()` short-circuiting.
- **Migration register.** `docs/GAME_MIGRATION_REGISTER.md` starts the production-game
  migration (Stage 1: inventory and classification). No production system is migrated yet.

### Added: the playable reference slice (2026-11-17)
- **Reference trial** on the title screen. A real single-player loop by World of
  ClaudeCraft's rules: class (9), spec (from level 5), a reference world mob (20 offered),
  combat with auto-combat on by default, manual commands, XP, corpse loot, bags, equip,
  unequip, sell, rest. It keeps its own save (`user://reference_slice.json`); hero saves
  are not touched. See `docs/PLAYABLE_SLICE.md` for what is partial.
- **Runtime (`client/sim`).** `RpgRng` (mulberry32), `RpgSwing` (`meleeSwing`,
  `mobSwing`), `RpgLootRoll` (`rollLoot`), `RpgCharacter`, `RpgGear` (equipment rules),
  `RpgEncounter` (one command pipeline for auto and manual), `RpgPack` and `RpgSave`.
- **Data.** `client/data/rpg/runtime_pack.json` comes from
  `tools/content/build_runtime_pack.py`. It contains every class, spec and level's known
  abilities as the source computes them, with each of the 424 abilities' entries marked
  EXECUTABLE (1) or NOT_EXECUTABLE with a reason.
- **Parity.** `tools/content/runtime_parity_fixtures.py` runs the reference's own `Rng`,
  `rollLoot` and `meleeSwing`. The Godot runtime matches it bit for bit: 5 seeds,
  720 loot rolls and 400 swings.
- **Evaluator.** `tools/content/ts_eval.py` gains `switch`, whole-chain optional
  short-circuiting (`a?.b.c`, `o.f?.()`) and `Object.getPrototypeOf` for plain records,
  with tests. The 12 reference registries are unchanged by it (`--check`).
- **Milestone A.** The eighth reward source, `rift_first_clear`
  (`addRiftProgressionLoot`), is modelled and verified: 840 scenarios, 0 mismatches. The
  world-quest cycle parser and rotation (A2) and the weekly-vault candidate construction
  (A3) now run as source-verified steps. The eight sources together cover 16,939
  scenarios, all PASS.
- **Not done (stated in game and in the doc).**
  - Ranged auto attacks: hunter, mage, priest, warlock and druid cannot fight yet.
  - 423 of 424 abilities do not run yet.
  - Spec modifiers, talents, auras, bosses, quests and upgrades are not applied.
  - No area placement.
  - No desktop build: it is blocked because there are no desktop export templates or
    preset.

### Added: reference reward-source execution models (2026-11-17)
- **Seven execution models.** The seven non-LootEntry reward sources (buddy drops,
  world-quest loot, hoard bosses, treasure vaults, Rift clear pools, the Drowned
  Litany chest, the weekly vault) now have execution models in
  `reference_loot_tables.json`. Each records:
  - its entry point, triggers and eligibility;
  - ownership, duplicate handling, reset, quantity and currency;
  - the ordered steps (draws, branches, loops, rewards), each citing `file:line`;
  - the source data it reads.

  `tools/content/reward_models.py` holds the models and a runner with `rng.ts`
  semantics, plus shared quality sub-models. `createLootQuality` makes five extra
  weight draws from tier 1 up.
- **Verified against the source.** `tools/content/verify_reward_models.py` runs each
  model against the real source function (static evaluator, a real `rng.ts` `Rng`
  with scripted values, side effects recorded) over 15,484 scenarios.
  - **Result:** 0 mismatches in rewards, owners, quantities and every draw.
  - **Reference test goldens:** `world_quest_item_slots.test.ts:89`, `:107` and
    `hoard_reward_roll.test.ts:56` all pass.
  - **Negative controls:** each mutated model is caught.
  - **Coverage:** every draw step is exercised.
- **Source findings:**
  - `rollHoardReward` never reads `guestCapped`, despite its comment; the reference's
    own test pins this, and the model follows the code.
  - Buddy rolls are drawn even for an owned companion.
  - The vault mount and next-map chances are drawn even when they cannot pay.
- **Evaluator additions:** classes with `this`, `Math.imul`, regular expressions with
  JavaScript semantics, `splice`, `Set`/`Map` `delete`, `Number()`, and a
  verification-only override of side-effecting collaborators.
- **Monster count reconciliation.** It is generated in `reference_monsters.json`
  `count_reconciliation`: the earlier text match is reproduced (316 = 302 + 14), and
  each of the 63 records it missed is classified from the syntax tree.
  - **Correction:** the earlier "53 missing" was 62 in `MOBS`; it left out the 9
    Tideglass Reflections.
- **Loot relationship graph.** It is validated in the manifest (`loot_graph`):
  monster → table → entry → item, quest gates (9 resolve in the Studio overlay's own
  quests), and reward sources → monsters, items, tables and models. 0 problems.
- **Tests:**
  - **New:** `test_rpg_reward_models.gd`, `tools/content/test_reward_models.py` (in
    CI) and more evaluator tests.
  - **Updated:** `test_rpg_loot_registry.gd`. Reward sources now read MODELLED, and
    must still be labelled "not Iron Legacy loot logic".
- **No gameplay, data, save, scene or art change.**

### Changed: final reference fidelity audit (2026-11-17)
- **Approximated Math audit.** The evaluator now traces every Math call and `**`
  operation:
  - 2,896 operations examined: 2,670 exact and 226 implementation-approximated, at 27
    sites;
  - every approximated result is tagged through data flow;
  - every decision on a tagged result is recorded.

  **Result:** 0 tagged values reach any registry, so all 226 are
  NON_GAMEPLAY_LAYOUT_ONLY. All 27 sites compute spatial data (spawn facings,
  positions, the Sledge Tusker's patrol loop).
  - The 62 decisions all stay inside `TUSKER_ROAD`. Its confinement is re-verified on
    every build.
  - A tagged value in a registry is written as UNKNOWN.
  - An unconfined decision fails the build.
  - **New tool:** `tools/content/audit_math_perturbation.py`. It found every registry
    byte-identical when each site moves one ulp up, one ulp down or grossly, and when
    all sites move together (83 rebuilds).
- **Evaluator fixes:**
  - `**` and `Math.pow` are counted as approximated, except for exact integer powers;
  - a negative base to a fractional power is now NaN, as in JavaScript; Python
    returned a complex number.
- **Owner decisions F1–F6 applied** and recorded in
  `ADOPTION_DECISIONS_IMPLEMENTATION.md`:
  - **Rare spawns stay `rare`:** `proposed_role` / mini-boss is removed from the
    registry, `RpgMonsterRegistry` and the matrix, whose slot is now `rare`.
  - **Level 21:** the level-21 ground stays empty.
  - **Matrix:** stays PROPOSED.
  - **Loot:** stays data only.
- **The owner's visual-overhaul deferral directive** is recorded; no visual content
  changed.
- **Tests:**
  - **Status totals:** items 2,197 + 42 + 24 = 2,263; monsters 118 + 126 + 28 + 7 + 49
    + 14 + 37 = 379.
  - **No mini-boss** anywhere.
  - **Level-21 invariant.**
  - **Loot semantics:** `heroicCopper`, `maxPlayerLevel`, `unlessOwned`, quest gates,
    fall-forward, world-boss personal loot, procedural labels, and group sums 49/46.
  - **Approximated Math isolation.**
  - **Evaluator taint tests.**
- **Docs updated:**
  - `REFERENCE_UNKNOWN_REPORT.md`, with the per-site table;
  - `REFERENCE_LOOT_REGISTRY.md`, with the semantic audit;
  - `REFERENCE_MONSTER_REGISTRY.md`, `ADAPTATION_REGISTER.md` and
    `REFERENCE_TRACEABILITY_MATRIX.md`;
  - `PHASE_B2_PLAN.md` and `REFERENCE_REGISTRY_BUILDER.md`;
  - the matrix, regenerated.

### Changed: Phase B2 monster registry validated; reference-locked loot registry (2026-11-17)
- **Correction to the entry below.** The monster registry did not hold every
  template. "None missing" was wrong: a text match cannot see records built by
  helpers, added when a module loads, or keyed by constants.
- **Evaluated registries.** The builder now reads the reference's own tables:
  - `MOBS`, `ITEMS` and the Studio overlay;
  - every loot table.

  It uses `tools/content/ts_eval.py`, a static evaluator for the data subset of
  TypeScript. It never runs reference code, and an unsupported construct is recorded
  as UNKNOWN with its file and line.
  - **Monsters:** 379 = 364 `MOBS` + 15 Studio overlay (was 316). 53 were missing,
    among them the hydra heads, the per-class Tideglass Reflections and the muster
    soldiers. The 14 Scorching Wastes templates are now labelled as the Studio
    overlay.
  - **Items:** 2,263 (was 1,948), including 116 heroic variants added at load.
  - **Other fixes:**
    - one non-item (a quartermaster offer) removed;
    - 19 trinkets corrected from an invented `trinket` kind to the source's `armor`.
  - **Mechanics:** all 68 UNKNOWN nested values resolved; 0 UNKNOWN remain.
  - **Fields:** every source field is kept in `source_fields`.
  - **Flags:** boss 34, elite 182, rare 26, worldBoss 3.
- **Classification.** `RpgMonsterRegistry.role()` returned "mini_boss" for rare
  spawns; the reference has no such flag. It is replaced by:
  - `classification()`: the source flags (VERIFIED);
  - `proposed_role()`: mini-boss for rares only (PROPOSED).
- **Loot registry (new, data only).** Three files in `data/registry/`:
  - `reference_loot_tables.json`: 400 tables (379 monster tables + 21 heroic
    appends), roller rules each citing `file:line`, 7 non-LootEntry reward sources,
    and a coverage list;
  - `reference_loot_entries.json`: 1,190 entries with exact chances, roll groups,
    quest gates and copper bands; 661 items, all resolving;
  - `loot_selection.json`: adoption separate from the data. Nothing is adopted, every
    item decision is pending (2,197), and the legacy loot file hashes are recorded.

  Roll-group sums are kept as computed, never normalised. The previous 744 entries
  missed every table built by a helper or a constant, and every heroic append.
- **Namespaces.**
  - Reference records are `reference:<id>`; the game's own are `iron_legacy:<id>`.
  - `data/registry/id_collisions.json` lists one shared bare id, `training_dummy`;
    each side keeps its own record.
- **Loading helper.** `client/sim/RpgRegistryLoader.gd` now loads and validates the
  registries, and `ContentDB.gd` is 996 lines. File access stays in `ContentDB`'s
  reviewed reader, so `test_sim_purity.gd` is unchanged.
- **New accessor:** `client/sim/RpgLootRegistry.gd`, pure and read-only.
- **Builder.** It now:
  - verifies that the reference checkout is at the pinned commit;
  - fails if a load-time effect cannot be evaluated;
  - writes a source manifest (`reference_registry_manifest.json`) with input and
    output hashes and an evaluator report;
  - lists any record defined in source but not registered.
- **Matrix audit.**
  - **Levels:** source and placement levels are separate fields.
  - **Heroic level 22:** used only for areas at exactly 22, through one recorded
    adaptation (ADAPT-HEROIC-22).
  - **Level 21:** the area at 21 is empty instead of silently taking level-22
    enemies.
  - **Themes:** a poor theme fit is DEFERRED_THEME, not dropped.
  - **Empty slots** are listed (57), with no promotions.
  - **Statuses:** every monster has one status.
  - **History:** the previous matrix is kept in `docs/history/`.
- **New docs:**
  - `REFERENCE_MONSTER_REGISTRY.md`;
  - `REFERENCE_LOOT_REGISTRY.md`;
  - `REFERENCE_REGISTRY_BUILDER.md`;
  - `REFERENCE_UNKNOWN_REPORT.md`;
  - `ADAPTATION_REGISTER.md`.
- **Updated docs:** the traceability matrix, the B2 plan status and corrections in
  `CONTENT_COMPLETENESS_AUDIT.md`.
- **Tests:**
  - **New:** `test_rpg_loot_registry.gd`, `test_rpg_registry_loader.gd` and
    `tools/content/test_ts_eval.py`.
  - **Updated:** the monster and item registry tests.
  - **CI** runs the evaluator tests and the matrix freshness check.
- **No gameplay change:** live enemies, items, loot, areas and levels are as before.

### Added: Phase B2 monster registry, boss and elite metadata, area selection matrix; fidelity rule (2026-11-17)
- **Monster registry.** `data/registry/reference_monsters.json` holds all **316**
  MobTemplate records at `d2b91e08` (the same count as the scan; none missing). Each has:
  - levels and stats as in source;
  - flags: boss 30, elite 155, rare 26, worldBoss 2, and others;
  - context: 157 world, 86 dungeon, 45 Rift, 18 delve, 10 player pets;
  - heroic level 22 for dungeon enemies;
  - 86 mechanic kinds keyed by their MobTemplate field ids (68 nested values marked
    UNKNOWN);
  - 744 loot entries, whose 516 item references all resolve.

  **Selection:** 245 PENDING_REVIEW, 45 DEFERRED (Rift, seasonal), 14 EXCLUDED
  (Scorching Wastes), 12 NOT_AN_ENEMY (pets, practice targets).
- **Accessor.** `RpgMonsterRegistry` is pure. `ContentDB.read_registry` reads registries
  kept outside the game build. `ContentDB.gd` is now at gdlint's 1,000-line limit:
  further loading goes in a helper.
- **Selection matrix.** `tools/content/render_monster_matrix.py` writes
  `docs/MONSTER_SELECTION_MATRIX.md` and `data/registry/monster_area_candidates.json`:
  PROPOSED candidates per area by reference level, source role and theme fit.
  - 114 monsters are proposed somewhere; 202 are not, each with its reason.
  - Deep farming grounds above 20 use dungeon enemies (heroic 22), labelled ADAPTED.
- `tools/content/area_level_proposal.py` exposes `area_rows()`. Its output is
  unchanged.
- **The owner's non-negotiable reference-fidelity rule** is recorded in
  `docs/REFERENCE_FIDELITY_RULE.md` and in `CLAUDE.md`.
- **New test** `test_rpg_monster_registry.gd`.

### Added: Phase B2 item and per-copy quality registries; level mapping approved; spec naming proposal (2026-11-17)
- **Quality.** `client/data/rpg/quality.json` and `RpgQuality` hold the six reference
  tiers (poor to legendary) and the per-copy quality from `createLootQuality`:
  - draws: plain 9,000; tier 1 900; tier 2 90; tier 3 9; tier 4 1, out of 10,000;
  - so 90 / 9 / 0.9 / 0.09 / 0.01%, summing to exactly 100%;
  - +2 item levels per tier.
- **Reference items.** `data/registry/reference_items.json` has 1,948 records, kept
  outside the Godot project so the browser build does not carry them:
  - each with kind, slot, quality, armour type, hand, required level (when set),
    stats, weapon, class restriction (all 695 constants resolved) and sell value;
  - the reference id, name (internal only) and file, with the SHA-256 of all 189
    inputs;
  - selection: 1,882 PENDING_SELECTION, 42 EXCLUDED (Scorching Wastes), 24 DEFERRED
    (Rift).
  - Item level is not a static field in the reference: it is derived at drop time,
    and it is not invented here.
- **Legacy items.** `data/registry/legacy_items.json` lists all 305 legacy items:
  - the 25 Godforged items map to legendary (ADAPTED);
  - the 31 charms keep the interim slot;
  - the live files are unchanged.
- **Level mapping v2 approved** by the owner, with boundaries. Not applied. The
  Scorching Wastes are recorded as excluded in the traceability matrix.
- **`docs/SPEC_NAMING_PROPOSAL.md`:** 27 original specialisation names, checked against
  the reference content and our data (0 collisions). PROPOSED, not active.
- **New test** `test_rpg_items_registry.gd`.

### Added: Phase B2.1 class registry and B2.2 equipment slot registry (2026-11-17)
- **Builder.** `tools/content/build_reference_registries.py` reads World of ClaudeCraft
  with `git show d2b91e08:<path>` (text, never executed) and records the SHA-256 of
  every input. `--check` reports stale outputs.
- **B2.1 classes.**
  - `client/data/rpg_reference.json` gains, per class: 3 specs (27 in all, with role,
    primary stat, signature ability and reference id), armour type, weapon groups and
    dual-wield rules.
  - Spec display names are INTERIM (the spec id) until a naming batch; the reference
    names are kept only as `ref.name`.
  - `client/data/rpg/talent_structure.json`: spec at level 5; talent rows at 5, 8, 11,
    14, 17 and 20 with 3 options each.
- **B2.2 slots.** `client/data/rpg/equipment_slots.json` holds the 13 reference slots,
  armour ranks, weapon groups, dual wield, the rogue two-hand ban, ring order and the
  legendary-unique rule. The interim Charm slot and the old-slot map sit in a separate
  `legacy` section marked ADAPTED.
- **Accessors.** `RpgClassRegistry` and `RpgEquipmentRules` are loaded and validated
  through `ContentDB`. **Gameplay does not use them yet:** the live slots are still the
  six legacy ones.
- **Level mapping v2:** evidence for enemies above 22 added. The Rift's S rank (23) is
  deferred until the Rift is adopted; the Scorching Wastes (to 24, a custom map) are
  not adopted.
- **New test** `test_rpg_registry.gd`.

### Added: Level 20 / 60 investigation, level proposal v2, Phase B2 plan (2026-11-17)
- **Verified in reference source:**
  - the player cap is 20;
  - "Level 60" is only Goldcrest's zone display band and the map schema's clamp
    (1–60);
  - pets are created at their owner's level;
  - heroic mobs are pinned to 22, the Rift caps at 22 with S at 23, and the Scorching
    Wastes reach 24;
  - Prestige and post-cap levels are cosmetic.
- **`docs/AREA_LEVEL_MAPPING_PROPOSAL.md` is v2,** with enemy levels from reference
  analogues: lairs 22, deep farming grounds 20–22, both ADAPTED. v1 is kept in
  `docs/history/`. Nothing is applied.
- **New `docs/PHASE_B2_PLAN.md`:** the registry architecture, dependency map, files,
  test plan and save-migration safety plan.
- `docs/ADOPTION_DECISIONS_IMPLEMENTATION.md` now records the owner's round-2
  decisions.

### Changed: owner decisions 1–7 applied where finished (2026-11-17)
- **Decision 7, done.** The Web export leaves out the 37 PixelFX effects that nothing
  uses yet.
  - It is driven by their recipe `use`: `tools/assets/web_export_filter.py`, with a CI
    check.
  - `index.pck` is now 19.2 MB, down from 29.4 MB. The browser smoke test passes.
- **Decision 4.** The reported drop figures were reconciled to exact items and steps.
  The drop audit now re-multiplies all 2,516 selected-drop paths on every run (0
  mismatches).
- **Phase B1.** `faithforged_guard` and the five unknown loot items are resolved, the
  latter as trinkets built by a helper. The reference indexes now hold 1,947 items and
  all 327 class-kit abilities.
- **Decision 2: PROPOSED.** `docs/AREA_LEVEL_MAPPING_PROPOSAL.md`
  (`tools/content/area_level_proposal.py`) covers every area, anchored to the
  reference zone bands, with conflicts and a save plan.
- **Decisions 3, 5 and 6: VERIFIED and PROPOSED.** `docs/ADOPTION_DECISIONS_IMPLEMENTATION.md`
  covers:
  - the Rift Forge rules and the workbench options;
  - the 13 slots and the slot mapping;
  - the 6 qualities, and the per-copy loot quality (90 / 9 / 0.9 / 0.09 / 0.01%,
    +2 item levels per tier);
  - Godforged, which is not in the reference, and its options.

### Added: content completeness audit, Phase A (2026-11-17)
- **New harness `client/tests/harness/ContentAudit.gd`:** reads every item, enemy,
  drop path and upgrade level through the game's own rules (LootIndex,
  EnhanceRules, ContentDB) into `data/content_audit.json`.
- **Generated documents:** `tools/content/render_content_audit.py` and
  `render_reference_catalog.py` write `docs/DROP_RATE_AUDIT.md` (4,490 drop paths with
  real chances and rare-drop expectations), `ITEM_DATABASE_CATALOG.md`,
  `MONSTER_BOSS_DROP_CATALOG.md`, `ENHANCEMENT_BALANCE_AUDIT.md`,
  `SKILL_DATABASE_CATALOG.md` and `EQUIPMENT_AND_RARITY_CATALOG.md`.
- **Reference indexes:** `data/reference/` holds text scans of World of ClaudeCraft at
  `d2b91e08` (abilities; items, mobs and mob loot). They are lower bounds, with their
  method recorded.
- **Written by hand:** `docs/CONTENT_COMPLETENESS_AUDIT.md` (findings and the owner
  decisions blocking Phases B–F), `REFERENCE_TRACEABILITY_MATRIX.md`,
  `CLASS_AND_COMBAT_BALANCE_AUDIT.md` and `PLAYER_GUIDE_DATA_SPEC.md`.
- **Correction:** the reference does have an equipment upgrade, the Rift Forge (5
  steps, essence 2/4/6/8/10, always succeeds, +1 item level). Earlier reports said it
  had none.
- **New test** `test_content_completeness.gd`:
  - every item obtainable;
  - every enemy placed;
  - drops sound;
  - item ids unique.
- No game value was changed.

### Added: 37 PixelFX effects as a traceable VFX library; effects load on demand (2026-11-17)
- **37 more effects from pixelfx** (MIT, owner-approved source) at the same pinned commit
  `a8415968`:
  - weapon slashes;
  - arrows and bolts;
  - fire, ice, lightning, holy, shadow, nature and arcane spells;
  - stun and sleep markers;
  - a spawn poof.

  All are listed in `art/pixelfx/effects.json` with a PROPOSED use; none is wired to a
  skill yet.
  - Re-rendering left the 25 effects already in the game byte-identical.
  - Nine candidates were rejected; seven of them draw PixelFX's stock character.
  - Details: `docs/PIXELFX_VFX.md`.
- **`Fx.gd` now loads an effect's sheet the first time it plays,** instead of every sheet
  at the first hit. All 62 sheets would need 131.5 MB of textures; typical play now
  loads 15.3 MB.
- `import_pixelfx.py` refuses sheets taller than 4096 px (the WebGL limit).
- Every PixelFX record now carries:
  - its source file at the commit;
  - its copyright, and its Sprite Fusion derivation where it has one;
  - its modifications, export size, frames and timing;
  - its proposed use.
- New test `test_pixelfx_library.gd`: browser texture limits, transparency, timing,
  8 players' effects at once, and the library being visual only.
- **Web build grows from 18.2 MB to 29.4 MB.** Whether to ship the unused proposed
  effects before they are wired is an owner decision.

### Added: LPC licences checked at their original sources; item art research (2026-11-17)
- **Every LPC part was checked against the pages its credits cite**, and the credits files
  inside those pages' downloads (`art/provenance/lpc_source_review.json`, with quotes).
  - 22 of the 25 primary pages were read, and 45 of the 52 cited pages overall.
  - Result: 43 VERIFIED, 18 RESTRICTED, 6 UNVERIFIED parts.
  - **All 70 LPC character sheets are RESTRICTED.** The adult bodies and human heads are
    granted only as CC-BY-SA 3.0 / GPL 3.0 by "LPC Character Bases", although the LPC
    generator records them as OGA-BY 3.0.
  - Report: `docs/LPC_LICENCE_VERIFICATION.md`.
- **The inventory now carries `licence_class` and `release_ready`**:
  - a composite takes its least clear part's class;
  - AI art without generation records and the placeholder hats are never release-ready.
- **New generated report** `docs/ASSET_PROVENANCE_GAPS.md`: the exact AI generation
  fields the owner must supply. It also lists the 24 placeholder hats (creator and
  licence UNKNOWN, excluded from release) and the 24 items that show them, with a
  prepared code-drawn fallback.
- **Free item art research:** `docs/FREE_ITEM_ART_RESEARCH.md` covers 13 packs read on
  their own pages, and recommends the CC0 Idylwild packs. Nothing was downloaded into the
  repository or imported.
- **New tests:**
  - `test_visual_replacement.gd`: redrawing a hat keeps the item, stats and save;
    swapping a class sprite keeps its stats.
  - `test_provenance.py`: licence classes, release-readiness, and hats never attributed.

### Added: asset provenance inventory and temporary class art (owner's asset directive, 2026-11-17)
- **`tools/assets/provenance.py`** builds one record per asset or source contribution
  (346 today) from the records the repository already keeps, into
  `data/asset_provenance.json`, `docs/asset_provenance.csv`, `docs/ASSET_PROVENANCE.md`,
  `docs/ASSET_CREDITS.md` and `docs/ASSET_REPLACEMENT_MAP.md`.
  - Unknown facts are written UNKNOWN.
  - Commercial use is "Allowed" only for a licence confirmed at its source
    (`art/provenance/licence_checks.json`).
  - The owner's AI-painted art (kit, weapons, four enemies) is labelled AI Generated,
    with generation records to be filled in `art/provenance/generation_records.json`.
- **CI** (`assets` job) now runs `test_provenance.py` and `provenance.py check`. It fails
  on duplicate ids, missing files, unrecorded assets, external assets without a
  licence, share-alike licences, or image paths in gameplay data.
- **18 temporary LPC class sheets** (`class_<class>_m` and `class_<class>_f`, all nine
  reference classes), mapped in `client/data/class_visuals.json` as
  `character.<class>.<male|female>`.
  - Built only from CC0, OGA-BY and CC-BY parts.
  - Not used by gameplay yet.
  - Tested by `test_class_visuals.gd`.
- Policy, record format, replacement workflow and open owner decisions:
  `docs/ASSET_PIPELINE_POLICY.md`.
- `docs/credits/ASSET_CREDITS.*` regenerated. This adds the class parts and refreshes the
  "Used in" columns, which were stale.

### Added: the Guide, an in-game farming guide (owner's request, 2026-11-16)
- **N (pad: share) or the Esc menu opens the Guide**, with four tabs: Items, Monsters,
  Bosses and Maps.
  - Each tab has search, a filter, a sort and a list, with a page for the chosen entry.
  - Every name on a page links to its own page (item → who drops it → where they
    fight → what else drops there), with Back.
- **Built on `LootIndex`, the rules that pay the drops**, so it cannot disagree with the
  game.
  - Chances are the actual chance per kill; a selection weight is never shown as a
    chance.
  - `progression.json` `"show_drop_rates"` (default true) shows exact rates, or rarity
    words worked out from the same chance.
  - An item with no source reads "Not currently obtainable"; a missing place is never
    made up.
- **Indexed**: 305 items, 39 monsters, 24 bosses and 57 maps.
- `ItemCard.details` can leave out its short "Where to get" list, which the Guide
  replaces with a linked one.
- While the player types in a screen's text box, letters are text, not hotkeys.
- Every drop line says whether it is guaranteed, random or conditional (on a field
  elite, or a world boss share and kill, with the condition written out). Pity drops
  say they rise and up to what. The catalog's initial values are marked `*`
  (`LootIndex.reward_type` / `data_status`).
- `docs/GODFORGED_IMPACT_REPORT.md`, generated: the 15 Godforged items the five non-raid
  world bosses pay (none has another source), and what moving them would change. No
  reward was changed.
- Performance: every one of the 425 pages opens in about 26 ms. Sort keys are worked out
  once per list, and LootIndex keeps each enemy's drops.
- Tests: `test_guide.gd`. `test_ui.gd` lets the Guide keep its four sections, as Settings
  keeps its tabs. `test_loot_index.gd` adds sources and drops agreeing both ways, the
  reward types and data status, and the impact report kept in step.
- Docs: `docs/PLAYER_ITEM_ENCYCLOPEDIA.md`, `docs/UI.md`.

### Added: LootIndex and the generated item and drop database (owner's request, 2026-11-16)
- **`LootIndex` (`client/sim/`)**: every source of every item, built from the rules that
  pay it, with the real chance per kill worked out in closed form. Catalog drops also
  give their conditional steps.
  - Sources: enemies' own tables, the catalog's tables and boss lists, farming grounds
    and field elites, world boss tiers and kills, shops and quests.
  - Enemy kinds: monster, elite, mini-boss, stage boss, world boss, raid world boss.
  - The index is built once per content, so a full report takes 1.6 s.
- **`docs/ITEM_DROP_DATABASE.md`**, generated by `client/tests/harness/DropReportRun.gd`:
  every item with its sources, every enemy's drop matrix by kind, the catalog tables'
  conditional shares, and an acquisition index. Every item has a source; none is
  unobtainable.
- `world_boss.json` marks the three raid world bosses `"raid": true`. This is data only;
  no reward changed.
- Tests: `test_loot_index.gd` (the report in step with the data, every drop traceable,
  chances against their formulas and a seeded run, grade rules, a loot identity for every
  boss, LootIndex and the item card agreeing).
- Open decision: all eight world bosses, not only the three raids, give Godforged prizes
  in the existing data. This is unchanged and recorded in `docs/ITEM_SYSTEM.md` §10.

### Added: the owner's 24 temporary placeholder hats worn on the characters (owner's request, 2026-11-16)
- **24 TEMPORARY / PLACEHOLDER hats cut from the owner's four magenta sprite sheets** by
  `tools/assets/import_placeholder_hats.py`. They exist to build and test the appearance
  system, not as production art.
  - The sheets hold 24 hats, six each, verified; the first brief said 23.
  - Each hat is found by its outline, never by equal cells, and each sheet must give
    exactly 6.
  - The background is removed with hard edges, and each hat is scaled to the size it is
    worn at, with a 16x16 icon.
  - The sources are kept in `art/placeholder/hats/`, and the sprites go to
    `client/assets/placeholder/hats/`, apart from the production art pipeline.
  - A fifth sheet was left out by the owner's decision: three of its hats face the wrong
    way.
- **A hat replaces what the character wears on its head.** In every frame of every
  animation the head's top rows are measured from the frame's pixels.
  - A covering hat hides them (a new shader `hide_rect`) and rests on the brow.
  - A hood shows the face through its opening.
  - Headbands, tiaras and the visor sit over the hair.
  - Each hat mirrors with the body; another hat swaps it, and taking it off brings the
    head back.
  - Tested for all five heroes, both ways, on every frame.
- **Items**: the five existing headgear items keep their ids and wear the officer cap,
  dragon bandana, crested knight helm, golden lion helm and horned crown. The other 19
  hats are new items, Common to Legendary, with the Lion King's Crown for bosses only.
- **Fixed**: the head was measured once per sheet instead of per frame, because every
  frame shares one atlas RID. It is now measured per frame, and stray pixels are ignored.
- Every art entry carries `"status": "placeholder"` (or `"final"`), checked on load.
  Replacing a hat means changing its asset entry; item ids, appearance ids, slots and
  saves stay as they are (`test_art_is_swapped_by_its_asset_entry_alone`).
- Tests: `test_hat_art.gd`, plus updates in `test_item_catalog.gd` and
  `test_item_testing_merchant.gd`.

### Added: item ecosystem, drop tables, equipment looks, Item Testing Merchant (owner's request, 2026-11-16)
- **37 new items** in `client/data/item_catalog.json`, with stable ids, in 8 categories:
  enhancement materials, ores and minerals, energy consumables, headgear, outfits, fist
  weapons, boss materials and special items. They use the six approved grades; none is
  Godforged.
- `items.json` and its 249 items are unchanged.
- Gear stats follow the existing `ItemRules` budgets.
- Details, ids and rates: `docs/ITEM_SYSTEM.md`.
- **Drops** (`drop_tables.json`, `DropTables`): rolled after an enemy's own loot table,
  which is unchanged, on a separate generator, so no fight changes.
  - Chance, category, grade, item and quantity are separate steps.
  - Grade weights (monster 75/20/4.5/0.5/0, boss 40/35/20/4.8/0.2) are shares of a
    successful drop, not chances per kill.
  - Ordinary monsters never roll Legendary, Godforged or boss-only items. This is
    enforced in code and content validation.
  - Named bosses have their own lists: signature materials, and a 0.5% signature
    Legendary.
  - World bosses, their arenas, the training dummy and arena rivals roll nothing new.
- **Enhancement**: stones and catalysts count as Scrap Metal or Refined Alloy at the
  workbench (`counts_as`). Its costs, odds and limits are unchanged.
- **Equipment looks**: a worn hat shows on the hero's head **in place of** the
  character's own headwear.
  - `EquipmentLooks` keeps `Fighter.appearance`; `EquipmentLayers` draws it.
  - Each frame the head's top rows are measured, and the hat covers them all: one
    hat, never two stacked.
  - Outfits and weapons keep the character's own look (owner's decision). Their
    appearance ids are kept for later art.
  - The art is temporary, drawn at runtime by `PlaceholderArt`: 16x16 grade-coloured
    icons marked with a black and white check, and no image files.
  - Item id, icon id, appearance id and art asset id are separate, so final art
    replaces placeholders without touching items or saves.
- **Item Testing Merchant**: one merchant in Iron City Central, behind
  `TEST_VENDOR_ENABLED`: the project setting `iron_legacy/test_vendor_enabled`, or the
  environment variable of that name. It is **on** now and must be turned off for
  production.
  - It sells every new item through the cart, in 8 sections, and gear can be tried on
    in the shop.
  - The token price is never below what a shop pays back for the item plus one coin,
    so buying to resell never pays.
- Arena rivals keep the arena's own gear set: the catalog never changes a loadout.
- "Where to get" lists the new drops and shows the merchant's real price.
- `test_main_city.gd` now counts the game's own city NPCs, which include the merchant
  while it is on.
- Tests: `test_item_catalog.gd` (11 tests) and `test_item_testing_merchant.gd` (4: the
  merchant, buying, a hat covering the old headwear, swapping hats, taking off, save and
  reload).

### Changed: grade colours, smooth arena rivals, auto resumes at once (owner's requests, 2026-11-16)
- **Grade colours (owner's standard)**: the six grades and their ids are unchanged, with
  no data migration (249 items, 25 Godforged kept).
  - Colours: Common white, Uncommon green, Rare blue, **Epic gold** (was purple),
    **Legendary red** (was orange), Godforged light blue (lightened, kept clearly apart
    from Rare's blue).
  - One colour table (`ItemText.RARITY_COLORS`) serves every screen.
  - Grade checks go by grade order (`ItemText.grade_rank`), not by a list of names.
    Godforged loot on the street now sparkles and has the tallest light beam, and its
    pickup is announced like Legendary.
  - Content validation (`ContentDB._validate_loot_grades`) now refuses an ordinary
    monster dropping Legendary or Godforged, and any loot table dropping Godforged
    (a world boss reward only). Tests: `test_grade_standard.gd`.
- **Arena rivals walk smoothly**: a rival used to step one tick at full speed each
  decision and then stand still, a stutter.
  - It now walks every tick between decisions at 1/cadence of full speed (`_drift`),
    covering the same ground as before, so the arena's pace and class balance are
    unchanged (`test_no_class_pairing_is_hopeless_in_the_arena` and the personality
    tests pass as before).
  - The walk animation slows to match a slow step instead of sliding
    (`FighterView.MIN_WALK_PACE`).
  - Tests: `test_arena_integrity.gd`.
- **Auto resumes at once**: the half-second wait after the player's own input
  (`MANUAL_HOLD_TICKS`) is gone. Auto plays from the very next tick, so the player can
  steer and let go, and auto strikes straight away. A blow the player started still
  plays out. Tests: `test_auto_battle.gd`.

### Fixed: boss shields are solid barriers that fit the boss (owner's request, 2026-11-16)
- **A raised shield is now a wall.** It applies to every shielded boss: Director Wiroj,
  the Wiroj Protocol, the Iron Colossus, Subject Zero, the Slag Titan, the Iron
  Sovereign, the Floodgate Marshal, the Crucible King and the Founder's Engine.
- While the shield is up, its footprint (an ellipse round the boss's feet) blocks the
  boss's foes: the hero cannot walk, dodge or be knocked into it. A hero inside when it
  goes up is thrown out and floored, with no damage. If a wall is close behind them,
  they are thrown out on the other side. One the barrier reaches later is shoved out
  without being floored.
- The boss's own side walks through it. The barrier goes when the shield drops or the
  boss falls.
- New rule class `BossBarrier` (`client/sim/`); `ZoneSim.barriers` and
  `ZoneSim._solids_for` make it a wall, and `CombatRules.barrier_shove` puts fighters
  out of it.
- **The dome fits the boss.** It used to be drawn at one size, so heads and raised
  weapons stuck out of it. Each shield in `enemies.json` now gives its footprint
  (`"half": [along, depth]`) and the dome's `"height"`. Both were measured from each
  boss's art in every standing pose. The dome is drawn to those same numbers, so what
  is seen is what blocks.
- Tests: `test_boss_barrier.gd`, including a check of every shielded boss's art against
  its dome.

### Fixed: a boss's skills no longer kill its own crew (owner's request, 2026-11-16)
- **A boss's hazards (its skills' blasts, drops, sweeps and domes) knock its own side
  down but never hurt it.** They used to hit the crew and reinforcements for full damage,
  so a boss could wipe out its own minions by accident.
- New rule `CombatRules.crew_hit`: damage 0, no KO, no stun or poise meter. An ordinary
  minion is floored and pushed out of the blast. One that does not flinch only stands
  it, and one guarding from the front holds. The hero in the same footprint still takes
  the full blow.
- `CombatEvent.friendly` marks such a hit, so no damage number, shake or debris is shown
  and it does not count as a hit in the session's stats.
- Tests: `test_boss_crew_hits.gd`.

### Changed: a shopping cart at the shops (owner's request, 2026-11-16)
- **Buying and selling many items at once is a cart now.** A click on a ware (or on an
  item from the bag, on Sell) puts it in a cart beside the list. Shift+click or a right
  click adds a stack. Each cart line has -, + and ×, and the cart shows the total and the
  coins after. One Buy or Sell settles it all. The old one-item deal bar and the "tick
  to sell" boxes are gone.
- **New rule class `TradeCart` (`client/sim/`).** It checks the cart against every
  `ShopRules` limit, including one deal's 99 (larger stacks are settled in several
  deals), gear bought one at a time, and the shop's wares and opening. The checkout is
  all or nothing: if anything fails, the coins and the bag are put back. A cart holds at
  most 20 different items, a size limit the server can apply to the same request.
- Sell's "Add all" fills the cart with everything the shop takes, except rare gear and
  upgraded items. Those go in one by one, and the cart asks "Sure?" before selling them.
- The screen refreshes in place instead of being rebuilt on every click, so the focus
  and the list's place are kept. Keys: Enter adds one, Left/Right change the count, X
  settles the cart, Q/E switch tabs.
- `Game._buy`/`_sell` are gone; the shop screen settles through `TradeCart`.
- Tests: `test_trade_cart.gd` (the rules) and `test_trade_ui.gd` (clicks, keys, checkout,
  Add all, Sure?, and everything on screen at 640x360).

### Changed: auto battle in the arena, and the player keeps control (owner's request, 2026-11-16)
- **The AUTO switch works during an arena match.** It used to refuse with "The arena is
  fought by hand." Auto now plays the match with the same buttons a player has. There is
  no food in the arena, and `ArenaMatch` still blanks all input during the countdown.
- In a match, auto goes after the rival at any distance instead of waiting for them to
  come within reach. It never follows the story or goes home to rest from the arena, and
  it turns off when the match ends ("Match over. Auto off."), leaving the result screen
  to the player.
- Tests: `test_arena.gd` covers an auto-piloted match fought to a knock-out, and the HUD
  switch turning on in a match and off at its result.
- **The player keeps control while auto is on (owner's request).** Walking, attacks,
  skills, guard, dodge and grabs are played as pressed, and auto stays on. The pilot waits
  half a second (`AutoBattle.MANUAL_HOLD_TICKS`, 30 ticks) after the player's last input
  before it plays again, so a step or a combo is not undone on the next tick. Auto still
  eats when hurt meanwhile.
- **Walking into another area no longer turns auto off.** Auto farms the new area from
  then on. It stops only where it cannot run, and says why (`AutoRules.problem`).
- Tests: `test_auto_battle.gd` covers every kind of the player's input with auto staying
  on, the pilot's pause after it, and auto following the hero into a new area.

### Changed: five distinct combat classes, a stronger combo engine, fair PvP (owner's request, 2026-11-13)
- **Each class has its own heavy attack** instead of the shared `haymaker`:
  - Boxer Overhand (breaks guard, chains into a Shovel Hook);
  - Brawler Hammer Fist (slow, breaks guard, floors, armoured);
  - Grappler Collar Tie (short, long hitstun to set up a grab);
  - Counter Fighter Check Hook (steps back while hooking, cannot be hit until its blow
    is through);
  - Street Striker Spinning Backfist (hits both sides).

  Every light chain ends in the class heavy.
- **Own light and heavy animations per class.** The hero recipes' `animation_overrides`
  compose each class's light and heavy swing from different LPC frames (the Boxer keeps
  the base clips). There are also 13 class clips (overhand, weave, hammer, clinch,
  check, whirl, spin, dash and five ultimates), plus Ground Pound (fists raised, a
  crouching punch into the ground), Brawler Whirl (Backhand Smash and Street Carnage turn
  all the way round), Oren's Ground Slam (a crouching slam) and a leaping slam for Street
  Carnage's finish. Every class move that reaches behind plays a clip that turns, slams
  or dashes through (tested, and checked on screen). `lpc_build.py` can take frames from the
  back and front views. The asset test now accepts any LPC blow struck by the near arm
  (half-slash, one-hand back-slash, thrust).
- **Area attacks for every class** that really hit several foes, tested against two foes
  each: Boxer Knockout Combo, Brawler Ground Pound / Wide Swing / Backhand Smash,
  Grappler Ground Slam, Counter Fighter Reversal Strike, Street Striker Dash Strike.
- **Mechanics that give each class its identity** (data fields, validated):
  - `armor`: the Brawler's committed heavies and Street Carnage cannot be interrupted
    by monsters. In PvP the armour takes one hero blow per swing; a guard breaker
    always breaks it. An armoured swing cannot be grabbed while it lands.
  - `otg`: Ground Pound, Ground Slam's wave and Chain Breaker also hit a foe lying on
    the ground, for damage only.
  - `catch_all`: the Counter Fighter's Perfect Parry catches guard breakers too, from
    heroes and ordinary monsters; a boss's guard breakers stay unanswerable by any stance,
    as before.
  - `energy_drain`: the Boxer's Body Blow takes 35 energy.
  - The Boxer's Slip Counter slips under a blow (untouchable) and answers. Heavy
    Cross, Body Blow and Uppercut step in.
  - Passives:
    - Boxer Combination Puncher: each landed route link takes 0.75 s off the other
      cooldowns.
    - Brawler Crushing Momentum: each landed blow adds 4% damage and 15% guard drain,
      up to five.
    - Street Striker Slipstream: cheaper dodges, and a landed blow can be cancelled
      into a dodge.
  - Ultimates redesigned: Absolute Retribution (two pivoting area bursts, then the
    blow), Million Fist Onslaught (dash through, a flurry, a spinning blow all
    around).
- **The Pit Arena is a session type of its own** (`SessionRules.ARENA_MATCH`): private
  like a story instance, one hero against an AI rival, key `arena/<hero>/<area>`
  (needed alongside the session types of D9).
- **Combo engine:**
  - a route link may be the class's own light or heavy punch (a third route per class
    opens on one);
  - skill → basic follow-ups (`chains` on a skill's last move);
  - the auto battle and the arena AI press route punches and use Slip Counter as an
    answer;
  - against a boss (never grabbable: bosses never are) the auto battle opens and waits
    for no combo route with a grab skill in it; on a grabbable foe its grab routes are as
    before;
  - a skill is held back for a route its punch opens only by the auto battle, and only
    a grab (the arena AI holds none: measured, holding them gave the Street Striker
    58%).
- **PvP-only rules** (hero on hero; PvE untouched):
  - combo scaling after the 3rd blow on a reeling hero, down to 50%;
  - a thrown hero is down 60 ticks and cannot be grabbed again for 1.5 s;
  - defense takes a share of each blow (defense / (defense + 90)) instead of a flat
    amount. Flat defense wiped out light punches and many-blow skills between geared
    heroes, which made fights a race of the biggest single hits;
  - the Boxer's step-in skills step less far in PvE (skill profile `advance`, a new
    profile field).
- **`SkillRegistry`**, run on every content load, rejects:
  - class moves shared or copied between classes;
  - identical skill sequences;
  - an ultimate without an animation of its own, or two ultimates sharing one.
- **Balance, measured** (mixed bots, 200 matches per pair):
  - classes 47–52%, every pair 42–58%; before the rebuild 19–80%;
  - PvE kills (auto battle, 27 minutes per hero), before → after: Riku 284 → 284,
    Mika 237 → 253, Kan 239 → 227, Oren 221 → 212, Dao 201 → 196 (Kan, Dao: their
    own heavy ends the light chain instead of the shared Haymaker; Oren: the auto battle
    keeps Power Throw for its route, which survives the hardest ground);
  - Grappler PvE ×1.3 is kept.

  Design, matrices and analysis: `docs/COMBAT_SYSTEM.md` and
  `docs/COMBAT_REBUILD_REPORT.md`.

### Changed: Grappler PvE damage ×1.3 (owner's approval, 2026-11-13)
- The Grappler's six active skills deal ×1.3 damage in PvE (`profiles.pve.damage`); PvP
  is unchanged. Oren: 185 → 221 kills in the standard 27-minute auto-battle measure,
  inside the other jobs' range (201–284). Side effect for the owner: his Ultimate is now
  1.67× his strongest skill in PvE, under the 2–3× design target (Ultimate ×1.2 would
  restore 2.0×; not applied).
- **PvP measured with mixed bots** (`ArenaBalance.gd --only=jobs_mixed`: AI skill and
  personality drawn per match, time spent down or held, share of damage from throws).
  Grappler 80%, Counter 69%, Boxer 49%, Striker 32%, Brawler 19% average win rate. Six
  candidate fixes measured, none applied: no single change balances PvP. Findings and the
  proposed PvP design pass: `docs/SKILL_FLOW_REPORT.md` §4–5 (also Dao PvE ×1.15
  measured, awaiting approval).

### Changed: grab skills used normally, counter replies that land, combos that flow (owner's request, 2026-11-13)
- **Auto battle uses grab skills like any other skill** (owner's rule, replacing "only
  when it pays, one every 5 s"): a ready grab skill is used when it is the best choice.
  The game's own rules still apply: no hold on a boss or mini-boss (a shove), no grab
  with a weapon in hand. Auto no longer stands over a foe it has just thrown while
  another foe can be hit (only foes it threw itself, so ordinary knock-downs are kept,
  and other jobs are unchanged), and it does not start a hold below half health with
  another foe within 100 px (a hold pins the hero; the level 50 ground's hunt survives
  11 of 12 seeds, 10 before). Measured, auto battle 3 minutes × 3 seeds on the level 9,
  29 and 50 grounds: Oren 138 → 185 kills, damage taken 13,461 → 10,206, completed
  combos 108 → 157. The other jobs: Riku 284, Kan 239, Mika 237, Dao 201
  (`docs/SKILL_FLOW_REPORT.md`).
- **Counter replies reach what they catch:** a caught attacker reels 14 px back, and the
  replies (reach 38) missed 41% of caught blows, which also broke Perfect Retort (it
  could never be completed). The first move of every counter reply now steps in 24 px
  (`advance`, `moves.json`: Counter Punch, Quick Counter, Perfect Parry, Reversal Strike,
  Absolute Retribution). Measured: replies land on 100% of caught blows (was 59%).
  Perfect Retort is completed against 12 of 20 attackers (the rest attack only with
  guard breaks or grabs, which stances cannot catch).
- **Auto battle goes on into the longer combo route** when its remaining skills are
  ready (+50% per further link), instead of always taking the shorter route that shares
  the same opener. It keeps a route's later skill for the route (×0.4) while the route's
  opener will be ready within 1 s. Completed combos: Kan 63 → 121, Mika 71 → 132, Riku
  94 → 105. Holding harder was measured worse and not kept.
- Tests: `test_skill_flow.gd` (each fails on the old behaviour).

### Changed: the arena's rivals are configured by data, play with human timing, and results are applied once (owner's request, 2026-11-13)
- **Rival equipment is fully configurable in `client/data/arena.json` v2**
  (`ArenaLoadout`): per slot item, grade, upgrade (+0 to the game's +10), weights or
  empty; reusable presets (balanced, heavy, fast, critical, defensive, custom,
  `sovereign_full`); nine tiers on the real items (Common, Common/Uncommon, Rare, Epic,
  top grade +0, then Godforged +1/+2, +3/+4, +5/+6, +7); rank overrides and per-opponent
  overrides. Precedence: opponent > rank > tier > preset > defaults, and a per-slot
  setting beats a ladder-wide one. Everything is validated on load (unknown or misplaced
  items, levels, grades, upgrades, typos). A rival with an error is never offered and
  never patched with another item. `config_version` is recorded with each result, and a
  running match keeps its rival when the configuration changes.
- **Real data findings:** no Common charm exists below level 53, so tier 1 wears none
  (the old code left the slot empty silently). Legendary has no body or feet, so a full
  Legendary set is reported as an error.
- **Personalities** (balanced, aggressive, defensive, counter, combo, tactical) set
  approach, attack rate, defense, combo and grab preference, counter stances, spacing,
  whiff punishing and low-health behaviour.
- **Human timing:** a rival sees a blow only 400 ms (beginner) to 200 ms (best) after it
  starts, decides every 100 to 50 ms and mashes at most 12 presses a second (it decided
  every tick and reacted at once before). It may raise its guard in anticipation from
  what is visible (at most 10% of decisions: at 20% the best AI over-defended and lost
  to beginners).
- **Five spread rivals:** the nearest, then the rivals closest to an easy, even, hard
  and much harder difficulty in a window above you that grows with your rank, each
  labelled Easy, Even, Hard or Very Hard from real power and AI. **New rivals** is free.
- **Details and challenge:** Fight opens the rival's gear by slot with grade and upgrade,
  style, AI level and reaction time, and power against yours. Challenge starts the match.
  The ladder adds draws, win rate and the champion. The result adds draws, the duration,
  the health left at time and Rematch.
- **Results applied once:** every match has an id, and a result is applied only once.
  Phases run forward only. Closing the game during a fight counts as one forfeit loss on
  the next start (the countdown is free). At time, health shares within 2 points are a
  draw (no rank change, no reward, recorded). A damaged ladder is repaired keeping the
  player's rank. Champion title defenses and streak are counted. Health and the ultimate
  gauge are restored after a match.
- **Balance harness** `tests/harness/ArenaSim.gd` / `ArenaBalance.gd` and report
  `docs/ARENA_BALANCE.md` (200 matches per comparison).

### Fixed: arena rivals fought without their skills
- The arena marks its rival as the zone's boss (for the HUD bar), and the boss-skill
  system replaced the rival's job skills with an empty boss table. Rivals only punched.
  `BossSkills` now leaves an arena rival's skills alone. With working skills, tier 1 moved
  from levels 6–12 to 3–10 to keep a gentle start (a level-10 stand-in won 10 of 10
  against #50).

### Added: The Pit Arena, a 50-rival PvP ladder against AI heroes (owner's request, 2026-11-13)
- **Khru Sombat in Iron City Central** (from level 10) opens the **Arena Ladder**: your
  rank, best rank, combat power and record, and the five rivals ranked just above you,
  each with rank, ring name, job, level, gear and power coloured against yours. Pick
  any. A win over a rival above you swaps your ranks; a loss changes nothing. A new
  challenger starts at #51; the champion defends against the rivals below.
- **Rivals are player heroes played by the computer** (`ArenaBrain`: same inputs as a
  player, combos, stances, dodges, grabs, ultimates; deterministic). Strength rises
  with rank (`data/arena.json`): plain common gear at the bottom, the best gear
  unupgraded by #21, then the best gear at +1 to +7 mixed by slot up to #1, with level
  and AI skill rising alongside. All five jobs in every five ranks.
- **Matches** (`ArenaMatch`): 3 s countdown, 90 s clock, PvP skill profile and health
  x2 for both sides, no food, no auto battle, no leaving mid-match; knock-out or the
  larger health share at time. Result screen, then straight back to the ladder.
- **Best-rank rewards** paid once: 500 / 1,500 / 4,000 / 10,000 / 20,000 / 50,000 coins at
  #40 / #30 / #20 / #10 / #5 / #1. Values, health x2 and names await owner approval.
- **Design and numbers:** `docs/ARENA_DESIGN.md`. Art prompts for the arena's own scene
  pieces: `docs/SCENE_PROMPTS.md` §6 (it uses the Fight Club pieces until then).
- The PvP harness now uses the arena's `ArenaBrain` as its bot (`DuelBot.gd` removed).
  `ZoneSim`'s attack tokens moved to `AttackTokens.gd`, and world-boss flow to
  `WorldBossFlow.gd`, to keep both files under the size limit.

### Fixed: a chapter card or match banner no longer reads "LEVEL UP!"
- The HUD's chapter card reused the level-up banner and kept its "LEVEL UP!" heading.
  It now shows its own title.

### Fixed: PvP balance now reaches a grab skill's throw; Added: 1 against 1 measurement
- **A grab skill's throw lands after the skill is over, so no balance profile reached
  it:** in PvP, Backbreaker's throw hit at full strength (153 instead of 92 at level 50)
  and took over half a health bar. The skill's scale is now kept for its throw and the
  body's crashes (`Fighter.throw_scale`). PvE is unchanged (every PvE profile is 1.0).
- **PvP 1 against 1 harness** (`tests/harness/DuelSim.gd`, `DuelCheck.gd`; the bot is the arena's `ArenaBrain`):
  every pairing of the five heroes, PvP profiles, the same bot for every job. Baseline,
  win rates and limits in `docs/GRAPPLER_AND_PVP_REPORT.md`.
- **PvP safety rails tested** (`test_duel.gd`): nobody helpless over 3 s, no blow over
  70% of a health bar, duels of 8 s or more on average, a held player struggles free.
- **Grappler measured and compensation proposed, not applied:** he kills 39% slower than
  the others because his six skills are grabs that auto battle paces to one per 5 s,
  and thrown foes cannot be hit for 1.5 s. Options and numbers in the report.

### Added: skill combos for every job (owner's request, 2026-11-12)
- **Two combo routes per job** (`client/data/jobs.json` `skill_combos`, `ComboRules`): one
  of two skills from level 3, one of three from level 30. Use a route's skills in order,
  each within 2 s of the last landing (3 s for the Grappler, whose thrown foes stay down
  longer): the last skill hits harder and the ultimate gauge gains 8 or 15. A miss, a
  stance nobody hits, a pause or a blow taken breaks the chain. Routes: One-Two and
  Knockout Sequence (Boxer), Hammer Time and Street Riot (Brawler), Lift and Drop and
  Wrecking Crew (Grappler), Slip and Punish and Perfect Retort (Counter Fighter), Flurry
  and Chain Reaction (Street Striker).
- **Balanced by the whole route's damage** (with each hero's power): 77 to 80 for the
  first routes, 123 to 140 for the second; the bonus on the last skill differs per job
  (30% to 100%) to get there. PvP profiles halve the bonus.
- **Shown to the player:** the next skill of a route pulses gold on the hotbar; a hit
  counter ("12 HITS") and the route's name when completed appear at the right; the Skills
  screen lists the routes; the level-up banner names a new route.
- **Auto battle** follows routes (the next skill weighs three times as much, a route's
  opener 1.3 times) and may grab to open or continue one.
- Measured with auto battle (4 farming grounds, 4 seeds, against main before): kills per
  hour +4% to +12% for every hero, damage taken lower for four of five.
- Design, architecture and measurements: `docs/SKILL_COMBO_DESIGN.md`.

### Added: the world's area types, story boss replays, the lairs' shared mini-boss and world boss elite reinforcements (owner's rules, 2026-11-13)
- **Area types** (`SessionRules`, new): Story Instance (the street: one hero, private
  state, no caps or waits), Farming Ground, Rematch (lair), World Boss and Hub. Instance
  keys and `may_join` (a story instance admits only its owner) for the zone allocator
  (M3/IL-7). `SessionRules.problems` refuses a boss of any kind in a farming ground.
- **Story boss and story mini-boss replays** (`ReplayRules`, new; `Rematch` UI helper):
  the 11 story bosses (6 stage bosses, 5 story mini-bosses by `MapRules.kind_of`; elites
  are not mini-bosses) can be fought again without limit once their area is reached. Each
  replay is a fresh fight straight to the boss; quests, evidence, areas reached and gates
  are untouched. Entry: Win's taxi **Boss Fights** (usual fare only), the game menu
  **Fight ... again** (free), the knock-out screen **Try again** (free, no coins dropped).
- **Reward integrity:** `LootRules.eligible` leaves out a once-only drop (evidence, a
  unique item) the hero already owns, alone; the rest of the table still drops. Each drop
  is still rolled, so seeds give the same rolls. First-clear rewards stay quest rewards.
- **Lairs (the truck's Rematches)** (`LairRules`, rewritten): one shared mini-boss for
  all ten blocks with an explicit lifecycle (waiting, active, respawn wait) and an
  encounter number. It turns up in a random block (all ten eligible) at a random spot
  clear of the block's ends (200 px, `mini_boss_spawn_margin`) and of the hero (was:
  always the block's centre), the moment it is due, even into the block a hero is already
  in (`LairRules.watch` after every zone tick, twice a second); a hero in another block is
  told where it is. It stays until beaten. Its health and place are recorded twice a
  second and on walking off, and written by the game's usual saves (every 20 s, leaving
  the tab or closing, quitting to the title, at once on a defeat), so a reload finds it as
  wounded. Its defeat is resolved once with one respawn wait (default 1800 s, confirmed by the
  owner; per lair with `mini_boss_respawn_seconds`). A lair must be exactly ten blocks.
  The field truck shows where it is out and its HP (once known), or when it is back.
  **Save version 13** (v12's due times carry over). This is local single-player
  persistence; the shared server-side record is IL-7.
- **World boss reinforcements** (`BossMechanics`, `WorldBossRun`): a new optional
  `elite_summon` next to the existing `summon` (unchanged). It names an existing elite
  (`elite: true`), which arrives as itself (its own stats, moves, AI, loot), on its own
  timer and cap, from an optional `below` health share; with both, each cap counts only
  its own kind. Missing, empty or malformed data calls no elites (`elite_spec`) and is
  reported by the validator. **Not active:** no world boss sets it (owner's decision).
  In world boss arenas only, a reinforcement never arrives within 60 px of the hero
  (`SUMMON_CLEARANCE`); every other caller keeps its original edges. When the boss
  falls or escapes its remaining minions leave once (`despawn`). When a world boss calls
  in an existing elite (through either field), the HUD says "An elite <name> joins the
  battle!" once per call (`boss_summon` carries `elite`; `GameFeedback`); normal minions
  and non-world-boss summons are not announced this way.
- Docs: ARCHITECTURE D9, BLUEPRINT D17–D20, PERFORMANCE capacity table,
  WORLD_BOSS_DESIGN §3b.
- Tests: `test_session_rules`, `test_story_replay`, `test_rematch_spawns`,
  `test_world_boss_reinforcements`, `test_minion_entry` (new); `test_taxi` expects the Boss Fights group;
  `test_lairs` expects the ten-block rule.

### Fixed: boss hazard marks left painted on the street (owner's report, 2026-11-12)
- **Cause:** when a boss fell, the hero went down or a world boss left, its waiting
  hazards were cleared in the sim without an event, so their warnings were never told to
  land: they stayed on the ground, locked and glowing, for the rest of the area, and kept
  redrawing every frame (part of the frame-rate drop in long boss fights). Warnings were
  also matched to hits by order, so staggered waves could land on the wrong mark.
- **Fix:** every hazard has an `id` (`BossMechanics`), carried on `hazard_warn`,
  `hazard_hit` and the new `hazard_cancel` (`BossSkills._stop` reports each hazard it
  clears). `GameFeedback` matches warnings by id; a called-off warning fades in 0.18 s
  with no impact (`HazardView.dismiss`); a landed mark holds 0.2 s and fades in 0.3 s
  (was 0.35 + 0.5 s). Safety net: a warning still up well past its time clears itself
  (`HazardView.overdue`). Hits and damage are unchanged (decided in the sim only).
- Tests: every boss's hazards each land or are called off exactly once; a fallen boss
  calls off each waiting hazard by id; marks never outlive their hazard (scene test).
- `HazardShapes`: the warning outline geometry moved out of `HazardView` (line limit);
  the unused `_on_rim` was removed.

### Docs: the lair mini-bosses stay hard (owner's decision D16, 2026-11-12)
- `docs/BLUEPRINT.md` D16: the lairs' mini-bosses are not made easier. Measured against
  all five heroes at the lair's level in shop gear with food, they win 0 to 6 fights in
  10; that is intended: players buy potions, find better gear and upgrade it first.

### Changed: one standard throw, damage on landing; the Grappler's auto battle and damage
Owner's requests (2026-11-11).
- **One throw:** the shoulder toss for every grab and grab skill; the body slam and
  piledriver poses are gone (`GrabRules.POSES`, the `"pose"` fields, `Fighter.hop`).
- **The throw hurts when the body lands.** Tossed, it tumbles down (it cannot be hit)
  and takes no damage in the air; when it hits the street the throw's blow lands
  (`GrabRules._slam`): the damage, a KO, the hit spark and number, with the thud, dust
  and shake. It hits face down with a little bounce, then rolls into the usual
  knocked-down pose for the rest of its 1.5 s and gets up as from any knockdown. A
  skill's follow-up (Ground Slam's wave) now lands while the body is still in the air.
- **Grappler on auto battle:** a grab skill on a foe that can be held only when it pays
  (`AutoPilot._grab_pays`): another foe where the body lands, or a tough foe (an elite,
  or one with poise) above half health, and at most one every 5 s. On a boss or
  mini-boss a grab skill is a quick shove and is used as before. Auto never pushes off
  either end of the street unless it means to walk on east (blocks and exits).
- **Grappler compensation**, measured (3 minutes of auto battle on the level 9, 29 and
  50 grounds, 3 seeds; before = the release before the throw changes): basic combo
  damage x1.5 (`grappler_short` 9, `grappler_heavy` 12, `grappler_push` 18); Power
  Throw and Crowd Toss throws and crashes x1.3, Ground Slam's x1.2. Backbreaker, Crushing
  Hold and Titan Destruction keep theirs, so the balance rules still hold (his ultimate
  2 to 3 times his strongest skill, none out-hits the Boxer's, every boss skill at
  least the median hero skill). Oren: kills 261 -> 218, XP 66.9k -> 54.7k, knock-outs
  1 -> 0 of 9, damage taken 15.0 -> 14.2 times his health. Pacing the grabs with no
  compensation: 179 kills; a grab every 3 s measured worse, and higher throw damage
  broke those rules.
- **Footsteps are 11 dB quieter** (hero -24 dB, monsters -29 dB).
- **Auto battle hunts a lair after the story** too (it said there was no one to fight):
  it may run wherever there is a living field.
- **Block signs:** the signs at each end of a block name the next and the previous
  block ("Block 3/10 >", "< Block 1/10"), or the area the end leads to.

### Changed: ten blocks per farming ground and lair; roaming lair mini-bosses; ranks; footsteps
Owner's requests (2026-11-11).
- **Ten blocks per farming ground** (`BlockRules`, areas.json `"blocks": 10`): each ground
  is ten blocks of the same street, level, monsters and camps, walked through east and
  west (1 to 10 and back). The first block's west edge and the last block's east edge
  are the ground's own exits; arriving from the east puts the hero in the last block.
  The arrival toast names the block ("Block 3/10"); street weapons stay in their block.
- **Lairs are ten blocks of field with a roaming mini-boss** (`LairRules`): each lair is
  a living field at its level (the pool of the ground beside it), with no arena. Its
  boss (areas.json `"mini_boss"`) turns up in one block at random, with no warning, and
  comes back 30 minutes (`PERIOD_SECONDS`) after it falls, in another block. The wait is
  kept per character (save field `lairs`, unix seconds). It keeps its skills, hazards,
  summons and fight timer. The map, the drop sources and the boss-skill tier read it.
- **Elite, mini-boss and boss are separate** ranks: a named elite (`"elite"` in
  enemies.json, e.g. the Smog Warden) shows the elite star (gold), not the mini-boss
  horns, and **can be grabbed and thrown** like any monster (it still has poise, so it
  is held for half as long). Bosses and mini-boss keep their own marks and can never be
  held.
- **Stronger mid-story mini-bosses**, measured (each against all five heroes at its
  area level in shop gear with food, 2 seeds): Security Chief, The Ringmaster and
  Subject 12 max HP x1.6 (Subject 12 x1.4) and power x1.25 (their enraged phase too);
  Pit Champion max HP x1.3. Before / after: Security Chief 26 s, 0.7x max HP taken ->
  49 s, 1.9x; Ringmaster 31 s, 0.7x -> 53 s, 1.5x; Subject 12 36 s, 0.6x -> 54 s, 1.3x;
  Pit Champion 31 s, 1.4x -> 44 s, 1.8x; all still won 10 of 10. The Sludge Foreman
  (43 s, 2.4x) and the lairs' mini-bosses (already 0 to 6 wins in 10 in shop gear) are
  unchanged.
- **Footsteps** are recorded steps on stone (CC0, Fantozzi's Footsteps on OpenGameArt;
  `art/sounds/sounds.json`, `step_l1`..`step_r3`), left and right, a different take each
  time, played on the walk animation's foot-contact frames (`FighterView.footfall`).
  They were synthesised thumps every 24 px, about twice the pace of the feet.
- Balance of the combat changes since the last release (the step before a throw, 3 to
  4 body throws, 1.5 s on the street), measured with auto battle: five heroes, three
  minutes on the level 9, 29 and 50 grounds, 3 seeds each, before and after. Riku, Kan,
  Dao and Mika: identical (auto battle never throws for them). Oren (Grappler): kills
  261 -> 234 (-10%), XP -8%, knock-outs 1 -> 0 of 9, damage taken the same.

### Fixed: auto battle at home; Changed: slammed foes stay down longer; three throw poses
Owner's requests (2026-11-11).
- **Auto battle no longer bounces between Depot Yard and the city.** A hurt hero with no
  food in Depot Yard was sent to rest in the city and, without coins for the taxi back,
  left there with auto off; from the city, auto took the taxi to Depot Yard. Now an area
  that heals on entry is its own rest (`AreaRules.rest_home`), a place one walk away is
  never paid for (`AutoRules.ride_fare`, `AreaRules.next_door`), and the story walks
  from the city into Depot Yard through its east exit instead of riding (`StoryAuto`).
  The harness uses the same fare.
- **A slammed foe lies on the street for 1.5 s** (`GrabRules.SLAM_DOWN_TICKS` 90, was
  the 50-tick knockdown) before getting up. A knockdown may now carry its own length
  (`Fighter.state_duration`); every other knockdown is unchanged.
- **Throws land 3 to 4 bodies ahead** (`MAX_THROW_BODIES` 4; was 2 to 3): Boxer and
  Street Fighter 3, Counter Fighter and Brawler 3.5, Grappler 4 (throw knockback 40,
  49, 58; Power Throw and Crowd Toss 58, Crushing Hold 40).
- **Three throw poses** (`GrabRules.POSES`, a `"pose"` on each job's and grab skill's
  grab, validated on load), drawn from the existing frames by `FighterView.POSES`. The
  bodies stay side-on, facing each other, never turned to the camera:
  - *shoulder toss* (`overhead`, every job's grab; Power Throw, Crowd Toss), to the
    owner's drawing: face to face with the hands at the waist (the grab frames),
    lifted across the shoulders head to the back (lift), **one step forward**
    (`GrabRules.STEP_LENGTH` over `STEP_TICKS`; no throw before the step is taken,
    a throw pressed sooner waits for it), tossed forward (throw) flat as it was
    carried, landing face down with its head towards the thrower, lying there
    1.5 s, then getting up. Every hold now lasts at least `READY_TICKS` + 1. The
    thrower's release (17 ticks, unchanged) holds the one-handed toss frame for the
    first half of the flight, then LPC's thrust frame 5 (borrowed whole into the
    throw row of every LPC character, `art/lpc/characters.json`; no edited frames);
  - *body slam* (Backbreaker, Crushing Hold): lifted to the chest, slammed down
    ahead;
  - *piledriver* (the Grappler's Ground Slam and Titan Destruction): hung upside down
    against the thrower's chest; the thrower jumps (`Fighter.hop`) and drives it head
    first into the street where it stands (at most half a body of travel).

### Added: every boss and mini-boss has skills of its own
- **110 boss skills** for all 24 bosses: 10 mini-bosses (3-4 each), 6 stage bosses (4-5)
  and 8 world bosses (5-7). Each has a unique id (`MB_`, `SB_` or `WB_`, the owner, a
  number) and its own moves, in `client/data/boss_skills.json`. The catalogue is separate
  from the heroes' `skills.json`, and the data is generated by
  `tools/content/boss_skills.py`.
- **Kinds of skill:** strikes, wide sweeps, combos of two or three blows, charges, leaps,
  grabs (which break guard), and casts that call a hazard (a burst, a row, a volley, a
  chain or a quake) or helpers. Later bands open more demanding kinds; some skills only
  come in a boss's later phases.
- **Rules:** `BossSkillRules` validates on load:
  - unique ids and a single owner per skill;
  - no hero skill id and no move shared with anything else;
  - real effects and sounds;
  - fairness floors: 18-tick wind-ups for heavy blows and 40-tick ground warnings.
- **Runtime:**
  - `BossSkills` (run by `BossMechanics`) plays combos and lands casts.
  - When a boss falls, the hero falls, or a world boss escapes at the bell, its skills
    and every waiting hazard are cleared.
  - `EnemyBrain` picks skills: off cooldown, in phase, rarely the same twice, closing in
    to each skill's range.
  - A boss casts only within 260 px of the hero, so it chases a hero who runs rather
    than calling skills from afar.
  - A boss's plain charge now starts from beyond its reach, so the charge can be seen.
- **Balance:**
  - A skill's damage is a share of the boss's heavy blow, and never below 1.1 times the
    heroes' median skill.
  - At the boss's level, no skill takes more than 45% of a shop-geared hero's health.
- **Effects:** a boss skill gathers its theme's glow through the wind-up. Its effect lands
  on the middle of its hitbox, sized to the hitbox.
- **Ultimates:** every boss and mini-boss also has an Ultimate (24, ids `..._ULT_001`).
  - One cast in the boss's `swing` pose (`stab` for the Sludge Foreman), announced by an
    "ULTIMATE" banner, a burst, a screen shake and a roar.
  - Then one to four waves of hazards over a wide area. Each wave is marked on the ground
    when it is next and warned for 98-110 ticks.
  - Each hit is 2-3 times the boss's basic blow; a fighter is hit at most once per wave.
  - Waves cover the street's whole depth and always leave a reachable safe spot.
  - Later bands add more waves, moving safe gaps and patterns that follow the hero.
  - The boss channels: it stands still and strikes nothing, and its own hazards and helpers
    wait until the last wave lands.
  - Cooldown 1500 ticks; first use no sooner than 540 ticks into the fight.
  - Hazards already on the ground at the cast land first; the first wave waits for them.
  - The waves are 48 ticks apart. A reacting hero escapes every Ultimate from 9 start
    positions with at least 14 ticks to spare (test).
  - An Ultimate of two or more waves totals at least 1.8 times its boss's strongest
    regular skill. Security Chief's Lockdown (a closing cage) and Spillway Chief's
    Floodgate Burst were reshaped to meet this, and Big Sak and Commander Arthit gained a
    third wave.
- **Fair on reaction:** every damaging regular boss skill can be avoided by a hero who
  reacts after 0.25 s (`test_boss_fairness`).
  - Charges and leaps wind up for at least 24 ticks.
  - A charge is active for 12 ticks.
  - Combo openers wind up for at least 18 ticks.
  - Combo light hits stun for 6 ticks.

  Damage is unchanged; the validator enforces these timings.
- **Evidence so far** (`docs/BOSS_SKILL_QUALITY_AUDIT.md`, `docs/BOSS_PLAYTEST_PLAN.md`):
  - **Automated tests:** pass.
  - **Scripted simulation:** `tests/harness/BossPlaytestScenarios.gd`.
    - A scripted hero escapes every Ultimate:
      - at 30, 60 and 120 FPS;
      - by walking at normal speed;
      - with a timed roll, also when slow or 200 ms behind.
    - The hero falling, the boss falling or a world boss escaping mid-Ultimate leaves
      nothing to land.
  - **Browser smoke test:** passes on the pinned Node and Chromium, but does not fight a
    boss.
  - **Human playtesting and multiplayer validation:** not done yet.
  - **Founder's Engine's Ultimate lowered (owner-approved):** waves 50 → 46 per hit.
    - Why: in its last phase under the round's enrage, one wave took 51-53% of a hero in
      level gear; now at most 49%.
    - Its total is still 184 (3.02 times its strongest skill).
    - Scope: only `WB_FOUNDERS_ENGINE_ULT_001`'s four wave damages changed.
- **Fits the five jobs.** The boss catalogue stays its own, beside the jobs' skills.
  - Boss data is unchanged.
  - The validator now knows every hero move (passives, later blows, grab moves, job
    movesets).
  - The generator measures the jobs' active skills, and keeps the approved balance
    baseline until the owner decides otherwise.
  - New read-only harness `BossJobMatrix.gd`: each job's hero against every boss under
    auto battle.
- **Owner-approved tuning for the five jobs:**
  - Four boss skills up one point to the jobs' median skill: Harbourmaster Chen 002 and
    Security Chief 001 (combo finisher 19 → 20), Iron Colossus 004 and Slag Titan 003
    (hazard 29 → 30).
  - The slowest job, the Grappler, can walk out of every Ultimate:
    - Subject Zero and Founder's Engine warn each wave 10 ticks longer;
    - Floodgate Marshal's waves come 8 ticks further apart.
  - No other boss value changed.
- **Quake warnings show their true area:** a sharp-edged red band, easy to see on the
  orange-lit streets. Presentation only; the hit area, damage and timing are unchanged.
- **Hazard warnings by importance** (`data/boss_fx.json` "telegraph", owner-approved art):
  - Ultimates warn in full; other skills' hazards and boss cycles warn minimally. A
    level can be set per skill (`"skills"`); `BossFxRules` names any bad value, unknown
    key or skill, and refuses `none` for a skill that drops a hazard.
  - The warning is a seam in the street at the hit area's true edge, coloured by what
    the ground does (steam, rain, sludge, quake, shock, crane) and the boss's theme.
    Large steam vents and wide slag rain have their own look.
  - Warnings lie on the street under the fighters; what is in the air (a falling
    container or drop) is drawn above them. A warning follows the zone's own tick count,
    so it ends on the exact tick its hit lands.
  - Performance: fills use a simple rounded shape, and a large warning's unchanging parts
    are recorded once (`HazardLayers`), so a frame only sets their colour. They render
    identically and are freed with the warning.
  - Presentation only: hit areas, damage, warning durations and the simulation are
    unchanged.

### Changed: grabs need empty hands; throws are short, heavy slams; KO wakes you in the city
Owner's requests (2026-11-11).
- **No grabbing with a weapon in hand.** The grab button with a weapon drops it at the
  hero's feet instead (`GrabRules.lets_go`, one press, one meaning); the next press grabs.
  The pick button already never grabbed while armed. Grab skills (the Grappler's) also
  wait for empty hands (`GrabRules.barred`): the hotbar says why, and auto battle skips
  them while armed. The tutorial's grab step says so.
- **A person is heavy: throws land 2 to 3 bodies away**, not across the street. One
  space is a person's width (18 px, `GrabRules.BODY`); every throw, the jobs' and the
  grab skills', lands at most 3 spaces from the thrower (`MAX_THROW_BODIES`), checked on
  load and capped in play so knockback bonuses cannot fling a body further. New throw
  knockback: Boxer and Street Fighter 22 (2 spaces), Brawler, Counter and Crushing Hold
  31 (2.5), Grappler, Power Throw and Crowd Toss 40 (3); before: 40 to 220.
- **Every throw is a slam.** The Boxer's and Street Fighter's throws now floor the foe
  like the others. A thrown body flies for `AIR_TICKS` (16) at an even pace, from over
  the thrower's head down onto the street, falling ever faster, then hits the ground
  once (`Fighter.landed`, zone event `slam`): a new deep `body_slam` thud, the ground
  shakes, dust bursts both ways and the body freezes for a beat. It knocks down foes it
  passes on the way, and anyone within a body and a half of where it lands
  (`LAND_HALF`), so a throw still clears space without flinging bodies across the
  street.
- **Knocked out in the story, you wake in Iron City Central** (`AreaRules.wake_area`),
  healed, minus the usual coins, never in the street that beat you. The story is kept:
  quests, streets reached (Win's and Uncle Thong's taxis ride back) and fights already
  won stay won (the city's own rest does not wipe them for a knock-out). Falling in the
  tutorial yard still wakes you there. `ZoneSim.respawn_x` is gone.
- **Footsteps.** Soft footfalls (`step_1`, `step_2`) for the hero and the monsters, one
  per stride while walking (`scenes/world/Footsteps.gd`). Monsters are quieter and fade
  out with distance from the hero, a boss's steps are deeper, and a crowd is heard at
  most once every 110 ms. They play on four voices of their own, so they never cut a
  blow's sound short.
- **Five character slots, one per job** (`max_characters` 5, was 4). The Characters
  screen fits five cards.
- Balance, measured: the Grappler (Oren) on auto battle, three minutes on the Core
  Overflow farming ground at its level, 16 seeds. Before: 5 knock-outs, 461 kills.
  Short throws alone: 6 knock-outs, 414 kills. Final (landing impact, and a slammed foe
  stays down for the full knockdown from the moment it lands, not from the throw):
  5 knock-outs, 452 kills.

### Added: the tutorial teaches grabbing; the ultimate gauge follows the hero
- **Tutorial:** a new step after the weapon throw has the player grab the training dummy
  (G, or E with empty hands) and says bosses and mini-bosses cannot be grabbed. Saves are
  version 12: a save past that point keeps its place, and a finished tutorial stays
  finished.
- **Ultimate gauge:** it is kept when the hero walks or rides to another area. It is not
  part of a save, so loading a game starts it empty.

### Fixed: mini-bosses can no longer be grabbed or thrown (owner's rule, 2026-11-11)
- **Only ordinary monsters and players are held or thrown.** Bosses already could not be;
  mini-bosses (enemies with the mini-boss mark, `"elite"` in `enemies.json`) could, for
  half the usual hold. A grab on either now lands as a shove.
- **Auto battle** no longer spends the Grappler's Iron Grip (a grab with no blow of its
  own) on a boss or mini-boss, and rates his other grab skills on them by their shove,
  not their throw. It never pressed the grab button itself.
- Cost to the Grappler, measured with auto battle on all 12 farming grounds (6 seeds):
  kills per hour 5% lower, damage taken 5% higher, knock-outs 2 of 72 (3 before).
- Tests: the farming hunt retries two more seeds after a knock-out (one seed alone was a
  lottery: about one three-minute run in thirty ends in a knock-out whatever the skills),
  and the story auto test gives the Grappler two more levels of margin.

### Added: the five job kits (30 active skills, 10 passives, 5 ultimates)
- **Every hero fights with their job's kit**: six active skills, two passives and an
  ultimate each (`client/data/skills.json`, kits in `jobs.json`). The old four-skill sets
  are gone; saved hotbars drop skills that no longer exist. Kit tables and measurements:
  `docs/JOB_SKILL_PLAN.md`.
- **Unlock levels:** active skills at 1, 2, 3, 5, 15 and 30, passives at 10 and 25, the
  ultimate at 50. The schedule first agreed (second skill at level 10) nearly doubled the
  damage auto battle took from the first boss, so early skills come sooner; awaiting the
  owner's confirmation.
- **Ultimates and their gauge** (`UltimateRules`): a gold bar under XP fills with every
  blow landed and every share of health lost. R fires the ultimate, or a hotbar slot.
  Knockout Devastation, Street Carnage, Titan Destruction, Absolute Retribution and Million
  Fist Onslaught each deal 2 to 3 times the job's strongest skill, warn before striking,
  and have an answer.
- **New skill rules:** skills that open with a grab and throw by themselves (bosses are
  struck instead), a squeezing hold, slipping punches that cannot be hit on the way in,
  timed buffs, bonuses tied to one skill, and passives that resist damage, lengthen holds
  or widen the parry.
- **Skills screen and character creation** show all nine skills in two columns; the
  Skills screen explains the card pointed at or pressed.
- **Auto battle** answers attacks with counter stances, throws what it grabs, braces when
  hurt and saves the ultimate for bosses and crowds.
- **Hero titles, taglines and bios** follow the jobs (The Boxer, The Brawler, The
  Grappler, The Counter Fighter, The Street Striker).
- **Skill pacing rule restated** (`test_skill_pacing`): regular skills come back within
  4.5 s as before; a job may have up to two slower ones (was one of four).
- **Balance tests restated for kits** (`test_balance`): ultimates at 2 to 3 times the
  strongest skill, the Boxer hardest on one target, the Brawler widest, the Striker
  quickest, counters never unprovoked, the Grappler's skills all grabs.
- Measured against the game before this work (auto battle, 4 farming grounds, 4 seeds):
  kills per hour within 8% for every hero, damage taken 3% to 24% lower; early story
  areas clear 3% to 19% slower, with no knock-outs.

### Changed: five heroes, one job each (owner's decision, 2026-11-10)
- **Pong the Soldier left the roster.** The five heroes are Riku (Boxer), Kan (Brawler),
  Oren (Grappler), Dao (Counter Fighter) and Mika (Street Striker). Pong's four skills and
  their moves are gone from the data; his art stays in the repository.
- **Saves are version 11.** A character saved as Pong carries on as Kan under the same
  name, with level, coins, items and quests kept and Kan's default hotbar.
- `docs/JOB_SKILL_PLAN.md` compares the owner's five-job blueprint (6 active, 2 passive and
  1 ultimate skill per job, shared grab and throw, separate PvE and PvP balance) with the
  game as built and sets out the work as a sequence of small PRs. The owner approved its
  eight decisions (BLUEPRINT D15).
- **Jobs are data** (`client/data/jobs.json`, `JobRules`): five jobs, each hero's `job` in
  `heroes.json`, and the levels a kit unlocks at (actives 1/10/20/25/35/40, passives 15/30,
  ultimate 50). Checked on load: one hero per job; a job's kit, once listed, is 6 active,
  2 passive and 1 ultimate skill at those levels; and no player skill uses an enemy's move.
- **Each job punches its own way** (`jobs.json` `moveset`, new moves in `moves.json`): the
  Boxer's jab, straight and heavy (longest reach, a last blow that staggers without
  flooring); the Brawler's left, right and swing (wider, a harder shove); the Counter
  Fighter's lighter quick, counter and heavy; the Street Striker's four fast punches. The
  Grappler's three keep the old combination's values until grabs arrive. The heavy button
  is unchanged. Measured with auto battle on four farming grounds (4 seeds each): kills
  per hour within 5% and damage taken within 11% of the old combination for every hero
  (`docs/JOB_SKILL_PLAN.md`).
- **Grab and throw for every job** (`GrabRules`, `jobs.json` `grab`): G grabs the foe in
  front (E, USE or B does too with empty hands and nothing to pick up); any attack button
  throws them the way the hero faces, and a thrown body knocks down others in its path.
  A hold ends by itself, a hit on the holder frees the foe, a held player shakes free by
  pressing buttons, nobody is grabbed twice within 1.5 s, bosses are only shoved and
  elites are held half as long. The Grappler reaches furthest, holds longest and throws
  hardest; the Boxer and the Street Striker push a foe off balance instead of flooring them.
- **Grab, lift and throw animations** for all 51 LPC characters, built from LPC's own
  thrust, spellcast and slash frames (`art/lpc/characters.json`); existing rows are
  unchanged. A held foe is drawn lying across the holder's raised hands.
- **Counter stances** (`CounterRules`, moves with `"counter": true`): a skill may open with
  a stance; a blow caught from the front while it is open does nothing, staggers the
  attacker and starts the skill's reply at once. A stance nobody hits deals nothing and
  leaves its user open. Guard breakers, blows from behind, grabs and thrown weapons go
  through it. The guard shows while a stance is open. No hero has such a skill yet.
- **Skills of several blows** (`SkillSequence`): a skill may list the moves that follow its
  first (`then`). Each stage starts by itself and can hit a defender once; only the first
  move costs energy; being hit ends the skill; nothing cancels it before its last stage.
- **Passive skills** (`PassiveRules`): data-driven stacks earned by landing blows or
  parrying, lost by missing or by time, adding damage, critical chance or attack speed,
  optionally only on a combination's last blow or on a counter. No hero has one yet.
- A running skill's PvE profile now scales its damage, hitstun and knockback as well as
  its cooldown.
- **PvE and PvP balance are separate** (`BalanceProfile`): a job skill carries a `pve` and
  a `pvp` profile of multipliers (damage, hitstun, knockback, duration, cooldown). Zones
  read cooldowns through the PvE profile; today's skills have none and are unchanged.

### Changed: quality-of-life pass (owner's list, November 2026)
- **Pickup feed:** items picked up are listed at the screen's left with their icon and their
  name in the rarity's colour.
- **Enhancement:** no more rising odds after a failure (no pity); upgrading only at the
  workbench NPC in the city.
- **Walking:** Depot Yard walks west back into the city. Farming grounds chain west into
  the ground one band lower; only the lowest opens onto the city.
- **City labels** sit on their NPC (MARKET / $ Ama, TAXI RANK / >> Win, ...).
- **Equipment screen** shows when auto-equip is on and can switch it off.
- **Shop:** tick many items and sell them at once.
- **World bosses** are open to every hero from level 10
  (`progression.json` `world_boss_entry_level`); no story boss has to fall first.
- **Two shops:** Ama's Kitchen sells food and tonics, every grade, priced by grade; Kenji's
  Gear Stall sells Common gear only ("Used ..." copies, about 85% of the old price). Uncommon
  and better gear only drops, and no shop sells upgrade materials (both checked on load).
- **Farming grounds** rise in step with their level: each ground has a `toughness` (HP and
  power multipliers on its enemies) and a pay to match, set with FarmCheck (shop gear +0,
  hero at the ground's level, 4 seeds). Kills per hour, before and after: Lv 4 1812 to 732,
  Lv 9 1269 to 540, Lv 15 753 to 396, Lv 29 639 to 320, Lv 58 618 to 306; every ground
  from Lv 22 to 68 now sits at 306-360.
- **Ground prizes:** every enemy on a ground may drop the Uncommon and Rare gear of its
  band (`spawning.drops`, shown under "Where to get"), the gear no shop sells.
- **Map (M)** shows only the story on the street, only the farming grounds in a ground or
  lair and only the arenas in a world boss arena; in the city everything, with each
  category's row in its own colour.
- **Skill effects** are drawn as wide as the blow reaches (a slam's crack, a heavy hit, a
  boss's heavy impact, hazard landings), not at the art's full size.
- **Bosses chase:** a boss whose hero runs more than 150 px off strides at 1.15 times the
  hero's walk until it is close again, instead of standing off calling its skills.
- **Mini-bosses** wear the map's mini-boss mark and "Mini-boss" overhead, on the boss bar
  and in their arrival toast, instead of the boss skull.

### Added: three raid world bosses, Godforged prizes, armed world bosses
- **The Floodgate Marshal** (Lv 56, 15 players), **The Crucible King** (Lv 64, 20) and **The
  Founder's Engine** (Lv 70, 30): each stronger than the last, with its own arena, weapon,
  moves (a new heavy every phase), colour and summons, and two new hazard kinds: "quake",
  a split across the street's whole depth, and "rain", a volley of drops.
- **Godforged** grade (budget ×2.2) for every world boss prize, replacing Mythic: about 38%
  above a Legendary of the same level.
- **Armed world bosses**: every world boss holds a weapon; a boss's weapon lasts
  `boss_weapon_durability` (2.5) times its hits.
- **Field truck** lists every ground, lair and world boss by level; closed ones say what
  opens them; a defeated world boss shows when it rises.
- `docs/WORLD_BOSS_DESIGN.md`: the roster, the server architecture for shared world bosses,
  the effects plan and the owner's decisions.

### Fixed: world boss endings
- The result screen (kill, time-out, knock-out) can be pressed: it was rebuilt every tick.
- At the end of the hour the boss escapes off the arena instead of staying to be beaten.
- A boss defeated this round cannot be fought again at 0 HP; it rises next round.
- The round runs on the world's clock: switching to another window no longer stops it.

### Changed: Phase 2 audit of the level 50-70 farming endgame
- **Rosters:** each 50-70 ground mixes three roles (common fighter, heavy, fast or ranged)
  and one elite instead of two kinds; the Iron Heart no longer fields two heavies. Knock-outs
  at the ground's level stay at or below 2 in 20 five-minute sessions (FarmCheck, 20 seeds).
- **Tints:** `enemies.json` `tint` colours a monster's sprite in the shader, so 50-70
  monsters, lair bosses and the new world bosses read as their own kinds; story enemies are
  unchanged.
- **Calibration:** per-tier XP and coin factors in the generator keep XP/h within 3% of the
  rates that met the level-time targets and coins/h at 48k, 51k, 62k and 75k. The XP curve
  is unchanged: 50-70 measures 89.4-89.6 h (target 90).
- **Spillway Chief** health x2.5 (from x2.0): it was the only lair boss that a hero with no
  gear always beat. The other lair bosses keep their values.
- **Enrage 75 s kept**, now with evidence: it never fires for a hero at level with shop or
  boss gear (slowest such kill 74 s), fires for 1-3 in 10 shop-geared heroes 5-10 levels
  under on the longest fights, and for nearly every stalled fight (no gear, 83-135 s).
- **Item sources:** the item card's "Where to get" now lists world boss prizes, farming-ground
  elite prizes and where field and lair monsters fight (`ItemSources`, split out of
  `ContentDB`, which drops to 932 lines).
- **Harness:** FarmCheck reports damage, food, kills, gear drops and knock-out causes;
  EnrageCompare takes enhancement levels and a no-gear kit; new WorldBossCheck.
- **Tests:** test_item_sources.gd, test_endgame_monsters.gd; enhancement boundaries, preview
  equals result, +10 save/load; auto battle never rides to a lair; tint reaches the shader.
- **Known limit (owner decision):** in the single-player build a 10-player world boss cannot
  be emptied by one hero within its hour (Iron Sovereign 97-149 min, the existing Subject
  Zero 99-166 min), so its prizes, including the mythic set, cannot drop yet. See
  `docs/PHASE2_AUDIT_REPORT.md`.

### Added: levels 50-70 content, boss lairs, mythic gear and boss enrage (Phase 2)
- **Level cap 70** with a data-driven XP curve (`progression.json` `xp.levels`), see the entry below.
- **Farming grounds:** Core Spillway (Lv 43, fills the 41-45 gap) and four grounds for 50-70:
  Coolant Vaults (53), Reactor Underworks (58), Foundry Depths (63) and The Iron Heart (68),
  each with two new monster kinds and a champion elite. Existing grounds and unlocks are unchanged.
- **Boss lairs** (`"kind": "lair"`, `AreaRules.LAIR`): a short arena beside each new ground
  with one boss fight that comes back after every rest; reached by Uncle Thong's truck
  ("Rematches"), opened with its ground. Bosses: Spillway Chief, Commander Arthit
  (Reinstated), Subject Twelve (Relapsed), Unit K-7 (Overdriven), The Wiroj Protocol.
  Ground and lair pairs open in a chain, never by level.
- **World bosses:** The Slag Titan (Lv 60, 5 players) and The Iron Sovereign (Lv 70, 10
  players). Unlimited entries and attempts, no daily limit, no wait, shared round pool,
  as for every world boss.
- **Gear:** 83 new items: uncommon, rare and epic in every slot for each tier (53, 58,
  63, 68), Spillway Chief's level 42 epic body and head (closing the boss-gear gap from
  27 to 48), three legendary Slag Titan prizes and a six-piece mythic Sovereign set.
  New grade **mythic** (budget x1.85). Every piece is priced to the `ItemRules` budget.
- **Enhancement:** still +0 to +10 with the same rates, pity and no-loss failures; no new
  material. `enhance.item_level_costs` scales coins x2 / materials x1.5 from item level
  51 and x3 / x2 from 61. The workbench card previews what the next level adds.
- **Market:** Ama's 50-70 stock opens with each lair boss (`"defeated"` stock entries).
- **Enrage** (`BossEnrage`, data-driven): lair bosses enrage after 75 s, warned 10 s ahead
  (x1.5 damage, hazards and summons 30% quicker); the 50-70 world bosses for the last 20
  minutes of the round (x1.3, 20% quicker), shown on the HUD. It never ends a fight or
  limits entries or food.
  - Compared with `tests/harness/EnrageCompare.gd` (5 lairs, shop and boss gear, 8 seeds,
    heroes at the lair level and 5 and 10 below): no knock-outs at any setting; median
    kills 16-60 s, slowest 62 s at the suggested level (Wiroj Protocol, shop gear) and
    70 s ten levels below. 60 s enraged that fight for on-level heroes (1 in 8 runs) and
    for 2-3 in 8 at ten levels below; 75 s and 90 s never fired. 75 s kept.
- **Balance pass** (measured with `FarmCheck.gd`, `EnrageCompare.gd`, `LevelingRun.gd`):
  - Lair bosses get ×2.0 the health of the story boss they come from (the Wiroj Protocol ×1.3,
    whose shield phases already make the fight long). On-level kills now take 33-65 s with no
    knock-out. The 75 s enrage fires in 1 of 8 on-level runs and 2-3 of 8 ten levels under;
    60 s fired in 4-6 of 8 on-level Wiroj Protocol runs, and 90 s never fired.
  - Field coins per tier scaled so coins per hour climb 35k (Core Overflow) → 44k → 50k → 61k →
    79-87k, instead of 76k-129k with Foundry above Iron Heart.
  - Iron Heart's Iron Sentry (a former elite) comes less often: knock-outs 3/8 → 1/8 at Lv 66.
  - Uncommon 50-70 charms take Kenji's Lucky Charm stat mix: crit 0.12-0.15 instead of 0.23-0.29.
  - Levelling after the pass: 50-60 23-25 h, 60-65 27 h, 65-70 40-45 h (targets 25/25/40).
- **Tools:** `tools/content/level70_content.py` generates all of the above (idempotent);
  `tests/harness/ItemBudgetQuery.gd`, `EnrageCompare.gd`, `FarmCheck.gd` (coins and materials per
  hour too); `LevelingRun` now measures the
  real grounds up to the cap. Scenery for the twelve new areas from the asset pipeline.
- **Tests:** `test_lairs.gd`, `test_boss_enrage.gd`, `test_level70_gear.gd`; the ground,
  taxi, market and boss-gear tests follow the new content.

### Added: the client/sim purity test and local architecture guides
- `client/tests/unit/test_sim_purity.gd` checks every `client/sim/*.gd` file.
  - **Forbidden:** scene types, the `Input` singleton, the scene tree, host services (`OS`, `Engine`, `Time`, ...), `res://scenes` paths, autoloads, global or unseeded random numbers, and file or network access.
  - **Exceptions:** only the two data loaders, which read the content JSON.
  - **Self-checks:** each rule is proven to fire on a forbidden sample and to spare comments, `FighterInput` and seeded RNGs.
- Local `CLAUDE.md` guides for `client/sim/`, `client/scenes/`, `client/data/`, `client/tests/`, `backend/` and `tools/`; the root `CLAUDE.md` points to them.
- No gameplay change.
### Fixed: the original food and world boss rules are back
- **Food:** unlimited again, as before PR #73.
  - The 6-foods-per-boss-fight cap is removed (progression.json `boss_fight_food`, `FoodRules.boss_food_left`, the hotbar dimming and the "No more food" message).
  - Healing is exactly as approved: the same heal amounts and the 2-second shared cooldown.
- **World bosses:** unlimited entries again.
  - The 3-tries-per-round limit is removed (world_boss.json `attempts`, `WorldBossRules.attempts_left` and `begin_attempt`, the "tries left" texts).
  - No daily limit and no wait between attempts.
  - Saves that carry the old attempt count still load; the field is ignored.
- **Bosses:** Director Wiroj's ×2.2 and Subject Twelve's ×1.5 power (phases included) are reverted to their earlier values.
  - They raised danger for every hero alike, the best-geared most (audit §12).
  - No replacement multiplier is added.
- **Tests:**
  - The three tests that encoded the caps are removed.
  - New guards: food is never limited in a boss fight; heal amounts and the cooldown keep their approved values; world-boss entries stay open after any number of attempts.

### Changed: gear and upgrades matter against bosses; food tops up, it does not carry the fight
- **The problem, measured** (ProgressionHarness, a level 50 hero against Director Wiroj,
  3 seeds each):
  - With no food, starter clothes always lose (3/3 knocked out). Shop gear wins, boss gear
    wins faster, and +10 gear takes a quarter of the damage.
  - But with 10 herbal tonics, starter clothes won, eating 4 times their health in food
    (one tonic every 2 seconds). About 900 coins of food did the work of all the gear,
    enhancing and boss drops, so none of them were needed.
- **The fix:** a boss fight allows 6 foods (progression.json `"boss_fight_food"`,
  `FoodRules.boss_food_left`). Elsewhere food is unlimited, as before. Each boss spawned
  (and each world boss attempt) starts a fresh allowance.
  - When the allowance is spent, the food slot on the hotbar dims.
  - The quick-heal key and the bag say "No more food in this boss fight".
  - Auto battle stops trying to eat.
- **After** (same harness):
  - Starter clothes at level 50 now lose to the Director 3/3, even with tonics.
  - Shop gear at each area's own level still clears every story stage sampled (from
    Rusted Corner to the Core Chamber, Oren and Mika, 0 knock-outs). The 6 allowed keep
    the Gang HQ boss as it was.
  - An over-levelled hero can still beat early bosses in old gear, as in any RPG.
- **Late bosses that hit too softly.** Without food, other bosses kill a hero in shop
  gear at their level in 25 to 40 seconds. Subject Twelve and Director Wiroj took 80 to
  120 seconds, and boss gear at +5 took almost nothing. So the end of the story was
  easier than its middle.
  - Subject Twelve now hits 1.5 times as hard and the Director 2.2 times, phases
    included (`enemies.json` power).
  - The finale now asks for upgrades. With the 6 foods allowed:
    - Shop gear at +0 goes down about one fight in three.
    - Shop gear at +5, or boss gear at any level, wins.
    - Starter clothes lose every time.
- **World bosses: 3 tries per round** (`world_boss.json` `"attempts"`,
  `WorldBossRules.attempts_left`).
  - Before, a hero could fall and ride back all hour, and the pool kept its damage.
    That let anyone grind down a boss built for a group, whatever they wore.
  - Now a fall or a ride home spends a try. Win's ride and the world boss list show the
    tries left.
  - Measured on an attempt at the Tunnel Mother (3 players), with food:
    - Shop gear at level 32 needs 16 to 21 tries.
    - Boss gear +5 at level 35 needs about 5.
    - Boss gear +10 at level 40 needs 2.
  - So a solo kill now takes real gear.
- **Tests:**
  - The allowance counts per boss fight and keeps the refused food.
  - Auto battle stops eating when the allowance is spent.
  - Starter clothes plus tonics lose to the final boss; shop gear wins.
  - A world boss round allows its tries, then refuses until the next round.

### Security: apt removed from the API image
- Trivy flagged apt 2.6.1 (CVE-2026-109518, HIGH) in the Debian base. The service never
  runs apt and the image is rebuilt rather than patched, so apt and libapt-pkg are
  purged from the runtime stage, as npm already was.

### Changed: quests taken and claimed from the quest card, as in mobile games
- **The quest card does it all** (`Hud._update_quest`, `QuestFlow`), from wherever the
  hero is, with no walk to a giver and no searching for one:
  1. NEW QUEST: its name and goal. Press F, or tap the card, to read the giver's offer
     and accept it.
  2. QUEST: "Defeat The Sludge Foreman 0/1" and where.
  3. QUEST COMPLETE!: a popup says so, and the card turns gold. Press F to hear the
     giver and claim the reward.
- The card opens the giver's own quest window, so the story's words and the rewards
  (coins, XP, gear, evidence, chapter ends, the epilogue) are as before.
- **Credit for earlier kills:** a boss beaten before its quest was taken counts. The
  quest is done the moment it is accepted (`QuestRules.catch_up`). A save that played
  on ahead clears its quests with a few presses.
- Auto battle takes and claims quests wherever it is (`StoryAuto`).
- The map's goal says "New quest: … (F)" or "Claim your reward (F)" instead of sending
  the hero back to a giver.
- The tutorial's last step is the first quest on the card ("press F to accept it"),
  instead of "Talk to Chief Odo".
- The quest givers stay at their rest points to talk to.
- New key: F (gamepad: left stick), "quest_action".
- This replaces the quests running themselves (below) with the player's own accept and
  claim, as the owner asked.
- **Tests:**
  - The card takes and claims from anywhere.
  - A boss beaten before its quest counts when it is taken.
  - Auto's steps take and hand in anywhere. 549 in all.

### Fixed: getting stuck in the story (auto looping, quests left behind, shut gates)
- **Auto no longer loops in one area:**
  - With the map's quest far behind (a quest never taken or handed in while playing on
    by hand, `StoryAuto.HERE`), or with the story finished, auto used to fall back to
    the farm loop. It cleared the area, rested in the city and rode back to the start
    of the same area, forever.
  - Reproduced in Freight Market: 32 Port Guards down and still there.
  - Now it walks on east as soon as the area is won and its gate is open
    (`AutoBattle._story`). With the "Story" auto setting off it still farms in place,
    as chosen.
- **A shut gate says why:**
  - When every fight in an area is won but its east gate still needs more of its guard
    knocked down, a message names it at once: "Port Guards watch the yard gate. Knock
    down 6 to pass. (5/6)" (`GameFeedback._gate_progress`).
  - Before, it only appeared on bumping the edge, while the area's fights came back.
- **The story's quests run themselves** (owner's choice; `QuestRules.auto_flow`,
  `QuestFlow`): a new player who never talks to a quest giver no longer misses the
  story's rewards and falls behind.
  - Each stage's quest is taken as soon as the one before it is handed in, the first
    from the start.
  - When its boss falls, its rewards are paid on the spot: coins, XP, gear, evidence,
    a level up, a chapter's end and the epilogue. The next quest is taken at once.
  - The giver's closing words open in their quest window when no other screen is
    open. The street goes on behind it.
  - A boss beaten before its quest came counts.
  - A save that played on without its quests catches up on load, paid in order.
  - The quest givers stay at their rest points to talk to.
- **Tests:**
  - With the quest far behind, auto walks on from Freight Market to Container Yard
    instead of looping.
  - The quests run themselves, and a save three bosses ahead is paid for each in
    order.
  - A finished quest is paid where it finishes. 549 in all.

### Changed: light and shadow on the street
- **No gap at the bottom of the screen** (`Scenery._apron`):
  - The road picture ended 6 game pixels short of the 360-pixel view, so a dark strip
    showed at the bottom (more in wide windows and under screen shake).
  - The road now runs 30 px further: its own bottom rows, mirrored, so it meets
    without a seam.
- **Shadows cast from the light, from each thing's own base** (`Shade`):
  - Fighters, NPCs, street furniture (trucks, crates, drums, lamps) and the props on
    the sidewalk cast their own silhouette onto the street. It is laid down from
    their base line, squashed by the low angle and slanted away from the light (the
    moon and lamps above, behind and a little to the left), so nothing looks like it
    floats.
  - A small, soft contact shadow darkens where each meets the ground.
  - A fighter's cast shadow follows its animation frame by frame.
- **Characters in the street's light** (`flash.gdshader`, `ZoneView.ambient_light`):
  - Heroes, monsters and NPCs take half the colour of the area's light (the street
    kit's tint).
  - They are a little darker toward the feet and a touch brighter at the head.
  - The hit flash is unchanged.
- **The street lamp's yellow disc is gone** (`kit_import.py` `"dehalo"`):
  - The painting's glow on the green backdrop had stayed behind as a flat yellow-green
    disc beside the lantern.
  - The importer now clears glow that reaches the outside, keeping the lantern's own
    glass. The game's own glow is drawn at 70%.
- **Tests:**
  - The road reaches past the view.
  - Props, furniture and lamps cast shadows from their base, slanted.
  - Fighters cast a shadow over their contact shadow and take the area's light.
  - The lamp carries no halo. 546 in all.

### Changed: the street goes on behind every screen; camps that amble and vary
- **The street never stops** (`Game._physics_process`):
  - With the bag, the map, skills, quests, a shop, a taxi or the game menu open, the
    street goes on as in an online game: enemies, hazards and the world boss's clock
    carry on.
  - Auto battle keeps fighting, farming and following the story. The keys belong to
    the screen, so without auto the hero waits where they stand.
  - Not even the screens that wait for a choice stop it (`Game.CHOICE_SCREENS`: game
    over, a world boss's results, the epilogue). Esc does not close those, and the
    world goes on behind them too, as it will online with many players.
  - The Esc menu is now titled "Menu", and "Resume" reads "Back to the game".
- **Camps that live** (`EnemyBrain._amble`): an idle camp member ambles about its spot
  (up to 36 px, at a slow pace, pausing 1 to 3 seconds between strolls), and never far
  from it.
- **Camps of 2 to 4** (`"camp_size": [2, 4]`, `FarmSpawner.size_range`):
  - Each camp rolls its size when it first stands and again each time it stands back
    up after being cleared.
  - Each ground now has 3 camps, 340 px apart.
- **One camp at a time:**
  - The aggro radius is 100 px.
  - A member walking home from a chase it gave up ignores everyone until it is back
    and healed. Before, it was woken again on its way through the next fight, so 6 to
    9 enemies could pile onto the hero.
  - Auto finishes the fight in hand before it pulls the next camp.
- **Measured** (harness, 3 seeds × Oren and Mika, 10 minutes per ground):
  - Coins ×0.99 to ×1.13 and XP ×1.02 to ×1.11 of the old field's rate.
  - No knock-outs.
- **Tests:**
  - The street goes on behind the bag, the map, the menu and the screens that wait
    for a choice, and auto fights on behind the bag.
  - Camps amble and roll sizes of 2, 3 and 4.
  - A cleared camp stands again at a new size, and the safe spot holds.

### Changed: one merchant, two taxis, a world boss hour, armed bosses
- **One merchant in the city: Ama's Market** (`shops.json` `city_market`, `ShopRules`):
  - Every stall's wares are sold in one list: food first, then gear by level
    (`ShopRules.wares`).
  - The other traders' stock still arrives with their chapter (`"stock"`:
    `{"reached", "from", "items"}`). The list's last row says whose stock comes next and
    where ("Kenji brings new stock once you reach Night Market.").
  - Kenji's, Noi's, Aunt Jum's, Uncle Thong's and Lek's stalls and Ama's crates are gone
    from the market. Validation of shops moved to `ShopRules.problems`.
- **Two taxis, each with its own menu** (`"routes"` on a travel NPC):
  - Win (`"story"`) rides only to the story's areas.
  - Uncle Thong's truck (`"field"`, new in the city) rides only to the farming grounds
    and the world bosses. The two never mix.
  - The story bible records Uncle Thong's new job.
- **The world boss hour** (`WorldBossRules`, `WorldBossRun`):
  - The boss is up for its hour, and that is the time to bring it down. An attempt now
    lasts until the hero leaves, falls or the hour ends (no 2.5-minute limit).
  - The round's damage stays counted all hour.
  - If the hour ends with the boss standing, it escapes: its next round starts at full
    health, and nobody is paid.
  - Rewards come only when it falls: every damage tier the round reached, plus the kill.
  - The results screen says so.
- **Bosses come armed** (`enemies.json` `"weapon"`, `LevelRules.armed_weapon`):
  - Every boss that fights with its hands steps in holding its own weapon, with its moves
    and its wear as a hero holding it would: the Foreman a wrench, the Baron a pipe, the
    Pit Champion a chair, Chen a machete, the Security Chief and Big Sak a bat, the
    Ringmaster a plank, Arthit a pipe, the Director a knife.
  - Creatures and machines (K-7, Subject 12, the world bosses) keep their own attacks.
- **Tests:**
  - The market gets each trader's stock with their chapter.
  - The two taxis keep to their routes.
  - Only the kill pays, and the fight lasts until the hour is up.
  - Every armed boss steps in holding its weapon.
  - The other tests follow the new names. 539 in all.

### Changed: farming grounds are camps that wait for the hero; story auto stays put
- **Camps, as in field-farming games** (`FarmSpawner`, `EnemyBrain.camp`):
  - Each ground holds 4 camps of 3 (`"camps"`, `"camp_size"` in `areas.json`), all
    standing when the hero arrives.
  - A camp waits at its spot until the hero comes within its aggro radius (140 px) or
    strikes one of it. Then the whole camp comes together; the other camps stay put.
  - A member chased past its leash, or unable to reach the hero for 3 seconds (the hero
    gone into the safe spot by the exit), walks home and heals there.
  - Ready for several players in one ground (IL-7): each pulls the camps near them.
- **Back in 3 to 5 seconds:** a fallen enemy returns to its camp 4 seconds (±1) after it
  falls, once its camp's fight is over, on the camp's side away from the hero. Clearing
  a camp earns a breather of a few seconds, then it stands again. Never quiet for long.
- **Each field enemy pays less** (`"reward_scale"`, 0.46 to 0.73 by ground; XP, coins
  and drop chances, `FarmSpawner._scale_rewards`):
  - The field is much busier now, so without this a minute of farming would pay ×1.7
    to ×2.8 the old rate.
  - With it, a minute pays about ×1.25 the old rate: the extra comes from never
    waiting, not from free money.
- **Story auto does not drag the hero back** (`StoryAuto.HERE`):
  - When the quest on the map points back to an area more than 8 levels easier (a quest
    left behind while playing on by hand), auto keeps fighting where the hero is.
  - It says once where that quest is.
  - Before, finishing a level-48 area could send auto off to level-17 monsters.
- **Tests:**
  - The camps stand full and wait.
  - Walking into a camp wakes only that camp, and a blow wakes the camp it lands on.
  - A chase gives up and heals at home, and a cleared camp stands again a few seconds
    later. A fallen one waits while its camp fights.
  - The reward scale applies, and the validator checks the new fields.
  - Story auto keeps fighting here for a quest left far behind.

### Changed: bosses, mini-bosses and elites are named clearly
- **One symbol per rank, the same as on the map:**
  - Over a boss's head: the map's red skull and its name in red.
  - Over a story mini-boss: the map's horned mini-boss mark and its name and level in
    orange.
  - Over a farming ground's elite: a gold star and "Elite <name>  Lv N" in gold.
  - Ordinary enemies keep just their level, coloured by threat (`FighterView._rank`).
- **The boss bar** at the top of the screen has the skull before the boss's name and level.
- **Toasts name the boss:**
  - "BOSS: Sludge Foreman" when it steps in (it used to say "A boss approaches!" before
    anyone could see it).
  - "<name> is enraged!" at its new phase, instead of "It's enraged!".
- **Tests:** an elite is named with its star; a world boss is named overhead with the
  skull and on the boss bar with it.

### Changed: skill effects and sounds, cleaned up
- **No shield when guarding:** a blocked blow used to show a large blue lattice shield
  (pixelfx `impacts/shield-block`). It now gives a small steel-blue spark: the hit spark
  recoloured (`art/pixelfx/effects.json`), credited in the register like the other pixelfx
  effects.
- **Effects stay where they land** (`GameFeedback`):
  - A slam's crack and dust are left on the street, on a new layer under the fighters
    (`ZoneView.ground`), and no longer slide along with the hero.
  - Strike bursts and the uppercut's arc stay where the blow landed.
  - Only a charge's trail and a spin around the body travel with the fighter (`FOLLOWS`).
- **No smoke when enemies come or go:** the puff of smoke on an enemy's arrival and at its
  fall looked like a ninja vanishing, and nobody in this game teleports.
  - An ordinary enemy now fades in over a quarter of a second (`ZoneView._fade_in`).
  - A fallen enemy's body just fades away.
  - An elite still arrives in gold light, and a boss with its landing slam.
  - The unused `poof` effect is removed from the assets and the credit register.
- **Quieter, plainer sounds:**
  - Each synthesised sound now has its own level (`gen_sfx.py`), so small sounds heard
    often sit well under the blows.
  - The coin is a short, quiet metallic clink instead of an arcade jingle, played at -8 dB.
    A pickup is a soft pop.
  - The level-up and quest sounds are warm chimes instead of square-wave fanfares.
- **Hazards sound like themselves:**
  - New original sounds: a two-tone warning (it used to be the menu's "denied" buzz),
    steam hiss, an electric zap, a laser beam.
  - An elite's arrival has its own shimmer instead of a pitched-down level-up.
- **The final boss's hazards are finished** (`HazardView`; the Director cycles steam, shock
  and laser):
  - Steam and sludge: the vent is as wide as what it hits, and hissing wisps rise as it
    comes. The column itself is the pixelfx burst, so the old drawn circles are gone.
  - Shock: the plate's seams glow as it charges, with stray sparks. On landing it flashes,
    and jagged arcs crackle across it, flickering and dying away.
  - Laser: on landing, a soft glow, a bright band and a white core that narrow as the beam
    fades. It ends in a spark where it hit, instead of a lightning bolt.
- **Credits:** the new sounds are the project's own, generated in code (MIT). The changed
  effect is pixelfx (MIT), already credited in game and in `docs/credits`.
- **Tests:** a slam stays on the street while a charge's trail follows the hero; every
  hazard draws, lands and sounds. 532 in all.

### Changed: auto battle plays the story and fights every boss
- **No first clear by hand:** auto battle now runs wherever there is a fight
  (`AutoRules.problem`):
  - story areas not cleared yet, and their bosses;
  - world boss arenas: it fights to the end of the attempt and never goes home halfway;
  - open farming grounds, as before.
- **Auto quest** (`StoryAuto`, new in `sim/`): following the map's goal (`MapRules.goal`),
  auto plays the story one step at a time:
  - At a rest point it hands in the quest that is done and takes the next one from the
    quest giver.
  - It fights through each area, walks on through the east exit, and fights the stage's
    boss.
  - Then it rests in the city and rides Win's taxi to where the quest goes next. The fare
    and the food restock work as in the farm loop.
  - It starts from the city or a quest giver's rest point too, with no one to fight there.
  - When the story is done, auto turns off.
- **Player control is unchanged:** any input of the player's own takes over, and the
  player walking to another area turns auto off. A knock-out turns auto off.
- **Setting:** "Story: take each quest and fight on to its boss" in the auto options (on
  by default). Off, auto stays in the area and farms it as before.
- **Hand-ins:** auto's quest steps go through the same quest rules as the giver's menu:
  the rewards, a level up, a chapter's end and the epilogue (`Game._hand_in`).
- **Wears better gear:** out of a fight, auto puts on any better gear the hero carries
  (`AutoRules.wear_upgrades`, the bag's "better" mark), after a drop or a quest's rewards.
  Setting: "Wear better gear found" (on by default).
- **Measured** (scratch run, not in CI): a new hero on auto, never touched, from Chief
  Odo's first quest to the epilogue:
  - Oren: about 60 minutes of play, 0 knock-outs, level 50 at the end.
  - Mika: about 57 minutes, 0 knock-outs, level 50.
  - Without wearing better gear, the same run was knocked out over and over by Unit K-7
    at level 25; that is why auto wears it.
- **Tests:** the steps of the first stage, and a new game playing stage one to the next
  quest on auto alone; wearing the best gear carried; no trip home from a world boss
  arena. The auto rules tests now cover the story areas, the city and the world boss
  arenas. 530 in all.

### Changed: farming fields send enemies in packs
- **What changes:** after the first fill, a field no longer trickles in one enemy each
  time one falls.
  - With room for a whole pack (3 of the 4 standing), the next pack arrives after the
    field's respawn time.
  - Its members run in together from one side, off camera, 12 ticks apart
    (`FarmSpawner`, `"pack"` in `areas.json`).
  - The next pack is already on its way as the last enemy of the old one falls, so the
    fighting comes in bursts instead of a slow drip.
- **Same income:** the respawn times were re-tuned for packs, from 650 to 1380 ticks
  depending on the field. Measured with the harness (Oren and Mika, 3 seeds, 10 minutes
  per field):
  - Coins and XP per minute are within ×0.97 to ×1.08 of the old loop.
  - No knock-outs.
- **Tests:** a field fills, then sends whole packs together from one side; a single loss
  waits for room.

### Added: boss skill effects for every boss (pixelfx, MIT, credited)
- **Wind-up glow:** a boss's heavy blow is telegraphed by a glow gathering on it through
  the wind-up, coloured by the boss's theme. The themes are brawl (gold), fire (red-orange),
  toxic (green), tech (cyan) and shadow (violet), set per boss in `data/boss_fx.json`.
- **Heavy blows:** a boss's heavy blow lands with a burst of debris and a shake.
- **Hazards:** each kind has its own effect.
  - Falling crates: a dust explosion.
  - Steam: a geyser.
  - Shock and laser: arcing lightning.
  - Sludge: an acid splash.
- **Shields:** a boss's shield is a hexagon force-field dome that loops for as long as it
  holds, and bursts when it drops. It replaces the drawn dome (`ShieldView`).
- **Summons:** reinforcements arrive in a flare.
- **Defeat:** a fallen boss goes up in a blast.
- **Where it is defined:** `sim/BossFxRules.gd` reads `data/boss_fx.json`. The validator
  checks that every boss has a theme, every hazard kind used has an effect, and every
  named effect exists.
- **Imported effects:** 12 more from pixelfx at the same pinned commit: five recoloured
  spell-charge glows, dirt explosion, big explosion, a recoloured geyser, zap hit, acid
  splash, force field and EMP blast.
  - The importer can now cut a time window (`start`/`end`), recolour (`palette`) and keep
    looping effects whole.
  - Every effect has its own credit-register row (410 rows in all).
- **Size:** pixelfx sheets now total about 5 MB.
- **Tests:** 526.

### Changed: combat effects from pixelfx (MIT, credited)
- **What is new:** 14 effects from [pixelfx](https://github.com/patch-gg/pixelfx) by Patch now play
  in the fights.
  - Replaced: hit spark, heavy hit, block, the slam, uppercut and whirlwind skills, heal,
    level-up.
  - New: critical hit, parry, enemy poof (arrival and defeat), elite flare, a boss's heavy
    landing, a boss's phase burst.
  - They play at their native pixel scale, which suits the characters, so they stay sharp.
  - The generated dust and rush trail stay.
- **Import:**
  - Rendered with pixelfx's own tool at the pinned commit
    `a84159688af3ca37a4be05a0d422b94451b2e24e`.
  - Imported by `tools/assets/import_pixelfx.py`, which keeps every Nth frame, drops faded
    tails and crops. `art/pixelfx/effects.json` names which pixelfx effect plays as which
    game effect.
  - Sheets are in `client/assets/fx/pixelfx/` (2.3 MB). `Fx.gd` reads per-effect sheets laid
    out as a grid.
- **Credits, per the MIT licence:**
  - pixelfx's LICENSE and NOTICE ship beside the sheets, and the permission notice is
    stored in the manifest (`fx_pixelfx`) so the web build carries it too.
  - The game's Credits print the attribution, both copyright lines, the source and commit,
    and the full MIT notice.
  - The credit register has one row per effect with its authors: Patch, plus Hugo Duprez
    for the 12 effects whose source says they adapt his Sprite Fusion effects. Their status
    is `VERIFIED_MIT`, because the licence was read in the source repository at that commit.
  - THIRD_PARTY_LICENSES and LICENSE_REGISTER are updated.
  - pixelfx's gallery font, which is not MIT, is not used.
- **Validation:** the asset validator checks every imported sheet, the pinned commit, the
  authors, the licence file and the notice.
- **Tests:** 524. Every effect loads with all its frames, a pixelfx effect plays, and the
  Credits carry the notice.

### Fixed and added: effects around the fights
- **Audit:** AutoPilot fought through every boss area, a farming ground and a world boss
  arena with every frame drawn.
  - No effect was left playing and no hazard marker was left behind.
  - No node leaked and no engine error was logged.
  - At most 19 effects were on screen at once.
- **Arrivals:** an enemy now arrives in a puff of dust instead of popping in. A field
  elite also flares gold (with a chime); a boss lands with a shockwave.
- **Boss phases:** a boss entering a new phase flares red and throws out a shockwave, on
  top of the roar and the shake.
- **Defeated enemies:** a defeated enemy's body fades into dust instead of vanishing
  (`ZoneView._fade_out`).
- **Tests:** 522. New: `test_effects.gd`.

### Changed: the city holds every service; the story gives one quest per stage
- **Services in the city only (owner decision).** Every merchant (Ama, Kenji, Noi,
  Aunt Jum, Uncle Thong, Lek, and Ama's supply crates) now keeps a stall in Iron City
  Central's market. Each stall opens once the story reaches that merchant's chapter
  (`shops.json` `unlock`, `ShopRules.is_open`); until then the stall says when it opens.
  - Win's rank in the city is the only taxi. The story road keeps only quest givers, at
    each district's rest point.
  - The kiosk is replaced by Ama's stall.
  - Auto battle rests and restocks in the city, from the story too.
- **Stage quests.** A stage is one quest: take it at a rest point, fight through to the
  stage's boss, hand it in.
  - **The chain:** 12 quests (Foreman, Pit Champion, Furnace Baron, Chen, Security
    Chief, K-7, Ringmaster, Big Sak, Subject 12, Arthit, the Reactor Walkway's
    sentinels, Director Wiroj). They replace the 31 "defeat N" quests.
  - **Kept:** the story's dialogue and every piece of evidence. Quest XP over the whole
    story is unchanged (136,660), and the hero stays within two levels of every area.
  - **Rewards:** each stage pays its own Rare gear (12 new quest-only pieces).
  - **The last stage:** it pays the **Heart of Iron City**, a one-of-a-kind Legendary
    given once. The validator refuses it anywhere else.
  - **Saves:** evidence or a unique prize already held is never handed over twice.
    Saves load as they are (version 10): a retired quest is dropped, and the next stage
    is offered.
- **Story bible** updated (market, Win, quest chains). Tests: 520 (new: `test_stage_quests.gd`).

### Added: loot guidance (the bag's upgrade arrow, prizes on the map)
- **The bag:** a green arrow marks carried gear the hero could wear now that beats what is
  worn in its slot. It is scored with upgrades included (`ItemRules.is_upgrade`); gear
  above the hero's level gets no arrow.
- **The Map:** the detail line names the gear to be won in each area: a boss's drops, a
  farming ground's elite prizes and a world boss's rolls. It reads, for example,
  "Legendary: Harbourmaster's Hook · Epic: Harbourmaster's Cap, Dockmaster's Boots"
  (`MapRules.prizes`).
- **Tests:** 513.

### Changed: gear grades, boss loot and a smoother difficulty curve
- **Grades mean something now** (`sim/ItemRules.gd`).
  - **Budget:** every piece of gear is worth a budget set by its level, slot and grade:
    Common ×0.85, Uncommon ×1.0, Rare ×1.15, Epic ×1.35, Legendary ×1.6. The validator
    keeps each item within ±15% of its budget.
  - **Shops:** they sell only Common and Uncommon gear (the steady baseline).
  - **Bosses:** Epic and Legendary come from bosses. The shop items that were labelled
    Rare are Uncommon now, and every item's stats were refitted to its budget.
  - **Effect on boss gear:** a story boss's gear now beats the shops' at its level by at
    least 20%. Late Legendaries were far below that and gained the most (Arthit's Baton
    power 0.70 → 1.35).
- **Every boss drops its own set.**
  - **New pieces:** 13 (boots, headgear, coats and gloves), so each slot has boss gear
    along the whole road.
  - **Drop rates:** a boss's Epics drop at 20 to 30%, its Legendary at 6%.
  - **Bad-luck protection:** a Legendary gets 25% of its chance more likely with every
    defeat while the hero has none, up to 50% (`LootRules.chance`). It reads the
    existing save (defeats, owned items), so nothing new is saved.
- **Field elites** in the farming grounds may drop their district bosses' Epics (3% each).
- **Drop feedback:** an Epic shows "Epic find: …"; a Legendary shows "LEGENDARY! …" with
  a fanfare, on top of the existing rarity beams.
- **Shop weapons:** five Uncommon weapons (Dock Hook L13, Shock Baton L21, Weighted
  Knuckles L27, Riot Baton L35, Alloy Knuckles L44). Before, the shops sold no weapon
  past level 6, which made the late story a wall for shop-geared heroes.
- **Selling boss gear:** spare boss gear sells by its grade and level (`ItemRules.value`).
  Before, it was worth nothing.
- **Difficulty, measured** (harness; Oren, Mika and Riku; 2 seeds; story areas at their
  level with the shops' gear and 6 rice boxes):
  - Ordinary areas now cost 15 to 77% of the hero's HP, and boss areas 120 to 180% (3 to
    5 meals).
  - Knock-outs from level 12 on went from 6 to 1 (the final boss, 1 in 6 runs). With boss
    gear there were none.
  - South Street (levels 2 to 10) is unchanged and stays gentle for new players.
- **Unchanged:** saves (version 10), enemy stats, XP, story.
- **Tests:** 511. New: `test_item_grades.gd`; the shop, progression and UI tests read the
  refitted stats.

### Changed: the farming grounds are living fields
- **What changed:** each of the seven grounds is now a living field (`"spawning"` in
  `areas.json`, rules in `sim/FarmSpawner.gd`). The old loop was two fixed fights, then
  walking back west to refill them.
  - Up to 4 enemies stand at once, and one more comes in after each loss, so the fight
    never stops.
  - Enemies enter away from the hero (off camera where the field allows).
  - Nothing walls the hero in. The way out is always open.
  - The west end is a safe spot: enemies never follow into it, so arriving or coming
    to after a knock-out starts calm.
- **Elites:** 1 in 20 is an elite, with a gold name and an "An elite ... joins the
  fight!" toast. It has ×3 HP, ×1.25 power, and pays ×3 XP, ×3 coins and three loot
  rolls.
- **Auto battle:** in a field it goes after the nearest enemy (status "Hunting") or waits
  mid-field. It rests in the city only when hurt with no food.
- **Same income:** respawn times are tuned per ground (300 to 690 ticks) so earnings stay
  near the old loop's. Measured with the harness: Oren and Mika, 3 seeds, 10 minutes per
  ground, against the old loop.

  | Ground | Respawn | Coins/min | XP/min |
  |---|---|---|---|
  | Saltmarket Backlots | 300 | ×1.09 | ×1.07 |
  | Rail Sidings | 310 | ×1.03 | ×1.02 |
  | Harbour Stacks | 360 | ×1.09 | ×1.05 |
  | Plant Outskirts | 500 | ×1.03 | ×1.01 |
  | Network Backrooms | 500 | ×1.07 | ×1.07 |
  | Facility Annex | 580 | ×0.97 | ×0.97 |
  | Core Overflow | 690 | ×0.92 | (level cap) |

  - Scrap and Refined Alloy came out at ×0.83 to ×1.27 (few drops per run, so noisy).
  - No knock-outs in 42 runs. The old loop had one, at Core Overflow.
- **Unchanged:** the story, the refill mechanism (`StreetMemory.refill`, for any ground
  with fixed fights), saves (version 10), drops, enemies.
- **Tests:** 502. New: `test_farm_spawner.gd` covers filling, respawn, entrances, the
  safe spot, the seed, elites and their loot, other areas, and the validator. The
  grounds and auto battle tests now cover the field.

### Changed: the farming grounds and world bosses are reached from the city only
- **Owner decision:** the story and the hub content are kept apart. Iron City Central
  is the hub (`AreaRules.hub`): the only way into a farming ground or a world boss
  arena is Win's taxi in the city, and every way out leads back to it.
- **In:** the story's seven taxi stands (Depot Yard, Night Market, Port Road, ...)
  offer the city and the story areas only; the city's Win offers the story, Farming
  and World Bosses. The city ride reads "(rest, farming, bosses)".
- **Out:** walking out of a ground or an arena west arrives at the city's taxi rank
  ("< Iron City Central" at the west end); a finished world boss attempt goes "Back to
  Iron City Central"; auto battle in a ground rests in the city (heal, the kiosk's food,
  the same 10-coin fare). On the street, auto battle and a knock-out are unchanged.
- **Map:** two sections, STORY (the six districts) and IRON CITY CENTRAL (the city,
  Farming, World Bosses); a ground or arena says "Win's taxi in Iron City Central".
- **Rules:** the validator requires a ground's and an arena's one way out to be west
  to the hub, and still refuses any story area that leads into the city.
- No save, balance, drop or fare change; saves made in a ground or an arena load as
  before. Tests: 494 (new: the story's taxis never ride to a ground or a world boss;
  the Map's two sections fit late in the game).

### Fixed: spare copies of a worn item were lost on load
- Loading a save dropped every carried copy of an item that was also worn (for
  example Oren's spare padded vests), and the next save made the loss permanent.
  Since 2026-10-28 (`_load_gear`). Spares now stay in the bag; a copy of its own
  (`#n`) is still in one place, and one item named in two slots is still one item.
  Save format unchanged (version 10). Items already lost are not given back.
- Test: `test_item_safety.gd::test_spares_of_a_worn_item_survive_a_save` (492 tests).

### Added: monster art audit, credit register and licence check (documents and tools only)
- **Audit (no game change):** `docs/monster_art/ENEMY_INVENTORY.md` (all 38 enemies:
  where they fight, art source, frames, scale, credits; classified KEEP 12, REWORK 17,
  REPLACE 5, INVESTIGATE 4), `FACTION_STYLE_GUIDE.md`,
  `CHARACTER_DESIGN_SPECIFICATIONS.md` (one design per enemy from licence-checked LPC
  parts), `LPC_GENERATOR_AUDIT.md` (the generator's licence filter, what LPC can and
  cannot give a modern city), `SAMPLE_GROUP_PROPOSAL.md` (South Street Gang first,
  awaiting approval).
- **Findings:** all 224 LPC credit rows match the generator's own records at the
  pinned commit; 4 (the spiked hair) are CC BY 4.0 only; three recipe parts (open
  vest, trench coat, tabard) are never drawn because the recipes ask for a recolour
  of a part the generator ships only as colour-named files; machines and the Tunnel
  Mother cannot be made in LPC.
- **Credit register:** `tools/assets/credit_register.py build` writes
  `docs/credits/ASSET_CREDITS.csv` and `.md` (384 rows, every shipped asset) from the
  repository's credit records; `docs/credits/LICENSE_REGISTER.md` and
  `THIRD_PARTY_LICENSES.md` summarise the licences.
- **Licence check:** `credit_register.py check` validates each enemy against the
  monster-art rules and writes `docs/monster_art/LICENSE_AUDIT_REPORT.md` (today 0 of
  38 compliant: website exports and per-monster manifests do not exist yet, and no
  licence is verified at its source). 10 tests in `tools/assets/test_credit_register.py`
  (not yet run by CI).

### Changed: Win's line, and a full-loop farming measurement
- **Win's line** at Depot Yard and Night Market (it said "Anywhere you've been on
  South Street") is now "Choose a destination you've unlocked. I'll take you there."
  The Depot Yard guard test still checks everything else there is as on `main`.
- **Auto battle in a farming ground** works as soon as the ground opens on its story
  rule: no fight there has to be won first, and nothing new is saved (still version
  10). Tested for all seven grounds, straight after the unlock and after a reload.
- **Harness:** `ProgressionHarness.run_loop`, a farming session as auto battle plays
  it (rest delay, rest at home, food restocked, fares paid), for full-loop economy
  comparisons. Measured (6 simulated minutes, 6 heroes x 5 seeds, Facility Annex and
  its district x 10): no ground beats the richest story area of its district on XP,
  net coins, Scrap or Alloy, as auto battle plays (closest: Facility Annex Scrap 0.90)
  or with an assumed 10 s per trip home by hand (Facility Annex Scrap 0.99,
  Saltmarket Backlots Scrap 0.98). No drop rate changed.

### Fixed: Win's taxi no longer runs off the screen late in the story
- **Bug (live site):** every ride was added straight into the dialog, so with
  every area reached (40-odd rides) the list grew taller than the screen; the rows
  above the top could not be reached.
- **Now:** a group on the left (City, each district with a ride, Farming, World
  Bosses, each with how many rides it holds), its places on the right (story
  areas two to a row). It opens on the hero's own district with its first ride
  focused (in the city or a ground, on the furthest district), so any ride is a few
  presses away and no group needs scrolling at 640x360. Fare, rides and
  destinations are unchanged (`GameMenus.travel`, `_ride_groups`, `_ride_picker`).
- 6 tests in `test_taxi.gd`, including every ride reading in full at 640x360,
  1280x720, 1920x1080 and 360x640; checked in a browser build with every ride open.

### Added: repeat fights and auto battle in the farming grounds
- **Repeat fights:** once every fight in a ground is won, they all come back as soon
  as the hero is back at its west end (`StreetMemory.refill`, `refill_x`): walking
  back for another round, arriving by taxi or loading a save there. A rest brings
  them back too. Nothing new is saved (the won fights are forgotten, as a rest
  does), so saves are unchanged (version 10). A toast says "The fights are back".
- **Auto battle** may farm an open ground (`AutoRules.problem`): every enemy kind in
  a ground already appears in the story before its unlock point (tested). The pilot
  walks back west between rounds ("Back for another round") and never walks out;
  each round counts as a run on the auto HUD. Rewards come only from defeats and
  pickups, as by hand (tested in every ground).
- **Suggested level:** a ground's level shows as "suggested Lv N" on the taxi and the
  map, with "No level needed to enter"; the map also shows what the ground is for.
  Core Overflow says that at the level cap (50) no XP is earned.
- **Facility Annex looks its own:** a fixed kit layout (`art/kit/kit.json`
  `layouts.farm_facility_annex`) of steel gates, guard booths and a storage block from
  its district's kit, never the warehouse wall that marks Harbour Stacks.
- **Harness:** `rounds` for farming grounds. Measured at four hero levels per ground
  (2 under, suggested, 5 and 10 over; 6 heroes x 3 seeds, 3 rounds): every run clears,
  no knock-outs, and no ground beats the richest story area of its district open at
  that point on XP, coins, Scrap or Alloy (closest: Facility Annex Scrap, 0.96-0.99).
- `ZoneSim._build_solids` written shorter (same solids) to stay under the 1000-line
  limit. 8 tests (`test_farming_loop.gd`, one in `test_farming_grounds.gd`).

### Fixed: fights in an area already passed no longer hold the hero in
- **Bug:** resting (Iron City Central, Depot Yard) brings back every fight already won,
  for farming. Walking back through a story area already passed then locked the hero
  into its fights again, bosses included: no way on east, back west or home by the
  pause menu until every wave was down, as if the area had never been beaten.
- **Now:** in a street area the hero has passed (the next area east reached, or the
  area's boss beaten at the end of the line; `StreetMemory.passed`), the fights still
  come back after a rest but nothing locks: walk on, walk back, or leave by the pause
  menu, or stay and fight (`ZoneSim.fight_locked`, `ZoneSim.walk`). Its enemies keep to
  the fight's own stretch of street and no longer block the hero bodily (they still
  hit), so the hero can walk through and on unhindered. A
  fight walked away from comes back next visit; one won stays won. A toast says so when such a fight
  starts, and the arena-lock sound and camera lock are left out.
- **Unchanged:** areas not passed yet, farming grounds and world boss arenas still wall
  the hero in; rewards, XP and drops; auto battle's farming loop.
- The gate rule now lives once, in `StreetMemory.gate` (`ZoneSim.exit_locked` and
  `StreetMemory.pending` use it).
- 7 tests in `test_passed_areas.gd` (462 in all); 4 of them fail on the old code.

### Added: the seven farming grounds
- **Seven optional areas** in `areas.json` (`"kind": "farm"`), off the story street,
  each with its district's enemies, one elite and no boss, two encounters of two waves,
  and its own generated sky and kit layout. Line-ups below; levels, encounter counts
  and line-ups are **provisional** until the owner approves them.

  | Ground | Level | Region | Opens when | Enemies (elite last) |
  |---|---|---|---|---|
  | Saltmarket Backlots | 4 | South Street | Rusted Corner reached | Smogling, Tar Rat, Bottle Thrower, Pipe Brute, Smog Warden |
  | Rail Sidings | 9 | South Street | Smokestack Refinery reached | Dock Thug, Market Punk, Rail Bruiser, Refinery Enforcer |
  | Harbour Stacks | 15 | Port District | Container Yard reached | Stevedore, Dock Slinger, Dock Thug, Port Guard |
  | Plant Outskirts | 22 | Industrial District | Waste Pools reached | Patrol Unit, Hazmat Sprayer, Plant Guard |
  | Network Backrooms | 29 | The Black Network | Counting House reached | Network Runner, Network Enforcer, Ring Fighter |
  | Facility Annex | 37 | The Core Facility | Machine Hall reached | Facility Trooper, Hazmat Sprayer, Patrol Unit, Riot Trooper |
  | Core Overflow | 50 | Main Control Centre | Director Wiroj defeated | Facility Trooper, Patrol Unit, Core Sentinel |

- **Travel:** Win's taxi lists the open grounds under Farming for the usual 10 coins,
  and the map shows them in its Farming row (both from F0). The one way out on foot is
  west to Depot Yard; the pause menu's Return to Iron City Central works there.
- **No Hybrids** in any ground: Hybrids are sick workers, not enemies to hunt
  (`docs/STORY_BIBLE.md`). Loot, XP and drop rates are the enemies' own; nothing in
  `enemies.json` changed.
- **Measured** with `ProgressionHarness.run_area` (6 heroes x 5 seeds, shop gear, at the
  ground's level): every ground clears 30/30 with no knock-out, and pays less XP, coins,
  Scrap Metal and Refined Alloy per minute than the richest story area of its district
  open at that point. Four line-ups were thinned to get there.
- Scenery: `gen_environment.py` and `kit_import.py` add `environment/farm_*` and
  `kit.areas.farm_*`; no existing asset or manifest entry changed.
- Story Bible: the seven names (proposed) and the no-Hybrid rule.
- 9 tests in `test_farming_grounds.gd`; `test_area_rules.gd`, `test_south_street.gd`
  and `test_main_city.gd` now allow for the grounds (455 in all).

### Fixed: the pause menu's return now goes to Iron City Central
- **Bug:** the pause menu's only return item, "Return to Depot Yard" (Recall), sent the
  hero to the story's starting area; the city needed a separate "Go to Iron City
  Central" item.
- **Now:** one item, **Return to Iron City Central**, takes the hero to the city's taxi
  rank from any area (story areas, Depot Yard, world-boss arenas outside an attempt),
  free and rested, with the same checks (not in a fight, not while knocked down, not
  during a world-boss attempt). It uses the existing city ride (`Game._go_to_city`).
- **Unchanged:** Depot Yard is still the start area; auto battle's trip home, a
  knock-out and the return after a world boss still go there; taxi rides and fares.
- Regression test `test_return_to_the_city_from_anywhere_lands_at_the_rank`; updated
  `test_recall.gd` and the city's pause-menu test (437 tests).

### Added: area kinds and farming-ground unlocks (F0)
- **`client/sim/AreaRules.gd`** (pure): an area's kind (`street`, `city`, `world_boss`,
  `farm`) and region, the farming grounds, and whether one is open. Kinds and regions
  of existing areas are derived from the data they already have (`city_area`, the
  `world_boss` flag, the street's districts); no existing area entry changed.
- **Farming-ground fields** in `areas.json`: `kind`, `region`, `purpose`, `unlock`
  (`{"reached": a story area}` or `{"defeated": a boss}`). Unlocks read the saved
  areas reached and enemies defeated, so the save format is unchanged (version 10).
- **Validation** (`AreaRules.problems`, called by `ContentDB.validate`): a farming
  ground is off the street, nothing leads into it, its one way out is west to Depot
  Yard, it is no place to rest, and its region, purpose and unlock rule are valid.
- **Win's taxi** lists open grounds under a Farming heading (only once one is open),
  for the usual 10-coin fare; **the map** gets a Farming row the same way.
- No farming ground is added yet: the game plays exactly as before.
- 9 tests in `test_area_rules.gd` (446 in all).

### Added: UI test harness (phase U0)
- **UI audit** (`client/tests/ui/UiAuditRun.gd`, `UiAuditSession.gd`, detectors in
  `UiAudit.gd`): every screen (title, hero creation, HUD, pause, Character, Bag,
  Skills, Quests, Map, Settings, item card, shop, conversation, taxi, knock-out)
  at four landscape window sizes (1280x720 mouse; 640x360, 844x390, 960x440
  touch), as is, with 150% text and with 40% longer strings. Checks off-screen,
  truncated and too-small text, keyboard focus, covered controls, touch target
  size and placement, touch buttons over people or the lane, and key hints on
  touch.
- **Baseline ratchet** (`client/tests/ui/baseline.json`, 351 known problems): CI fails
  on a new problem and on a fixed one still listed. Runs in the `godot-tests` job;
  report uploaded as the **ui-audit** artifact.
- **Detector self-tests and real input** in `test_ui_audit.gd` (15 tests, 436 in all).
- **Browser screenshots** (`tools/web-smoke/ui-shots.ts`) at the same four sizes,
  checking that keys, a mouse click and a touch reach the game; uploaded as the
  **ui-shots** artifact. See `docs/UI_TESTING.md`.
- Landscape-only: no portrait window size is tested.

### Added: measurement harness for progression and economy (`client/tests/harness/`)
- **Measures only**, from the game's own rules: it changes no game data, no save and
  no balance value, and refuses to write its report inside the repository.
- **Story XP model** (exact arithmetic over the data and `LevelRules`): one story pass
  ends at level 48, 23,431 XP short of 50; scenarios for no level-gap multipliers,
  each boss once more, and every area twice.
- **Simulated yields**: `ZoneSim` played by `AutoPilot` with fixed seeds, per area,
  gear profile (shop or boss gear, chosen from the data) and boss-only runs: time,
  XP, coins, Scrap Metal and Refined Alloy per minute, food, damage, knock-outs.
- **Boss reward comparison scenarios** (current, reduced repeat rewards, separate
  rematch channel). Their parameters in `harness_config.json` are comparison values,
  not approved game values.
- Run: `godot --headless --path client --script res://tests/harness/HarnessRun.gd --
  --out=<folder outside the repository> [--quick]`. See `docs/HARNESS.md`.
- 5 unit tests in `test_harness.gd` (421 tests in all).

### Added: Iron City Central, the city hub (`main_city`)
- **A separate, safe city map**, off the story street. It is not Depot Yard, not a story
  stage and not a farming area. Arriving heals the hero and refills the streets,
  exactly as at Depot Yard.
- **Places, west to east:**
  - Taxi Rank, with Win;
  - Notice Board: current job, world bosses once the story unlocks them, planned
    services;
  - Market: a self-service kiosk with exactly Ama's stock and prices;
  - Workshop: a workbench that opens the existing upgrades;
  - Training Yard: dummy and practice weapons;
  - Trading Post and Guild Hall signs, marked planned with nothing to press;
  - a one-way gate east into Depot Yard.
- **Getting there:**
  - Win's first ride at every stand;
  - "Go to Iron City Central" in the pause menu: free, with Recall's checks, and never
    during a world-boss attempt;
  - its own row on the map.
- **Unchanged:** Depot Yard (its data, art and NPCs are byte-identical to before, and a
  test checks that), every story area, Recall, auto battle's trip home, the return
  after a world boss, items, drops, prices, upgrade costs and the save format (v10).
- **Every taxi stand:** rides are grouped by district and the list scrolls. With every
  area reached, the old list (33 rides) was taller than the screen. Rides, fares and
  unlock rules are unchanged.

### Fixed: loading a save made off the story street unlocked the whole street
- **The bug:** a save made in a world-boss arena (and, without this fix, in the new
  city) loaded with every story area marked as reached. That opened Win's rides up to
  the final chapter, even for a level 1 hero.
- **The fix:** loading now walks the street only when the save was made on it. Saves
  made on the street load exactly as before, from every version 5 to 10.
- **Tests:** `test_city_saves.gd` covers the city, all three world-boss arenas,
  versions 5 to 10, and a normal save on the street.

### Verification
- gdformat and gdlint pass.
- Godot import exit 0; **416 tests passed, 0 failed**.
- Asset pipeline: 39 tests OK; asset validation reports 0 problems.
- Web export succeeds: `index.pck` grows by 43.7 KB.
- The browser smoke test passes locally.
- Backend not run: no change there.

### Added: City hub and farming blueprint (plan only, no gameplay change)
- `docs/CITY_AND_FARMING_BLUEPRINT.md`: an audit of the current state, verified
  against the code and data at `f8bc743` (393 tests passing). It plans the city hub
  (Depot Yard widened, same id), seven data-only farming grounds that reuse
  existing areas and enemies, boss rematch arenas, and what the later unified drop
  table needs.
- It records a gap between the design target and the repository: 50 stages are
  targeted, but the repository has 6 chapters and 30 story areas with 11 story
  bosses. The owner decides this before Phase 2.
- Found, not fixed: the item card shows no source for the six world-boss
  legendaries. README and GAME_DESIGN figures are out of date.

### Changed: Harbourmaster Chen's crane drops real, container-sized drops
- **Before:** the drop was small. Its footprint was 60x20 px, so a short
  side step dodged it.
- **Container size:** each drop is a full container, 100x36 px. The hero
  has to really get out from under it.
- **How many:** one falls on the hero. When Chen is enraged, two fall: one
  on the hero, one within 150 px, 14 ticks later. He is a stage boss, so
  it stays at that.
- **Look and feel:** each container is drawn as wide as what it hits and
  hangs from two crane cables. A sharp outline marks the danger zone from
  the first frame, and every landing shakes the screen.
- **Volleys for any boss:** hazards can take a volley (`count`, `spread`,
  `stagger`, all validated). `BossMechanics.volley` picks the spots from
  the zone's seeded RNG and never stacks drops, so there is always a way
  out.
- **Tests:** `test_chapter_two.gd`:
  - checks one drop, two when enraged, the first on the hero, staggered
    landings, no stacking and a safe spot;
  - the enraged test now checks the phase's own hazard.

### Fixed: bosses grew weaker in their later phases
- **The bug:** a boss phase's `power`, `speed`, `cooldown` and
  `heavy_chance` are written on the enemy's base (level 1) scale. They were
  applied raw, which threw away the boss's level scaling. At 66% health the
  Tunnel Mother (Lv 32) fell from power x3.48 to x1.05: its light blow went
  from 45 to 14 and its heavy from 90 to 25. Every levelled boss had the
  same problem, story bosses included.
- **The fix:** `LevelRules.phase_stats` runs a phase through the same level
  scaling as the boss's own block (`enemy_stats`, `enemy_ai`), and
  `ZoneSim._check_phases` uses it. At Lv 32 the Mother's phases now hit for
  48/88 and 50/115, and it moves and attacks faster. At level 1 a phase is
  exactly what the data says.
- **Content rule:** the validator rejects a phase that softens its boss.
  Lower power, speed or heavy chance than the base is rejected, and so is a
  longer cooldown.
- **Tests:** `test_boss_phases.gd` checks every phase of every boss at levels
  1-55, the fight in a zone, and the validator. The zone test fails on the
  old code.

### Changed: world bosses are fixed, like field bosses in an MMO
- **The rule:** every world boss now fights at its own fixed `level`, with a
  fixed health pool, whoever comes. Nothing scales to the hero, and no level
  is asked at the door. Heroes grow strong, gear up and band together to take
  it on.
- **The Tunnel Mother:** fixed at Lv 32, no longer hero level +2 with a floor
  of 26. It is built for 3 players and now has a kill reward (3000 coins,
  refined alloy, a 15% roll each for Mother's Fang and Mother's Heart).
  Personal tiers are shares of one player's third of the pool.
- **The Iron Colossus (Lv 52) and Subject Zero (Lv 55):** no longer turn away
  heroes below Lv 40 and Lv 48. Win's ride shows the boss's level.
- **Content rules:** `world_boss.json` needs a `level`. `min_level`,
  `level_above_hero` and `min_hero_level` are rejected.
- **API:** `WorldBossRules.level` and `pool` no longer take the hero.
- **Tests:** `test_world_boss.gd` covers the fixed level and pool, entry with
  no level gate, and the validator.

### Changed: bosses never flinch, stagger or fall, except to a crowd
- **Bosses and mini-bosses are unshaken** (`Fighter.unshaken`). No blow
  makes them flinch, stagger, reel from a parry, stun from a guard break or
  fall to a knockdown or a thrown weapon. They still take the damage, and a
  parry still leaves them open to a counter.
- **The break:** the damage a boss takes fills a hidden break meter. The
  meter drains 6% of the boss's max HP every second. When it reaches 35% of
  max HP, the boss is broken: knocked down, with "BREAK!" and a hard screen
  shake. It cannot be broken again for 20 s.
- **Who can break a boss:**
  - **Rarely possible:** a hero fighting alone at the boss's level never
    deals damage faster than the meter drains. In simulated fights, an
    at-level hero broke the boss 0 times, and a hero 20 levels above it
    broke it now and then.
  - **Built for crowds:** a break is meant for a crowd beating on the boss
    together. That is the online case.
- **Replaces** the earlier three-knockdown-blows rule.
- **Ordinary enemies, elites and the hero** are unchanged.
- **Tests:** `test_boss_unshaken.gd`.

### Added: bosses sometimes grab weapons off the street
- **What happens:** in a fight, a boss or mini-boss may go for a weapon on
  the ground. It does not happen every time.
  - **When it looks:** every few seconds (`ai.grab.every`). It considers the
    nearest weapon only if it is in range and the boss would reach it before
    the hero, so a boss never takes a weapon from under the hero's feet.
  - **Whether it goes:** it rolls its own chance (`ai.grab.chance`).
  - **The warning:** a gold "!" over its head shows it is going. The hero can
    race it to the weapon or knock it down.
  - **Giving up:** the boss stops when the weapon is gone, or after 2.5
    seconds of walking.
  - **Once it has the weapon:** the weapon's name flashes over the boss. It
    swings the weapon for its light blows but keeps its own signature heavy.
    The weapon wears out and breaks as usual, and the boss drops it when
    knocked down.
- **Which bosses:** nine human bosses, each tuned to its character. Big Sak
  and the Ringmaster are the most eager; the Pit Champion, a boxer, rarely
  bothers. Robots and hybrids never grab.
- **Content rules:** `ai.grab` is validated: bosses only, with
  0 < chance <= 1, and `every` and `range` at least 1.
- **Refactor:** street-weapon placement moved from `ZoneSim` to
  `StreetWeapons`.
- **Tests:** `test_boss_grab.gd` covers the first look, the walk and pickup,
  never taking a weapon from under the hero's feet, giving up, the share of
  looks that become a grab, the boss keeping its own heavy, and the
  validator.

### Fixed: E always throws the weapon in hand
- **The bug:** with a weapon in hand, E threw it only when nothing lay
  underfoot. Standing on a pile (where foes drop their weapons), E swapped
  for one of them instead, so the throw seemed not to work.
- **The fix:** for the hero, E with a weapon in hand always throws it; the
  next E picks up from the pile. Enemies still swap or put weapons down. The
  "[E] Pick up" highlight no longer shows while the hero holds a weapon, and
  the tutorial line says "Press E again to throw it."
- **Tests:** a pile underfoot does not stop the throw, and the next press
  picks up from the pile.

### Fixed: street weapons can always be picked up
- **The bug:** a weapon could be scattered close enough to an NPC (the taxi
  driver, the vendor) that, from where the hero stood to pick it up, the NPC
  was within talk reach. E talks before it picks up, so it opened the taxi or
  the shop instead. A weapon could also be pushed off one solid into another.
- **The fix:** `ZoneSim` now owns `TALK_REACH`, and `NPC_CLEARANCE` is
  derived from it (talk reach + pickup reach + a margin). A weapon spot that
  is near an NPC or has no room to stand is rolled again (`_weapon_spot`).
  `Bodies.clear_spot` keeps pushing until the spot is clear of every solid.
- **Tests:** every area over 120 seeds: each weapon has room around it, can be
  reached from where it lies, and no NPC can be talked to from anywhere it can
  be picked up. The test fails with the old placement.

### Fixed: the street no longer ends early in narrow fight arenas
- **The bug:** in a fight, the camera is fenced to the locked arena. When that
  arena was narrower than the screen (the Pit Champion's at the Fight Club, or
  any arena on a wide browser window), the camera kept the left fence and
  showed past the right. The road and sidewalk then stopped short of the edge.
  It happened only in some arenas and window shapes, so it looked random.
- **The fix:**
  - A narrow range now grows evenly to the view's width and is moved back
    inside the street (`ZoneView.camera_limits`, a pure function).
  - The road and sidewalk also run 640 px past both ends of every street
    (`Scenery.GROUND_OVERRUN`), so no camera position or window shape can show
    a gap.
- **Tests:** every area and every fight arena, on 16:9 and wider windows, is
  checked to stay on the street with room for the whole view.

### Added: a hotbar the player lays out, and a Skills screen
- **Before:** the seven slots were fixed (attack, four skills, two foods). Food
  could not be moved, and when it ran out no other food could take its place.
- **Now:**
  - Any slot takes the attack, one of the hero's skills or any consumable, in
    any order (say, food on 3).
  - Each one is on the bar once: putting it on a slot moves it there and swaps
    out what was there.
  - The layout is saved per character (`PlayerProfile.hotbar`). Without one,
    skills.json's default for the hero is used.
- **Items and skills stay apart:**
  - The **Bag** has a HOTBAR row that only takes food from the bag.
  - The new **Skills screen** (V, with a menu-bar button and a pause-menu entry)
    lists the attack and the hero's skills. Each card shows its energy,
    cooldown, unlock level, help and current key, and its row only takes skills.
- **Editing either row:**
  - Drag onto a slot.
  - Drag a slot onto another to swap them, or back onto the list to empty it.
  - Right-click a slot to empty it.
  - Or point at something and press 1–7.
- **Running out:** food that runs out stays on the bar, tinted, until other food
  replaces it. An empty slot does nothing when pressed.
- **Rules:** in `sim/HotbarRules.gd`, shared with the server: only the hero's own
  skills and consumables are allowed, nothing goes on twice, and saved layouts
  are cleaned on load.

### Added: mini-bosses on the map, with map icons
- **Route card and map screen:** both now show where every boss waits, before the
  area is reached. A horned orange skull marks a mini-boss and a round red skull
  marks the district's boss. Both turn grey with a green tick once beaten. Who a
  boss is stays hidden until the hero gets there ("A mini-boss waits here").
- **New pixel-art map icons** (`tools/assets/map_icons.py`): mini-boss, boss,
  both beaten, and goal flag. They are small, about 7 px, so they sit on the
  route without crowding it. The route card and the map screen's boxes and
  legend all use them.
- **Smaller route card:** 152×36. The hero is a small orange marker over an
  orange dot. A town is a teal dot (no house, so nothing stacks on the first
  node), and the gold flag alone marks the goal.
- **`MapRules`:**
  - `kind_of` tells a town, a plain area, a mini-boss and the district's boss
    apart.
  - `route` builds the HUD route from the rules, so the card only draws it.
  - `about` gives every area's kind.
  - The card rebuilds its route four times a second, not every frame.

### Changed: the HUD map strip is a route card players can read at a glance
- **Before:** a row of unlabelled dots with no district name and no count.
  Players could not tell where they were.
- **Now** (`MiniMap.gd`, top right), two lines:
  - The district, then the area and its level ("SOUTH STREET   Depot Yard ·
    Lv 1").
  - The route, one node per area: ⌂ town, ○ area (filled once reached), an
    orange ▲ where the hero is, and the district's last area as a red ☠ BOSS
    (grey with a tick once beaten). The goal flies a gold flag. The way
    travelled is solid and the way ahead dashed.
  - A red bar on the road just east of the hero while the way on is still shut.
  - "GOAL" with an arrow, under BOSS, when the goal lies in another district.
  - A long district and area name never run off the card: the area name is
    shortened and the level always shows.
  - Under each node, the area's number in the district (1, 2, 3 …, the hero's in
    orange). The names stay, because quests and the story send the hero to
    places by name.
  - Hovering a node names its area, its boss and whether it is the goal. A tap
    still opens the map.
- `MapRules.boss_of` is now public.

### Fixed: nothing a player owns can be lost
- **Safe saves:**
  - A save is written to a temporary file and read back before it replaces the old
    one. A full disk or a quota error never truncates a good save.
  - The previous save is kept as `<id>.json.bak`. If the save cannot be read, the
    newest of the `.tmp` and `.bak` copies is used.
- **Unreadable characters are kept:** a corrupt save, or one from a newer build, is
  shown as "This save cannot be read" on the Characters screen. It is not hidden.
  - It still holds its slot, so a new character can never be made that then
    fails to save.
  - It can be deleted, which moves it aside.
- **Unknown items are kept:**
  - Items this build does not know (renamed, removed, or from a newer build) are
    parked in `unknown` with their upgrades, saved unchanged, and come back when a
    build knows them again.
  - Worn gear that no longer fits its slot goes to the bag. Before, it vanished.
- **Ground loot:**
  - Loot left on the ground is picked up automatically on leaving an area (taxi,
    recall, getting up, auto battle).
  - Picking something up saves at once.
- **More saves:** the game also saves every 20 seconds and when the tab is hidden or
  the window closes.
- **World boss:** a fight cut short by a closed tab or a crash is banked the next
  time the game starts.
- **One tab:** only one browser tab may hold the saves (Web Lock). A second tab says
  "Already open" and writes nothing, so two tabs can no longer undo each other's
  progress.
- **Old save:** the old single save can never overwrite a character it was already
  imported as.
- **Money rules:** the knock-out penalty and all fares (taxi, world boss ride, auto
  battle's ride back) moved to `sim/EconomyRules.gd`, so the server can apply the
  same rules.

### Fixed: upgrade review
- **Loading a save:** upgrades are kept only on a copy of its own (`#n` key) that
  the hero still has. A level on a plain item id would upgrade its whole stack
  again.
  - A copy found both worn and in the bag is kept in one place, the worn one.
  - A new copy never takes a key left over from an old upgrade or pity entry.
- **Item card:**
  - The comparison counts upgrades on both sides ("Compared with Foreman's Wrench
    +5").
  - A carried upgraded copy shows "Upgraded +N" and what it adds.
  - The note under the upgrade now says upgrades stay with the item. It used to
    say they stay with the slot.
- **Losing an upgraded copy:** the Sell tab shows "+N" on upgraded copies.
  Discarding one asks "Discard +N for good?".
- **Workbench:** says why nothing happened on an item that is already fully
  upgraded, or on an empty slot.

### Added: up to four characters per account
- **Before:** there was one save. Making a new hero replaced it, so a level 20 hero
  was lost when a new one was started.
- **Now:** every character has its own id and its own save file
  (`user://characters/<id>.json`). Making a new hero never touches another.
  - **Id:** 16 random hex digits, 64 bits, from `SaveStore.new_id()`.
  - **Rules:** `sim/RosterRules.gd` holds the id format, the limit (`max_characters`
    in progression.json, 4) and the rule that names must differ within an account,
    so the server can apply the same ones.
- **Title screen:** Continue plays the character played last. **Characters** lists
  every character with its look, hero, level, area and when it was last played.
  Click a card to choose it. Play, Enter or a double click plays it. A free slot
  makes a new character.
  - Delete asks a second time, by name.
  - A deleted character's file is moved to `characters/deleted/`, never erased.
- **Old saves:** the single save of earlier builds becomes the first character the
  first time the game starts. It is kept as `save.imported.json`.
  - Its id comes from its content, so it is never imported twice, even if the
    rename fails or it is carried over from the old data folder again.
  - An unreadable old save is set aside as `save.unreadable.json`.
- **Full account:** a fifth character is refused at save time, and character
  creation says that all slots are in use.
- **Separation:** items, upgrades, coins and quests belong to one character. A test
  checks that nothing leaks between two characters. A save whose content names a
  different id from its file name is refused.
- **Online plan:** BLUEPRINT.md sets out how the server will key characters and item
  copies, by (character id, copy key).

### Fixed: upgrading one item no longer upgrades every copy of it
- **Before:** upgrades were kept per item id, and identical items stack under one
  id. Upgrading the worn wrench to +10 showed, and gave, +10 on all 17 wrenches in
  the bag.
- **Now:** an upgrade belongs to one copy.
  - Untouched items still stack.
  - The first workbench attempt on a worn item makes it a copy of its own, under the
    key `"<item id>#<n>"`. Identical items in the bag stay +0.
  - An upgraded copy has its own cell in the bag and its own line in the Sell tab.
- **Save v10:** each old shared upgrade goes to one copy, the worn one if there is
  one, else one from the bag. The other copies are +0.
- **Code:** `ContentDB.item()` and `sources()` accept copy keys.
  `PlayerProfile.owned()` counts every copy.

### Fixed: blows land when the fist is out, not while it is raised
- **Before:** an attack animation played at an even pace over the whole move. A
  haymaker's damage showed while the fist was still raised beside the head.
- **Now:** each LPC attack animation names its contact frames (`contact` in the
  recipe and manifest). The game plays the wind-up over the move's start-up, the
  contact frames while the hit can land, and the rest over the recovery.
- **Who gets it:** every character, heroes and monsters, for light, heavy, swing
  and stab.
- **Tests:** the contact frames show on the hit tick, and they are where the hand
  reaches furthest forward.

### Added: selling, and a shop screen that always shows its Buy button
- **Sell tab** (Q/E switch tabs). A shop pays 30% of the price (`sell_rate` in
  progression.json). It never buys evidence or worn gear. Rare gear and upgraded
  items ask "Sure?" first.
- **Upgrades:** once the last copy of an item is sold or thrown away, its upgrades
  go with it, so an item bought back starts at +0.
- **Deal bar:** the amount, total and Buy/Sell button sit at the bottom of the shop
  window, under the scrolling item card. Before, a long card pushed the Buy button
  off screen.
- **Amounts:** food and materials can be bought or sold several at a time with
  -, + and Max (Left/Right on the list). Gear is bought one at a time.
- **Code:** the shop has its own screen (`ShopScreen.gd`, with the window's ×
  button). Its rules live in `sim/ShopRules.gd` (buy by amount, `sell`,
  `sell_price`, `affordable`) so a server can run the same ones later.

### Added: drag and drop in the bag
- Drag gear from the bag onto its slot, or onto the hero, to wear it. Drag worn gear
  onto the bag to take it off.
- While dragging, the slots the item can go to light up.
- Right click wears gear, eats food, or takes worn gear off, without opening the
  card.
- `tools/web-smoke/shots.ts` gains mouse `down`/`move`/`up` steps for drag shots.

### Fixed: skills and heavy blows are thrown with the right hand
- The `heavy` animation, played by heavy attacks and most skills, was LPC's `slash`.
  In side view that move strikes with the far arm, so fighters punched, and swung a
  held weapon, with the left hand.
- `heavy` is now built from the right-hand half-slash for every LPC character,
  monsters included:
  - a wind-up;
  - the right fist raised beside the head and held a beat, borrowed from spellcast
    like the weapon swing;
  - the strike forward;
  - a follow-through.
  The left fist stays at the chest, and a held weapon stays in the right hand.
- A pipeline test fails if any blow is again built from a move that strikes with the
  left arm.

### Fixed: upgrades stay with the item
- Upgrades now belong to the **item**, not the equipment slot. Save v9 moves each
  slot's level onto the item worn there. A +9 weapon taken off keeps its +9 in the
  bag, and the empty slot no longer shows a +.
- The worn slot's +N updates the moment an upgrade lands, without reopening the menu.
- Thirty-four pieces of gear that borrowed another item's picture now have their own
  icon (`tools/assets/gear_icons.py`).

### Changed: every screen does one job
- Character (C), Bag (B), Quests (O), Map (M) and Settings each open in their own
  window with an icon, a key cap and a × button, instead of sharing one tabbed pause
  window. A screen's key toggles it.
- Esc opens a short pause menu: Resume, the five screens, return home, save, and
  save and quit.
- The HUD gets a small menu bar: five 20x20 icon buttons, bottom right, with the
  key in each tooltip (`tools/assets/menu_icons.py`).
- The AUTO switch is a small round icon button. It glows, and its arrows turn,
  while auto battle runs. The status and tally text lines are gone from the HUD;
  the tally sits in the tooltip.
- Auto battle messages are shorter and plainer ("Auto on. Move or attack to take
  back control.").

### Changed: weapon blows and throws raise the weapon beside the head
- A new body animation, **`swing`**, plays for every weapon blow and throw:
  - bottle, plank, pipe, machete, chair, frying pan, wrench and bat;
  - the hero's weapon throw, and the bottle lob of the enemies who throw.
- **The motion:** wind up, raise the weapon beside the head, bring it down
  forward, level with the ground at the hit, then follow through. The left fist
  stays at the chest.
- **Who gets it:** every LPC character (heroes, enemies and anyone added later). It
  is built from LPC's half slash, with the raised frame borrowed from LPC's
  spellcast.
- Painted custom sheets fall back to their light attack.
- **Grip:** the weapon's angle follows the swing, and the fist is drawn over the
  handle, so the grip is always in the hand.
- **New `lpc_build.py` option, `borrow`:** puts a frame of another LPC move into an
  animation. It can erase parts of that frame and patch in pieces of others.
- Tests cover the swing's wind-up, raise, hit and follow-through, the fallback,
  and that every armed body has a hand socket per frame.

### Changed: the gallery is a proper browsing screen
- The title's **Characters** button is now **Gallery**. Before, items and characters
  were drawn over each other and the page could not scroll.
- **Characters tab:**
  - The roster on the left, grouped into heroes, people, enemies and bosses, each listed
    by name.
  - The chosen character stands large on a stage, with a button for each animation.
    One-shot moves return to idle.
  - Its source, licences and artists are shown below.
- **Items tab:**
  - Every item as slots, grouped by rarity (with counts) and sorted by type and name.
  - The chosen item shows its card and how it looks lying on the street.
- Works with keyboard and gamepad: arrows move, Q/E switch tabs and Esc goes back. The
  lists scroll to follow the focus.
- A UI test checks every character and item is listed, that selecting one plays it,
  and that the layout fits the screen.

### Changed: Riku has a new streetwear look, built from LPC
- Riku the Boxer is now built from LPC parts like the other heroes, so he has the same
  proportions and face style as the team.
- His outfit:
  - a white snapback with a hot-pink brim and a gold badge;
  - a hot-pink open top over a white tee, with a gold chain;
  - charcoal cuffed pants and white shoes.
- The owner-supplied sheets are no longer used.
- **Two new recipe options in `lpc_build.py`** restyle LPC parts without adding frames:
  - A recolour can give its own palette (hex colours, darkest first), for colours LPC
    lacks, such as hot pink.
  - `"cap"` turns the top of the hair layer into a snapback, shade for shade. The brim
    goes at the front in side views and along the crown in front views; it is left off
    when the hero lies on the ground.

### Added — City map
- **Map tab** in the pause window; **M** (gamepad: press the right stick) opens and
  closes it.
  - Shows where the hero is: the area, its level, and its district with the hero's place
    in it (e.g. "Port District 2 / 4").
  - Shows the goal: the tracked quest's area, the giver once the quest is done, or the
    next quest's giver.
  - The street is laid out in six districts, one row each, plus the world boss arenas
    once unlocked.
  - Each area's level is coloured by danger. The map marks the hero, the goal, towns
    (shop, quests, taxi) and bosses (green once beaten).
  - Only areas the hero has reached, and the next one east, are named. Further areas
    show `???`, and so does a district with nothing known.
  - Moving across the boxes shows what is known of each area: services, the boss, and
    why a gate is still shut.
- **HUD map strip** under the area name:
  - top line: the district's areas as dots, with the hero and the goal (or an arrow
    pointing to it);
  - bottom line: this area from west to east, with the fights still to win, a shut
    gate, and where the hero stands.
  - Tap it to open the map.
- Entering an area now also names its district, e.g. "Saltmarket Street · South Street
  2/11".
- **Data:**
  - `areas.json` `districts` defines the districts.
  - Every quest objective names its `area`.
  - `ContentDB` checks that districts run in street order and that each quest's area
    actually fields its target.
- `MapRules` (`client/sim/`) is pure and saves nothing new. Tests are in
  `tests/unit/test_map.gd`.

### Added — Group world bosses: The Iron Colossus and Subject Zero (decision D14)
- **The Iron Colossus**: Kraisorn's prototype security walker, woken in the Old Scrapyard.
  - For heroes of level 40 and up; it fights at level 52.
  - Built for 5 players; out every 6 hours.
  - Mechanics: lasers, shocking floor plates and falling scrap, a shield phase, and Core
    Sentinels called in.
- **Subject Zero**: the first worker The Core changed, broken out of the Sunken
  Reservoir.
  - For heroes of level 48 and up; it fights at level 55.
  - Built for 10 players; once a day at 20:00 Thailand time.
  - Mechanics: sludge, steam and lasers, a shield in its last phase, and Hybrid Brutes.
  - Both unlock after Director Wiroj, and each phase brings new heavy blows.
- **Group-sized pools, two kinds of reward** (`WorldBossRules`):
  - **Personal tiers** are measured against one player's part of the pool (the pool
    divided by the players it is built for). A player who pulls their weight earns
    every tier whatever the others do.
  - **The kill** is paid to everyone who fought, once the whole pool falls within the
    round.
- **Four new legendaries, rare and hard to get:**
  - Colossus Core and Piston Gauntlets (level 45);
  - Zero's Mantle and The Iron Legacy (level 50).
  - The top personal tier rolls them at 1–2%, the kill at 3–8%. A test checks the drop
    rate over 400 kills.
- **Built for groups, on purpose.** Measured with the auto-battle pilot, a level 50 hero
  alone deals about 6–13% of their part per Colossus attempt and 5–7% per Subject Zero
  attempt even in full end-game gear, and is usually knocked down. Alone, these bosses
  cannot be killed within a round. Their kill drops become reachable when online play
  arrives (IL-7), with the same rules on the server.
- **One schedule per boss** (`offset_minutes`); Win's taxi lists every unlocked boss
  with its level and group size. **Save version 8** keeps a round per boss and moves a
  version 7 round to the Tunnel Mother.
- Tests: the level gate and fixed level, Subject Zero's daily opening, tiers by one
  player's part, the kill paid once, the rarity of the drops, and the v7 migration.

### Added — World boss: The Tunnel Mother (decision D13)
- **The Tunnel Mother**, a giant mutant grown from The Core's sludge, rises in **The
  Great Drain** on a real clock: every 3 hours, for 1 hour. It unlocks once Unit K-7 is
  beaten. While a round is open, Win's taxi offers the ride, and a toast announces it.
- **One health pool per round**, 14 times a boss of her level. Each attempt lasts 2½
  minutes, and the damage adds up across attempts until she falls. She fights two levels
  above the hero (minimum 26), so she is worth fighting from Chapter 4 to level 50.
- **Five reward tiers** (5%, 15%, 35%, 60% and 100% of the pool dealt), each paid once
  per round. Coins grow with her level, and the higher tiers can roll the two new
  legendaries: **Mother's Fang** (weapon) and **Mother's Heart** (charm).
- **Her mechanics:** sludge geysers (the new `sludge` hazard kind) and Tar Rat broods,
  both faster as she weakens, with a new heavy attack in each of her three phases.
- **Attempts:** a results screen after each one shows the damage, the round so far, the
  next tier and what was won. Being knocked out there costs nothing. The HUD shows the
  attempt's clock and how much of her is left. Auto battle is not allowed against her.
- **Save version 7** keeps the round's progress; older saves start fresh.
- **Ready for online (ARCHITECTURE D8):** `WorldBossRules` and `WorldBossRun` are pure,
  with the time passed in. At IL-7 the server keeps one pool for all players using the
  same rules.
- **Bosses no longer show their name overhead.** The boss bar already shows it and the
  level, and on a giant boss the overhead label was huge.
- **Measured** with the auto-battle pilot and no gear: one attempt takes 12–22% of the
  pool at every level from 26 to 50, so a round takes about seven attempts, fewer with
  gear.
- **Tests:** the round clock; the unlock; level scaling; tiers paid once per round and
  reset next round; an attempt fighting the round's pool; ending on the clock; the taxi
  offering it only while open; the results screen instead of the game-over; the arena
  never entered without an attempt; and the round surviving a save and v6 migration.

### Added — Final chapter: The Iron Legacy, and the Epilogue (IL-5: main story complete)
- Four areas past the Control Room, open once Commander Arthit is down:
  - **Core Approach** (level 42)
  - **Cooling Tunnels** (44)
  - **Reactor Walkway** (46)
  - **The Core Chamber** (48)
- **Dr. Pim** gives the last quests: The Last Door, Cooling Down, The Walkway and The
  Iron Legacy. **Ama** brings South Street's supplies to the front line, selling level
  42–44 gear, and Win's taxi waits at the approach.
- New enemies: the **Core Sentinel** (elite machine Wiroj built to guard himself) and the
  **Hybrid Brute** (the longest-exposed workers).
- **Director Wiroj**, at the level cap (50), in three phases (story bible §4):
  1. His own blows, each heavy one announced.
  2. Below 70% health, the chamber's defences come up in turn: a steam vent, shocking
     floor plates, a sweeping laser. He waits behind a shield, untouchable for 7
     seconds, then the system resets for 5 seconds and he can be hit.
  3. Below 30%, the defences fail and he fights desperately: long lunging heavies with
     long recoveries to punish.
- **Epilogue: A City That Remains**, shown after he falls: what became of Ama, Chief
  Odo, Dr. Pim, Big Sak, Nattapong, Kraisorn, the night shift and the canal. The game
  then goes on: farming, enhancing and levelling to 50.
- Boss mechanics (`BossMechanics`):
  - a `cycle` of hazards called in turn;
  - per-phase `hazard` (`{}` turns them off);
  - a per-phase `shield` with `up` and `down` ticks, untouchable and standing back while
    up;
  - the new hazard kind `shock`;
  - a `boss_shield` event with a dome on the boss and toasts ("Defences up. Survive!" /
    "System reset. Strike now!").
  All are validated on load.
- Balance: the Hybrid Brute uses a regular telegraphed slam. Subject 12's long lunge
  stays his own, since in a crowd it took a quarter of the hero's health a hit.
- XP pacing: a straight run keeps the hero within two levels of every area to the Core
  Chamber.
- Measured with the auto-battle pilot, hero one level above each area, no gear, 10 of
  the food the loop would buy: 85 of 90 seeded runs clear from the Test Labs to the Core
  Chamber. The final chapter is the hardest, as it should be. With no food, Wiroj ends a
  close fight like every chapter boss before him.
- Tests: the street ends in the Core Chamber; Wiroj fights at the cap; three distinct
  phases; phase 1 without defences; the shield's rhythm (up, reset, up; no new hazards
  while reset); the defences in turn; the last stand without them; the epilogue plays
  and the game goes on.

### Added — Chapter 5: The Core Facility (IL-5)
- Four areas past Rattanachai Tower, open once Big Sak is down:
  - **Core Facility Gate** (level 33)
  - **Test Labs** (35)
  - **Machine Hall** (37)
  - **Control Room** (39)
- **Dr. Pim** gives the chapter: Facility Breach, Subject 12, Machine Hall and Commander
  Arthit. **Lek**, a laid-off lab technician, sells level 33–35 gear, and Win's taxi
  stands at the gate.
- New enemies: the **Facility Trooper**, the **Riot Trooper** (elite, heavy armour) and
  the first **Hybrid Workers**, workers The Core changed. Dr. Pim and the Exposure Report
  explain them (story bible §6), and they appear only in the facility.
- Two bosses:
  - **Subject 12**, mid-chapter: a lunge with a long reach and a frenzied sweep when
    hurt. Beating him hands over the **Exposure Report**: the change reverses if the
    exposure stops.
  - **Commander Arthit**, at the end: security **lasers** that sweep the whole street at
    the hero's depth, so the escape is a lane change or a roll, not walking away. He
    calls in a trooper too, and both come faster once he is enraged. Beating him hands
    over the **Core Source Data**.
- The hazard system gains the `laser` kind. Warnings now carry their footprint, so the
  red mark on screen is the size of what it hits. `CraneDrop` becomes `HazardView` (it
  draws all three kinds).
- Auto battle escapes a hazard the quicker way, along the street or across the lane, and
  rolls when it is too late to walk.
- **Fix:** the pilot could stall forever when pinned between a crate and the lane's edge
  (it tried to go round the far side, through the crate). It now passes obstacles on the
  side it is already on, or backs off and goes round.

### Changed — XP pacing for the late game
- XP curve squared term 6 → 5: late levels were costing more than the areas pay, so the
  hero fell 3 levels behind by the Test Labs.
- Two Chapter 1 quest rewards were trimmed (The Pit 850, Rat Nest 520), and Chapter 5's
  trooper and hybrid XP was set for its two-level steps.
- A straight run now keeps the hero within two levels of every area, Depot to Control
  Room (`test_levels`).
- Measured with the auto-battle pilot, hero one level above each area, no gear, 10 of
  the food the loop would buy: 126 of 126 seeded runs clear every area from the Crane
  Yard to the Control Room. With no food, each chapter boss ends a close fight (13–29%
  of its health left on average when it wins).

### Added — Chapter 4: The Black Network (IL-5)
- Four areas past the Factory Drains, open once Unit K-7 is down:
  - **Warehouse Row** (level 26)
  - **The Underground Ring** (27)
  - **The Counting House** (29)
  - **Rattanachai Tower** (31)
- **Kenji**, exposed as a one-time courier for the network, gives the chapter's quests to
  make it right: Follow the Money, The Ring, Cooked Books and Big Sak. **Uncle Thong**
  sells level 26–27 gear, and Win's taxi stands at Warehouse Row.
- New enemies: the **Network Runner** (fast, bare-handed courier), the **Network
  Enforcer** (heavy) and the **Ring Fighter** (elite).
- Two bosses:
  - **The Ringmaster**, mid-chapter, with a spinning kick that reaches both sides.
  - **Big Sak**, at the end. He whistles in his runners, two at a time and never more
    than two standing, and more often once enraged.
- Evidence: the **Money Trail** names Director Wiroj for the first time, and the **Core
  Facility Pass** leads to Chapter 5.
- **Boss mechanics moved out of ZoneSim** into `BossMechanics` (hazards plus the new
  `summon`, validated on load, only for bosses), with no change to how hazards play.
  The new `boss_summon` event shows a "calls for backup!" toast.

### Added — Food that scales with the hero
- **Rice Box** (heals 120) and **Herbal Tonic** (heals 220, plus energy), sold from the
  Depot onwards and dropped by later enemies. Steamed buns alone heal about 6% of a level
  30 hero.
- `FoodRules` picks what to eat: the smallest food that covers most of the wound, or the
  biggest when in trouble. The quick-heal key (H/Q) and auto battle both use it, so the
  quick-heal key now eats every kind of food, not just buns and tea.
- The farm loop buys food sized to the hero (about a third of their health per bite)
  instead of always the cheapest.
- Measured with the auto-battle pilot, hero one level above the area, no gear, 10 of the
  food the loop would buy: every hero clears every area from the Crane Yard to
  Rattanachai Tower (108 of 108 seeded runs). With no food at all, Big Sak and Unit K-7
  are about equally hard.
- Tests: Chapter 4's order, levels, quest chain and evidence; the Director kept out of
  earlier chapters; the Ringmaster's gate; Big Sak's whistle (count, limit, quicker when
  enraged, silent once he falls); summon validation; and food choice, shopping, restock
  and the quick-heal key.

### Added — Auto battle (decision D12)
- **Auto battle** (T, gamepad Back/Select, or the AUTO button under the hero card). It is
  allowed only in areas the hero has already beaten by hand: the next area east has been
  reached, or, at the end of the street, its bosses have been beaten. Elsewhere the
  button is dimmed, and pressing it says why. Any input of the player's own takes over
  for that tick.
- The pilot (`client/sim/AutoPilot.gd`) plays like a careful player. It is deterministic
  and only sends player input:
  - eats below a set health share, picking the smallest food that covers the loss and
    the biggest one in real trouble;
  - steps out of crane and steam shadows, sidesteps or blocks thrown weapons;
  - dodges guard breakers and telegraphed heavies, or walks out of their reach when
    there is time, and stops queuing combo links while one is coming;
  - guards plain blows just before they land (a perfect guard parries), and hits first
    when its jab is quicker against a foe that flinches;
  - picks skills from each hero's own move data: area skills into crowds, finishers saved
    for three foes or a boss, and always energy kept for a dodge;
  - chains light combos into a heavy finisher, and targets close, hurt or unguarded
    ranged foes;
  - between fights, picks up a street weapon, collects drops (giving up on any it cannot
    reach), walks around street furniture and on to the next fight.
- **Farm loop.** When an area is clear, or the hero is hurt with nothing left to eat, the
  hero goes home to rest. It buys food at home up to a set stock, always keeping the taxi
  fare, rides Win's taxi back and goes again. The HUD shows what it is doing and the
  session's runs, KOs, coins and XP. Settings are on the pause menu's Game tab: the
  health share to eat at, the loop on or off, and the food stock to keep.
- **Measured** with a hero one level above each area, no gear and 10 buns:
  - every hero clears every Chapter 1 to 3 area alone, bosses included (88 of 90 seeded
    runs in the five hardest areas);
  - 20 minutes of the farm loop gave 13 to 15 runs and 200+ KOs per hero, with no
    knock-outs.
- Tests: auto is allowed only where beaten; every hero clears a street alone and picks up
  the drops; eating; area skills on a crowd; the big skill saved for bosses; dodging and
  parrying; hazard shadows; the loop rules and the full loop through the game; the
  player's input winning; the HUD switch.

### Changed — Levels 1-50, climbing chapter by chapter (decision D11, replaces D9)
- The hero now levels up to **50**. Each chapter has its own level band: South Street
  areas run levels 1-10, the Port District 12-16 and the Industrial District 19-24.
  Elites fight one level above their area and bosses two (`LevelRules.enemy_level`;
  `level_bonus` still overrides). Item level requirements, weapon `min_level` and quest XP
  follow the new bands.
- Enemies grow at the hero's pace: per level +6% health (the hero's damage grows about
  as fast) and +8% damage (the hero's health grows about as fast), +1 defense every 8
  levels. An enemy at the hero's level is about as hard at level 40 as at level 4; the
  gap decides, and gear and enhancing keep the hero ahead.
- Brains sharpen slowly instead of peaking by level 13: reactions and attack pauses
  shorten 1.2% per level (at most halved), guarding starts at level 4, picking up weapons
  at 6 and dodging at 9. Chapter 1 enemies stay simple-minded.
- **Name colours by level gap** over every enemy and on the boss bar (which now shows
  the boss's level): grey (6+ levels below the hero), green (3-5 below), yellow (within
  2), orange (3-5 above), red (6+ above).
- XP depends on the gap too: grey foes pay 10%, green 60%, yellow 100%, orange 120%, red
  140%. Money is unchanged, so old streets can still be farmed for coins.
- XP curve `100 + 100·(L-1) + 6·(L-1)²` per level (new optional `square` term in
  `progression.json`), tuned so that clearing each area once and handing in its quests
  brings the hero in within two levels of every area.
- Tests: elites and bosses fight above their area, chapters stay in their bands, early
  enemies are simple-minded, an even-level fight stays fair from level 1 to 50, name
  colours, XP by gap, and a straight run keeps the hero near each area's level.

### Added — Return to the Depot Yard from the pause menu
- **Return to Depot Yard** (pause menu, Game tab) takes the hero straight home to upgrade
  gear at the workbench, shop and rest. Arriving heals and brings every street's fights
  back, as walking in would. Win's taxi rides back out to any area reached.
- It is never an escape from a fight: greyed out, with the reason shown, during a fight
  (bosses included), while knocked down, or at home already (`ZoneSim.recall_problem`).
- Tests: recall takes the hero home rested; there is no recall mid-fight; the menu offers it
  only when allowed.

### Added — Chapter 3: the Industrial District (IL-5)
- Four areas past the Crane Yard, open once Harbourmaster Chen is beaten: **Factory Gate**
  (level 14), **Production Line** (15), **Waste Pools** (16) and the **Factory Drains**
  (17).
- **Dr. Pim**, the former city inspector, gives the chapter's quests (Factory Doors, The
  Chief, Sample Run, Unit K-7). **Aunt Jum** sells level 14-15 gear (Hazmat Hood, Plant
  Security Vest, Insulated Gloves, Lab Boots), and Win's taxi stands at the gate.
- New enemies: the **Plant Guard** (elite), the **Hazmat Sprayer** (ranged) and the **Patrol
  Unit**, the first machine.
- Two bosses:
  - **Security Chief Nattapong**, mid-chapter. Beaten, he takes off his badge and walks
    out (spared).
  - **Unit K-7**, at the end. Its floor vents burst with steam where the hero stands, after
    a warning. The hazard system now has kinds (`"kind": "crane" | "steam"`, validated on
    load).
- Evidence: the **Waste Sample**, then the **Experiment Log**, where the words "The Core"
  appear for the first time. K-7 ends Chapter 3.
- Fixed: the generated street backgrounds no longer crash on a sliver of building at an
  area's end.
- The story test allows The Core from Chapter 3 on, and only in late evidence, as the
  story bible says.
- Art is temporary (D10). The robots are LPC armour builds, and the vents are drawn with
  shapes.

### Added — Chapter 2: the Port District (IL-5)
- Four areas past the Gang Headquarters, open once the Furnace Baron is beaten: **Port
  Road** (level 10), **Freight Market** (11), **Container Yard** (12) and the **Crane
  Yard** (13).
- **Uncle Chai**, the dock canteen cook, gives the chapter's quests (Dock Shakedown,
  Market Watch, Hooks and Wrenches, The Harbourmaster). **Noi** sells level 10-11 gear (Docker's
  Cap, Port Authority Jacket, Cargo Gloves, Deck Boots), and Win's taxi waits at Port Road too.
- New enemies: the **Stevedore** (heavy), the **Port Guard** (elite) and the **Dock Slinger**
  (ranged, throws wrenches).
- **Harbourmaster Chen**, boss of Chapter 2, works the cranes: every few seconds a
  red shadow grows where the hero stands, and a container drops on it after at least a
  second. It hits everyone under it but Chen, his own crew included, and comes faster
  once he is enraged (`hazard` in `enemies.json`, validated on load; `hazard_warn` and
  `hazard_hit` zone events). Beating him gives the **Altered Manifest**, whose new
  destination points to the Industrial District, and ends Chapter 2.
- Art is temporary (decision D10: finish the game first, then one art pass). The new
  characters are LPC builds, the docks reuse kit pieces, and the container is drawn with
  shapes.
- Tests: the port follows the Gang HQ in story order; Chen ends the chapter with new
  evidence; the crane warns, then drops on the hero's spot; stepping out of the shadow is
  safe and Chen is never hit; it comes faster when he is enraged; there is no crane
  outside the boss fight. Ranged enemies are exempt from the heavy-blow pause test by their
  `ranged` block, not by name.

### Added — Painted enemy sheets on a green backdrop (IL-4, D6)
- **Four enemies repainted by the owner, as the story describes them**: the Tar Rat (a gang
  kid in a rubber rat mask and black hoodie), the Smogling (a drifter in a yellow raincoat
  and home-made bottle gas mask), the Smog Warden (grey hazmat suit with a skeleton
  pattern) and the Sludge Foreman (boar-masked boss in suspenders). Their LPC recipes
  are retired, and the hurt and knock-down frames are painted too.
- `custom_import.py` reads sheets of loose figures (`"figures": true`). It finds every figure
  on the green backdrop (grid lines and specks ignored), groups them into rows by where
  their feet stand, scales them so a chosen figure stands a set height (`row_scale`
  evens out rows painted at another size), and anchors each figure on its own feet.
  Animations pick `[row, index]`. Frames the painting got wrong (legs cut by the grid,
  two figures overlapping, a kick split across cells) are left out.
- `custom_import.py` cuts a flat green backdrop out of a painted sprite sheet
  (`"key": true` in `import.json`), like the street kit. The grid is kept, and green
  clothing inside the figure's outline stays green. A pipeline test checks both.
- `docs/ENEMY_PROMPTS.md`: sheet rules and prompts to repaint the Tar Rat, Smogling, Smog
  Warden and Sludge Foreman as the story describes them (rat-masked gang member, drifter in a
  home-made gas mask, hazmat security, boar-masked boss). LPC has no such masks under the
  allowed licences.

### Added — Checkpoints, remembered fights and the motorbike taxi
- **Knocked out, you get up where you fell**: at the west end of the same area, or just
  short of the boss fight you lost, to try again at once. Losing still costs coins.
  Before, every knockout sent the hero back to the Depot Yard.
- **Fights you win stay won** (`StreetMemory`, saved as `cleared`) until you rest at the
  Depot Yard, which brings every fight on every street back for farming coins, XP and
  drops (bosses too; quest rewards and evidence still come once). If an area's fights
  are all won while its gate is still shut, they come back, so a gate always opens
  where it stands.
- **Win, the motorbike taxi** (new LPC NPC in an orange shirt), at the Depot Yard and
  the Night Market: for 10 coins, rides to any area reached before (`visited`), in street
  order. Rest at the Depot first to farm a street from scratch.
- Save version 6 adds `cleared` and `visited`. Older saves load with every fight ready
  and every area up to the saved one reached.
- Night Market: one more Punk in the last fight, so its gate (10 Punks) opens in one
  pass. Before, it only opened by re-entering.
- Tests: won fights stay won and come back after a rest; a shut gate always has fights
  left; every gate opens in one pass; getting up at a boss's door; getting up keeps won
  fights; taxi destinations and fare; a version 5 save loads with its road reached.

### Changed — Skill pacing: heroes faster, enemies and bosses slower (IL-4)
- Every hero's skills come back sooner: regular skills in 2.5–4.25 s (were 4–7 s),
  ultimates in 11–12.5 s (were 20–22.5 s), for all six classes.
- Enemies and bosses can no longer chain their heavy blows. Each waits `heavy_cooldown`
  (in `enemies.json` `ai`, and per boss phase) between heavies: 4.5 s for street gangs,
  5 s for elites and bosses (4.5 s in phase 2), 5.5 s for the Furnace Baron (5 s in
  phase 2). That is always longer than any hero skill short of an ultimate. The Bottle
  Thrower's lob is its basic attack and waits 2 s.
- To keep the bosses a threat without the spam, they throw normal blows about 20% more
  often. The Sludge Foreman hits harder (power 1.3, 1.5 in phase 2, 460 HP), and the Pit
  Champion has 380 HP.
- Scripted-player boss probe (no gear, no food, no parry; 10 seeds per class): the
  Sludge Foreman is won 7–10/10 (was 3–8), the Pit Champion 1–5/10 (was 0–1), and the
  Furnace Baron still 0/10.
- Tests: hero skills come back within 4.5 s (ultimates within 13 s); every enemy's heavy
  waits longer than any hero skill short of an ultimate, bosses 5 s or more; a boss never
  chains heavies.

### Added — The rest of South Street: Parking Lot, Rat Nest, Gang HQ (IL-4)
- **Parking Lot** (level 4), between the Rusted Corner and the Rail Yards: a multi-storey car
  park whose ramps Pipe Brutes guard, with cars parked at the kerb. Quest "Night Shift":
  the refinery man's trucks hand their crates to the freight wagons here.
- **Rat Nest** (level 9), the drainage tunnels under the Refinery: the Tar Rats' lair, in
  the painted tunnel walls, pipes and grates with the wet tunnel floor. Quest "Rat Nest".
- **Gang Headquarters** (level 9), the end of South Street: the Furnace Baron's fortified
  building, behind a steel gate and guard booth. The Baron now fights here and closes
  Chapter 1; at the Refinery his enforcers hold the smelter (quest "The Smelter", gate:
  knock down 5 enforcers) and he escapes into the drains.
- Main quests run in street order: Glass Rain, Night Shift, Rail Yard Rumble, Market
  Lights, The Pit, The Smelter, Rat Nest, The Furnace Baron.
- Tests: the new areas stand in story order, the Baron fights only at his headquarters and
  ends the chapter, one quest chain follows the street, each new area has its own scenery.
  Boss probe: the Baron at the HQ (level 9) is about as hard as he was at the Refinery
  (level 8).

### Changed — Street scale, sidewalk and solid vehicles (IL-4)
- Buildings, shops and lamp posts are sized to the characters: doors are now taller
  than a person (shophouses 280, shops 170, lamp posts 185, power poles 250 game px),
  and buildings may rise past the top of the view. Booths, gates, stalls, the ring and
  the pickup grew to match.
- Fighters cannot walk onto the sidewalk: the kerb is drawn above the fighters' lane.
  Lamp posts, power poles, bins and traffic cones stand on the sidewalk; crates and
  oil drums stand at the kerb, never in the middle of the road.
- Parked vehicles (taxi, tuk-tuk, songthaew, pickup, motorbike, car wreck) are solid
  street furniture placed in `areas.json`, at the kerb of every street but the Fight
  Club. They block as rectangles (`"box"` in `obstacles.json`), so nobody slips
  between a car and the kerb; enemies walk round them. The kit no longer scatters
  vehicles.
- Vehicles are sized for the characters (about 52 px tall): a taxi 64, pickup 72,
  songthaew 78, tuk-tuk 66 and motorbike 48 game px, so a person fits in the cabin
  and on the seat; the skytrain is 80 px on a thicker beam, raised to clear the
  shops.
- A held weapon stays in the same hand in every animation. In the heavy blow the
  weapon now swings with the striking arm instead of resting at the hip while the
  other arm hits (`"hand": "front"` in the recipes' `weapon_pose`; while that arm is
  hidden behind the body the weapon waits where it next shows). The fist closes
  around the middle of the handle and the handle's end shows below it (`handle` in
  `art/weapons/weapons.json`), instead of the weapon starting at the back of the hand.
- The folding chair weapon is film-sized (about 42 px against 50 px characters). A
  painted weapon can ask for a bigger sprite cell (`cell` in
  `art/weapons/weapons.json`), and its grip follows (`weapon_grips` in the manifest).
- Tests: furniture on the sidewalk or at the kerb, the hero stays on the road,
  vehicles block with no gap at the kerb, enemies go round them, the chair's size,
  vehicles sized against a character, the weapon never jumping between hands, and
  every handle showing below the fist.

### Added — Street kit: all 22 pieces from the scene prompts (IL-4)
- Every piece in `docs/SCENE_PROMPTS.md`, painted by the owner and cut out by
  `kit_import.py`: Fight Club (warehouse wall, ring, crowd, work lamps, tyres, chairs),
  Rusted Corner (junk shop, fence, scrap, drums, car wreck), Parking Lot (car park,
  barrier booth, pickup, scooters), Rat Nest (tunnel wall, drain pipe, grate, the
  `tunnel_floor_tile` ground strip) and Gang HQ (facade, steel gate, guard booth).
- Crops drop what the paintings added outside the piece: the smear above the fence and
  the framed lamp section at the left of the crowd.
- Fight Club is now an underground ring: corrugated warehouse walls with work lamps
  strung overhead, the ring, the crowd, tyres, chairs and drums along the back. Rusted
  Corner is a junk-dealers' street: the junk shop and patched fences, scrap heaps, oil
  drums and a car wreck at the kerb. An area's `kit_theme` picks its own kit theme
  (the generated fallback scenery still follows `theme`), and themes can hang pieces
  overhead (`hanging`). Checked in a browser; one new pipeline test.
- The Parking Lot, Rat Nest and Gang HQ pieces are imported but wait for those areas.

### Added — Three more heroes: the Basketball Player, the Police Officer, the Soldier (IL-4)
- **Kan Srisuk, the Basketball Player**: the crowd controller. Crossover (a stunning
  change of direction), Elbow Clear (both sides), Post Up (breaks guard) and Slam Dunk,
  the widest hit in the crew. 110 HP, 105% speed and attack speed.
- **Dao Kittikun, the Police Officer**: defence and counters. Her parry window is 12
  ticks (everyone else 8), Wrist Lock holds a foe longest, Riot Shove floors a crowd.
  120 HP, 95% power. Hardest to play (3/3).
- **Pong Rattana, the Soldier**: once one of his skills starts, nothing interrupts it
  (Combat Elbow, Breach Kick, Shoulder Drive, Ground Pound). Toughest (140 HP, 3
  defense) and slowest (80%). Easiest to play.
- Each hero's edge is data (`heroes.json` `parry_window`, `skill_armor`) used by the
  existing rules, not new combat code paths. All six heroes pass the existing balance
  rules (same-slot skills within 15%, every skill 1.5x the heavy attack, the slot-5
  skill strongest); new tests check every class is in the roster, nobody tops health,
  power and speed together, the Soldier is slowest and toughest, Kan reaches widest,
  Dao parries where others only block, and Pong's skills cannot be interrupted.
- Measured with the same scripted player against the Smog Warden at level 5: Kan
  5.0 s, Dao 5.1 s, Pong 6.1 s (the first three heroes 3.8–4.9 s); all win 20/20.
- Sprites built with the LPC pipeline from licence-cleared layers; twelve new 24 px
  skill icons. Hero creation switches to compact cards when there are more than four
  heroes, so all six fit above the name bar (checked in a browser).
- `docs/SCENE_PROMPTS.md`: painting prompts and rules for the next street-kit pieces
  (Fight Club ring, Rusted Corner junk yard, and the planned Parking Lot, Rat Nest and
  Gang HQ). 5 new tests (225 total).

### Added — South Street grows: Rusted Corner, Fight Club, ranged enemies, a mini-boss (IL-4)
- **Rusted Corner** (level 3, between Canal Works and the Rail Yards) introduces the
  first ranged enemy, the **Bottle Thrower**: it hangs back 80–150 px, lines up in your
  lane, winds up (telegraphed) and lobs a bottle that stuns but never floors and
  shatters where it lands; caught up close it jabs. Its exit opens after 6 throwers.
- **Fight Club** (level 7, between the Night Market and the Refinery) ends in the
  **Pit Champion**, a mini-boss: a jab-cross chain, a telegraphed guard-breaking
  overhand, and below half HP a charging rush. Poise 70. Drops scrap and alloy always
  and the new **Champion's Wraps** (epic hands: attack, crit, attack speed) 25% of the
  time. His exit opens the back door to the Refinery.
- Two new LPC characters built with the asset pipeline from layers already cleared by
  the licence policy (OGA-BY): the red-bandana thrower and the shirtless champion.
  Scenery for both areas is laid out from the owner's kit like every other street.
- Two quests join Chief Odo's chain, voiced like the rest: "Glass Rain" (after the
  Foreman) and "The Pit" (after Market Lights, before the Baron). The story bible maps
  both areas and gives the champion his reason to fight.
- Ranged attacks reuse the throwing system (`ZoneSim` projectiles) instead of a second
  one; the AI is `EnemyBrain._keep_range`; the data (`ranged` on the enemy and its
  `ai`) is validated on load.
- Measured the rules' cost with 10 enemies on screen: 0.30 ms per tick on average
  (PERFORMANCE.md), well inside a 60 fps frame.
- After a fight is cleared, a blinking **GO >>** points the way on (only where the
  street continues east).
- New tests keep the street one connected line with rising levels, every gate
  winnable in its own area, every quest target findable, and check the thrower keeps
  its distance and its bottles stun and shatter. 6 new tests (220 total).
- Measured with a scripted player (no gear, no healing, no parries): the champion is
  as hard as the existing Furnace Baron for that player (both unbeaten), the Sludge
  Foreman is beaten 30–80% of the time. Real tuning needs playtests; recorded in
  docs/BLUEPRINT.md.

### Added — Elites and bosses cannot be pinned by mashing (poise)
- Found while balancing the classes: replaying a fight against the Smog Warden (one
  scripted player per hero, 20 seeds) showed a hero who just mashed light attacks kept
  the elite helpless 60–77% of the fight and was never hit back, which made its
  telegraphed attacks meaningless.
- Elites and bosses now have **poise** (`enemies.json` `poise`: 60 for elites, 80 for
  bosses). Hitstun fills it; past it they shrug blows off for 1.5 s (still taking
  damage, with a warm sheen and steel-grey damage numbers), and they are unflinching
  while winding up a telegraphed attack, so the answer is to dodge, guard or parry.
  A parry still staggers them. Same replay: helpless 39–55%, and at level 5 the elite
  now lands hits. Heroes and ordinary enemies are unchanged.
- The same replay showed why Mika's kills are slowest at level 1: both her starting
  skills knock down, and a floored enemy cannot be hit for 50 ticks. That is the
  intended trade (knockdowns buy safety), recorded in the blueprint rather than
  re-tuned without playtesting. 6 new tests (214 total).

### Added — Gear upgrades at the workbench (IL-3)
- Every equipment slot can be upgraded from +0 to +10. Each level adds 10% of the worn
  item's own stats (penalties are never amplified). Upgrades belong to the **slot**, so
  changing gear never throws them away, and there is no per-item bookkeeping that a
  save could lose.
- Each attempt costs coins and materials (+1: 40 coins and 1 Scrap; +10: 1,100 coins,
  8 Scrap, 3 Alloy) and succeeds at the level's rate (100% down to 20%). **A failure
  keeps the item and the level**, spends only the cost, and adds +5% to the next try in
  that slot until one succeeds. Costs and rates are data (`progression.json`
  `enhance`), validated on load (costs in materials, rates never rising).
- From the worn item's card in a safe area (the Depot Yard): what the upgrades add
  now, the next level's chance and cost (red where you are short), and an "Upgrade
  +N (chance)" button. Success and failure each have a sound and a message; a second
  press within 0.4 s is ignored and every attempt is saved at once. Upgraded slots
  show a gold "+N".
- The rule is `sim/EnhanceRules.gd`: check, pay, roll, apply in one call, with the
  roll from the caller (the server, once online). **Save version 5** stores levels and
  pity; version 4 saves start at +0, values are clamped and unknown slots dropped.
- 9 new tests (208 total).

### Added — Critical hits and attack speed (IL-3, decision D8)
- Two new stats: **Crit** (chance of a 1.5x blow; every hero starts at 5%, Riku the
  Boxer at 8%; capped at 50%) and **Atk Speed** (cuts the recovery after each attack,
  never the wind-up, so combos stay readable; 70–130%). Crits come only from the zone's
  seeded generator, so a fight replays identically; enemies do not crit. No accuracy
  stat: hits are decided by where the blow lands.
- Gear that fits: Lucky Coin, Iron Wraps, Brass Knuckles and the Baron Knuckledusters
  add crit; Fingerless Gloves, Street Runners and the Jade Charm add attack speed.
  Status and item cards show both. Crits show "CRIT" and shake the camera.
- 4 new tests (199 total); Riku's all-rounder test now covers the core stats and
  requires him to crit most often.

### Added — Upgrade materials and "where to get" (IL-3)
- Two materials (new item type `material`): **Scrap Metal** (common; dropped by street
  enemies 15–30%, elites 80%, sold by Ama and Kenji for 30) and **Refined Alloy**
  (rare; elites 25–30%, Kenji for 300). Every boss now guarantees both, so a boss kill
  always pays even when the signature gear does not drop. New icons; materials sort
  between gear and evidence in the bag and can be discarded.
- Item cards show **WHERE TO GET**: who drops it (chance, where they fight), who sells
  it and for how much, which quest gives it. Worked out from the loot tables, shops and
  quests (`ContentDB.sources`), so it can never disagree with them.
- Fixed a test that only passed by luck: it expected the Sludge Foreman's wrench every
  time, which stopped being true when boss loot became farmable. 5 new tests (195 total).

### Added — A tutorial that teaches by doing (IL-2)
- New heroes are walked through the basics in the Depot Yard, one step at a time in
  the quest card's spot: move, punch the dummy (3 hits), heavy blow, a skill, dodge,
  guard (and how to parry), pick up a weapon, throw it, talk to Chief Odo. Each step
  finishes when the player does it, with a chime; the last says the street is open.
- Skippable from the menu (Game tab, "Skip tutorial"). Steps are data
  (`client/data/tutorial.json`, validated on load) and the rule lives in
  `sim/TutorialRules.gd`.
- **Save version 4** stores tutorial progress. Version 3 saves migrate with the
  tutorial marked finished, since those players already know the game; values are
  clamped on load. 7 new tests (190 total).

### Added — Prologue and Chapter 1 told through the quests (IL-2)
- Chief Odo's six quests are rewritten from `docs/STORY_BIBLE.md` as the Prologue
  ("First Night") and Chapter 1 ("South Street"): a shakedown at Ama's stall, a crate
  the crew came back for, masked guards at the canal, forged freight papers, Kenji's
  tip and the Furnace Baron's ledger, which points to the port.
- Quest givers speak: each quest has an offer, a nudge while it is under way and a
  closing line on hand-in (`quests.json` `dialogue`, one or two sentences). Below the
  speech the dialog always spells out the chapter, quest, **Goal** and reward, so
  skipping the words never leaves anyone lost.
- **Evidence** (new item type `key`): the Torn Shipping Label, Forged Delivery Note and
  the Baron's Ledger are handed over on completion ("New evidence: ..."), sorted at the
  end of the bag, readable from the item card and never sold, used or discarded (a
  sim rule, not only the UI). They are not listed as rewards, to keep the surprise. New
  16 px icons drawn by `gen_ui.py`.
- Handing in "The Furnace Baron" shows a **Chapter 1 complete** card naming where the
  trail leads next.
- Tests keep every quest in a chapter with all three lines, keep The Core unnamed in
  quests and items (story bible §7), and reject priced evidence. 6 new tests (183 total).

### Added — The street opens as the story moves on (IL-2)
- Exits east are now guarded: Saltmarket → Canal Works opens once the Smog Warden is
  down, Canal Works → Rail Yards after the Sludge Foreman, Rail Yards → Night Market
  after 8 Dock Thugs, Night Market → Refinery after 10 Night Market Punks (the same
  goals as Chief Odo's quests, counted whether or not the quest is active, so nobody
  has to fight a guard twice). Before, a new hero could walk straight to the level 8
  Refinery. The way back is always open.
- A locked exit's sign turns red and shows progress ("Locked 0/1 Canal Works >");
  pushing on it plays a refusal and says what opens it, once per push.
- Gates are data (`areas.json` `exits.*.requires`: enemy, count, hint), validated on
  load. 5 new tests (177 total).

### Changed — Boss loot is worth farming; heroes have their classes (IL-2)
- Bosses no longer hand out their best item every time: the Furnace Baron drops the
  Baron Knuckledusters (legendary) 12% of the time (was 100%) and the Jade Charm 20%
  (was 50%; his quest still gives one), the Sludge Foreman his Foreman Wrench (epic)
  30% (was 100%). Bosses respawn on re-entry, so they can be farmed. A test keeps every
  epic or legendary drop at 35% or less.
- Heroes carry their class (decision D3): Mika is **The Footballer** (new bio and
  tagline: sweeping kicks and line-breaking charges), Oren **The Street Brawler**,
  Riku stays **The Boxer**. Display text only; saves are unaffected. 1 new test (172 total).

### Changed — The game is now *The Iron Legacy* (IL-2, decision D1)
- Project name, browser tab, title logo ("THE / IRON / LEGACY") and credits. The title
  tagline promises only the street ("Take Iron City back, one street at a time"), since
  the story bible keeps The Core secret until chapter 3. The README is retitled.
- **Saves survive the rename.** Godot names the user data folder after the project, in
  the browser too (checked in Chromium: a save made by the old build was not seen by
  the renamed one). `SaveStore` now copies `save.json` and `settings.json` from the old
  "Ironbound Streets" folder on first start, never overwriting a newer file and never
  deleting the original. Verified in a real browser: a save made by the old build
  continues in the new one. 3 new tests (171 total).
- Internal names stay (`window.ironboundProbe`, the API image name), as renaming them
  changes nothing a player sees.

### Added — The Furnace Baron charges; fair-fight rules (IL-1)
- Below half HP the Furnace Baron no longer just hits harder: he charges (new
  `baron_rush`: 24 ticks of warning, carries him 110 px, breaks guard, knocks down) and
  is left open for 40 ticks after it. Enemy AI now starts lunging attacks from the range
  the lunge covers, so a charge is seen coming instead of starting point-blank.
- `tests/unit/test_fairness.gd` turns the blueprint's quality bar into rules every enemy
  must pass: openers that floor or break guard are telegraphed with at least 16 ticks of
  warning, telegraphed attacks leave at least 20 ticks to punish, and every boss phase
  adds a new attack. 4 new tests (168 total). This completes milestone IL-1.

### Added — Throw the weapon in hand (IL-1)
- With nothing underfoot to pick up, E now **throws** the held weapon instead of
  putting it down: a short wind-up, then it spins along the street (about 160 px), hits
  the first foe in its path for the weapon's heavy-blow damage at the hero's power and
  knocks them down, then lands at their feet with one use less, or breaks if that was
  its last. A guard blocks it from the front. Bosses are stunned, never floored, so a
  pile of pipes cannot trivialise them. A miss lands where it stops; it never leaves
  the area.
- Throws are simulation (`ZoneSim.thrown`, `CombatRules.thrown_hit`), drawn as a
  spinning weapon at chest height with a whoosh. The HUD hint reads "Grab / Throw /
  Talk". Enemies still only put weapons down.
- 6 new tests (164 total).

### Added — Perfect guard and counters (IL-1)
- Raise guard at most 8 ticks before a hit from the front and it is **parried**: no
  damage, no energy lost (15 energy back), guard breakers included. The attacker reels
  for 30 ticks and the first hit on them is a **counter** for 1.5x damage. Letting go
  of guard closes the parry window for 24 ticks, so it rewards timing, not tapping.
  Only the hero parries, so enemy guards never punish the player's combos.
- A parry flashes, clangs and freezes both fighters for a beat and shows "PARRY";
  counters show "COUNTER" and shake the camera. The Controls tab explains it.
- 6 new tests (158 total).

### Fixed — A crowd can no longer stun-lock the hero (IL-1)
- Hitstun the hero takes fills a stun meter that drains while they are in control. A hit
  that would push it past 40 ticks knocks the hero down instead of holding them, and
  getting up gives 36 ticks in which nothing can hit them (the hero blinks; attacking
  ends it). Measured worst case against three Night Market Punks with no input: 169 →
  68 ticks (2.8 s → 1.1 s); the cap is 90 ticks (1.5 s). Enemies are unchanged, so hero
  combos still chain.
- 4 new tests (152 total with the solid-street tests), including a zone test with three punks over three seeds.

### Changed — Direction approved
- The owner approved every recommendation in `docs/BLUEPRINT.md` (D1–D9): *The Iron
  Legacy*, Iron City and The Core, heroes mapped to classes, single player first (online
  work moves to IL-7). CLAUDE.md, GAME_DESIGN and ROADMAP point to the blueprint and the
  story bible.

### Added — The Iron Legacy: audit and blueprint (IL-0)
- `docs/BLUEPRINT.md`: audit of what exists, works, is missing or risky (baseline 140/140
  tests passing on Godot 4.7.2), conflicts between code, docs and the owner's brief,
  decisions the owner needs to make, the system blueprint built on the existing code, a
  roadmap by risk (IL-0 to IL-7) and a test plan. Measured stun-lock: three Night Market
  Punks keep an idle hero out of control for up to 169 ticks (2.8 s).
- `docs/STORY_BIBLE.md`: the proposed single source for the story (Iron City, The Core,
  characters, chapters, bosses, how the current areas and enemies fit), pending approval.
- Corrected stale lines in README (test count), GAME_DESIGN ("implemented so far") and
  ARCHITECTURE (shared rules). No game code or data changed.

### Added — Solid street: no walking through things or people
- Lamp posts, power poles, bins, cones, crates, NPCs, the training dummy, the hero and
  enemies are now solid. You bump into them and must walk round (a step at an angle
  slides along); enemies step round furniture and each other to reach you. Fighters
  in hitstun or knocked down do not block.
- Street furniture is gameplay data: kinds and footprints in
  `client/data/obstacles.json`, positions per area in `areas.json`, validated on load
  and shared with the future server. The game draws it among the fighters, sorted by
  depth; the scenery kit no longer scatters lamp posts at random and keeps sidewalk
  props and parked vehicles clear of it.
- Loot, weapons, spawns and arrivals never land inside furniture. Tests cover
  blocking, sliding, walking round, enemies detouring, NPCs, fallen fighters and
  furniture placement; the browser smoke test now walks round obstacles.

### Added — Painted street weapons, and a frying pan, wrench and bat
- The street weapons now use the project owner's paintings, reduced to hand-sized
  pixel sprites with an outline like the characters (in hand, on the street and on
  the HUD badge). `gen_ui.py` keys them from their green backdrop and puts the
  handle's end under the grip; `art/weapons/weapons.json` lists them.
- Three new weapons: **frying pan** (from level 1; the heavy bonk dazes and breaks a
  guard), **pipe wrench** (from level 2; quick, sturdy), **baseball bat** (from level
  3; long reach, a heavy swing that sends them flying). Added to the area weapon
  pools.

### Changed — HD-2D Bangkok streets
- Every area is now built from a kit of painted pieces (Octopath-style HD-2D): shops
  (convenience store, noodle shop, massage shop, pharmacy, a shuttered shop),
  shophouses, condo towers and an unbroken elevated skytrain track with trains behind them, a skyline, sidewalk and road
  tiles, street lamps and power poles, food carts, umbrella stalls, stools, plants,
  bins, cones, crates, a vending machine and bus stop, spirit houses (with Nang Kwak), cats and dogs, and a tuk-tuk,
  taxi, songthaew or motorbike parked at the kerb. Layers scroll at different speeds
  for depth, and leaves in front of the fighters scroll faster. Pieces are painted at
  twice the game size and drawn smoothly, so they stay sharp at any window size while
  the characters stay pixel art. Lamps glow. Depot, market and canal areas each
  have their own mix and tint.
- `tools/assets/kit_import.py` keys the pieces out of their green backdrops (green
  inside the outline, like the pharmacy cross, stays), trims, scales and lays out
  every area deterministically; `art/kit/kit.json` holds the recipe. The validator
  checks pieces against their sources and that layouts are current. Art by the
  project owner, credited in game. The generated sky stays; the generated buildings
  remain as a fallback.

### Added — A real punch sound
- Fists and kicks that land now sound like a punch, picked at random from six recorded
  hits so combos do not repeat one sound: "Punch 5" by jakeeaton (Freesound, CC-BY 4.0)
  and five punches cut from "multi punch" by Shikamarunara74 (Freesound, CC-BY 3.0),
  each trimmed so the impact plays within 20 ms. The in-game credits use each recording's attribution line
  as given, e.g. "multi punch.wav by Shikamarunara74 -- https://freesound.org/s/126317/
  -- License: Attribution 3.0".
- Four more punches from "Punches.mp3" by mrrap4food (Freesound, CC0 as listed), ten in
  all. That file's tags name a commercial library (Hollywood Edge), so it is kept only
  while the game is free: it is marked `replace_before_paid` and the validator reminds
  on every run (docs/ASSETS.md). Heavy blows play it lower with the old thump under
  it; weapon hits keep their own sounds. Credited in the in-game credits.
- `tools/assets/import_sounds.py` imports recorded sounds listed in
  `art/sounds/sounds.json` (cut, fade, normalise to -1 dBFS) with their authors,
  licence and source; the validator checks the licence against the policy and that the
  file matches a fresh import. The other supplied file (punches.mp3) was not used: its
  tags say "copyright 1999 Hollywood Edge", a commercial library.

### Changed — Riku at hero size
- Riku looked smaller than the NPCs: he was as tall as them in pixels, but his realistic
  proportions (small head, slim build) read smaller next to the big-headed LPC cast. He
  is now drawn 20% larger (about 60 px tall in his guard, in 80x80 frames), so he stands
  out as a hero. `FighterView` reads each art's frame size for the weapon hand and fist
  instead of assuming 64x64.

### Added — Riku Sato, the Boxer (third hero)
- A third playable hero with art by the project owner (walk and punch sheets in
  `art/custom/hero_riku/`): the all-rounder, between Mika and Oren on every stat
  (115 HP, 105% power, 1 defense, 100% speed). Jab on Z, cross on X, a guard-up idle.
  Skills: Liver Shot (fastest, long stun, breaks guard), One-Two (step-in knockdown),
  Dempsey Roll (weaving charge, breaks guard), Knockout Blow (big area finisher), each
  with its own icon. Starts with fingerless gloves, sneakers, buns and ginger tea.
- `tools/assets/custom_import.py` imports sheets drawn outside LPC: evens out sheets
  drawn at different sizes, scales to the game's size with crisp edges, adds the LPC-style
  dark outline, derives hurt and knock-down by tilting a frame about the feet (the art
  has no such frames), finds the fist for held weapons, and a portrait crop on the head.
  Credited to the project owner; the validator accepts owner art for `custom` sources.
- The "E Grab / Talk" hint moved right of the hotbar so it is not hidden at 1280x720.
- 1 new game test (139 total) and 2 pipeline tests.

### Fixed — Weapons stay in one hand and move like the weapon
- A held weapon now always sits in the same (near) hand, through idle, walk, swing, hit
  and dodge. Before, the socket followed whichever hand was closest, so the weapon
  jumped between hands.
- The fist closes around the handle: the weapon hand is drawn again over the weapon
  (a per-character `hands.png` cut from each frame with LPC's glove mask), so the
  handle sits inside the hand instead of lying across the back of it.
- Each weapon moves like itself: the knife **stabs** straight forward (new `stab`
  animation from LPC's one-handed slash, arm extended), while the bottle, plank, steel
  pipe, machete and chair **swing**: wound up behind the head, then brought forward and
  down in an arc. Before, every weapon pointed straight ahead and looked like a stab.
- Only enemies that can wield weapons go and fetch them; the Smog Warden (skeleton
  body, no one-handed swing in LPC) no longer wields. 3 new tests (138 total).

### Changed — Weapons sized to the hand
- Held weapons are redrawn at the characters' scale (knife blade ~9 px, bottle ~12 px,
  plank and pipe ~23 px, folding chair ~20 px) with slim, unoutlined handles so the fist
  still shows around the grip. Before, they were nearly half a character tall.

### Changed — Weapons stay on their street
- Walking into another area puts the held weapon down where the hero stood; it cannot be
  carried between areas. Each area keeps the weapons lying in it for the session, so a
  dropped weapon (with its wear) is still there on return. 2 new tests (136 total).

### Added — Three new areas, street weapons and smarter enemies
- The street goes on past the Sludge Foreman: **Rail Yards** (level 4), **Night Market**
  (level 6, with Kenji's Night Stall) and **Smokestack Refinery** (level 8, boss: the
  Furnace Baron). Every area has a level; enemies scale with it (HP, damage, defense,
  speed, XP, coins) and get smarter: faster reactions, guarding against wind-ups (from
  level 3), hopping back and grabbing weapons (from level 5). Enemy level shows over
  their heads and the area level on the HUD. New enemies with their own outfits: Dock
  Thug, Rail Bruiser, Market Punk, Refinery Enforcer (elite), Furnace Baron (boss).
- **Street weapons**: knife, bottle, wooden plank, steel pipe, machete and folding chair
  lie around (random by area and level; two in the Depot Yard to practise with). E picks
  one up or puts it down; it gives Z/X its own moves, wears out per landed blow (pips on
  the HUD), breaks with a sound, and is **drawn in the hand, following every frame of
  the swing**. Anyone knocked down drops their weapon and has to pick it up again.
  Wielding enemies may start armed.
- Quests Rail Yard Rumble, Market Lights and The Furnace Baron; six new items (rare to
  legendary, levels 5-8) with their own icons.
- Sprite builder: per-frame hand sockets from LPC's glove layer; weapon sprites and
  sounds (grab, drop, glass/wood/metal break) generated like the other assets.
- Smoke test picks up a weapon in the yard. 17 new tests (134 total), 2 pipeline tests.

### Changed — Skills worth their cooldown
- The heavy attack (X/K) has no cooldown, so it no longer rivals skills: 13 damage
  (was 18) and 20 energy (was 15). Skills hit harder: Mika 26/22/28/45, Oren
  28/24/30/50 (base). `test_balance.gd` now requires every skill to hit at least 1.5x
  the heavy attack.

### Added — Readable loot
- Items on the street show their own icon (at 2x, sharp) with a shadow, a glow and, for
  uncommon and better, a light beam in the rarity colour (taller for rarer items); epic
  and legendary items sparkle. Each shows its name in its rarity colour; coins spin and
  show their amount. Drops pop out of the enemy in an arc and fly off when collected.
- The bag and worn slots show icons at 2x in larger cells.
- The Characters gallery shows every item as it looks on the ground.
- 1 new test (117 total).

### Changed — Hero balance
- Clear roles: Mika is damage and mobility (power 110%, speed 110%, 100 HP); Oren is
  toughness and control (power 100%, speed 85%, 130 HP, 2 defense, wider skills).
- Skill damage retuned so every skill out-damages the free heavy attack, each hero's
  slot-5 skill is their strongest, and same-slot skills of both heroes land within 15%
  of each other: Mika 20/18/22/38, Oren 22/20/24/42 (base, before power).
- `test_balance.gd` keeps these rules (4 tests, 116 total).

### Fixed — Attack buttons felt unresponsive
- Input buffer: a light/heavy attack or skill pressed in the last 12 ticks (0.2 s) of a
  missed swing now starts as soon as that swing ends; before, the press was dropped,
  so Z/X (and J/K) seemed not to work when mashed.
- A heavy attack or dodge without enough energy now plays a refusal sound and blinks the
  energy bar instead of silently doing nothing. 3 new tests (112 total).
- The attack slot (1) lights up when Z/J is pressed and is labelled "1 Z", so it is
  clear Z is the same basic attack (no cooldown); the key hint shows X for heavy.

### Added — Hero portrait on the HUD
- The hero card shows the hero's face (cut from the current sprite, so armour shows) on
  a backdrop in the hero's colour, with the level in a gold badge on its corner, the
  player's name and the hero's role. The portrait flashes red when the hero is hit and
  its frame pulses red below 25% HP. 1 new test (109 total).

### Added — Character status, equipment and items
- Status tab: the hero (sprite, level, role, HP/energy/XP), read-only attributes (Max HP,
  Attack, Defense, Speed) as total + gear bonus with a line of help each, what the next
  level brings (stats and skills), and a record.
- Equipment tab: six worn slots around the hero (head, body, hands, weapon, feet, charm,
  with empty-slot silhouettes and a turnable preview), a stats summary, and the bag as a
  grid with stack counts and rarity frames.
- Item card on any item: icon, name in its rarity colour, rarity and slot, required
  level, effects in player terms, comparison with what is worn, description, and
  Equip / Unequip / Use / Discard (asks first). The shop shows the same details.
- Items: rarity, required level, `stats` bonuses (penalties allowed), descriptions.
  15 items with new icons; Ama sells ten, enemies drop the rest. Each hero starts with a
  small kit (worn gear, buns, coins).
- Saves (version 3) map the old `armor`/`accessory` slots to `body`/`charm`.
- 3 new tests (108 total).

### Added — Hero creation and a second hero
- Hero creation screen after New game: roster cards with portraits, a large animated
  preview, bio, play style, difficulty, stats compared across heroes, the hero's four
  skills, and a name field (2–16 characters, any script including Thai; Random
  suggestions). Keyboard, gamepad, mouse and touch.
- Oren Vale, a male bruiser (LPC, OGA-BY): 130 HP, 115% power, 2 defense, 85% speed,
  with Headbutt, Clothesline, Shoulder Charge and Earthshaker (new moves and icons) and
  an armoured look.
- Heroes are data (`data/heroes.json`): stats, sprites and looks, skills. The hotbar
  template fills its skill slots from the hero. Items change looks by name (`look`).
- Saves (version 2) store the hero and the player's name; version 1 saves become Mika.
- The title shows the saved hero (card and line-up). Credits now include the Godot
  licence and the bundled font.
- Noto Sans Thai (OFL) as a font fallback, pinned by SHA-256 and validated in CI.
- 8 new tests (105 total); the smoke test picks Oren and types a name.

### Changed
- `progression.json` no longer holds hero stats; they live with each hero.

### Added — Skills, combat feedback and sound
- Skill hotbar (`data/skills.json`): slot 1 attack, slots 2–5 Rising Uppercut, Whirlwind
  Kick, Shoulder Rush and Furnace Slam, slots 6–7 Steamed Bun and Ginger Tea. Skills
  cost energy, have cooldowns, unlock at levels 1/1/2/3 and can cancel a landed attack.
  Cooldowns, unlocks and a shared 2 s consumable cooldown are simulation rules
  (`SkillRules`, `CombatRules.start_skill`, `ZoneSim.use_item`). New move fields:
  `advance` (lunges). Knockback now pushes away from the attacker.
- Hotbar UI: icons, key numbers, cooldown sweep and seconds, energy and lock states, item
  counts, tooltips, click/tap; keys 1–7 and gamepad RT combinations.
- Combat feedback: hit sparks, impact flash and freeze, dust, per-skill effects, camera
  shake, hurt vignette, level-up light and banner naming unlocked skills.
- Sound: 25 original synthesised effects and a sound-volume option.
- Training dummy: an original wooden sparring post that rocks when hit and tips over.
- Generators `gen_fx.py`, `gen_sfx.py`, `gen_dummy.py` and skill icons in `gen_ui.py`, all
  validated in CI. 15 new tests (97 total); the smoke test casts a skill.

### Added — Interface overhaul
- One visual language (`UiTheme`: palette, type scale, control styles) applied to
  every screen through the project theme, and a kit of building blocks (`UiKit`).
  See `docs/UI.md`.
- Title screen: live street backdrop, logo, Continue first when a save exists,
  confirmation before a new game replaces a save, key hints.
- HUD: hero card with level badge and HP/energy/XP bars (damage trail), coins
  with icon, area name, tracked quest card, boss bar, notification banner, key
  hints; touch controls on touch devices only.
- Pause window with tabs (Status, Bag, Quests, Controls, Game) switched with Q/E or
  LB/RB; bag and shop list items with icons and a detail panel; quest cards with
  progress and rewards; options for screen shake and a frame-rate counter
  (`user://settings.json`).
- NPC conversations in a dialog box with a portrait; "[E] Talk/Shop" prompt over
  the NPC in reach; knock-out screen; outlined names and damage numbers; camera
  shake on heavy hits.
- Generated item and interface icons (`tools/assets/gen_ui.py`), validated in CI.
- `test_ui.gd`: screens fit the 640x360 base view, wrapping text has a width,
  focus is set, tabs switch, prompts appear only near NPCs (82 tests total).
- `tools/web-smoke/shots.ts` for screenshots of a web build.

### Fixed
- The title text wrapped one word per line (an autowrapping label without a width).

### Added — Character art pipeline and first art pack
- `tools/assets/`: LPC character builder (pinned generator commit, licence policy,
  recolouring, credits), UnitForge "Godot 4" export importer, SpriteFrames
  generator, asset validator and 14 pipeline unit tests; `Assets` workflow to
  build/import in the cloud; CI job validating every asset. See `docs/ASSETS.md`.
- Nine LPC-built characters (CC0/OGA-BY/CC-BY only): hero Mika and an armoured
  variant (shown when the Work Jacket is equipped), NPCs Ama and Chief Odo, and all
  five enemy types including the elite and the boss. `FighterView` plays them with
  `AnimatedSprite2D`, attack frames stepped by simulation ticks.
- Title screen: Characters (gallery) and Credits.
- Tar Hound renamed "Tar Rat" to match its art.
- Generated scenery for every area (`tools/assets/gen_environment.py`, original
  MIT art): sky and parallax skyline, themed facades (depot warehouses and
  containers, market shophouses and stalls, canal factories and water), detailed
  street, props and lamp glow. Validated for freshness in CI.

### Added — Milestone 2, part 2: playable single-player loop
- Title screen (New game / Continue), pause menu, inventory and equipment, shop,
  quest dialog and log, game over with a coin penalty, notifications, boss HP bar.
- Three areas from `data/areas.json`: Depot Yard (home: vendor, quest giver, training
  dummy, heals on entry), Saltmarket Street and Canal Works, joined by exits.
- Enemies from `data/enemies.json`: Smogling, Tar Hound, Pipe Brute, elite Smog Warden
  and a two-phase boss, the Sludge Foreman. `EnemyBrain` AI keeps spacing, lines up,
  reacts and swings; at most two attack at once (attack tokens); telegraphed heavies
  show a warning. Enemies push apart instead of stacking.
- Encounters with waves lock the arena until cleared and reset on re-entry (farming).
- Rewards decided by the zone simulation from a seeded generator: XP and levels,
  money and item drops from loot tables, quest progress. Items, shops, quests and
  progression are data (`items.json`, `shops.json`, `quests.json`, `progression.json`),
  validated together with cross-references by `ContentDB`.
- `PlayerProfile` with versioned, sanitising (de)serialisation; local save via
  `SaveStore` (atomic write; IndexedDB in browsers), autosave on area change, defeat,
  purchase and quest hand-in.
- 30 new tests (69 total); the test runner now ignores warnings but still fails on
  errors. The browser smoke test plays title -> new game -> dummy combo -> pause ->
  next area -> a real street fight.

### Added — Milestone 2, part 1: combat core
- Deterministic 60 Hz combat simulation in `client/sim/` (`CombatRules`, `Fighter`,
  `FighterInput`, `CombatEvent`): light combo jab → cross → body hook (chains only
  after a connected hit), guard-breaking haymaker, dodge with invulnerability frames,
  guard (front only, chip damage, energy drain, guard break), hit stun, knockback,
  knockdown, KO, simultaneous-hit trades.
- Attacks are data: `client/data/moves.json`, loaded and validated by `MoveLibrary`.
- Test zone: training dummy with HP bar and respawn, HUD HP/energy bars, floating
  damage numbers, keyboard/gamepad/touch bindings for light, heavy, dodge, guard.
- 23 new tests (39 total). Browser smoke test now lands a combo on the dummy.
- `pages.yml` plays the live HTTPS site after each deploy.

### Security
- Asset tools pin Pillow 13.0.0: dependency review flagged 20+ HIGH advisories in
  12.3.0 (PDF, TIFF, JPEG, GIF decoders). Rebuilt assets are byte-identical.

### Changed
- CI jobs have time limits. The smoke test installs only Chromium's headless shell
  (cached) instead of `--with-deps`, which spent 10+ minutes on a slow apt mirror.
- Light hits push less (jab 4 px, cross 6 px) so the combo stays in reach.

## [0.1.0] — 2026-10-23 (Milestone 1 / Task 001)

### Added — Milestone 1 / Task 001: cloud build pipeline
- Godot 4.7.2 client project (`client/`): test street, placeholder hero with lane movement
  (keyboard, gamepad, touch), bounded camera, HUD.
- Shared rules module `client/sim/LaneMovement.gd` with unit tests.
- Headless Godot test runner that fails tests on any engine or script error.
- Release web export preset (single-threaded, Compatibility renderer).
- Browser smoke test (Playwright + Chromium) that verifies boot and keyboard movement.
- API service skeleton (Node 24.22.1, Fastify): `/healthz`, `/readyz`, checksummed
  forward-only migration runner, migration `0001_accounts`.
- CI: repository policy, gdlint/gdformat, Godot tests, web export + smoke test + artifact
  with SHA-256 manifest, backend tests on PostgreSQL 16, image build + Trivy + SBOM.
  Security: gitleaks, npm audit, dependency review. Gated GitHub Pages deployment of the
  CI artifact.
- Documentation set and repository audit.

### Security
- Runtime image drops npm, npx and corepack (multi-stage build). Their bundled
  `brace-expansion` 5.0.9 and `undici` 6.28.0 had HIGH CVEs (CVE-2026-102276,
  CVE-2026-102278, CVE-2026-19534) reported by Trivy; the API never runs them.
