# Six-class weapon system: Phase 0 baseline and Phase 1 architecture

**Status: Phase 0 and Phase 1 only. No gameplay code, data, save format, test or
balance value was changed.**

Implementation (Phase 2 onwards) is **stopped** pending the owner decisions in §4.
The master prompt requires stopping on major architectural conflicts and on
destructive migrations, and §4 lists them.

Labels used below:

- **VERIFIED:** read in source, data, tests or docs.
- **PROPOSED:** a design, not built.
- **UNKNOWN:** could not be determined.

## 1. Phase 0: baseline

VERIFIED (2026-11-17):

| Item | Value |
|---|---|
| Branch | `claude/stoic-cori-i4r01i` |
| HEAD | `8fdd45b696f8c87170b5102dda24b7a7ba267a98`, the preserved baseline; working tree clean before this document |
| `origin/main` | `7bf5416`, unchanged |
| Godot tests | `godot --headless --path client --script res://tests/TestRunner.gd`: **975 passed, 0 failed** |
| Lint | `gdformat --check .` and `gdlint .`: clean (271 files) |
| Repo check | `tools/ci/check-repo.sh`: exit 0 |
| Unit test files | 246 in `client/tests/unit` |
| Test merchant | `client/project.godot` `iron_legacy/test_vendor_enabled=true` (known, unchanged; needs a separate release decision) |

## 2. The existing system

### 2.1 Characters, jobs and skills

All VERIFIED.

- **Five heroes, each bound to one job** (`heroes.json` `job`; BLUEPRINT D15,
  owner-approved 2026-11-10):

  | Hero | Job |
  |---|---|
  | `riku` | Boxer |
  | `kan` | Brawler |
  | `oren` | Grappler |
  | `dao` | Counter Fighter |
  | `mika` | Street Striker |

  The job is derived from the hero (`JobRules.job_of`). There is no separate
  class field.
- **Jobs** (`jobs.json`): name, role, combo, moveset, grab, skills and skill
  combos.
- **Skills** (`skills.json`, 45): data-driven, per job.
  - Each skill has `job`, `type` (active/passive/ultimate), `move`, `cooldown`,
    `unlock_level`, `icon`, `fx` and a `profiles.pve`/`pvp` balance profile
    (`BalanceProfile`).
  - Execution goes through `SkillRules`, `ComboRules`, `PassiveRules` and the 403
    entries in `moves.json`.
  - Auto battle chooses skills in `AutoSkills.gd` (158 lines).
  - The resources are energy (`CombatRules.MAX_ENERGY`) and an Ultimate gauge.
  - The hotbar has 7 slots, plus Grab and Ultimate keys.
- **Combat:** a 2D side-on beat 'em up (`CombatRules`, 712 lines).
  - Lanes, light/heavy, grab and throw, parry, juggle, poise.
  - Blows are fist or kick moves. BLUEPRINT D7 states the weapon slot is
    knuckles ("ต่อยด้วยหมัด", "fight with fists").
- **Size limit:** `ZoneSim.gd` is at 996 of the 1,000-line lint limit
  (`client/sim/CLAUDE.md`). New behaviour must go into helper classes.

### 2.2 Weapons

All VERIFIED.

- **Equipment slot `weapon`:** 48 items (43 legacy, 5 catalog). They are fist
  weapons, batons, pipes and crowbars, with no weapon family field. Examples:
  - Legendary: `baron_knuckledusters`, `harbour_hook`, `arthit_baton`.
  - Godforged world boss prizes: `sovereign_fists`, `iron_legacy`,
    `titan_slagfist`, `mothers_fang`, `founders_edge`.
