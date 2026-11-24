#!/usr/bin/env python3
"""Builds the reference-derived registries (Phase B2) from World of ClaudeCraft source.

  python3 tools/content/build_reference_registries.py --ref <checkout> [--check]

<checkout> is a clone of https://github.com/levy-street/world-of-claudecraft whose
HEAD is the pinned commit (the build verifies this and stops otherwise). Every input
is read with `git show <COMMIT>:<path>`, so the result depends only on the pinned
commit. Nothing from the reference is executed: class, talent, slot and quality
rules are matched as text, and the content tables (monsters, items, loot) are
evaluated by tools/content/ts_eval.py, a static evaluator for the data subset of
TypeScript with no I/O of its own. Each output records the commit and the SHA-256
of every input file; the manifest also records every output's hash.
--check rebuilds in memory and exits 1 if a committed output differs.

B2.1 classes  -> client/data/rpg_reference.json (adds "specs", "armor",
                 "weapon_groups", "dual_wield" to the existing class records;
                 base stats and kits stay as they were, already pinned by tests)
                 and client/data/rpg/talent_structure.json
B2.2 slots    -> client/data/rpg/equipment_slots.json (the 13 reference slots and
                 the class equipment rules; the legacy Charm slot is a separate,
                 hand-written ADAPTED section, never generated)
B2 R4/R5      -> client/data/rpg/quality.json, data/registry/reference_items.json,
                 data/registry/legacy_items.json
B2 R6         -> data/registry/reference_monsters.json
B2 R7         -> data/registry/reference_loot_tables.json, reference_loot_entries.json,
                 loot_selection.json
Audit         -> data/registry/id_collisions.json, reference_registry_manifest.json

Display names: class names are the approved roster names. Spec display names are
INTERIM (the spec id, capitalised) until a naming batch is approved
(docs/NAMING_FRAMEWORK.md); the reference's own spec names are kept only as
`ref.name` for traceability and must never be shown.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reference_content as rc  # noqa: E402
import reward_models  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
COMMIT = "d2b91e0884cb269422c28d0b42d2a30a01de130a"
REPO = "https://github.com/levy-street/world-of-claudecraft"
CLASSES = ["warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"]
RPG_REFERENCE = ROOT / "client" / "data" / "rpg_reference.json"
TALENTS_OUT = ROOT / "client" / "data" / "rpg" / "talent_structure.json"
SLOTS_OUT = ROOT / "client" / "data" / "rpg" / "equipment_slots.json"
QUALITY_OUT = ROOT / "client" / "data" / "rpg" / "quality.json"
# The full reference sets are registries, not shipped content: they live outside
# the Godot project so the browser build does not carry them while they are data
# only (selected records move into client/data in their phase).
REGISTRY = ROOT / "data" / "registry"
ITEMS_OUT = REGISTRY / "reference_items.json"
MONSTERS_OUT = REGISTRY / "reference_monsters.json"
LEGACY_OUT = REGISTRY / "legacy_items.json"
LOOT_TABLES_OUT = REGISTRY / "reference_loot_tables.json"
LOOT_ENTRIES_OUT = REGISTRY / "reference_loot_entries.json"
LOOT_SELECTION_OUT = REGISTRY / "loot_selection.json"
COLLISIONS_OUT = REGISTRY / "id_collisions.json"
MANIFEST_OUT = REGISTRY / "reference_registry_manifest.json"
# The game's own drop data (legacy). The loot registry never changes it; its
# hashes are recorded so a change to it is visible in the freshness check.
LEGACY_LOOT_FILES = ["client/data/enemies.json", "client/data/areas.json", "client/data/drop_tables.json",
                     "client/data/world_boss.json", "client/data/items.json", "client/data/item_catalog.json"]
GAME_NAMESPACE = "iron_legacy"

# The legacy Charm slot (owner Decision 5): hand-written, ADAPTED, legacy only.
LEGACY = {
    "status": "ADAPTED",
    "note": "Legacy compatibility only (owner decision 5, 2026-11-17). Not a reference slot. Only items marked legacy may use it; reference items never can. Removed only after every charm and save has an approved migration.",
    "slots": {
        "charm": {"accepts": "legacy_charm", "reference_equivalent": None},
    },
    "slot_map": {
        "weapon": "mainhand",
        "head": "helmet",
        "body": "chest",
        "hands": "gloves",
        "feet": "feet",
        "charm": "charm",
    },
}

# Reward sources that do not use LootEntry. The static data named here is
# evaluated exactly; the draw procedure is cited (file and line, re-located on
# every build) and not re-implemented: it is code, and porting it is a later,
# separately approved step.
REWARD_SOURCES = [
    {"id": "buddy_boss_drops", "system": "buddies",
     "data": [("src/sim/content/buddy_sources.ts", "BUDDY_BOSS_DROPS"), ("src/sim/content/buddy_sources.ts", "BUDDY_FULL_GROUP")],
     "procedure": [("src/sim/content/buddy_sources.ts", "export function buddyChancePerPlayer(", "per-player chance = chance x BUDDY_FULL_GROUP / max(1, recipients) below a full group"),
                   ("src/sim/combat/damage.ts", "rollBossBuddyDrops(ctx, e, worldBossContribs, null);", "rolled at the boss death site, never from corpse loot")]},
    {"id": "world_quest_class_loot", "system": "world quests",
     "data": [("src/sim/content/world_quest_loot.ts", "WORLD_QUEST_CLASS_LOOT")],
     "procedure": [("src/sim/world_quest_item_slots.ts", "const table = WORLD_QUEST_CLASS_LOOT[cls];", "the reward is chosen from the player's class list by world_quest_item_slots.ts")]},
    {"id": "hoard_boss_loot", "system": "treasure-map hoards",
     "data": [("src/sim/content/hoard_loot.ts", "HOARD_BOSS_LOOT_TABLES"), ("src/sim/content/hoard_loot.ts", "HOARD_BASE_ITEM_IDS"),
              ("src/sim/content/hoard_loot.ts", "HOARD_LOOT_TIERS"), ("src/sim/content/hoard_loot.ts", "HOARD_PIECES_PER_BOSS")],
     "procedure": [("src/sim/content/hoard_loot.ts", "(bossTemplateId ? HOARD_BOSS_LOOT_TABLES[bossTemplateId] : undefined) ?? HOARD_BASE_ITEM_IDS;", "rollHoardBossDrop picks from the boss's table, or the base pieces")]},
    {"id": "treasure_vault_payouts", "system": "treasure-map hoards",
     "data": [("src/sim/content/treasure_maps.ts", "VAULT_PAYOUTS"), ("src/sim/content/treasure_maps.ts", "VAULT_MATERIAL_POOL"),
              ("src/sim/content/treasure_maps.ts", "VAULT_GUEST_GEAR_CHANCE"), ("src/sim/content/treasure_maps.ts", "VAULT_OWNER_COPPER_BONUS")],
     "procedure": [("src/sim/rift/hoard_reward_roll.ts", "export function rollHoardReward(", "fixed draw order: material, gear, marks, mount, next map; every chance is drawn")]},
    {"id": "rift_clear_pools", "system": "the Rift",
     "calls": [("src/sim/rift/loot_pools.ts", "riftNormalClearPool"), ("src/sim/rift/loot_pools.ts", "riftHeroicClearPool")],
     "data": [("src/sim/rift/loot_pools.ts", "RIFT_NORMAL_LOOT_SOURCE_LEVEL")],
     "procedure": [("src/sim/rift/progression.ts", "const pool = riftNormalClearPool();", "a C-rank clear pays one item picked from the normal pool (rng.int)"),
                   ("src/sim/rift/progression.ts", "const heroicPool = riftHeroicClearPool();", "higher ranks add a pick from the heroic pool")]},
    {"id": "rift_first_clear", "system": "the Rift",
     "data": [("src/sim/rift/progression.ts", "TIER_POWER"), ("src/sim/rift/progression.ts", "RIFT_GEM_IDS"),
              ("src/sim/content/rift/items.ts", "RIFT_ESSENCE_ITEM_ID")],
     "procedure": [("src/sim/rift/progression.ts", "export function addRiftProgressionLoot(", "first-clear personal loot: a band per participant (quality drawn when eligible), Rift Essence by tier power, a gem on A/S or a high crafting bias"),
                   ("src/sim/rift/runs.ts", "addRiftProgressionLoot(", "paid only when the race claim names an event (the winning party)")]},
    {"id": "drowned_litany_chest", "system": "delves",
     "data": [("src/sim/content/delves/drowned_litany_loot.ts", "LOOT_ARCHETYPE"), ("src/sim/content/delves/drowned_litany_loot.ts", "UNCOMMON_A"),
              ("src/sim/content/delves/drowned_litany_loot.ts", "UNCOMMON_B"), ("src/sim/content/delves/drowned_litany_loot.ts", "RARE"),
              ("src/sim/content/delves/drowned_litany_loot.ts", "EPIC")],
     "procedure": [("src/sim/content/delves/drowned_litany_loot.ts", "export function drownedLitanyChestItemsForTier(", "the chest's chances (0.5, 0.12, 0.2 and the rest) are literals inside this function, drawn in a fixed order")]},
    {"id": "weekly_boss_tables", "system": "weekly rewards",
     "data": [("src/sim/weekly_reward_tables.ts", "WEEKLY_BOSS_TABLES")],
     "procedure": [("src/sim/weekly_reward_tables.ts", "export function weeklyBossLootPool(", "a weekly choice reads the boss's own loot table (item rows with chance > 0, no quest rows)")]},
]
# Reward modules that are not loot tables; listed so every source is accounted for.
NOT_LOOT_SOURCES = {
    "src/sim/content/faction_rewards.ts": "faction reputation rewards (faction system)",
    "src/sim/content/quest_choice_rewards.ts": "quest choose-one rewards (quest system)",
    "src/sim/quests/quest_recipe_rewards.ts": "quest recipe rewards (quest system)",
    "src/sim/quests/quest_reward_choice.ts": "quest reward choice (quest system)",
    "src/sim/content/queue_rewards.ts": "group-finder queue rewards (queue system)",
    "src/sim/social/queue_rewards.ts": "group-finder queue rewards (queue system)",
    "src/sim/content/referral_rewards.ts": "referral rewards (account system)",
    "src/sim/referral_rewards.ts": "referral rewards (account system)",
    "src/sim/pvp/world_pvp_rewards.ts": "world PvP rewards (PvP system, excluded from scope)",
    "src/sim/pvp/world_pvp_rewards_rules.ts": "world PvP rewards (PvP system, excluded from scope)",
    "src/sim/daily_rewards_stub.ts": "daily login reward stub (account system)",
    "src/sim/dev/balgath_dev_loot.ts": "developer tooling, not game content",
    "src/sim/world_quest_reward_mail.ts": "mail delivery of world-quest rewards (data in world_quest_class_loot)",
    "src/sim/weekly_rewards.ts": "weekly reward state (data in weekly_boss_tables)",
}


class Source:
    def __init__(self, checkout: Path) -> None:
        self.checkout = checkout
        self.hashes: dict[str, str] = {}

    _cache: dict[str, str] = {}

    def read(self, path: str) -> str:
        if path in Source._cache:
            out = Source._cache[path]
            self.hashes[path] = hashlib.sha256(out.encode()).hexdigest()
            return out
        out = subprocess.run(["git", "-C", str(self.checkout), "show", f"{COMMIT}:{path}"],
                             capture_output=True, text=True, check=True).stdout
        Source._cache[path] = out
        self.hashes[path] = hashlib.sha256(out.encode()).hexdigest()
        return out


def verify_checkout(checkout: Path) -> None:
    """Stop unless the checkout's HEAD is the pinned commit."""
    head = subprocess.run(["git", "-C", str(checkout), "rev-parse", "HEAD"], capture_output=True, text=True)
    if head.returncode != 0:
        raise SystemExit(f"{checkout}: not a git checkout")
    if head.stdout.strip() != COMMIT:
        raise SystemExit(f"{checkout}: HEAD is {head.stdout.strip()}, not the pinned {COMMIT}; "
                         f"point --ref at a World of ClaudeCraft clone checked out at the pinned commit (changing the pin needs the owner's approval)")


