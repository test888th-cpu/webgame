# UNKNOWN field report (reference registries)

**Reference:** World of ClaudeCraft `d2b91e0884cb269422c28d0b42d2a30a01de130a`.
**Date:** 2026-11-17.

The authoritative counts are in
`data/registry/reference_registry_manifest.json` (`counts.unknown_values`).

## 1. Current status

| Registry | Records | UNKNOWN values |
|---|---:|---:|
| Monsters (`reference_monsters.json`) | 379 | **0** |
| Items (`reference_items.json`) | 2,263 | **0** |
| Loot entries (`reference_loot_entries.json`) | 1,190 | **0** |
| Reward-source data (`reference_loot_tables.json`, `reward_sources`) | 7 sources | **0** |
| Top-level load-time effects | 9 | **0** (all applied) |
| Approximated Math results reaching a registry | 226 calls examined | **0** (§3) |
| Unparsed statements (modules evaluated) | 118 modules | **0** |

## 2. The 68 mechanics resolved in this phase

The earlier text parse left these MobTemplate values UNKNOWN ("nested value not
parsed"). All are now evaluated from source; the values are in each record's
`mechanics` and `source_fields`.

| Field | Records | Resolved |
|---|---:|---|
| `trashKit` | 40 | nested objects and shared kits (for example `BRINE_MEND_KIT`, and cast ids from other modules) |
| `rankMechanics` | 14 | arrays of mechanic ids, or empty arrays (Rift bosses) |
| `petRanged` | 3 | nested objects (pets) |
| `arcCleave`, `breathCone` | 2 each | nested objects |
| `broodWhelp` | 2 | nested objects with a burn aura |
| `rangedMechanics`, `slams`, `starwake`, `warpath` | 1 each (`balgath_cyclops`) | nested objects and arrays |
| `deathThroes` | 1 (`crypt_bone_minion`) | two levels deep (`shrapnel`) |
| **Total** | **68** | |

## 3. Approximated Math audit (all 226 calls)

ECMAScript leaves `Math.sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp`,
`log`, `log2`, `log10`, `cbrt`, `hypot`, `pow` and the `**` operator
implementation-approximated, so V8 may return a different last bit than this
evaluator. The earlier report called the 226 calls "layout only" without per-call
evidence. This audit replaces that claim.

### How each call was traced

1. **Every Math call is recorded** by `tools/content/ts_eval.py` `Trace`, with its
   site (file:line), enclosing function and operation.
   - `**` and `Math.pow` count as exact only when both operands are integers and the
     result is an integer below 2^53. Every conforming engine returns that exactly.
2. **Taint follows the data.** Every approximated result carries its site through:
   - arithmetic and string building;
   - `Math.round` and the other built-ins;
   - object and array construction.
3. **Taint is checked at the registries.** The builder scans the raw evaluated tables
   for tainted values: `MOBS`, `ITEMS`, the Studio overlay, `HEROIC_BOSS_LOOT` and
   the reward-source data.
   - A tainted value would be REGISTRY_RELEVANT.
   - It would be written as `{"$unknown": "depends on an implementation-approximated
     operation", ...}`, never as a VERIFIED value.
4. **Decisions are recorded.** Every comparison, branch, truthiness test, property key,
   array index or sort comparison on a tainted value is recorded as a *decision*: a
   possible implicit flow.
5. **Decisions must stay confined.** The builder **fails** if any decision falls
   outside a reviewed binding in `reference_content.CONFINED_BINDINGS`.
   - It re-checks that each confined binding shares no object with any registry.
   - It re-checks that the binding's source references are exactly the recorded
     ones.
6. **Perturbation evidence.** `tools/content/audit_math_perturbation.py` rebuilt every
   registry with each site's results moved one ulp up, one ulp down, and grossly
   (×1.5 + 0.25, which flips every branch taken on it), and all sites together one
   ulp up and down. It compared the registries byte for byte, with the results in
   `data/registry/math_perturbation_audit.json`.

### Totals

| Measure | Value |
|---|---:|
| Math calls and `**` operations examined | 2896 |
| Exact deterministic operations | 2670 (Math.abs 2, Math.ceil 3, Math.floor 746, Math.max 768, Math.min 11, Math.round 1140) |
| Approximated operations | 226 at 27 sites |
| Proven irrelevant to registry data (NON_GAMEPLAY_LAYOUT_ONLY) | 226 |
| REGISTRY_RELEVANT | 0 |
| UNRESOLVED_DEPENDENCY | 0 |
| Decisions taken on approximated values | 62, all inside `gravewyrm_sanctum.ts#TUSKER_ROAD` |
| Registry bytes changed by any perturbation | 0 (83 rebuilds) |

**Conclusion: no approximated operation affects a registry value.** None of the 226
results reaches a monster, item, loot table, loot entry, chance, weight, roll group,
quantity, copper range, condition, classification, level or stat. The registries'
0-UNKNOWN count therefore holds, with this evidence.

### What the sites compute

All 27 sites compute **spatial data**:

- the facing angles of spawn rows (`across()` with `atan2`);
- ring and arc positions of props and spawns;
- muster drill lanes;
- the Sledge Tusker's patrol loop (`mob/patrol_route.ts`).

This is data the reference's world and AI use; **no registry records it**. Patrol
geometry is AI movement data, not "non-gameplay", in the strict sense. If map, spawn
or AI data is ever registered, these sites must be evaluated exactly or marked
UNKNOWN first.

**Why they are evaluated at all.** The heroic-variant load step
(`heroic_variants.ts:191`) iterates every dungeon's spawn list to find heroic-eligible
monster ids, and the lazy evaluator builds each spawn row whole, positions included.
Keeping those calculations out of the extraction path would need lazy object fields.
That is not practical, and it is not needed given the proof above.

**The 62 decisions.** They are corner and arc branches in `shuttleLoop`, `lane`, `arc`
and `sweep`, made while building `TUSKER_ROAD`.
- `TUSKER_ROAD` is named only at `gravewyrm_sanctum.ts:604` (its definition) and `:643`
  (`patrolling('sledge_tusker', TUSKER_ROAD, ...)`).
- The only registry-relevant reader of spawn rows reads `mobId`, which is the literal
  `'sledge_tusker'` here.

### Every approximated call site

The perturbation column shows one ulp up / one ulp down / gross.

| File (`src/sim/`) | Line | Function | Operation | Calls | Decisions on it | Perturbation | Result |
|---|---:|---|---|---:|---:|---|---|
| `content/drowned_temple.ts` | 724 | drowned_temple.ts across() | `Math.atan2` | 6 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/gravewyrm_sanctum.ts` | 769 | gravewyrm_sanctum.ts across() | `Math.atan2` | 7 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/hollow_crypt.ts` | 748 | hollow_crypt.ts across() | `Math.atan2` | 4 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/hollow_crypt_layout.ts` | 86 | hollow_crypt_layout.ts anonymous() | `Math.sin` | 3 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/hollow_crypt_layout.ts` | 87 | hollow_crypt_layout.ts anonymous() | `Math.cos` | 3 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/mirefen_muster.ts` | 111 | binding mirefen_muster.ts#MUSTER_DRILL_LANE | `Math.sin` | 1 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/mirefen_muster.ts` | 112 | binding mirefen_muster.ts#MUSTER_DRILL_LANE | `Math.cos` | 1 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/mirefen_muster.ts` | 129 | mirefen_muster.ts anonymous() | `Math.cos` | 1 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/mirefen_muster.ts` | 129 | mirefen_muster.ts anonymous() | `Math.sin` | 1 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/mirefen_muster.ts` | 130 | mirefen_muster.ts anonymous() | `Math.cos` | 1 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/mirefen_muster.ts` | 130 | mirefen_muster.ts anonymous() | `Math.sin` | 1 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/mirefen_muster.ts` | 136 | mirefen_muster.ts anonymous() | `Math.atan2` | 1 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/sunken_bastion.ts` | 742 | sunken_bastion.ts anonymous() | `Math.cos` | 12 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/sunken_bastion.ts` | 742 | sunken_bastion.ts anonymous() | `Math.sin` | 12 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/sunken_bastion.ts` | 948 | sunken_bastion.ts across() | `Math.atan2` | 3 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/sunken_bastion_layout.ts` | 107 | sunken_bastion_layout.ts anonymous() | `Math.sin` | 4 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/sunken_bastion_layout.ts` | 108 | sunken_bastion_layout.ts anonymous() | `Math.cos` | 4 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `content/wildheart.ts` | 1324 | wildheart.ts across() | `Math.atan2` | 7 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 115 | mob/patrol_route.ts dirOf() | `Math.hypot` | 10 | 62 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 134 | mob/patrol_route.ts arc() | `Math.cos` | 66 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 134 | mob/patrol_route.ts arc() | `Math.sin` | 66 | 0 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 164 | mob/patrol_route.ts lane() | `Math.acos` | 2 | 46 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 171 | mob/patrol_route.ts lane() | `Math.tan` | 2 | 44 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 185 | mob/patrol_route.ts lane() | `Math.atan2` | 2 | 44 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 186 | mob/patrol_route.ts lane() | `Math.atan2` | 2 | 44 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 214 | mob/patrol_route.ts anonymous() | `Math.atan2` | 2 | 4 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |
| `mob/patrol_route.ts` | 217 | mob/patrol_route.ts anonymous() | `Math.atan2` | 2 | 4 | identical / identical / identical | NON_GAMEPLAY_LAYOUT_ONLY |

## 4. What is still not modelled (not UNKNOWN values)

None of these is an UNKNOWN value: each is recorded with its source and scope.

| Item | Where | Why it is not modelled | Recorded as |
|---|---|---|---|
| ~~Draw sequences of the seven reward sources~~ | | **Resolved 2026-11-17:** each now has an execution model, verified against the source function (same scripted draws, every draw compared) and the reference's test goldens | `execution_model`, `reward_model_verification.json` |
| Source dependencies of two reward models | `worldQuestCycleNumber` (cycle id parsing); `weeklyRewardTableOptions` and `selectedWeeklyRewardTables` (class, spec, level and reservation filters) | they draw nothing; the models take their output, and verification calls the source functions themselves | `dependencies` in each model, with the source path |
| `addRiftProgressionLoot` (first-clear personal Rift rewards) | `src/sim/rift/progression.ts` | a separate path from the clear pools, outside the seven sources | `related_paths` of the Rift model: OUT OF SCOPE |
| Generator functions | `src/sim/instance_entities.ts:16`, `src/sim/nythraxis_raid_readouts.ts:48` | outside the evaluator's subset; neither feeds a registry | `unparsed` in the evaluator log; not loaded by any registry table |
| Implementation-approximated `Math` (`sin`, `cos`, `atan2`, `acos`, `tan`, `hypot`) | 226 calls at 27 sites | ECMAScript leaves their last bit to the engine | §3: traced per site; none reaches a registry value; the builder fails if that changes |

## 5. Earlier UNKNOWN items (other documents)

`REFERENCE_TRACEABILITY_MATRIX.md` "Reference values not verified" listed two items.
Both are resolved:

| Item | Resolution |
|---|---|
| `faithforged_guard` (paladin kit, not parsed by the scan) | an ability id (Debt of Light: `content/classes.ts:333`, `combat/paladin_debt_of_light.ts`), not an item; resolved earlier (CONTENT_COMPLETENESS_AUDIT.md §4.4) and recorded by the ability registry (R2, not started) |
| five mob-loot items with no static record | trinkets built by the `trinket()` helper (resolved earlier, §4.4); every one of the 661 loot items now resolves through the evaluated `ITEMS` table |

## 6. Corrections found by the evaluated registries

| Earlier value | Corrected value | Cause |
|---|---|---|
| 19 trinkets recorded with `kind: "trinket"` | `kind: "armor"`, `slot: "trinket"` (31 trinkets in all) | the text parse labelled `trinket()` records itself; the source never uses a `trinket` kind |
| `mount_lantern_hall_destrier` recorded as an item | a guild quartermaster offer (`GUILD_QUARTERMASTER_STOCK`), not an item; the item is `reins_lantern_hall_destrier` | the text parse matched any `{ id, kind }` object; the reins' id is a constant |
| 316 monsters, 1,948 items, 744 loot entries | 379, 2,263, 1,190 | records built by helpers, added at load, or keyed by constants were missed |
| flags boss 30, elite 155, worldBoss 2 | 34, 182, 3 | as above; `seasonalEvent` is a string, not `true` |
