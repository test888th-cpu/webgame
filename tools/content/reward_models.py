"""Execution models of the seven World of ClaudeCraft reward sources that do not use
LootEntry (buddy drops, world-quest loot, hoard bosses, treasure vaults, Rift clear
pools, the Drowned Litany chest and the weekly vault), and the runner that executes
them.

Each model is DATA: its entry point, triggers, eligibility, ownership, reset rules
and the ordered execution steps, every one with the source file and the code it
was read from (`cite`: the builder re-locates each citation in the pinned source
and fails if the code is gone). The steps are a small language:

  draw       one rng call: chance(p) / int(min, max) / pick(list) / next()
  let        bind a value
  if         a branch (both arms kept: never flattened into a static list)
  for_each   a loop over a list, in order, with an optional index
  for_range  a loop of a counted length
  push, remove_at   build or shrink a list in place
  emit       a reward (item, copper, buddy, choice, ...) with its owner
  submodel   run another model on the same rng (e.g. per-copy quality)
  seeded_rng a private deterministic generator (rng.ts Rng with a seed)
  return / set_result / continue

Expressions are JSON: literals, {"var"}, {"data"} (source values the builder
evaluates and stores with the model), {"get"}, {"op"} and {"call"} (a named
dependency: a source function or registry lookup, listed with its citation and
how it is resolved).

The runner (`run`) executes a model with a scripted random source and returns the
emitted rewards and the draw log (method, arguments, result). It applies the
reference's own Rng semantics (src/sim/rng.ts): int(min, max) =
floor(min + next() * (max + 1 - min)); chance(p) = next() < p; pick(a) =
a[floor(next() * a.length)]; the seeded generator is rng.ts's mulberry32.
tools/content/verify_reward_models.py runs every model against the real source
functions (static evaluator, same scripted draws) and the reference's own test
goldens. Nothing here is game code: the models are data, not adopted loot.
"""

from __future__ import annotations

import math

RNG_SEMANTICS = {
    "source": "src/sim/rng.ts",
    "next": "a uniform double in [0, 1) from the generator",
    "int(min, max)": "floor(min + next() * (max + 1 - min)), both bounds inclusive",
    "chance(p)": "next() < p",
    "pick(a)": "a[floor(next() * a.length)]",
    "seeded": "new Rng(seed): mulberry32 over seed >>> 0 (0 becomes 0x9e3779b9)",
}

# Shared sub-model: one copy's permanent quality (loot_quality/core.ts).
QUALITY = {
    "id": "loot_quality.create",
    "entry_point": {"file": "src/sim/loot_quality/core.ts", "cite": "export function createLootQuality(", "function": "createLootQuality"},
    "inputs": {},
    "steps": [
        {"do": "draw", "id": "quality_tier", "method": "int", "args": [0, 9999], "bind": "draw",
         "cite": ["src/sim/loot_quality/core.ts", "const draw = rng.int(0, 9999);"]},
        {"do": "if", "cond": {"op": "lt", "args": [{"var": "draw"}, 9000]},
         "then": [{"do": "set_result", "value": None}, {"do": "return"}],
         "cite": ["src/sim/loot_quality/core.ts", "if (draw < 9000) return undefined;"]},
        {"do": "let", "bind": "tier", "value": {"op": "if", "args": [
            {"op": "lt", "args": [{"var": "draw"}, 9900]}, 1,
            {"op": "if", "args": [{"op": "lt", "args": [{"var": "draw"}, 9990]}, 2,
                                  {"op": "if", "args": [{"op": "lt", "args": [{"var": "draw"}, 9999]}, 3, 4]}]}]},
         "cite": ["src/sim/loot_quality/core.ts", "const tier = draw < 9900 ? 1 : draw < 9990 ? 2 : draw < 9999 ? 3 : 4;"]},
        {"do": "let", "bind": "weights", "value": []},
        {"do": "for_range", "count": 5, "index": "w", "body": [
            {"do": "draw", "id": "quality_weight", "method": "int", "args": [1, 1000], "bind": "x"},
            {"do": "push", "list": "weights", "value": {"var": "x"}}],
         "cite": ["src/sim/loot_quality/core.ts", "rng.int(1, 1000),"]},
        {"do": "set_result", "value": {"op": "dict", "fields": {"tier": {"var": "tier"}, "weights": {"var": "weights"}}}},
    ],
}

# isEligibleLootQualityItem (loot_quality/core.ts), as an expression over an item record.
ITEM_QUALITY_ELIGIBLE = {"op": "and", "args": [
    {"op": "truthy", "args": [{"get": [{"var": "item"}, "slot"]}]},
    {"op": "in", "args": [{"get": [{"var": "item"}, "kind"]}, ["weapon", "armor", "held_offhand"]]},
    {"op": "in", "args": [{"op": "default", "args": [{"get": [{"var": "item"}, "quality"]}, "common"]},
                          ["uncommon", "rare", "epic", "legendary"]]},
]}

# rollFreshLootQualities (loot/fresh_quality_grant.ts): one quality per copy of an eligible item.
FRESH_QUALITY = {
    "id": "loot.fresh_quality",
    "entry_point": {"file": "src/sim/loot/fresh_quality_grant.ts", "cite": "export function rollFreshLootQualities(", "function": "rollFreshLootQualities"},
    "inputs": {"item_id": "item id", "count": "copies"},
    "steps": [
        {"do": "let", "bind": "item", "value": {"call": "item", "args": [{"var": "item_id"}]}},
        {"do": "let", "bind": "out", "value": []},
        {"do": "if", "cond": {"op": "or", "args": [
            {"op": "eq", "args": [{"var": "item"}, None]},
            {"op": "not", "args": [ITEM_QUALITY_ELIGIBLE]},
            {"op": "not", "args": [{"op": "ge", "args": [{"var": "count"}, 1]}]}]},
         "then": [{"do": "set_result", "value": []}, {"do": "return"}],
         "cite": ["src/sim/loot/fresh_quality_grant.ts", "if (!item || !isEligibleLootQualityItem(item) || !(count >= 1)) return [];"]},
        {"do": "for_range", "count": {"op": "floor", "args": [{"var": "count"}]}, "index": "c", "body": [
            {"do": "submodel", "model": "loot_quality.create", "args": {}, "bind": "q"},
            {"do": "push", "list": "out", "value": {"var": "q"}}],
         "cite": ["src/sim/loot/fresh_quality_grant.ts", "return Array.from({ length: Math.floor(count) }, () => createLootQuality(rng));"]},
        {"do": "set_result", "value": {"var": "out"}},
    ],
}

# rollEnemyLootQuality (loot/enemy_quality.ts): per copy of each eligible slot, when the
# killed mob is an eligible source.
ENEMY_QUALITY = {
    "id": "loot.enemy_quality",
    "entry_point": {"file": "src/sim/loot/enemy_quality.ts", "cite": "export function rollEnemyLootQuality(", "function": "rollEnemyLootQuality"},
    "inputs": {"source_eligible": "isEligibleEnemyQualitySource(mob)", "slots": "new loot slots [{itemId, count}]"},
    "steps": [
        {"do": "if", "cond": {"op": "not", "args": [{"var": "source_eligible"}]},
         "then": [{"do": "set_result", "value": {"var": "slots"}}, {"do": "return"}],
         "cite": ["src/sim/loot/enemy_quality.ts", "if (!isEligibleEnemyQualitySource(mob)) return slots;"]},
        {"do": "let", "bind": "out", "value": []},
        {"do": "for_each", "in": {"var": "slots"}, "as": "slot", "body": [
            {"do": "let", "bind": "item", "value": {"call": "item", "args": [{"get": [{"var": "slot"}, "itemId"]}]}},
            {"do": "if", "cond": {"op": "or", "args": [{"op": "eq", "args": [{"var": "item"}, None]},
                                                        {"op": "not", "args": [ITEM_QUALITY_ELIGIBLE]}]},
             "then": [{"do": "push", "list": "out", "value": {"var": "slot"}}, {"do": "continue"}]},
            {"do": "for_range", "count": {"get": [{"var": "slot"}, "count"]}, "index": "c", "body": [
                {"do": "submodel", "model": "loot_quality.create", "args": {}, "bind": "q"},
                {"do": "push", "list": "out", "value": {"op": "dict", "fields": {
                    "itemId": {"get": [{"var": "slot"}, "itemId"]}, "count": 1, "quality": {"var": "q"}}}}]}],
         "cite": ["src/sim/loot/enemy_quality.ts", "return Array.from({ length: slot.count }, () => {"]},
        {"do": "set_result", "value": {"var": "out"}},
    ],
}

# ---------------------------------------------------------------------------
# 1. Buddy drops

BUDDY = {
    "id": "buddy_boss_drops",
    "source_type": "per-player boss roll (companions, not items)",
    "entry_point": {"file": "src/sim/buddy_drops.ts", "cite": "export function rollBossBuddyDrops(", "function": "rollBossBuddyDrops"},
    "triggers": [
        {"rule": "an instance boss death on the kill-credit path, for a non-world boss, with the claim the boss died inside",
         "cite": ["src/sim/combat/damage.ts", "rollBossBuddyDrops(ctx, e, heroicRewardRecipients, claimedInst);"]},
        {"rule": "a world boss death, on the never-pruned contributor roster, with no claim (inst = null)",
         "cite": ["src/sim/combat/damage.ts", "rollBossBuddyDrops(ctx, e, worldBossContribs, null);"]},
    ],
    "eligibility": [
        {"rule": "instance kills: the credited party members whose participation position is in range, or the credited player alone",
         "cite": ["src/sim/combat/damage.ts", "if (eligible.length === 0) eligible.push(meta);"]},
        {"rule": "a row marked heroicOnly rolls only when the claim's difficulty is 'heroic' (no draw otherwise)",
         "cite": ["src/sim/buddy_drops.ts", "if (row.heroicOnly && !heroic) continue;"]},
        {"rule": "only bosses listed in BUDDY_BOSS_DROPS have rows; every other kill draws nothing",
         "cite": ["src/sim/buddy_drops.ts", "if (rows.length === 0 || recipients.length === 0) return;"]},
    ],
    "ownership": {"rule": "personal: each recipient rolls for themself; a win attaches a PENDING buddy to that player, revealed on zone-out (instance) or at 80 yards (world)",
                  "cite": ["src/sim/buddy_drops.ts", "attachPendingBuddy(ctx, meta.entityId, row.key, source, { x: boss.pos.x, z: boss.pos.z });"]},
    "duplicates": {"rule": "the draw is made even when the player already owns the companion (fixed draw count per player and row)",
                   "cite": ["src/sim/buddy_drops.ts", "const won = ctx.rng.chance(chance);"]},
    "reset": "none: no lockout or weekly limit in this path (inspected; not present)",
    "quantity": "one buddy per winning row (inspected: no quantity field)",
    "currency": "none (inspected: not present)",
    "data": {"BUDDY_BOSS_DROPS": ["src/sim/content/buddy_sources.ts", "BUDDY_BOSS_DROPS"],
             "BUDDY_FULL_GROUP": ["src/sim/content/buddy_sources.ts", "BUDDY_FULL_GROUP"]},
    "dependencies": {},
    "inputs": {"boss_template_id": "the dead boss's template id", "recipients": "[{entityId}] in the order the death site hands them",
               "claim": "{difficulty} of the instance claim, or null for a world boss"},
    "steps": [
        {"do": "let", "bind": "rows", "value": {"op": "filter", "list": {"data": "BUDDY_BOSS_DROPS"}, "as": "r",
                                                "where": {"op": "eq", "args": [{"get": [{"var": "r"}, "bossId"]}, {"var": "boss_template_id"}]}},
         "cite": ["src/sim/content/buddy_sources.ts", "export function buddyBossDropsFor(bossId: string)"]},
        {"do": "if", "cond": {"op": "or", "args": [{"op": "eq", "args": [{"op": "len", "args": [{"var": "rows"}]}, 0]},
                                                    {"op": "eq", "args": [{"op": "len", "args": [{"var": "recipients"}]}, 0]}]},
         "then": [{"do": "return"}], "cite": ["src/sim/buddy_drops.ts", "if (rows.length === 0 || recipients.length === 0) return;"]},
        {"do": "let", "bind": "heroic", "value": {"op": "and", "args": [{"op": "ne", "args": [{"var": "claim"}, None]},
                                                                         {"op": "eq", "args": [{"get": [{"var": "claim"}, "difficulty"]}, "heroic"]}]},
         "cite": ["src/sim/buddy_drops.ts", "const heroic = inst?.difficulty === 'heroic';"]},
        {"do": "let", "bind": "source", "value": {"op": "if", "args": [{"op": "ne", "args": [{"var": "claim"}, None]}, "instance", "world"]},
         "cite": ["src/sim/buddy_drops.ts", "const source = inst ? 'instance' : 'world';"]},
        {"do": "let", "bind": "n", "value": {"op": "len", "args": [{"var": "recipients"}]}},
        {"do": "for_each", "in": {"var": "recipients"}, "as": "meta", "body": [
            {"do": "for_each", "in": {"var": "rows"}, "as": "row", "body": [
                {"do": "if", "cond": {"op": "and", "args": [{"op": "truthy", "args": [{"get": [{"var": "row"}, "heroicOnly"]}]},
                                                             {"op": "not", "args": [{"var": "heroic"}]}]},
                 "then": [{"do": "continue"}]},
                {"do": "let", "bind": "chance", "value": {"op": "if", "args": [
                    {"op": "ge", "args": [{"var": "n"}, {"data": "BUDDY_FULL_GROUP"}]},
                    {"get": [{"var": "row"}, "chance"]},
                    {"op": "div", "args": [{"op": "mul", "args": [{"get": [{"var": "row"}, "chance"]}, {"data": "BUDDY_FULL_GROUP"}]},
                                           {"op": "max", "args": [1, {"var": "n"}]}]}]},
                 "cite": ["src/sim/content/buddy_sources.ts", "return (chance * BUDDY_FULL_GROUP) / Math.max(1, recipients);"]},
                {"do": "draw", "id": "buddy_roll", "method": "chance", "args": [{"var": "chance"}], "bind": "won"},
                {"do": "if", "cond": {"var": "won"}, "then": [
                    {"do": "emit", "kind": "buddy", "fields": {"owner": {"get": [{"var": "meta"}, "entityId"]},
                                                               "key": {"get": [{"var": "row"}, "key"]}, "source": {"var": "source"}}}]}]}],
         "cite": ["src/sim/buddy_drops.ts", "for (const meta of recipients) {"]},
    ],
}