def tree(checkout: Path, prefix: str = "src") -> set[str]:
    return set(subprocess.run(["git", "-C", str(checkout), "ls-tree", "-r", "--name-only", COMMIT, prefix],
                              capture_output=True, text=True, check=True).stdout.split())


def strings(text: str) -> list[str]:
    """Quoted string literals in order (single or double quotes, escapes kept simple)."""
    return [m.group(2) for m in re.finditer(r"(['\"])((?:\\.|(?!\1).)*)\1", text)]


def parse_specs(src: Source) -> dict[str, list[dict]]:
    specs: dict[str, list[dict]] = {c: [] for c in CLASSES}
    classic = src.read("src/sim/content/talents_classic.ts")
    for m in re.finditer(r"\bspec\(\s*(.*?)\n  \),", classic, re.S):
        args = strings(m.group(1))
        spec_id, cls, name, role, _icon, _desc, signature = args[:7]
        specs[cls].append({"id": spec_id, "ref_name": name, "role": role, "signature": signature})
    warrior = src.read("src/sim/content/talents_warrior.ts")
    for m in re.finditer(r"id: '([a-z_]+)', class: 'warrior', name: '([^']+)', role: '([a-z]+)'.*?signature: '([a-z_]+)'",
                         warrior, re.S):
        specs["warrior"].append({"id": m.group(1), "ref_name": m.group(2), "role": m.group(3), "signature": m.group(4)})
    primary = src.read("src/sim/content/spec_primary_stat.ts")
    for cls in CLASSES:
        line = re.search(rf"^\s*{cls}: \{{(.*?)\}},", primary, re.M).group(1)
        stats = dict(re.findall(r"([a-z_]+): '([a-z]+)'", line))
        for spec in specs[cls]:
            spec["primary_stat"] = stats[spec["id"]]
        if set(stats) != {s["id"] for s in specs[cls]}:
            raise SystemExit(f"{cls}: spec ids differ between spec defs and SPEC_PRIMARY_STAT")
    return specs


