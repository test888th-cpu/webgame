"""Reference monsters, items and loot, read from World of ClaudeCraft's own registries.

Used by build_reference_registries.py. Where the earlier builder matched record
text, this module evaluates the tables the game itself uses (tools/content/ts_eval.py,
no JavaScript engine):

* monsters: `MOBS` in src/sim/data.ts, plus the Studio overlay
  (`STUDIO_CONTENT.mobs` in src/sim/studio_content.ts) that a custom map merges in;
* items: `ITEMS` (`mergeItems(...)` plus the heroic variants that data.ts adds at
  load), plus `STUDIO_CONTENT.items`;
* loot: every monster's `loot`, the heroic appends (`HEROIC_BOSS_LOOT`), and the
  reward sources that do not use LootEntry (buddy drops, world-quest class loot,
  hoard boss tables, Rift clear pools, the Drowned Litany chest, weekly tables).

Every value is exactly what the source computes: probabilities, weights and
quantities are never rounded, normalised or filled in. A value the evaluator
cannot compute is kept in place as {"$unknown": reason, "at": "file:line"}.
"""

from __future__ import annotations

import hashlib
import json
import math
import re

import ts_eval
from ts_eval import Interpreter, Unknown, Unsupported, to_json

NAMESPACE = "reference"
MOBS_TABLE = "MOBS"
STUDIO_MOBS_TABLE = "STUDIO_CONTENT.mobs"
ITEMS_TABLE = "ITEMS"
STUDIO_ITEMS_TABLE = "STUDIO_CONTENT.items"

# Top-level effects whose UNKNOWN outcome cannot change a registry value. Any
# other UNKNOWN effect fails the build: a skipped mutation could silently change
# what MOBS, ITEMS or a loot table contains.
HARMLESS_EFFECTS: dict[str, str] = {}

# Bindings whose evaluation takes decisions on approximated values, reviewed and
# shown to stay out of every registry. For each: the reason, and every source
# line that names the binding. The build re-checks both on every run (a new
# reader, or any object of the binding found in a registry, fails it), so the
# confinement is enforced, not assumed.
CONFINED_BINDINGS = {
    "src/sim/content/gravewyrm_sanctum.ts#TUSKER_ROAD": {
        "reason": "the Sledge Tusker's patrol loop, built by shuttleLoop (src/sim/mob/patrol_route.ts) from "
                  "TUSKER_ROAD_LINE; its corner and arc branches compare approximated angles. Patrol geometry is "
                  "AI movement data that no registry records; its one reader is the spawn row "
                  "patrolling('sledge_tusker', TUSKER_ROAD, ...), whose monster id is a literal",
        "references": ["src/sim/content/gravewyrm_sanctum.ts:604", "src/sim/content/gravewyrm_sanctum.ts:643"],
    },
}

# MobTemplate fields that describe the record rather than a combat mechanic.
MOB_BASE_FIELDS = {
    "id", "name", "minLevel", "maxLevel", "family", "hpPerLevel", "hpBase", "dmgBase", "dmgPerLevel",
    "attackSpeed", "armorPerLevel", "moveSpeed", "aggroRadius", "hardLeashRadius", "damageFloorPct", "loot",
    "scale", "bodyRadius", "color", "componentTags", "boss", "bossCorpseHold", "rare", "untameable",
    "worldBoss", "seasonalEvent", "quietMechanics", "elite", "xpMult", "requiresQuestId", "canSwim",
    "phasesThroughObstacles", "keepOut", "wadeDepth", "corpseSink", "respawnMult", "respawnWindow",
    "respawnSeconds", "dummy", "friendlyPracticeTarget", "restHpFraction", "offStreamIdle", "wanderHaste",
    "idleStationary", "ambient", "musterSoldier", "landmarkRange", "ccImmune", "slowImmune", "ignoreTaunt",
    "petCanTaunt", "petScaleRanks", "petRole", "mechanicLevelScale", "yells", "battleYells", "engageShout",
}
MOB_STAT_FIELDS = ["hpBase", "hpPerLevel", "dmgBase", "dmgPerLevel", "attackSpeed", "armorPerLevel", "moveSpeed",
                   "aggroRadius", "hardLeashRadius", "damageFloorPct", "scale", "bodyRadius", "xpMult",
                   "respawnSeconds", "respawnMult"]