# ---------------------------------------------------------------------------
# 2. World-quest loot (the day's item; deterministic, no ctx.rng)

WORLD_QUEST = {
    "id": "world_quest_class_loot",
    "source_type": "deterministic daily item per cycle, zone and class (seeded generator; no ctx.rng draw)",
    "entry_point": {"file": "src/sim/world_quest_item_slots.ts", "cite": "export function worldQuestItemRewardForQuest(", "function": "worldQuestItemRewardForQuest"},
    "triggers": [{"rule": "a world quest turn-in (awardWorldQuest), after XP and copper and the quest's fixed extra item",
                  "cite": ["src/sim/world_quests.ts", "const dailyItemId = worldQuestItemRewardForQuest(meta.worldQuestCycle, quest, meta.cls, level);"]}],
    "eligibility": [
        {"rule": "the character's level at turn-in is at least WORLD_QUEST_ITEM_MIN_LEVEL (16)",
         "cite": ["src/sim/world_quest_item_slots.ts", "if (level < WORLD_QUEST_ITEM_MIN_LEVEL) return null;"]},
        {"rule": "always-active daily quests never carry the item",
         "cite": ["src/sim/world_quest_item_slots.ts", "if (ALWAYS_ACTIVE_WORLD_QUEST_IDS.includes(quest.id)) return null;"]},
        {"rule": "the quest's zone is one of the cycle's three item zones",
         "cite": ["src/sim/world_quest_item_slots.ts", "if (!worldQuestItemZonesForCycle(cycle).includes(zoneId)) return null;"]},
    ],
    "ownership": {"rule": "personal to the completing character; into bags, or posted to the Ravenpost when the bags cannot hold it",
                  "cite": ["src/sim/world_quests.ts", "grantWorldQuestRewardItems(ctx, meta, rewardItems);"]},
    "duplicates": {"rule": "fixed per cycle, zone and class: a reroll in the same zone keeps the day's item; once per quest completion per cycle",
                   "cite": ["src/sim/world_quest_item_slots.ts", "export function worldQuestItemRewardFor("]},
    "reset": "per world-quest cycle (worldQuestCycleNumber of the realm's reset day)",
    "quantity": "count 1",
    "currency": "the quest bundle's XP, copper, Honor and standing are quest rewards, not this source (world_quests.ts awardWorldQuest)",
    "data": {"WORLD_QUEST_CLASS_LOOT": ["src/sim/content/world_quest_loot.ts", "WORLD_QUEST_CLASS_LOOT"],
             "WORLD_QUEST_ITEM_ZONES": ["src/sim/world_quest_item_slots.ts", "WORLD_QUEST_ITEM_ZONES"],
             "ALWAYS_ACTIVE_WORLD_QUEST_IDS": ["src/sim/world_quest_rotation.ts", "ALWAYS_ACTIVE_WORLD_QUEST_IDS"],
             "ALL_CLASSES": ["src/sim/types.ts", "ALL_CLASSES"],
             "SLOTS_PER_CYCLE": ["src/sim/world_quest_item_slots.ts", "WORLD_QUEST_ITEM_SLOTS_PER_CYCLE"],
             "MIN_LEVEL": ["src/sim/world_quest_item_slots.ts", "WORLD_QUEST_ITEM_MIN_LEVEL"],
             "SLOT_SEED_SALT": ["src/sim/world_quest_item_slots.ts", "SLOT_SEED_SALT"],
             "ITEM_SEED_SALT": ["src/sim/world_quest_item_slots.ts", "ITEM_SEED_SALT"]},
    "dependencies": {},
    "inputs": {"cycle": "the character's world-quest cycle id", "quest": "{id, zoneId}", "cls": "player class", "level": "level at turn-in"},
    "steps": [
        {"do": "if", "cond": {"op": "lt", "args": [{"var": "level"}, {"data": "MIN_LEVEL"}]}, "then": [{"do": "return"}]},
        {"do": "if", "cond": {"op": "in", "args": [{"get": [{"var": "quest"}, "id"]}, {"data": "ALWAYS_ACTIVE_WORLD_QUEST_IDS"}]},
         "then": [{"do": "return"}]},
        {"do": "submodel", "model": "world_quest.cycle_number", "args": {"cycle": {"var": "cycle"}}, "bind": "number",
         "cite": ["src/sim/world_quest_item_slots.ts", "const number = worldQuestCycleNumber(cycle);"]},
        {"do": "if", "cond": {"op": "eq", "args": [{"var": "number"}, None]}, "then": [{"do": "return"}]},
        {"do": "seeded_rng", "bind": "slot_rng", "seed": {"op": "u32", "args": [{"op": "add", "args": [{"data": "SLOT_SEED_SALT"}, {"var": "number"}]}]},
         "cite": ["src/sim/world_quest_item_slots.ts", "const rng = new Rng((SLOT_SEED_SALT + number) >>> 0);"]},
        {"do": "let", "bind": "pool", "value": {"op": "copy", "args": [{"data": "WORLD_QUEST_ITEM_ZONES"}]}},
        {"do": "let", "bind": "zones", "value": []},
        {"do": "for_range", "count": {"op": "min", "args": [{"data": "SLOTS_PER_CYCLE"}, {"op": "len", "args": [{"var": "pool"}]}]}, "index": "slot", "body": [
            {"do": "draw", "id": "zone_pick", "rng": "slot_rng", "method": "int",
             "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"var": "pool"}]}, 1]}], "bind": "index"},
            {"do": "push", "list": "zones", "value": {"get": [{"var": "pool"}, {"var": "index"}]}},
            {"do": "remove_at", "list": "pool", "index": {"var": "index"}}],
         "cite": ["src/sim/world_quest_item_slots.ts", "pool.splice(index, 1);"]},
        {"do": "if", "cond": {"op": "not", "args": [{"op": "in", "args": [{"get": [{"var": "quest"}, "zoneId"]}, {"var": "zones"}]}]},
         "then": [{"do": "return"}]},
        {"do": "let", "bind": "table", "value": {"get": [{"data": "WORLD_QUEST_CLASS_LOOT"}, {"var": "cls"}]}},
        {"do": "if", "cond": {"op": "eq", "args": [{"op": "len", "args": [{"var": "table"}]}, 0]}, "then": [{"do": "return"}]},
        {"do": "seeded_rng", "bind": "item_rng", "seed": {"op": "u32", "args": [{"op": "add", "args": [
            {"op": "add", "args": [{"op": "add", "args": [{"data": "ITEM_SEED_SALT"}, {"op": "mul", "args": [{"var": "number"}, 1009]}]},
                                   {"op": "mul", "args": [{"op": "index_of", "args": [{"data": "WORLD_QUEST_ITEM_ZONES"}, {"get": [{"var": "quest"}, "zoneId"]}]}, 31]}]},
            {"op": "index_of", "args": [{"data": "ALL_CLASSES"}, {"var": "cls"}]}]}]},
         "cite": ["src/sim/world_quest_item_slots.ts", "const rng = new Rng((ITEM_SEED_SALT + number * 1009 + zoneIndex * 31 + classIndex) >>> 0);"]},
        {"do": "draw", "id": "item_pick", "rng": "item_rng", "method": "int",
         "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"var": "table"}]}, 1]}], "bind": "k"},
        {"do": "emit", "kind": "item", "fields": {"itemId": {"get": [{"var": "table"}, {"var": "k"}]}, "count": 1, "owner": "completer"}},
    ],
}

# ---------------------------------------------------------------------------
# 3. Hoard bosses (one piece off the fallen keeper's table)

HOARD = {
    "id": "hoard_boss_loot",
    "source_type": "one gear piece per winning gear roll of a treasure-vault reward (sub-roll of treasure_vault_payouts)",
    "entry_point": {"file": "src/sim/content/hoard_loot.ts", "cite": "export function rollHoardBossDrop(", "function": "rollHoardBossDrop"},
    "triggers": [{"rule": "called by rollHoardReward only when its gear chance succeeds",
                  "cite": ["src/sim/rift/hoard_reward_roll.ts", "itemId: rollHoardBossDrop(rng, input.bossTemplateId, input.rarity, input.cls),"]}],
    "eligibility": [{"rule": "70% of rolls prefer pieces aimed at the looter's class (requiredClass includes it, or none); the rest roll the whole table",
                     "cite": ["src/sim/content/hoard_loot.ts", "export const HOARD_LOOT_CLASS_BIAS = 0.7;"]}],
    "ownership": {"rule": "the vault entrant whose reward is being rolled (personal parcel)", "cite": ["src/sim/treasure_vault.ts", "export function payTreasureVault("]},
    "duplicates": {"rule": "no duplicate guard (inspected: not present)", "cite": ["src/sim/content/hoard_loot.ts", "const baseId = candidates[rng.int(0, candidates.length - 1)];"]},
    "reset": "none in this function (inspected; not present)",
    "quantity": "count 1 (set by the caller)",
    "currency": "none",
    "data": {"HOARD_BOSS_LOOT_TABLES": ["src/sim/content/hoard_loot.ts", "HOARD_BOSS_LOOT_TABLES"],
             "HOARD_BASE_ITEM_IDS": ["src/sim/content/hoard_loot.ts", "HOARD_BASE_ITEM_IDS"],
             "CLASS_BIAS": ["src/sim/content/hoard_loot.ts", "HOARD_LOOT_CLASS_BIAS"]},
    "dependencies": {"item": {"source": "ITEMS (src/sim/data.ts)", "resolved_by": "the reference item registry (requiredClass)"}},
    "inputs": {"boss_template_id": "fallen keeper's template id, or null", "rarity": "map rarity", "cls": "looter class, or null"},
    "steps": [
        {"do": "let", "bind": "table", "value": {"op": "default", "args": [
            {"op": "if", "args": [{"op": "truthy", "args": [{"var": "boss_template_id"}]},
                                  {"get": [{"data": "HOARD_BOSS_LOOT_TABLES"}, {"var": "boss_template_id"}]}, None]},
            {"data": "HOARD_BASE_ITEM_IDS"}]},
         "cite": ["src/sim/content/hoard_loot.ts", "(bossTemplateId ? HOARD_BOSS_LOOT_TABLES[bossTemplateId] : undefined) ?? HOARD_BASE_ITEM_IDS;"]},
        {"do": "let", "bind": "usable", "value": {"op": "if", "args": [{"op": "truthy", "args": [{"var": "cls"}]},
            {"op": "filter", "list": {"var": "table"}, "as": "id", "where": {"op": "or", "args": [
                {"op": "not", "args": [{"op": "truthy", "args": [{"get": [{"call": "item", "args": [{"var": "id"}]}, "requiredClass"]}]}]},
                {"op": "in", "args": [{"var": "cls"}, {"get": [{"call": "item", "args": [{"var": "id"}]}, "requiredClass"]}]}]}},
            []]}},
        {"do": "draw", "id": "class_bias", "method": "chance", "args": [{"data": "CLASS_BIAS"}], "bind": "biased",
         "cite": ["src/sim/content/hoard_loot.ts", "const biased = rng.chance(HOARD_LOOT_CLASS_BIAS);"]},
        {"do": "let", "bind": "candidates", "value": {"op": "if", "args": [
            {"op": "and", "args": [{"var": "biased"}, {"op": "gt", "args": [{"op": "len", "args": [{"var": "usable"}]}, 0]}]},
            {"var": "usable"}, {"var": "table"}]}},
        {"do": "draw", "id": "piece_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"var": "candidates"}]}, 1]}], "bind": "k"},
        {"do": "let", "bind": "tier", "value": {"op": "if", "args": [{"op": "eq", "args": [{"var": "rarity"}, "legendary"]}, "legendary",
                                                                     {"op": "if", "args": [{"op": "eq", "args": [{"var": "rarity"}, "epic"]}, "epic", "rare"]}]},
         "cite": ["src/sim/content/hoard_loot.ts", "return rarity === 'legendary' ? 'legendary' : rarity === 'epic' ? 'epic' : 'rare';"]},
        {"do": "set_result", "value": {"op": "if", "args": [{"op": "eq", "args": [{"var": "tier"}, "epic"]},
                                                             {"get": [{"var": "candidates"}, {"var": "k"}]},
                                                             {"op": "concat_str", "args": [{"var": "tier"}, "_", {"get": [{"var": "candidates"}, {"var": "k"}]}]}]},
         "cite": ["src/sim/content/hoard_loot.ts", "return tier === 'epic' ? baseId : `${tier}_${baseId}`;"]},
    ],
}

# ---------------------------------------------------------------------------
# 4. Treasure vaults (rollHoardReward, per entrant)

VAULT = {
    "id": "treasure_vault_payouts",
    "source_type": "per-entrant parcel when a treasure-map vault's boss falls",
    "entry_point": {"file": "src/sim/rift/hoard_reward_roll.ts", "cite": "export function rollHoardReward(", "function": "rollHoardReward"},
    "triggers": [
        {"rule": "the vault boss falls (local run): payTreasureVault rolls once per participant",
         "cite": ["src/sim/treasure_vault.ts", "const reward = rollHoardReward(ctx.rng, {"]},
        {"rule": "the vault boss falls (saved-reward host): one roll per entrant snapshot, frozen into a claim",
         "cite": ["src/sim/rift/runs.ts", "const reward = rollHoardReward(ctx.rng, {"]},
    ],
    "eligibility": [
        {"rule": "payTreasureVault skips a participant with no meta or entity, or who is leaving",
         "cite": ["src/sim/treasure_vault.ts", "if (!meta || !player || meta.leaving) continue;"]},
        {"rule": "the owner (by entity id or character id) uses the rarity's gearChance; a guest uses VAULT_GUEST_GEAR_CHANCE",
         "cite": ["src/sim/rift/hoard_reward_roll.ts", "if (rng.chance(input.owner ? def.gearChance : VAULT_GUEST_GEAR_CHANCE[input.rarity])) {"]},
        {"rule": "guestCapped is passed in but never read by rollHoardReward: the code always draws and returns capped: false. Its doc comment ('A capped guest takes no draws') does not match the code; the model follows the code",
         "cite": ["src/sim/rift/hoard_reward_roll.ts", "capped: false,"]},
    ],
    "ownership": {"rule": "personal parcel per entrant (grantHoardReward)", "cite": ["src/sim/treasure_vault.ts", "paid = grantHoardReward(ctx, pid, vault.rarity, reward) || paid;"]},
    "duplicates": {"rule": "the mount chance is drawn even when the mount is owned; the item is then withheld. The next-map chance is drawn even at the top rarity; nothing is paid then",
                   "cite": ["src/sim/rift/hoard_reward_roll.ts", "if (rng.chance(def.mountChance) && !input.mountOwned)"]},
    "reset": "none in this function; vault entry and lifetime rules live in treasure_vault.ts (not a draw rule)",
    "quantity": "materials: VAULT_PAYOUTS[rarity].materials; marks: .marks; everything else count 1",
    "currency": "copper = round(treasureCasketCopper(level) x copperMult x (1.5 for the owner)); Heroic Marks as an item stack",
    "data": {"VAULT_PAYOUTS": ["src/sim/content/treasure_maps.ts", "VAULT_PAYOUTS"],
             "VAULT_MATERIAL_POOL": ["src/sim/content/treasure_maps.ts", "VAULT_MATERIAL_POOL"],
             "VAULT_GUEST_GEAR_CHANCE": ["src/sim/content/treasure_maps.ts", "VAULT_GUEST_GEAR_CHANCE"],
             "VAULT_OWNER_COPPER_BONUS": ["src/sim/content/treasure_maps.ts", "VAULT_OWNER_COPPER_BONUS"],
             "TREASURE_MAP_RARITIES": ["src/sim/content/treasure_maps.ts", "TREASURE_MAP_RARITIES"],
             "TREASURE_MAP_ITEM_IDS": ["src/sim/content/treasure_maps.ts", "TREASURE_MAP_ITEM_IDS"],
             "HEROIC_MARK_CURRENCY_ID": ["src/sim/content/dungeon_difficulty.ts", "HEROIC_MARK_CURRENCY_ID"],
             "MOUNT_REINS": ["src/sim/rift/hoard_reward_roll.ts", "VAULT_MOUNT_REINS_ITEM_ID"],
             "CASKET_COPPER_BASE": ["src/sim/clue_casket.ts", "CASKET_COPPER_BASE"],
             "CASKET_COPPER_PER_LEVEL": ["src/sim/clue_casket.ts", "CASKET_COPPER_PER_LEVEL"]},
    "dependencies": {"item": {"source": "ITEMS (src/sim/data.ts)", "resolved_by": "the reference item registry"}},
    "inputs": {"rarity": "map rarity", "boss_template_id": "fallen keeper", "cls": "entrant class", "level": "entrant level",
               "owner": "true for the map's owner", "guest_capped": "passed, unread", "mount_owned": "entrant owns the vault mount"},
    "steps": [
        {"do": "let", "bind": "def", "value": {"get": [{"data": "VAULT_PAYOUTS"}, {"var": "rarity"}]}},
        {"do": "draw", "id": "material_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"data": "VAULT_MATERIAL_POOL"}]}, 1]}], "bind": "m",
         "cite": ["src/sim/rift/hoard_reward_roll.ts", "const material = VAULT_MATERIAL_POOL[rng.int(0, VAULT_MATERIAL_POOL.length - 1)];"]},
        {"do": "emit", "kind": "item", "fields": {"itemId": {"get": [{"data": "VAULT_MATERIAL_POOL"}, {"var": "m"}]}, "count": {"get": [{"var": "def"}, "materials"]}}},
        {"do": "let", "bind": "gear", "value": None},
        {"do": "draw", "id": "gear_roll", "method": "chance", "args": [{"op": "if", "args": [{"var": "owner"}, {"get": [{"var": "def"}, "gearChance"]},
                                                                                              {"get": [{"data": "VAULT_GUEST_GEAR_CHANCE"}, {"var": "rarity"}]}]}], "bind": "g"},
        {"do": "if", "cond": {"var": "g"}, "then": [
            {"do": "submodel", "model": "hoard_boss_loot", "args": {"boss_template_id": {"var": "boss_template_id"}, "rarity": {"var": "rarity"}, "cls": {"var": "cls"}}, "bind": "gear"},
            {"do": "emit", "kind": "item", "fields": {"itemId": {"var": "gear"}, "count": 1}}]},
        {"do": "draw", "id": "marks_roll", "method": "chance", "args": [{"get": [{"var": "def"}, "markChance"]}], "bind": "mk"},
        {"do": "if", "cond": {"var": "mk"}, "then": [
            {"do": "emit", "kind": "item", "fields": {"itemId": {"data": "HEROIC_MARK_CURRENCY_ID"}, "count": {"get": [{"var": "def"}, "marks"]}}}]},
        {"do": "draw", "id": "mount_roll", "method": "chance", "args": [{"get": [{"var": "def"}, "mountChance"]}], "bind": "mt"},
        {"do": "if", "cond": {"op": "and", "args": [{"var": "mt"}, {"op": "not", "args": [{"var": "mount_owned"}]}]}, "then": [
            {"do": "emit", "kind": "item", "fields": {"itemId": {"data": "MOUNT_REINS"}, "count": 1}}]},
        {"do": "let", "bind": "next", "value": {"get": [{"data": "TREASURE_MAP_RARITIES"},
                                                        {"op": "add", "args": [{"op": "index_of", "args": [{"data": "TREASURE_MAP_RARITIES"}, {"var": "rarity"}]}, 1]}]},
         "cite": ["src/sim/content/treasure_maps.ts", "return TREASURE_MAP_RARITIES[index + 1] ?? null;"]},
        {"do": "draw", "id": "next_map_roll", "method": "chance", "args": [{"get": [{"var": "def"}, "nextMapChance"]}], "bind": "nm"},
        {"do": "if", "cond": {"op": "and", "args": [{"var": "nm"}, {"op": "truthy", "args": [{"var": "next"}]}]}, "then": [
            {"do": "emit", "kind": "item", "fields": {"itemId": {"get": [{"data": "TREASURE_MAP_ITEM_IDS"}, {"var": "next"}]}, "count": 1}}]},
        {"do": "if", "cond": {"op": "ne", "args": [{"var": "gear"}, None]}, "then": [
            {"do": "submodel", "model": "loot.fresh_quality", "args": {"item_id": {"var": "gear"}, "count": 1}, "bind": "qs"},
            {"do": "if", "cond": {"op": "and", "args": [{"op": "gt", "args": [{"op": "len", "args": [{"var": "qs"}]}, 0]},
                                                         {"op": "ne", "args": [{"get": [{"var": "qs"}, 0]}, None]}]},
             "then": [{"do": "emit", "kind": "quality", "fields": {"itemId": {"var": "gear"}, "quality": {"get": [{"var": "qs"}, 0]}}}]}],
         "cite": ["src/sim/rift/hoard_reward_roll.ts", "const [lootQuality] = gear ? rollFreshLootQualities(rng, gear.itemId, 1) : [];"]},
        {"do": "let", "bind": "base", "value": {"op": "mul", "args": [
            {"op": "add", "args": [{"data": "CASKET_COPPER_BASE"},
                                   {"op": "mul", "args": [{"data": "CASKET_COPPER_PER_LEVEL"}, {"op": "max", "args": [1, {"op": "floor", "args": [{"var": "level"}]}]}]}]},
            {"get": [{"var": "def"}, "copperMult"]}]},
         "cite": ["src/sim/clue_casket.ts", "return CASKET_COPPER_BASE + CASKET_COPPER_PER_LEVEL * Math.max(1, Math.floor(level));"]},
        {"do": "emit", "kind": "copper", "fields": {"amount": {"op": "js_round", "args": [{"op": "if", "args": [
            {"var": "owner"}, {"op": "mul", "args": [{"var": "base"}, {"op": "add", "args": [1, {"data": "VAULT_OWNER_COPPER_BONUS"}]}]}, {"var": "base"}]}]}},
         "cite": ["src/sim/rift/hoard_reward_roll.ts", "const copper = Math.round(input.owner ? base * (1 + VAULT_OWNER_COPPER_BONUS) : base);"]},
    ],
}

# ---------------------------------------------------------------------------
# 5. Rift clear pools (addRiftClearGearLoot)

RIFT = {
    "id": "rift_clear_pools",
    "source_type": "rank-gated gear pushed onto the final boss's corpse on a winning Rift clear",
    "entry_point": {"file": "src/sim/rift/progression.ts", "cite": "export function addRiftClearGearLoot(", "function": "addRiftClearGearLoot"},
    "triggers": [{"rule": "every winning clear (ranked race or dev portal); the rank comes from the descriptor baseLevel",
                  "cite": ["src/sim/rift/progression.ts", "const rank = riftRankForBaseLevel(baseLevel);"]}],
    "eligibility": [{"rule": "rank by baseLevel: S >= 28, A >= 25, B >= 22, else C (RIFT_RANK_BASE_LEVEL)",
                     "cite": ["src/sim/rift/ranks.ts", "export const RIFT_RANK_BASE_LEVEL: Record<RiftTier, number> = { C: 20, B: 22, A: 25, S: 28 };"]},
                    {"rule": "quality draws only for newly added items, only when the boss is an eligible quality source and the item is quality-eligible",
                     "cite": ["src/sim/rift/progression.ts", "return [...items.slice(0, start), ...rollEnemyLootQuality(ctx.rng, boss, items.slice(start))];"]}],
    "ownership": {"rule": "plain corpse drops: the normal party loot rules decide who takes them",
                  "cite": ["src/sim/rift/progression.ts", "Rank-gated gear payout on the winning clear: pushed onto the final boss's"]},
    "duplicates": {"rule": "no duplicate guard: two heroic-epic picks can name the same item (inspected: not present)",
                   "cite": ["src/sim/rift/progression.ts", "const epic = (): string => heroicPool[ctx.rng.int(0, heroicPool.length - 1)];"]},
    "reset": "none in this function; the first-clear race is decided by the caller (claimRiftFirstClear)",
    "quantity": "count 1 per pick",
    "currency": "copper bonus by rank (C/B 10,000, A 35,000, S 50,000), added to the boss coin",
    "related_paths": [{"path": "src/sim/rift/progression.ts addRiftProgressionLoot",
                       "status": "OUT OF SCOPE: first-clear personal rewards (rift gear instance, Rift Essence, gems), a separate path from the clear pools; recorded, not modelled here"}],
    "data": {"NORMAL_POOL": ["src/sim/rift/loot_pools.ts", "riftNormalClearPool()"],
             "HEROIC_POOL": ["src/sim/rift/loot_pools.ts", "riftHeroicClearPool()"],
             "RANK_BASE_LEVEL": ["src/sim/rift/ranks.ts", "RIFT_RANK_BASE_LEVEL"],
             "EPIC_CHANCE_B": ["src/sim/rift/progression.ts", "RIFT_EPIC_CHANCE_B"],
             "SECOND_EPIC_CHANCE_S": ["src/sim/rift/progression.ts", "RIFT_SECOND_EPIC_CHANCE_S"],
             "LEGENDARY_IDS": ["src/sim/rift/progression.ts", "RIFT_LEGENDARY_ITEM_IDS"],
             "LEGENDARY_CHANCE_S": ["src/sim/rift/progression.ts", "RIFT_LEGENDARY_CHANCE_S"],
             "GREEN_REINS": ["src/sim/rift/progression.ts", "RIFT_GREEN_MOUNT_REINS"],
             "GREEN_CHANCE": ["src/sim/rift/progression.ts", "RIFT_GREEN_MOUNT_CHANCE"],
             "BLUE_REINS": ["src/sim/rift/progression.ts", "RIFT_BLUE_MOUNT_REINS"],
             "BLUE_CHANCE": ["src/sim/rift/progression.ts", "RIFT_BLUE_MOUNT_CHANCE"],
             "EPIC_REINS": ["src/sim/rift/progression.ts", "RIFT_EPIC_MOUNT_REINS"],
             "EPIC_MOUNT_CHANCE": ["src/sim/rift/progression.ts", "RIFT_EPIC_MOUNT_CHANCE"],
             "PATTERN_IDS": ["src/sim/rift/progression.ts", "RIFT_PATTERN_ITEM_IDS"],
             "PATTERN_CHANCE": ["src/sim/rift/progression.ts", "RIFT_PATTERN_CHANCE"],
             "FARM_IDS": ["src/sim/rift/progression.ts", "FARM_RIFT_DROP_ITEM_IDS"],
             "FARM_CHANCE": ["src/sim/rift/progression.ts", "FARM_RIFT_DROP_CHANCE"],
             "COIN_C": ["src/sim/rift/progression.ts", "RIFT_COIN_BONUS_C"],
             "COIN_B": ["src/sim/rift/progression.ts", "RIFT_COIN_BONUS_B"],
             "COIN_A": ["src/sim/rift/progression.ts", "RIFT_COIN_BONUS_A"],
             "COIN_S": ["src/sim/rift/progression.ts", "RIFT_COIN_BONUS_S"]},
    "dependencies": {"item": {"source": "ITEMS (src/sim/data.ts)", "resolved_by": "the reference item registry (quality eligibility)"}},
    "inputs": {"base_level": "Rift descriptor baseLevel", "quality_source": "isEligibleEnemyQualitySource(boss)"},
    "steps": [
        {"do": "let", "bind": "rank", "value": {"op": "if", "args": [
            {"op": "ge", "args": [{"var": "base_level"}, {"get": [{"data": "RANK_BASE_LEVEL"}, "S"]}]}, "S",
            {"op": "if", "args": [{"op": "ge", "args": [{"var": "base_level"}, {"get": [{"data": "RANK_BASE_LEVEL"}, "A"]}]}, "A",
                                  {"op": "if", "args": [{"op": "ge", "args": [{"var": "base_level"}, {"get": [{"data": "RANK_BASE_LEVEL"}, "B"]}]}, "B", "C"]}]}]}},
        {"do": "let", "bind": "new", "value": []},
        {"do": "if", "cond": {"op": "eq", "args": [{"var": "rank"}, "C"]}, "then": [
            {"do": "draw", "id": "c_normal_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"data": "NORMAL_POOL"}]}, 1]}], "bind": "k",
             "cite": ["src/sim/rift/progression.ts", "loot.items.push({ itemId: pool[ctx.rng.int(0, pool.length - 1)], count: 1 });"]},
            {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"get": [{"data": "NORMAL_POOL"}, {"var": "k"}]}, "count": 1}}},
            {"do": "emit", "kind": "copper", "fields": {"amount": {"data": "COIN_C"}}},
            {"do": "submodel", "model": "loot.enemy_quality", "args": {"source_eligible": {"var": "quality_source"}, "slots": {"var": "new"}}, "bind": "final"},
            {"do": "emit", "kind": "items", "fields": {"slots": {"var": "final"}, "owner": "corpse (party loot rules)"}},
            {"do": "return"}]},
        {"do": "if", "cond": {"op": "eq", "args": [{"var": "rank"}, "B"]},
         "then": [
             {"do": "draw", "id": "b_epic_roll", "method": "chance", "args": [{"data": "EPIC_CHANCE_B"}], "bind": "e"},
             {"do": "if", "cond": {"var": "e"}, "then": [
                 {"do": "draw", "id": "heroic_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"data": "HEROIC_POOL"}]}, 1]}], "bind": "k"},
                 {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"get": [{"data": "HEROIC_POOL"}, {"var": "k"}]}, "count": 1}}}]}],
         "else": [
             {"do": "draw", "id": "heroic_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"data": "HEROIC_POOL"}]}, 1]}], "bind": "k"},
             {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"get": [{"data": "HEROIC_POOL"}, {"var": "k"}]}, "count": 1}}},
             {"do": "if", "cond": {"op": "eq", "args": [{"var": "rank"}, "S"]}, "then": [
                 {"do": "draw", "id": "s_second_epic_roll", "method": "chance", "args": [{"data": "SECOND_EPIC_CHANCE_S"}], "bind": "e2"},
                 {"do": "if", "cond": {"var": "e2"}, "then": [
                     {"do": "draw", "id": "heroic_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"data": "HEROIC_POOL"}]}, 1]}], "bind": "k2"},
                     {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"get": [{"data": "HEROIC_POOL"}, {"var": "k2"}]}, "count": 1}}}]},
                 {"do": "for_each", "in": {"data": "LEGENDARY_IDS"}, "as": "lid", "body": [
                     {"do": "draw", "id": "s_legendary_roll", "method": "chance", "args": [{"data": "LEGENDARY_CHANCE_S"}], "bind": "l"},
                     {"do": "if", "cond": {"var": "l"}, "then": [
                         {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"var": "lid"}, "count": 1}}}]}],
                  "cite": ["src/sim/rift/progression.ts", "for (const legendaryId of RIFT_LEGENDARY_ITEM_IDS) {"]}]}],
         "cite": ["src/sim/rift/progression.ts", "if (ctx.rng.chance(RIFT_EPIC_CHANCE_B)) loot.items.push({ itemId: epic(), count: 1 });"]},
        {"do": "let", "bind": "reins", "value": {"op": "if", "args": [{"op": "eq", "args": [{"var": "rank"}, "B"]}, {"data": "GREEN_REINS"},
                                                                      {"op": "if", "args": [{"op": "eq", "args": [{"var": "rank"}, "A"]}, {"data": "BLUE_REINS"}, {"data": "EPIC_REINS"}]}]}},
        {"do": "let", "bind": "mount_chance", "value": {"op": "if", "args": [{"op": "eq", "args": [{"var": "rank"}, "B"]}, {"data": "GREEN_CHANCE"},
                                                                             {"op": "if", "args": [{"op": "eq", "args": [{"var": "rank"}, "A"]}, {"data": "BLUE_CHANCE"}, {"data": "EPIC_MOUNT_CHANCE"}]}]}},
        {"do": "draw", "id": "mount_roll", "method": "chance", "args": [{"var": "mount_chance"}], "bind": "mo",
         "cite": ["src/sim/rift/progression.ts", "if (ctx.rng.chance(mount.chance)) {"]},
        {"do": "if", "cond": {"var": "mo"}, "then": [
            {"do": "draw", "id": "mount_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"var": "reins"}]}, 1]}], "bind": "r"},
            {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"get": [{"var": "reins"}, {"var": "r"}]}, "count": 1}}}]},
        {"do": "draw", "id": "pattern_roll", "method": "chance", "args": [{"data": "PATTERN_CHANCE"}], "bind": "pa",
         "cite": ["src/sim/rift/progression.ts", "if (ctx.rng.chance(RIFT_PATTERN_CHANCE)) {"]},
        {"do": "if", "cond": {"var": "pa"}, "then": [
            {"do": "draw", "id": "pattern_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"data": "PATTERN_IDS"}]}, 1]}], "bind": "p"},
            {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"get": [{"data": "PATTERN_IDS"}, {"var": "p"}]}, "count": 1}}}]},
        {"do": "draw", "id": "farm_roll", "method": "chance", "args": [{"data": "FARM_CHANCE"}], "bind": "fa",
         "cite": ["src/sim/rift/progression.ts", "if (ctx.rng.chance(FARM_RIFT_DROP_CHANCE)) {"]},
        {"do": "if", "cond": {"var": "fa"}, "then": [
            {"do": "draw", "id": "farm_pick", "method": "int", "args": [0, {"op": "sub", "args": [{"op": "len", "args": [{"data": "FARM_IDS"}]}, 1]}], "bind": "f"},
            {"do": "push", "list": "new", "value": {"op": "dict", "fields": {"itemId": {"get": [{"data": "FARM_IDS"}, {"var": "f"}]}, "count": 1}}}]},
        {"do": "emit", "kind": "copper", "fields": {"amount": {"op": "if", "args": [{"op": "eq", "args": [{"var": "rank"}, "B"]}, {"data": "COIN_B"},
                                                                                 {"op": "if", "args": [{"op": "eq", "args": [{"var": "rank"}, "A"]}, {"data": "COIN_A"}, {"data": "COIN_S"}]}]}}},
        {"do": "submodel", "model": "loot.enemy_quality", "args": {"source_eligible": {"var": "quality_source"}, "slots": {"var": "new"}}, "bind": "final"},
        {"do": "emit", "kind": "items", "fields": {"slots": {"var": "final"}, "owner": "corpse (party loot rules)"}},
    ],
}