def parse_talent_rows(src: Source) -> dict:
    rows = src.read("src/sim/content/talent_rows.ts")
    levels = re.search(r"ROW_LEVELS[^=]*=\s*\[([^\]]*)\]", rows)
    options = re.search(r"OPTIONS_PER_ROW[^=]*=\s*(\d+)", rows)
    if not levels or not options:
        raise SystemExit("talent_rows.ts: ROW_LEVELS or OPTIONS_PER_ROW not found")
    row_levels = [int(x) for x in re.findall(r"\d+", levels.group(1))]
    talents = src.read("src/sim/content/talents.ts")
    unlock = re.search(r"export const SPEC_UNLOCK_LEVEL = (ROW_LEVELS\[(\d+)\]|\d+);", talents)
    if not unlock:
        raise SystemExit("talents.ts: SPEC_UNLOCK_LEVEL not found")
    spec_level = row_levels[int(unlock.group(2))] if unlock.group(2) else int(unlock.group(1))
    return {
        "row_levels": row_levels,
        "options_per_row": int(options.group(1)),
        "spec_level": spec_level,
        "spec_level_source": f"src/sim/content/talents.ts SPEC_UNLOCK_LEVEL = {unlock.group(1)}",
    }


def parse_equipment(src: Source) -> dict:
    types = src.read("src/sim/types.ts")
    slots = re.findall(r"'([a-z0-9]+)'", re.search(r"ALL_EQUIP_SLOTS[^=]*=\s*\[(.*?)\]", types, re.S).group(1))
    rules = src.read("src/sim/equipment_rules.ts")

    def group(name: str) -> list[str]:
        body = re.search(rf"const {name} = new Set<PlayerClass>\(\[(.*?)\]\)", rules, re.S).group(1)
        return re.findall(r"'([a-z]+)'", body)

    rank = dict((k, int(v)) for k, v in re.findall(r"^\s*(cloth|leather|mail): (\d+),", rules, re.M))
    mail, leather = group("MAIL_CLASSES"), group("LEATHER_CLASSES")
    armor = {c: "mail" if c in mail else "leather" if c in leather else "cloth" for c in CLASSES}
    dual = re.search(r"export function canDualWield\(.*?\{(.*?)\n\}", rules, re.S).group(1)
    dual_rules = [{"class": c, "spec": s or None} for c, s in
                  re.findall(r"cls === '([a-z]+)'(?: && spec === '([a-z_]+)')?", dual)]
    two = re.search(r"export function canDualWieldTwoHand\(.*?\{(.*?)\n\}", rules, re.S).group(1)
    two_rules = [{"class": c, "spec": s} for c, s in re.findall(r"cls === '([a-z]+)' && spec === '([a-z_]+)'", two)]
    return {
        "slots": slots,
        "armor_rank": rank,
        "class_max_armor": armor,
        "weapon_groups": {"warrior": group("WARRIOR_WEAPON_CLASSES"), "caster": group("CASTER_WEAPON_CLASSES"),
                          "rogue": group("ROGUE_WEAPON_CLASSES")},
        "dual_wield": dual_rules,
        "dual_wield_two_hand": two_rules,
        "rogue_no_two_hand": "cls === 'rogue' && item.kind === 'weapon' && weaponHand(item) === 'twohand'" in rules,
        "ring_order": ["ring1", "ring2"] if "if (!equipment.ring1) return 'ring1';" in rules else None,
        "legendary_unique": "Every legendary item is unique-equipped" in rules,
    }


def parse_quality(src: Source) -> dict:
    types = src.read("src/sim/types.ts")
    tiers = re.findall(r"'([a-z]+)'", re.search(r"quality\?: ((?:'[a-z]+' \| )+'[a-z]+');", types).group(1))
    core = src.read("src/sim/loot_quality/core.ts")
    draw = re.search(r"rng\.int\((\d+), (\d+)\)", core)
    none = int(re.search(r"if \(draw < (\d+)\) return undefined;", core).group(1))
    t = re.search(r"draw < (\d+) \? 1 : draw < (\d+) \? 2 : draw < (\d+) \? 3 : 4", core)
    step = int(re.search(r"level \+ (\d+) \* quality\.tier\)", core).group(1))
    lo, hi = int(draw.group(1)), int(draw.group(2))
    edges = [lo, none, int(t.group(1)), int(t.group(2)), int(t.group(3)), hi + 1]
    per_copy = []
    for tier in range(5):
        per_copy.append({"tier": tier, "id": "plain" if tier == 0 else f"tier{tier}",
                         "draws": edges[tier + 1] - edges[tier], "item_level_bonus": step * tier})
    return {"tiers": tiers, "per_copy": {"draw_range": [lo, hi], "outcomes": per_copy}}


def mob_mechanic_fields(src: Source) -> list[str]:
    types = src.read("src/sim/types.ts")
    start = types.index("export interface MobTemplate")
    end = types.index("\n}", start)
    fields = re.findall(r"^  ([a-zA-Z]+)\??:", types[start:end], re.M)
    return [f for f in fields if f not in rc.MOB_BASE_FIELDS]


def mob_template_fields(src: Source) -> list[str]:
    types = src.read("src/sim/types.ts")
    start = types.index("export interface MobTemplate")
    end = types.index("\n}", start)
    return re.findall(r"^  ([a-zA-Z]+)\??:", types[start:end], re.M)


def item_kinds(src: Source) -> list[str]:
    types = src.read("src/sim/types.ts")
    m = re.search(r"export type ItemKind =((?:\s*\|\s*'[a-z_]+')+);", types)
    if not m:
        raise SystemExit("types.ts: ItemKind union not found")
    return re.findall(r"'([a-z_]+)'", m.group(1))


def text_scan_ids(src: Source, files: set[str], kinds: list[str]) -> tuple[set[str], set[str]]:
    """Record ids found by matching `{ id: '...' }` text: a cross-check only."""
    mobs, items = set(), set()
    kind_re = re.compile(r"\bkind:\s*'(" + "|".join(kinds) + r")'")
    for path in sorted(f for f in files if f.startswith("src/sim/content/") and f.endswith(".ts")):
        text = strip_comments(src.read(path))
        for body in objects_with_id(text):
            rec_id = re.match(r"\{\s*id:\s*'([^']+)'", body).group(1)
            top = flatten(body[1:-1])
            if re.search(r"\bhpBase\s*:", top):
                mobs.add(rec_id)
            elif kind_re.search(top) and re.search(r"\bname\s*:", top):
                items.add(rec_id)
    return mobs, items