MOB_FLAGS = ["boss", "elite", "rare", "worldBoss", "seasonalEvent", "dummy", "friendlyPracticeTarget", "ambient",
             "musterSoldier", "ccImmune", "slowImmune", "ignoreTaunt", "untameable", "petRole"]

PET_FILES = {"src/sim/content/warlock_pets.ts", "src/sim/content/mage_pets.ts", "src/sim/content/necromancy.ts"}
DUNGEON_FILES = {"src/sim/content/dungeons.ts", "src/sim/content/hollow_crypt.ts",
                 "src/sim/content/hollow_crypt_trash.ts", "src/sim/content/sunken_bastion.ts",
                 "src/sim/content/temple.ts", "src/sim/content/gravewyrm_sanctum.ts",
                 "src/sim/content/drowned_temple.ts"}
# Non-enemy templates identified by their module's own header comment.
NON_ENEMY_FILES = {
    "src/sim/content/buddy_mobs.ts": ("companion", "NOT_AN_ENEMY: a buddy follower, spawned non-hostile (buddy_mobs.ts header)"),
    "src/sim/content/yumi.ts": ("minigame_objective", "NOT_AN_ENEMY: the Protect Yumi! team objective (yumi.ts header)"),
    "src/sim/content/objective_bots.ts": ("map_objective", "NOT_AN_ENEMY: an authored map's objective rehearsal body (objective_bots.ts header)"),
}
SEASONAL_FILES = {"src/sim/content/gourdlight_eve_scarecrow.ts": "DEFERRED: Gourdlight Eve seasonal event content; adopted with the event system"}
EXCLUDED_FILES = {"src/sim/content/scorching_wastes.ts": "EXCLUDED: Scorching Wastes, a custom-map desert (owner decision 2026-11-17)"}
DEFERRED_PREFIXES = {"src/sim/content/rift/": "DEFERRED: Rift content, adopted with the Rift system"}

# The source's own classification flags, highest first. `rare` is the
# reference's rare-spawn flag; it is never a mini-boss (owner decision 2026-11-17).
CLASSIFICATION_ORDER = [("worldBoss", "world_boss"), ("boss", "boss"), ("rare", "rare"), ("elite", "elite")]


def namespaced(item_id: str) -> str:
    return f"{NAMESPACE}:{item_id}"


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def line_of(text: str, needle: str, path: str) -> int:
    """1-based line of the first occurrence; the build fails if the source no
    longer contains the code a recorded rule cites."""
    at = text.find(needle)
    if at < 0:
        raise SystemExit(f"{path}: expected source text not found: {needle!r}")
    return text.count("\n", 0, at) + 1


def approx_values(value, path: str, out: list) -> None:
    """Paths of approximated values inside a raw (pre-JSON) evaluated value."""
    if isinstance(value, (ts_eval.ApproxFloat, ts_eval.ApproxStr)):
        out.append((path, value.sites))
    elif isinstance(value, dict):
        for k, v in value.items():
            approx_values(v, f"{path}.{k}", out)
    elif isinstance(value, (list, tuple)):
        for i, v in enumerate(value):
            approx_values(v, f"{path}[{i}]", out)
    elif isinstance(value, ts_eval.JSSet):
        approx_values(value.items, path, out)
    elif isinstance(value, ts_eval.JSMap):
        approx_values(value.pairs, path, out)


def find_unknowns(value, path: str, out: list) -> None:
    if isinstance(value, dict):
        if "$unknown" in value and "at" in value:
            out.append({"path": path, "reason": value["$unknown"], "at": value["at"]})
            return
        for k, v in value.items():
            find_unknowns(v, f"{path}.{k}", out)
    elif isinstance(value, list):
        for i, v in enumerate(value):
            find_unknowns(v, f"{path}[{i}]", out)