# ---------------------------------------------------------------------------
# 5b. Rift first clear (addRiftProgressionLoot)

RIFT_FIRST = {
    "id": "rift_first_clear",
    "source_type": "first-clear personal rewards on the final boss's corpse, for the party that wins a ranked Rift event",
    "entry_point": {"file": "src/sim/rift/progression.ts", "cite": "export function addRiftProgressionLoot(", "function": "addRiftProgressionLoot"},
    "triggers": [
        {"rule": "a winning clear whose first-clear claim names an event (the party won the race) and whose final boss exists",
         "cite": ["src/sim/rift/runs.ts", "addRiftProgressionLoot("]},
        {"rule": "a party that loses the race takes completeLosingRun instead: no first-clear loot (repeat and losing clears pay only the clear pools)",
         "cite": ["src/sim/rift/runs.ts", "completeLosingRun(ctx, inst);"]},
    ],
    "eligibility": [
        {"rule": "the claim's participants: the current members (a vault's admitted party, else the players present, else every member)",
         "cite": ["src/sim/rift/runs.ts", "const participants = inst.vault"]},
        {"rule": "a participant without a player record is skipped, but still advances the gem index",
         "cite": ["src/sim/rift/progression.ts", "if (!meta) continue;"]},
        {"rule": "a gem only on an A or S event, or when the run's crafting-material bias is at least 0.5",
         "cite": ["src/sim/rift/progression.ts", "if (tier === 'A' || tier === 'S' || craftingMaterialBias >= 0.5) {"]},
    ],
    "ownership": {"rule": "every item is personalFor its participant (personal corpse loot)", "cite": ["src/sim/rift/progression.ts", "personalFor: [pid],"]},
    "duplicates": {"rule": "no guard: each first clear mints a new band copy bound to its owner (inspected: not present)",
                   "cite": ["src/sim/rift/progression.ts", "const gear = createRiftGearInstance(eventId, tier, meta.cls, pid);"]},
    "reset": "one first clear per event (the race claim); the function itself keeps no state",
    "quantity": "one band per participant; Rift Essence = max(1, min(8, round(TIER_POWER[tier] x clamp(lootMultiplier, 0.5, 2)))), one stack of 1 each; one gem",
    "currency": "the corpse copper is multiplied by clamp(lootMultiplier, 0.5, 2) and rounded",
    "data": {"TIER_POWER": ["src/sim/rift/progression.ts", "TIER_POWER"],
             "RIFT_GEM_IDS": ["src/sim/rift/progression.ts", "RIFT_GEM_IDS"],
             "ESSENCE": ["src/sim/content/rift/items.ts", "RIFT_ESSENCE_ITEM_ID"]},
    "dependencies": {"shell_item": {"source": "src/sim/rift/progression.ts shellItemIdForClass (createRiftGearInstance)",
                                    "resolved_by": "source function (class -> band id; deterministic, no draws)"},
                     "item": {"source": "ITEMS (src/sim/data.ts)", "resolved_by": "the reference item registry (quality eligibility)"}},
    "inputs": {"tier": "event tier C/B/A/S", "participants": "[{pid, cls or null when the player record is missing}]",
               "loot_multiplier": "run upgrade lootMultiplier (default 1)", "crafting_material_bias": "run upgrade bias (default 0.25)",
               "boss_copper": "the corpse's copper before", "quality_source": "isEligibleEnemyQualitySource(boss)"},
    "steps": [
        {"do": "let", "bind": "mult", "value": {"op": "max", "args": [0.5, {"op": "min", "args": [2, {"var": "loot_multiplier"}]}]}},
        {"do": "emit", "kind": "copper", "fields": {"amount": {"op": "js_round", "args": [{"op": "mul", "args": [{"var": "boss_copper"}, {"var": "mult"}]}]}},
         "cite": ["src/sim/rift/progression.ts", "loot.copper = Math.round(loot.copper * Math.max(0.5, Math.min(2, lootMultiplier)));"]},
        {"do": "let", "bind": "essence", "value": {"op": "max", "args": [1, {"op": "min", "args": [8, {"op": "js_round", "args": [
            {"op": "mul", "args": [{"get": [{"data": "TIER_POWER"}, {"var": "tier"}]}, {"var": "mult"}]}]}]}]},
         "cite": ["src/sim/rift/progression.ts", "Math.min(8, Math.round(TIER_POWER[tier] * Math.max(0.5, Math.min(2, lootMultiplier)))),"]},
        {"do": "for_each", "in": {"var": "participants"}, "as": "p", "index": "i", "body": [
            {"do": "if", "cond": {"op": "eq", "args": [{"get": [{"var": "p"}, "cls"]}, None]}, "then": [{"do": "continue"}]},
            {"do": "let", "bind": "band", "value": {"call": "shell_item", "args": [{"get": [{"var": "p"}, "cls"]}]}},
            {"do": "let", "bind": "item", "value": {"call": "item", "args": [{"var": "band"}]}},
            {"do": "let", "bind": "q", "value": None},
            {"do": "if", "cond": {"op": "and", "args": [{"var": "quality_source"}, {"op": "ne", "args": [{"var": "item"}, None]}, ITEM_QUALITY_ELIGIBLE]}, "then": [
                {"do": "submodel", "model": "loot_quality.create", "args": {}, "bind": "q"}],
             "cite": ["src/sim/rift/progression.ts", "? createLootQuality(ctx.rng)"]},
            {"do": "emit", "kind": "item", "fields": {"owner": {"get": [{"var": "p"}, "pid"]}, "itemId": {"var": "band"}, "count": 1, "quality": {"var": "q"}}},
            {"do": "for_range", "count": {"var": "essence"}, "index": "e", "body": [
                {"do": "emit", "kind": "item", "fields": {"owner": {"get": [{"var": "p"}, "pid"]}, "itemId": {"data": "ESSENCE"}, "count": 1, "quality": None}}]},
            {"do": "if", "cond": {"op": "or", "args": [{"op": "in", "args": [{"var": "tier"}, ["A", "S"]]}, {"op": "ge", "args": [{"var": "crafting_material_bias"}, 0.5]}]}, "then": [
                {"do": "emit", "kind": "item", "fields": {"owner": {"get": [{"var": "p"}, "pid"]},
                                                          "itemId": {"get": [{"data": "RIFT_GEM_IDS"}, {"op": "mod", "args": [{"var": "i"}, {"op": "len", "args": [{"data": "RIFT_GEM_IDS"}]}]}]},
                                                          "count": 1, "quality": None}}],
             "cite": ["src/sim/rift/progression.ts", "itemId: RIFT_GEM_IDS[i % RIFT_GEM_IDS.length],"]}],
         "cite": ["src/sim/rift/progression.ts", "for (let i = 0; i < participants.length; i++) {"]},
    ],
}