def flatten(body: str) -> str:
    prev = None
    while prev != body:
        prev, body = body, re.sub(r"\{[^{}]*\}", "{}", body)
    return body


def objects_with_id(text: str):
    stack, instr, i, n = [], None, 0, len(text)
    while i < n:
        c = text[i]
        if instr:
            if c == "\\":
                i += 2
                continue
            if c == instr:
                instr = None
        elif c in "'\"`":
            instr = c
        elif c == "{":
            stack.append(i)
        elif c == "}" and stack:
            start = stack.pop()
            body = text[start:i + 1]
            if re.match(r"\{\s*id:\s*'", body):
                yield body
        i += 1


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"(?m)(^|[^:'\"])//.*$", r"\1", text)


def legacy_items() -> dict:
    data = ROOT / "client" / "data"
    out = {}
    for name in ("items.json", "item_catalog.json"):
        for item_id, item in json.loads((data / name).read_text())["items"].items():
            rec = {"file": f"client/data/{name}", "rarity": item.get("rarity"), "slot": item.get("slot"),
                   "status": "LEGACY", "stats_kept": True}
            if item.get("rarity") == "godforged":
                rec["adapted_rarity"] = "legendary"
                rec["adaptation"] = "ADAPTED: Godforged is not a reference tier; mapped to legendary as legacy compatibility (owner decision 4). Applies when items move to the new rules; the live data keeps 'godforged' until then."
            if item.get("slot") == "charm":
                rec["slot_note"] = "interim legacy Charm slot (owner decision 5); a per-charm mapping proposal comes later"
            out[item_id] = rec
    return dict(sorted(out.items()))


def monster_reconciliation(ref: rc.Reference, src: Source, monsters: dict, scan_mobs: set[str]) -> dict:
    """The earlier registry's 316 (a `{ id: '...' }` text match with hpBase) against
    the evaluated tables, every difference classified from the source itself."""
    base = {k for k, m in monsters.items() if m["registry_table"] == rc.MOBS_TABLE}
    studio = set(monsters) - base
    reasons: dict[str, list[str]] = {}
    for mob_id in sorted((base | studio) - scan_mobs):
        ref_ = monsters[mob_id]["ref"]
        path, export = ref_["file"], ref_["export"]
        live = ref.module_value(path, export)
        if not (isinstance(live, dict) and mob_id in live):
            # The attributed export is the record itself, keyed by a computed key
            # in data.ts or studio_content.ts.
            why = "registered under a computed key ([RECORD.id]: RECORD); its id is a constant"
        else:
            why = ref.record_construction(path, export, mob_id)
        if why.startswith("a literal record whose id is the constant"):
            category = "a literal record whose id is a named constant (the text match needs id: '<literal>')"
        elif why.startswith("built by a factory call"):
            category = "built by a factory call (the text match needs a literal record)"
        elif why.startswith("spread into the table literal"):
            category = "spread into its table from a builder function (no literal record)"
        else:
            category = why
        reasons.setdefault(category, []).append({"id": mob_id, "file": path, "how": why})
    by_selection: dict[str, int] = {}
    by_context: dict[str, int] = {}
    for m in monsters.values():
        sel = m["selection"].split(":")[0]
        by_selection[sel] = by_selection.get(sel, 0) + 1
        by_context[m["context"]] = by_context.get(m["context"], 0) + 1
    return {
        "_comment": "How the earlier text-matched count (316) relates to the evaluated tables. The earlier method is reproduced here (text_scan_ids), so the comparison is from the source, not from memory.",
        "earlier_text_scan": {"method": "`{ id: '<literal>' }` objects with hpBase at their top level, in src/sim/content (never evaluated)",
                              "count": len(scan_mobs), "in_MOBS": len(scan_mobs & base),
                              "in_STUDIO_CONTENT.mobs": len(scan_mobs & studio),
                              "registered_nowhere": sorted(scan_mobs - set(monsters))},
        "evaluated": {"MOBS": len(base), "STUDIO_CONTENT.mobs": len(studio), "total": len(monsters)},
        "missed_by_the_text_scan": {why: recs for why, recs in sorted(reasons.items())},
        "missed_count": sum(len(v) for v in reasons.values()),
        "duplicate_ids_across_tables": sorted(base & studio),
        "studio_overlay": "STUDIO_CONTENT.mobs is merged only while an authored map is active (studio_content.ts addMissing); the earlier registry listed its 14 Scorching Wastes records as if they were base-world monsters",
        "by_selection": dict(sorted(by_selection.items())),
        "by_context": dict(sorted(by_context.items())),
        "enemies": "PENDING_REVIEW, DEFERRED and EXCLUDED records are enemies; NOT_AN_ENEMY records are pets, buddies, practice targets, ambient creatures, muster soldiers, escort caravans and objective bodies",
    }