class Reference:
    """The evaluated reference tables. `src` is the builder's Source (it reads
    `git show <commit>:<path>` and records every input's hash)."""

    def __init__(self, src, files: set[str], perturb=None) -> None:
        self.src = src
        self.files = files
        self.trace = ts_eval.Trace()
        self.trace.perturb = perturb
        ts_eval.TRACE = self.trace
        self.interp = Interpreter(src.read, lambda p: p in files)
        self.data = self.interp.module_for("src/sim/data.ts")
        self.mobs = self.data.export("MOBS")
        self.items = self.data.export("ITEMS")
        studio_mod = self.interp.module_for("src/sim/studio_content.ts")
        studio = studio_mod.export("STUDIO_CONTENT")
        self.studio_mobs = studio["mobs"]
        self.studio_items = studio["items"]
        self.mob_origin = self._origins(self.data, "MOBS", self.mobs)
        self.item_origin = self._origins(self.data, "ITEMS", self.items)
        studio_node = studio_mod.decl_nodes["STUDIO_CONTENT"]
        self.studio_mob_origin = self._origins_from_prop(studio_mod, studio_node, "mobs", self.studio_mobs)
        self.studio_item_origin = self._origins_from_prop(studio_mod, studio_node, "items", self.studio_items)
        self.check_effects()

    # -- evaluation report
    def effects(self) -> list[dict]:
        out = []
        for path in sorted(self.interp.modules):
            for where, result in self.interp.modules[path].effect_results:
                out.append({"at": where, "result": result})
        return out

    def check_effects(self) -> None:
        bad = [e for e in self.effects() if e["result"] != "applied" and e["at"] not in HARMLESS_EFFECTS]
        if bad:
            raise SystemExit("top-level source effects could not be evaluated; a registry could be incomplete:\n"
                             + "\n".join(f"  {e['at']}: {e['result']}" for e in bad))

    def report(self) -> dict:
        unparsed = sorted(u for m in self.interp.modules.values() for u in m.unparsed)
        return {
            "modules_evaluated": len(self.interp.modules),
            "top_level_effects": self.effects(),
            "unparsed_statements": unparsed,
        }

    def math_audit(self, outputs: dict[str, object]) -> dict:
        """Every Math call and `**` the evaluation made, and where each approximated
        result can go. `outputs` maps a registry name to its raw (pre-JSON) value;
        an approximated value found in one is REGISTRY_RELEVANT (and becomes
        UNKNOWN in the JSON, never VERIFIED); a decision taken on one is an
        UNRESOLVED_DEPENDENCY (a branch could depend on the last bit)."""
        reached: dict[str, list[str]] = {}
        for name, value in outputs.items():
            hits: list = []
            approx_values(value, name, hits)
            for path, sites in hits:
                for site in sites:
                    reached.setdefault(site, []).append(path)
        decided: dict[str, list[dict]] = {}
        for d in self.trace.decisions:
            for site in d["sites"]:
                decided.setdefault(site, []).append(d)
        confined = self.check_confinement(outputs)
        sites: dict[str, dict] = {}
        totals = {"exact": 0, "approximated": 0}
        for (op, where, context, approximated), count in sorted(self.trace.calls.items()):
            totals["approximated" if approximated else "exact"] += count
            if not approximated:
                continue
            site = f"{where} {op}"
            rec = sites.setdefault(site, {"site": site, "file": where.rsplit(":", 1)[0],
                                          "line": int(where.rsplit(":", 1)[1]), "operation": op,
                                          "functions": [], "calls": 0})
            rec["calls"] += count
            if context not in rec["functions"]:
                rec["functions"].append(context)
        for site, rec in sites.items():
            if site in reached:
                rec["result"] = "REGISTRY_RELEVANT"
                rec["evidence"] = {"registry_paths": sorted(set(reached[site]))[:20]}
            elif site in decided:
                bindings = sorted({str(d["binding"]) for d in decided[site]})
                if all(b in confined for b in bindings):
                    rec["result"] = "NON_GAMEPLAY_LAYOUT_ONLY"
                    rec["evidence"] = {"registry_values_reached": 0,
                                       "decisions_taken_on_it": len(decided[site]),
                                       "decisions_confined_to": {b: confined[b] for b in bindings}}
                else:
                    rec["result"] = "UNRESOLVED_DEPENDENCY"
                    rec["evidence"] = {"decisions": decided[site][:10],
                                       "unconfined_bindings": [b for b in bindings if b not in confined]}
            else:
                rec["result"] = "NON_GAMEPLAY_LAYOUT_ONLY"
                rec["evidence"] = {"registry_values_reached": 0, "decisions_taken_on_it": 0}
        exact_ops: dict[str, int] = {}
        for (op, _w, _c, approximated), count in self.trace.calls.items():
            if not approximated:
                exact_ops[op] = exact_ops.get(op, 0) + count
        by_result: dict[str, int] = {}
        for rec in sites.values():
            by_result[rec["result"]] = by_result.get(rec["result"], 0) + rec["calls"]
        return {
            "calls_examined": totals["exact"] + totals["approximated"],
            "exact_calls": totals["exact"],
            "exact_calls_by_operation": dict(sorted(exact_ops.items())),
            "approximated_calls": totals["approximated"],
            "approximated_sites": len(sites),
            "approximated_calls_by_result": dict(sorted(by_result.items())),
            "decisions_on_approximated_values": len(self.trace.decisions),
            "sites": [sites[k] for k in sorted(sites)],
        }

    def check_confinement(self, outputs: dict[str, object]) -> dict[str, dict]:
        """Re-verify every CONFINED_BINDINGS entry; fail the build if one no longer holds."""
        registry_ids: set[int] = set()

        def collect(v) -> None:
            if isinstance(v, (dict, list, ts_eval.JSSet, ts_eval.JSMap)):
                if id(v) in registry_ids:
                    return
                registry_ids.add(id(v))
                items = v.values() if isinstance(v, dict) else v.items if isinstance(v, ts_eval.JSSet) \
                    else [x for pair in v.pairs for x in pair] if isinstance(v, ts_eval.JSMap) else v
                for x in items:
                    collect(x)

        for value in outputs.values():
            collect(value)
        out = {}
        for key, spec in CONFINED_BINDINGS.items():
            path, name = key.split("#")
            value = self.module_value(path, name)
            shared: list = []

            def walk(v, where) -> None:
                if isinstance(v, (dict, list)):
                    if id(v) in registry_ids:
                        shared.append(where)
                    for k, x in (v.items() if isinstance(v, dict) else enumerate(v)):
                        walk(x, f"{where}.{k}")
            walk(value, name)
            refs = sorted(f"{f}:{i + 1}" for f in sorted(self.files) if f.startswith("src/") and f.endswith(".ts")
                          and not f.endswith(".test.ts") and name in (text := self.src.read(f))
                          for i, line in enumerate(text.splitlines())
                          if re.search(rf"\b{re.escape(name)}\b", line))
            if shared:
                raise SystemExit(f"{key}: objects of this binding appear in a registry: {shared[:5]}")
            if refs != spec["references"]:
                raise SystemExit(f"{key}: its source references changed: {refs}; review the confinement")
            out[key] = {"reason": spec["reason"], "references": refs, "objects_shared_with_registries": 0}
        return out

    # -- where each record comes from
    def _origins(self, mod, name: str, table: dict) -> dict[str, dict]:
        out: dict[str, dict] = {}
        self._attribute(mod, mod.decl_nodes[name], out, name)
        for key in table:
            if key not in out:
                out[key] = self._effect_origin(mod, name)
        return out

    def _origins_from_prop(self, mod, node, prop_name: str, table: dict) -> dict[str, dict]:
        out: dict[str, dict] = {}
        for prop in node[2]:
            if prop[0] == "prop" and prop[2][0] == "str" and prop[2][2] == prop_name:
                self._attribute(mod, prop[3], out, prop_name)
        for key in table:
            out.setdefault(key, {"file": mod.path, "export": prop_name})
        return out

    def _effect_origin(self, mod, name: str) -> dict:
        added = [w for w, r in mod.effect_results
                 if r == "applied" and name in mod.text.splitlines()[int(w.rsplit(":", 1)[1]) - 1]]
        return {"file": mod.path, "export": name, "added_at_load_by": added}

    def _attribute(self, mod, node, out: dict, export: str) -> None:
        """Credit each key of a table to the module whose literal or export
        defines it, following spreads and `mergeItems(...)` arguments."""
        k = node[0]
        if k == "paren":
            return self._attribute(mod, node[2], out, export)
        if k == "object":
            for prop in node[2]:
                if prop[0] == "spread":
                    self._attribute(mod, prop[2], out, export)
                else:
                    key = ts_eval.prop_key(self.interp.eval(prop[2], mod.scope, mod))
                    target = prop[3]
                    if target[0] == "id":
                        file, local = mod.origin(target[2])
                        out[key] = {"file": file, "export": local}
                    else:
                        out[key] = {"file": mod.path, "export": export}
            return
        if k == "call":
            for arg in node[3]:
                self._attribute(mod, arg, out, export)
            return
        if k == "id":
            file, local = mod.origin(node[2])
            owner = self.interp.module_for(file)
            decl = owner.decl_nodes.get(local)
            sub: dict = {}
            if decl is not None and decl[0] in ("object", "call", "paren"):
                self._attribute(owner, decl, sub, local)
            value = owner.export(local) if owner.has_export(local) else owner._get_local(local)
            if isinstance(value, dict):
                for key in value:
                    sub.setdefault(key, {"file": file, "export": local})
            out.update(sub)  # a later spread overrides an earlier one, as in JavaScript
            return

    # -- records
    def monster_records(self) -> dict[str, dict]:
        out = {}
        for table, mobs, origins in ((MOBS_TABLE, self.mobs, self.mob_origin),
                                     (STUDIO_MOBS_TABLE, self.studio_mobs, self.studio_mob_origin)):
            for mob_id, template in mobs.items():
                if table == STUDIO_MOBS_TABLE and mob_id in self.mobs:
                    continue  # the overlay never replaces a base record (studio_content.ts addMissing)
                out[mob_id] = self._monster(mob_id, to_json(template), table, origins[mob_id])
        return dict(sorted(out.items()))

    def _monster(self, mob_id: str, fields: dict, table: str, origin: dict) -> dict:
        path = origin["file"]
        flags = {f: fields[f] for f in MOB_FLAGS if f in fields and fields[f] not in (False, None)}
        context = mob_context(path, fields)
        unknowns: list = []
        find_unknowns(fields, mob_id, unknowns)
        classification = next((label for flag, label in CLASSIFICATION_ORDER if fields.get(flag)), "normal")
        source_fields = {k: v for k, v in fields.items() if k != "loot"}
        return {
            "id": mob_id,
            "namespaced_id": namespaced(mob_id),
            "registry_table": table,
            "ref": {"id": mob_id, "name": fields.get("name"), "file": path, "export": origin["export"],
                    **({"added_at_load_by": origin["added_at_load_by"]} if origin.get("added_at_load_by") else {})},
            "family": fields.get("family"),
            "level": {"min": fields.get("minLevel"), "max": fields.get("maxLevel")},
            "stats": {k: fields[k] for k in MOB_STAT_FIELDS if k in fields},
            "flags": flags,
            "classification": classification,
            "classification_status": "VERIFIED: from the source flags worldBoss > boss > rare > elite > none; a rare spawn stays 'rare' (owner decision 2026-11-17: never a mini-boss)",
            "context": context,
            "heroic_level": 22 if context == "dungeon" else None,
            "mechanics": {},  # filled by the builder from the MobTemplate field list
            "source_fields": source_fields,
            "loot_table": f"mob:{mob_id}",
            "unknown_values": unknowns,
            "selection": mob_selection(path, table, context, fields),
        }

    def item_records(self, kinds: list[str]) -> dict[str, dict]:
        out = {}
        for table, items, origins in ((ITEMS_TABLE, self.items, self.item_origin),
                                      (STUDIO_ITEMS_TABLE, self.studio_items, self.studio_item_origin)):
            for item_id, item in items.items():
                if table == STUDIO_ITEMS_TABLE and item_id in self.items:
                    continue
                fields = to_json(item)
                origin = origins[item_id]
                path = origin["file"]
                unknowns: list = []
                find_unknowns(fields, item_id, unknowns)
                req = fields.get("requiredClass")
                out[item_id] = {
                    "id": item_id,
                    "namespaced_id": namespaced(item_id),
                    "registry_table": table,
                    "kind": fields.get("kind"),
                    "slot": fields.get("slot"),
                    "quality": fields.get("quality"),
                    "armor_type": fields.get("armorType"),
                    "hand": fields.get("hand"),
                    "required_level": fields.get("requiredLevel"),
                    "stats": fields.get("stats"),
                    "weapon": fields.get("weapon"),
                    "required_class": {"classes": req} if isinstance(req, list) else None if req is None else {"unresolved": req},
                    "sell_value": fields.get("sellValue"),
                    "ref": {"id": item_id, "name": fields.get("name"), "file": path, "export": origin["export"],
                            **({"added_at_load_by": origin["added_at_load_by"]} if origin.get("added_at_load_by") else {})},
                    "source_fields": fields,
                    "unknown_values": unknowns,
                    "selection": item_selection(path, table),
                }
        return dict(sorted(out.items()))

    # -- loot
    def heroic_boss_loot(self) -> dict:
        return self.interp.module_for("src/sim/content/heroic_loot.ts").export("HEROIC_BOSS_LOOT")

    def module_value(self, path: str, name: str):
        """An exported or module-private binding, evaluated."""
        mod = self.interp.module_for(path)
        if mod.has_export(name):
            return mod.export(name)
        return mod._get_local(name)

    def fresh_literal_keys(self, path: str, name: str) -> set[str] | None:
        """Keys of a table's own literal, evaluated afresh (before any load-time
        statement added to the live object); None if it is not a literal."""
        mod = self.interp.module_for(path)
        node = mod.decl_nodes.get(name)
        if node is None or node[0] not in ("object", "paren", "call"):
            return None
        value = self.interp.eval(node, mod.scope, mod)
        return set(value) if isinstance(value, dict) else None

    def record_construction(self, path: str, export: str, record_id: str) -> str:
        """How a table's record is written in its table literal, read from the
        syntax tree: a factory call, a literal record (and how its id is given),
        a computed key, or absent from the literal (added by a load-time statement)."""
        mod = self.interp.module_for(path)
        node = mod.decl_nodes.get(export)
        while node is not None and node[0] == "paren":
            node = node[2]
        if node is None or node[0] != "object":
            return f"its table {export} is built by an expression, not a literal"
        for prop in node[2]:
            if prop[0] != "prop":
                continue
            try:
                key = ts_eval.prop_key(self.interp.eval(prop[2], mod.scope, mod))
            except Unsupported:
                continue
            if key != record_id:
                continue
            computed = prop[2][0] != "str"
            value = prop[3]
            if value[0] == "call":
                callee = value[2]
                name = callee[2] if callee[0] == "id" else "a helper"
                return f"built by a factory call {name}(...)" + (" under a computed key" if computed else "")
            if value[0] == "object":
                id_props = [q for q in value[2] if q[0] == "prop" and q[2][0] == "str" and q[2][2] == "id"]
                if id_props and id_props[0][3][0] != "str":
                    v = id_props[0][3]
                    shown = v[2] if v[0] == "id" else "an expression"
                    return f"a literal record whose id is the constant {shown}"
                if any(q[0] == "spread" for q in value[2]):
                    return "a literal record whose remaining fields (hpBase included) come from a spread"
                return "a literal record"
            if value[0] == "id":
                return "registered under a computed key ([RECORD.id]: RECORD); its id is a constant" if computed \
                    else f"the record is the constant {value[2]}"
            return f"built by a {value[0]} expression"
        for prop in node[2]:
            if prop[0] != "spread":
                continue
            spread = self.interp.eval(prop[2], mod.scope, mod)
            if isinstance(spread, dict) and record_id in spread:
                inner = prop[2]
                name = inner[2][2] if inner[0] == "call" and inner[2][0] == "id" else (inner[2] if inner[0] == "id" else "an expression")
                return f"spread into the table literal from {name}{'(...)' if inner[0] == 'call' else ''}"
        fresh = self.fresh_literal_keys(path, export)
        if fresh is not None and record_id not in fresh:
            return "absent from the table literal: added by a load-time statement"
        return "not found in the table literal"

    def model_data(self, model: dict) -> dict:
        """The source values an execution model reads, by its local names.
        A name ending in '()' is a call of that source function."""
        out = {}
        for local, (path, binding) in model.get("data", {}).items():
            if binding.endswith("()"):
                value = self.call(path, binding[:-2])
            else:
                value = self.module_value(path, binding)
            out[local] = to_json(value)
        return out

    def call(self, path: str, name: str, *args):
        mod = self.interp.module_for(path)
        fn = mod.export(name) if mod.has_export(name) else mod._get_local(name)
        return self.interp.call(fn, list(args), f"{path}:{name}")