# ---------------------------------------------------------------------------
# 6. Drowned Litany chest

LITANY = {
    "id": "drowned_litany_chest",
    "source_type": "per-party-member chest when the Drowned Reliquary opens (delve finale)",
    "entry_point": {"file": "src/sim/content/delves/drowned_litany_loot.ts", "cite": "export function drownedLitanyChestItemsForTier(", "function": "drownedLitanyChestItemsForTier"},
    "triggers": [
        {"rule": "the last correct shrine touch: tier = capTier(lootTierForMistakes(mistakes, allowed), riteCeiling(intensity))",
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "lootTierForMistakes(st.mistakes, st.mistakesAllowed),"]},
        {"rule": "out of tries (mistakes > allowed): the reliquary opens at tier 'low'",
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "openDrownedReliquary(ctx, run, 'low', pid);"]},
        {"rule": "opens once: a reliquary already opened does nothing",
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "if (!st || st.opened) return;"]},
    ],
    "eligibility": [
        {"rule": "every party member (partyMembersForKey), or the opener alone without a party; class falls back to warrior",
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "const members = run.partyKey ? ctx.partyMembersForKey(run.partyKey) : [openerId];"]},
        {"rule": "the bountiful (coffer) table applies when the run is bountiful and this reliquary is the reward chest",
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "const isCoffer = run.bountiful && st.reliquaryId === run.rewardChestId;"]},
    ],
    "ownership": {"rule": "personal: each member's own list (partyLoot[pid]), rolled in member order",
                  "cite": ["src/sim/delves/drowned_litany_rite.ts", "partyLoot[pid] = drownedLitanyChestItemsForTier(tier, cls, ctx.rng, isCoffer);"]},
    "duplicates": {"rule": "none (inspected: not present)", "cite": ["src/sim/content/delves/drowned_litany_loot.ts", "const result: { itemId: string; count: number }[] = [];"]},
    "reset": "once per rite (st.opened)",
    "quantity": "count 1 per item",
    "currency": "none in this function; the delve's own rewards are granted separately (grantDelveRewards, grantRiteBonus)",
    "data": {"LOOT_ARCHETYPE": ["src/sim/content/delves/drowned_litany_loot.ts", "LOOT_ARCHETYPE"],
             "UNCOMMON_A": ["src/sim/content/delves/drowned_litany_loot.ts", "UNCOMMON_A"],
             "UNCOMMON_B": ["src/sim/content/delves/drowned_litany_loot.ts", "UNCOMMON_B"],
             "RARE": ["src/sim/content/delves/drowned_litany_loot.ts", "RARE"],
             "EPIC": ["src/sim/content/delves/drowned_litany_loot.ts", "EPIC"]},
    "dependencies": {},
    "inputs": {"tier": "premium | medium | low", "members": "[{entityId, cls}] in party order", "bountiful": "coffer flag"},
    "steps": [
        {"do": "for_each", "in": {"var": "members"}, "as": "m", "body": [
            {"do": "let", "bind": "arch", "value": {"op": "default", "args": [{"get": [{"data": "LOOT_ARCHETYPE"}, {"op": "default", "args": [{"get": [{"var": "m"}, "cls"]}, "warrior"]}]}, "WAR"]}},
            {"do": "draw", "id": "uncommon_pick", "method": "chance", "args": [0.5], "bind": "a",
             "cite": ["src/sim/content/delves/drowned_litany_loot.ts", "const uncommonId = rng.chance(0.5) ? UNCOMMON_A[arch] : UNCOMMON_B[arch];"]},
            {"do": "let", "bind": "uncommon", "value": {"op": "if", "args": [{"var": "a"}, {"get": [{"data": "UNCOMMON_A"}, {"var": "arch"}]}, {"get": [{"data": "UNCOMMON_B"}, {"var": "arch"}]}]}},
            {"do": "let", "bind": "owner", "value": {"get": [{"var": "m"}, "entityId"]}},
            {"do": "if", "cond": {"var": "bountiful"}, "then": [
                {"do": "emit", "kind": "item", "fields": {"owner": {"var": "owner"}, "itemId": {"var": "uncommon"}, "count": 1}},
                {"do": "emit", "kind": "item", "fields": {"owner": {"var": "owner"}, "itemId": {"get": [{"data": "RARE"}, {"var": "arch"}]}, "count": 1}},
                {"do": "draw", "id": "epic_roll", "method": "chance", "args": [0.12], "bind": "e"},
                {"do": "if", "cond": {"var": "e"}, "then": [
                    {"do": "emit", "kind": "item", "fields": {"owner": {"var": "owner"}, "itemId": {"get": [{"data": "EPIC"}, {"var": "arch"}]}, "count": 1}}]},
                {"do": "continue"}],
             "cite": ["src/sim/content/delves/drowned_litany_loot.ts", "if (rng.chance(0.12)) result.push({ itemId: EPIC[arch], count: 1 }); // draw 2"]},
            {"do": "if", "cond": {"op": "eq", "args": [{"var": "tier"}, "premium"]}, "then": [
                {"do": "emit", "kind": "item", "fields": {"owner": {"var": "owner"}, "itemId": {"var": "uncommon"}, "count": 1}},
                {"do": "draw", "id": "rare_roll", "method": "chance", "args": [0.2], "bind": "r"},
                {"do": "if", "cond": {"var": "r"}, "then": [
                    {"do": "emit", "kind": "item", "fields": {"owner": {"var": "owner"}, "itemId": {"get": [{"data": "RARE"}, {"var": "arch"}]}, "count": 1}}]},
                {"do": "continue"}],
             "cite": ["src/sim/content/delves/drowned_litany_loot.ts", "if (rng.chance(0.2)) result.push({ itemId: RARE[arch], count: 1 }); // draw 2"]},
            {"do": "if", "cond": {"op": "eq", "args": [{"var": "tier"}, "medium"]}, "then": [
                {"do": "emit", "kind": "item", "fields": {"owner": {"var": "owner"}, "itemId": {"var": "uncommon"}, "count": 1}},
                {"do": "draw", "id": "placeholder", "method": "chance", "args": [0], "bind": "_"},
                {"do": "continue"}],
             "cite": ["src/sim/content/delves/drowned_litany_loot.ts", "rng.chance(0); // draw 2 placeholder"]},
            {"do": "draw", "id": "consolation_roll", "method": "chance", "args": [0.5], "bind": "c"},
            {"do": "if", "cond": {"var": "c"}, "then": [
                {"do": "emit", "kind": "item", "fields": {"owner": {"var": "owner"}, "itemId": {"var": "uncommon"}, "count": 1}}],
             "cite": ["src/sim/content/delves/drowned_litany_loot.ts", "if (rng.chance(0.5)) result.push({ itemId: uncommonId, count: 1 }); // draw 2"]}],
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "for (const pid of members) {"]},
    ],
}