def loot_graph_validation(ref: rc.Reference, monsters: dict, items: dict, tables: dict, entries: dict,
                          rewards: dict) -> dict:
    """Every link of the loot graph, checked from both ends. Nothing is dropped:
    a broken link is listed under its relation with the record it came from."""
    problems: dict[str, list] = {}

    def bad(rel, what):
        problems.setdefault(rel, []).append(what)

    quests = set(ref.module_value("src/sim/data.ts", "QUESTS"))
    # The Studio overlay brings its own quests; its monsters' quest gates resolve
    # there (studio_content.ts STUDIO_CONTENT.quests), base monsters only in QUESTS.
    studio_quests = set(ref.module_value("src/sim/studio_content.ts", "STUDIO_CONTENT")["quests"])
    # monster -> loot table
    for mob_id in monsters:
        if f"mob:{mob_id}" not in tables:
            bad("monster -> loot table", mob_id)
    # loot table -> owner, entries
    seen_entries: dict[str, str] = {}
    for tid, t in tables.items():
        if t["owner"] not in monsters:
            bad("loot table -> owner monster", tid)
        if t["kind"] == "heroic_append" and not monsters.get(t["owner"], {}).get("flags", {}).get("boss") \
                and not monsters.get(t["owner"], {}).get("flags", {}).get("elite"):
            bad("heroic append -> boss owner", tid)
        for eid in t["entries"]:
            if eid not in entries:
                bad("loot table -> entry", f"{tid} -> {eid}")
            if eid in seen_entries:
                bad("duplicate entry id", eid)
            seen_entries[eid] = tid
    for eid, e in entries.items():
        if seen_entries.get(eid) != e["table"]:
            bad("orphan entry", eid)
        item = e.get("item")
        if item and item["id"] not in items:
            bad("loot entry -> item", f"{eid} -> {item['id']}")
        if e.get("quest_id") is not None:
            owner = monsters.get(tables.get(e["table"], {}).get("owner"), {})
            known = quests | studio_quests if owner.get("registry_table") == rc.STUDIO_MOBS_TABLE else quests
            if e["quest_id"] not in known:
                bad("conditional entry -> quest", f"{eid} -> {e['quest_id']}")
        if e.get("unless_owned_item") is not None and e["unless_owned_item"] not in items:
            bad("conditional entry -> unlessOwnedItem", f"{eid} -> {e['unless_owned_item']}")
    # reward source -> monsters, tables, items, execution model
    links: dict[str, dict] = {}
    for sid, r in rewards.items():
        data = r["model_data"]
        mobs_named: set[str] = set()
        items_named: set[str] = set()
        if sid == "buddy_boss_drops":
            mobs_named = {d["bossId"] for d in data["BUDDY_BOSS_DROPS"]}
        elif sid == "hoard_boss_loot":
            mobs_named = set(data["HOARD_BOSS_LOOT_TABLES"])
            bases = set(data["HOARD_BASE_ITEM_IDS"]) | {i for v in data["HOARD_BOSS_LOOT_TABLES"].values() for i in v}
            items_named = {pre + b for b in bases for pre in ("", "rare_", "legendary_")}
        elif sid == "weekly_boss_tables":
            mobs_named = {t["bossId"] for t in data["WEEKLY_BOSS_TABLES"]}
            for boss in mobs_named:
                if f"mob:{boss}" not in tables:
                    bad("reward source -> loot table", f"{sid} -> mob:{boss}")
        elif sid == "world_quest_class_loot":
            items_named = {i for v in data["WORLD_QUEST_CLASS_LOOT"].values() for i in v}
        elif sid == "treasure_vault_payouts":
            items_named = set(data["VAULT_MATERIAL_POOL"]) | set(data["TREASURE_MAP_ITEM_IDS"].values()) | \
                {data["HEROIC_MARK_CURRENCY_ID"], data["MOUNT_REINS"]}
        elif sid == "rift_clear_pools":
            for k in ("NORMAL_POOL", "HEROIC_POOL", "LEGENDARY_IDS", "GREEN_REINS", "BLUE_REINS", "EPIC_REINS",
                      "PATTERN_IDS", "FARM_IDS"):
                items_named |= set(data[k])
        elif sid == "rift_first_clear":
            items_named = set(data["RIFT_GEM_IDS"]) | {data["ESSENCE"], "riftbound_band_of_might", "riftbound_band_of_guile",
                                                       "riftbound_band_of_insight"}
        elif sid == "drowned_litany_chest":
            for k in ("UNCOMMON_A", "UNCOMMON_B", "RARE", "EPIC"):
                items_named |= set(data[k].values())
        for m in sorted(mobs_named - set(monsters)):
            bad("reward source -> monster", f"{sid} -> {m}")
        for i in sorted(items_named - set(items)):
            bad("reward source -> item", f"{sid} -> {i}")
        model = r.get("execution_model") or {}
        if not model.get("steps") or not model.get("entry_point", {}).get("source"):
            bad("reward source -> execution model", sid)
        links[sid] = {"monsters": len(mobs_named), "items": len(items_named),
                      "entry_point": model.get("entry_point", {}).get("source")}
    counts = {
        "monsters": len(monsters), "loot_tables": len(tables), "loot_entries": len(entries),
        "entries_with_items": sum(1 for e in entries.values() if e.get("item")),
        "quest_gated_entries": sum(1 for e in entries.values() if e.get("quest_id") is not None),
        "reward_sources": len(rewards), "quests_known": len(quests), "studio_quests_known": len(studio_quests),
        "quest_gates_resolved_in_studio_overlay": sum(
            1 for e in entries.values() if e.get("quest_id") in studio_quests and e.get("quest_id") not in quests),
    }
    return {"counts": counts, "reward_source_links": links, "problems": problems,
            "result": "PASS" if not problems else "FAIL"}


def source_block(src: Source) -> dict:
    return {"repository": REPO, "commit": COMMIT, "inputs": dict(sorted(src.hashes.items())),
            "method": "pinned source read with git show (never executed); tools/content/build_reference_registries.py"}


def game_ids() -> dict[str, set[str]]:
    data = ROOT / "client" / "data"
    items = set()
    for name in ("items.json", "item_catalog.json"):
        items |= set(json.loads((data / name).read_text())["items"])
    enemies = set(json.loads((data / "enemies.json").read_text())["enemies"])
    return {"monsters": enemies, "items": items}


def collisions_doc(monsters: dict, items: dict, tables: dict) -> dict:
    """Ids that exist in both namespaces. Each side keeps its own record; the
    namespaced ids (reference:<id>, iron_legacy:<id>) never collide."""
    game = game_ids()
    out = {}
    for domain, ref_ids in (("monsters", set(monsters)), ("items", set(items))):
        shared = sorted(ref_ids & game[domain])
        out[domain] = {
            "reference_count": len(ref_ids),
            "iron_legacy_count": len(game[domain]),
            "shared_bare_ids": [{"id": i, "reference": rc.namespaced(i), "iron_legacy": f"{GAME_NAMESPACE}:{i}",
                                 "resolution": "each side keeps its own record; adopting the reference record needs a mapped id"}
                                for i in shared],
        }
    cross = sorted(set(monsters) & set(items))
    out["reference_monsters_vs_reference_items"] = cross
    out["loot_table_ids_unique"] = len(tables) == len(set(tables))
    return {
        "_comment": "B2 id collision audit. Reference records are addressed as reference:<id> and the game's own as iron_legacy:<id>; a bare id shared by both is listed here and never merged. Generated; do not edit.",
        "namespaces": {"reference": "World of ClaudeCraft records at the pinned commit (data/registry)",
                       GAME_NAMESPACE: "The Iron Legacy's own records (client/data)"},
        **out,
    }


def resolved_model(src: Source, model: dict) -> dict:
    """A model with every citation re-located in the pinned source (file:line);
    the build fails if a cited line of code no longer exists."""
    def walk(v):
        if isinstance(v, dict):
            out = {}
            for k, x in v.items():
                if k == "cite" and isinstance(x, list):
                    path, needle = x
                    out["source"] = f"{path}:{rc.line_of(src.read(path), needle, path)}"
                    out["code"] = needle
                elif k == "entry_point":
                    out[k] = {**x, "source": f"{x['file']}:{rc.line_of(src.read(x['file']), x['cite'], x['file'])}"}
                    out[k].pop("cite")
                else:
                    out[k] = walk(x)
            return out
        if isinstance(v, list):
            return [walk(x) for x in v]
        return v
    resolved = walk(model)
    resolved["model_sha256"] = rc.sha256(json.dumps(model, sort_keys=True))
    return resolved