def mob_context(path: str, fields: dict) -> str:
    if path in PET_FILES or fields.get("petRole"):
        return "player_pet"
    if path in NON_ENEMY_FILES:
        return NON_ENEMY_FILES[path][0]
    if path.startswith("src/sim/content/rift/"):
        return "rift"
    if path.startswith("src/sim/content/delves/"):
        return "delve"
    if path in DUNGEON_FILES:
        return "dungeon"
    if path == "src/sim/content/world_quests.ts" and str(fields.get("id", "")).endswith("_caravan"):
        return "escort_objective"
    return "world"


def mob_selection(path: str, table: str, context: str, fields: dict) -> str:
    if path in EXCLUDED_FILES:
        return EXCLUDED_FILES[path]
    if table == STUDIO_MOBS_TABLE:
        return "NOT_AN_ENEMY: an authored-map (Studio) record outside the base world" if path in NON_ENEMY_FILES \
            else "EXCLUDED: Studio overlay record outside the base world"
    if context == "rift":
        return "DEFERRED: Rift enemy; level 23 (S rank) only once the Rift is implemented and validated"
    if context == "player_pet":
        return "NOT_AN_ENEMY: a player pet or summon (created at its owner's level)"
    if path in NON_ENEMY_FILES:
        return NON_ENEMY_FILES[path][1]
    if context == "escort_objective":
        return "NOT_AN_ENEMY: a world-quest escort caravan (objective type 'escort' in world_quests.ts)"
    if fields.get("dummy") or fields.get("friendlyPracticeTarget"):
        return "NOT_AN_ENEMY: a practice target (source flag dummy)"
    if fields.get("ambient"):
        return "NOT_AN_ENEMY: ambient decoration, never hostile and un-attackable (source flag ambient)"
    if fields.get("musterSoldier"):
        return "NOT_AN_ENEMY: a muster soldier, never hostile (source flag musterSoldier)"
    if fields.get("seasonalEvent") or path in SEASONAL_FILES:
        return SEASONAL_FILES.get(path, "DEFERRED: seasonal event enemy; adopted with the event system")
    return "PENDING_REVIEW"