# ---------------------------------------------------------------------------
# 7. Weekly vault (earning at reset, opening a choice, claiming it)

WEEKLY = {
    "id": "weekly_boss_tables",
    "source_type": "weekly vault: choices earned by thresholds, materialised at the weekly reset, each opened by one pick and claimed one per batch",
    "entry_point": {"file": "src/sim/weekly_reward_open.ts", "cite": "export function prepareWeeklyRewardOpen(", "function": "prepareWeeklyRewardOpen"},
    "triggers": [
        {"rule": "progress is recorded by boss kills in a claimed instance, world-quest completions and PvP wins",
         "cite": ["src/sim/weekly_rewards.ts", "export function recordWeeklyBossKill("]},
        {"rule": "at the weekly reset (state.resetAtMs <= now) the earned rolls become a vault batch of choices",
         "cite": ["src/sim/weekly_rewards.ts", "if (state.resetAtMs > nowMs) return;"]},
        {"rule": "a choice is opened at the vault keeper, then claimed (one claim per batch, oldest batch first)",
         "cite": ["src/sim/weekly_rewards.ts", "export function claimWeeklyReward("]},
    ],
    "eligibility": [
        {"rule": "earned rolls per pool: raid and dungeon clears against thresholds raid [1,2,3] and dungeon [1,4,8] (heroic clears to the heroic pool); world [2,4,8]; PvP [1,3,5]",
         "cite": ["src/sim/weekly_rewards.ts", "export function earnedWeeklyRolls(state: WeeklyRewardState): number[] {"]},
        {"rule": "a pool's slot is created only when it has candidate loot for the class (available(pool))",
         "cite": ["src/sim/weekly_rewards.ts", "if (available(pool)) choices.push({ pool });"]},
        {"rule": "opening needs the keeper in reach, the oldest batch past its reset, an unopened choice, and a valid table selection",
         "cite": ["src/sim/weekly_reward_open.ts", "if (!batch || batch.resetAtMs > ctx.lockoutNowMs()) return null;"]},
        {"rule": "options: unreserved, class- and spec-compatible items of the selected tables, within the equip level (required level <= level + 3)",
         "cite": ["src/sim/weekly_reward_options.ts", "requiredLevelFor(ITEMS[itemId]) <= level + WEEKLY_REWARD_MAX_LEVEL_OFFSET"]},
    ],
    "ownership": {"rule": "personal: each character's own vault state", "cite": ["src/sim/weekly_rewards.ts", "export function stateFor(ctx: SimContext, meta: PlayerMeta): WeeklyRewardState {"]},
    "duplicates": {"rule": "items already reserved by another choice of the batch are excluded; the selected tables' items are de-duplicated and sorted before the pick",
                   "cite": ["src/sim/weekly_reward_open.ts", "const items = [...new Set(selected.flatMap((table) => table.items))].sort();"]},
    "reset": "weekly: at resetAtMs the counters reset and a batch is stored (backlog up to 520 batches); the next reset comes from the realm's weekly raid reset",
    "quantity": "one item per opened choice; quality draws per copy at claim (grantFreshLoot)",
    "currency": "none in the vault itself (inspected: not present)",
    "data": {"POOL_IDS": ["src/sim/weekly_rewards.ts", "WEEKLY_POOL_IDS"],
             "THRESHOLDS": ["src/sim/weekly_rewards.ts", "WEEKLY_THRESHOLDS"],
             "BACKLOG_LIMIT": ["src/sim/weekly_rewards.ts", "WEEKLY_BACKLOG_LIMIT"],
             "WEEKLY_BOSS_TABLES": ["src/sim/weekly_reward_tables.ts", "WEEKLY_BOSS_TABLES"]},
    "dependencies": {"options": {"source": "src/sim/weekly_reward_options.ts weeklyRewardTableOptions + selectedWeeklyRewardTables",
                                 "resolved_by": "source function (class, spec, level and reservation filters over the boss tables; no draws)"},
                     "item": {"source": "ITEMS (src/sim/data.ts)", "resolved_by": "the reference item registry (quality eligibility at claim)"}},
    "inputs": {"phase": "earn | open | claim", "state": "earning counters (earn)", "available": "{pool: bool} (earn)",
               "selected_items": "the selected options' item lists (open)", "item_id": "the opened choice's item (claim)"},
    "steps": [
        {"do": "if", "cond": {"op": "eq", "args": [{"var": "phase"}, "earn"]}, "then": [
            {"do": "let", "bind": "tiers", "value": [{"get": [{"var": "state"}, "raidClears"]}, {"get": [{"var": "state"}, "dungeons"]}]},
            {"do": "let", "bind": "earned", "value": [0, 0, 0, 0, 0, 0]},
            {"do": "for_each", "in": [["raid", 0], ["dungeon", 1]], "as": "kind", "body": [
                {"do": "for_each", "in": {"get": [{"data": "THRESHOLDS"}, {"get": [{"var": "kind"}, 0]}]}, "as": "required", "body": [
                    {"do": "let", "bind": "tier", "value": {"get": [{"get": [{"var": "tiers"}, {"get": [{"var": "kind"}, 1]}]}, {"op": "sub", "args": [{"var": "required"}, 1]}]}},
                    {"do": "if", "cond": {"op": "truthy", "args": [{"var": "tier"}]}, "then": [
                        {"do": "increment", "list": "earned", "index": {"op": "add", "args": [{"op": "mul", "args": [{"get": [{"var": "kind"}, 1]}, 2]},
                                                                                              {"op": "if", "args": [{"op": "eq", "args": [{"var": "tier"}, 2]}, 1, 0]}]}}]}]}],
             "cite": ["src/sim/weekly_rewards.ts", "if (tier) earned[index * 2 + (tier === 2 ? 1 : 0)]++;"]},
            {"do": "set_at", "list": "earned", "index": 4, "value": {"op": "count_le", "args": [{"get": [{"data": "THRESHOLDS"}, "world"]}, {"get": [{"var": "state"}, "world"]}]},
             "cite": ["src/sim/weekly_rewards.ts", "earned[4] = WEEKLY_THRESHOLDS.world.filter((n) => state.world >= n).length;"]},
            {"do": "set_at", "list": "earned", "index": 5, "value": {"op": "count_le", "args": [{"get": [{"data": "THRESHOLDS"}, "pvp"]}, {"get": [{"var": "state"}, "pvp"]}]}},
            {"do": "for_each", "in": {"var": "earned"}, "as": "count", "index": "i", "body": [
                {"do": "for_range", "count": {"var": "count"}, "index": "slot", "body": [
                    {"do": "if", "cond": {"get": [{"var": "available"}, {"get": [{"data": "POOL_IDS"}, {"var": "i"}]}]}, "then": [
                        {"do": "emit", "kind": "choice", "fields": {"pool": {"get": [{"data": "POOL_IDS"}, {"var": "i"}]}}}]}]}],
             "cite": ["src/sim/weekly_rewards.ts", "for (let slot = 0; slot < count; slot++) {"]},
            {"do": "return"}]},
        {"do": "if", "cond": {"op": "eq", "args": [{"var": "phase"}, "open"]}, "then": [
            {"do": "let", "bind": "items", "value": {"op": "sorted_unique", "args": [{"op": "flatten", "args": [{"var": "selected_items"}]}]}},
            {"do": "if", "cond": {"op": "eq", "args": [{"op": "len", "args": [{"var": "items"}]}, 0]}, "then": [{"do": "return"}],
             "cite": ["src/sim/weekly_reward_open.ts", "if (!items.length) return null;"]},
            {"do": "draw", "id": "weekly_pick", "method": "pick", "args": [{"var": "items"}], "bind": "chosen",
             "cite": ["src/sim/weekly_reward_open.ts", "choice.itemId = ctx.rng.pick(items);"]},
            {"do": "emit", "kind": "choice_item", "fields": {"itemId": {"var": "chosen"}}},
            {"do": "return"}]},
        {"do": "submodel", "model": "loot.fresh_quality", "args": {"item_id": {"var": "item_id"}, "count": 1}, "bind": "qs",
         "cite": ["src/sim/weekly_rewards.ts", "grantFreshLoot(ctx, choice.itemId, 1, r.e.id);"]},
        {"do": "emit", "kind": "item", "fields": {"itemId": {"var": "item_id"}, "count": 1, "qualities": {"var": "qs"}}},
    ],
}