def build_loot(ref: rc.Reference, src: Source, monsters: dict, item_index: dict[str, str]) -> tuple[dict, dict, dict]:
    tables: dict[str, dict] = {}
    entries: dict[str, dict] = {}

    def add_table(table_id: str, kind: str, owner: str | None, roller: str, raw: list, source: dict) -> None:
        recs = [rc.loot_entry(table_id, i, e, item_index) for i, e in enumerate(raw)]
        for r in recs:
            entries[r["id"]] = r
        ids = sorted({r["item"]["id"] for r in recs if r.get("item")})
        tables[table_id] = {
            "id": table_id,
            "kind": kind,
            "owner": owner,
            "owner_namespaced": rc.namespaced(owner) if owner else None,
            "roller": roller,
            "entries": [r["id"] for r in recs],
            "entry_count": len(recs),
            "roll_group_totals": rc.group_totals(recs),
            "item_ids": ids,
            "unresolved_item_ids": sorted({r["item"]["id"] for r in recs if r.get("item") and not r["item"]["resolves"]}),
            "copper_rows": sum(1 for r in recs if r.get("copper") is not None),
            "quest_rows": sum(1 for r in recs if r.get("quest_id") is not None),
            "source": source,
        }

    for mob_id, mob in monsters.items():
        raw = ref.mobs.get(mob_id, ref.studio_mobs.get(mob_id))
        loot = rc.to_json(raw.get("loot", [])) if isinstance(raw, dict) else []
        roller = "world_boss_personal" if mob["flags"].get("worldBoss") else "corpse"
        add_table(f"mob:{mob_id}", "mob_loot", mob_id, roller, loot if isinstance(loot, list) else [loot],
                  {"file": mob["ref"]["file"], "field": f"{mob['registry_table']}.{mob_id}.loot"})
    heroic = ref.heroic_boss_loot()
    for boss_id in sorted(heroic):
        add_table(f"heroic_append:{boss_id}", "heroic_append", boss_id, "corpse_heroic_append", rc.to_json(heroic[boss_id]),
                  {"file": "src/sim/content/heroic_loot.ts", "field": f"HEROIC_BOSS_LOOT.{boss_id}"})

    rewards = {}
    for spec in REWARD_SOURCES:
        data = {}
        for path, name in spec["data"]:
            try:
                data[name] = rc.to_json(ref.module_value(path, name))
            except rc.Unsupported as e:
                data[name] = {"$unknown": e.reason, "at": e.where or path}
        for path, name in spec.get("calls", []):
            try:
                data[f"{name}()"] = rc.to_json(ref.call(path, name))
            except rc.Unsupported as e:
                data[f"{name}()"] = {"$unknown": e.reason, "at": e.where or path}
        named: set[str] = set()
        rc.item_ids_in(data, named)
        linked = sorted(i for i in named if i in item_index)
        unknowns: list = []
        rc.find_unknowns(data, spec["id"], unknowns)
        rewards[spec["id"]] = {
            "id": spec["id"],
            "kind": "reward_source",
            "system": spec["system"],
            "data": data,
            "data_status": "VERIFIED: evaluated from the pinned source",
            "procedure": [{"rule": rule, "source": f"{p}:{rc.line_of(src.read(p), needle, p)}"} for p, needle, rule in spec["procedure"]],
            "procedure_status": "MODELLED: ordered execution steps in 'execution_model', verified against the source functions (same scripted draws) and the reference's own test goldens by tools/content/verify_reward_models.py (data/registry/reward_model_verification.json). Documented source rules, not Iron Legacy loot logic.",
            "execution_model": resolved_model(src, reward_models.MODELS[spec["id"]]),
            "model_data": ref.model_data(reward_models.MODELS[spec["id"]]),
            "item_ids": linked,
            "unknown_values": unknowns,
        }
    owned = {e: s for e, s in NOT_LOOT_SOURCES.items()}
    for path in owned:
        src.read(path)  # fails if a listed module no longer exists
    coverage = [{"path": p, "status": "LOOT_TABLES", "covered_by": "mob loot (MOBS) and HEROIC_BOSS_LOOT"} for p in
                ("src/sim/loot/loot_roll.ts", "src/sim/content/heroic_loot.ts", "src/sim/content/nythraxis_loot.ts",
                 "src/sim/content/crucible_collections.ts", "src/sim/loot/weighted_loot_group.ts")]
    for spec in REWARD_SOURCES:
        for p in sorted({p for p, *_ in spec["data"] + spec.get("calls", []) + spec["procedure"]}):
            coverage.append({"path": p, "status": "REWARD_SOURCE", "covered_by": spec["id"]})
    coverage += [{"path": p, "status": "NOT_A_LOOT_TABLE", "reason": why} for p, why in sorted(owned.items())]
    submodels = {mid: {**resolved_model(src, m), "model_data": ref.model_data(m)}
                 for mid, m in sorted(reward_models.SUBMODELS.items())}
    return tables, entries, {"reward_sources": rewards, "coverage": coverage,
                             "execution_submodels": submodels, "rng_semantics": reward_models.RNG_SEMANTICS}


def raw_registry_values(ref: rc.Reference) -> dict[str, object]:
    """Every evaluated value the registries are made from, before JSON: the
    monster and item tables, the heroic appends and the reward-source data."""
    out: dict[str, object] = {
        "MOBS": ref.mobs, "STUDIO_CONTENT.mobs": ref.studio_mobs,
        "ITEMS": ref.items, "STUDIO_CONTENT.items": ref.studio_items,
        "HEROIC_BOSS_LOOT": ref.heroic_boss_loot(),
    }
    for spec in REWARD_SOURCES:
        for path, name in spec["data"]:
            try:
                out[f"{spec['id']}.{name}"] = ref.module_value(path, name)
            except rc.Unsupported:
                pass  # already recorded as UNKNOWN in the reward source
        for path, name in spec.get("calls", []):
            try:
                out[f"{spec['id']}.{name}()"] = ref.call(path, name)
            except rc.Unsupported:
                pass
    return out