- **Ground weapons** (`weapons.json`): 9 kinds (knife, bottle, plank, pipe,
  machete, chair, frying pan, wrench, baseball bat).
  - They are placed in 49 areas.
  - The hero can pick one up, use it until it breaks, and throw it.
  - 18 enemies wield or scavenge them.
  - 6 ranged enemies throw them as their projectile (`ZoneSim` "a ranged
    enemy's lob").
  - It is a BLUEPRINT core feature ("อาวุธจากพื้น 9 ชนิด", "9 kinds of ground
    weapon"). 12 unit test files touch it.
- **Held-weapon visuals already exist:** `art/lpc/characters.json`
  `weapon_pose` sets the held-weapon angle per frame for each animation.
- **Projectiles:** only thrown weapon objects. There is no player ranged attack
  or magic projectile system.

### 2.3 Art

All VERIFIED.

- Characters are built from the Universal LPC Spritesheet generator (commit
  pinned in `art/lpc/characters.json`).
- The licence policy allows only CC0, OGA-BY and CC-BY; CC-BY-SA and GPL parts
  need the owner's explicit approval.
- The animations used today are combat, walk, 1h_halfslash, spellcast, hurt and
  so on. The generator also has thrust, shoot and slash animations.
- Whether licence-compatible LPC sword, axe, spear, bow and staff sprites exist
  for every family is **UNKNOWN**. Many LPC weapon parts are CC-BY-SA or GPL.
- On hats, the owner said earlier: "Do not use LPC".

### 2.4 Saves

All VERIFIED.

- `PlayerProfile.SAVE_VERSION = 13`, with a one-step-at-a-time `migrate()`
  chain (v1 → v13).
- Version 11 already retired a hero (Pong) and migrated saves to Kan.
- `from_dict` returns `null` (the save does not load) if the saved hero id is
  unknown.
- It **silently drops unknown item ids** ("unknown content ids dropped"). That
  conflicts with the master prompt §7.3, which requires unknown ids to be kept.
- The backend stores accounts only (`backend/migrations/0001_accounts.sql`).
  Characters are local saves until IL-7.

### 2.5 Story

VERIFIED (`docs/STORY_BIBLE.md`, approved 2026-10-26, "the only source" for
names and places):

- **§1:** "ไม่มีเวทมนตร์" ("no magic"): every anomaly has an industrial,
  chemical or human cause.
- **§ heroes:** the five heroes and their jobs.

## 3. Reference findings: World of ClaudeCraft

VERIFIED at commit `d2b91e08`, read only. No code or assets copied.

| Topic | Reference file | What it does | Fit for The Iron Legacy |
|---|---|---|---|
| Class definitions | `src/sim/content/classes.ts` (`CLASSES`, `ClassDef`) | Per class: base stats, stats per level, `resourceType` (rage/mana/energy/focus), ability list | A `classes.json` with the same shape fits our data-driven `ContentDB` |
| Ability data | `src/sim/types.ts` `AbilityDef` (line 4451) | id, class, cost, castTime, cooldown, range, minRange, projectile, school, requiresTarget, passive | Matches our `skills.json` fields; we would add `class`, `weapon_family`, `category`, `range`, `target` |
| Equip gate | `src/sim/equipment_rules.ts` `canEquipItem` (line 422) | One function at the equipment boundary; class-locked items, archetype sets, special cases (`questTool`) | We need the same single gate in `PlayerProfile.equip_problem` |
| Class-locked loot | `src/sim/loot/class_locked_drop.ts` | A class-locked drop rolls only if a present class can use it; no extra RNG draws | Relevant to world boss and party drops (§4 D4) |
| Licence | `LICENSE` (MIT, code only), `CREDITS.md` (art per asset, some must not be redistributed) | | Ideas only |

## 4. Conflicts that need owner decisions (STOP)

Each item below is a decision the master prompt cannot settle without overriding
an approved document or risking player data. Each has a recommendation.

| # | Conflict (VERIFIED) | Options | Recommendation (PROPOSED) |
|---|---|---|---|
| **D1** | Mage with a staff and magic, against Story Bible §1 "no magic" | (a) Keep `mage` as the class id but make its power industrial: a "Core-rod" staff using arcs, coolant or chemical bursts with an in-world cause; (b) amend the Story Bible to allow magic; (c) a different sixth class | (a). No Story Bible rewrite; the class plays as ranged and area as requested. Needs your wording approval. |
| **D2** | Classes against heroes: BLUEPRINT D15 binds 5 story heroes to 5 jobs, and the Story Bible lists them | (a) **Decouple:** hero = identity and appearance; class chosen at creation; any hero can be any of the 6 classes; (b) six new story heroes; (c) map heroes to classes and add one hero | (a). Keeps the five story heroes, saves and art. Needs D15 replaced and a Story Bible edit. |
| **D3** | Existing saves: a hero's job is a fist job with no justified class equivalent; the prompt forbids converting everyone to Warrior | (a) Save v14 adds `"class": ""`; a legacy character keeps everything and picks its class once on first load (a one-time screen); (b) a fixed job → class map (for example Boxer → Assassin, Brawler → Berserker, Counter → Warrior), which is weakly justified | (a). Versioned, idempotent (an empty class means "not chosen"), nothing removed. |
| **D4** | The 48 existing weapon items (including 5 Godforged and 4 Legendary boss prizes) belong to no weapon family. World boss and stage boss reward tables pay them | (a) Assign each a family by an owner-approved table (changes item identity and art); (b) keep them as **legacy weapons** wearable by every class (an exception, like the reference's `questTool`); (c) add new family items and leave the old ones as legacy; (d) class-resolving drops (a boss drop becomes the killer's family), which changes reward semantics | (b) for owned copies, so nothing disappears. For future rewards, your choice of (a) or (d), each a reward-table decision you must approve. |
| **D5** | Removing ground-weapon pickup | (a) Remove the **hero's** pickup and throw only; keep `weapons.json`, enemy wielding and scavenging, and enemy projectiles; (b) remove everything | (a). Enemy AI and 6 ranged enemies depend on it. 12 test files change. |
| **D6** | Combat model: every move and animation is a fist or kick; 403 moves | The six classes need new movesets (light, heavy, combos, skills) per weapon and a new **projectile system** for Bow and Staff. Grab and throw: keep for all classes or only some? | Keep grab and parry for all (core beat 'em up feel); weapon movesets replace the fist movesets per class. Needs your confirmation on grab. |
| **D7** | The 45 job skills (6 active + 2 passive + 1 ultimate each) | (a) Retire them as legacy (data kept, unused); (b) reuse some as class skills | (a), with useful mechanics (combo, parry, juggle) reused inside the new skills. |
| **D8** | Art and licence: no licence-checked sword, axe, spear, dual-dagger, bow and staff sprites; LPC parts may be CC-BY-SA or GPL; you said "Do not use LPC" for hats | (a) Simple procedural or self-drawn placeholder weapons, marked TEMPORARY; (b) approve specific CC0 or CC-BY packs | (a) now, (b) later per pack |
| **D9** | Arena and class-balance tests are per job (`test_arena_integrity`, duel and arena harnesses) | Redo for 6 classes; the old job guard tests would be retired | Needs your approval: those tests guard your balance rules |
| **D10** | Scope | Several weeks of work in 8 phases; `ZoneSim` and `CombatRules` are near size limits | Deliver phase by phase, each phase tested and committed only with your authorization |

## 5. Proposed architecture (PROPOSED; after the decisions)

| Concern | Design | Where |
|---|---|---|
| Classes | `client/data/classes.json`: 6 entries (`warrior`, `assassin`, `berserker`, `lancer`, `mage`, `ranger`) with name, description, weapon family, base stats and scaling, resource, moveset, skill list and colour. Loaded and validated by `ContentDB` (exactly 6; unique ids; one family each) | data + `ClassRules.gd` (new, pure) |
| Weapon families | `weapon_family` field on weapon items (`sword`, `dual_daggers`, `axe`, `spear`, `staff`, `bow`); `legacy: true` for the 48 existing weapons per D4 | `items.json` / `item_catalog.json` (additive fields only) |
| Compatibility gate | One function `ClassRules.can_wield(class, item)`, called from `PlayerProfile.equip_problem` (equip, load, loot auto-equip, class pick, arena loadout). The only place the rule lives | `ClassRules.gd`, `PlayerProfile.gd` |
| Skills | `skills.json` gains `category` (`class` / `weapon`), `class`, `weapon_family`, `range`, `target`, `hits`, `damage_type`. Ids are new and unique; boss skill ids stay separate (`boss_skills.json`). Validation (owned, class, weapon, cooldown, resource, target, range, state) lives in `SkillRules` | data + `SkillRules.gd` |
| Projectiles | New pure `Projectiles.gd` in `sim/` (spawn, travel per tick, hit test, pierce, area). `ZoneSim` and `ArenaMatch` tick it. Reuses the thrown-weapon hit rules | new helper (`ZoneSim` cannot grow) |
| Auto combat | `AutoSkills` scores skills by availability, cost, range, number of targets and priority. Manual commands go through the same `SkillRules` validation, and auto resumes next tick (today's AutoBattle rule) | `AutoSkills.gd`, `AutoBattle.gd` |
| Weapon visuals | Extend the existing held-weapon overlay (`weapon_pose` angles per frame) to permanent weapons. Dual daggers draw two sprites (main and off hand); bow and staff use the shoot and spellcast poses | `FighterView.gd`, `EquipmentLayers.gd`, `characters.json` |
| Saves | v14: add `"class"`; keep unknown item ids in a `dormant_items` list instead of dropping them (fixes §2.4); one-time class pick for legacy saves (D3). Idempotent, tested from v1–v13 fixtures | `PlayerProfile.gd` |
| UI | Character tab shows the class; item cards show the weapon family and "Usable by: X"; the skills tab splits Class and Weapon skills; clear refusal messages | `CharacterTabs`, `ItemCard`, `ItemText` |

## 6. Test plan (PROPOSED)

- **New tests** for classes, the compatibility gate, skills (ownership, cooldown,
  resource, range, target, invalid ids), projectiles, auto combat (each state in
  the prompt §5.4) and save migration (v13 → v14, idempotent, unknown ids kept,
  every legacy hero).
- **Regression:** all 975 existing tests stay. Job-specific guard tests are
  replaced only with your approval (D9).
- **Balance:** 6 classes × farming, elite, mini-boss, stage boss, world boss and
  arena, using the existing harnesses with seeds and sample statistics, reported
  as in `docs/ITEM_POWER_MR_VALIDATION.md`.

## 7. Delivery plan (each step waits for your authorization)

1. Decisions D1–D10.
2. Phase 2:
   - `classes.json`, `ClassRules` and the gate.
   - Weapon family fields.
   - Save v14 with dormant items, behind the class pick.
3. Phase 3: weapon items per family (placeholder art), the visual overlay, and
   hero ground pickup off (D5).
4. Phase 4: the projectile system, then class and weapon skills per class.
5. Phase 5: auto-combat skill selection and manual commands.
6. Phase 6: UI.
7. Phases 8–9: balance runs and a full regression; docs and CHANGELOG.