# The rite's loot tier (delves/drowned_litany_rite.ts): mistakes against the
# allowed count, capped by the intensity's ceiling.
LITANY_TIER = {
    "id": "drowned_litany.tier",
    "entry_point": {"file": "src/sim/delves/drowned_litany_rite.ts", "cite": "function lootTierForMistakes(mistakes: number, mistakesAllowed: number): LootTier {", "function": "lootTierForMistakes, capTier, riteCeiling"},
    "data": {"RITE_INTENSITY": ["src/sim/delves/rite_tuning.ts", "RITE_INTENSITY"]},
    "inputs": {"mistakes": "wrong touches", "allowed": "tries - 1", "intensity": "rite intensity or null"},
    "steps": [
        {"do": "let", "bind": "raw", "value": {"op": "if", "args": [{"op": "eq", "args": [{"var": "mistakes"}, 0]}, "premium",
                                                                    {"op": "if", "args": [{"op": "le", "args": [{"var": "mistakes"}, {"var": "allowed"}]}, "medium", "low"]}]},
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "if (mistakes <= mistakesAllowed) return 'medium';"]},
        {"do": "let", "bind": "ceiling", "value": {"get": [{"get": [{"data": "RITE_INTENSITY"}, {"op": "default", "args": [{"var": "intensity"}, "medium"]}]}, "ceiling"]},
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "return RITE_INTENSITY[intensity ?? 'medium'].ceiling;"]},
        {"do": "let", "bind": "order", "value": {"op": "dict", "fields": {"low": 0, "medium": 1, "premium": 2}}},
        {"do": "set_result", "value": {"op": "if", "args": [
            {"op": "le", "args": [{"get": [{"var": "order"}, {"var": "raw"}]}, {"get": [{"var": "order"}, {"var": "ceiling"}]}]},
            {"var": "raw"}, {"var": "ceiling"}]},
         "cite": ["src/sim/delves/drowned_litany_rite.ts", "return TIER_ORDER[tier] <= TIER_ORDER[ceiling] ? tier : ceiling;"]},
    ],
}

# world_quest_rotation.ts: civilDayNumber, normalizeWorldQuestCycle, worldQuestCycleNumber.
WQ_CYCLE = {
    "id": "world_quest.cycle_number",
    "entry_point": {"file": "src/sim/world_quest_rotation.ts", "cite": "export function worldQuestCycleNumber(cycle: unknown): number | null {", "function": "worldQuestCycleNumber"},
    "data": {"ROTATION_DAYS": ["src/sim/world_quest_rotation.ts", "WORLD_QUEST_ROTATION_DAYS"],
             "PREFIX": ["src/sim/world_quest_rotation.ts", "WORLD_QUEST_CYCLE_PREFIX"],
             "DAYS_IN_MONTH": ["src/sim/world_quest_rotation.ts", "DAYS_IN_MONTH"],
             "EPOCH_DAY": ["src/sim/world_quest_rotation.ts", "WORLD_QUEST_ROTATION_EPOCH_DAY"]},
    "inputs": {"cycle": "a cycle id, an ISO reset day, or anything else"},
    "steps": [
        {"do": "set_result", "value": None},
        {"do": "if", "cond": {"op": "not", "args": [{"op": "is_string", "args": [{"var": "cycle"}]}]}, "then": [{"do": "return"}],
         "cite": ["src/sim/world_quest_rotation.ts", "if (typeof cycle !== 'string') return '';"]},
        {"do": "if", "cond": {"op": "gt", "args": [{"op": "str_len", "args": [{"var": "cycle"}]}, 32]}, "then": [{"do": "return"}],
         "cite": ["src/sim/world_quest_rotation.ts", "if (cycle.length > 32) return '';"]},
        # An ISO reset day: civilDayNumber, then whole rotation periods since the epoch.
        {"do": "let", "bind": "m", "value": {"op": "regex", "args": [r"(\d{4})-(\d{2})-(\d{2})", {"var": "cycle"}]},
         "cite": ["src/sim/world_quest_rotation.ts", r"const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);"]},
        {"do": "if", "cond": {"op": "ne", "args": [{"var": "m"}, None]}, "then": [
            {"do": "let", "bind": "year", "value": {"op": "number", "args": [{"get": [{"var": "m"}, 1]}]}},
            {"do": "let", "bind": "month", "value": {"op": "number", "args": [{"get": [{"var": "m"}, 2]}]}},
            {"do": "let", "bind": "day", "value": {"op": "number", "args": [{"get": [{"var": "m"}, 3]}]}},
            {"do": "let", "bind": "leap", "value": {"op": "and", "args": [
                {"op": "eq", "args": [{"op": "mod", "args": [{"var": "year"}, 4]}, 0]},
                {"op": "or", "args": [{"op": "ne", "args": [{"op": "mod", "args": [{"var": "year"}, 100]}, 0]},
                                      {"op": "eq", "args": [{"op": "mod", "args": [{"var": "year"}, 400]}, 0]}]}]}},
            {"do": "let", "bind": "valid", "value": {"op": "and", "args": [
                {"op": "ge", "args": [{"var": "month"}, 1]}, {"op": "le", "args": [{"var": "month"}, 12]}, {"op": "ge", "args": [{"var": "day"}, 1]},
                {"op": "le", "args": [{"var": "day"}, {"op": "if", "args": [
                    {"op": "and", "args": [{"op": "eq", "args": [{"var": "month"}, 2]}, {"var": "leap"}]}, 29,
                    {"get": [{"data": "DAYS_IN_MONTH"}, {"op": "sub", "args": [{"var": "month"}, 1]}]}]}]}]},
             "cite": ["src/sim/world_quest_rotation.ts", "if (day > maxDay) return null;"]},
            {"do": "if", "cond": {"var": "valid"}, "then": [
                {"do": "let", "bind": "ay", "value": {"op": "sub", "args": [{"var": "year"}, {"op": "if", "args": [{"op": "le", "args": [{"var": "month"}, 2]}, 1, 0]}]}},
                {"do": "let", "bind": "era", "value": {"op": "floor", "args": [{"op": "div", "args": [{"var": "ay"}, 400]}]}},
                {"do": "let", "bind": "yoe", "value": {"op": "sub", "args": [{"var": "ay"}, {"op": "mul", "args": [{"var": "era"}, 400]}]}},
                {"do": "let", "bind": "sm", "value": {"op": "add", "args": [{"var": "month"}, {"op": "if", "args": [{"op": "gt", "args": [{"var": "month"}, 2]}, -3, 9]}]}},
                {"do": "let", "bind": "doy", "value": {"op": "sub", "args": [{"op": "add", "args": [
                    {"op": "floor", "args": [{"op": "div", "args": [{"op": "add", "args": [{"op": "mul", "args": [153, {"var": "sm"}]}, 2]}, 5]}]}, {"var": "day"}]}, 1]}},
                {"do": "let", "bind": "doe", "value": {"op": "add", "args": [{"op": "sub", "args": [
                    {"op": "add", "args": [{"op": "mul", "args": [{"var": "yoe"}, 365]}, {"op": "floor", "args": [{"op": "div", "args": [{"var": "yoe"}, 4]}]}]},
                    {"op": "floor", "args": [{"op": "div", "args": [{"var": "yoe"}, 100]}]}]}, {"var": "doy"}]}},
                {"do": "let", "bind": "civil", "value": {"op": "add", "args": [{"op": "mul", "args": [{"var": "era"}, 146097]}, {"var": "doe"}]},
                 "cite": ["src/sim/world_quest_rotation.ts", "return era * 146_097 + dayOfEra;"]},
                {"do": "set_result", "value": {"op": "floor", "args": [{"op": "div", "args": [
                    {"op": "sub", "args": [{"var": "civil"}, {"data": "EPOCH_DAY"}]}, {"data": "ROTATION_DAYS"}]}]},
                 "cite": ["src/sim/world_quest_rotation.ts", "const cycle = Math.floor((day - WORLD_QUEST_ROTATION_EPOCH_DAY) / WORLD_QUEST_ROTATION_DAYS);"]},
                {"do": "return"}]}]},
        {"do": "if", "cond": {"op": "starts_with", "args": [{"var": "cycle"}, {"data": "PREFIX"}]}, "then": [
            {"do": "let", "bind": "enc", "value": {"op": "slice_from", "args": [{"var": "cycle"}, {"op": "str_len", "args": [{"data": "PREFIX"}]}]}},
            {"do": "if", "cond": {"op": "eq", "args": [{"op": "regex", "args": [r"-?\d+", {"var": "enc"}]}, None]}, "then": [{"do": "return"}]},
            {"do": "let", "bind": "v", "value": {"op": "number", "args": [{"var": "enc"}]}},
            {"do": "if", "cond": {"op": "is_safe_int", "args": [{"var": "v"}]}, "then": [{"do": "set_result", "value": {"var": "v"}}]},
            {"do": "return"}],
         "cite": ["src/sim/world_quest_rotation.ts", "if (cycle.startsWith(WORLD_QUEST_CYCLE_PREFIX)) {"]},
        {"do": "if", "cond": {"op": "starts_with", "args": [{"var": "cycle"}, "wq3_"]}, "then": [
            {"do": "let", "bind": "enc", "value": {"op": "slice_from", "args": [{"var": "cycle"}, 4]}},
            {"do": "if", "cond": {"op": "eq", "args": [{"op": "regex", "args": [r"-?\d+", {"var": "enc"}]}, None]}, "then": [{"do": "return"}]},
            {"do": "let", "bind": "v", "value": {"op": "number", "args": [{"var": "enc"}]}},
            {"do": "if", "cond": {"op": "is_safe_int", "args": [{"var": "v"}]}, "then": [{"do": "set_result", "value": {"op": "mul", "args": [{"var": "v"}, 3]}}]}],
         "cite": ["src/sim/world_quest_rotation.ts", "return Number.isSafeInteger(value) ? `${WORLD_QUEST_CYCLE_PREFIX}${value * 3}` : '';"]},
    ],
}