def build(checkout: Path, perturb=None) -> dict[Path, str]:
    verify_checkout(checkout)
    src = Source(checkout)
    specs = parse_specs(src)
    talents = parse_talent_rows(src)
    equip = parse_equipment(src)
    reference = json.loads(RPG_REFERENCE.read_text())
    for cls in CLASSES:
        rec = reference["classes"][cls]
        rec["specs"] = [{
            "id": s["id"],
            "display_name": s["id"].replace("_", " ").title(),
            "display_name_status": "INTERIM: spec id; original name pending a naming batch",
            "role": s["role"], "primary_stat": s["primary_stat"], "signature": s["signature"],
            "ref": {"id": s["id"], "name": s["ref_name"], "file": "src/sim/content/talents_warrior.ts" if cls == "warrior"
                    else "src/sim/content/talents_classic.ts", "commit": COMMIT},
        } for s in specs[cls]]
        rec["armor"] = equip["class_max_armor"][cls]
        rec["weapon_groups"] = sorted(g for g, members in equip["weapon_groups"].items() if cls in members)
        rec["dual_wield"] = [r["spec"] or "all" for r in equip["dual_wield"] if r["class"] == cls]
    reference["registry_source"] = source_block(src)
    slots_doc = {
        "_comment": "B2.2 equipment slot registry. 'reference' is generated from the pinned source (VERIFIED); 'legacy' is hand-written compatibility data (ADAPTED). Not used by gameplay yet.",
        "source": source_block(src),
        "reference": {
            "slots": [{"id": s, "accepts": "ring" if s in ("ring1", "ring2") else s} for s in equip["slots"]],
            "armor_rank": equip["armor_rank"],
            "weapon_groups": equip["weapon_groups"],
            "dual_wield": equip["dual_wield"],
            "dual_wield_two_hand": equip["dual_wield_two_hand"],
            "rogue_no_two_hand": equip["rogue_no_two_hand"],
            "ring_order": equip["ring_order"],
            "legendary_unique": equip["legendary_unique"],
        },
        "legacy": LEGACY,
    }
    talents_doc = {
        "_comment": "B2.1 talent structure (VERIFIED). Rows and options per class come with the ability registry (B2 R2).",
        "source": source_block(src),
        **talents,
    }
    qsrc = Source(checkout)
    quality = parse_quality(qsrc)
    total = sum(o["draws"] for o in quality["per_copy"]["outcomes"])
    span = quality["per_copy"]["draw_range"][1] - quality["per_copy"]["draw_range"][0] + 1
    if total != span:
        raise SystemExit(f"per-copy quality draws sum to {total}, not {span}")
    quality_doc = {
        "_comment": "B2 quality registry (VERIFIED). 'tiers' is the item quality union in src/sim/types.ts; 'per_copy' is createLootQuality in src/sim/loot_quality/core.ts: one integer draw in draw_range, each outcome owning 'draws' of it (probability = draws / span), and item_level_bonus = 2 x tier. Data only.",
        "source": source_block(qsrc),
        **quality,
    }

    # Monsters, items and loot: evaluated from the game's own tables.
    files = tree(checkout)
    esrc = Source(checkout)
    ref = rc.Reference(esrc, files, perturb)
    kinds = item_kinds(esrc)
    items = ref.item_records(kinds)
    bad_kinds = sorted({str(i["kind"]) for i in items.values()} - set(kinds))
    if bad_kinds:
        raise SystemExit(f"item kinds outside the ItemKind union: {bad_kinds}")
    item_index = {i: rec["registry_table"] for i, rec in items.items()}
    mechanic_fields = mob_mechanic_fields(esrc)
    template_fields = set(mob_template_fields(esrc))
    monsters = ref.monster_records()
    undeclared: dict[str, list[str]] = {}
    for mob_id, mob in monsters.items():
        mob["mechanics"] = {f: mob["source_fields"][f] for f in mechanic_fields if f in mob["source_fields"]}
        extra = sorted(set(mob["source_fields"]) - template_fields)
        if extra:
            undeclared[mob_id] = extra
    tables, entries, rewards = build_loot(ref, esrc, monsters, item_index)
    rollers = rc.roller_rules(esrc)
    scan_mobs, scan_items = text_scan_ids(esrc, files, kinds)
    reconciliation = monster_reconciliation(ref, esrc, monsters, scan_mobs)
    evaluation = ref.report()
    math_audit = ref.math_audit(raw_registry_values(ref))
    unresolved = [x["site"] for x in math_audit["sites"] if x["result"] == "UNRESOLVED_DEPENDENCY"]
    if unresolved:
        # A branch on an approximated value could change a registry value; the
        # values would no longer be VERIFIED. Review, then confine or mark UNKNOWN.
        raise SystemExit("approximated Math results feed decisions outside the reviewed bindings "
                         f"(reference_content.CONFINED_BINDINGS): {unresolved}")
    eval_source = source_block(esrc)

    tables_by_kind: dict[str, int] = {}
    for t in tables.values():
        tables_by_kind[t["kind"]] = tables_by_kind.get(t["kind"], 0) + 1
    monster_unknowns = sum(len(m["unknown_values"]) for m in monsters.values())
    item_unknowns = sum(len(i["unknown_values"]) for i in items.values())
    entry_unknowns = sum(len(e["unknown_values"]) for e in entries.values())

    items_doc = {
        "_comment": "B2 reference item registry: every record of the reference's ITEMS table (src/sim/data.ts, including the heroic variants it adds at load) and of the Studio overlay (STUDIO_CONTENT.items), evaluated from the pinned source. Item level is not a static field in the reference: it comes from the drop source at run time (src/sim/item_level.ts), and the required level, when null, derives from quality (src/sim/item_level_req.ts); neither is filled in. 'source_fields' keeps every field as written; names under ref.name are the reference's and are never shown. 'selection': PENDING_SELECTION (not yet decided), EXCLUDED or DEFERRED with the reason. Not shipped and not used by gameplay.",
        "source": eval_source,
        "count": len(items),
        "tables": {t: sum(1 for i in items.values() if i["registry_table"] == t) for t in (rc.ITEMS_TABLE, rc.STUDIO_ITEMS_TABLE)},
        "kinds": kinds,
        "items": items,
    }
    monsters_doc = {
        "_comment": "B2 reference monster registry: every MobTemplate of the reference's MOBS table (src/sim/data.ts, including records added at load) and of the Studio overlay (STUDIO_CONTENT.mobs), evaluated from the pinned source. 'source_fields' keeps every field as written except 'loot', which is in reference_loot_entries.json (table 'loot_table'). 'classification' comes only from the source flags (VERIFIED): world_boss, boss, rare, elite or normal; the reference has no mini-boss flag and a rare spawn stays 'rare' (owner decision 2026-11-17). 'mechanics' are the MobTemplate fields that are not record or stat fields. heroic_level is set for dungeon enemies (dungeon_difficulty.ts pins heroic mobs at 22). 'selection' is never a placement: PENDING_REVIEW, DEFERRED, EXCLUDED or NOT_AN_ENEMY with the reason. Not shipped; not used by gameplay.",
        "source": eval_source,
        "count": len(monsters),
        "tables": {t: sum(1 for m in monsters.values() if m["registry_table"] == t) for t in (rc.MOBS_TABLE, rc.STUDIO_MOBS_TABLE)},
        "mechanic_fields": mechanic_fields,
        "fields_not_in_mob_template": undeclared,
        "unknown_value_count": monster_unknowns,
        "count_reconciliation": reconciliation,
        "monsters": monsters,
    }
    legacy_doc = {
        "_comment": "The game's own items (client/data/items.json, item_catalog.json), all LEGACY. Godforged maps to legendary as an ADAPTED compatibility rule and charms keep the interim Charm slot (owner decisions 4 and 5). Their stats are kept as they are: no conversion to reference stats. Data only; the live files are unchanged.",
        "count": None,
        "items": legacy_items(),
    }
    legacy_doc["count"] = len(legacy_doc["items"])
    loot_tables_doc = {
        "_comment": "B2 R7 reference loot tables: every monster's loot (MOBS and the Studio overlay), every heroic append (HEROIC_BOSS_LOOT) and the reward sources that do not use LootEntry, evaluated from the pinned source. 'rollers' cites the code that rolls each kind of table. Chances are the exact doubles the source computes (weightedLootGroup partitions included); roll_group_totals are summed in roll order and never normalised. Data only: nothing here drops in the game.",
        "source": eval_source,
        "count": len(tables),
        "tables_by_kind": dict(sorted(tables_by_kind.items())),
        "rollers": rollers,
        "tables": dict(sorted(tables.items())),
        **rewards,
    }
    loot_entries_doc = {
        "_comment": "B2 R7 reference loot entries, one per LootEntry, id '<table>#<index>' in roll order. Fields map LootEntry one to one (itemId -> item, rollGroup -> roll_group, ...); 'source_fields' keeps the entry as written. 'copper_roll' is the inclusive range rollLoot draws (ceil(base x 0.6) to ceil(base x 1.4)). Items link to the reference item registry by reference:<id>.",
        "source": eval_source,
        "count": len(entries),
        "unknown_value_count": entry_unknowns,
        "entries": dict(sorted(entries.items())),
    }
    selection_doc = loot_selection(tables, rewards["reward_sources"], monsters, items)
    graph = loot_graph_validation(ref, monsters, items, tables, entries, rewards["reward_sources"])
    collisions = collisions_doc(monsters, items, tables)

    outputs = {
        RPG_REFERENCE: json.dumps(reference, indent=2, ensure_ascii=False) + "\n",
        SLOTS_OUT: json.dumps(slots_doc, indent=2, ensure_ascii=False) + "\n",
        TALENTS_OUT: json.dumps(talents_doc, indent=2, ensure_ascii=False) + "\n",
        QUALITY_OUT: json.dumps(quality_doc, indent=2, ensure_ascii=False) + "\n",
        ITEMS_OUT: rc.canonical(items_doc),
        MONSTERS_OUT: rc.canonical(monsters_doc),
        LEGACY_OUT: rc.canonical(legacy_doc),
        LOOT_TABLES_OUT: rc.canonical(loot_tables_doc),
        LOOT_ENTRIES_OUT: rc.canonical(loot_entries_doc),
        LOOT_SELECTION_OUT: rc.canonical(selection_doc),
        COLLISIONS_OUT: rc.canonical(collisions),
    }
    manifest = {
        "_comment": "Source manifest of the reference registries: the pinned commit, every input's SHA-256, every output's SHA-256 and count, the evaluator's report (top-level effects applied, unparsed statements, implementation-approximated Math calls) and a text-scan cross-check. Generated; do not edit.",
        "repository": REPO,
        "commit": COMMIT,
        "builder": "tools/content/build_reference_registries.py (evaluator: tools/content/ts_eval.py, tables: tools/content/reference_content.py)",
        "inputs": dict(sorted({**src.hashes, **qsrc.hashes, **esrc.hashes}.items())),
        "outputs": {str(p.relative_to(ROOT)): {"sha256": rc.sha256(t)} for p, t in sorted(outputs.items())},
        "counts": {
            "monsters": len(monsters), "monsters_by_table": monsters_doc["tables"],
            "items": len(items), "items_by_table": items_doc["tables"],
            "loot_tables": len(tables), "loot_tables_by_kind": loot_tables_doc["tables_by_kind"],
            "loot_entries": len(entries), "reward_sources": len(rewards["reward_sources"]),
            "unknown_values": {"monsters": monster_unknowns, "items": item_unknowns, "loot_entries": entry_unknowns},
        },
        "evaluation": evaluation,
        "math_audit": math_audit,
        "loot_graph": graph,
        "text_scan_cross_check": {
            "_comment": "Ids a `{ id: '...' }` text match finds in src/sim/content but that no registered table (MOBS, ITEMS, Studio overlay) contains: defined in source, never registered in the game. Listed, not adopted.",
            "monsters_defined_not_registered": sorted(scan_mobs - set(monsters)),
            "items_defined_not_registered": sorted(scan_items - set(items) - set(monsters)),
        },
    }
    outputs[MANIFEST_OUT] = rc.canonical(manifest)
    return outputs