def item_selection(path: str, table: str) -> str:
    if path in EXCLUDED_FILES:
        return EXCLUDED_FILES[path]
    if table == STUDIO_ITEMS_TABLE:
        return "EXCLUDED: Studio overlay record outside the base world"
    for prefix, why in DEFERRED_PREFIXES.items():
        if path.startswith(prefix):
            return why
    return "PENDING_SELECTION"


# ---------------------------------------------------------------------------
# Loot semantics, read from the rollers. Each rule cites the source line, which
# the build re-locates on every run (line_of): if the code moves or changes,
# the build fails instead of keeping a stale citation.

ROLLER_CITATIONS = {
    "corpse": [
        ("src/sim/loot/loot_roll.ts", "export function rollLoot(", "rollLoot: one pass over template.loot in array order"),
        ("src/sim/loot/loot_roll.ts", "if (!lootEntryRollsOnClaim(entry, heroicClaim)) continue;", "normalOnly rows (and their whole roll group) are skipped on a heroic claim, drawing nothing"),
        ("src/sim/loot/loot_roll.ts", "const roll = ctx.rng.next();", "a rollGroup draws exactly one rng.next() for the whole group"),
        ("src/sim/loot/loot_roll.ts", "export function pickRollGroupWinner(", "the group's winner is the first entry whose cumulative chance exceeds the draw; none if the chances sum below the draw; an item already awarded on this kill falls forward to the next entry of its group"),
        ("src/sim/loot/loot_roll.ts", "if (entry.questId) {", "a questId row rolls only if some eligible player needs it, and drops as personal loot for each of them"),
        ("src/sim/loot/loot_roll.ts", "if (!ctx.rng.chance(entry.chance)) continue;", "every other row is an independent rng.chance(chance): drops when next() < chance"),
        ("src/sim/loot/loot_roll.ts", "copper += ctx.rng.int(Math.ceil(moneyBase * 0.6), Math.ceil(moneyBase * 1.4));", "copper pays rng.int(ceil(base x 0.6), ceil(base x 1.4)), inclusive; base is heroicCopper on a heroic claim, else copper"),
        ("src/sim/rng.ts", "int(min: number, max: number): number {", "rng.int is inclusive of both bounds"),
        ("src/sim/loot/class_locked_drop.ts", "export function usableRollGroup(", "a soulbound class-locked row is withheld when no eligible class can use it; its group is rescaled over the usable rows, the group total kept"),
        ("src/sim/loot/heroic_item.ts", "export function heroicLootItemId(", "on a heroic claim an item is swapped for its heroic variant when that variant has a higher item level"),
        ("src/sim/combat/damage.ts", "if (!template?.worldBoss) ctx.rollLoot(", "world bosses never use this roller"),
    ],
    "corpse_heroic_append": [
        ("src/sim/loot/loot_roll.ts", "const heroicEntries = HEROIC_BOSS_LOOT[mob.templateId];", "rolled after the base table, only on a heroic claim, into the same corpse; roll-group names never overlap the base table's"),
    ],
    "world_boss_personal": [
        ("src/sim/world_boss.ts", "export function rollWorldBossLoot(", "rollWorldBossLoot: the template's loot rolled once per eligible contributor, contributors in entityId order"),
        ("src/sim/world_boss.ts", "let gearWon = false;", "at most one roll-group (gear) item per contributor; every group is still rolled"),
        ("src/sim/world_boss.ts", "(entry.maxPlayerLevel === undefined || level <= entry.maxPlayerLevel) &&", "maxPlayerLevel, unlessOwned and unlessOwnedItem gate a win per contributor"),
        ("src/sim/world_boss.ts", "const copper = mob.loot?.copper ?? 0;", "copper rows are drawn but pay nothing here: the corpse copper comes from mob.loot, and rollLoot never runs for a world boss"),
    ],
}