# activeWorldQuestsForCycle: one rotating quest per zone, then the always-active dailies.
WQ_ROTATION = {
    "id": "world_quest.active_quests",
    "entry_point": {"file": "src/sim/world_quest_rotation.ts", "cite": "export function activeWorldQuestsForCycle(cycle: unknown): readonly WorldQuestDef[] {", "function": "activeWorldQuestsForCycle"},
    "data": {"ZONES": ["src/sim/world_quest_rotation.ts", "WORLD_QUEST_ZONES"],
             "BY_ZONE": ["src/sim/world_quest_rotation.ts", "WORLD_QUESTS_BY_ZONE"],
             "ALWAYS": ["src/sim/world_quest_rotation.ts", "ALWAYS_ACTIVE_WORLD_QUEST_IDS"],
             "QUEST_IDS": ["src/sim/world_quest_rotation.ts", "WORLD_QUESTS_BY_ID"]},
    "inputs": {"cycle": "cycle id"},
    "steps": [
        {"do": "submodel", "model": "world_quest.cycle_number", "args": {"cycle": {"var": "cycle"}}, "bind": "n"},
        {"do": "set_result", "value": []},
        {"do": "if", "cond": {"op": "eq", "args": [{"var": "n"}, None]}, "then": [{"do": "return"}]},
        {"do": "let", "bind": "out", "value": []},
        {"do": "for_each", "in": {"data": "ZONES"}, "as": "zone", "body": [
            {"do": "let", "bind": "ids", "value": {"op": "filter", "list": {"op": "default", "args": [{"get": [{"data": "BY_ZONE"}, {"var": "zone"}]}, []]},
                                                   "as": "id", "where": {"op": "not", "args": [{"op": "in", "args": [{"var": "id"}, {"data": "ALWAYS"}]}]}}},
            {"do": "if", "cond": {"op": "eq", "args": [{"op": "len", "args": [{"var": "ids"}]}, 0]}, "then": [{"do": "continue"}]},
            {"do": "let", "bind": "k", "value": {"op": "mod", "args": [{"op": "add", "args": [{"op": "mod", "args": [{"var": "n"}, {"op": "len", "args": [{"var": "ids"}]}]},
                                                                                              {"op": "len", "args": [{"var": "ids"}]}]}, {"op": "len", "args": [{"var": "ids"}]}]},
             "cite": ["src/sim/world_quest_rotation.ts", "const index = ((number % ids.length) + ids.length) % ids.length;"]},
            {"do": "push", "list": "out", "value": {"get": [{"var": "ids"}, {"var": "k"}]}}]},
        {"do": "for_each", "in": {"data": "ALWAYS"}, "as": "id", "body": [{"do": "push", "list": "out", "value": {"var": "id"}}]},
        {"do": "set_result", "value": {"var": "out"}},
    ],
}

# weekly_reward_tables.ts weeklyBossLootPool: one boss's weekly pool.
WEEKLY_BOSS_POOL = {
    "id": "weekly.boss_pool",
    "entry_point": {"file": "src/sim/weekly_reward_tables.ts", "cite": "export function weeklyBossLootPool(", "function": "weeklyBossLootPool"},
    "data": {"WEEKLY_BOSS_TABLES": ["src/sim/weekly_reward_tables.ts", "WEEKLY_BOSS_TABLES"],
             "NYTHRAXIS_RAID_BOSS_ID": ["src/sim/content/heroic_loot.ts", "NYTHRAXIS_RAID_BOSS_ID"]},
    "dependencies": {
        "mob_loot": {"source": "MOBS[boss].loot", "resolved_by": "the reference loot registry (entries in roll order)"},
        "heroic_append": {"source": "HEROIC_BOSS_LOOT[boss]", "resolved_by": "the reference loot registry"},
        "heroic_item": {"source": "src/sim/loot/heroic_item.ts heroicLootItemId", "resolved_by": "source function (heroic variant when its item level is higher)"},
        "relocated_shelf": {"source": "src/sim/weekly_reward_tables.ts addRelocatedRaidShelf", "resolved_by": "source function"},
        "is_relocated": {"source": "src/sim/weekly_reward_tables.ts isRelocatedRaidPiece", "resolved_by": "source function"},
        "eligible": {"source": "weeklyRewardItemAllowed && weeklyRewardFitsClass && weeklyLootSpecFitsItem (weekly_reward_eligibility.ts, weekly_loot_spec.ts)",
                     "resolved_by": "source functions (item kind and quality, equip rules, class and spec fit)"},
    },
    "inputs": {"boss_id": "", "pool": "", "cls": "", "spec": "loot spec or null"},
    "steps": [
        {"do": "set_result", "value": []},
        {"do": "let", "bind": "table", "value": {"op": "default", "args": [
            {"get": [{"op": "filter", "list": {"data": "WEEKLY_BOSS_TABLES"}, "as": "t", "where": {"op": "eq", "args": [{"get": [{"var": "t"}, "bossId"]}, {"var": "boss_id"}]}}, 0]}, None]}},
        {"do": "if", "cond": {"op": "or", "args": [{"op": "eq", "args": [{"var": "table"}, None]},
                                                    {"op": "not", "args": [{"op": "in", "args": [{"var": "pool"}, ["raid", "raid_heroic", "dungeon", "dungeon_heroic"]]}]},
                                                    {"op": "not", "args": [{"op": "starts_with", "args": [{"var": "pool"}, {"get": [{"var": "table"}, "category"]}]}]}]},
         "then": [{"do": "return"}],
         "cite": ["src/sim/weekly_reward_tables.ts", "if (!table || !needsWeeklyBossTable(pool) || !pool.startsWith(table.category)) return [];"]},
        {"do": "let", "bind": "heroic", "value": {"op": "ends_with", "args": [{"var": "pool"}, "_heroic"]}},
        {"do": "let", "bind": "ids", "value": []},
        {"do": "for_each", "in": {"call": "mob_loot", "args": [{"var": "boss_id"}]}, "as": "e", "body": [
            {"do": "if", "cond": {"op": "and", "args": [
                {"op": "truthy", "args": [{"get": [{"var": "e"}, "itemId"]}]},
                {"op": "not", "args": [{"op": "truthy", "args": [{"get": [{"var": "e"}, "questId"]}]}]},
                {"op": "gt", "args": [{"get": [{"var": "e"}, "chance"]}, 0]},
                {"op": "not", "args": [{"op": "and", "args": [{"var": "heroic"}, {"op": "truthy", "args": [{"get": [{"var": "e"}, "normalOnly"]}]}]}]}]},
             "then": [{"do": "add_unique", "list": "ids", "value": {"call": "heroic_item", "args": [{"get": [{"var": "e"}, "itemId"]}, {"var": "heroic"}]}}]}],
         "cite": ["src/sim/weekly_reward_tables.ts", "if (entry.itemId && !entry.questId && entry.chance > 0 && !(heroic && entry.normalOnly))"]},
        {"do": "if", "cond": {"var": "heroic"}, "then": [
            {"do": "for_each", "in": {"call": "heroic_append", "args": [{"var": "boss_id"}]}, "as": "e", "body": [
                {"do": "if", "cond": {"op": "and", "args": [
                    {"op": "truthy", "args": [{"get": [{"var": "e"}, "itemId"]}]},
                    {"op": "not", "args": [{"op": "truthy", "args": [{"get": [{"var": "e"}, "questId"]}]}]},
                    {"op": "gt", "args": [{"get": [{"var": "e"}, "chance"]}, 0]}]},
                 "then": [{"do": "add_unique", "list": "ids", "value": {"get": [{"var": "e"}, "itemId"]}}]}]}],
         "cite": ["src/sim/weekly_reward_tables.ts", "for (const entry of HEROIC_BOSS_LOOT[bossId] ?? [])"]},
        {"do": "if", "cond": {"op": "eq", "args": [{"var": "boss_id"}, {"data": "NYTHRAXIS_RAID_BOSS_ID"}]},
         "then": [{"do": "for_each", "in": {"call": "relocated_shelf", "args": [{"var": "heroic"}]}, "as": "rid", "body": [
             {"do": "add_unique", "list": "ids", "value": {"var": "rid"}}]}],
         "else": [{"do": "if", "cond": {"op": "eq", "args": [{"get": [{"var": "table"}, "category"]}, "dungeon"]}, "then": [
             {"do": "for_each", "in": {"op": "copy", "args": [{"var": "ids"}]}, "as": "rid", "body": [
                 {"do": "if", "cond": {"call": "is_relocated", "args": [{"var": "rid"}]}, "then": [{"do": "remove_value", "list": "ids", "value": {"var": "rid"}}]}]}]}],
         "cite": ["src/sim/weekly_reward_tables.ts", "if (bossId === NYTHRAXIS_RAID_BOSS_ID) addRelocatedRaidShelf(ids, heroic);"]},
        {"do": "set_result", "value": {"op": "sorted_unique", "args": [{"op": "filter", "list": {"var": "ids"}, "as": "id",
                                                                       "where": {"call": "eligible", "args": [{"var": "id"}, {"var": "pool"}, {"var": "cls"}, {"var": "spec"}]}}]}},
    ],
}

# weekly_reward_options.ts weeklyRewardTableOptions: the selectable tables of one choice.
WEEKLY_OPTIONS = {
    "id": "weekly.options",
    "entry_point": {"file": "src/sim/weekly_reward_options.ts", "cite": "export function weeklyRewardTableOptions(", "function": "weeklyRewardTableOptions"},
    "data": {"WEEKLY_BOSS_TABLES": ["src/sim/weekly_reward_tables.ts", "WEEKLY_BOSS_TABLES"]},
    "dependencies": {
        "pool_items": {"source": "src/sim/weekly_rewards.ts weeklyLootPool (world and PvP rows)", "resolved_by": "source function"},
        "within_level": {"source": "src/sim/weekly_reward_options.ts weeklyItemWithinLevel (required level <= level + 3)", "resolved_by": "source function"},
    },
    "inputs": {"batch": "{choices, bossUnlocks, raidUnlocks}", "pool": "the choice's pool", "cls": "", "level": "", "spec": "loot spec or null"},
    "steps": [
        {"do": "let", "bind": "reserved", "value": {"op": "map_field", "args": [{"get": [{"var": "batch"}, "choices"]}, "itemId"]},
         "cite": ["src/sim/weekly_reward_options.ts", "const reserved = new Set(batch.choices.map((entry) => entry.itemId));"]},
        {"do": "let", "bind": "groups", "value": []},
        {"do": "if", "cond": {"op": "not", "args": [{"op": "in", "args": [{"var": "pool"}, ["raid", "raid_heroic", "dungeon", "dungeon_heroic"]]}]}, "then": [
            {"do": "let", "bind": "items", "value": {"op": "not_in_list", "args": [
                {"call": "pool_items", "args": [{"var": "pool"}, {"var": "cls"}, {"get": [{"var": "batch"}, "raidUnlocks"]}, {"var": "spec"}]}, {"var": "reserved"}]}},
            {"do": "if", "cond": {"op": "gt", "args": [{"op": "len", "args": [{"var": "items"}]}, 0]}, "then": [
                {"do": "push", "list": "groups", "value": {"op": "dict", "fields": {"id": {"var": "pool"}, "kind": "pool", "items": {"var": "items"}}}}]}],
         "else": [
            {"do": "let", "bind": "tier", "value": {"op": "if", "args": [{"op": "ends_with", "args": [{"var": "pool"}, "_heroic"]}, 2, 1]}},
            {"do": "let", "bind": "order", "value": []},
            {"do": "let", "bind": "by_id", "value": {"op": "dict", "fields": {}}},
            {"do": "for_each", "in": {"data": "WEEKLY_BOSS_TABLES"}, "as": "t", "body": [
                {"do": "if", "cond": {"op": "lt", "args": [{"op": "default", "args": [{"get": [{"op": "default", "args": [{"get": [{"var": "batch"}, "bossUnlocks"]}, {"op": "dict", "fields": {}}]}, {"get": [{"var": "t"}, "bossId"]}]}, 0]}, {"var": "tier"}]},
                 "then": [{"do": "continue"}],
                 "cite": ["src/sim/weekly_reward_tables.ts", "(table) => (batch.bossUnlocks?.[table.bossId] ?? 0) >= tier,"]},
                {"do": "submodel", "model": "weekly.boss_pool", "args": {"boss_id": {"get": [{"var": "t"}, "bossId"]}, "pool": {"var": "pool"}, "cls": {"var": "cls"}, "spec": {"var": "spec"}}, "bind": "bp"},
                {"do": "let", "bind": "items", "value": {"op": "not_in_list", "args": [{"var": "bp"}, {"var": "reserved"}]}},
                {"do": "if", "cond": {"op": "eq", "args": [{"op": "len", "args": [{"var": "items"}]}, 0]}, "then": [{"do": "continue"}]},
                {"do": "let", "bind": "gid", "value": {"op": "if", "args": [{"op": "eq", "args": [{"get": [{"var": "t"}, "category"]}, "dungeon"]},
                                                                              {"get": [{"var": "t"}, "dungeonId"]}, {"get": [{"var": "t"}, "bossId"]}]}},
                {"do": "if", "cond": {"op": "not", "args": [{"op": "in", "args": [{"var": "gid"}, {"var": "order"}]}]}, "then": [
                    {"do": "push", "list": "order", "value": {"var": "gid"}},
                    {"do": "push", "list": "groups", "value": {"op": "dict", "fields": {"id": {"var": "gid"},
                        "kind": {"op": "if", "args": [{"op": "eq", "args": [{"get": [{"var": "t"}, "category"]}, "dungeon"]}, "dungeon", "mob"]}, "items": []}}}]},
                {"do": "extend_group", "list": "groups", "index": {"op": "index_of", "args": [{"var": "order"}, {"var": "gid"}]}, "value": {"var": "items"}}],
             "cite": ["src/sim/weekly_reward_options.ts", "group.items.push(...items);"]},
            {"do": "for_each", "in": {"op": "copy", "args": [{"var": "groups"}]}, "as": "g", "index": "gi", "body": [
                {"do": "set_group_items", "list": "groups", "index": {"var": "gi"}, "value": {"op": "sorted_unique", "args": [{"get": [{"var": "g"}, "items"]}]}}],
             "cite": ["src/sim/weekly_reward_options.ts", "items: [...new Set(group.items)].sort(),"]}]},
        {"do": "set_result", "value": {"op": "level_filter", "args": [{"var": "groups"}, {"var": "level"}]},
         "cite": ["src/sim/weekly_reward_options.ts", "const items = table.items.filter((id) => weeklyItemWithinLevel(id, level));"]},
    ],
}