def loot_selection(tables: dict, rewards: dict, monsters: dict, items: dict) -> dict:
    out_tables = {}
    for table_id, t in sorted(tables.items()):
        owner = monsters.get(t["owner"]) if t["owner"] else None
        owner_sel = owner["selection"] if owner else "MISSING_OWNER"
        if owner is None:
            status = "PENDING_REVIEW"
        elif owner_sel.startswith("PENDING_REVIEW"):
            status = "PENDING_REVIEW"
        elif owner_sel.startswith("NOT_AN_ENEMY"):
            status = "NOT_APPLICABLE"
        else:
            status = owner_sel.split(":", 1)[0]
        out_tables[table_id] = {"adoption": status, "owner_selection": owner_sel}
    counts: dict[str, int] = {}
    for v in out_tables.values():
        counts[v["adoption"]] = counts.get(v["adoption"], 0) + 1
    item_counts: dict[str, int] = {}
    for i in items.values():
        key = i["selection"].split(":", 1)[0]
        item_counts[key] = item_counts.get(key, 0) + 1
    legacy = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in LEGACY_LOOT_FILES}
    return {
        "_comment": "B2 R7 loot adoption status, separate from the data. A table's adoption follows its owner monster's selection: PENDING_REVIEW, DEFERRED, EXCLUDED, or NOT_APPLICABLE for a non-enemy. Nothing is adopted: no table drops in the game, every item decision stays pending, and the game's own (legacy) loot is unchanged (its file hashes are below).",
        "status_values": {
            "PENDING_REVIEW": "the owner monster may be adopted; its table is a candidate, not active",
            "DEFERRED": "waits for its system (the Rift, seasonal events, buddies, delves, weekly rewards, world quests, treasure maps)",
            "EXCLUDED": "outside the game by owner decision (Scorching Wastes, Studio overlay)",
            "NOT_APPLICABLE": "the owner is not an enemy (pet, practice target, objective, ambient)",
        },
        "tables": out_tables,
        "table_counts": dict(sorted(counts.items())),
        "reward_sources": {k: {"adoption": "DEFERRED", "reason": f"adopted with the {v['system']} system"} for k, v in sorted(rewards.items())},
        "items": {
            "selection_counts": dict(sorted(item_counts.items())),
            "note": "Every item decision stays pending (PENDING_SELECTION); this registry selects nothing.",
        },
        "legacy_loot": {"status": "UNCHANGED", "note": "The game's drop data is not read or changed by the reference registries.", "sha256": legacy},
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ref", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv[1:])
    outputs = build(args.ref)
    stale = [p for p, text in outputs.items() if not p.exists() or p.read_text(encoding="utf-8") != text]
    if args.check:
        for p in stale:
            print("stale:", p.relative_to(ROOT))
        if not stale:
            print(f"all {len(outputs)} registries are current")
        return 1 if stale else 0
    for path, text in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print("wrote", path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