def roller_rules(src) -> dict:
    out = {}
    for roller, cites in ROLLER_CITATIONS.items():
        out[roller] = [{"rule": rule, "source": f"{path}:{line_of(src.read(path), needle, path)}"}
                       for path, needle, rule in cites]
    return out


ENTRY_FIELDS = {
    "itemId": "item", "copper": "copper", "heroicCopper": "heroic_copper", "chance": "chance",
    "rollGroup": "roll_group", "questId": "quest_id", "normalOnly": "normal_only",
    "preserveSourceTier": "preserve_source_tier", "unlessOwned": "unless_owned",
    "unlessOwnedItem": "unless_owned_item", "maxPlayerLevel": "max_player_level",
}


def copper_range(base) -> dict | None:
    if not isinstance(base, (int, float)) or isinstance(base, bool):
        return None
    return {"min": math.ceil(base * 0.6), "max": math.ceil(base * 1.4)}


def loot_entry(table_id: str, index: int, raw, item_index: dict) -> dict:
    """One LootEntry, every source field kept. `chance` is the exact double the
    source computes (authored, or derived by weightedLootGroup/usableRollGroup
    at module load); nothing is rounded or normalised."""
    entry_id = f"{table_id}#{index}"
    if not isinstance(raw, dict):
        return {"id": entry_id, "table": table_id, "index": index, "source_fields": raw,
                "unknown_values": [{"path": entry_id, "reason": "not an object", "at": None}]}
    rec: dict = {"id": entry_id, "table": table_id, "index": index}
    for src_key, key in ENTRY_FIELDS.items():
        rec[key] = raw.get(src_key)
    unknown_fields = sorted(set(raw) - set(ENTRY_FIELDS))
    item_id = raw.get("itemId")
    if isinstance(item_id, str):
        target = item_index.get(item_id)
        rec["item"] = {"id": item_id, "namespaced_id": namespaced(item_id), "resolves": target is not None,
                       "registry_table": target}
    rec["copper_roll"] = copper_range(raw.get("copper"))
    rec["heroic_copper_roll"] = copper_range(raw.get("heroicCopper"))
    rec["fields_not_in_loot_entry"] = unknown_fields
    rec["source_fields"] = raw
    unknowns: list = []
    find_unknowns(raw, entry_id, unknowns)
    rec["unknown_values"] = unknowns
    return rec


def group_totals(entries: list[dict]) -> dict:
    """Each roll group's summed chance, as the roller accumulates it (in order,
    double arithmetic). Recorded, never forced to 1: a total below 1 means the
    group can drop nothing."""
    totals: dict[str, float] = {}
    for e in entries:
        g = e.get("roll_group")
        c = e.get("chance")
        if isinstance(g, str) and isinstance(c, (int, float)) and not isinstance(c, bool):
            totals[g] = totals.get(g, 0.0) + float(c)
    return {g: (int(t) if float(t).is_integer() else t) for g, t in totals.items()}


def canonical(doc) -> str:
    return json.dumps(doc, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def item_ids_in(value, out: set) -> None:
    """Item ids named by a static reward table (strings that are item ids)."""
    if isinstance(value, str):
        out.add(value)
    elif isinstance(value, dict):
        for v in value.values():
            item_ids_in(v, out)
    elif isinstance(value, list):
        for v in value:
            item_ids_in(v, out)


__all__ = ["Reference", "Unknown", "Unsupported", "canonical", "loot_entry", "group_totals", "roller_rules",
           "namespaced", "sha256", "line_of", "find_unknowns", "item_ids_in", "re"]