SUBMODELS = {m["id"]: m for m in (QUALITY, FRESH_QUALITY, ENEMY_QUALITY, LITANY_TIER, WQ_CYCLE, WQ_ROTATION,
                                  WEEKLY_BOSS_POOL, WEEKLY_OPTIONS)}
MODELS = {m["id"]: m for m in (BUDDY, WORLD_QUEST, HOARD, VAULT, RIFT, RIFT_FIRST, LITANY, WEEKLY)}

# ---------------------------------------------------------------------------
# Runner


class ScriptedRng:
    """rng.ts semantics over a scripted sequence of next() values."""

    def __init__(self, values, log: list, name: str = "rng") -> None:
        self.values = iter(values)
        self.log = log
        self.name = name

    def next(self) -> float:
        try:
            return float(next(self.values))
        except StopIteration:
            raise RuntimeError("scripted draws exhausted") from None

    def call(self, method: str, args: list):
        if method == "next":
            out = self.next()
        elif method == "int":
            lo, hi = float(args[0]), float(args[1])
            out = float(math.floor(lo + self.next() * (hi + 1 - lo)))
        elif method == "chance":
            out = self.next() < float(args[0])
        elif method == "pick":
            arr = args[0]
            out = arr[int(math.floor(self.next() * len(arr)))]
        else:
            raise ValueError(method)
        self.log.append([self.name, method, _plain(args if method != "pick" else [len(args[0])]), _plain(out)])
        return out


class DecisionRng(ScriptedRng):
    """The reference tests' scriptedRng: int() and chance() results scripted
    directly (tests/hoard_reward_roll.test.ts), every call logged."""

    def __init__(self, ints, chances, log: list, name: str = "rng") -> None:
        self.ints = list(ints)
        self.chances = list(chances)
        self.log = log
        self.name = name

    def call(self, method: str, args: list):
        if method == "int":
            v = float(self.ints.pop(0))
            if not (float(args[0]) <= v <= float(args[1])):
                raise RuntimeError("unscripted int")
        elif method == "chance":
            v = bool(self.chances.pop(0))
        else:
            raise RuntimeError(f"unscripted {method}")
        self.log.append([self.name, method, _plain(args), _plain(v)])
        return v


class SeededRng(ScriptedRng):
    """rng.ts `new Rng(seed)`: mulberry32."""

    def __init__(self, seed: int, log: list, name: str) -> None:
        self.s = int(seed) & 0xFFFFFFFF or 0x9E3779B9
        self.log = log
        self.name = name

    def next(self) -> float:
        self.s = (self.s + 0x6D2B79F5) & 0xFFFFFFFF
        t = self.s
        t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF
        t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF
        return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296


def _plain(v):
    if isinstance(v, float) and v.is_integer():
        return int(v)
    if isinstance(v, list):
        return [_plain(x) for x in v]
    if isinstance(v, dict):
        return {k: _plain(x) for k, x in v.items()}
    return v


class _Return(Exception):
    pass


class _Continue(Exception):
    pass


def _js_round(x: float) -> float:
    return float(math.floor(x + 0.5))


def ev(e, env: dict, ctx: dict):
    if e is None or isinstance(e, (bool, int, float, str)):
        return float(e) if isinstance(e, int) and not isinstance(e, bool) else e
    if isinstance(e, list):
        return [ev(x, env, ctx) for x in e]
    if "var" in e:
        return env[e["var"]]
    if "data" in e:
        return ctx["data"][e["data"]]
    if "get" in e:
        obj, key = ev(e["get"][0], env, ctx), ev(e["get"][1], env, ctx)
        if obj is None:
            return None
        if isinstance(obj, list):
            i = int(key)
            return obj[i] if 0 <= i < len(obj) else None
        return obj.get(key)
    if "call" in e:
        return ctx["deps"][e["call"]](*[ev(a, env, ctx) for a in e["args"]])
    op = e["op"]
    if op == "filter":
        out = []
        for x in ev(e["list"], env, ctx):
            if _truthy(ev(e["where"], {**env, e["as"]: x}, ctx)):
                out.append(x)
        return out
    if op == "dict":
        return {k: ev(v, env, ctx) for k, v in e["fields"].items()}
    if op == "if":
        c, a, b = e["args"]
        return ev(a, env, ctx) if _truthy(ev(c, env, ctx)) else ev(b, env, ctx)
    if op == "and":
        for a in e["args"]:
            if not _truthy(ev(a, env, ctx)):
                return False
        return True
    if op == "or":
        for a in e["args"]:
            if _truthy(ev(a, env, ctx)):
                return True
        return False
    a = [ev(x, env, ctx) for x in e["args"]]
    if op == "add":
        return a[0] + a[1]
    if op == "sub":
        return a[0] - a[1]
    if op == "mul":
        return a[0] * a[1]
    if op == "div":
        return a[0] / a[1]
    if op in ("lt", "le", "gt", "ge"):
        return {"lt": a[0] < a[1], "le": a[0] <= a[1], "gt": a[0] > a[1], "ge": a[0] >= a[1]}[op]
    if op == "eq":
        return a[0] == a[1]
    if op == "ne":
        return a[0] != a[1]
    if op == "not":
        return not _truthy(a[0])
    if op == "truthy":
        return _truthy(a[0])
    if op == "min":
        return min(a)
    if op == "max":
        return max(a)
    if op == "floor":
        return float(math.floor(a[0]))
    if op == "js_round":
        return _js_round(a[0])
    if op == "len":
        return float(len(a[0]))
    if op == "in":
        return a[0] in (a[1] or [])
    if op == "index_of":
        return float(a[0].index(a[1])) if a[1] in a[0] else -1.0
    if op == "default":
        return a[1] if a[0] is None else a[0]
    if op == "u32":
        return float(int(a[0]) & 0xFFFFFFFF)
    if op == "copy":
        return list(a[0])
    if op == "concat_str":
        return "".join(str(x) for x in a)
    if op == "sorted_unique":
        return sorted(set(a[0]))
    if op == "flatten":
        return [x for xs in a[0] for x in xs]
    if op == "count_le":
        return float(sum(1 for n in a[0] if a[1] >= n))
    if op == "map_field":
        return [x.get(a[1]) if isinstance(x, dict) else None for x in a[0]]
    if op == "level_filter":
        out = []
        for g in a[0]:
            items = [i for i in g["items"] if ctx["deps"]["within_level"](i, a[1])]
            if items:
                out.append({**g, "items": items})
        return out
    if op == "ends_with":
        return isinstance(a[0], str) and a[0].endswith(a[1])
    if op == "not_in_list":
        return [x for x in a[0] if x not in (a[1] or [])]
    if op == "mod":  # JavaScript %: the sign follows the dividend
        return math.fmod(a[0], a[1])
    if op == "is_string":
        return isinstance(a[0], str)
    if op == "str_len":
        return float(len(a[0]))
    if op == "starts_with":
        return isinstance(a[0], str) and a[0].startswith(a[1])
    if op == "slice_from":
        return a[0][int(a[1]):]
    if op == "regex":  # full-match groups as strings, or None (JavaScript \\d is ASCII)
        import re as _re
        m = _re.fullmatch(a[0], a[1], _re.ASCII)
        return None if m is None else [m.group(0)] + list(m.groups())
    if op == "number":  # Number(text) for a decimal integer string
        return float(int(a[0]))
    if op == "is_safe_int":
        return isinstance(a[0], float) and a[0].is_integer() and abs(a[0]) <= 2**53 - 1
    if op == "concat_num":  # `${prefix}${n}` for an integer n
        return f"{a[0]}{int(a[1])}"
    raise ValueError(f"unknown op {op}")


def _truthy(v) -> bool:
    if v is None or v is False:
        return False
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return v != 0
    if isinstance(v, str):
        return v != ""
    return True


def _exec(steps, env, ctx):
    for st in steps:
        do = st["do"]
        if do == "let":
            env[st["bind"]] = ev(st["value"], env, ctx)
        elif do == "draw":
            rng = env[st["rng"]] if "rng" in st else ctx["rng"]
            env[st["bind"]] = rng.call(st["method"], [ev(a, env, ctx) for a in st["args"]])
            ctx.setdefault("draw_ids", set()).add(st["id"])
        elif do == "seeded_rng":
            env[st["bind"]] = SeededRng(int(ev(st["seed"], env, ctx)), ctx["log"], st["bind"])
        elif do == "if":
            _exec(st["then"] if _truthy(ev(st["cond"], env, ctx)) else st.get("else", []), env, ctx)
        elif do == "for_each":
            for i, x in enumerate(ev(st["in"], env, ctx)):
                env[st["as"]] = x
                if "index" in st:
                    env[st["index"]] = float(i)
                try:
                    _exec(st["body"], env, ctx)
                except _Continue:
                    continue
        elif do == "for_range":
            n = int(ev(st["count"], env, ctx))
            for i in range(n):
                env[st["index"]] = float(i)
                try:
                    _exec(st["body"], env, ctx)
                except _Continue:
                    continue
        elif do == "push":
            env[st["list"]].append(ev(st["value"], env, ctx))
        elif do == "add_unique":
            v = ev(st["value"], env, ctx)
            if v not in env[st["list"]]:
                env[st["list"]].append(v)
        elif do == "extend_group":
            env[st["list"]][int(ev(st["index"], env, ctx))]["items"].extend(ev(st["value"], env, ctx))
        elif do == "set_group_items":
            env[st["list"]][int(ev(st["index"], env, ctx))]["items"] = ev(st["value"], env, ctx)
        elif do == "remove_value":
            v = ev(st["value"], env, ctx)
            if v in env[st["list"]]:
                env[st["list"]].remove(v)
        elif do == "remove_at":
            del env[st["list"]][int(ev(st["index"], env, ctx))]
        elif do == "increment":
            env[st["list"]][int(ev(st["index"], env, ctx))] += 1
        elif do == "set_at":
            env[st["list"]][int(ev(st["index"], env, ctx))] = ev(st["value"], env, ctx)
        elif do == "emit":
            ctx["emitted"].append({"kind": st["kind"], **{k: _plain(ev(v, env, ctx)) for k, v in st["fields"].items()}})
        elif do == "submodel":
            sub = ctx["models"][st["model"]]
            sub_env = {k: ev(v, env, ctx) for k, v in st["args"].items()}
            sub_ctx = {**ctx, "data": ctx["model_data"].get(st["model"], {}), "result": None, "emitted": ctx["emitted"]}
            try:
                _exec(sub["steps"], sub_env, sub_ctx)
            except _Return:
                pass
            env[st["bind"]] = sub_ctx["result"]
        elif do == "set_result":
            ctx["result"] = ev(st["value"], env, ctx)
        elif do == "return":
            raise _Return()
        elif do == "continue":
            raise _Continue()
        else:
            raise ValueError(f"unknown step {do}")


def run(model_id: str, inputs: dict, draws, deps: dict, model_data: dict, models: dict | None = None, rng=None) -> dict:
    """Execute a model. `draws` scripts the shared rng's next() values; `deps`
    resolves named dependencies; `model_data` maps model id -> its data values."""
    models = models or {**MODELS, **SUBMODELS}
    log: list = []
    if rng is not None:
        rng.log = log
    ctx = {"rng": rng or ScriptedRng(draws, log), "log": log, "deps": deps, "models": models, "model_data": model_data,
           "data": model_data.get(model_id, {}), "emitted": [], "result": None, "draw_ids": set()}
    env = {k: (float(v) if isinstance(v, int) and not isinstance(v, bool) else v) for k, v in inputs.items()}
    try:
        _exec(models[model_id]["steps"], env, ctx)
    except _Return:
        pass
    return {"emitted": ctx["emitted"], "draws": log, "result": _plain(ctx["result"]),
            "draw_ids": sorted(ctx.get("draw_ids", set()))}


def all_models() -> dict:
    return {**MODELS, **SUBMODELS}


def all_draw_ids(model: dict) -> list[str]:
    """Every draw step id of a model (sub-models excluded)."""
    out: set = set()

    def walk(v):
        if isinstance(v, dict):
            if v.get("do") == "draw":
                out.add(v["id"])
            for x in v.values():
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)
    walk(model["steps"])
    return sorted(out)
